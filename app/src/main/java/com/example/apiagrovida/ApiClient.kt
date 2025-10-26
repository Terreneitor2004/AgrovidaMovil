package com.example.apiagrovida

import okhttp3.OkHttpClient

object ApiClient {
    val client = OkHttpClient()
    const val BASE_URL = "https://backed-agrovida-346767576630.us-central1.run.app"
}
