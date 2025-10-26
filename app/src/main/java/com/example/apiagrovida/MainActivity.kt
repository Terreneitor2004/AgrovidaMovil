package com.example.apiagrovida

import android.content.Context
import android.os.Bundle
import android.os.StrictMode
import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Marker
import com.google.android.gms.maps.model.MarkerOptions
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : AppCompatActivity(), OnMapReadyCallback {
    private lateinit var map: GoogleMap
    private val PREFS_NAME = "ComentariosPrefs"

    // Comentarios por marcador (persistentes)
    private val comentariosPorUbicacion = mutableMapOf<String, MutableList<String>>()

    override fun onMapReady(googleMap: GoogleMap) {
        map = googleMap

        // Terrenos
        addMarkerWithWeather(LatLng(14.750868, -90.244365), "Terreno Girasoles")
        addMarkerWithWeather(LatLng(14.217446, -88.513120), "Terreno Maíz")
        addMarkerWithWeather(LatLng(53.170622, 17.248931), "Terreno Europa")

        // Abrir comentarios al tocar un marcador
        map.setOnInfoWindowClickListener { marker ->
            mostrarDialogoComentarios(marker)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        createMapFragment()

        // Permitir HTTP (solo pruebas)
        val policy = StrictMode.ThreadPolicy.Builder().permitAll().build()
        StrictMode.setThreadPolicy(policy)

        // Cargar comentarios previos
        cargarComentarios()
    }

    private fun createMapFragment() {
        val mapFragment = supportFragmentManager
            .findFragmentById(R.id.fragmentMap) as SupportMapFragment
        mapFragment.getMapAsync(this)
    }

    private fun addMarkerWithWeather(location: LatLng, title: String) {
        val clima = getWeather(location.latitude, location.longitude)
        val marker = map.addMarker(
            MarkerOptions()
                .position(location)
                .title(title)
                .snippet("Clima: $clima")
        )

        marker?.id?.let {
            if (!comentariosPorUbicacion.containsKey(it)) {
                comentariosPorUbicacion[it] = mutableListOf()
            }
        }

        map.animateCamera(
            CameraUpdateFactory.newLatLngZoom(location, 15f),
            2000,
            null
        )
    }

    private fun getWeather(lat: Double, lon: Double): String {
        return try {
            val apiKey = "d49f768bd5ea4f249972455f214cadfe"
            val url =
                "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&lang=es&appid=$apiKey"
            val client = OkHttpClient()
            val request = Request.Builder().url(url).build()
            val response = client.newCall(request).execute()
            val jsonData = response.body?.string() ?: return "No disponible"
            val jsonObject = JSONObject(jsonData)
            val main = jsonObject.getJSONObject("main")
            val temp = main.getDouble("temp")
            val weather = jsonObject.getJSONArray("weather").getJSONObject(0).getString("description")
            "$temp°C, $weather"
        } catch (e: Exception) {
            e.printStackTrace()
            "No disponible"
        }
    }

    // Mostrar comentarios con lista editable
    private fun mostrarDialogoComentarios(marker: Marker) {
        val historial = comentariosPorUbicacion[marker.id] ?: mutableListOf()

        val listView = ListView(this)
        val adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, historial)
        listView.adapter = adapter

        val builder = AlertDialog.Builder(this)
        builder.setTitle("${marker.title} - ${marker.snippet}")
        builder.setView(listView)

        builder.setPositiveButton("Agregar") { dialog, _ ->
            pedirNuevoComentario(marker, adapter)
            dialog.dismiss()
        }

        builder.setNegativeButton("Cerrar") { dialog, _ -> dialog.dismiss() }

        val dialog = builder.create()
        dialog.show()

        // Click en comentario para editar o eliminar
        listView.setOnItemClickListener { _, _, position, _ ->
            val opciones = arrayOf("Editar", "Eliminar")
            AlertDialog.Builder(this)
                .setTitle("Acción sobre el comentario")
                .setItems(opciones) { _, which ->
                    when (which) {
                        0 -> editarComentario(marker, position, adapter)
                        1 -> eliminarComentario(marker, position, adapter)
                    }
                }.show()
        }
    }

    //Agregar comentario
    private fun pedirNuevoComentario(marker: Marker, adapter: ArrayAdapter<String>) {
        val input = EditText(this)
        val builder = AlertDialog.Builder(this)
        builder.setTitle("Nuevo comentario")
        builder.setView(input)

        builder.setPositiveButton("Guardar") { dialog, _ ->
            val comentario = input.text.toString()
            if (comentario.isNotBlank()) {
                val fecha = SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault()).format(Date())
                val nuevoComentario = "$fecha - $comentario"
                comentariosPorUbicacion[marker.id]?.add(nuevoComentario)
                guardarComentarios()
                adapter.notifyDataSetChanged()
            }
            dialog.dismiss()
        }
        builder.setNegativeButton("Cancelar") { dialog, _ -> dialog.dismiss() }
        builder.show()
    }

    // 🔹 Editar comentario
    private fun editarComentario(marker: Marker, index: Int, adapter: ArrayAdapter<String>) {
        val historial = comentariosPorUbicacion[marker.id] ?: return
        val input = EditText(this)
        input.setText(historial[index])

        AlertDialog.Builder(this)
            .setTitle("Editar comentario")
            .setView(input)
            .setPositiveButton("Guardar") { dialog, _ ->
                historial[index] = input.text.toString()
                guardarComentarios()
                adapter.notifyDataSetChanged()
                dialog.dismiss()
            }
            .setNegativeButton("Cancelar") { dialog, _ -> dialog.dismiss() }
            .show()
    }

    //Eliminar comentario
    private fun eliminarComentario(marker: Marker, index: Int, adapter: ArrayAdapter<String>) {
        comentariosPorUbicacion[marker.id]?.removeAt(index)
        guardarComentarios()
        adapter.notifyDataSetChanged()
    }

    //Guardar en SharedPreferences
    private fun guardarComentarios() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        val json = JSONObject()

        for ((key, lista) in comentariosPorUbicacion) {
            json.put(key, JSONArray(lista))
        }
        editor.putString("comentarios", json.toString())
        editor.apply()
    }

    //Cargar de SharedPreferences
    private fun cargarComentarios() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val data = prefs.getString("comentarios", null) ?: return
        val json = JSONObject(data)

        for (key in json.keys()) {
            val lista = mutableListOf<String>()
            val arr = json.getJSONArray(key)
            for (i in 0 until arr.length()) {
                lista.add(arr.getString(i))
            }
            comentariosPorUbicacion[key] = lista
        }
    }
}
