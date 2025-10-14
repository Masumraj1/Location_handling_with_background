# ============background_service===========
await initializeService(); // একবার অ্যাপ স্টার্টে


startBackgroundService(); // Background service চালু
stopBackgroundService();  // থামানোর জন্য

# ===============Android Modification==============
android>app>build.gradle>
* Added this Code
     compileOptions {
     isCoreLibraryDesugaringEnabled = true
      sourceCompatibility = JavaVersion.VERSION_11
      targetCompatibility = JavaVersion.VERSION_11
       }
* Added This Dependency
       dependencies {
       coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
        }


And Use Background Service