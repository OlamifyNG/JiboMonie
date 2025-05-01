package com.jibojay.dev

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.jibomonie.logger"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "log" -> {
                    val message = call.argument<String>("message")
                    val level = call.argument<String>("level") ?: "info"
                    val timestamp = call.argument<String>("timestamp")
                    
                    val fullMessage = "[${timestamp ?: ""}] $message"
                    
                    when (level) {
                        "error" -> Log.e("JiboMonie", fullMessage)
                        "warning" -> Log.w("JiboMonie", fullMessage)
                        else -> Log.i("JiboMonie", fullMessage)
                    }
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}