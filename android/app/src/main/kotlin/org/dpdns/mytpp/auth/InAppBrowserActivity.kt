package org.dpdns.mytpp.auth

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView

/**
 * Native In-App Browser for OAuth Authorization.
 *
 * Loads the Bank Authorization portal (e.g. Open Finance AE APIHub) and intercepts
 * any OAuth redirection containing `code`, `state`, and `issuer` parameters.
 * Automatically closes upon detecting the redirection and returns the extracted
 * tokens to Flutter.
 */
class InAppBrowserActivity : Activity() {

    companion object {
        const val EXTRA_URL = "url"
        const val EXTRA_REDIRECT_URL = "redirect_url"
        const val EXTRA_CODE = "code"
        const val EXTRA_STATE = "state"
        const val EXTRA_ISSUER = "issuer"
        const val EXTRA_ERROR = "error"
        const val EXTRA_ERROR_DESCRIPTION = "error_description"

        private const val DEFAULT_ISSUER = "https://auth1.altareq1.sandbox.apihub.openfinance.ae"
    }

    private lateinit var webView: WebView
    private lateinit var progressBar: ProgressBar
    private lateinit var urlSubtitleView: TextView
    private var isRedirectHandled = false

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val targetUrl = intent.getStringExtra(EXTRA_URL)
        if (targetUrl.isNullOrBlank()) {
            setResult(RESULT_CANCELED)
            finish()
            return
        }

