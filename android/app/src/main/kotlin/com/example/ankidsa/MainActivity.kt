package com.example.ankidsa

import io.flutter.embedding.android.FlutterActivity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("ankidsa_reminders", "Review reminders", NotificationManager.IMPORTANCE_DEFAULT)
            channel.description = "A daily reminder when you have problems to revisit"
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}
