import java.util.Base64 // Читаю флаг отдельной сборки из параметров Flutter
plugins {
    id("com.android.application")
    // Подключаю Flutter после Android-плагина.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.romance_club"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Задаю ID основного приложения.
        applicationId = "com.example.romance_club"
        // Задаю поддерживаемые версии Android.
        // Минимальную версию беру из Flutter.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        // Беру номер и название версии из pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // Для проверки звука создаю отдельное приложение с отдельными локальными данными.
            val audioCheck = (project.findProperty("dart-defines") as? String).orEmpty()
                .split(',').any { encoded ->
                    runCatching {
                        String(Base64.getDecoder().decode(encoded)) == "ROMANCE_AUDIO_CHECK=true"
                    }.getOrDefault(false)
                }
            if (audioCheck) {
                applicationIdSuffix = ".audio_check"
            }
        }
        release {
            // Для учебной release-сборки оставляю отладочную подпись.
            // Для публикации понадобится отдельная подпись.
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