import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> checkSpeechPermission() async {
  var status = await Permission.notification.status;

  if (status.isDenied) {
    status = await Permission.notification.request();
  }

  if (status.isPermanentlyDenied) {
    Fluttertoast.showToast(
      msg: "⚠️ Please enable Notification permission from settings",
      gravity: ToastGravity.BOTTOM,
      toastLength: Toast.LENGTH_LONG,
    );

    final opened = await openAppSettings();
    if (!opened) {
      Fluttertoast.showToast(
        msg: "❌ Could not open settings automatically. Open manually.",
        gravity: ToastGravity.BOTTOM,
      );
    }
  } else if (status.isGranted) {
    Fluttertoast.showToast(
      msg: "✅ Notification permission granted",
      gravity: ToastGravity.BOTTOM,
    );
  }
}
