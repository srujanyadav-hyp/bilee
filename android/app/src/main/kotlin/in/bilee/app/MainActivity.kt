package `in`.bilee.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.bilee.app.UpiPaymentHandler

class MainActivity : FlutterActivity() {
    private var upiPaymentHandler: UpiPaymentHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup app icon fetcher method channel
        AppIconHelper.setupMethodChannel(flutterEngine, this)
        
        // Setup UPI payment handler
        upiPaymentHandler = UpiPaymentHandler(this)
        upiPaymentHandler?.setupChannel(flutterEngine)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        // Forward result to UPI payment handler
        upiPaymentHandler?.onActivityResult(requestCode, resultCode, data)
    }
}
