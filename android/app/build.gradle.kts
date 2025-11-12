plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // Plugin de Google Services para Firebase
    id("com.google.gms.google-services")
}

dependencies {
    // Importa el Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // Puedes agregar otras dependencias de Firebase aquí
    // https://firebase.google.com/docs/android/setup#available-libraries
}

android {
    namespace = "com.example.semana7_castillo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Debe coincidir con el package configurado en Firebase
        applicationId = "com.example.semana7_castillo"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        setProperty("archivesBaseName", "Juanchos")
    }

    buildTypes {
        release {
            // Firma temporal con claves de depuración
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
