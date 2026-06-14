plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "kr.ssing.catsong"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "dudnf1212@@"
            storeFile = file("upload-keystore.jks")
            storePassword = "dudnf1212@@"
        }
    }

    defaultConfig {
        applicationId = "kr.ssing.catsong"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            isShrinkResources = false
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("release")
        }
    }

    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.media3") {
                useVersion("1.9.2")
            }
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

dependencies {
    implementation("androidx.media3:media3-common:1.9.2")
    implementation("androidx.media3:media3-exoplayer:1.9.2")
    implementation("androidx.media3:media3-exoplayer-hls:1.9.2")
    implementation("androidx.media3:media3-exoplayer-dash:1.9.2")
    implementation("androidx.media3:media3-datasource:1.9.2")
    implementation("androidx.media3:media3-datasource-okhttp:1.9.2")
    implementation("androidx.media3:media3-extractor:1.9.2")
    implementation("androidx.media3:media3-session:1.9.2")
    implementation("androidx.media3:media3-ui:1.9.2")
}
