plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "id.web.synvorateknologiindonesia.benih_jagung"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "id.web.synvorateknologiindonesia.benih_jagung"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Prototipe dibagikan langsung sebagai APK, bukan lewat Play Store, jadi memakai kunci debug.
            // Akibatnya APK yang dibangun di laptop lain tidak bisa memperbarui aplikasi yang sudah
            // terpasang; hapus aplikasi lama dulu sebelum memasang yang baru.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
