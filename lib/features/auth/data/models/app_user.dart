import '../../../../core/constants/app_constants.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? photoUrl;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = UserRole.member,
    this.photoUrl,
    this.createdAt,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'display_name': displayName,
    'role': role.name,
    'photo_url': photoUrl,
    'created_at': createdAt?.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: json['uid'] as String? ?? json['id'] as String? ?? '',
    email: json['email'] as String? ?? '',
    displayName: json['display_name'] as String? ?? json['displayName'] as String? ?? '',
    role: () {
      final roleStr = json['role'] as String? ?? 'member';
      if (roleStr == 'super_admin') return UserRole.superAdmin;
      return UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.member,
      );
    }(),
    photoUrl: json['photo_url'] as String? ?? json['photoUrl'] as String?,
    createdAt: (json['created_at'] ?? json['createdAt']) != null
        ? DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString())
        : null,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
