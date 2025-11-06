package com.example.apiagrovida

import android.content.Context
import android.util.Log
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Marker
import com.google.android.gms.maps.model.MarkerOptions
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import androidx.core.content.ContextCompat



class TerrenoRepository {
    private val client = ApiClient.client
    private val baseUrl = ApiClient.BASE_URL
    private val weatherService = WeatherService()

    // URL del receptor PHP (ajústala si cambia la ruta)
    private val phpReceiverUrl = "http://34.132.245.216/Screens/recibeLands.php"

    // GUARDAR TERRENO (agrega propietario)
    fun guardarTerreno(
        nombre: String,
        propietario: String,
        latLng: LatLng,
        map: GoogleMap,
        markerMap: MutableMap<Marker, Int>,
        context: Context
    ) {
        val json = JSONObject()
            .put("nombre", nombre)
            .put("propietario", propietario)
            .put("latitud", latLng.latitude)
            .put("longitud", latLng.longitude)

        val body = json.toString()
            .toRequestBody("application/json; charset=utf-8".toMediaTypeOrNull())

        val request = Request.Builder()
            .url("$baseUrl/terrenos")
            .post(body)
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                (context as AppCompatActivity).runOnUiThread {
                    Toast.makeText(context, "Error de red: ${e.message}", Toast.LENGTH_LONG).show()
                }
            }

            override fun onResponse(call: Call, response: Response) {
                val respBody = response.body?.string()
                (context as AppCompatActivity).runOnUiThread {
                    if (response.isSuccessful && respBody != null) {
                        try {
                            val id = JSONObject(respBody).getInt("id")

                            // Enviar automáticamente al PHP con el JSON solicitado
                            enviarTerrenoAlPhp(
                                id = id,
                                nombre = nombre,
                                propietario = propietario,
                                lat = latLng.latitude,
                                lon = latLng.longitude
                            )

                            val tituloBase = if (propietario.isNotEmpty())
                                "$nombre — $propietario" else nombre

                            val marker = map.addMarker(
                                MarkerOptions()
                                    .position(latLng)
                                    .title(tituloBase)
                                    .icon(MapUtils.markerFromVector(context as AppCompatActivity, R.drawable.baseline_add_location_24,
                                        ContextCompat.getColor(context, R.color.purple_500)))
                            )
                            if (marker != null) markerMap[marker] = id

                            weatherService.getWeather(latLng.latitude, latLng.longitude) { clima ->
                                (context).runOnUiThread {
                                    marker?.title = "$tituloBase — $clima"
                                }
                            }

                            Toast.makeText(context, "Terreno guardado", Toast.LENGTH_SHORT).show()
                        } catch (e: Exception) {
                            Toast.makeText(context, "Error al obtener ID", Toast.LENGTH_SHORT).show()
                        }
                    } else {
                        Toast.makeText(context, "Error del servidor: $respBody", Toast.LENGTH_LONG).show()
                    }
                }
            }
        })
    }

    // CARGAR TERRENOS (lee y muestra propietario si viene en el JSON)
    fun cargarTerrenos(
        map: GoogleMap,
        markerMap: MutableMap<Marker, Int>,
        context: Context
    ) {
        val request = Request.Builder().url("$baseUrl/terrenos").get().build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                (context as AppCompatActivity).runOnUiThread {
                    Toast.makeText(context, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }

            override fun onResponse(call: Call, response: Response) {
                val respBody = response.body?.string()
                (context as AppCompatActivity).runOnUiThread {
                    if (response.isSuccessful && respBody != null) {
                        try {
                            val array = JSONArray(respBody)
                            for (i in 0 until array.length()) {
                                val t = array.getJSONObject(i)
                                val id = t.getInt("id")
                                val lat = t.getDouble("latitud")
                                val lon = t.getDouble("longitud")
                                val nombre = t.getString("nombre")
                                val propietario = t.optString("propietario", "")
                                val latLng = LatLng(lat, lon)

                                val tituloBase = if (propietario.isNotEmpty())
                                    "$nombre — $propietario" else nombre

                                val marker = map.addMarker(
                                    MarkerOptions()
                                        .position(latLng)
                                        .title(tituloBase)
                                        .icon(MapUtils.markerFromVector(context as AppCompatActivity, R.drawable.baseline_add_location_24,
                                            ContextCompat.getColor(context, R.color.purple_500)))
                                )

                                if (marker != null) markerMap[marker] = id

                                weatherService.getWeather(lat, lon) { clima ->
                                    (context).runOnUiThread {
                                        marker?.title = "$tituloBase — $clima"
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            Log.e("TERR_REPO", "Error parseando terrenos", e)
                        }
                    }
                }
            }
        })
    }

    // ELIMINAR TERRENO
    fun eliminarTerreno(
        terrenoId: Int,
        map: GoogleMap,
        markerMap: MutableMap<Marker, Int>,
        context: Context
    ) {
        val request = Request.Builder()
            .url("$baseUrl/terrenos/$terrenoId")
            .delete()
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                (context as AppCompatActivity).runOnUiThread {
                    Toast.makeText(context, "Error al eliminar terreno: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }

            override fun onResponse(call: Call, response: Response) {
                (context as AppCompatActivity).runOnUiThread {
                    if (response.isSuccessful) {
                        val markerAEliminar = markerMap.entries.find { it.value == terrenoId }?.key
                        markerAEliminar?.remove()
                        markerMap.remove(markerAEliminar)
                        Toast.makeText(context, "Terreno eliminado correctamente", Toast.LENGTH_SHORT).show()
                    } else {
                        Toast.makeText(context, "Error del servidor al eliminar", Toast.LENGTH_SHORT).show()
                    }
                }
            }
        })
    }

    // Envía el JSON al PHP: construye { id_global, latitud, longitud, nombre, propietario }
    private fun enviarTerrenoAlPhp(
        id: Int,
        nombre: String,
        propietario: String,
        lat: Double,
        lon: Double
    ) {
        val payload = JSONObject()
            // Si quieres que sea exactamente "22_carlos", cambia a .put("id_global", "22_carlos")
            .put("id_global", "${id}_${propietario.ifEmpty { "sinprop" }}")
            .put("latitud", lat)
            .put("longitud", lon)
            .put("nombre", nombre)
            .put("propietario", propietario)

        val body = payload.toString()
            .toRequestBody("application/json; charset=utf-8".toMediaTypeOrNull())

        val req = Request.Builder()
            .url(phpReceiverUrl)
            .post(body)
            .build()

        client.newCall(req).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e("PHP_POST", "Error enviando a PHP: ${e.message}", e)
            }

            override fun onResponse(call: Call, response: Response) {
                val resp = response.body?.string()
                Log.d("PHP_POST", "Respuesta PHP: ${response.code} | $resp")
                response.close()
            }
        })
    }
}
