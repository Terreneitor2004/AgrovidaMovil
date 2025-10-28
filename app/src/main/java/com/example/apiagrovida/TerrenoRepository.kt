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

class TerrenoRepository {
    private val client = ApiClient.client
    private val baseUrl = ApiClient.BASE_URL
    private val weatherService = WeatherService()
    //GUARDAR TERRENO
    fun guardarTerreno(
        nombre: String,
        latLng: LatLng,
        map: GoogleMap,
        markerMap: MutableMap<Marker, Int>,
        context: Context
    ) {
        val json = JSONObject()
        json.put("nombre", nombre)
        json.put("latitud", latLng.latitude)
        json.put("longitud", latLng.longitude)

        val body = json.toString().toRequestBody("application/json; charset=utf-8".toMediaTypeOrNull())
        val request = Request.Builder().url("$baseUrl/terrenos").post(body).build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                (context as AppCompatActivity).runOnUiThread {
                    Toast.makeText(context, "Error de red: ${e.message}", Toast.LENGTH_LONG).show()
                }
            }

            override fun onResponse(call: Call, response: Response) {
                val body = response.body?.string()
                (context as AppCompatActivity).runOnUiThread {
                    if (response.isSuccessful && body != null) {
                        try {
                            val id = JSONObject(body).getInt("id")

                            // Agregar marcador al mapa
                            val marker = map.addMarker(MarkerOptions().position(latLng).title(nombre))
                            if (marker != null) markerMap[marker] = id

                            // Obtener clima y actualizar título
                            weatherService.getWeather(latLng.latitude, latLng.longitude) { clima ->
                                (context).runOnUiThread {
                                    marker?.title = "$nombre — $clima"
                                }
                            }

                            Toast.makeText(context, "Terreno guardado", Toast.LENGTH_SHORT).show()
                        } catch (e: Exception) {
                            Toast.makeText(context, "Error al obtener ID", Toast.LENGTH_SHORT).show()
                        }
                    } else {
                        Toast.makeText(context, "Error del servidor: $body", Toast.LENGTH_LONG).show()
                    }
                }
            }
        })
    }
    //CARGAR TERRENOS
    fun cargarTerrenos(map: GoogleMap, markerMap: MutableMap<Marker, Int>, context: Context) {
        val request = Request.Builder().url("$baseUrl/terrenos").get().build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                (context as AppCompatActivity).runOnUiThread {
                    Toast.makeText(context, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }

            override fun onResponse(call: Call, response: Response) {
                val body = response.body?.string()
                (context as AppCompatActivity).runOnUiThread {
                    if (response.isSuccessful && body != null) {
                        try {
                            val array = JSONArray(body)
                            for (i in 0 until array.length()) {
                                val t = array.getJSONObject(i)
                                val id = t.getInt("id")
                                val lat = t.getDouble("latitud")
                                val lon = t.getDouble("longitud")
                                val nombre = t.getString("nombre")
                                val latLng = LatLng(lat, lon)

                                //Agregar marcador temporal con el nombre
                                val marker = map.addMarker(MarkerOptions().position(latLng).title(nombre))
                                if (marker != null) markerMap[marker] = id

                                //Pedir clima y actualizar título
                                weatherService.getWeather(lat, lon) { clima ->
                                    (context).runOnUiThread {
                                        marker?.title = "$nombre — $clima"
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
    //ELIMINAR TERRENO (nuevo)
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
                        //Buscar el marcador asociado al terreno
                        val markerAEliminar = markerMap.entries.find { it.value == terrenoId }?.key
                        //Eliminar marcador del mapa
                        markerAEliminar?.remove()
                        //Quitar del mapa interno
                        markerMap.remove(markerAEliminar)

                        Toast.makeText(context, "Terreno eliminado correctamente", Toast.LENGTH_SHORT).show()
                    } else {
                        Toast.makeText(context, "Error del servidor al eliminar", Toast.LENGTH_SHORT).show()
                    }
                }
            }
        })
    }
}
