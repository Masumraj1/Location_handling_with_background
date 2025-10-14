import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/widgets.dart';


//━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🚀 BACKGROUND SERVICE CONTROL FUNCTIONS
//━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 🔹 Service চালু করার ফাংশন
/// ─────────────────────────────
/// এই ফাংশনটি ব্যাকগ্রাউন্ড সার্ভিস চালু করে।
void startBackgroundService() {
  final service = FlutterBackgroundService();
  service.startService();
}

/// 🔹 Service বন্ধ করার ফাংশন
/// ─────────────────────────────
/// সার্ভিস বন্ধ করতে এই ফাংশনটি ব্যবহৃত হয়।
void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}



//━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ⚙️ INITIALIZATION & CONFIGURATION
//━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 🔸 সার্ভিস ইনিশিয়ালাইজ করার মূল ফাংশন
/// ─────────────────────────────────────────
/// এখানে service configuration, notification setup,
/// এবং isolate binding initialize করা হয়।
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // 🔍 আগে থেকেই সার্ভিস চলছে কিনা চেক করা হচ্ছে
  bool isRunning = await service.isRunning();
  if (isRunning) {
    stopBackgroundService(); // পুরোনো সার্ভিস বন্ধ করে নতুনভাবে শুরু করা হবে
  }

  //━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔔 Notification Channel তৈরি (Android 8.0+)
  //━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'MY FOREGROUND SERVICE',
    description: 'এই চ্যানেলটি গুরুত্বপূর্ণ নোটিফিকেশনের জন্য ব্যবহৃত হয়।',
    importance: Importance.low,
  );

  // Notification Plugin instance তৈরি করা হচ্ছে
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Android ও iOS দুই প্ল্যাটফর্মে initialize
  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

  // Android এ Notification Channel রেজিস্টার করা হচ্ছে
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  //━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ⚙️ Service Configuration (Android & iOS)
  //━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart, // Background isolate শুরু হলে এই ফাংশন কল হবে
      autoStart: true, // App চালু হলে সার্ভিস নিজে থেকেই শুরু হবে
      isForegroundMode: true, // Notification সহ foreground মোডে চলবে
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing...',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart, // iOS foreground হলে এই ফাংশন কল হবে
      onBackground: onIosBackground, // iOS background isolate callback
    ),
  );
}



//━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🍎 iOS BACKGROUND HANDLER
//━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 🔹 iOS ব্যাকগ্রাউন্ড isolate callback
/// ─────────────────────────────────────
/// এখানে Flutter binding ইনিশিয়ালাইজ করা হয় যাতে isolate সঠিকভাবে কাজ করে।
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}



//━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🧠 MAIN BACKGROUND SERVICE LOGIC
//━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 🔸 ব্যাকগ্রাউন্ডে চলা মূল ফাংশন
/// ─────────────────────────────────────
/// এখানে service-এর মূল কাজ (notification update, timer, ইত্যাদি) সম্পন্ন হয়।
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // 🧩 Flutter plugin binding ইনিশিয়ালাইজ করা
  DartPluginRegistrant.ensureInitialized();

  debugPrint('🟢 FLUTTER BACKGROUND SERVICE শুরু হয়েছে: ${DateTime.now()}');

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  //━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔁 Foreground ↔ Background Switch Events
  //━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  //━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ⛔ সার্ভিস বন্ধ করার listener
  //━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  //━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ⏱ Periodic Timer (প্রতি ৫ সেকেন্ডে একবার)
  //━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    debugPrint("⏰ Timer tick at ${DateTime.now()}");

    // যদি service foreground মোডে থাকে তাহলে নতুন notification দেখানো হবে
    if (service is AndroidServiceInstance &&
        await service.isForegroundService()) {
      flutterLocalNotificationsPlugin.show(
        888,
        '📡 Location Service Active',
        'Last update: ${DateTime.now()}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'my_foreground',
            'MY FOREGROUND SERVICE',
            icon: 'ic_bg_service_small',
            ongoing: true,
          ),
        ),
      );

      // Foreground notification info update করা
      service.setForegroundNotificationInfo(
        title: "📍 Location Service",
        content: "Updated at ${DateTime.now()}",
      );
    }

    // Console log এ সার্ভিস activity দেখানো
    debugPrint('🕓 SERVICE ACTIVE: ${DateTime.now()}');
  });
}
