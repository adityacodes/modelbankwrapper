import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'model_bank_config.dart';
import 'model_bank_models.dart';

/// Core service orchestrating the Model Bank OAuth Gateway lifecycle:
/// 1. Intercepting deeplinks
/// 2. Parsing OAuth query parameters
/// 3. Opening the Bank Auth portal in an In-App Browser
/// 4. Intercepting redirect responses (`code`, `state`, `issuer`)
/// 5. Forwarding and opening the target TPP link
class ModelBankGatewayService extends ChangeNotifier {
  static const MethodChannel _platformChannel = MethodChannel(
    'org.modelbank/gateway',
  );

  // Singleton instance
  static final ModelBankGatewayService _instance =
      ModelBankGatewayService._internal();
  factory ModelBankGatewayService() => _instance;
  ModelBankGatewayService._internal();

  GatewayStage _stage = GatewayStage.idle;
  OAuthAuthRequest? _currentRequest;
  OAuthAuthResponse? _currentResponse;
  Uri? _currentBankAuthUri;
  Uri? _currentTppForwardUri;
  String? _errorMessage;
  bool _isInitialized = false;

  final List<GatewayLogEntry> _logs = [];

  // Getters
  GatewayStage get stage => _stage;
  OAuthAuthRequest? get currentRequest => _currentRequest;
  OAuthAuthResponse? get currentResponse => _currentResponse;
  Uri? get currentBankAuthUri => _currentBankAuthUri;
  Uri? get currentTppForwardUri => _currentTppForwardUri;
  String? get errorMessage => _errorMessage;
  List<GatewayLogEntry> get logs => List.unmodifiable(_logs);

