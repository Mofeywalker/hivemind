import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimezoneService {
  TimezoneService._();

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      tz.initializeTimeZones();
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      } catch (e) {
        debugPrint(
          'Could not configure local timezone, fallback to default: $e',
        );
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing timezones: $e');
    }
  }

  static tz.Location get localLocation {
    return tz.local;
  }

  static tz.TZDateTime fromDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, localLocation);
  }

  static tz.TZDateTime now() {
    return tz.TZDateTime.now(localLocation);
  }
}
