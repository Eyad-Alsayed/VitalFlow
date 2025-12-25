import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';
import '../../models/icu_bed_request.dart' as icu_models;
import '../../widgets/app_bar_actions.dart';
import '../../utils/timezone_helper.dart';

class CreateICURequestScreen extends ConsumerStatefulWidget {
  const CreateICURequestScreen({super.key});

  @override
  ConsumerState<CreateICURequestScreen> createState() => _CreateICURequestScreenState();
}

class _CreateICURequestScreenState extends ConsumerState<CreateICURequestScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request ICU Bed'),
        actions: const [HomeActionButton(), LogoutActionButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'patientMrn',
                      decoration: const InputDecoration(
                        labelText: 'Patient MRN',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(3),
                      ]),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'patientName',
                      decoration: const InputDecoration(
                        labelText: 'Patient Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'patientWard',
                      decoration: const InputDecoration(
                        labelText: 'Patient Ward',
                        prefixIcon: Icon(Icons.local_hospital),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'indication',
                      decoration: const InputDecoration(
                        labelText: 'Name of the Procedure',
                        prefixIcon: Icon(Icons.report_problem_outlined),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Urgency',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    FormBuilderDropdown<icu_models.ICUUrgencyLevel>(
                      name: 'urgencyLevel',
                      decoration: const InputDecoration(
                        labelText: 'Select urgency level (Critical or Elective)',
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                      items: icu_models.ICUUrgencyLevel.values
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u.displayName),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Elective Scheduling',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 8),
                    FormBuilderDateTimePicker(
                      name: 'requestedDate',
                      decoration: const InputDecoration(
                        labelText: 'Requested Date (no time)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                      inputType: InputType.date,
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Contacts',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'consultantName',
                      decoration: const InputDecoration(
                        labelText: 'Consultant Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'consultantPhone',
                      decoration: const InputDecoration(
                        labelText: 'Consultant Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(7),
                      ]),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'requestingPhysician',
                      decoration: const InputDecoration(
                        labelText: 'Requesting Physician',
                        prefixIcon: Icon(Icons.person_pin_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'requestingPhysicianPhone',
                      decoration: const InputDecoration(
                        labelText: 'Requesting Physician Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(7),
                      ]),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isSubmitting ? 'Submitting...' : 'Create ICU Request'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    setState(() => _isSubmitting = true);

    try {
      final userInfo = await ref.read(userInfoProvider.future);
      if (userInfo == null) {
        throw Exception('User info unavailable');
      }

      final values = _formKey.currentState!.value;
      final contact = icu_models.ICUContactInfo(
        consultantName: values['consultantName'],
        consultantPhone: values['consultantPhone'],
  requestingPhysician: values['requestingPhysician'],
  requestingPhysicianPhone: values['requestingPhysicianPhone'],
      );

      final createdBy = icu_models.UserInfo(
        uid: userInfo.uid,
        role: userInfo.role,
        displayName: userInfo.displayName,
      );

      final request = icu_models.ICUBedRequest(
        patientMrn: values['patientMrn'],
        patientName: values['patientName'] ?? '',
        patientWard: values['patientWard'] ?? '',
        indication: values['indication'],
        urgencyLevel: values['urgencyLevel'] as icu_models.ICUUrgencyLevel,
        contact: contact,
        requestedAt: DateTime.now(),
        requestedDate: values['requestedDate'] as DateTime, // required elective date (no time)
        status: icu_models.ICUBookingStatus.pending,
        createdBy: createdBy,
        lastUpdatedAt: nowRiyadh(),
      );

      final database = ref.read(databaseServiceProvider);
      final id = await database.createICUBedRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ICU bed request created')),
        );
        context.push('/icu-requests/$id');
      }
    } catch (e, st) {
      LoggerService.error('Failed to create ICU bed request', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create ICU request: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
