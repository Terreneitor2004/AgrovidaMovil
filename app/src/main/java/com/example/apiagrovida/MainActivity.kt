package com.example.apiagrovida

import android.Manifest
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import androidx.core.content.ContextCompat
import androidx.core.view.GravityCompat
import androidx.drawerlayout.widget.DrawerLayout
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Marker
import com.google.android.material.bottomappbar.BottomAppBar
import com.google.android.material.floatingactionbutton.FloatingActionButton
import com.google.android.material.navigation.NavigationView
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import android.content.res.Configuration
import com.google.android.gms.maps.model.MapStyleOptions
import android.view.LayoutInflater
import android.view.View
import android.widget.TextView
import androidx.core.widget.addTextChangedListener


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

        val bottomAppBar = findViewById<BottomAppBar>(R.id.bottomAppBar)

// Acciones del BottomAppBar
        bottomAppBar.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.action_list_terrenos -> {
                    mostrarListaTerrenos()
                    true
                }
                R.id.action_recenter -> {
                    // Recentrar a Guatemala
                    val gt = LatLng(14.6349, -90.5069)
                    map.animateCamera(CameraUpdateFactory.newLatLngZoom(gt, 7f))
                    true
                }
                else -> false
            }
        }


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

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
        }
        NotificationUtils.ensureChannel(this)

        startWeatherService()
    }

    override fun onMapReady(googleMap: GoogleMap) {
        map = googleMap

        //estilo oscuro/claro
        val night = (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                Configuration.UI_MODE_NIGHT_YES
        val styleRes = if (night) R.raw.map_style_dark else R.raw.map_style_light
        map.setMapStyle(MapStyleOptions.loadRawResourceStyle(this, styleRes))

        //configuración visual del mapa
        map.uiSettings.isMapToolbarEnabled = false
        map.uiSettings.isCompassEnabled = true
        map.uiSettings.isMyLocationButtonEnabled = false

        //cámara inicial sobre Guatemala
        val inicio = LatLng(14.6349, -90.5069)
        map.moveCamera(CameraUpdateFactory.newLatLngZoom(inicio, 7f))

        // cargar terrenos existentes
        terrenoRepo.cargarTerrenos(map, markerTerrenoMap, this)

        map.setOnMapClickListener { latLng ->
            MapUtils.mostrarBottomSheetAgregarTerreno(
                this, latLng, weatherService, terrenoRepo, map, markerTerrenoMap
            )
        }

        map.setOnMarkerClickListener { marker ->
            marker.showInfoWindow()
            true
        }

        map.setInfoWindowAdapter(object : GoogleMap.InfoWindowAdapter {
            override fun getInfoWindow(marker: Marker): View? = null

            override fun getInfoContents(marker: Marker): View {
                val v = layoutInflater.inflate(R.layout.view_infowindow_terreno, null)

                val tvNombre = v.findViewById<TextView>(R.id.tvNombre)
                val tvProp = v.findViewById<TextView>(R.id.tvPropietario)
                val tvClima = v.findViewById<TextView>(R.id.tvClima)
                val tvAccion = v.findViewById<TextView>(R.id.tvAccion)

                // el título llega como "Nombre — Propietario — Clima"
                val parts = (marker.title ?: "").split(" — ")
                val nombre = parts.getOrNull(0) ?: "Terreno"
                val propietario = parts.getOrNull(1) ?: ""
                val clima = parts.getOrNull(2) ?: ""

                tvNombre.text = nombre

                if (propietario.isNotEmpty()) {
                    tvProp.visibility = View.VISIBLE
                    tvProp.text = "Propietario: $propietario"
                } else tvProp.visibility = View.GONE

                if (clima.isNotEmpty()) {
                    tvClima.visibility = View.VISIBLE
                    tvClima.text = "Clima: $clima"
                } else tvClima.visibility = View.GONE

                tvAccion.text = "Ver comentarios"
                return v
            }
        })

        //abrir comentarios
        map.setOnInfoWindowClickListener { marker ->
            val terrenoId = markerTerrenoMap[marker]
            if (terrenoId != null) {
                MapUtils.mostrarBottomSheetComentarios(
                    this, terrenoId, marker.title ?: "Terreno", comentarioRepo
                )
            }
        }

        // Controles de zoom
        val zoomIn = findViewById<com.google.android.material.floatingactionbutton.FloatingActionButton>(R.id.btnZoomIn)
        val zoomOut = findViewById<com.google.android.material.floatingactionbutton.FloatingActionButton>(R.id.btnZoomOut)

        zoomIn.setOnClickListener {
            val currentZoom = map.cameraPosition.zoom
            map.animateCamera(CameraUpdateFactory.zoomTo(currentZoom + 1))
        }

        zoomOut.setOnClickListener {
            val currentZoom = map.cameraPosition.zoom
            map.animateCamera(CameraUpdateFactory.zoomTo(currentZoom - 1))
        }
    }


    private fun startWeatherService() {
        val i = Intent(this, WeatherForegroundService::class.java)
        ContextCompat.startForegroundService(this, i)
    }

    private fun stopWeatherService() {
        val i = Intent(this, WeatherForegroundService::class.java)
        stopService(i)
    }

    // lista de terrenos
    private fun mostrarListaTerrenos() {
        val dialog = com.google.android.material.bottomsheet.BottomSheetDialog(this)
        val view = layoutInflater.inflate(R.layout.bottomsheet_list_terrenos, null)
        dialog.setContentView(view)

        val etBuscar = view.findViewById<com.google.android.material.textfield.TextInputEditText>(R.id.etBuscar)
        val chipGroup = view.findViewById<com.google.android.material.chip.ChipGroup>(R.id.chipGroupSort)
        val rv = view.findViewById<androidx.recyclerview.widget.RecyclerView>(R.id.rvTerrenos)
        val tvEmpty = view.findViewById<TextView>(R.id.tvEmpty)

        if (rv == null || etBuscar == null || chipGroup == null || tvEmpty == null) {
            Toast.makeText(this, "Error de vista: revisa IDs del layout bottomsheet_list_terrenos", Toast.LENGTH_LONG).show()
            return
        }

        rv.layoutManager = androidx.recyclerview.widget.LinearLayoutManager(this)
        val adapter = TerrenosAdapter(mutableListOf(),
            onClick = { t ->
                val target = LatLng(t.lat, t.lon)
                map.animateCamera(CameraUpdateFactory.newLatLngZoom(target, 14f))
                val marker = markerTerrenoMap.entries.find { it.value == t.id }?.key
                marker?.showInfoWindow()
                dialog.dismiss()
            },
            onEdit = { t -> mostrarDialogoEditarTerreno(t.id, t.nombre) },
            onDelete = { t -> eliminarTerreno(t.id) }
        )
        rv.adapter = adapter

        val client = ApiClient.client
        val request = okhttp3.Request.Builder().url("${ApiClient.BASE_URL}/terrenos").get().build()
        client.newCall(request).enqueue(object : okhttp3.Callback {
            override fun onFailure(call: okhttp3.Call, e: java.io.IOException) {
                runOnUiThread {
                    tvEmpty.text = "Error de red"
                    tvEmpty.visibility = View.VISIBLE
                }
            }
            override fun onResponse(call: okhttp3.Call, response: okhttp3.Response) {
                val body = response.body?.string() ?: "[]"
                if (!response.isSuccessful) {
                    runOnUiThread {
                        tvEmpty.text = "Error del servidor"
                        tvEmpty.visibility = View.VISIBLE
                    }
                    return
                }
                val arr = org.json.JSONArray(body)
                val list = mutableListOf<TerrenoItem>()
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    list.add(
                        TerrenoItem(
                            id = o.getInt("id"),
                            nombre = o.optString("nombre", "Terreno"),
                            propietario = o.optString("propietario", ""),
                            lat = o.getDouble("latitud"),
                            lon = o.getDouble("longitud")
                        )
                    )
                }
                runOnUiThread {
                    adapter.update(list)
                    tvEmpty.visibility = if (list.isEmpty()) View.VISIBLE else View.GONE

                    // buscar (usa core-ktx)
                    etBuscar.addTextChangedListener { s ->
                        val q = (s?.toString() ?: "").trim().lowercase()
                        val filtered = list.filter {
                            it.nombre.lowercase().contains(q) || it.propietario.lowercase().contains(q)
                        }
                        adapter.update(filtered)
                        tvEmpty.visibility = if (filtered.isEmpty()) View.VISIBLE else View.GONE
                    }

                    chipGroup.check(R.id.chipRecientes)
                    chipGroup.setOnCheckedStateChangeListener { _, _ ->
                        val sorted = when (chipGroup.checkedChipId) {
                            R.id.chipNombre -> adapterCurrent(adapter).sortedBy { it.nombre.lowercase() }
                            R.id.chipPropietario -> adapterCurrent(adapter).sortedBy { it.propietario.lowercase() }
                            else -> adapterCurrent(adapter).sortedByDescending { it.id } // recientes
                        }
                        adapter.update(sorted)
                    }
                }
            }
        })

        dialog.setOnShowListener {
            val sheet = dialog.findViewById<android.widget.FrameLayout>(com.google.android.material.R.id.design_bottom_sheet)
            sheet?.let {
                val behavior = com.google.android.material.bottomsheet.BottomSheetBehavior.from(it)
                behavior.state = com.google.android.material.bottomsheet.BottomSheetBehavior.STATE_EXPANDED
                behavior.skipCollapsed = true
            }
        }

        dialog.show()
    }

    private fun adapterCurrent(adapter: TerrenosAdapter): List<TerrenoItem> {
        val list = mutableListOf<TerrenoItem>()
        for (i in 0 until adapter.itemCount) {
        }
        return list
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
        input.setText(nombreActual.substringBefore(" — ")) // si viene con propietario, solo toma el nombre
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
                        //Eliminar marcador
                        val markerAEliminar = markerTerrenoMap.entries.find { it.value == id }?.key
                        markerAEliminar?.remove()
                        markerTerrenoMap.remove(markerAEliminar)

                        //Eliminar de la lista
                        try {
                            val rv = findViewById<androidx.recyclerview.widget.RecyclerView>(R.id.rvTerrenos)
                            val adapter = rv?.adapter as? TerrenosAdapter
                            if (adapter != null) {
                                val nuevaLista = adapter.getCurrentItems().toMutableList()
                                val eliminado = nuevaLista.removeIf { it.id == id }
                                if (eliminado) adapter.update(nuevaLista)
                            }
                        } catch (e: Exception) {
                        }

                        Toast.makeText(this@MainActivity, "Terreno eliminado correctamente", Toast.LENGTH_SHORT).show()
                    } else {
                        Toast.makeText(this@MainActivity, "Error del servidor al eliminar", Toast.LENGTH_SHORT).show()
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
