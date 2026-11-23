import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'App_config.dart';
import 'attendance_service.dart';
import 'background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackgroundService();
  await AttendanceService.resumeIfCheckedIn();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WageBook Demo',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const AttendanceScreen(),
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _checkedIn = false;
  bool _loading = false;
  double? _lat;
  double? _lng;
  DateTime? _lastSent;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadState(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final ms = prefs.getInt(Keys.lastSentAt);
    if (!mounted) return;
    setState(() {
      _checkedIn = prefs.getBool(Keys.isCheckedIn) ?? false;
      _lat = prefs.getDouble(Keys.lastLat);
      _lng = prefs.getDouble(Keys.lastLng);
      _lastSent = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    });
  }

  Future<void> _onPressed() async {
    setState(() => _loading = true);
    final error = _checkedIn
        ? await AttendanceService.checkOut()
        : await AttendanceService.checkIn();

    await _loadState();
    if (!mounted) return;
    setState(() => _loading = false);
    final message =
        error ??
        (_checkedIn
            ? 'Check-in সফল। Tracking চালু।'
            : 'Check-out সফল। Tracking বন্ধ।');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final color = _checkedIn ? Colors.green : Colors.grey;

    return Scaffold(
      appBar: AppBar(title: const Text('WageBook Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _checkedIn ? Icons.location_on : Icons.location_off,
              size: 72,
              color: color,
            ),
            const SizedBox(height: 12),

            Text(
              _checkedIn ? 'Checked In' : 'Checked Out',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),

            if (_checkedIn)
              Text(
                'Location active until check-out\n'
                '(প্রতি ${AppConfig.sendInterval.inHours} ঘণ্টা পর পর পাঠানো হয়)',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),

            if (_lat != null && _lng != null)
              Text(
                'Last location:\n'
                '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                textAlign: TextAlign.center,
              ),
            if (_lastSent != null)
              Text(
                '\nLast sent: ${_lastSent!.toLocal()}',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _loading ? null : _onPressed,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: _checkedIn ? Colors.red : Colors.green,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _checkedIn ? 'CHECK OUT' : 'CHECK IN',
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
