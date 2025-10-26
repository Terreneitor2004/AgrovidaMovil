package com.example.apiagrovida

import android.util.Log
import okhttp3.*
import org.json.JSONObject
import java.io.IOException

class WeatherService {

    private val client = ApiClient.client
    private val API_KEY = "d49f768bd5ea4f249972455f214cadfe"

    fun getWeather(lat: Double, lon: Double, callback: (String) -> Unit) {
        val url = "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&lang=es&appid=$API_KEY"
        val request = Request.Builder().url(url).build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e("WEATHER", "Error: ${e.message}", e)
                callback("No disponible (Error de red)")
            }

            override fun onResponse(call: Call, response: Response) {
                val data = response.body?.string()
                if (response.isSuccessful && data != null) {
                    try {
                        val obj = JSONObject(data)
                        val temp = obj.getJSONObject("main").getDouble("temp")
                        val desc = obj.getJSONArray("weather").getJSONObject(0).getString("description")
                        callback("${String.format("%.1f", temp)}°C, $desc")
                    } catch (e: Exception) {
                        callback("No disponible (Error de datos)")
                    }
                } else callback("No disponible")
            }
        })
    }
}
