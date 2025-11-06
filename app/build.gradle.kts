plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.example.apiagrovida"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.apiagrovida"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    implementation(libs.androidx.activity)
    implementation(libs.androidx.constraintlayout)
    implementation(libs.androidx.recyclerview)

    // Google Maps - usa UNA sola versión (la más nueva que ya tenías)
    implementation("com.google.android.gms:play-services-maps:18.2.0")

    // OkHttp - deja solo una versión (la más nueva)
    implementation("com.squareup.okhttp3:okhttp:4.11.0")

    // JSON
    implementation("org.json:json:20230227")
    implementation("com.google.code.gson:gson:2.10.1")

    // WorkManager: solo si quieres la opción 1 (puedes comentar si no lo usarás)
    // implementation("androidx.work:work-runtime-ktx:2.9.1")

    // QUITA esta línea, es la que te metía el NotificationUtils ajeno:
    // implementation(libs.androidbrowserhelper)
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.activity:activity-ktx:1.9.3")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
}
