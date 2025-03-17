package com.tapmap.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.tapmap.app/deep_links"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "Configuring Flutter Engine")
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "Received method call: ${call.method}")
            when (call.method) {
                "getInitialLink" -> {
                    val intent = intent
                    Log.d(TAG, "Checking initial intent: ${intent?.action}")
                    if (intent?.action == Intent.ACTION_VIEW) {
                        val uri = intent.data
                        Log.d(TAG, "Found URI: $uri")
                        if (uri != null) {
                            result.success(uri.toString())
                        } else {
                            Log.d(TAG, "URI is null")
                            result.success(null)
                        }
                    } else {
                        Log.d(TAG, "Not a VIEW action")
                        result.success(null)
                    }
                }
                else -> {
                    Log.d(TAG, "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "Received new intent: ${intent.action}")
        setIntent(intent)
        val uri = intent.data
        if (uri != null) {
            Log.d(TAG, "Processing deep link: $uri")
            MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CHANNEL)
                .invokeMethod("handleDeepLink", mapOf("url" to uri.toString()))
        } else {
            Log.d(TAG, "No URI in new intent")
        }
    }
} 