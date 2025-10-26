package com.example.apiagrovida

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AlertDialog
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Marker

class MainActivity : AppCompatActivity(), OnMapReadyCallback {

    private lateinit var map: GoogleMap
    private val terrenoRepo = TerrenoRepository()
    private val comentarioRepo = ComentarioRepository()
    private val weatherService = WeatherService()

    private val markerTerrenoMap = mutableMapOf<Marker, Int>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val mapFragment = supportFragmentManager
            .findFragmentById(R.id.fragmentMap) as SupportMapFragment
        mapFragment.getMapAsync(this)
    }

    override fun onMapReady(googleMap: GoogleMap) {
        map = googleMap
        val inicio = LatLng(14.6349, -90.5069)
        map.moveCamera(CameraUpdateFactory.newLatLngZoom(inicio, 7f))

        terrenoRepo.cargarTerrenos(map, markerTerrenoMap, this)

        map.setOnMapClickListener { latLng ->
            MapUtils.mostrarDialogoAgregarTerreno(this, latLng, weatherService, terrenoRepo, map, markerTerrenoMap)
        }

        map.setOnMarkerClickListener { marker ->
            val terrenoId = markerTerrenoMap[marker]
            if (terrenoId != null) {
                MapUtils.mostrarDialogoComentarios(this, terrenoId, marker.title ?: "Terreno", comentarioRepo)
            }
            true
        }
    }
}
