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
        val layout = LinearLayout(activity)
        layout.orientation = LinearLayout.VERTICAL
        layout.setPadding(50, 40, 50, 10)

        val inputNombre = EditText(activity)
        inputNombre.hint = "Nombre del terreno"
        layout.addView(inputNombre)

        val tvClima = TextView(activity)
        tvClima.text = "Cargando clima..."
        layout.addView(tvClima)

        weatherService.getWeather(latLng.latitude, latLng.longitude) {
            (activity).runOnUiThread { tvClima.text = "Clima: $it" }
        }

        AlertDialog.Builder(activity)
            .setTitle("Agregar Terreno")
            .setView(layout)
            .setPositiveButton("Guardar") { dialog, _ ->
                val nombre = inputNombre.text.toString().trim()
                if (nombre.isEmpty()) {
                    Toast.makeText(activity, "El nombre es obligatorio", Toast.LENGTH_SHORT).show()
                } else {
                    terrenoRepo.guardarTerreno(nombre, latLng, map, markerMap, activity)
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
        val layout = LinearLayout(activity)
        layout.orientation = LinearLayout.VERTICAL
        layout.setPadding(50, 40, 50, 10)

        val input = EditText(activity)
        input.hint = "Escribe un comentario"
        layout.addView(input)

        val scroll = ScrollView(activity)
        val lista = LinearLayout(activity)
        lista.orientation = LinearLayout.VERTICAL
        scroll.addView(lista)
        layout.addView(scroll)

        val dialog = AlertDialog.Builder(activity)
            .setTitle("Comentarios de $nombreTerreno")
            .setView(layout)
            .setPositiveButton("Guardar", null)
            .setNegativeButton("Cerrar", null)
            .create()

        dialog.setOnShowListener {
            comentarioRepo.cargarComentarios(terrenoId, lista, activity)
            val btn = dialog.getButton(AlertDialog.BUTTON_POSITIVE)
            btn.setOnClickListener {
                val texto = input.text.toString().trim()
                if (texto.isNotEmpty()) {
                    comentarioRepo.guardarComentario(terrenoId, texto, activity) {
                        if (it) {
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
