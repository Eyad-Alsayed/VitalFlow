import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../common/comments_section.dart';
import '../../models/booking_comment.dart';
import '../../models/icu_bed_request.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_bar_actions.dart';

class ICUDetailScreen extends ConsumerWidget {
  final String requestId;
  
  const ICUDetailScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df = DateFormat('y-MM-dd');
    final future = ref.watch(_icuRequestFutureProvider(requestId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('ICU Request Details'),
        actions: const [HomeActionButton(), LogoutActionButton()],
      ),
      body: future.when(
        data: (r) {
          if (r == null) return const Center(child: Text('Request not found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${r.patientMrn} — ${r.indication}', style: Theme.of(context).textTheme.titleLarge),
              if (r.patientName.isNotEmpty)
                Text(r.patientName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Urgency: ${r.urgencyLevel.displayName}'),
              if (r.requestedDate != null) Text('Requested Date: ${df.format(r.requestedDate!)}'),
              Text('Status: ${r.status.name}'),
              _ICUStatusEditor(requestId: r.id!, current: r.status),
              const Divider(height: 32),
              Text('Requested: ${df.format(r.requestedAt)}'),
              const SizedBox(height: 8),
              Text('Consultant: ${r.contact.consultantName}'),
              Text('Consultant Phone: ${r.contact.consultantPhone}'),
              Text('Requesting Physician: ${r.contact.requestingPhysician}'),
              Text('Requesting Physician Phone: ${r.contact.requestingPhysicianPhone}'),
              const SizedBox(height: 8),
              if (r.unit != null && r.room != null) ...[
                const Divider(),
                Text('Unit: ${r.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Room: ${r.room}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 8),
              const Divider(height: 32),
              CommentsSection(
                bookingId: r.id!,
                contextType: BookingContext.icu,
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
                Text('Failed to load request:\n$e', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _icuRequestFutureProvider = FutureProvider.family((ref, String id) async {
  final fs = ref.read(databaseServiceProvider);
  return fs.getICUBedRequest(id);
});

String _icuStatusLabel(ICUBookingStatus s) {
  switch (s) {
    case ICUBookingStatus.pending:
      return 'Pending';
    case ICUBookingStatus.confirmed:
      return 'Confirmed';
    case ICUBookingStatus.noBedAvailable:
      return 'No Bed Available';
    case ICUBookingStatus.notRequested:
      return 'Not Requested';
  }
}

class _ICUStatusEditor extends ConsumerStatefulWidget {
  final String requestId;
  final ICUBookingStatus current;
  const _ICUStatusEditor({required this.requestId, required this.current});

  @override
  ConsumerState<_ICUStatusEditor> createState() => _ICUStatusEditorState();
}

class _ICUStatusEditorState extends ConsumerState<_ICUStatusEditor> {
  bool _updating = false;

  Future<void> _update(ICUBookingStatus s) async {
    // If confirming, show dialog to get unit and room
    if (s == ICUBookingStatus.confirmed) {
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => const _ConfirmICUDialog(),
      );
      
      if (result == null) {
        // User cancelled the dialog
        return;
      }
      
      final unit = result['unit']!;
      final room = result['room']!;
      
      // Confirm with unit and room
      setState(() => _updating = true);
      try {
        await ref.read(databaseServiceProvider).confirmICUBedRequest(widget.requestId, unit, room);
        ref.invalidate(_icuRequestFutureProvider(widget.requestId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Confirmed: $unit, $room')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to confirm: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _updating = false);
      }
      return;
    }
    
    // For all other statuses (including No Bed Available), update normally
    setState(() => _updating = true);
    try {
      await ref.read(databaseServiceProvider).updateICUBedRequestStatus(widget.requestId, s);
      ref.invalidate(_icuRequestFutureProvider(widget.requestId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${_icuStatusLabel(s)}')),
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
        // Only ICU team can edit ICU request status
        if (role != UserRole.icuTeam) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: DropdownButton<ICUBookingStatus>(
            value: widget.current,
            onChanged: _updating ? null : (val) {
              if (val == null || val == widget.current) return;
              _update(val);
            },
            items: ICUBookingStatus.values
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(_icuStatusLabel(s)),
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

class _ConfirmICUDialog extends StatefulWidget {
  const _ConfirmICUDialog();

  @override
  State<_ConfirmICUDialog> createState() => _ConfirmICUDialogState();
}

class _ConfirmICUDialogState extends State<_ConfirmICUDialog> {
  final _formKey = GlobalKey<FormState>();
  final _unitController = TextEditingController();
  final _roomController = TextEditingController();

  @override
  void dispose() {
    _unitController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm ICU Bed Assignment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Unit',
                hintText: 'e.g., ICU-A, CCU, MICU',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Unit is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Room',
                hintText: 'e.g., Room 101, Bed 5',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Room is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'unit': _unitController.text.trim(),
                'room': _roomController.text.trim(),
              });
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
