package com.example.apiagrovida

import android.content.Context
import android.util.Log
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
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

    fun guardarComentario(terrenoId: Int, texto: String, context: Context, callback: (Boolean) -> Unit) {
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
                            for (i in 0 until array.length()) {
                                val c = array.getJSONObject(i)
                                val texto = c.getString("texto")
                                val fecha = c.getString("fecha").substring(0, 10)
                                val tv = TextView(context)
                                tv.text = "[$fecha] $texto"
                                layout.addView(tv)
                            }
                            if (array.length() == 0) {
                                val tv = TextView(context)
                                tv.text = "No hay comentarios."
                                layout.addView(tv)
                            }
                        } catch (e: Exception) {
                            Log.e("COM_REPO", "Error parseando", e)
                        }
                    }
                }
            }
        })
    }
}
