class FirebaseValueUtils {
  static Map<dynamic, dynamic> asMap(dynamic value) {
    if (value is Map) {
      return Map<dynamic, dynamic>.from(value);
    }
    return {};
  }

  static List<MapEntry<dynamic, dynamic>> asEntries(dynamic value) {
    final map = asMap(value);
    return map.entries.toList();
  }

  static String asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static int asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static double asDouble(dynamic value, {double fallback = 0.0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static bool asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }

    return fallback;
  }

  static DateTime? asDateTimeFromMilliseconds(dynamic value) {
    final millis = asInt(value, fallback: -1);
    if (millis <= 0) return null;

    try {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }
}