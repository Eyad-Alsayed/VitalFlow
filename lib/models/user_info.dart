import 'package:equatable/equatable.dart';

class UserInfo extends Equatable {
  final String uid;
  final String role;
  final String displayName;

  const UserInfo({
    required this.uid,
    required this.role,
    required this.displayName,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role,
      'displayName': displayName,
    };
  }

  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      uid: map['uid'] ?? '',
      role: map['role'] ?? '',
      displayName: map['displayName'] ?? '',
    );
  }

  UserInfo copyWith({
    String? uid,
    String? role,
    String? displayName,
  }) {
    return UserInfo(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  List<Object?> get props => [uid, role, displayName];

  @override
  String toString() => 'UserInfo(uid: $uid, role: $role, displayName: $displayName)';
}
