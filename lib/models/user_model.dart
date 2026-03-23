class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final int coins;
  final int xp;
  final int streak;
  final int approvedProofs;
  final int approvedChallenges;
  final String? photoUrl;
  final String? bio;
  final String? rankTitle;
  final String? lastApprovedDate;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.coins,
    required this.xp,
    required this.streak,
    required this.approvedProofs,
    required this.approvedChallenges,
    this.photoUrl,
    this.bio,
    this.rankTitle,
    this.lastApprovedDate,
  });

  factory UserModel.empty(String uid, String email) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: '',
      coins: 100,
      xp: 0,
      streak: 0,
      approvedProofs: 0,
      approvedChallenges: 0,
      photoUrl: null,
      bio: null,
      rankTitle: 'Beginner',
      lastApprovedDate: null,
    );
  }

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return UserModel(
      uid: uid,
      email: (map['email'] ?? '') as String,
      displayName: (map['displayName'] ?? '') as String,
      coins: _toInt(map['coins']),
      xp: _toInt(map['xp']),
      streak: _toInt(map['streak']),
      approvedProofs: _toInt(map['approvedProofs']),
      approvedChallenges: _toInt(map['approvedChallenges']),
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      rankTitle: (map['rankTitle'] ?? 'Beginner') as String,
      lastApprovedDate: map['lastApprovedDate'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'coins': coins,
      'xp': xp,
      'streak': streak,
      'approvedProofs': approvedProofs,
      'approvedChallenges': approvedChallenges,
      'photoUrl': photoUrl,
      'bio': bio,
      'rankTitle': rankTitle,
      'lastApprovedDate': lastApprovedDate,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    int? coins,
    int? xp,
    int? streak,
    int? approvedProofs,
    int? approvedChallenges,
    String? photoUrl,
    String? bio,
    String? rankTitle,
    String? lastApprovedDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      coins: coins ?? this.coins,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      approvedProofs: approvedProofs ?? this.approvedProofs,
      approvedChallenges: approvedChallenges ?? this.approvedChallenges,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      rankTitle: rankTitle ?? this.rankTitle,
      lastApprovedDate: lastApprovedDate ?? this.lastApprovedDate,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}