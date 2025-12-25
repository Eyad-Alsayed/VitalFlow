import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_bar_actions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userInfoProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('VitalFlow'),
        actions: const [HomeActionButton(), LogoutActionButton()],
      ),
      body: userAsync.when(
        data: (user) => user != null ? _buildHomeContent(context, user) : _buildLoadingContent(),
        loading: () => _buildLoadingContent(),
        error: (error, stack) => _buildErrorContent(error),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, userInfo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.deepPurple.shade100,
                        child: Text(
                          userInfo.displayName.isNotEmpty 
                              ? userInfo.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.deepPurple.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${userInfo.displayName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Role: ${_formatRole(userInfo.role)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Role-based action cards
          _buildRoleBasedActions(context, userInfo.role),
        ],
      ),
    );
  }

  Widget _buildRoleBasedActions(BuildContext context, String role) {
    switch (role.toLowerCase()) {
      case 'applicant':
        return _buildApplicantActions(context);
      case 'anesthesia':
        return _buildAnesthesiaActions(context);
      case 'icu_team':
      case 'icu team':
        return _buildICUTeamActions(context);
      case 'admin':
        return const SizedBox.shrink(); // Admin goes directly to dashboard, no home actions
      default:
        return _buildApplicantActions(context); // Default to applicant
    }
  }

  Widget _buildApplicantActions(BuildContext context) {
    return Column(
      children: [
        _buildActionCard(
          context,
          title: 'OR',
          subtitle: 'Operating Room services',
          icon: Icons.emergency,
          color: Colors.red,
          onTap: () => _showOROptions(context),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          context,
          title: 'ICU',
          subtitle: 'ICU bed services',
          icon: Icons.bed,
          color: Colors.blue,
          onTap: () => _showICUOptions(context),
        ),
      ],
    );
  }

  void _showOROptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OR Services',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'Request Emergency OR',
              subtitle: 'Submit urgent operating room requests',
              icon: Icons.emergency,
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                context.push('/or-bookings/create');
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              title: 'View OR Status',
              subtitle: 'Check status of OR requests',
              icon: Icons.list_alt,
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                context.push('/or-bookings');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showICUOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ICU Services',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'Request ICU Bed',
              subtitle: 'Submit ICU bed reservation requests',
              icon: Icons.bed,
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                context.push('/icu-requests/create');
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              title: 'View ICU Status',
              subtitle: 'Check status of ICU requests',
              icon: Icons.monitor,
              color: Colors.teal,
              onTap: () {
                Navigator.pop(context);
                context.push('/icu/status');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnesthesiaActions(BuildContext context) {
    return Column(
      children: [
        _buildActionCard(
          context,
          title: 'OR Management',
          subtitle: 'Manage and respond to OR requests',
          icon: Icons.emergency,
          color: Colors.red,
          onTap: () => context.push('/or-bookings'),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          context,
          title: 'Create OR Request',
          subtitle: 'Submit new emergency OR request',
          icon: Icons.add_circle,
          color: Colors.orange,
          onTap: () => context.push('/or-bookings/create'),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          context,
          title: 'OR Registry',
          subtitle: 'View complete OR booking registry',
          icon: Icons.list_alt,
          color: Colors.purple,
          onTap: () => context.push('/or-registry'),
        ),
      ],
    );
  }

  Widget _buildICUTeamActions(BuildContext context) {
    return Column(
      children: [
        _buildActionCard(
          context,
          title: 'ICU Requests',
          subtitle: 'Review and respond to ICU bed requests',
          icon: Icons.bed,
          color: Colors.blue,
          onTap: () => context.push('/icu-requests'),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          context,
          title: 'ICU Registry',
          subtitle: 'View complete ICU bed registry',
          icon: Icons.monitor,
          color: Colors.teal,
          onTap: () => context.push('/icu-registry'),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          context,
          title: 'Request ICU Bed',
          subtitle: 'Submit new ICU bed request',
          icon: Icons.add_circle,
          color: Colors.green,
          onTap: () => context.push('/icu-requests/create'),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorContent(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading user information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'applicant':
        return 'Applicant';
      case 'anesthesia':
        return 'Anesthesia Staff';
      case 'icu_team':
      case 'icu team':
        return 'ICU Team';
      case 'admin':
        return 'Administrator';
      default:
        return role;
    }
  }
}
