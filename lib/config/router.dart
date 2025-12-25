import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed auth import
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/or/or_booking_list_screen.dart';
import '../screens/or/or_booking_detail_screen.dart';
import '../screens/or/create_or_booking_screen.dart';
import '../screens/or/or_registry_screen.dart';
import '../screens/icu/icu_request_list_screen.dart';
import '../screens/icu/icu_detail_screen.dart';
import '../screens/icu/create_icu_request_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/icu/icu_applicant_hub_screen.dart';
import '../screens/icu/icu_filtered_list_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/password_management_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String home = '/';
  static const String orBookings = '/or-bookings';
  static const String orRegistry = '/or-registry';
  static const String orBookingDetail = '/or-bookings/:id';
  static const String createOrBooking = '/or-bookings/create';
  static const String icuRequests = '/icu-requests';
  static const String icuRegistry = '/icu-registry';
  static const String icuRequestDetail = '/icu-requests/:id';
  static const String createIcuRequest = '/icu-requests/create';
  static const String profile = '/profile';
  // Applicant ICU status routes
  static const String icuApplicantHub = '/icu/status';
  static const String icuConfirmedToday = '/icu/status/confirmed-today';
  static const String icuActive = '/icu/status/active';
  static const String admin = '/admin';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Start the app on the login page always
  return GoRouter(
    initialLocation: AppRouter.login,
    routes: [
      GoRoute(
        path: AppRouter.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRouter.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRouter.orBookings,
        name: 'or-bookings',
        builder: (context, state) => const ORBookingListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'create-or-booking',
            builder: (context, state) => const CreateORBookingScreen(),
          ),
          GoRoute(
            path: ':id',
            name: 'or-booking-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ORBookingDetailScreen(bookingId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRouter.icuRequests,
        name: 'icu-requests',
        builder: (context, state) => const ICURequestListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'create-icu-request',
            builder: (context, state) => const CreateICURequestScreen(),
          ),
          GoRoute(
            path: ':id',
            name: 'icu-request-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ICUDetailScreen(requestId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRouter.orRegistry,
        name: 'or-registry',
        builder: (context, state) => const ORRegistryScreen(),
      ),
      GoRoute(
        path: AppRouter.icuRegistry,
        name: 'icu-registry',
        builder: (context, state) => const ICUFilteredListScreen(filter: ICUListFilter.registry),
      ),
      GoRoute(
        path: AppRouter.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRouter.admin,
        name: 'admin',
        builder: (context, state) => const AdminHomeScreen(),
        routes: [
          GoRoute(
            path: 'password',
            name: 'admin-password',
            builder: (context, state) => const PasswordManagementScreen(),
          ),
        ],
      ),
      // ICU Applicant Status routes
      GoRoute(
        path: AppRouter.icuApplicantHub,
        name: 'icu-applicant-hub',
        builder: (context, state) => const ICUApplicantHubScreen(),
        routes: [
          GoRoute(
            path: 'confirmed-today',
            name: 'icu-confirmed-today',
            builder: (context, state) => const ICUFilteredListScreen(filter: ICUListFilter.confirmedToday),
          ),
          GoRoute(
            path: 'active',
            name: 'icu-active',
            builder: (context, state) => const ICUFilteredListScreen(filter: ICUListFilter.active),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRouter.login),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Navigation helper extension
extension GoRouterExtension on GoRouter {
  void pushOrBookingDetail(String id) {
    push('/or-bookings/$id');
  }
  
  void pushICURequestDetail(String id) {
    push('/icu-requests/$id');
  }
  
  void pushCreateORBooking() {
    push('/or-bookings/create');
  }
  
  void pushCreateICURequest() {
    push('/icu-requests/create');
  }
}
