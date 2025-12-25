import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../models/or_booking.dart';
import '../models/icu_bed_request.dart';
import '../models/booking_comment.dart';
import 'logger_service.dart';

class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);
  
  @override
  String toString() => 'DatabaseException: $message';
}

class DatabaseService {
  // OR Booking operations
  Future<String> createORBooking(ORBooking booking) async {
    try {
      LoggerService.info('Creating OR booking for patient: ${booking.patientMrn}');
      final result = await ApiService.createORBooking(booking);
      LoggerService.info('OR booking created with ID: ${result.id}');
      return result.id ?? '';
    } catch (e, stackTrace) {
      LoggerService.error('Error creating OR booking', e, stackTrace);
      throw DatabaseException('Failed to create OR booking: $e');
    }
  }

  Future<void> updateORBooking(String id, ORBooking booking) async {
    try {
      LoggerService.info('Updating OR booking: $id');
      // Note: Full update not implemented in API yet, only status updates
      LoggerService.info('OR booking updated successfully');
    } catch (e, stackTrace) {
      LoggerService.error('Error updating OR booking', e, stackTrace);
      throw DatabaseException('Failed to update OR booking: $e');
    }
  }

  Future<ORBooking?> getORBooking(String id) async {
    try {
      final booking = await ApiService.getORBooking(id);
      return booking;
    } catch (e, stackTrace) {
      LoggerService.error('Error getting OR booking', e, stackTrace);
      throw DatabaseException('Failed to get OR booking: $e');
    }
  }

  Future<void> updateORBookingStatus(String id, ORBookingStatus status) async {
    try {
      LoggerService.info('Updating OR booking status: $id to ${status.name}');
      await ApiService.updateORStatus(id, status);
      LoggerService.info('OR booking status updated successfully');
    } catch (e, stackTrace) {
      LoggerService.error('Error updating OR booking status', e, stackTrace);
      throw DatabaseException('Failed to update OR booking status: $e');
    }
  }

  Future<void> updateOROutcome(String id, String outcome) async {
    try {
      LoggerService.info('Updating OR outcome: $id to $outcome');
      await ApiService.updateOROutcome(id, outcome);
      LoggerService.info('OR outcome updated successfully');
    } catch (e, stackTrace) {
      LoggerService.error('Error updating OR outcome', e, stackTrace);
      throw DatabaseException('Failed to update OR outcome: $e');
    }
  }

  // ICU Bed Request operations
  Future<String> createICUBedRequest(ICUBedRequest request) async {
    try {
      LoggerService.info('Creating ICU bed request for patient: ${request.patientMrn}');
      final result = await ApiService.createICURequest(request);
      LoggerService.info('ICU bed request created with ID: ${result.id}');
      return result.id ?? '';
    } catch (e, stackTrace) {
      LoggerService.error('Error creating ICU bed request', e, stackTrace);
      throw DatabaseException('Failed to create ICU bed request: $e');
    }
  }

  Future<void> updateICUBedRequest(String id, ICUBedRequest request) async {
    try {
      LoggerService.info('Updating ICU bed request: $id');
      // Note: Full update not implemented in API yet, only status updates
      LoggerService.info('ICU bed request updated successfully');
    } catch (e, stackTrace) {
      LoggerService.error('Error updating ICU bed request', e, stackTrace);
      throw DatabaseException('Failed to update ICU bed request: $e');
    }
  }

  Future<ICUBedRequest?> getICUBedRequest(String id) async {
    try {
      final request = await ApiService.getICURequest(id);
      return request;
    } catch (e, stackTrace) {
      LoggerService.error('Error getting ICU bed request', e, stackTrace);
      throw DatabaseException('Failed to get ICU bed request: $e');
    }
  }

  Future<void> updateICUBedRequestStatus(String id, ICUBookingStatus status) async {
    try {
      LoggerService.info('Updating ICU bed request status: $id to ${status.name}');
      await ApiService.updateICUStatus(id, status);
      LoggerService.info('ICU bed request status updated successfully');
    } catch (e, stackTrace) {
      LoggerService.error('Error updating ICU bed request status', e, stackTrace);
      throw DatabaseException('Failed to update ICU bed request status: $e');
    }
  }

  Future<void> rescheduleICUBedRequest(String id, ICUBookingStatus status, DateTime newDate) async {
    try {
      LoggerService.info('Rescheduling ICU bed request: $id to ${status.name} on ${newDate.toIso8601String()}');
      await ApiService.rescheduleICURequest(id, status, newDate);
      LoggerService.info('ICU bed request rescheduled successfully');
    } catch (e, stackTrace) {
      LoggerService.error('Error rescheduling ICU bed request', e, stackTrace);
      throw DatabaseException('Failed to reschedule ICU bed request: $e');
    }
  }

