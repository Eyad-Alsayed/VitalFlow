import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../common/comments_section.dart';
import '../../models/booking_comment.dart';
import '../../models/or_booking.dart';
import '../../services/auth_service.dart';
import '../../widgets/urgency_chip.dart';
import '../../widgets/app_bar_actions.dart';

class ORBookingDetailScreen extends ConsumerWidget {
  final String bookingId;

  const ORBookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df = DateFormat('y-MM-dd HH:mm');
    final future = ref.watch(_orBookingFutureProvider(bookingId));
    final userAsync = ref.watch(userInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OR Booking Details'),
        actions: const [HomeActionButton(), LogoutActionButton()],
      ),
      body: future.when(
        data: (b) {
          if (b == null) {
            return const Center(child: Text('Booking not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${b.patientMrn} — ${b.procedure}', style: Theme.of(context).textTheme.titleLarge),
              if (b.patientName.isNotEmpty)
                Text(b.patientName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Urgency: ${b.urgencyLevel.displayName}'),
              Row(
                children: [
                  UrgencyChip(level: b.urgencyLevel),
                  const Spacer(),
                  Text('Status: '),
                  Text(_orStatusLabel(b.status), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  _ORStatusEditor(bookingId: b.id!, current: b.status),
                ],
              ),
              const Divider(height: 32),
              Text('Requested: ${df.format(b.requestedAt)}'),
              const SizedBox(height: 8),
              Text('Consultant: ${b.contact.consultantName}'),
              Text('Consultant Phone: ${b.contact.consultantPhone}'),
              Text('Requesting Physician: ${b.contact.requestingPhysician}'),
              Text('Requesting Physician Phone: ${b.contact.requestingPhysicianPhone}'),
              const SizedBox(height: 8),
              
              // Outcome dropdown (only for anesthesia staff)
              userAsync.when(
                data: (user) {
                  if (user?.role.toLowerCase() == 'anesthesia') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 32),
                        Row(
                          children: [
                            const Text('Outcome: ', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: b.outcome,
                              hint: const Text('Select outcome'),
                              items: const [
                                DropdownMenuItem(value: 'OR Done', child: Text('OR Done')),
                                DropdownMenuItem(value: 'OR Cancelled', child: Text('OR Cancelled')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  _handleOutcome(context, ref, b.id!, value, b.procedure);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              
              const Divider(height: 32),
              CommentsSection(
                bookingId: b.id!,
                contextType: BookingContext.or,
              ),
            ],
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
                Text('Failed to load booking:\n$e', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleOutcome(BuildContext context, WidgetRef ref, String bookingId, String outcome, String procedure) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark this OR as "$outcome"?'),
        content: Text('Procedure: $procedure'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: outcome == 'OR Cancelled' ? Colors.red : null,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(databaseServiceProvider).updateOROutcome(bookingId, outcome);
        ref.invalidate(_orBookingFutureProvider(bookingId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Outcome updated to "$outcome"')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update outcome: $e')),
          );
        }
      }
    }
  }
}

final _orBookingFutureProvider = FutureProvider.family((ref, String id) async {
  final fs = ref.read(databaseServiceProvider);
  return fs.getORBooking(id);
});

String _orStatusLabel(ORBookingStatus s) {
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

class _ORStatusEditor extends ConsumerStatefulWidget {
  final String bookingId;
  final ORBookingStatus current;
  const _ORStatusEditor({required this.bookingId, required this.current});

  @override
  ConsumerState<_ORStatusEditor> createState() => _ORStatusEditorState();
}

class _ORStatusEditorState extends ConsumerState<_ORStatusEditor> {
  bool _updating = false;

  Future<void> _update(ORBookingStatus s) async {
    setState(() => _updating = true);
    try {
      await ref.read(databaseServiceProvider).updateORBookingStatus(widget.bookingId, s);
      // Refresh details
      ref.invalidate(_orBookingFutureProvider(widget.bookingId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${_orStatusLabel(s)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(userRoleProvider);
    return roleAsync.when(
      data: (role) {
        // Only anesthesia can edit OR booking status
        if (role != UserRole.anesthesia) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: DropdownButton<ORBookingStatus>(
            value: widget.current,
            onChanged: _updating ? null : (val) {
              if (val == null || val == widget.current) return;
              _update(val);
            },
            items: [
              ORBookingStatus.pending,
              ORBookingStatus.seenAccepted,
              ORBookingStatus.awaitingResources,
            ]
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(_orStatusLabel(s)),
                    ))
                .toList(),
          ),
        );
      },
      loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}
