package com.example.apiagrovida

import okhttp3.OkHttpClient

object ApiClient {
    // Cliente HTTP reutilizable
    val client = OkHttpClient()

    // Tu backend principal (Cloud Run)
    const val BASE_URL = "https://backed-agrovida-346767576630.us-central1.run.app"

    // Nueva base URL de la máquina virtual del amigo (CAMBIA ESTA IP)
    const val FRIEND_BASE = "http://34.132.245.216/"
}
