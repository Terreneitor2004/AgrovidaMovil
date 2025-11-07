package com.example.apiagrovida

import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Marker
import android.graphics.Bitmap
import android.graphics.Canvas
import androidx.annotation.ColorInt
import androidx.annotation.DrawableRes
import androidx.appcompat.content.res.AppCompatResources
import androidx.core.graphics.drawable.DrawableCompat
import com.google.android.gms.maps.model.BitmapDescriptor
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import android.view.LayoutInflater
import android.widget.*
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.textfield.TextInputEditText





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
        val inputPropietario = EditText(activity).apply { hint = "Propietario" }
        val tvClima = TextView(activity).apply { text = "Cargando clima..." }

        layout.addView(inputNombre)
        layout.addView(inputPropietario)
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
                        terrenoRepo.guardarTerreno(
                            nombre = nombre,
                            propietario = propietario,
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
    fun markerFromVector(context: AppCompatActivity, @DrawableRes drawableId: Int, @ColorInt tint: Int? = null): BitmapDescriptor {
        val drawable = AppCompatResources.getDrawable(context, drawableId)!!.mutate()
        if (tint != null) DrawableCompat.setTint(drawable, tint)

        val bmp = Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return BitmapDescriptorFactory.fromBitmap(bmp)
    }

    //AGREGAR TERRENO
    fun mostrarBottomSheetAgregarTerreno(
        activity: AppCompatActivity,
        latLng: LatLng,
        weatherService: WeatherService,
        terrenoRepo: TerrenoRepository,
        map: GoogleMap,
        markerMap: MutableMap<Marker, Int>
    ) {
        val dialog = BottomSheetDialog(activity)
        val view = LayoutInflater.from(activity).inflate(R.layout.bottomsheet_terreno, null)
        dialog.setContentView(view)

        val etNombre = view.findViewById<TextInputEditText>(R.id.etNombre)
        val etProp = view.findViewById<TextInputEditText>(R.id.etPropietario)
        val tvClima = view.findViewById<TextView>(R.id.tvClima)
        val btnGuardar = view.findViewById<com.google.android.material.button.MaterialButton>(R.id.btnGuardar)

        //Clima para esa lat/lon
        weatherService.getWeather(latLng.latitude, latLng.longitude) {
            activity.runOnUiThread { tvClima.text = "Clima: $it" }
        }

        btnGuardar.setOnClickListener {
            val nombre = etNombre.text?.toString()?.trim().orEmpty()
            val propietario = etProp.text?.toString()?.trim().orEmpty()

            when {
                nombre.isEmpty() -> etNombre.error = "Requerido"
                propietario.isEmpty() -> etProp.error = "Requerido"
                else -> {
                    terrenoRepo.guardarTerreno(
                        nombre = nombre,
                        propietario = propietario,
                        latLng = latLng,
                        map = map,
                        markerMap = markerMap,
                        context = activity
                    )
                    dialog.dismiss()
                }
            }
        }

        dialog.setOnShowListener {
            val sheet = dialog.findViewById<FrameLayout>(com.google.android.material.R.id.design_bottom_sheet)
            if (sheet != null) {
                val behavior = com.google.android.material.bottomsheet.BottomSheetBehavior.from(sheet)
                behavior.state = com.google.android.material.bottomsheet.BottomSheetBehavior.STATE_EXPANDED
                behavior.skipCollapsed = true
            }
        }

        dialog.show()
    }

    //COMENTARIOS
    fun mostrarBottomSheetComentarios(
        activity: AppCompatActivity,
        terrenoId: Int,
        nombreTerreno: String,
        comentarioRepo: ComentarioRepository
    ) {
        val dialog = BottomSheetDialog(activity)
        val view = LayoutInflater.from(activity).inflate(R.layout.bottomsheet_comentarios, null)
        dialog.setContentView(view)

        val tvTitulo = view.findViewById<TextView>(R.id.tvTitulo)
        val etComentario = view.findViewById<TextInputEditText>(R.id.etComentario)
        val btnGuardar = view.findViewById<com.google.android.material.button.MaterialButton>(R.id.btnGuardarComentario)
        val lista = view.findViewById<LinearLayout>(R.id.layoutLista)

        tvTitulo.text = "Comentarios de $nombreTerreno"

        //Cargar existentes
        comentarioRepo.cargarComentarios(terrenoId, lista, activity)

        btnGuardar.setOnClickListener {
            val texto = etComentario.text?.toString()?.trim().orEmpty()
            if (texto.isEmpty()) {
                etComentario.error = "Escribe algo"
                return@setOnClickListener
            }
            comentarioRepo.guardarComentario(terrenoId, texto, activity) { ok ->
                if (ok) {
                    etComentario.setText("")
                    comentarioRepo.cargarComentarios(terrenoId, lista, activity)
                }
            }
        }

        // (Opcional) abrir expandido
        dialog.setOnShowListener {
            val sheet = dialog.findViewById<FrameLayout>(com.google.android.material.R.id.design_bottom_sheet)
            if (sheet != null) {
                val behavior = com.google.android.material.bottomsheet.BottomSheetBehavior.from(sheet)
                behavior.state = com.google.android.material.bottomsheet.BottomSheetBehavior.STATE_EXPANDED
                behavior.skipCollapsed = true
            }
        }

        dialog.show()
    }
}
