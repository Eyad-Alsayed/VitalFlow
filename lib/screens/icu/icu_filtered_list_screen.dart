import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../models/icu_bed_request.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_bar_actions.dart';

enum ICUListFilter { confirmedToday, active, registry }

class ICUFilteredListScreen extends ConsumerStatefulWidget {
  final ICUListFilter filter;
  const ICUFilteredListScreen({super.key, required this.filter});

  @override
  ConsumerState<ICUFilteredListScreen> createState() => _ICUFilteredListScreenState();
}

class _ICUFilteredListScreenState extends ConsumerState<ICUFilteredListScreen> {
  DateTime? _selectedDate; // Applicant date filter (Requested Date)
  DateTime? _confirmedFilterDate; // Optional date filter for Confirmed Today page

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('y-MM-dd');
    final dtf = DateFormat('y-MM-dd HH:mm');
    final asyncRequests = ref.watch(icuBedRequestsStreamProvider(const {}));
    final userAsync = ref.watch(userInfoProvider);
    final showDateFilter = widget.filter == ICUListFilter.active || widget.filter == ICUListFilter.registry; // filter UI on Active and Registry pages
    final showConfirmedDateFilter = widget.filter == ICUListFilter.confirmedToday; // optional date filter for Confirmed Today

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(widget.filter)),
        actions: const [HomeActionButton(), LogoutActionButton()],
      ),
      body: Column(
        children: [
          if (showConfirmedDateFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _confirmedFilterDate == null
                            ? 'Today (tap to change date)'
                            : 'Date: ${df.format(_confirmedFilterDate!)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _confirmedFilterDate ?? now,
                          firstDate: DateTime(now.year - 1, 1, 1),
                          lastDate: DateTime(now.year + 2, 12, 31),
                        );
                        if (!mounted) return;
                        setState(() => _confirmedFilterDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_confirmedFilterDate != null)
                    TextButton(
                      onPressed: () => setState(() => _confirmedFilterDate = null),
                      child: const Text('Reset to Today'),
                    ),
                ],
              ),
            ),
          if (showDateFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate == null
                            ? 'Filter by Needed Date'
                            : 'Needed Date: ${df.format(_selectedDate!)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? now,
                          firstDate: DateTime(now.year - 1, 1, 1),
                          lastDate: DateTime(now.year + 2, 12, 31),
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
            child: asyncRequests.when(
              data: (list) {
                final today = DateTime.now();
                // Use custom date for confirmed filter, or today if not set
                final filterDate = widget.filter == ICUListFilter.confirmedToday && _confirmedFilterDate != null
                    ? _confirmedFilterDate!
                    : today;
                List<ICUBedRequest> filtered =
                    list.where((r) => _matchesWithDate(r, widget.filter, filterDate)).toList();

                // Apply date filter (requestedDate) for applicants on Active page
                if (showDateFilter && _selectedDate != null) {
                  final d = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
                  filtered = filtered.where((r) {
                    if (r.requestedDate == null) return false;
                    final rd = DateTime(r.requestedDate!.year, r.requestedDate!.month, r.requestedDate!.day);
                    return rd == d;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text('No requests found'));
                }
                
                // Sort by requestedAt (earliest first)
                filtered.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
                
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final r = filtered[index];
                    return userAsync.when(
                      data: (user) => _buildRequestCard(context, r, df, dtf, user),
                      loading: () => _buildRequestCard(context, r, df, dtf, null),
                      error: (_, __) => _buildRequestCard(context, r, df, dtf, null),
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
                      Text('Failed to load ICU requests\n$e', textAlign: TextAlign.center),
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

  Widget _buildRequestCard(BuildContext context, ICUBedRequest r, DateFormat df, DateFormat dtf, SimpleUserInfo? user) {
    final isICUStaff = user?.role.toLowerCase() == 'icu_team';
    final showOutcomeDropdown = isICUStaff && widget.filter == ICUListFilter.confirmedToday;

    return Card(
      child: InkWell(
        onTap: () => context.push('/icu-requests/${r.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r.patientMrn} — ${r.indication}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (r.patientName.isNotEmpty)
                      Text(
                        r.patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text('Requested at: ${dtf.format(r.requestedAt)}'),
                    if (r.requestedDate != null)
                      Text('Requested Date: ${df.format(r.requestedDate!)}'),
                    Text('Status: ${_statusLabel(r.status)}'),
                    if (r.unit != null && r.room != null) ...[
                      const SizedBox(height: 4),
                      Text('📍 ${r.unit} - ${r.room}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                    if (showOutcomeDropdown) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Outcome: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Expanded(
                            child: DropdownButton<String>(
                              value: r.outcome?.isEmpty ?? true ? null : r.outcome,
                              hint: const Text('Select outcome'),
                              isExpanded: true,
                              underline: Container(
                                height: 1,
                                color: Colors.grey.shade300,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Admitted',
                                  child: Text('Admitted'),
                                ),
                                DropdownMenuItem(
                                  value: 'Back to Ward',
                                  child: Text('Back to Ward'),
                                ),
                                DropdownMenuItem(
                                  value: 'OR Cancelled',
                                  child: Text('OR Cancelled'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  _handleAction(context, r, value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, ICUBedRequest request, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text('Mark this request as "$action"?\n\nPatient: ${request.patientMrn}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'OR Cancelled' ? Colors.red : Colors.blue,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Update the request outcome field
      await ref.read(databaseServiceProvider).updateICUOutcome(request.id!, action);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request marked as "$action"'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the list
        ref.invalidate(icuBedRequestsStreamProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

String _titleFor(ICUListFilter f) {
  switch (f) {
    case ICUListFilter.confirmedToday:
      return 'Confirmed for Today';
    case ICUListFilter.active:
      return 'Active Requests';
    case ICUListFilter.registry:
      return 'ICU Registry';
  }
}

bool _matchesWithDate(ICUBedRequest r, ICUListFilter f, DateTime filterDate) {
  final targetDate = DateTime(filterDate.year, filterDate.month, filterDate.day);
  final requestedDate = r.requestedDate != null
      ? DateTime(r.requestedDate!.year, r.requestedDate!.month, r.requestedDate!.day)
      : null;
  final requestedAtDate = DateTime(r.requestedAt.year, r.requestedAt.month, r.requestedAt.day);

  switch (f) {
    case ICUListFilter.confirmedToday:
      if (r.status != ICUBookingStatus.confirmed) return false;
      if (requestedDate != null) return requestedDate == targetDate;
      return requestedAtDate == targetDate;
    case ICUListFilter.active:
      return r.status == ICUBookingStatus.pending ||
          r.status == ICUBookingStatus.confirmed ||
          r.status == ICUBookingStatus.noBedAvailable;
    case ICUListFilter.registry:
      return true; // Show all statuses: pending, confirmed, noBedAvailable, notRequested
  }
}

// Legacy function for backward compatibility
bool _matches(ICUBedRequest r, ICUListFilter f, DateTime now) {
  return _matchesWithDate(r, f, now);
}

String _statusLabel(ICUBookingStatus s) {
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
