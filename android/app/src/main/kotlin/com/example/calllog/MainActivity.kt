package com.example.calllog

import android.provider.CallLog
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.calllog/call_log"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