  /// Initializes native platform communication and checks for launch deeplink.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _addLog(
      LogType.info,
      'Gateway Initialized',
      'Model Bank OAuth Gateway listener is active and waiting for App Links (https://auth.mytpp.dpdns.org, https://auth1.altareq1.sandbox.apihub.openfinance.ae).',
    );

    _platformChannel.setMethodCallHandler(_handlePlatformMethodCall);

    try {
      final initialLink = await _platformChannel.invokeMethod<String>(
        'getInitialDeepLink',
      );
      if (initialLink != null && initialLink.isNotEmpty) {
        _addLog(
          LogType.deeplink,
          'Cold Launch Deeplink Intercepted',
          'Application started with deeplink: $initialLink',
        );
        await handleIncomingDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Initial deeplink query error (safe on desktop/web): $e');
    }
  }

  /// Handles runtime method invocations from native Android/iOS.
  Future<dynamic> _handlePlatformMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDeepLinkReceived':
        final link = call.arguments as String?;
        if (link != null && link.isNotEmpty) {
          _addLog(
            LogType.deeplink,
            'Runtime Deeplink Intercepted',
            'Received deep link while app active: $link',
          );
          await handleIncomingDeepLink(link);
        }
        break;
      default:
        break;
    }
  }

  /// Processes an incoming deeplink URI.
  Future<void> handleIncomingDeepLink(String rawLink) async {
    try {
      _errorMessage = null;
      final parsedRequest = OAuthAuthRequest.fromString(rawLink);
      _currentRequest = parsedRequest;
      _currentResponse = null;
      _currentTppForwardUri = null;

      // Construct target bank auth URL preserving all incoming query parameters
      _currentBankAuthUri = parsedRequest.toBankAuthUri(
        ModelBankConfig.baseAuthUrl,
      );

      _stage = GatewayStage.deeplinkReceived;

      _addLog(
        LogType.deeplink,
        'OAuth Deeplink Parsed',
        'Scheme: ${Uri.parse(rawLink).scheme} | Host: ${Uri.parse(rawLink).host}\n'
            'Client ID: ${parsedRequest.clientId ?? "None"}\n'
            'Response Type: ${parsedRequest.responseType ?? "None"}\n'
            'Scope: ${parsedRequest.scope ?? "None"}\n'
            'Request URI: ${parsedRequest.requestUri ?? "None"}',
      );

      _addLog(
        LogType.browser,
        'Bank Portal URL Generated',
        _currentBankAuthUri.toString(),
      );

      notifyListeners();

      if (ModelBankConfig.autoLaunchBrowser) {
        await launchInAppBrowser();
      }
    } catch (e) {
      _stage = GatewayStage.error;
      _errorMessage = 'Failed to process incoming deeplink: $e';
      _addLog(LogType.error, 'Deeplink Processing Error', _errorMessage!);
      notifyListeners();
    }
  }

  /// Launches the In-App Browser to load the Bank Auth portal.
  /// Intercepts redirect containing `state`, `code`, and `issuer`.
  Future<void> launchInAppBrowser({Uri? targetUri}) async {
    final authUri = targetUri ?? _currentBankAuthUri;
    if (authUri == null) {
      _errorMessage = 'No bank authorization URL available to launch.';
      _stage = GatewayStage.error;
      notifyListeners();
      return;
    }

    _stage = GatewayStage.browserActive;
    _errorMessage = null;
    _addLog(
      LogType.browser,
      'Opening In-App Browser',
      'Navigating to: ${authUri.toString()}',
    );
    notifyListeners();

    try {
      // 1. Attempt native InAppBrowserActivity via MethodChannel
      final result = await _platformChannel.invokeMapMethod<String, dynamic>(
        'openInAppBrowser',
        {'url': authUri.toString()},
      );

      if (result != null) {
        final cancelled = result['cancelled'] == true;
        if (cancelled) {
          _stage = GatewayStage.idle;
          _addLog(
            LogType.info,
            'Browser Closed by User',
            'User closed the In-App Browser without completing authentication.',
          );
          notifyListeners();
          return;
        }

        final response = OAuthAuthResponse.fromMap(
          result,
          fallbackIssuer: ModelBankConfig.defaultIssuer,
        );

        await handleOAuthResponse(response);
      }
    } on MissingPluginException {
      // Platform channel not available (e.g. running on Windows desktop / Web)
      _addLog(
        LogType.info,
        'Desktop/Web Fallback',
        'Native Android InAppBrowser not available on this platform. Launching external browser.',
      );

      final launched = await launchUrl(
        authUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch browser for URL: $authUri');
      }

      _stage = GatewayStage.browserActive;
      notifyListeners();
    } catch (e) {
      _stage = GatewayStage.error;
      _errorMessage = 'Error launching In-App Browser: $e';
      _addLog(LogType.error, 'Browser Launch Failure', _errorMessage!);
      notifyListeners();
    }
  }

  /// Handles the intercepted OAuth response and prepares the TPP forward URL.
  Future<void> handleOAuthResponse(OAuthAuthResponse response) async {
    _currentResponse = response;

    if (response.isSuccess) {
      _currentTppForwardUri = response.toTppForwardUri(
        ModelBankConfig.targetTppUrl,
      );
      _stage = GatewayStage.redirectIntercepted;

      _addLog(
        LogType.redirect,
        'Redirection Intercepted',
        'State: ${response.state ?? "N/A"}\n'
            'Code: ${response.code ?? "N/A"}\n'
            'Issuer: ${response.issuer ?? "N/A"}',
      );

      _addLog(
        LogType.handoff,
        'TPP Destination Prepared',
        _currentTppForwardUri.toString(),
      );

      notifyListeners();

      if (ModelBankConfig.autoOpenTpp) {
        await forwardToTpp();
      }
    } else if (response.error != null) {
      _stage = GatewayStage.error;
      _errorMessage =
          'OAuth Error: ${response.error} (${response.errorDescription ?? "No description"})';
      _addLog(LogType.error, 'OAuth Flow Error', _errorMessage!);
      notifyListeners();
    } else {
      _stage = GatewayStage.idle;
      notifyListeners();
    }
  }

  /// Opens the target TPP link (`https://cbd-flutter.go.link/tpp?state=...&code=...&issuer=...`)
  /// in the external application or system handler.
  Future<bool> forwardToTpp({Uri? targetTppUri}) async {
    final forwardUri = targetTppUri ?? _currentTppForwardUri;
    if (forwardUri == null) {
      _errorMessage = 'No TPP target URL generated to open.';
      notifyListeners();
      return false;
    }

    try {
      _addLog(
        LogType.handoff,
        'Opening TPP Link in System Browser',
        forwardUri.toString(),
      );

      final success = await launchUrl(
        forwardUri,
        mode: LaunchMode.externalApplication,
      );

      if (success) {
        _stage = GatewayStage.forwardedToTpp;
        _addLog(
          LogType.handoff,
          'Flow Completed Successfully',
          'User handed back to TPP via: ${forwardUri.toString()}',
        );
      } else {
        _addLog(
          LogType.error,
          'TPP Forward Launch Failed',
          'OS could not open external application for link: $forwardUri',
        );
      }

      notifyListeners();
      return success;
    } catch (e) {
      _stage = GatewayStage.error;
      _errorMessage = 'Failed to open TPP URL: $e';
      _addLog(LogType.error, 'Handoff Error', _errorMessage!);
      notifyListeners();
      return false;
    }
  }

  /// Simulates a completed redirection response for instant testing & validation.
  Future<void> simulateCompletedCallback({
    String code = 'asasa',
    String state = 'asa',
    String issuer = 'asajsa',
  }) async {
    _addLog(
      LogType.info,
      'Test Simulation Triggered',
      'Injecting mock OAuth completion callback with state=$state, code=$code, issuer=$issuer',
    );

    final mockResponse = OAuthAuthResponse(
      code: code,
      state: state,
      issuer: issuer,
      rawRedirectUrl:
          '${ModelBankConfig.targetTppUrl}?state=$state&code=$code&issuer=$issuer',
      isCancelled: false,
    );

    await handleOAuthResponse(mockResponse);
  }

  /// Clears active session state back to idle.
  void resetSession() {
    _stage = GatewayStage.idle;
    _currentRequest = null;
    _currentResponse = null;
    _currentBankAuthUri = null;
    _currentTppForwardUri = null;
    _errorMessage = null;
    _addLog(
      LogType.info,
      'Session Reset',
      'Gateway returned to idle listening state.',
    );
    notifyListeners();
  }

  /// Clears the audit logs.
  void clearLogs() {
    _logs.clear();
    _addLog(LogType.info, 'Logs Cleared', 'Audit log memory cleared by user.');
    notifyListeners();
  }

  void _addLog(LogType type, String title, String description) {
    _logs.insert(
      0,
      GatewayLogEntry(
        timestamp: DateTime.now(),
        type: type,
        title: title,
        description: description,
      ),
    );
    // Keep max 150 log entries in memory
    if (_logs.length > 150) {
      _logs.removeLast();
    }
  }
}