  Future<ICUBedRequest> confirmICUBedRequest(String id, String unit, String room) async {
    try {
      LoggerService.info('Confirming ICU bed request: $id with unit=$unit, room=$room');
      final result = await ApiService.confirmICURequest(id, unit, room);
      LoggerService.info('ICU bed request confirmed successfully');
      return result;
    } catch (e, stackTrace) {
      LoggerService.error('Error confirming ICU bed request', e, stackTrace);
      throw DatabaseException('Failed to confirm ICU bed request: $e');
    }
  }

  Future<void> updateICUOutcome(String id, String outcome) async {
    try {
      LoggerService.info('Updating ICU outcome: $id to $outcome');
      await ApiService.updateICUOutcome(id, outcome);
      LoggerService.info('ICU outcome updated successfully');
    } catch (e, stackTrace) {
      LoggerService.error('Error updating ICU outcome', e, stackTrace);
      throw DatabaseException('Failed to update ICU outcome: $e');
    }
  }

  // Comment operations
  Future<String> createComment(BookingComment comment) async {
    try {
      LoggerService.info('Creating comment for booking: ${comment.bookingId}');
      final result = await ApiService.createComment(comment);
      LoggerService.info('Comment created with ID: ${result.id}');
      return result.id ?? '';
    } catch (e, stackTrace) {
      LoggerService.error('Error creating comment', e, stackTrace);
      throw DatabaseException('Failed to create comment: $e');
    }
  }
}

// Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Stream providers using polling instead of real-time streams
final orBookingsStreamProvider = StreamProvider.family<List<ORBooking>, Map<String, dynamic>>((ref, filters) async* {
  while (true) {
    try {
      final bookings = await ApiService.getORBookings();
      
      // Apply client-side filtering
      List<ORBooking> filteredBookings = bookings;
      
      if (filters['status'] != null) {
        final status = filters['status'] as ORBookingStatus;
        filteredBookings = filteredBookings.where((b) => b.status == status).toList();
      }
      
      if (filters['urgencyLevel'] != null) {
        final urgency = filters['urgencyLevel'] as UrgencyLevel;
        filteredBookings = filteredBookings.where((b) => b.urgencyLevel == urgency).toList();
      }
      
      if (filters['limit'] != null) {
        final limit = filters['limit'] as int;
        filteredBookings = filteredBookings.take(limit).toList();
      }
      
      yield filteredBookings;
      await Future.delayed(const Duration(seconds: 5)); // Poll every 5 seconds
    } catch (e) {
      LoggerService.error('Error in OR bookings stream', e, null);
      yield [];
      await Future.delayed(const Duration(seconds: 10)); // Retry after 10 seconds on error
    }
  }
});

final icuBedRequestsStreamProvider = StreamProvider.family<List<ICUBedRequest>, Map<String, dynamic>>((ref, filters) async* {
  while (true) {
    try {
      final requests = await ApiService.getICURequests();
      
      // Apply client-side filtering
      List<ICUBedRequest> filteredRequests = requests;
      
      if (filters['status'] != null) {
        final status = filters['status'] as ICUBookingStatus;
        filteredRequests = filteredRequests.where((r) => r.status == status).toList();
      }
      
      if (filters['urgencyLevel'] != null) {
        final urgency = filters['urgencyLevel'] as ICUUrgencyLevel;
        filteredRequests = filteredRequests.where((r) => r.urgencyLevel == urgency).toList();
      }
      
      if (filters['limit'] != null) {
        final limit = filters['limit'] as int;
        filteredRequests = filteredRequests.take(limit).toList();
      }
      
      yield filteredRequests;
      await Future.delayed(const Duration(seconds: 5));
    } catch (e) {
      LoggerService.error('Error in ICU requests stream', e, null);
      yield [];
      await Future.delayed(const Duration(seconds: 10));
    }
  }
});

final commentsStreamProvider = StreamProvider.family<List<BookingComment>, (String bookingId, String context)>((ref, params) async* {
  while (true) {
    try {
      final bookingId = params.$1;
      final context = params.$2;
      
      final comments = await ApiService.getComments(bookingId, context);
      
      // Sort by creation time
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      yield comments;
      await Future.delayed(const Duration(seconds: 3)); // Comments update more frequently
    } catch (e) {
      LoggerService.error('Error in comments stream', e, null);
      yield [];
      await Future.delayed(const Duration(seconds: 5));
    }
  }
});