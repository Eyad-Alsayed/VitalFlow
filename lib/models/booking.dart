import '../utils/timezone_helper.dart';

class Booking {
  final int? id; // Auto-increment ID from database
  final String? mrn;
  final String? patientName;
  final String? procedure;
  final String bookingType; // 'OR' or 'ICU'
  final String? urgency;
  final String status;
  final String? outcome;
  final String? consultant;
  final String? consultantPhone;
  final String? requestingPhysician;
  final String? requestingPhysicianPhone;
  final String? anesthesiaTeamContact;
  final String? indication;
  final DateTime? requestedDate;
  final String? priorityNotes;
  final String? specialRequirements;
  final String? createdByName;
  final String? createdByRole;
  final String? updatedByName;
  final String? updatedByRole;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;
  final bool isActive;

  const Booking({
    this.id,
    this.mrn,
    this.patientName,
    this.procedure,
    required this.bookingType,
    this.urgency,
    this.status = 'pending',
    this.outcome,
    this.consultant,
    this.consultantPhone,
    this.requestingPhysician,
    this.requestingPhysicianPhone,
    this.anesthesiaTeamContact,
    this.indication,
    this.requestedDate,
    this.priorityNotes,
    this.specialRequirements,
    this.createdByName,
    this.createdByRole,
    this.updatedByName,
    this.updatedByRole,
    required this.createdAt,
    this.lastUpdatedAt,
    this.isActive = true,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int?,
      mrn: json['mrn'] as String?,
      patientName: json['patient_name'] as String?,
      procedure: json['procedure'] as String?,
      bookingType: json['type_of_booking'] as String,
      urgency: json['urgency'] as String?,
      status: json['status'] as String? ?? 'pending',
      outcome: json['outcome'] as String?,
      consultant: json['consultant'] as String?,
      consultantPhone: json['consultant_phone'] as String?,
      requestingPhysician: json['requesting_physician'] as String?,
      requestingPhysicianPhone: json['requesting_physician_phone'] as String?,
      anesthesiaTeamContact: json['anesthesia_team_contact'] as String?,
      indication: json['indication'] as String?,
      requestedDate: json['requested_date'] != null 
          ? parseRiyadhDateTime(json['requested_date'] as String)
          : null,
      priorityNotes: json['priority_notes'] as String?,
      specialRequirements: json['special_requirements'] as String?,
      createdByName: json['created_by_name'] as String?,
      createdByRole: json['created_by_role'] as String?,
      updatedByName: json['updated_by_name'] as String?,
      updatedByRole: json['updated_by_role'] as String?,
      createdAt: parseRiyadhDateTime(json['created_at'] as String),
      lastUpdatedAt: json['last_updated_at'] != null 
          ? parseRiyadhDateTime(json['last_updated_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (mrn != null) 'mrn': mrn,
      if (patientName != null) 'patient_name': patientName,
      if (procedure != null) 'procedure': procedure,
      'type_of_booking': bookingType,
      if (urgency != null) 'urgency': urgency,
      'status': status,
      if (outcome != null) 'outcome': outcome,
      if (consultant != null) 'consultant': consultant,
      if (consultantPhone != null) 'consultant_phone': consultantPhone,
      if (requestingPhysician != null) 'requesting_physician': requestingPhysician,
      if (requestingPhysicianPhone != null) 'requesting_physician_phone': requestingPhysicianPhone,
      if (anesthesiaTeamContact != null) 'anesthesia_team_contact': anesthesiaTeamContact,
      if (indication != null) 'indication': indication,
      if (requestedDate != null) 'requested_date': requestedDate!.toIso8601String(),
      if (priorityNotes != null) 'priority_notes': priorityNotes,
      if (specialRequirements != null) 'special_requirements': specialRequirements,
      if (createdByName != null) 'created_by_name': createdByName,
      if (createdByRole != null) 'created_by_role': createdByRole,
      if (updatedByName != null) 'updated_by_name': updatedByName,
      if (updatedByRole != null) 'updated_by_role': updatedByRole,
      'created_at': createdAt.toIso8601String(),
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt!.toIso8601String(),
      'is_active': isActive,
    };
  }

  Booking copyWith({
    int? id,
    String? mrn,
    String? patientName,
    String? procedure,
    String? bookingType,
    String? urgency,
    String? status,
    String? outcome,
    String? consultant,
    String? consultantPhone,
    String? requestingPhysician,
    String? requestingPhysicianPhone,
    String? anesthesiaTeamContact,
    String? indication,
    DateTime? requestedDate,
    String? priorityNotes,
    String? specialRequirements,
    String? createdByName,
    String? createdByRole,
    String? updatedByName,
    String? updatedByRole,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    bool? isActive,
  }) {
    return Booking(
      id: id ?? this.id,
      mrn: mrn ?? this.mrn,
      patientName: patientName ?? this.patientName,
      procedure: procedure ?? this.procedure,
      bookingType: bookingType ?? this.bookingType,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      outcome: outcome ?? this.outcome,
      consultant: consultant ?? this.consultant,
      consultantPhone: consultantPhone ?? this.consultantPhone,
      requestingPhysician: requestingPhysician ?? this.requestingPhysician,
      requestingPhysicianPhone: requestingPhysicianPhone ?? this.requestingPhysicianPhone,
      anesthesiaTeamContact: anesthesiaTeamContact ?? this.anesthesiaTeamContact,
      indication: indication ?? this.indication,
      requestedDate: requestedDate ?? this.requestedDate,
      priorityNotes: priorityNotes ?? this.priorityNotes,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      createdByName: createdByName ?? this.createdByName,
      createdByRole: createdByRole ?? this.createdByRole,
      updatedByName: updatedByName ?? this.updatedByName,
      updatedByRole: updatedByRole ?? this.updatedByRole,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Booking(id: $id, patientName: $patientName, procedure: $procedure, type: $bookingType, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper getters for UI
  String get displayName => patientName ?? 'Unknown Patient';
  String get displayProcedure => procedure ?? indication ?? 'No procedure specified';
  String get displayUrgency => urgency ?? 'Not specified';
  String get displayConsultant => consultant ?? 'Not assigned';
  String get displayStatus => status.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)).join(' ');
  
  bool get isOR => bookingType == 'OR';
  bool get isICU => bookingType == 'ICU';
  bool get isPending => status == 'pending';
  bool get isCompleted => outcome != null && outcome!.isNotEmpty;
  
  // Status color helpers for UI
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'orange';
      case 'confirmed':
      case 'seen_accepted':
        return 'green';
      case 'rejected':
      case 'cancelled':
        return 'red';
      case 'waitlisted':
        return 'blue';
      default:
        return 'grey';
    }
  }
  
  // Urgency color helpers for UI
  String get urgencyColor {
    switch (urgency?.toLowerCase()) {
      case 'e1':
      case 'critical':
        return 'red';
      case 'e2':
        return 'orange';
      case 'e3':
      case 'elective':
        return 'green';
      default:
        return 'grey';
    }
  }
}
