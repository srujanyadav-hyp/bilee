package com.example.bilee

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Setup UPI chooser method channel
        UpiChooserHelper.setupMethodChannel(flutterEngine, this)
    }
}
