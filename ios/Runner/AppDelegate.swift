import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let url = launchOptions?[.url] as? URL {
      ModelBankGatewayManager.shared.handleDeepLink(url.absoluteString)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    ModelBankGatewayManager.shared.configure(with: engineBridge.pluginRegistry)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    ModelBankGatewayManager.shared.handleDeepLink(url.absoluteString)
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      ModelBankGatewayManager.shared.handleDeepLink(url.absoluteString)
      return true
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}

// MARK: - Model Bank Gateway Platform Channel Manager

class ModelBankGatewayManager: NSObject {
  static let shared = ModelBankGatewayManager()

  private static let channelName = "org.modelbank/gateway"
  private var channel: FlutterMethodChannel?
  private var initialDeepLink: String?

  private override init() {
    super.init()
  }

  func configure(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "ModelBankGatewayPlugin") else {
      return
    }
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: registrar.messenger())
    self.channel = channel

    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  func handleDeepLink(_ link: String) {
    guard isSupportedLink(link) else { return }

    if let channel = channel {
      channel.invokeMethod("onDeepLinkReceived", arguments: link)
    } else {
      initialDeepLink = link
    }
  }

  private func isSupportedLink(_ link: String) -> Bool {
    let lower = link.lowercased()
    return lower.hasPrefix("modelbank://") ||
           lower.hasPrefix("https://auth.mytpp.dpdns.org") ||
           lower.hasPrefix("http://auth.mytpp.dpdns.org") ||
           lower.hasPrefix("https://auth1.altareq1.sandbox.apihub.openfinance.ae") ||
           lower.hasPrefix("http://auth1.altareq1.sandbox.apihub.openfinance.ae")
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getInitialDeepLink":
      let link = initialDeepLink
      initialDeepLink = nil
      result(link)

    case "openInAppBrowser":
      guard let args = call.arguments as? [String: Any],
            let urlString = args["url"] as? String,
            let targetUrl = URL(string: urlString) else {
        result(FlutterError(code: "INVALID_URL", message: "Target auth URL is missing or invalid", details: nil))
        return
      }
      presentInAppBrowser(url: targetUrl, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func presentInAppBrowser(url: URL, result: @escaping FlutterResult) {
    guard let topVC = UIApplication.shared.topViewController() else {
      result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Cannot find root view controller", details: nil))
      return
    }

    let browserVC = InAppBrowserViewController(targetUrl: url) { resultMap in
      result(resultMap)
    }
    browserVC.modalPresentationStyle = .fullScreen
    topVC.present(browserVC, animated: true, completion: nil)
  }
}

// MARK: - Native In-App Browser for OAuth Authorization

class InAppBrowserViewController: UIViewController, WKNavigationDelegate, UIAdaptivePresentationControllerDelegate {

  private let targetUrl: URL
  private var completion: (([String: Any]) -> Void)?
  private var isRedirectHandled = false

  private var webView: WKWebView!
  private var progressView: UIProgressView!
  private var subtitleLabel: UILabel!
  private var progressObserver: NSKeyValueObservation?

  private static let defaultIssuer = "https://auth1.altareq1.sandbox.apihub.openfinance.ae"

  init(targetUrl: URL, completion: @escaping ([String: Any]) -> Void) {
    self.targetUrl = targetUrl
    self.completion = completion
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    presentationController?.delegate = self
    setupUI()
    loadUrl()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent || isBeingDismissed {
      if !isRedirectHandled {
        isRedirectHandled = true
        completion?([
          "success": false,
          "cancelled": true,
          "message": "In-app browser authorization was closed or cancelled by user."
        ])
        completion = nil
      }
    }
  }

  deinit {
    progressObserver?.invalidate()
    webView?.stopLoading()
    webView?.navigationDelegate = nil
  }

  private func setupUI() {
    // 1. Header Bar Container (CBD Deep Dark Lime #142E28)
    let headerBackground = UIView()
    headerBackground.backgroundColor = UIColor(red: 0x14/255.0, green: 0x2E/255.0, blue: 0x28/255.0, alpha: 1.0)
    headerBackground.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(headerBackground)

    let headerContent = UIView()
    headerContent.translatesAutoresizingMaskIntoConstraints = false
    headerBackground.addSubview(headerContent)

    // Close Button (✕)
    let closeButton = UIButton(type: .system)
    closeButton.setTitle("✕", for: .normal)
    closeButton.setTitleColor(.white, for: .normal)
    closeButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
    headerContent.addSubview(closeButton)

    // Refresh Button (↻)
    let refreshButton = UIButton(type: .system)
    refreshButton.setTitle("↻", for: .normal)
    refreshButton.setTitleColor(.white, for: .normal)
    refreshButton.titleLabel?.font = .systemFont(ofSize: 22, weight: .regular)
    refreshButton.translatesAutoresizingMaskIntoConstraints = false
    refreshButton.addTarget(self, action: #selector(didTapReload), for: .touchUpInside)
    headerContent.addSubview(refreshButton)

    // Title and Subtitle Stack
    let titleStack = UIStackView()
    titleStack.axis = .vertical
    titleStack.alignment = .center
    titleStack.distribution = .fillProportionally
    titleStack.spacing = 2
    titleStack.translatesAutoresizingMaskIntoConstraints = false

    let titleLabel = UILabel()
    titleLabel.text = "Model Bank Gateway"
    titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
    titleLabel.textColor = .white
    titleStack.addArrangedSubview(titleLabel)

    let host = targetUrl.host ?? "apihub.openfinance.ae"
    subtitleLabel = UILabel()
    subtitleLabel.text = "🔒 \(host)"
    subtitleLabel.font = .systemFont(ofSize: 11, weight: .regular)
    subtitleLabel.textColor = UIColor(red: 0xA3/255.0, green: 0xC2/255.0, blue: 0x93/255.0, alpha: 1.0) // CBD Light Lime accent
    titleStack.addArrangedSubview(subtitleLabel)

    headerContent.addSubview(titleStack)

    // 2. Progress Bar (CBD Vivid Lime #76BC21)
    progressView = UIProgressView(progressViewStyle: .default)
    progressView.progressTintColor = UIColor(red: 0x76/255.0, green: 0xBC/255.0, blue: 0x21/255.0, alpha: 1.0)
    progressView.trackTintColor = .clear
    progressView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(progressView)

    // 3. WKWebView
    let config = WKWebViewConfiguration()
    config.defaultWebpagePreferences.allowsContentJavaScript = true
    config.allowsInlineMediaPlayback = true

    webView = WKWebView(frame: .zero, configuration: config)
    webView.navigationDelegate = self
    webView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(webView)

    // Layout Constraints
    NSLayoutConstraint.activate([
      headerBackground.topAnchor.constraint(equalTo: view.topAnchor),
      headerBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      headerBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      headerBackground.bottomAnchor.constraint(equalTo: headerContent.bottomAnchor),

      headerContent.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      headerContent.leadingAnchor.constraint(equalTo: headerBackground.leadingAnchor),
      headerContent.trailingAnchor.constraint(equalTo: headerBackground.trailingAnchor),
      headerContent.heightAnchor.constraint(equalToConstant: 48),

      closeButton.leadingAnchor.constraint(equalTo: headerContent.leadingAnchor, constant: 8),
      closeButton.centerYAnchor.constraint(equalTo: headerContent.centerYAnchor),
      closeButton.widthAnchor.constraint(equalToConstant: 44),
      closeButton.heightAnchor.constraint(equalToConstant: 44),

      refreshButton.trailingAnchor.constraint(equalTo: headerContent.trailingAnchor, constant: -8),
      refreshButton.centerYAnchor.constraint(equalTo: headerContent.centerYAnchor),
      refreshButton.widthAnchor.constraint(equalToConstant: 44),
      refreshButton.heightAnchor.constraint(equalToConstant: 44),

      titleStack.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 8),
      titleStack.trailingAnchor.constraint(equalTo: refreshButton.leadingAnchor, constant: -8),
      titleStack.centerYAnchor.constraint(equalTo: headerContent.centerYAnchor),

      progressView.topAnchor.constraint(equalTo: headerBackground.bottomAnchor),
      progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      progressView.heightAnchor.constraint(equalToConstant: 3),

      webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    // Progress KVO Observer
    progressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
      DispatchQueue.main.async {
        let progress = Float(webView.estimatedProgress)
        self?.progressView.setProgress(progress, animated: true)
        self?.progressView.isHidden = (progress >= 1.0)
      }
    }
  }

  private func loadUrl() {
    let request = URLRequest(url: targetUrl)
    webView.load(request)
  }

  @objc private func didTapClose() {
    if !isRedirectHandled {
      isRedirectHandled = true
      dismiss(animated: true) { [weak self] in
        self?.completion?([
          "success": false,
          "cancelled": true,
          "message": "In-app browser authorization was closed or cancelled by user."
        ])
        self?.completion = nil
      }
    }
  }

  @objc private func didTapReload() {
    webView.reload()
  }

  // MARK: - Redirection & Parameter Interception

  private func checkForOAuthRedirection(url: URL) -> Bool {
    if isRedirectHandled { return true }

    let urlString = url.absoluteString

    var params: [String: String] = [:]
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
      components.queryItems?.forEach { item in
        params[item.name] = item.value
      }
      if let fragment = components.fragment {
        let pairs = fragment.split(separator: "&")
        for pair in pairs {
          let parts = pair.split(separator: "=", maxSplits: 1)
          if parts.count == 2 {
            let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
            let val = String(parts[1]).removingPercentEncoding ?? String(parts[1])
            params[key] = val
          }
        }
      }
    }

    let code = params["code"]
    let state = params["state"]
    let issuer = params["issuer"] ?? params["iss"] ?? Self.defaultIssuer
    let error = params["error"]
    let errorDescription = params["error_description"]

    let lowerUrl = urlString.lowercased()
    let isSuccessRedirect = (code != nil)
    let isTppCallback = lowerUrl.contains("go.link") || lowerUrl.contains("/tpp") || lowerUrl.contains("mytpp") || lowerUrl.contains("cbdflutter")
    let isErrorRedirect = (error != nil)

    if isSuccessRedirect || isTppCallback || isErrorRedirect {
      isRedirectHandled = true
      webView.stopLoading()

      var resultMap: [String: Any] = [
        "success": isSuccessRedirect || (!isErrorRedirect && isTppCallback),
        "cancelled": false,
        "redirectUrl": urlString,
        "issuer": issuer
      ]
      if let code = code { resultMap["code"] = code }
      if let state = state { resultMap["state"] = state }
      if let error = error { resultMap["error"] = error }
      if let errorDescription = errorDescription { resultMap["errorDescription"] = errorDescription }

      dismiss(animated: true) { [weak self] in
        self?.completion?(resultMap)
        self?.completion = nil
      }
      return true
    }

    return false
  }

  // MARK: - WKNavigationDelegate

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    if let url = navigationAction.request.url, checkForOAuthRedirection(url: url) {
      decisionHandler(.cancel)
      return
    }
    decisionHandler(.allow)
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationResponse: WKNavigationResponse,
    decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
  ) {
    if let url = navigationResponse.response.url, checkForOAuthRedirection(url: url) {
      decisionHandler(.cancel)
      return
    }
    decisionHandler(.allow)
  }

  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    if let url = webView.url, checkForOAuthRedirection(url: url) {
      webView.stopLoading()
    }
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    if let host = webView.url?.host {
      subtitleLabel.text = "🔒 \(host)"
    }
  }

  // MARK: - UIAdaptivePresentationControllerDelegate

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    if !isRedirectHandled {
      isRedirectHandled = true
      completion?([
        "success": false,
        "cancelled": true,
        "message": "In-app browser authorization was closed or cancelled by user."
      ])
      completion = nil
    }
  }
}

// MARK: - Top View Controller Helper

private extension UIApplication {
  func topViewController(base: UIViewController? = nil) -> UIViewController? {
    let baseVC = base ?? connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController

    if let nav = baseVC as? UINavigationController {
      return topViewController(base: nav.visibleViewController)
    }
    if let tab = baseVC as? UITabBarController {
      if let selected = tab.selectedViewController {
        return topViewController(base: selected)
      }
    }
    if let presented = baseVC?.presentedViewController {
      return topViewController(base: presented)
    }
    return baseVC
  }
}
