import 'package:flutter_test/flutter_test.dart';
import 'package:modelbank/src/model_bank/model_bank_config.dart';
import 'package:modelbank/src/model_bank/model_bank_gateway_service.dart';
import 'package:modelbank/src/model_bank/model_bank_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleDeepLink =
      'modelbank://auth?client_id=https%3A%2F%2Frp.sandbox.directory.openfinance.ae%2Fopenid_relying_party%2F340ebd0e-4848-4cc1-95e7-d6b4776e42a8&response_type=code&scope=openid&request_uri=urn%3Aietf%3Aparams%3Aoauth%3Arequest_uri%3Ab17b9064-d660-4f74-bc42-e5b2fb9d73b7';

  group('Model Bank OAuth Deeplink Parsing & URL Transformation Tests', () {
    test('Correctly parses incoming modelbank://auth deeplink parameters', () {
      final req = OAuthAuthRequest.fromString(sampleDeepLink);

      expect(
        req.clientId,
        'https://rp.sandbox.directory.openfinance.ae/openid_relying_party/340ebd0e-4848-4cc1-95e7-d6b4776e42a8',
      );
      expect(req.responseType, 'code');
      expect(req.scope, 'openid');
      expect(
        req.requestUri,
        'urn:ietf:params:oauth:request_uri:b17b9064-d660-4f74-bc42-e5b2fb9d73b7',
      );
      expect(req.allParams.length, 4);
    });

    test('Constructs Bank Auth URL with all query parameters intact', () {
      final req = OAuthAuthRequest.fromString(sampleDeepLink);
      final authUri = req.toBankAuthUri(
        'https://auth1.altareq1.sandbox.apihub.openfinance.ae/auth',
      );

      expect(authUri.scheme, 'https');
      expect(authUri.host, 'auth1.altareq1.sandbox.apihub.openfinance.ae');
      expect(authUri.path, '/auth');
      expect(
        authUri.queryParameters['client_id'],
        'https://rp.sandbox.directory.openfinance.ae/openid_relying_party/340ebd0e-4848-4cc1-95e7-d6b4776e42a8',
      );
      expect(authUri.queryParameters['response_type'], 'code');
      expect(authUri.queryParameters['scope'], 'openid');
      expect(
        authUri.queryParameters['request_uri'],
        'urn:ietf:params:oauth:request_uri:b17b9064-d660-4f74-bc42-e5b2fb9d73b7',
      );
    });

    test('Correctly extracts state, code, and issuer from redirection callback', () {
      const callbackUrl =
          'https://cbd-flutter.go.link/tpp?state=asa&code=asasa&issuer=asajsa';
      final response = OAuthAuthResponse.fromUrl(callbackUrl);

      expect(response.isSuccess, isTrue);
      expect(response.state, 'asa');
      expect(response.code, 'asasa');
      expect(response.issuer, 'asajsa');
    });

    test(
      'Correctly formats target TPP forward URL with state, code, and issuer',
      () {
        const response = OAuthAuthResponse(
          code: 'asasa',
          state: 'asa',
          issuer: 'asajsa',
        );

        final forwardUri = response.toTppForwardUri(
          'https://cbd-flutter.go.link/tpp',
        );

        expect(forwardUri.scheme, 'https');
        expect(forwardUri.host, 'cbd-flutter.go.link');
        expect(forwardUri.path, '/tpp');
        expect(forwardUri.queryParameters['state'], 'asa');
        expect(forwardUri.queryParameters['code'], 'asasa');
        expect(forwardUri.queryParameters['issuer'], 'asajsa');
        expect(
          forwardUri.toString(),
          'https://cbd-flutter.go.link/tpp?state=asa&code=asasa&issuer=asajsa',
        );
      },
    );

    test('Falls back to default issuer when issuer is omitted in redirect', () {
      const redirectWithoutIssuer =
          'https://modelbank.ae/callback?state=xyz&code=abc12345';
      final response = OAuthAuthResponse.fromUrl(
        redirectWithoutIssuer,
        defaultIssuer: ModelBankConfig.defaultIssuer,
      );

      expect(response.code, 'abc12345');
      expect(response.state, 'xyz');
      expect(
        response.issuer,
        'https://auth1.altareq1.sandbox.apihub.openfinance.ae',
      );

      final forwardUri = response.toTppForwardUri(
        'https://cbd-flutter.go.link/tpp',
      );
      expect(
        forwardUri.queryParameters['issuer'],
        'https://auth1.altareq1.sandbox.apihub.openfinance.ae',
      );
    });
  });

  group('Model Bank Gateway Service Lifecycle Tests', () {
    test(
      'Simulated redirection transitions stage and prepares TPP URL',
      () async {
        final service = ModelBankGatewayService();
        ModelBankConfig.autoOpenTpp =
            false; // Disable opening external app in test

        await service.simulateCompletedCallback(
          code: 'asasa',
          state: 'asa',
          issuer: 'asajsa',
        );

        expect(service.stage, GatewayStage.redirectIntercepted);
        expect(service.currentResponse?.code, 'asasa');
        expect(service.currentResponse?.state, 'asa');
        expect(service.currentResponse?.issuer, 'asajsa');
        expect(
          service.currentTppForwardUri.toString(),
          'https://cbd-flutter.go.link/tpp?state=asa&code=asasa&issuer=asajsa',
        );

        service.resetSession();
        expect(service.stage, GatewayStage.idle);
        expect(service.currentResponse, isNull);
      },
    );
  });
}
