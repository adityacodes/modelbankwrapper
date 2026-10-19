/// Configuration constants for the Model Bank OAuth Gateway.
class ModelBankConfig {
  /// Base URL of the Bank's Authorization endpoint (APIHub Open Finance AE).
  static String baseAuthUrl =
      'https://auth1.altareq1.sandbox.apihub.openfinance.ae/auth';

  /// Target redirect URL for the TPP application handoff.
  static String targetTppUrl = 'https://cbd-flutter.go.link/tpp';

  /// Default issuer identifier when not explicitly returned in callback parameters.
  static String defaultIssuer =
      'https://auth1.altareq1.sandbox.apihub.openfinance.ae';

  /// Example App Link provided for testing and simulation (TPP Domain).
  static const String sampleDeepLink =
      'https://auth.mytpp.dpdns.org/auth?client_id=https%3A%2F%2Frp.sandbox.directory.openfinance.ae%2Fopenid_relying_party%2F340ebd0e-4848-4cc1-95e7-d6b4776e42a8&response_type=code&scope=openid&request_uri=urn%3Aietf%3Aparams%3Aoauth%3Arequest_uri%3Ab17b9064-d660-4f74-bc42-e5b2fb9d73b7';

  /// Example Auth Link directly from Open Finance AE Sandbox domain.
  static const String sampleApiHubLink =
      'https://auth1.altareq1.sandbox.apihub.openfinance.ae/auth?client_id=https%3A%2F%2Frp.sandbox.directory.openfinance.ae%2Fopenid_relying_party%2F340ebd0e-4848-4cc1-95e7-d6b4776e42a8&response_type=code&scope=openid&request_uri=urn%3Aietf%3Aparams%3Aoauth%3Arequest_uri%3Ab17b9064-d660-4f74-bc42-e5b2fb9d73b7';

  /// Whether to automatically launch the In-App Browser when a deeplink arrives.
  static bool autoLaunchBrowser = true;

  /// Whether to automatically open the target TPP link upon intercepting the redirect.
  static bool autoOpenTpp = true;
}
