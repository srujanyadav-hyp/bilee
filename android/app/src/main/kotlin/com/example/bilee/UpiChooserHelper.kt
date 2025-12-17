package com.example.bilee

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class UpiChooserHelper {
    companion object {
        private const val CHANNEL = "com.example.bilee/upi_chooser"

        fun setupMethodChannel(flutterEngine: FlutterEngine, activity: MainActivity) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "launchUpiChooser" -> {
                            try {
                                val upiUri = call.argument<String>("upiUri")
                                if (upiUri == null) {
                                    result.error("INVALID_ARGUMENT", "URI cannot be null", null)
                                    return@setMethodCallHandler
                                }

                                val intent = Intent(Intent.ACTION_VIEW)
                                intent.data = Uri.parse(upiUri)
                                
                                // Create chooser to show all UPI apps
                                val chooser = Intent.createChooser(intent, "Pay using")
                                
                                // Verify there are apps that can handle this intent
                                if (intent.resolveActivity(activity.packageManager) != null) {
                                    activity.startActivity(chooser)
                                    result.success(true)
                                } else {
                                    result.error("NO_APP", "No UPI app found", null)
                                }
                            } catch (e: Exception) {
                                result.error("ERROR", e.message, null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                }
        }
    }
}
