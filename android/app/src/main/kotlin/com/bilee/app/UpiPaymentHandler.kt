package com.bilee.app

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * UPI Payment Handler for Android
 * Handles UPI payment intents and returns results to Flutter
 */
class UpiPaymentHandler(private val activity: Activity) : PluginRegistry.ActivityResultListener {
    companion object {
        private const val CHANNEL_NAME = "com.bilee.upi/payment"
        private const val UPI_PAYMENT_REQUEST_CODE = 1001
    }

    private var methodChannel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null

    fun setupChannel(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUpiApps" -> {
                    result.success(hasUpiApps())
                }
                "getUpiApps" -> {
                    result.success(getInstalledUpiApps())
                }
                "initiatePayment" -> {
                    initiateUpiPayment(call.arguments as Map<String, Any>, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Check if device has UPI apps installed
     */
    private fun hasUpiApps(): Boolean {
        val upiIntent = Intent(Intent.ACTION_VIEW, Uri.parse("upi://pay"))
        val packageManager = activity.packageManager
        val activities = packageManager.queryIntentActivities(upiIntent, PackageManager.MATCH_DEFAULT_ONLY)
        return activities.isNotEmpty()
    }

    /**
     * Get list of installed UPI apps
     */
    private fun getInstalledUpiApps(): List<Map<String, String>> {
        val upiIntent = Intent(Intent.ACTION_VIEW, Uri.parse("upi://pay"))
        val packageManager = activity.packageManager
        val activities = packageManager.queryIntentActivities(upiIntent, PackageManager.MATCH_DEFAULT_ONLY)

        return activities.map { resolveInfo ->
            mapOf(
                "packageName" to resolveInfo.activityInfo.packageName,
                "appName" to resolveInfo.loadLabel(packageManager).toString()
            )
        }
    }

    /**
     * Initiate UPI payment
     */
    private fun initiateUpiPayment(arguments: Map<String, Any>, result: MethodChannel.Result) {
        try {
            val pa = arguments["pa"] as? String ?: throw Exception("Missing payee address")
            val pn = arguments["pn"] as? String ?: throw Exception("Missing payee name")
            val tr = arguments["tr"] as? String ?: throw Exception("Missing transaction ref")
            val tn = arguments["tn"] as? String ?: throw Exception("Missing transaction note")
            val am = arguments["am"] as? String ?: throw Exception("Missing amount")
            val cu = arguments["cu"] as? String ?: "INR"
            val preferredApp = arguments["preferredApp"] as? String

            // Build UPI URI
            val uriBuilder = Uri.Builder()
                .scheme("upi")
                .authority("pay")
                .appendQueryParameter("pa", pa)
                .appendQueryParameter("pn", pn)
                .appendQueryParameter("tr", tr)
                .appendQueryParameter("tn", tn)
                .appendQueryParameter("am", am)
                .appendQueryParameter("cu", cu)

            val uri = uriBuilder.build()

            // Create intent
            val intent = Intent(Intent.ACTION_VIEW, uri)

            // If preferred app is specified, set package
            if (!preferredApp.isNullOrEmpty()) {
                intent.setPackage(preferredApp)
            }

            // Check if any app can handle this intent
            val packageManager = activity.packageManager
            val activities = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)

            if (activities.isEmpty()) {
                result.error("NO_UPI_APP", "No UPI app found to handle payment", null)
                return
            }

            // Store result for later
            pendingResult = result

            // Launch UPI app
            activity.startActivityForResult(intent, UPI_PAYMENT_REQUEST_CODE)

        } catch (e: Exception) {
            result.error("PAYMENT_ERROR", e.message, null)
        }
    }

    /**
     * Handle activity result from UPI app
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == UPI_PAYMENT_REQUEST_CODE) {
            val result = pendingResult ?: return false

            if (resultCode == Activity.RESULT_OK && data != null) {
                // Parse UPI response
                val response = data.getStringExtra("response") ?: ""
                val responseMap = parseUpiResponse(response)

                result.success(responseMap)
            } else {
                // Payment cancelled or failed
                result.success(mapOf(
                    "status" to "failed",
                    "error" to "Payment cancelled or failed"
                ))
            }

            pendingResult = null
            return true
        }
        return false
    }

    /**
     * Parse UPI response string into map
     * UPI response format: key1=value1&key2=value2&...
     */
    private fun parseUpiResponse(response: String): Map<String, String> {
        val map = mutableMapOf<String, String>()

        if (response.isEmpty()) {
            map["status"] = "failed"
            map["error"] = "Empty response from UPI app"
            return map
        }

        // Parse response string
        response.split("&").forEach { pair ->
            val parts = pair.split("=")
            if (parts.size == 2) {
                map[parts[0].lowercase()] = parts[1]
            }
        }

        // Normalize status field
        val status = map["status"]?.lowercase() ?: "failed"
        map["status"] = when (status) {
            "success" -> "success"
            "submitted" -> "submitted"
            else -> "failed"
        }

        return map
    }
}
