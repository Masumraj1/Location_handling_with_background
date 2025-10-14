# ============background_service===========
await initializeService(); // একবার অ্যাপ স্টার্টে


startBackgroundService(); // Background service চালু
stopBackgroundService();  // থামানোর জন্য

# Android Modification
### android>app>build.gradle>
* Added this Code And This Dependency

             compileOptions {
             isCoreLibraryDesugaringEnabled = true
              sourceCompatibility = JavaVersion.VERSION_11
               targetCompatibility = JavaVersion.VERSION_11
                 }

            dependencies {
            coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
             }


And Use Background Service


* Add This line and permission: # <AndroidManifest.xml>
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
  <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>

    <!-- Add for background service -->
        <service
            android:name="id.flutter.flutter_background_service.BackgroundService"
            android:foregroundServiceType="dataSync"
            />
        <!-- End background service -->