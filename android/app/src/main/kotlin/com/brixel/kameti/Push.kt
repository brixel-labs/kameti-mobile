package com.brixel.kameti

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.brixel.kameti.feature.shell.PushCenter
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Push plumbing that needs the app itself: Firebase, the notification
 * channel, and what happens when a notification arrives or is tapped.
 * Everything the screens need goes through [PushCenter].
 */
object Push {
    const val CHANNEL_ID = "kameti"

    /** Call once at app start. Without `google-services.json` the app runs, just without push. */
    fun start(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, context.getString(R.string.notification_channel_name), NotificationManager.IMPORTANCE_DEFAULT,
            ).apply { description = context.getString(R.string.notification_channel_description) }
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
        if (FirebaseApp.getApps(context).isEmpty()) return
        FirebaseMessaging.getInstance().token.addOnSuccessListener { token -> PushCenter.token.value = token }
    }

    /** A notification the app was opened from: hand it to [PushCenter]. Returns whether [intent] was one. */
    fun handleTap(intent: Intent): Boolean {
        val kind = intent.getStringExtra(PushCenter.EXTRA_KIND) ?: return false
        PushCenter.handleTap(kind, intent.getStringExtra(PushCenter.EXTRA_KAMETI_ID))
        // So a rotation or coming back doesn't open it again.
        intent.removeExtra(PushCenter.EXTRA_KIND)
        return true
    }
}

class KametiMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        PushCenter.token.value = token
    }

    /**
     * Called only while the app is open (in the background Android shows the
     * notification itself): still show it, like the banner on iOS.
     */
    override fun onMessageReceived(message: RemoteMessage) {
        val shown = message.notification ?: return
        val allowed = Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        if (!allowed) return
        val open = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            .putExtra(PushCenter.EXTRA_KIND, message.data[PushCenter.EXTRA_KIND].orEmpty())
            .putExtra(PushCenter.EXTRA_KAMETI_ID, message.data[PushCenter.EXTRA_KAMETI_ID])
        val id = (message.data["notification_id"] ?: message.messageId ?: shown.title.orEmpty()).hashCode()
        val tap = PendingIntent.getActivity(this, id, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(this, Push.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(shown.title)
            .setContentText(shown.body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(shown.body))
            .setAutoCancel(true)
            .setContentIntent(tap)
            .build()
        NotificationManagerCompat.from(this).notify(id, notification)
    }
}
