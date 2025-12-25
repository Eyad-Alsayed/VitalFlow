import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/or_booking.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/urgency_chip.dart';
import '../../widgets/app_bar_actions.dart';

class ORBookingListScreen extends ConsumerWidget {
  const ORBookingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBookings = ref.watch(orBookingsStreamProvider(const {}));
    final df = DateFormat('y-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('OR Bookings'),
        actions: const [HomeActionButton(), LogoutActionButton()],
      ),
      body: asyncBookings.when(
        data: (bookings) {
          // Filter out cancelled, done bookings, and bookings with outcomes
          final activeBookings = bookings.where((b) => 
            b.status != ORBookingStatus.cancelled && 
            b.status != ORBookingStatus.opDone &&
            b.outcome == null
          ).toList();
          
          if (activeBookings.isEmpty) {
            return const Center(child: Text('No active OR bookings'));
          }
          
          // Sort by urgency first (E1 > E2 > E3), then by requested time
          final sortedBookings = activeBookings
            ..sort((a, b) {
              // Compare urgency level first
              final urgencyCompare = _urgencyPriority(a.urgencyLevel).compareTo(_urgencyPriority(b.urgencyLevel));
              if (urgencyCompare != 0) return urgencyCompare;
              
              // If same urgency, sort by requested time (oldest first)
              return a.requestedAt.compareTo(b.requestedAt);
            });
          
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: sortedBookings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final b = sortedBookings[index];
              final isDelayed = _isDelayedOver24Hours(b);
              
              return Card(
                color: isDelayed ? Colors.red.shade50 : null,
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('${b.patientMrn} — ${b.procedure}')),
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
                      Text('Requested: ${df.format(b.requestedAt)}'),
                      Text('Consultant: ${b.contact.consultantName} • ${b.contact.consultantPhone}'),
                      Row(
                        children: [
                          Text('Status: ${_statusLabel(b.status)}'),
                          if (isDelayed) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Postponed > 24h',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                Text('Failed to load OR bookings:\n$e', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.refresh(orBookingsStreamProvider(const {})),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/or-bookings/create'),
        icon: const Icon(Icons.add),
        label: const Text('New OR Booking'),
      ),
    );
  }
}

String _statusLabel(ORBookingStatus s) {
  switch (s) {
    case ORBookingStatus.pending:
      return 'Pending';
    case ORBookingStatus.seenAccepted:
      return 'Seen & Accepted';
    case ORBookingStatus.awaitingResources:
  return 'Seen With New Requests';
    case ORBookingStatus.opDone:
      return 'Operation Done';
    case ORBookingStatus.cancelled:
      return 'Cancelled';
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

bool _isDelayedOver24Hours(ORBooking booking) {
  // Check if request is older than 24 hours and not completed
  if (booking.status == ORBookingStatus.opDone || 
      booking.status == ORBookingStatus.cancelled) {
    return false;
  }
  
  final now = DateTime.now();
  final hoursSinceRequest = now.difference(booking.requestedAt).inHours;
  return hoursSinceRequest > 24;
}
