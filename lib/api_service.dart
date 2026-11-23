
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'App_config.dart';

class ApiService {
  static Future<bool> checkIn(double lat, double lng) {
    return _post('/attendance/check-in', _body(lat, lng));
  }

  static Future<bool> checkOut(double lat, double lng) {
    return _post('/attendance/check-out', _body(lat, lng));
  }


  static Future<bool> sendLocation(double lat, double lng) async {
    final prefs = await _prefs();

    final queue = prefs.getStringList(Keys.pendingQueue) ?? <String>[];

    queue.add(jsonEncode(_body(lat, lng)));

    final remaining = <String>[];
    bool failed = false;

    for (final item in queue) {
      if (failed) {
        remaining.add(item);
        continue;
      }
      final ok = await _post(
        '/attendance/location',
        jsonDecode(item) as Map<String, dynamic>,
      );
      if (!ok) {
        failed = true;
        remaining.add(item);
      }
    }
    await prefs.setStringList(Keys.pendingQueue, remaining);

    return !failed;
  }

  static Map<String, dynamic> _body(double lat, double lng) {
    return {
      'latitude': lat,
      'longitude': lng,
      'recorded_at': DateTime.now().toUtc().toIso8601String(),
    };
  }


  static Future<bool> _post(String path, Map<String, dynamic> body) async {
    if (AppConfig.useMockApi) {
      debugPrint('MOCK POST $path -> $body');
      return true;
    }

    try {
      final prefs = await _prefs();
      final token = prefs.getString(Keys.token) ?? '';

      final res = await http
          .post(
        Uri.parse('${AppConfig.baseUrl}$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 20));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('API error on $path: $e');
      return false;
    }
  }


  static Future<SharedPreferences> _prefs() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return p;
  }
}