import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logger_service.dart';
import 'api_service.dart';

enum UserRole {
  applicant('Applicant'),
  anesthesia('Anesthesia'),
  icuTeam('ICU Team'),
  admin('Admin');

  const UserRole(this.displayName);
  final String displayName;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'applicant':
        return UserRole.applicant;
      case 'anesthesia':
        return UserRole.anesthesia;
      case 'icu team':
      case 'icu_team':
        return UserRole.icuTeam;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.applicant;
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}

class SimpleUser {
  final String name;
  final UserRole role;
  const SimpleUser({required this.name, required this.role});
}

class SimpleUserInfo {
  final String displayName;
  final String role; // 'applicant' | 'anesthesia' | 'icu_team'
  final String uid;
  const SimpleUserInfo({required this.displayName, required this.role, required this.uid});
}

class AuthService extends StateNotifier<AsyncValue<SimpleUser?>> {
  AuthService() : super(const AsyncValue.data(null));

  SimpleUser? get currentUser => state.hasValue ? state.value : null;
  bool get isLoggedIn => currentUser != null;

  Future<UserRole> getUserRole() async {
    final user = currentUser;
    if (user == null) throw const AuthException('No user logged in');
    return user.role;
  }

  Future<SimpleUser?> getUserInfo() async {
    return currentUser;
  }

  // Applicant sign-in: name only
  Future<void> signInApplicant({required String name}) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) {
      throw const AuthException('Please enter your name');
    }
    LoggerService.info('Applicant sign-in: $cleaned');
    state = AsyncValue.data(SimpleUser(name: cleaned, role: UserRole.applicant));
  }

  // Staff login with role-specific passwords
  Future<void> signInStaff({
    required String name,
    required String password,
    required UserRole role,
  }) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) {
      throw const AuthException('Please enter your name');
    }
    LoggerService.info('Attempting simplified staff login for: $cleaned as ${role.name}');
    
    // Check password based on role
    if (role == UserRole.admin) {
      // =======================================================================
      // ADMIN PASSWORD - TO BE CONFIGURED BY IT DEPARTMENT
      // =======================================================================
      // IMPORTANT: Change this default password immediately after deployment!
      // Consider moving to environment variable or backend authentication.
      // =======================================================================
      const String adminPassword = 'CHANGE_ME_ADMIN_PASSWORD';  // TODO: Set secure admin password
      if (password != adminPassword) {
        throw const AuthException('Incorrect password');
      }
    } else {
      // For staff, verify password via backend
      try {
        final isValid = await ApiService.verifyStaffPassword(password);
        if (!isValid) {
          throw const AuthException('Incorrect password');
        }
      } catch (e) {
        LoggerService.error('Error verifying staff password', e, StackTrace.current);
        throw const AuthException('Authentication error. Please try again.');
      }
    }
    
    state = AsyncValue.data(SimpleUser(name: cleaned, role: role));
    LoggerService.info('Simplified staff login successful');
  }

  Future<void> signOut() async {
    LoggerService.info('Signing out user');
    state = const AsyncValue.data(null);
  }
}

// Providers
final authServiceProvider = StateNotifierProvider<AuthService, AsyncValue<SimpleUser?>>((ref) {
  return AuthService();
});

final currentUserProvider = Provider<SimpleUser?>((ref) {
  final authState = ref.watch(authServiceProvider);
  return authState.maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );
});

final userRoleProvider = FutureProvider<UserRole?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return UserRole.applicant; // default applicant role
  return user.role;
});

String _roleToString(UserRole role) =>
    role == UserRole.icuTeam ? 'icu_team' : role.name; // map icuTeam -> icu_team

final userInfoProvider = FutureProvider<SimpleUserInfo?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    // Default, unauthenticated applicant experience
    return const SimpleUserInfo(
      displayName: 'Applicant',
      role: 'applicant',
      uid: 'applicant',
    );
  }
  final displayName = user.name;
  // Create a simple uid from the name
  var uid = user.name.toLowerCase();
  uid = uid.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  uid = uid.replaceFirst(RegExp(r'^-+'), '');
  uid = uid.replaceFirst(RegExp(r'-+$'), '');
  return SimpleUserInfo(
    displayName: displayName,
    role: _roleToString(user.role),
    uid: uid.isEmpty ? 'user' : uid,
  );
});
