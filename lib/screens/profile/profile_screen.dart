import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userInfoProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: userAsync.when(
        data: (user) => user != null ? _buildProfile(user) : _buildNoUser(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildProfile(dynamic user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Display Name: ${user.displayName}'),
                  const SizedBox(height: 8),
                  Text('Role: ${user.role}'),
                  const SizedBox(height: 8),
                  Text('User ID: ${user.uid}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUser() {
    return const Center(
      child: Text('No user information available'),
    );
  }
}
