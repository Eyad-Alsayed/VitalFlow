import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/or_booking.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/urgency_chip.dart';
import '../../widgets/app_bar_actions.dart';

class ORRegistryScreen extends ConsumerStatefulWidget {
  const ORRegistryScreen({super.key});

  @override
  ConsumerState<ORRegistryScreen> createState() => _ORRegistryScreenState();
}

class _ORRegistryScreenState extends ConsumerState<ORRegistryScreen> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Default to today
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final asyncBookings = ref.watch(orBookingsStreamProvider(const {}));
    final df = DateFormat('y-MM-dd');
    final dtf = DateFormat('y-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('OR Registry'),
        actions: const [HomeActionButton(), LogoutActionButton()],
      ),
      body: Column(
        children: [
          // Date filter
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate == null
                          ? 'Filter by Date'
                          : 'Date: ${df.format(_selectedDate!)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? now,
                        firstDate: DateTime(now.year - 1, 1, 1),
                        lastDate: now,
                      );
                      if (!mounted) return;
                      setState(() => _selectedDate = picked);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (_selectedDate != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedDate = null),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: asyncBookings.when(
              data: (bookings) {
                // Filter only bookings with outcomes set (OR Done or OR Cancelled)
                var filteredBookings = bookings.where((b) =>
                    b.outcome != null && b.outcome!.isNotEmpty).toList();

                // Apply date filter if selected
                if (_selectedDate != null) {
                  final selectedDay = DateTime(
                      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
                  filteredBookings = filteredBookings.where((b) {
                    final requestDay = DateTime(
                        b.requestedAt.year, b.requestedAt.month, b.requestedAt.day);
                    return requestDay == selectedDay;
                  }).toList();
                }

                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedDate != null
                          ? 'No completed/cancelled ORs for ${df.format(_selectedDate!)}'
                          : 'No completed/cancelled ORs',
                    ),
                  );
                }

                // Sort by urgency first, then by requested time
                filteredBookings.sort((a, b) {
                  final urgencyCompare = _urgencyPriority(a.urgencyLevel)
                      .compareTo(_urgencyPriority(b.urgencyLevel));
                  if (urgencyCompare != 0) return urgencyCompare;
                  return a.requestedAt.compareTo(b.requestedAt);
                });

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredBookings.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final b = filteredBookings[index];
                    // Use outcomeChangedAt if available, otherwise fall back to lastUpdatedAt
                    final statusTime = b.outcomeChangedAt ?? b.lastUpdatedAt;
                    final statusTimeStr = dtf.format(statusTime);

                    return Card(
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: Text('${b.patientMrn} — ${b.procedure}')),
                                const SizedBox(width: 8),
                                UrgencyChip(level: b.urgencyLevel),
                              ],
                            ),
                            if (b.patientName.isNotEmpty)
                              Text(b.patientName),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Requested: ${dtf.format(b.requestedAt)}'),
                            Text(
                              'Consultant: ${b.contact.consultantName} • ${b.contact.consultantPhone}',
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: b.outcome == 'OR Done'
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                b.outcome == 'OR Done'
                                    ? 'OR done at $statusTimeStr'
                                    : 'OR cancelled at $statusTimeStr',
                                style: TextStyle(
                                  color: b.outcome == 'OR Done'
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/or-bookings/${b.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Failed to load OR registry:\n$e',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () =>
                            ref.refresh(orBookingsStreamProvider(const {})),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int _urgencyPriority(UrgencyLevel level) {
  switch (level) {
    case UrgencyLevel.e1WithinOneHour:
      return 1;
    case UrgencyLevel.e2WithinSixHours:
      return 2;
    case UrgencyLevel.e3WithinTwentyFourHours:
      return 3;
  }
}
