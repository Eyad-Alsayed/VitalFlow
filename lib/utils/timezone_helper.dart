/// Helper functions for handling Riyadh timezone (GMT+3)
library;

/// Parse a datetime string from the backend API.
/// The backend stores times in Riyadh timezone but may send them without timezone info.
/// We need to interpret them as Riyadh time (add 3 hours from UTC).
DateTime parseRiyadhDateTime(String dateTimeString) {
  // Parse the datetime string (will be treated as UTC by default)
  DateTime dt = DateTime.parse(dateTimeString);
  
  // If it ends with 'Z', it's UTC - add 3 hours for Riyadh
  if (dateTimeString.endsWith('Z')) {
    return dt.add(const Duration(hours: 3));
  }
  
  // If it has explicit +03:00 offset, keep as-is
  if (dateTimeString.contains('+03:00')) {
    return dt;
  }
  
  // Otherwise, backend sent it as naive datetime in Riyadh time
  // Treat as UTC and add 3 hours
  return dt.add(const Duration(hours: 3));
}

/// Get current datetime in Riyadh timezone (for creating new records)
DateTime nowRiyadh() {
  // This will be sent to backend and stored correctly
  return DateTime.now().toUtc().add(const Duration(hours: 3));
}
