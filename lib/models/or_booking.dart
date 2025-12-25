import 'package:equatable/equatable.dart';
import '../utils/timezone_helper.dart';

enum ORBookingStatus {
  pending,
  seenAccepted,
  awaitingResources,
  opDone,
  cancelled,
}

enum UrgencyLevel {
  e1WithinOneHour('E1- Within 1 hour'),
  e2WithinSixHours('E2- Within 6 hours'),
  e3WithinTwentyFourHours('E3- Within 24 hours');

  const UrgencyLevel(this.displayName);
  final String displayName;
}

class ContactInfo extends Equatable {
  final String consultantName;
  final String consultantPhone;
  final String requestingPhysician;
  final String anesthesiaTeamContact;
  final String requestingPhysicianPhone;

  const ContactInfo({
    required this.consultantName,
    required this.consultantPhone,
    required this.requestingPhysician,
    required this.anesthesiaTeamContact,
    required this.requestingPhysicianPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'consultantName': consultantName,
      'consultantPhone': consultantPhone,
      'requestingPhysician': requestingPhysician,
      'anesthesiaTeamContact': anesthesiaTeamContact,
  'requestingPhysicianPhone': requestingPhysicianPhone,
    };
  }

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      consultantName: map['consultantName'] ?? '',
      consultantPhone: map['consultantPhone'] ?? '',
      requestingPhysician: map['requestingPhysician'] ?? '',
      anesthesiaTeamContact: map['anesthesiaTeamContact'] ?? '',
  requestingPhysicianPhone: map['requestingPhysicianPhone'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        consultantName,
        consultantPhone,
        requestingPhysician,
        anesthesiaTeamContact,
  requestingPhysicianPhone,
      ];
}

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

  @override
  List<Object?> get props => [uid, role, displayName];
}

class ORBooking extends Equatable {
  final String? id;
  final String patientMrn;
  final String patientName;
  final String patientWard;
  final String procedure;
  final UrgencyLevel urgencyLevel;
  final ContactInfo contact;
  final DateTime requestedAt;
  final DateTime? scheduledAt;
  final ORBookingStatus status;
  final String? outcome;
  final DateTime? outcomeChangedAt;
  final UserInfo createdBy;
  final DateTime lastUpdatedAt;

  const ORBooking({
    this.id,
    required this.patientMrn,
    required this.patientName,
    required this.patientWard,
    required this.procedure,
    required this.urgencyLevel,
    required this.contact,
    required this.requestedAt,
    this.scheduledAt,
    this.status = ORBookingStatus.pending,
    this.outcome,
    this.outcomeChangedAt,
    required this.createdBy,
    required this.lastUpdatedAt,
  });

  Map<String, dynamic> toMap() {
    // Convert urgency to database format (e1, e2, e3) - lowercase
    String urgencyCode;
    switch (urgencyLevel) {
      case UrgencyLevel.e1WithinOneHour:
        urgencyCode = 'e1';
        break;
      case UrgencyLevel.e2WithinSixHours:
        urgencyCode = 'e2';
        break;
      case UrgencyLevel.e3WithinTwentyFourHours:
        urgencyCode = 'e3';
        break;
    }
    
    return {
      'mrn': patientMrn,
      'patient_name': patientName,
      'patient_ward': patientWard,
      'procedure': procedure,
      'urgency': urgencyCode,
      'consultant': contact.consultantName,
      'consultant_phone': contact.consultantPhone,
      'requesting_physician': contact.requestingPhysician,
      'requesting_physician_phone': contact.requestingPhysicianPhone,
      'created_by_uid': createdBy.uid,
      'created_by_name': createdBy.displayName,
      'created_by_role': createdBy.role,
    };
  }

  factory ORBooking.fromMap(Map<String, dynamic> map, {String? documentId}) {
    // Parse urgency from database format (E1, E2, E3) to enum
    UrgencyLevel urgency;
    final urgencyStr = (map['urgency'] ?? map['urgencyLevel'] ?? '').toString().toUpperCase();
    if (urgencyStr.contains('E1')) {
      urgency = UrgencyLevel.e1WithinOneHour;
    } else if (urgencyStr.contains('E2')) {
      urgency = UrgencyLevel.e2WithinSixHours;
    } else {
      urgency = UrgencyLevel.e3WithinTwentyFourHours;
    }
    
    return ORBooking(
      id: documentId ?? map['id']?.toString(),
      patientMrn: map['mrn'] ?? '',
      patientName: map['patient_name'] ?? '',
      patientWard: map['patient_ward'] ?? '',
      procedure: map['procedure'] ?? '',
      urgencyLevel: urgency,
      contact: ContactInfo(
        consultantName: map['consultant'] ?? '',
        consultantPhone: map['consultant_phone'] ?? '',
        requestingPhysician: map['requesting_physician'] ?? '',
        anesthesiaTeamContact: '',
        requestingPhysicianPhone: map['requesting_physician_phone'] ?? '',
      ),
      requestedAt: map['created_at'] is String
        ? parseRiyadhDateTime(map['created_at'])
        : DateTime.now(),
      scheduledAt: null,
      status: ORBookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ORBookingStatus.pending,
      ),
      outcome: map['outcome'],
      outcomeChangedAt: map['outcome_changed_at'] != null
        ? parseRiyadhDateTime(map['outcome_changed_at'])
        : null,
      createdBy: UserInfo(
        uid: map['created_by_uid'] ?? '',
        role: map['created_by_role'] ?? '',
        displayName: map['created_by_name'] ?? '',
      ),
      lastUpdatedAt: map['last_updated_at'] is String
        ? parseRiyadhDateTime(map['last_updated_at'])
        : DateTime.now(),
    );
  }

  ORBooking copyWith({
    String? id,
    String? patientMrn,
    String? patientName,
    String? patientWard,
    String? procedure,
    UrgencyLevel? urgencyLevel,
    ContactInfo? contact,
    DateTime? requestedAt,
    DateTime? scheduledAt,
    ORBookingStatus? status,
    String? outcome,
    DateTime? outcomeChangedAt,
    UserInfo? createdBy,
    DateTime? lastUpdatedAt,
  }) {
    return ORBooking(
      id: id ?? this.id,
      patientMrn: patientMrn ?? this.patientMrn,
      patientName: patientName ?? this.patientName,
      patientWard: patientWard ?? this.patientWard,
      procedure: procedure ?? this.procedure,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      contact: contact ?? this.contact,
      requestedAt: requestedAt ?? this.requestedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      outcome: outcome ?? this.outcome,
      outcomeChangedAt: outcomeChangedAt ?? this.outcomeChangedAt,
      createdBy: createdBy ?? this.createdBy,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patientMrn,
        patientName,
        patientWard,
        procedure,
        urgencyLevel,
        contact,
        requestedAt,
        scheduledAt,
        status,
        outcome,
        outcomeChangedAt,
        createdBy,
        lastUpdatedAt,
      ];
}
