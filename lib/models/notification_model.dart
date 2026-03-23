import '../utils/firebase_value_utils.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final int timestamp;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
  });

  factory NotificationModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return NotificationModel(
      id: id,
      title: FirebaseValueUtils.asString(map['title']),
      body: FirebaseValueUtils.asString(map['body']),
      timestamp: FirebaseValueUtils.asInt(map['timestamp']),
      isRead: FirebaseValueUtils.asBool(map['isRead']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}