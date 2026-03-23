class SubmissionModel {
  final String id;
  final String userId;
  final String userName;
  final String challengeId;
  final String challengeTitle;
  final int points;
  final String status;
  final String imageUrl;
  final int submittedAt;
  final bool cameraOnly;
  final String submittedDate;
  final String platform;

  const SubmissionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.challengeId,
    required this.challengeTitle,
    required this.points,
    required this.status,
    required this.imageUrl,
    required this.submittedAt,
    required this.cameraOnly,
    required this.submittedDate,
    required this.platform,
  });

  factory SubmissionModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return SubmissionModel(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      userName: (map['userName'] ?? 'Unknown User').toString(),
      challengeId: (map['challengeId'] ?? '').toString(),
      challengeTitle: (map['challengeTitle'] ?? '').toString(),
      points: _toInt(map['points']),
      status: (map['status'] ?? 'pending').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      submittedAt: _toInt(map['submittedAt']),
      cameraOnly: map['cameraOnly'] == true,
      submittedDate: (map['submittedDate'] ?? '').toString(),
      platform: (map['platform'] ?? 'unknown').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'challengeId': challengeId,
      'challengeTitle': challengeTitle,
      'points': points,
      'status': status,
      'imageUrl': imageUrl,
      'submittedAt': submittedAt,
      'cameraOnly': cameraOnly,
      'submittedDate': submittedDate,
      'platform': platform,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}
