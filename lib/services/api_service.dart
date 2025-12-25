import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/or_booking.dart';
import '../models/icu_bed_request.dart';
import '../models/booking_comment.dart';

class ApiService {
  // ==========================================================================
  // API CONFIGURATION - TO BE CONFIGURED BY IT DEPARTMENT
  // ==========================================================================
  // Replace this URL with your hospital's backend server address
  // Examples:
  //   Local server:    'http://192.168.1.100:8000'
  //   Hospital server: 'https://medical-api.hospital.local'
  //   Cloud server:    'https://your-api-server.com'
  // ==========================================================================
  static const String baseUrl = 'http://localhost:8000';  // TODO: Configure your server URL
  
  static final http.Client _client = http.Client();
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // OR Bookings
  static Future<List<ORBooking>> getORBookings() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/or-bookings'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ORBooking.fromMap(json)).toList();
      }
      throw Exception('Failed to load OR bookings: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<ORBooking> getORBooking(String id) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/or-bookings/$id'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return ORBooking.fromMap(json.decode(response.body));
    }
    throw Exception('Failed to load OR booking');
  }

  static Future<ORBooking> createORBooking(ORBooking booking) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/or-bookings'),
      headers: _headers,
      body: json.encode(booking.toMap()),
    );
    
    if (response.statusCode == 200) {
      return ORBooking.fromMap(json.decode(response.body));
    }
    throw Exception('Failed to create OR booking');
  }

  static Future<void> updateORStatus(String bookingId, ORBookingStatus status) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/or-bookings/$bookingId/status'),
      headers: _headers,
      body: json.encode({'status': status.toString().split('.').last}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update OR status');
    }
  }

  static Future<void> updateOROutcome(String id, String outcome) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/or-bookings/$id/outcome'),
      headers: _headers,
      body: json.encode({'outcome': outcome}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update OR outcome');
    }
  }

  // ICU Requests
  static Future<List<ICUBedRequest>> getICURequests() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/icu-requests'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ICUBedRequest.fromMap(json)).toList();
      }
      throw Exception('Failed to load ICU requests: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<ICUBedRequest> getICURequest(String id) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/icu-requests/$id'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return ICUBedRequest.fromMap(json.decode(response.body));
    }
    throw Exception('Failed to load ICU request');
  }

  static Future<ICUBedRequest> createICURequest(ICUBedRequest request) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/icu-requests'),
      headers: _headers,
      body: json.encode(request.toMap()),
    );
    
    if (response.statusCode == 200) {
      return ICUBedRequest.fromMap(json.decode(response.body));
    }
    throw Exception('Failed to create ICU request');
  }

  static Future<void> updateICUStatus(String requestId, ICUBookingStatus status) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/icu-requests/$requestId/status'),
      headers: _headers,
      body: json.encode({'status': status.toString().split('.').last}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update ICU status');
    }
  }

  static Future<void> rescheduleICURequest(String requestId, ICUBookingStatus status, DateTime newDate) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/icu-requests/$requestId'),
      headers: _headers,
      body: json.encode({
        'status': status.toString().split('.').last,
        'requested_date': newDate.toIso8601String(),
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to reschedule ICU request');
    }
  }

  static Future<ICUBedRequest> confirmICURequest(String id, String unit, String room) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/icu-requests/$id/confirm'),
      headers: _headers,
      body: json.encode({
        'unit': unit,
        'room': room,
      }),
    );
    
    if (response.statusCode == 200) {
      return ICUBedRequest.fromMap(json.decode(response.body));
    }
    throw Exception('Failed to confirm ICU request');
  }

  static Future<void> updateICUOutcome(String id, String outcome) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/icu-requests/$id/outcome'),
      headers: _headers,
      body: json.encode({'outcome': outcome}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update ICU outcome');
    }
  }

  // Comments
  static Future<List<BookingComment>> getComments(String bookingId, String context) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/comments?booking_id=$bookingId&context=$context'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => BookingComment.fromMap(json)).toList();
    }
    throw Exception('Failed to load comments');
  }

  static Future<BookingComment> createComment(BookingComment comment) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/comments'),
      headers: _headers,
      body: json.encode(comment.toMap()),
    );
    
    if (response.statusCode == 200) {
      return BookingComment.fromMap(json.decode(response.body));
    }
    throw Exception('Failed to create comment');
  }

  // Admin - Password Management
  static Future<void> updateStaffPassword(String newPassword) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/admin/staff-password'),
      headers: _headers,
      body: json.encode({'password': newPassword}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update staff password');
    }
  }

  static Future<bool> verifyStaffPassword(String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/admin/verify-staff-password'),
      headers: _headers,
      body: json.encode({'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['valid'] as bool;
    }
    throw Exception('Failed to verify staff password');
  }
}