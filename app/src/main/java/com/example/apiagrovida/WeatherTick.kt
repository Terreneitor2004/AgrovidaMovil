package com.example.apiagrovida

import android.content.Context
import okhttp3.Request
import org.json.JSONArray
import java.util.concurrent.atomic.AtomicInteger

object WeatherTick {
    private val client = ApiClient.client
    private val baseUrl = ApiClient.BASE_URL
    private val weather = WeatherService()

    fun run(context: Context) {
        val req = Request.Builder().url("$baseUrl/terrenos").get().build()
        client.newCall(req).enqueue(object : okhttp3.Callback {
            override fun onFailure(call: okhttp3.Call, e: java.io.IOException) {
                // log opcional
            }

            override fun onResponse(call: okhttp3.Call, response: okhttp3.Response) {
                val body = response.body?.string() ?: return
                if (!response.isSuccessful) return
                try {
                    val arr = JSONArray(body)

                    if (arr.length() == 0) {
                        NotificationUtils.showNotification(
                            context, 1999, "Clima de tus terrenos", "No hay terrenos registrados"
                        )
                        return
                    }

                    val sb = StringBuilder()
                    val total = arr.length()
                    val done = AtomicInteger(0)

                    for (i in 0 until total) {
                        val t = arr.getJSONObject(i)
                        val nombre = t.getString("nombre")
                        val lat = t.getDouble("latitud")
                        val lon = t.getDouble("longitud")

                        weather.getWeather(lat, lon) { texto ->
                            synchronized(sb) { sb.appendLine("$nombre: $texto") }

                            if (done.incrementAndGet() == total) {
                                val resumen = sb.toString().trim().ifEmpty { "Sin datos de clima" }
                                NotificationUtils.showNotification(
                                    context, 1999, "Clima de tus terrenos", resumen
                                )
                            }
                        }
                    }
                } catch (_: Exception) { /* log opcional */ }
            }
        })
    }
}
