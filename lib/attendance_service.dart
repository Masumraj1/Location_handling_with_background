
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'App_config.dart';
import 'background_service.dart';

class AttendanceService {
  static Future<String?> _ensurePermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return 'ফোনের Location (GPS) বন্ধ আছে। চালু করে আবার চেষ্টা করুন।';
    }

    final whenInUse = await Permission.location.request();
    if (!whenInUse.isGranted) {
      if (whenInUse.isPermanentlyDenied) {
        await openAppSettings();
      }
      return 'Location permission দরকার। Allow করুন।';
    }


    final always = await Permission.locationAlways.request();
    if (!always.isGranted) {
      return 'ব্যাকগ্রাউন্ডে location-এর জন্য "Allow all the time" বেছে নিন।';
    }

    await Permission.notification.request();

    await Permission.ignoreBatteryOptimizations.request();

    return null;
  }

  static Future<Position> _currentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30),
      ),
    );
  }


  static Future<String?> checkIn() async {
    final permissionError = await _ensurePermissions();
    if (permissionError != null) return permissionError;


    Position pos;
    try {
      pos = await _currentPosition();
    } catch (e) {
      return 'Location পাওয়া যায়নি। খোলা জায়গায় গিয়ে আবার চেষ্টা করুন।';
    }

    final ok = await ApiService.checkIn(pos.latitude, pos.longitude);
    if (!ok) {
      return 'Check-in সার্ভারে পাঠানো যায়নি। ইন্টারনেট দেখে আবার চেষ্টা করুন।';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Keys.isCheckedIn, true);
    await prefs.setInt(Keys.lastSentAt, DateTime.now().millisecondsSinceEpoch);
    await prefs.setDouble(Keys.lastLat, pos.latitude);
    await prefs.setDouble(Keys.lastLng, pos.longitude);

    await startTracking();
    return null;
  }

  static Future<String?> checkOut() async {
    final prefs = await SharedPreferences.getInstance();
    double lat;
    double lng;
    try {
      final pos = await _currentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (e) {
      lat = prefs.getDouble(Keys.lastLat) ?? 0;
      lng = prefs.getDouble(Keys.lastLng) ?? 0;
    }


    final ok = await ApiService.checkOut(lat, lng);
    if (!ok) {
      return 'Check-out সার্ভারে পাঠানো যায়নি। আবার চেষ্টা করুন।';
    }
    await prefs.setBool(Keys.isCheckedIn, false);
    stopTracking();
    return null;
  }


  static Future<bool> resumeIfCheckedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final checkedIn = prefs.getBool(Keys.isCheckedIn) ?? false;
    if (checkedIn) {
      await startTracking();
    }
    return checkedIn;
  }
}