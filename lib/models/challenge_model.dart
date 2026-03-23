import '../utils/firebase_value_utils.dart';

class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final int points;
  final bool requiresCamera;

  final String status; // pending / active / expired / completed
  final String startDate; // yyyy-MM-dd
  final String endDate; // yyyy-MM-dd
  final int createdAt;
  final String? winnerUserId;
  final String? winnerName;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.requiresCamera,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.winnerUserId,
    this.winnerName,
  });

  factory ChallengeModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return ChallengeModel(
      id: id,
      title: FirebaseValueUtils.asString(map['title']),
      description: FirebaseValueUtils.asString(map['description']),
      points: FirebaseValueUtils.asInt(map['points']),
      requiresCamera: map['requiresCamera'] != false,
      status: FirebaseValueUtils.asString(
        map['status'],
        fallback: 'pending',
      ),
      startDate: FirebaseValueUtils.asString(map['startDate']),
      endDate: FirebaseValueUtils.asString(map['endDate']),
      createdAt: FirebaseValueUtils.asInt(map['createdAt']),
      winnerUserId: map['winnerUserId'] == null
          ? null
          : FirebaseValueUtils.asString(map['winnerUserId']),
      winnerName: map['winnerName'] == null
          ? null
          : FirebaseValueUtils.asString(map['winnerName']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'points': points,
      'requiresCamera': requiresCamera,
      'status': status,
      'startDate': startDate,
      'endDate': endDate,
      'createdAt': createdAt,
      'winnerUserId': winnerUserId,
      'winnerName': winnerName,
    };
  }

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    int? points,
    bool? requiresCamera,
    String? status,
    String? startDate,
    String? endDate,
    int? createdAt,
    String? winnerUserId,
    String? winnerName,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      requiresCamera: requiresCamera ?? this.requiresCamera,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      winnerUserId: winnerUserId ?? this.winnerUserId,
      winnerName: winnerName ?? this.winnerName,
    );
  }
}