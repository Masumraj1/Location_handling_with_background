import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'App_config.dart';

const String _channelId = 'wagebook_location';
const int _notificationId = 777;

// ───────────────────────────────────────────────────────────
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const channel = AndroidNotificationChannel(
    _channelId,
    'WageBook Location Tracking',
    description: 'Check-in থাকা অবস্থায় location tracking চলছে তা জানায়।',
    importance: Importance.low,
  );

  final notifications = FlutterLocalNotificationsPlugin();

  await notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: _channelId,
      initialNotificationTitle: 'WageBook',
      initialNotificationContent: 'Location tracking চালু আছে',
      foregroundServiceNotificationId: _notificationId,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// ───────────────────────────────────────────────────────────
Future<void> startTracking() async {
  final service = FlutterBackgroundService();
  if (!await service.isRunning()) {
    await service.startService();
  }
}

void stopTracking() {
  FlutterBackgroundService().invoke('stopService');
}

// ───────────────────────────────────────────────────────────
// ───────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// ───────────────────────────────────────────────────────────
// ───────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  StreamSubscription<Position>? subscription;
  bool busy = false;
  service.on('stopService').listen((event) async {
    await subscription?.cancel();
    service.stopSelf();
  });

  final settings = AndroidSettings(
    accuracy: LocationAccuracy.medium,
    distanceFilter: 0,
    intervalDuration: AppConfig.gpsCheckInterval,
  );

  subscription = Geolocator.getPositionStream(locationSettings: settings)
      .listen(
        (Position pos) async {
          if (busy) return;
          busy = true;

          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.reload();

            final checkedIn = prefs.getBool(Keys.isCheckedIn) ?? false;
            if (!checkedIn) {
              await subscription?.cancel();
              service.stopSelf();
              return;
            }

            final lastSentMs = prefs.getInt(Keys.lastSentAt) ?? 0;
            final elapsed = DateTime.now().millisecondsSinceEpoch - lastSentMs;
            if (elapsed < AppConfig.sendInterval.inMilliseconds) {
              return;
            }

            final ok = await ApiService.sendLocation(
              pos.latitude,
              pos.longitude,
            );

            if (ok) {
              await prefs.setInt(
                Keys.lastSentAt,
                DateTime.now().millisecondsSinceEpoch,
              );
            }
            await prefs.setDouble(Keys.lastLat, pos.latitude);
            await prefs.setDouble(Keys.lastLng, pos.longitude);

            if (service is AndroidServiceInstance) {
              final t = DateTime.now();
              final hh = t.hour.toString().padLeft(2, '0');
              final mm = t.minute.toString().padLeft(2, '0');
              service.setForegroundNotificationInfo(
                title: 'WageBook – Checked in',
                content: ok
                    ? 'Location পাঠানো হয়েছে: $hh:$mm'
                    : 'পাঠানো যায়নি, পরে আবার চেষ্টা হবে ($hh:$mm)',
              );
            }

            debugPrint(
              '📍 Location sent=$ok: ${pos.latitude}, ${pos.longitude}',
            );
          } catch (e) {
            debugPrint('Background error: $e');
          } finally {
            busy = false;
          }
        },
        onError: (e) => debugPrint('Location stream error: $e'),
        cancelOnError: false,
      );
}
