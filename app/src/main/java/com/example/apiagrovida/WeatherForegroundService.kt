package com.example.apiagrovida

import android.app.Notification
import android.app.Service
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

class WeatherForegroundService : Service() {

    private val tag = "WeatherFGS"
    private val handler = Handler(Looper.getMainLooper())
    private val intervalMs = 5 * 60 * 1000L

    private val runnable = object : Runnable {
        override fun run() {
            try {
                WeatherTick.run(applicationContext)
            } catch (e: Throwable) {
                Log.e(tag, "Tick error", e)
            }
            handler.postDelayed(this, intervalMs)
        }
    }

    override fun onCreate() {
        super.onCreate()
        try {
            // Asegura el canal antes de construir la notificación
            NotificationUtils.ensureChannel(this)

            val ongoing: Notification = NotificationCompat.Builder(this, NotificationUtils.CHANNEL_ID)
                .setContentTitle("Clima de terrenos activo")
                .setContentText("Consultando clima cada 5 minutos")
                .setSmallIcon(android.R.drawable.ic_menu_compass)
                .setOngoing(true)
                .build()

            startForeground(12345, ongoing)

            handler.post(runnable)
        } catch (e: Throwable) {
            Log.e(tag, "Error al iniciar FGS", e)
            stopSelf()
        }
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
