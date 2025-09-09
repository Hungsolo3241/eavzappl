package com.blerdguild.eavzappl

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle // Import Bundle
import android.view.WindowManager // Import WindowManager

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
