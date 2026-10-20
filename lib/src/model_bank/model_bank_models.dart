/// Represents the current stage in the Model Bank OAuth Gateway lifecycle.
enum GatewayStage {
  idle,
  deeplinkReceived,
  browserActive,
  redirectIntercepted,
  forwardedToTpp,
  error,
}

/// Category of gateway log entries.
enum LogType {
  deeplink,
  browser,
  redirect,
  handoff,
  error,
  info,
}

/// Represents an incoming OAuth authorization request initiated via deeplink.
class OAuthAuthRequest {
  final String rawUri;
  final String? clientId;
  final String? responseType;
  final String? scope;
  final String? requestUri;
  final String? state;
  final Map<String, String> allParams;

  const OAuthAuthRequest({
    required this.rawUri,
    this.clientId,
    this.responseType,
    this.scope,
    this.requestUri,
    this.state,
    required this.allParams,
  });

  factory OAuthAuthRequest.fromUri(Uri uri) {
    final params = Map<String, String>.from(uri.queryParameters);
    return OAuthAuthRequest(
      rawUri: uri.toString(),
      clientId: params['client_id'],
      responseType: params['response_type'],
      scope: params['scope'],
      requestUri: params['request_uri'],
      state: params['state'],
      allParams: params,
    );
  }

  factory OAuthAuthRequest.fromString(String raw) {
    final parsed = Uri.parse(raw);
    return OAuthAuthRequest.fromUri(parsed);
  }

  /// Constructs the full Bank Auth portal URL to open in the In-App Browser,
  /// preserving all query parameters from the incoming request.
  Uri toBankAuthUri(String baseAuthUrl) {
    final base = Uri.parse(baseAuthUrl);
    final merged = Map<String, String>.from(base.queryParameters)
      ..addAll(allParams);
    return base.replace(queryParameters: merged);
  }
}

/// Represents the OAuth response intercepted from the In-App Browser redirection.
class OAuthAuthResponse {
  final String? code;
  final String? state;
  final String? issuer;
  final String? error;
  final String? errorDescription;
  final String? rawRedirectUrl;
  final bool isCancelled;

  const OAuthAuthResponse({
    this.code,
    this.state,
    this.issuer,
    this.error,
    this.errorDescription,
    this.rawRedirectUrl,
    this.isCancelled = false,
  });

  bool get isSuccess => code != null && !isCancelled && error == null;

  factory OAuthAuthResponse.fromMap(Map<dynamic, dynamic> map,
      {String? fallbackIssuer}) {
    final cancelled = map['cancelled'] == true;
    final code = map['code'] as String?;
    final state = map['state'] as String?;
    final rawIssuer = map['issuer'] as String?;
    final error = map['error'] as String?;
    final errorDesc = map['errorDescription'] as String?;
    final redirectUrl = map['redirectUrl'] as String?;

    return OAuthAuthResponse(
      code: code,
      state: state,
      issuer: (rawIssuer != null && rawIssuer.isNotEmpty)
          ? rawIssuer
          : fallbackIssuer,
      error: error,
      errorDescription: errorDesc,
      rawRedirectUrl: redirectUrl,
      isCancelled: cancelled,
    );
  }

  factory OAuthAuthResponse.fromUrl(String url, {String? defaultIssuer}) {
    final uri = Uri.parse(url);
    final params = uri.queryParameters;
    final code = params['code'];
    final state = params['state'];
    final issuer = params['issuer'] ?? params['iss'] ?? defaultIssuer;
    final error = params['error'];
    final errorDescription = params['error_description'];

    return OAuthAuthResponse(
      code: code,
      state: state,
      issuer: issuer,
      error: error,
      errorDescription: errorDescription,
      rawRedirectUrl: url,
      isCancelled: false,
    );
  }

  /// Builds the target TPP forward URL:
  /// Preserves any existing query parameters in [baseTppUrl] and appends/updates
  /// OAuth callback parameters (`state`, `code`, `issuer`, `error`, `error_description`).
  Uri toTppForwardUri(String baseTppUrl) {
    final base = Uri.parse(baseTppUrl);
    final forwardParams = Map<String, String>.from(base.queryParameters);

    if (state != null && state!.isNotEmpty) {
      forwardParams['state'] = state!;
    }
    if (code != null && code!.isNotEmpty) {
      forwardParams['code'] = code!;
    }
    if (issuer != null && issuer!.isNotEmpty) {
      forwardParams['issuer'] = issuer!;
    }
    if (error != null && error!.isNotEmpty) {
      forwardParams['error'] = error!;
    }
    if (errorDescription != null && errorDescription!.isNotEmpty) {
      forwardParams['error_description'] = errorDescription!;
    }

    return base.replace(queryParameters: forwardParams);
  }
}

/// Audit log entry tracking lifecycle steps in the Model Bank Gateway.
class GatewayLogEntry {
  final DateTime timestamp;
  final LogType type;
  final String title;
  final String description;

  const GatewayLogEntry({
    required this.timestamp,
    required this.type,
    required this.title,
    required this.description,
  });
}
