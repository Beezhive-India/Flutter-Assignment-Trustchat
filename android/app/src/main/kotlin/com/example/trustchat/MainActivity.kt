package com.example.trustchat

import io.flutter.embedding.android.FlutterActivity
import android.view.WindowManager;

class MainActivity: FlutterActivity() {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE);
    }

}
