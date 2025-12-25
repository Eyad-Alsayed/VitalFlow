import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/router.dart';
import '../../widgets/app_bar_actions.dart';

class ICURequestListScreen extends ConsumerWidget {
  const ICURequestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICU Requests'),
        actions: const [HomeActionButton(), LogoutActionButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BigButton(
              label: 'Confirmed for today',
              icon: Icons.event_available,
              onTap: () => context.go(AppRouter.icuConfirmedToday),
            ),
            const SizedBox(height: 16),
            _BigButton(
              label: 'Active requests',
              icon: Icons.playlist_add_check,
              onTap: () => context.go(AppRouter.icuActive),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/icu-requests/create'),
        icon: const Icon(Icons.add),
        label: const Text('New ICU Request'),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _BigButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0),
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
