import '../utils/timezone_helper.dart';

class Comment {
  final int? id;
  final int bookingId;
  final String message;
  final String authorName;
  final String authorRole;
  final DateTime createdAt;
  final bool isInternal;

  const Comment({
    this.id,
    required this.bookingId,
    required this.message,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
    this.isInternal = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int?,
      bookingId: json['booking_id'] as int,
      message: json['message'] as String,
      authorName: json['author_name'] as String,
      authorRole: json['author_role'] as String,
      createdAt: parseRiyadhDateTime(json['created_at'] as String),
      isInternal: json['is_internal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'booking_id': bookingId,
      'message': message,
      'author_name': authorName,
      'author_role': authorRole,
      'created_at': createdAt.toIso8601String(),
      'is_internal': isInternal,
    };
  }

  Comment copyWith({
    int? id,
    int? bookingId,
    String? message,
    String? authorName,
    String? authorRole,
    DateTime? createdAt,
    bool? isInternal,
  }) {
    return Comment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      message: message ?? this.message,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      createdAt: createdAt ?? this.createdAt,
      isInternal: isInternal ?? this.isInternal,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, authorName: $authorName, message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper getters for UI
  String get displayAuthor => authorName;
  String get displayRole => authorRole.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)).join(' ');
  String get shortMessage => message.length > 100 ? 
      '${message.substring(0, 100)}...' : message;
  
  // Role color helper for UI
  String get roleColor {
    switch (authorRole.toLowerCase()) {
      case 'anesthesia':
        return 'blue';
      case 'icu_team':
        return 'green';
      case 'applicant':
        return 'orange';
      default:
        return 'grey';
    }
  }

  // Time formatting helper
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
