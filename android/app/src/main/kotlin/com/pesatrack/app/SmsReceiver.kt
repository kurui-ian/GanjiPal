package com.pesatrack.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.telephony.SmsMessage
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * BroadcastReceiver for incoming SMS messages.
 * Performs minimal execution on the broadcast thread:
 * 1. Confirms whether the SMS is an M-Pesa transaction confirmation.
 * 2. Caches pending messages in SharedPreferences for reliable consumption by Flutter.
 * 3. Notifies MainActivity if the app process is currently active.
 */
class SmsReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "PesaTrackSmsReceiver"
        const val PREFS_NAME = "pesatrack_sms_cache"
        const val KEY_PENDING_SMS = "pending_m_pesa_sms"

        fun getAndClearPendingSms(context: Context): List<String> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val raw = prefs.getString(KEY_PENDING_SMS, null) ?: return emptyList()
            val list = mutableListOf<String>()
            try {
                val array = JSONArray(raw)
                for (i in 0 until array.length()) {
                    val item = array.getJSONObject(i)
                    list.add(item.getString("body"))
                }
                prefs.edit().remove(KEY_PENDING_SMS).apply()
            } catch (e: Exception) {
                Log.e(TAG, "Error reading pending SMS cache", e)
            }
            return list
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            return
        }

        try {
            val messages: Array<SmsMessage> = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
            val fullBodyBuilder = StringBuilder()
            var sender = ""

            for (sms in messages) {
                fullBodyBuilder.append(sms.messageBody)
                if (sender.isEmpty() && sms.originatingAddress != null) {
                    sender = sms.originatingAddress ?: ""
                }
            }

            val fullBody = fullBodyBuilder.toString()

            // Confirm whether this message is from M-Pesa
            val isMpesaSender = sender.contains("MPESA", ignoreCase = true) ||
                    sender.contains("M-PESA", ignoreCase = true) ||
                    sender.contains("SAFARICOM", ignoreCase = true)
            val hasConfirmedPattern = fullBody.contains("Confirmed.", ignoreCase = true) ||
                    fullBody.contains("Confirmed ", ignoreCase = true)

            if (isMpesaSender || hasConfirmedPattern) {
                Log.d(TAG, "M-Pesa SMS detected. Caching for processing.")

                // Store in shared preferences queue
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val existing = prefs.getString(KEY_PENDING_SMS, "[]")
                val array = JSONArray(existing)
                val item = JSONObject()
                item.put("body", fullBody)
                item.put("sender", sender)
                item.put("timestamp", System.currentTimeMillis())
                array.put(item)

                prefs.edit().putString(KEY_PENDING_SMS, array.toString()).apply()

                // Notify running activity if attached
                MainActivity.instance?.notifySmsReceived(fullBody)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in SMS BroadcastReceiver", e)
        }
    }
}
