import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_bar_actions.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: const [LogoutActionButton()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Registry Exports',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Download monthly registry data as CSV files',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 300,
                height: 60,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.medical_services, size: 28),
                  label: const Text('OR Registry', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showMonthPicker(context, 'OR'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                height: 60,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.local_hospital, size: 28),
                  label: const Text('ICU Registry', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showMonthPicker(context, 'ICU'),
                ),
              ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                width: 300,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.lock_reset, size: 24),
                  label: const Text('Change Staff Password', style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange, width: 2),
                  ),
                  onPressed: () => context.push('/admin/password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMonthPicker(BuildContext context, String type) async {
    final now = DateTime.now();
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthPickerDialog(initialDate: now),
    );

    if (result == null || !context.mounted) return;

    final month = result.month;
    final year = result.year;

    // Build export URL
    final url = type == 'OR'
        ? '${ApiService.baseUrl}/api/export/or-bookings?month=$month&year=$year'
        : '${ApiService.baseUrl}/api/export/icu-requests?month=$month&year=$year';

    // Trigger download
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloading $type Registry for ${DateFormat('MMMM y').format(result)}')),
          );
        }
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e')),
        );
      }
    }
  }
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  const _MonthPickerDialog({required this.initialDate});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int selectedMonth;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.initialDate.month;
    selectedYear = widget.initialDate.year;
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final years = List.generate(5, (i) => DateTime.now().year - i);

    return AlertDialog(
      title: const Text('Select Month'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: selectedMonth,
            decoration: const InputDecoration(
              labelText: 'Month',
              border: OutlineInputBorder(),
            ),
            items: List.generate(12, (i) => i + 1)
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(months[m - 1]),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedMonth = value);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: selectedYear,
            decoration: const InputDecoration(
              labelText: 'Year',
              border: OutlineInputBorder(),
            ),
            items: years
                .map((y) => DropdownMenuItem(
                      value: y,
                      child: Text(y.toString()),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedYear = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(DateTime(selectedYear, selectedMonth));
          },
          child: const Text('Download'),
        ),
      ],
    );
  }
}
