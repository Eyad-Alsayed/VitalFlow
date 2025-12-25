import 'package:equatable/equatable.dart';
import '../utils/timezone_helper.dart';

enum ICUBookingStatus {
  pending,
  confirmed,
  noBedAvailable,
  notRequested,
}

enum ICUUrgencyLevel {
  critical('Critical'),
  elective('Elective');

  const ICUUrgencyLevel(this.displayName);
  final String displayName;
}

class ICUContactInfo extends Equatable {
  final String consultantName;
  final String consultantPhone;
  final String requestingPhysician;
  final String requestingPhysicianPhone;

  const ICUContactInfo({
    required this.consultantName,
    required this.consultantPhone,
    required this.requestingPhysician,
    required this.requestingPhysicianPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'consultantName': consultantName,
      'consultantPhone': consultantPhone,
      'requestingPhysician': requestingPhysician,
      'requestingPhysicianPhone': requestingPhysicianPhone,
    };
  }

  factory ICUContactInfo.fromMap(Map<String, dynamic> map) {
    return ICUContactInfo(
      consultantName: map['consultantName'] ?? '',
      consultantPhone: map['consultantPhone'] ?? '',
      requestingPhysician: map['requestingPhysician'] ?? '',
      requestingPhysicianPhone: map['requestingPhysicianPhone'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        consultantName,
        consultantPhone,
        requestingPhysician,
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

class ICUBedRequest extends Equatable {
  final String? id;
  final String patientMrn;
  final String patientName;
  final String patientWard;
  final String indication;
  final ICUUrgencyLevel urgencyLevel;
  final ICUContactInfo contact;
  final DateTime requestedAt;
  final DateTime? requestedDate;
  final ICUBookingStatus status;
  final String? unit;
  final String? room;
  final String? outcome;
  final UserInfo createdBy;
  final DateTime lastUpdatedAt;

  const ICUBedRequest({
    this.id,
    required this.patientMrn,
    required this.patientName,
    required this.patientWard,
    required this.indication,
    required this.urgencyLevel,
    required this.contact,
    required this.requestedAt,
    this.requestedDate,
    this.status = ICUBookingStatus.pending,
    this.unit,
    this.room,
    this.outcome,
    required this.createdBy,
    required this.lastUpdatedAt,
  });

  Map<String, dynamic> toMap() {
    // Convert urgency to database format (lowercase for backend enum)
    String urgencyCode = urgencyLevel == ICUUrgencyLevel.critical ? 'critical' : 'elective';
    
    return {
      'mrn': patientMrn,
      'patient_name': patientName,
      'patient_ward': patientWard,
      'indication': indication,
      'urgency': urgencyCode,
      'consultant': contact.consultantName,
      'consultant_phone': contact.consultantPhone,
      'requesting_physician': contact.requestingPhysician,
      'requesting_physician_phone': contact.requestingPhysicianPhone,
      'requested_date': requestedDate?.toIso8601String(),
      'created_by_uid': createdBy.uid,
      'created_by_name': createdBy.displayName,
      'created_by_role': createdBy.role,
    };
  }

  factory ICUBedRequest.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return ICUBedRequest(
      id: documentId ?? map['id']?.toString(),
      patientMrn: map['mrn'] ?? '',
      patientName: map['patient_name'] ?? '',
      patientWard: map['patient_ward'] ?? '',
      indication: map['indication'] ?? '',
      urgencyLevel: ICUUrgencyLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == (map['urgency'] ?? map['urgencyLevel'] ?? '').toString().toLowerCase(),
        orElse: () => ICUUrgencyLevel.elective,
      ),
      contact: ICUContactInfo(
        consultantName: map['consultant'] ?? '',
        consultantPhone: map['consultant_phone'] ?? '',
        requestingPhysician: map['requesting_physician'] ?? '',
        requestingPhysicianPhone: map['requesting_physician_phone'] ?? '',
      ),
      requestedAt: map['created_at'] is String
        ? parseRiyadhDateTime(map['created_at'])
        : nowRiyadh(),
      requestedDate: map['requested_date'] != null
        ? parseRiyadhDateTime(map['requested_date'])
        : null,
      status: ICUBookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ICUBookingStatus.pending,
      ),
      unit: map['unit'],
      room: map['room'],
      outcome: map['outcome'],
      createdBy: UserInfo(
        uid: map['created_by_uid'] ?? '',
        role: map['created_by_role'] ?? '',
        displayName: map['created_by_name'] ?? '',
      ),
      lastUpdatedAt: map['last_updated_at'] is String
        ? parseRiyadhDateTime(map['last_updated_at'])
        : nowRiyadh(),
    );
  }

  ICUBedRequest copyWith({
    String? id,
    String? patientMrn,
    String? patientName,
    String? patientWard,
    String? indication,
    ICUUrgencyLevel? urgencyLevel,
    ICUContactInfo? contact,
    DateTime? requestedAt,
    DateTime? requestedDate,
    ICUBookingStatus? status,
    String? unit,
    String? room,
    String? outcome,
    UserInfo? createdBy,
    DateTime? lastUpdatedAt,
  }) {
    return ICUBedRequest(
      id: id ?? this.id,
      patientMrn: patientMrn ?? this.patientMrn,
      patientName: patientName ?? this.patientName,
      patientWard: patientWard ?? this.patientWard,
      indication: indication ?? this.indication,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      contact: contact ?? this.contact,
      requestedAt: requestedAt ?? this.requestedAt,
      requestedDate: requestedDate ?? this.requestedDate,
      status: status ?? this.status,
      unit: unit ?? this.unit,
      room: room ?? this.room,
      outcome: outcome ?? this.outcome,
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
        indication,
        urgencyLevel,
        contact,
        requestedAt,
        requestedDate,
        status,
        unit,
        room,
        outcome,
        createdBy,
        lastUpdatedAt,
      ];
}
