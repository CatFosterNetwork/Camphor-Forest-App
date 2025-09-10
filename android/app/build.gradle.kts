plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "social.swu.camphor_forest"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = "29.0.13599879"
    ndkVersion = "27.0.12077973"
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "social.swu.camphor_forest"
        minSdk = 22 // 支持Android 5.0+，覆盖95%+用户
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // 启用多dex支持（应用较大时需要）
        multiDexEnabled = true
        
        // 启用向量图形支持
        vectorDrawables.useSupportLibrary = true
    }

    buildTypes {
        release {
            // 启用代码混淆和资源缩减
            isMinifyEnabled = true
            isShrinkResources = true
            
            // 使用R8进行代码优化
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // TODO: 配置正式签名文件
            // 临时使用debug签名，生产环境需要配置release签名
            signingConfig = signingConfigs.getByName("debug")
            
            // 启用ZIP对齐优化
            isZipAlignEnabled = true
            
            // 设置应用名称
            manifestPlaceholders["appName"] = "樟木林Toolbox"
        }
        
        debug {
            // 调试版本配置
            isMinifyEnabled = false
            manifestPlaceholders["appName"] = "樟木林Toolbox-Debug"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-splashscreen:1.0.1")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.multidex:multidex:2.0.1")
    
    // 性能优化
    implementation("androidx.profileinstaller:profileinstaller:1.3.1")
    
    // 百度地图 SDK
    implementation("com.baidu.lbsyun:BaiduMapSDK_Map:7.6.4")
}

