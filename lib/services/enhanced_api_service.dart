import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking.dart';
import '../models/comment.dart';

class EnhancedApiService {
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
  
  // User session management
  static String? currentUserName;
  static String? currentUserRole;
  
  static Future<void> createSession(String userName, String userRole) async {
    currentUserName = userName;
    currentUserRole = userRole;
    
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_name': userName,
        'user_role': userRole,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to create session: ${response.body}');
    }
  }
  
  // Enhanced booking operations
  static Future<List<Booking>> getBookings({
    int skip = 0,
    int limit = 100,
    String? typeFilter,
    String? statusFilter,
    bool activeOnly = true,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      'active_only': activeOnly.toString(),
    };
    
    if (typeFilter != null) queryParams['type_filter'] = typeFilter;
    if (statusFilter != null) queryParams['status_filter'] = statusFilter;
    
    final uri = Uri.parse('$baseUrl/bookings/').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Booking.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load bookings: ${response.body}');
    }
  }
  
  static Future<Booking> getBooking(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/bookings/$id'));
    
    if (response.statusCode == 200) {
      return Booking.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Booking not found');
    } else {
      throw Exception('Failed to load booking: ${response.body}');
    }
  }
  
  static Future<Booking> createBooking(Booking booking) async {
    // Add current user info if available
    final bookingData = booking.toJson();
    if (currentUserName != null) {
      bookingData['created_by_name'] = currentUserName;
    }
    if (currentUserRole != null) {
      bookingData['created_by_role'] = currentUserRole;
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bookingData),
    );
    
    if (response.statusCode == 200) {
      return Booking.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create booking: ${response.body}');
    }
  }
  
  static Future<Booking> updateBooking(int id, Map<String, dynamic> updates) async {
    // Add current user info for audit trail
    if (currentUserName != null) {
      updates['updated_by_name'] = currentUserName;
    }
    if (currentUserRole != null) {
      updates['updated_by_role'] = currentUserRole;
    }
    
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updates),
    );
    
    if (response.statusCode == 200) {
      return Booking.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Booking not found');
    } else {
      throw Exception('Failed to update booking: ${response.body}');
    }
  }
  
  static Future<void> deleteBooking(int id) async {
    final queryParams = <String, String>{};
    if (currentUserName != null) {
      queryParams['deleted_by_name'] = currentUserName!;
    }
    if (currentUserRole != null) {
      queryParams['deleted_by_role'] = currentUserRole!;
    }
    
    final uri = Uri.parse('$baseUrl/bookings/$id').replace(queryParameters: queryParams);
    final response = await http.delete(uri);
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete booking: ${response.body}');
    }
  }
  
  // Comment operations
  static Future<List<Comment>> getComments(int bookingId, {bool includeInternal = false}) async {
    final queryParams = {'include_internal': includeInternal.toString()};
    final uri = Uri.parse('$baseUrl/bookings/$bookingId/comments/').replace(queryParameters: queryParams);
    
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load comments: ${response.body}');
    }
  }
  
  static Future<Comment> addComment(int bookingId, String message, {bool isInternal = false}) async {
    if (currentUserName == null || currentUserRole == null) {
      throw Exception('User session required to add comments');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/comments/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'author_name': currentUserName,
        'author_role': currentUserRole,
        'is_internal': isInternal,
      }),
    );
    
    if (response.statusCode == 200) {
      return Comment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add comment: ${response.body}');
    }
  }
  
  // Statistics and reporting
  static Future<Map<String, dynamic>> getBookingStats() async {
    final response = await http.get(Uri.parse('$baseUrl/bookings/stats/summary'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load statistics: ${response.body}');
    }
  }
  
  // Audit log
  static Future<List<Map<String, dynamic>>> getAuditLog(int bookingId) async {
    final response = await http.get(Uri.parse('$baseUrl/bookings/$bookingId/audit-log'));
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load audit log: ${response.body}');
    }
  }
  
  // Active sessions
  static Future<List<Map<String, dynamic>>> getActiveSessions() async {
    final response = await http.get(Uri.parse('$baseUrl/sessions/active'));
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load active sessions: ${response.body}');
    }
  }
  
  // Convenience methods for specific booking types
  static Future<List<Booking>> getORBookings({String? statusFilter}) async {
    return getBookings(typeFilter: 'OR', statusFilter: statusFilter);
  }
  
  static Future<List<Booking>> getICUBookings({String? statusFilter}) async {
    return getBookings(typeFilter: 'ICU', statusFilter: statusFilter);
  }
  
  // Status update shortcuts
  static Future<Booking> updateBookingStatus(int id, String newStatus, {String? notes}) async {
    final updates = <String, dynamic>{'status': newStatus};
    if (notes != null && notes.isNotEmpty) {
      // Add a comment along with status update
      await addComment(id, 'Status updated to: $newStatus. Notes: $notes');
    }
    return updateBooking(id, updates);
  }
  
  static Future<Booking> updateBookingOutcome(int id, String outcome, {String? notes}) async {
    final updates = <String, dynamic>{'outcome': outcome};
    if (notes != null && notes.isNotEmpty) {
      await addComment(id, 'Outcome updated to: $outcome. Notes: $notes');
    }
    return updateBooking(id, updates);
  }
  
  // Search and filter helpers
  static Future<List<Booking>> searchBookings(String searchTerm) async {
    // Get all bookings and filter client-side
    // In a production app, you'd want server-side search
    final allBookings = await getBookings(limit: 1000);
    
    final searchLower = searchTerm.toLowerCase();
    return allBookings.where((booking) {
      return booking.mrn?.toLowerCase().contains(searchLower) == true ||
             booking.patientName?.toLowerCase().contains(searchLower) == true ||
             booking.procedure?.toLowerCase().contains(searchLower) == true ||
             booking.consultant?.toLowerCase().contains(searchLower) == true ||
             booking.requestingPhysician?.toLowerCase().contains(searchLower) == true;
    }).toList();
  }
  
  // Health check
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}