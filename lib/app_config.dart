class AppConfig {
  static const bool useMockApi = true;
  static const String baseUrl = 'https://your-backend.com/api';

  static const Duration sendInterval = Duration(minutes: 2);
  static const Duration gpsCheckInterval = Duration(minutes: 1);
}

class Keys {
  static const String token = 'token';
  static const String isCheckedIn = 'is_checked_in';
  static const String lastSentAt = 'last_sent_at';
  static const String lastLat = 'last_lat';
  static const String lastLng = 'last_lng';
  static const String pendingQueue = 'pending_queue';
}
