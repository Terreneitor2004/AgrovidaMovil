package com.example.apiagrovida

import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Marker

object MapUtils {

    fun mostrarDialogoAgregarTerreno(
        activity: AppCompatActivity,
        latLng: LatLng,
        weatherService: WeatherService,
        terrenoRepo: TerrenoRepository,
        map: GoogleMap,
        markerMap: MutableMap<Marker, Int>
    ) {
        val layout = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(50, 40, 50, 10)
        }

        val inputNombre = EditText(activity).apply { hint = "Nombre del terreno" }
        val inputPropietario = EditText(activity).apply { hint = "Propietario" }   // ← NUEVO
        val tvClima = TextView(activity).apply { text = "Cargando clima..." }

        layout.addView(inputNombre)
        layout.addView(inputPropietario) // ← NUEVO
        layout.addView(tvClima)

        weatherService.getWeather(latLng.latitude, latLng.longitude) {
            activity.runOnUiThread { tvClima.text = "Clima: $it" }
        }

        AlertDialog.Builder(activity)
            .setTitle("Agregar Terreno")
            .setView(layout)
            .setPositiveButton("Guardar") { dialog, _ ->
                val nombre = inputNombre.text.toString().trim()
                val propietario = inputPropietario.text.toString().trim() // ← NUEVO
                when {
                    nombre.isEmpty() -> {
                        Toast.makeText(activity, "El nombre es obligatorio", Toast.LENGTH_SHORT).show()
                    }
                    propietario.isEmpty() -> {
                        Toast.makeText(activity, "El propietario es obligatorio", Toast.LENGTH_SHORT).show()
                    }
                    else -> {
                        // Ajusta el repo para aceptar propietario (ver snippet abajo)
                        terrenoRepo.guardarTerreno(
                            nombre = nombre,
                            propietario = propietario,              // ← NUEVO
                            latLng = latLng,
                            map = map,
                            markerMap = markerMap,
                            context = activity
                        )
                    }
                }
                dialog.dismiss()
            }
            .setNegativeButton("Cancelar", null)
            .show()
    }

    fun mostrarDialogoComentarios(
        activity: AppCompatActivity,
        terrenoId: Int,
        nombreTerreno: String,
        comentarioRepo: ComentarioRepository
    ) {
        val layout = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(50, 40, 50, 10)
        }

        val input = EditText(activity).apply { hint = "Escribe un comentario" }
        val scroll = ScrollView(activity)
        val lista = LinearLayout(activity).apply { orientation = LinearLayout.VERTICAL }
        scroll.addView(lista)

        layout.addView(input)
        layout.addView(scroll)

        val dialog = AlertDialog.Builder(activity)
            .setTitle("Comentarios de $nombreTerreno")
            .setView(layout)
            .setPositiveButton("Guardar", null)
            .setNegativeButton("Cerrar", null)
            .create()

        dialog.setOnShowListener {
            comentarioRepo.cargarComentarios(terrenoId, lista, activity)
            dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener {
                val texto = input.text.toString().trim()
                if (texto.isNotEmpty()) {
                    comentarioRepo.guardarComentario(terrenoId, texto, activity) { ok ->
                        if (ok) {
                            input.setText("")
                            comentarioRepo.cargarComentarios(terrenoId, lista, activity)
                        }
                    }
                } else {
                    Toast.makeText(activity, "Comentario vacío", Toast.LENGTH_SHORT).show()
                }
            }
        }
        dialog.show()
    }
}
