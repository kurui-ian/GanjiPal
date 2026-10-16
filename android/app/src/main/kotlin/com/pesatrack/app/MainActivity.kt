package com.pesatrack.app

import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.pesatrack.app/sms_channel"
        private const val TAG = "PesaTrackMainActivity"
        var instance: MainActivity? = null
    }

    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingSms" -> {
                    val list = SmsReceiver.getAndClearPendingSms(context)
                    result.success(list)
                }

                "queryInboxSms" -> {
                    val limit = call.argument<Int>("limit") ?: 100
                    val sinceTimestamp = call.argument<Long>("sinceTimestamp") ?: 0L
                    try {
                        val messages = queryMpesaInboxMessages(limit, sinceTimestamp)
                        result.success(messages)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error querying SMS inbox", e)
                        result.error("QUERY_ERROR", e.message, null)
                    }
                }

                "openAppSettings" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", packageName, null)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    fun notifySmsReceived(body: String) {
        runOnUiThread {
            methodChannel?.invokeMethod("onSmsReceived", body)
        }
    }

    private fun queryMpesaInboxMessages(limit: Int, sinceTimestamp: Long): List<Map<String, Any>> {
        val results = mutableListOf<Map<String, Any>>()
        val uri = Uri.parse("content://sms/inbox")
        val projection = arrayOf("_id", "address", "body", "date")
        val selection = if (sinceTimestamp > 0L) "date >= ?" else null
        val selectionArgs = if (sinceTimestamp > 0L) arrayOf(sinceTimestamp.toString()) else null
        val sortOrder = "date DESC"

        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)
            if (cursor != null && cursor.moveToFirst()) {
                val bodyIndex = cursor.getColumnIndex("body")
                val addressIndex = cursor.getColumnIndex("address")
                val dateIndex = cursor.getColumnIndex("date")

                do {
                    val body = cursor.getString(bodyIndex) ?: ""
                    val address = cursor.getString(addressIndex) ?: ""
                    val date = cursor.getLong(dateIndex)

                    val isMpesa = address.contains("MPESA", ignoreCase = true) ||
                            address.contains("M-PESA", ignoreCase = true) ||
                            body.contains("Confirmed.", ignoreCase = true) ||
                            body.contains("Confirmed ", ignoreCase = true)

                    if (isMpesa) {
                        val map = HashMap<String, Any>()
                        map["body"] = body
                        map["address"] = address
                        map["date"] = date
                        results.add(map)
                        if (results.size >= limit) {
                            break
                        }
                    }
                } while (cursor.moveToNext())
            }
        } finally {
            cursor?.close()
        }

        return results
    }
}
