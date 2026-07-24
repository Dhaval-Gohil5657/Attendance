import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static final Logger logger = Logger();

  static Future<bool> requestAllPermissions() async {
    logger.i('Requesting location & notification permissions...');

    // 1. Request Foreground Location (Fine & Coarse)
    PermissionStatus locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      locationStatus = await Permission.location.request();
      logger.i('Foreground Location Permission status: $locationStatus');
    }

    // 2. Request Background Location if foreground location is granted
    if (locationStatus.isGranted) {
      PermissionStatus bgStatus = await Permission.locationAlways.status;
      if (!bgStatus.isGranted) {
        bgStatus = await Permission.locationAlways.request();
        logger.i('Background Location Permission status: $bgStatus');
      }
    }

    // 3. Request Notification Permission (Android 13+)
    PermissionStatus notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      notificationStatus = await Permission.notification.request();
      logger.i('Notification Permission status: $notificationStatus');
    }

    // 4. Ignore Battery Optimizations for Background Service
    PermissionStatus batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) {
      batteryStatus = await Permission.ignoreBatteryOptimizations.request();
      logger.i('Battery Optimization Exemption status: $batteryStatus');
    }

    final isGranted = locationStatus.isGranted;
    return isGranted;
  }
}
