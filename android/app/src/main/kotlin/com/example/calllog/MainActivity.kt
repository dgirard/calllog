package com.example.calllog

import android.content.Intent
import android.provider.CallLog
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.calllog/call_log"
    private val SHARE_CHANNEL = "com.example.calllog/share"
    private var sharedText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Channel pour les appels
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCallsSince" -> {
                    val timestamp = call.argument<Long>("timestamp")
                    if (timestamp != null) {
                        val calls = getCallsSince(timestamp)
                        result.success(calls)
                    } else {
                        result.error("INVALID_ARGUMENT", "Timestamp is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Channel pour le partage
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedText" -> {
                    result.success(sharedText)
                    sharedText = null // Consommer le texte
                }
                else -> result.notImplemented()
            }
        }

        // Channel pour lancer des apps externes
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.calllog/launcher").setMethodCallHandler { call, result ->
            when (call.method) {
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val launched = launchApp(packageName)
                        result.success(launched)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
        }
    }

    private fun launchApp(packageName: String): Boolean {
        return try {
            // Essayer d'abord avec getLaunchIntentForPackage
            var intent = packageManager.getLaunchIntentForPackage(packageName)

            if (intent == null) {
                // Fallback: créer un intent ACTION_MAIN explicite
                intent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    setPackage(packageName)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }

                // Vérifier si une activité peut gérer cet intent
                val activities = packageManager.queryIntentActivities(intent, 0)
                if (activities.isEmpty()) {
                    return false
                }
            }

            startActivity(intent)
            true
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error launching app: ${e.message}")
            false
        }
    }

    private fun getCallsSince(timestamp: Long): List<Map<String, Any>> {
        val calls = mutableListOf<Map<String, Any>>()

        try {
            val projection = arrayOf(
                CallLog.Calls.NUMBER,
                CallLog.Calls.DATE,
                CallLog.Calls.TYPE,
                CallLog.Calls.DURATION
            )

            val selection = "${CallLog.Calls.DATE} >= ?"
            val selectionArgs = arrayOf(timestamp.toString())
            val sortOrder = "${CallLog.Calls.DATE} DESC"

            val cursor = contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                sortOrder
            )

            cursor?.use {
                val numberIndex = it.getColumnIndex(CallLog.Calls.NUMBER)
                val dateIndex = it.getColumnIndex(CallLog.Calls.DATE)
                val typeIndex = it.getColumnIndex(CallLog.Calls.TYPE)
                val durationIndex = it.getColumnIndex(CallLog.Calls.DURATION)

                while (it.moveToNext()) {
                    val call = mapOf(
                        "number" to it.getString(numberIndex),
                        "date" to it.getLong(dateIndex),
                        "type" to it.getInt(typeIndex),
                        "duration" to it.getInt(durationIndex)
                    )
                    calls.add(call)
                }
            }
        } catch (e: Exception) {
            // Log l'erreur mais ne crash pas
            e.printStackTrace()
        }

        return calls
    }
}
