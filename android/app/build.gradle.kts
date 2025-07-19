plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.gaza.medical_assistant"
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
        applicationId = "com.gaza.medical_assistant"
        minSdk = 21  // Android 5.0+ for better low-spec device support
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Optimize for low-spec devices
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Optimize for size and performance
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // For production, use proper signing
            signingConfig = signingConfigs.getByName("debug")
        }
        
        debug {
            // Faster builds for development
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    // Split APKs by ABI for smaller downloads (only for release builds)
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a")
            isUniversalApk = false
        }
    }
}

flutter {
    source = "../.."
}
