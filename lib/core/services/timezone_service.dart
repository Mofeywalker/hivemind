import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimezoneService {
  TimezoneService._();

  static bool _isInitialized = false;
  static String? _timeZoneName;

  /// IANA name of the device timezone, e.g. `Europe/Berlin`. Null when it could
  /// not be determined, in which case the backend falls back to the reminder
  /// creator's zone. Used to render push notifications in local time.
  static String? get timeZoneName => _timeZoneName;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      tz.initializeTimeZones();
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        _timeZoneName = timezoneInfo.identifier;
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
