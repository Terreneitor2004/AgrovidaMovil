package com.example.apiagrovida

import android.content.Context
import android.util.Log
import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException

class ComentarioRepository {

    private val client = ApiClient.client
    private val baseUrl = ApiClient.BASE_URL

    // 🔹 Guardar un nuevo comentario
    fun guardarComentario(
        terrenoId: Int,
        texto: String,
        context: Context,
        callback: (Boolean) -> Unit
    ) {
        val json = JSONObject()
        json.put("terreno_id", terrenoId)
        json.put("texto", texto)

        val body = json.toString().toRequestBody("application/json; charset=utf-8".toMediaTypeOrNull())
        val request = Request.Builder().url("$baseUrl/comentarios").post(body).build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                (context as AppCompatActivity).runOnUiThread {
                    Toast.makeText(context, "Error de red", Toast.LENGTH_SHORT).show()
                    callback(false)
                }
            }

            override fun onResponse(call: Call, response: Response) {
                (context as AppCompatActivity).runOnUiThread {
                    if (response.isSuccessful) {
                        Toast.makeText(context, "Comentario guardado", Toast.LENGTH_SHORT).show()
                        callback(true)
                    } else {
                        callback(false)
                    }
                }
            }
        })
    }

    // 🔹 Cargar comentarios (ahora con opciones de editar/eliminar)
    fun cargarComentarios(terrenoId: Int, layout: LinearLayout, context: Context) {
        val request = Request.Builder().url("$baseUrl/comentarios/$terrenoId").get().build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {}

            override fun onResponse(call: Call, response: Response) {
                val body = response.body?.string()
                (context as AppCompatActivity).runOnUiThread {
                    layout.removeAllViews()
                    if (response.isSuccessful && body != null) {
                        try {
                            val array = JSONArray(body)
                            if (array.length() == 0) {
                                val tv = TextView(context)
                                tv.text = "No hay comentarios."
                                layout.addView(tv)
                                return@runOnUiThread
                            }

                            for (i in 0 until array.length()) {
                                val c = array.getJSONObject(i)
                                val id = c.getInt("id")
                                val texto = c.getString("texto")
                                val fecha = c.getString("fecha").substring(0, 10)

                                // 🔸 Contenedor horizontal: texto + botones editar/eliminar
                                val fila = LinearLayout(context)
                                fila.orientation = LinearLayout.HORIZONTAL
                                fila.setPadding(0, 8, 0, 8)

                                val tv = TextView(context)
                                tv.text = "[$fecha] $texto"
                                tv.layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                                fila.addView(tv)

                                val btnEditar = ImageButton(context)
                                btnEditar.setImageResource(android.R.drawable.ic_menu_edit)
                                btnEditar.setOnClickListener {
                                    mostrarDialogoEditarComentario(context, id, texto, terrenoId, layout)
                                }
                                fila.addView(btnEditar)

                                val btnEliminar = ImageButton(context)
                                btnEliminar.setImageResource(android.R.drawable.ic_menu_delete)
                                btnEliminar.setOnClickListener {
                                    eliminarComentario(context, id, terrenoId, layout)
                                }
                                fila.addView(btnEliminar)

                                layout.addView(fila)
                            }

                        } catch (e: Exception) {
                            Log.e("COM_REPO", "Error parseando", e)
                        }
                    }
                }
            }
        })
    }

    // 🔹 Mostrar diálogo para editar comentario
    private fun mostrarDialogoEditarComentario(
        context: Context,
        comentarioId: Int,
        textoActual: String,
        terrenoId: Int,
        layout: LinearLayout
    ) {
        val input = EditText(context)
        input.setText(textoActual)

        AlertDialog.Builder(context)
            .setTitle("Editar comentario")
            .setView(input)
            .setPositiveButton("Guardar") { _, _ ->
                val nuevoTexto = input.text.toString().trim()
                if (nuevoTexto.isNotEmpty()) {
                    editarComentario(context, comentarioId, nuevoTexto, terrenoId, layout)
                }
            }
            .setNegativeButton("Cancelar", null)
            .show()
    }

    // 🔹 Llamada PUT para editar comentario
    private fun editarComentario(
        context: Context,
        comentarioId: Int,
        nuevoTexto: String,
        terrenoId: Int,
        layout: LinearLayout
    ) {
        val json = JSONObject().put("texto", nuevoTexto)
        val body = json.toString().toRequestBody("application/json".toMediaTypeOrNull())
        val request = Request.Builder()
            .url("$baseUrl/comentarios/$comentarioId")
            .put(body)
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                (context as AppCompatActivity).runOnUiThread {
                    Toast.makeText(context, "Error al editar", Toast.LENGTH_SHORT).show()
                }
            }

            override fun onResponse(call: Call, response: Response) {
                (context as AppCompatActivity).runOnUiThread {
                    if (response.isSuccessful) {
                        Toast.makeText(context, "Comentario actualizado", Toast.LENGTH_SHORT).show()
                        cargarComentarios(terrenoId, layout, context)
                    }
                }
            }
        })
    }

    // 🔹 Eliminar comentario con confirmación
    private fun eliminarComentario(
        context: Context,
        comentarioId: Int,
        terrenoId: Int,
        layout: LinearLayout
    ) {
        AlertDialog.Builder(context)
            .setTitle("Eliminar comentario")
            .setMessage("¿Deseas eliminar este comentario?")
            .setPositiveButton("Sí") { _, _ ->
                val request = Request.Builder()
                    .url("$baseUrl/comentarios/$comentarioId")
                    .delete()
                    .build()

                client.newCall(request).enqueue(object : Callback {
                    override fun onFailure(call: Call, e: IOException) {
                        (context as AppCompatActivity).runOnUiThread {
                            Toast.makeText(context, "Error al eliminar", Toast.LENGTH_SHORT).show()
                        }
                    }

                    override fun onResponse(call: Call, response: Response) {
                        (context as AppCompatActivity).runOnUiThread {
                            if (response.isSuccessful) {
                                Toast.makeText(context, "Comentario eliminado", Toast.LENGTH_SHORT).show()
                                cargarComentarios(terrenoId, layout, context)
                            }
                        }
                    }
                })
            }
            .setNegativeButton("Cancelar", null)
            .show()
    }
}
