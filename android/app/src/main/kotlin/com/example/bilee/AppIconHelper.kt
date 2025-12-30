package com.example.bilee

import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class AppIconHelper {
    companion object {
        private const val CHANNEL = "com.example.bilee/app_icon"

        fun setupMethodChannel(flutterEngine: FlutterEngine, activity: FlutterActivity) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppIcon" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            try {
                                val iconBytes = getAppIcon(activity.packageManager, packageName)
                                result.success(iconBytes)
                            } catch (e: Exception) {
                                result.error("ICON_ERROR", "Failed to get icon for $packageName", e.message)
                            }
                        } else {
                            result.error("INVALID_ARGUMENT", "packageName is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }

        private fun getAppIcon(packageManager: PackageManager, packageName: String): ByteArray? {
            return try {
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                val icon: Drawable = packageManager.getApplicationIcon(appInfo)
                val bitmap = drawableToBitmap(icon)
                
                // Compress bitmap to byte array
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                stream.toByteArray()
            } catch (e: PackageManager.NameNotFoundException) {
                null
            }
        }

        private fun drawableToBitmap(drawable: Drawable): Bitmap {
            if (drawable is BitmapDrawable) {
                return drawable.bitmap
            }

            val bitmap = Bitmap.createBitmap(
                drawable.intrinsicWidth,
                drawable.intrinsicHeight,
                Bitmap.Config.ARGB_8888
            )

            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)

            return bitmap
        }
    }
}
