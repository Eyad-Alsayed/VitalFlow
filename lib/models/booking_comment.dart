import 'package:equatable/equatable.dart';

enum BookingContext { or, icu }

class CommentAuthor extends Equatable {
  final String uid;
  final String displayName;
  final String role;

  const CommentAuthor({
    required this.uid,
    required this.displayName,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'role': role,
    };
  }

  factory CommentAuthor.fromMap(Map<String, dynamic> map) {
    return CommentAuthor(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? '',
    );
  }

  @override
  List<Object?> get props => [uid, displayName, role];
}

class BookingComment extends Equatable {
  final String? id;
  final String bookingId;
  final BookingContext context;
  final CommentAuthor author;
  final String text;
  final DateTime createdAt;

  const BookingComment({
    this.id,
    required this.bookingId,
    required this.context,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'booking_id': bookingId,
      'context': context.name,
      'author_uid': author.uid,
      'author_name': author.displayName,
      'author_role': author.role,
      'message': text,
    };
  }

  factory BookingComment.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime created;
    final raw = map['created_at'] ?? map['createdAt'];
    if (raw is String) {
      created = DateTime.tryParse(raw) ?? DateTime.now();
    } else if (raw is DateTime) {
      created = raw;
    } else {
      created = DateTime.now();
    }

    return BookingComment(
      id: documentId ?? map['id']?.toString(),
      bookingId: map['booking_id']?.toString() ?? map['bookingId'] ?? '',
      context: BookingContext.values.firstWhere(
        (e) => e.name == map['context'],
        orElse: () => BookingContext.or,
      ),
      author: CommentAuthor(
        uid: map['author_uid'] ?? map['author']?['uid'] ?? '',
        displayName: map['author_name'] ?? map['author']?['displayName'] ?? '',
        role: map['author_role'] ?? map['author']?['role'] ?? '',
      ),
      text: map['message'] ?? map['text'] ?? '',
      createdAt: created,
    );
  }

  BookingComment copyWith({
    String? id,
    String? bookingId,
    BookingContext? context,
    CommentAuthor? author,
    String? text,
    DateTime? createdAt,
  }) {
    return BookingComment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      context: context ?? this.context,
      author: author ?? this.author,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, bookingId, context, author, text, createdAt];
}
