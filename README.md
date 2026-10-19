# Model Bank OAuth Gateway (Open Finance AE)

A specialized Flutter model bank gateway implementing the **Open Finance AE (APIHub Sandbox)** OAuth 2.0 authorization mechanism.

---

## Architecture & Flow Overview

```
┌─────────────────────────────────┐
│     Third-Party Provider (TPP)  │
│          Mobile / Web App       │
└────────────────┬────────────────┘
                 │ 1. Invokes App Link
                 ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                               MODEL BANK GATEWAY APP                             │
│                                                                                  │
│  [App Link Receiver]                                                             │
│  https://auth.mytpp.dpdns.org/auth?client_id=...&response_type=code...          │
│                                                                                  │
│  [URL Transformation]                                                            │
│  https://auth1.altareq1.sandbox.apihub.openfinance.ae/auth?                      │
│      client_id=...&response_type=code&scope=openid&request_uri=...              │
│                                                                                  │
│  [Native In-App Browser]                                                         │
│  Loads bank login & consent portal -> Intercepts completion redirection          │
│                                                                                  │
│  [Extraction & Handoff]                                                          │
│  Captures: state, code, issuer                                                   │
│  Opens: https://cbd-flutter.go.link/tpp?state=asa&code=asasa&issuer=asajsa               │
└────────────────┬─────────────────────────────────────────────────────────────────┘
                 │ 4. Handoff via external app/browser
                 ▼
┌─────────────────────────────────┐
│         Target TPP App          │
│    (https://cbd-flutter.go.link/tpp)    │
└─────────────────────────────────┘
```

---

## 1. App Link Interception (`auth.mytpp.dpdns.org`)

The gateway intercepts authorization requests matching domain `auth.mytpp.dpdns.org` (and fallback scheme `modelbank`):

```
https://auth.mytpp.dpdns.org/auth?client_id=https%3A%2F%2Frp.sandbox.directory.openfinance.ae%2Fopenid_relying_party%2F340ebd0e-4848-4cc1-95e7-d6b4776e42a8&response_type=code&scope=openid&request_uri=urn%3Aietf%3Aparams%3Aoauth%3Arequest_uri%3Ab17b9064-d660-4f74-bc42-e5b2fb9d73b7
```

### Captured Query Parameters:
- `client_id`: Open Finance AE Relying Party identifier (e.g. `https://rp.sandbox.directory.openfinance.ae/openid_relying_party/...`)
- `response_type`: Authorization code request (`code`)
- `scope`: Requested scopes (`openid`)
- `request_uri`: Pushed Authorization Request reference URN (`urn:ietf:params:oauth:request_uri:...`)
- Any additional OAuth/OIDC parameters (`state`, `nonce`, etc.)

---

## 2. In-App Browser Launch

The gateway reconstructs the target authorization URL on the sandbox identity portal:

```
https://auth1.altareq1.sandbox.apihub.openfinance.ae/auth?client_id=https%3A%2F%2Frp.sandbox.directory.openfinance.ae%2Fopenid_relying_party%2F340ebd0e-4848-4cc1-95e7-d6b4776e42a8&response_type=code&scope=openid&request_uri=urn%3Aietf%3Aparams%3Aoauth%3Arequest_uri%3Ab17b9064-d660-4f74-bc42-e5b2fb9d73b7
```

- **Native Android In-App Browser (`InAppBrowserActivity.kt`)**: Zero external library dependencies, hardware-accelerated WebView with custom header, progress bar, and comprehensive redirection interceptor.
- **Interception Mechanism**: Inspects all navigation requests (`shouldOverrideUrlLoading`, `onPageStarted`, `doUpdateVisitedHistory`) to capture 302 redirects and client-side navigations before routing fails.

---

## 3. Redirection Interception & Parameter Extraction

Upon successful authentication in the bank portal, the browser intercepts the redirection callback containing:
- `code`: The authorization code issued by the IdP
- `state`: The state string passed from the initial request
- `issuer`: The authorization server issuer (RFC 9207 `iss` or `issuer`, defaulting to `https://auth1.altareq1.sandbox.apihub.openfinance.ae`)

---

## 4. TPP Handoff (`cbd-flutter.go.link/tpp`)

The gateway constructs the final handoff URL:

```
https://cbd-flutter.go.link/tpp?state=asa&code=asasa&issuer=asajsa
```

And launches it in the system browser / external application using `url_launcher`.

---

## Project Structure

```
lib/
├── main.dart                               # App entry point & initialization
└── src/
    ├── model_bank/
    │   ├── model_bank_config.dart          # Base auth URLs, TPP target URL, behavior toggles
    │   ├── model_bank_models.dart          # OAuthAuthRequest, OAuthAuthResponse, logs
    │   └── model_bank_gateway_service.dart # Platform channel, flow coordinator, event logs
    ├── screens/
    │   ├── splash_screen.dart              # Launch screen navigating to Gateway
    │   └── model_bank_gateway_screen.dart  # Gateway console, visual stepper, testing studio
    └── theme/
        ├── cbd_colors.dart                 # Bank brand color system & design tokens
        └── smooth_page_route.dart          # Smooth transitions
android/
└── app/src/main/
    ├── AndroidManifest.xml                 # App Links for https://auth.mytpp.dpdns.org & modelbank://
    └── kotlin/org/dpdns/mytpp/auth/
        ├── MainActivity.kt                 # MethodChannel handler for deep links
        └── InAppBrowserActivity.kt         # Native In-App WebView with redirect interceptor
test/
├── model_bank_gateway_test.dart            # Unit tests for parsing, URLs, and lifecycle
└── widget_test.dart                        # Widget tests for Gateway UI
```

---


## Generating Release APKs (ARM64 Low-Size vs Universal)

### Why Standard APKs are ~48 MB
A universal "fat" APK packages compiled native binaries for 3 distinct CPU architectures:
- `arm64-v8a` (Modern Android smartphones and tablets)
- `armeabi-v7a` (Older 32-bit devices)
- `x86_64` (Emulators and Intel tablets)

Each architecture adds ~15 MB to the APK.

---

### Option 1: Optimized Low-Size Release APK for Modern Devices (~16.5 MB)
Generates a lightweight release APK compiled exclusively for 64-bit ARM devices (`arm64-v8a`), reducing size by **~65%**:

```bash
flutter build apk --release --target-platform android-arm64
```
**Output File**:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

### Option 2: Universal Release APK (All Devices / Emulators) (~48 MB)
Builds an APK compatible with all architectures:

```bash
flutter build apk --release
```
**Output File**:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Interactive Simulation Studio

When developing without a live TPP trigger, use the built-in Gateway UI:
1. Tap **Test Incoming Link** to simulate cold-launching or receiving an App Link.
2. Tap **Simulate Handoff** to immediately test parameter extraction and opening `https://cbd-flutter.go.link/tpp?state=asa&code=asasa&issuer=asajsa` without needing an active bank session.
