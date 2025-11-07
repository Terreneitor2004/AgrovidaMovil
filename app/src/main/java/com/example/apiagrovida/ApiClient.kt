package com.example.apiagrovida

import okhttp3.OkHttpClient

object ApiClient {
    val client = OkHttpClient()

    // Tu backend principal (Cloud Run)
    const val BASE_URL = "https://backed-agrovida-346767576630.us-central1.run.app"

    const val FRIEND_BASE = "http://34.132.245.216/"
}
