import 'dart:convert';
import 'package:intl/intl.dart';

import '../models/or_booking.dart' as or_model;
import '../models/icu_bed_request.dart' as icu_model;
import 'csv_download.dart';

class CsvExportService {
  static String _escape(String v) {
    final s = v.replaceAll('"', '""');
    return '"$s"';
  }

  static String exportORBookings(List<or_model.ORBooking> items) {
    final dfDateTime = DateFormat('y-MM-dd HH:mm');
    final header = [
      'ID',
      'Patient MRN',
      'Procedure',
      'Urgency',
      'Status',
      'Requested At',
      'Last Updated At',
      'Consultant Name',
      'Consultant Phone',
      'Requesting Physician',
      'Requesting Physician Phone',
      'Anesthesia On-call',
      'Created By (Name)',
      'Created By (Role)',
    ];
    final rows = <String>[];
    rows.add(header.map(_escape).join(','));
    for (final b in items) {
      rows.add([
        b.id ?? '',
        b.patientMrn,
        b.procedure,
        b.urgencyLevel.displayName,
        b.status.name,
        dfDateTime.format(b.requestedAt),
        dfDateTime.format(b.lastUpdatedAt),
        b.contact.consultantName,
        b.contact.consultantPhone,
        b.contact.requestingPhysician,
        b.contact.requestingPhysicianPhone,
        b.contact.anesthesiaTeamContact,
        b.createdBy.displayName,
        b.createdBy.role,
      ].map(_escape).join(','));
    }
    return const LineSplitter().convert(rows.join('\n')).join('\n');
  }

  static String exportICURequests(List<icu_model.ICUBedRequest> items) {
    final dfDate = DateFormat('y-MM-dd');
    final dfDateTime = DateFormat('y-MM-dd HH:mm');
    final header = [
      'ID',
      'Patient MRN',
      'Indication',
      'Urgency',
      'Status',
      'Requested At',
      'Requested Date',
      'Last Updated At',
      'Consultant Name',
      'Consultant Phone',
      'Requesting Physician',
      'Requesting Physician Phone',
      'Created By (Name)',
      'Created By (Role)',
    ];
    final rows = <String>[];
    rows.add(header.map(_escape).join(','));
    for (final r in items) {
      rows.add([
        r.id ?? '',
        r.patientMrn,
        r.indication,
        r.urgencyLevel.displayName,
        r.status.name,
        dfDateTime.format(r.requestedAt),
        r.requestedDate != null ? dfDate.format(r.requestedDate!) : '',
        dfDateTime.format(r.lastUpdatedAt),
        r.contact.consultantName,
        r.contact.consultantPhone,
        r.contact.requestingPhysician,
        r.contact.requestingPhysicianPhone,
        r.createdBy.displayName,
        r.createdBy.role,
      ].map(_escape).join(','));
    }
    return const LineSplitter().convert(rows.join('\n')).join('\n');
  }

  static Future<void> downloadCsv(String filename, String csv) async {
    await downloadCsvFile(filename, csv);
  }
}