        // Build Programmatic UI to ensure zero resource-ID / XML dependencies
        val density = resources.displayMetrics.density
        fun dp(value: Float) = (value * density).toInt()

        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.WHITE)
        }

        // 1. App Bar Header (CBD Dark Slate / Dark Lime Fintech Styling)
        val headerLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(58f)
            )
            setBackgroundColor(Color.parseColor("#142E28")) // Deep CBD Dark Lime
            setPadding(dp(12f), 0, dp(12f), 0)
        }

        // Close Button (✕)
        val closeBtn = TextView(this).apply {
            text = "✕"
            textSize = 20f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(dp(40f), dp(40f))
            setOnClickListener {
                if (!isRedirectHandled) {
                    setResult(RESULT_CANCELED)
                    finish()
                }
            }
        }
        headerLayout.addView(closeBtn)

        // Title and Subtitle Container
        val titleContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f)
            setPadding(dp(8f), 0, dp(8f), 0)
        }

        val appTitleView = TextView(this).apply {
            text = "Model Bank Gateway"
            textSize = 15f
            setTextColor(Color.WHITE)
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        }
        titleContainer.addView(appTitleView)

        val initialHost = try {
            Uri.parse(targetUrl).host ?: "apihub.openfinance.ae"
        } catch (_: Exception) {
            "apihub.openfinance.ae"
        }

        urlSubtitleView = TextView(this).apply {
            text = "🔒 $initialHost"
            textSize = 11f
            setTextColor(Color.parseColor("#A3C293")) // CBD Light Lime accent
        }
        titleContainer.addView(urlSubtitleView)

        headerLayout.addView(titleContainer)

        // Reload Button (↻)
        val refreshBtn = TextView(this).apply {
            text = "↻"
            textSize = 22f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(dp(40f), dp(40f))
            setOnClickListener {
                webView.reload()
            }
        }
        headerLayout.addView(refreshBtn)

        rootLayout.addView(headerLayout)

        // 2. Horizontal Progress Bar
        progressBar = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(3f)
            )
            max = 100
            progress = 10
            val shape = GradientDrawable().apply {
                setColor(Color.parseColor("#76BC21")) // CBD Vivid Lime
            }
            progressDrawable = shape
        }
        rootLayout.addView(progressBar)

        // 3. WebView Container
        val webViewContainer = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1.0f
            )
        }

        webView = WebView(this).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.databaseEnabled = true
            settings.useWideViewPort = true
            settings.loadWithOverviewMode = true
            settings.cacheMode = WebSettings.LOAD_DEFAULT
            settings.setSupportZoom(true)
            settings.builtInZoomControls = true
            settings.displayZoomControls = false

            webChromeClient = object : WebChromeClient() {
                override fun onProgressChanged(view: WebView?, newProgress: Int) {
                    super.onProgressChanged(view, newProgress)
                    progressBar.progress = newProgress
                    if (newProgress >= 100) {
                        progressBar.visibility = View.GONE
                    } else {
                        progressBar.visibility = View.VISIBLE
                    }
                }

                override fun onReceivedTitle(view: WebView?, title: String?) {
                    super.onReceivedTitle(view, title)
                    if (!title.isNullOrBlank()) {
                        val currentHost = try {
                            Uri.parse(view?.url ?: targetUrl).host ?: "openfinance.ae"
                        } catch (_: Exception) {
                            "openfinance.ae"
                        }
                        urlSubtitleView.text = "🔒 $currentHost"
                    }
                }
            }

            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    val url = request?.url?.toString() ?: return false
                    if (checkForOAuthRedirection(url)) {
                        return true
                    }
                    return false
                }

                @Deprecated("Deprecated in Java")
                override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                    if (url == null) return false
                    if (checkForOAuthRedirection(url)) {
                        return true
                    }
                    return false
                }

                override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
                    super.onPageStarted(view, url, favicon)
                    if (url != null && checkForOAuthRedirection(url)) {
                        view?.stopLoading()
                    }
                }

                override fun doUpdateVisitedHistory(view: WebView?, url: String?, isReload: Boolean) {
                    super.doUpdateVisitedHistory(view, url, isReload)
                    if (url != null && checkForOAuthRedirection(url)) {
                        view?.stopLoading()
                    }
                }
            }
        }

        webViewContainer.addView(webView)
        rootLayout.addView(webViewContainer)

        setContentView(rootLayout)

        // Load bank auth URL
        webView.loadUrl(targetUrl)
    }

    /**
     * Checks if the given URL corresponds to an OAuth authorization redirection
     * containing `code`, `state`, or error responses, or targeting TPP callback endpoints.
     */
    private fun checkForOAuthRedirection(url: String): Boolean {
        if (isRedirectHandled) return true

        try {
            val uri = Uri.parse(url)

            // Extract parameters from Query or Fragment
            val code = uri.getQueryParameter("code") ?: extractFromFragment(url, "code")
            val state = uri.getQueryParameter("state") ?: extractFromFragment(url, "state")
            val issuer = uri.getQueryParameter("issuer")
                ?: uri.getQueryParameter("iss")
                ?: extractFromFragment(url, "issuer")
                ?: extractFromFragment(url, "iss")
                ?: DEFAULT_ISSUER

            val error = uri.getQueryParameter("error") ?: extractFromFragment(url, "error")
            val errorDescription = uri.getQueryParameter("error_description")
                ?: extractFromFragment(url, "error_description")

            // Redirection match criteria:
            // 1) Contains authorization `code`
            // 2) Matches `go.link`, `tpp`, or `mytpp` callback pattern
            // 3) Has OAuth error response with state
            val isSuccessRedirect = code != null
            val isTppCallback = url.contains("go.link") || url.contains("/tpp") || url.contains("mytpp")
            val isErrorRedirect = error != null

            if (isSuccessRedirect || isTppCallback || isErrorRedirect) {
                isRedirectHandled = true

                val resultIntent = Intent().apply {
                    putExtra(EXTRA_REDIRECT_URL, url)
                    if (code != null) putExtra(EXTRA_CODE, code)
                    if (state != null) putExtra(EXTRA_STATE, state)
                    putExtra(EXTRA_ISSUER, issuer)
                    if (error != null) putExtra(EXTRA_ERROR, error)
                    if (errorDescription != null) putExtra(EXTRA_ERROR_DESCRIPTION, errorDescription)
                }

                setResult(RESULT_OK, resultIntent)
                finish()
                return true
            }
        } catch (_: Exception) {
            // Continue loading if URI parsing fails
        }

        return false
    }

    private fun extractFromFragment(url: String, paramName: String): String? {
        val hashIdx = url.indexOf('#')
        if (hashIdx == -1 || hashIdx == url.length - 1) return null
        val fragment = url.substring(hashIdx + 1)
        val pairs = fragment.split('&')
        for (pair in pairs) {
            val idx = pair.indexOf('=')
            if (idx != -1) {
                val key = Uri.decode(pair.substring(0, idx))
                if (key == paramName) {
                    return Uri.decode(pair.substring(idx + 1))
                }
            }
        }
        return null
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            if (!isRedirectHandled) {
                setResult(RESULT_CANCELED)
            }
            super.onBackPressed()
        }
    }

    override fun onDestroy() {
        try {
            webView.stopLoading()
            webView.destroy()
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
