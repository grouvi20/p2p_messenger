class User {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime lastSeen;

  const User({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.isOnline = false,
    required this.lastSeen,
  });

  User copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'isOnline': isOnline,
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        isOnline: json['isOnline'] as bool? ?? false,
        lastSeen: DateTime.parse(json['lastSeen'] as String),
      );
}
