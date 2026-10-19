package org.dpdns.mytpp.auth

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL_NAME = "org.modelbank/gateway"
        private const val REQUEST_CODE_BROWSER = 1001
    }

    private var channel: MethodChannel? = null
    private var initialDeepLink: String? = null
    private var pendingBrowserResult: MethodChannel.Result? = null

    private fun isSupportedLink(link: String): Boolean {
        return link.startsWith("modelbank://", ignoreCase = true) ||
               link.startsWith("https://auth.mytpp.dpdns.org", ignoreCase = true) ||
               link.startsWith("http://auth.mytpp.dpdns.org", ignoreCase = true) ||
               link.startsWith("https://auth1.altareq1.sandbox.apihub.openfinance.ae", ignoreCase = true) ||
               link.startsWith("http://auth1.altareq1.sandbox.apihub.openfinance.ae", ignoreCase = true)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val data = intent?.dataString
        if (!data.isNullOrBlank() && isSupportedLink(data)) {
            initialDeepLink = data
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val data = intent.dataString
        if (!data.isNullOrBlank() && isSupportedLink(data)) {
            channel?.invokeMethod("onDeepLinkReceived", data)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInitialDeepLink" -> {
                val link = initialDeepLink
                initialDeepLink = null // consume once
                result.success(link)
            }
            "openInAppBrowser" -> {
                val url = call.argument<String>("url")
                if (url.isNullOrBlank()) {
                    result.error("INVALID_URL", "Target auth URL is missing or empty", null)
                    return
                }

                pendingBrowserResult = result
                val intent = Intent(this, InAppBrowserActivity::class.java).apply {
                    putExtra(InAppBrowserActivity.EXTRA_URL, url)
                }
                startActivityForResult(intent, REQUEST_CODE_BROWSER)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_CODE_BROWSER) {
            val res = pendingBrowserResult
            pendingBrowserResult = null
            if (res == null) return

            if (resultCode == Activity.RESULT_OK && data != null) {
                val resultMap = mutableMapOf<String, Any?>()
                resultMap["success"] = true
                resultMap["cancelled"] = false
                resultMap["redirectUrl"] = data.getStringExtra(InAppBrowserActivity.EXTRA_REDIRECT_URL)
                resultMap["code"] = data.getStringExtra(InAppBrowserActivity.EXTRA_CODE)
                resultMap["state"] = data.getStringExtra(InAppBrowserActivity.EXTRA_STATE)
                resultMap["issuer"] = data.getStringExtra(InAppBrowserActivity.EXTRA_ISSUER)
                resultMap["error"] = data.getStringExtra(InAppBrowserActivity.EXTRA_ERROR)
                resultMap["errorDescription"] = data.getStringExtra(InAppBrowserActivity.EXTRA_ERROR_DESCRIPTION)
                res.success(resultMap)
            } else {
                res.success(mapOf(
                    "success" to false,
                    "cancelled" to true,
                    "message" to "In-app browser authorization was closed or cancelled by user."
                ))
            }
        }
    }
}
