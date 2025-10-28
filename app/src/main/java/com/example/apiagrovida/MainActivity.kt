package com.example.apiagrovida

import android.Manifest
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.widget.Toolbar
import androidx.drawerlayout.widget.DrawerLayout
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Marker
import com.google.android.material.navigation.NavigationView
import androidx.core.view.GravityCompat
import androidx.core.content.ContextCompat
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException

class MainActivity : AppCompatActivity(), OnMapReadyCallback {

    private lateinit var map: GoogleMap
    private val terrenoRepo = TerrenoRepository()
    private val comentarioRepo = ComentarioRepository()
    private val weatherService = WeatherService()

    private val markerTerrenoMap = mutableMapOf<Marker, Int>()

    private lateinit var drawerLayout: DrawerLayout
    private lateinit var navigationView: NavigationView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val toolbar = findViewById<Toolbar>(R.id.toolbar)
        setSupportActionBar(toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.setHomeAsUpIndicator(android.R.drawable.ic_menu_sort_by_size)

        drawerLayout = findViewById(R.id.drawerLayout)
        navigationView = findViewById(R.id.navigationView)

        navigationView.setNavigationItemSelectedListener { menuItem ->
            when (menuItem.itemId) {
                R.id.menu_ver_terrenos -> {
                    mostrarListaTerrenos()
                    drawerLayout.closeDrawer(GravityCompat.START)
                    true
                }
                else -> false
            }
        }

        val mapFragment = supportFragmentManager
            .findFragmentById(R.id.fragmentMap) as SupportMapFragment
        mapFragment.getMapAsync(this)

        // Permisos y canal de notificaciones
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
        }
        NotificationUtils.ensureChannel(this)

        // Arrancar el servicio Foreground de clima
        startWeatherService()
    }

    override fun onMapReady(googleMap: GoogleMap) {
        map = googleMap
        val inicio = LatLng(14.6349, -90.5069)
        map.moveCamera(CameraUpdateFactory.newLatLngZoom(inicio, 7f))

        terrenoRepo.cargarTerrenos(map, markerTerrenoMap, this)

        map.setOnMapClickListener { latLng ->
            MapUtils.mostrarDialogoAgregarTerreno(
                this, latLng, weatherService, terrenoRepo, map, markerTerrenoMap
            )
        }

        map.setOnMarkerClickListener { marker ->
            val terrenoId = markerTerrenoMap[marker]
            if (terrenoId != null) {
                MapUtils.mostrarDialogoComentarios(
                    this, terrenoId, marker.title ?: "Terreno", comentarioRepo
                )
            }
            true
        }
    }

    // Iniciar/Detener servicio Foreground
    private fun startWeatherService() {
        val i = Intent(this, WeatherForegroundService::class.java)
        ContextCompat.startForegroundService(this, i)
    }

    private fun stopWeatherService() {
        val i = Intent(this, WeatherForegroundService::class.java)
        stopService(i)
    }

    // Lista de terrenos
    private fun mostrarListaTerrenos() {
        val client = ApiClient.client
        val request = Request.Builder().url("${ApiClient.BASE_URL}/terrenos").get().build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                runOnUiThread {
                    Toast.makeText(this@MainActivity, "Error al cargar terrenos", Toast.LENGTH_SHORT).show()
                }
            }

            override fun onResponse(call: Call, response: Response) {
                val body = response.body?.string()
                if (response.isSuccessful && body != null) {
                    val array = JSONArray(body)
                    val nombres = mutableListOf<String>()
                    val ids = mutableListOf<Int>()

                    for (i in 0 until array.length()) {
                        val t = array.getJSONObject(i)
                        nombres.add(t.getString("nombre"))
                        ids.add(t.getInt("id"))
                    }

                    runOnUiThread {
                        AlertDialog.Builder(this@MainActivity)
                            .setTitle("Lista de Terrenos")
                            .setItems(nombres.toTypedArray()) { _, which ->
                                val terrenoId = ids[which]
                                val terrenoNombre = nombres[which]
                                mostrarOpcionesTerreno(terrenoId, terrenoNombre)
                            }
                            .setPositiveButton("Cerrar", null)
                            .show()
                    }
                }
            }
        })
    }

    private fun mostrarOpcionesTerreno(id: Int, nombreActual: String) {
        val opciones = arrayOf("Editar nombre", "Eliminar terreno", "Cancelar")

        AlertDialog.Builder(this)
            .setTitle("Opciones para \"$nombreActual\"")
            .setItems(opciones) { dialog, which ->
                when (which) {
                    0 -> mostrarDialogoEditarTerreno(id, nombreActual)
                    1 -> eliminarTerreno(id)
                    else -> dialog.dismiss()
                }
            }
            .show()
    }

    private fun mostrarDialogoEditarTerreno(id: Int, nombreActual: String) {
        val input = EditText(this)
        input.setText(nombreActual)
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(40, 30, 40, 0)
            addView(input)
        }

        AlertDialog.Builder(this)
            .setTitle("Editar nombre del terreno")
            .setView(layout)
            .setPositiveButton("Guardar") { _, _ ->
                val nuevoNombre = input.text.toString().trim()
                if (nuevoNombre.isNotEmpty()) {
                    editarTerreno(id, nuevoNombre)
                } else {
                    Toast.makeText(this, "El nombre no puede estar vacío", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancelar", null)
            .show()
    }

    private fun editarTerreno(id: Int, nuevoNombre: String) {
        val client = ApiClient.client
        val json = JSONObject().put("nombre", nuevoNombre)
        val body = RequestBody.create("application/json".toMediaTypeOrNull(), json.toString())
        val request = Request.Builder()
            .url("${ApiClient.BASE_URL}/terrenos/$id")
            .put(body)
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                runOnUiThread {
                    Toast.makeText(this@MainActivity, "Error al editar terreno", Toast.LENGTH_SHORT).show()
                }
            }

            override fun onResponse(call: Call, response: Response) {
                runOnUiThread {
                    if (response.isSuccessful) {
                        Toast.makeText(this@MainActivity, "Terreno actualizado", Toast.LENGTH_SHORT).show()
                        terrenoRepo.cargarTerrenos(map, markerTerrenoMap, this@MainActivity)
                    } else {
                        Toast.makeText(this@MainActivity, "Error al actualizar terreno", Toast.LENGTH_SHORT).show()
                    }
                }
            }
        })
    }

    private fun eliminarTerreno(id: Int) {
        val client = ApiClient.client
        val request = Request.Builder()
            .url("${ApiClient.BASE_URL}/terrenos/$id")
            .delete()
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                runOnUiThread {
                    Toast.makeText(this@MainActivity, "Error al eliminar terreno", Toast.LENGTH_SHORT).show()
                }
            }

            override fun onResponse(call: Call, response: Response) {
                runOnUiThread {
                    if (response.isSuccessful) {
                        Toast.makeText(this@MainActivity, "Terreno eliminado", Toast.LENGTH_SHORT).show()
                        terrenoRepo.cargarTerrenos(map, markerTerrenoMap, this@MainActivity)
                    } else {
                        Toast.makeText(this@MainActivity, "No se pudo eliminar el terreno", Toast.LENGTH_SHORT).show()
                    }
                }
            }
        })
    }

    override fun onSupportNavigateUp(): Boolean {
        drawerLayout.openDrawer(GravityCompat.START)
        return true
    }
}
