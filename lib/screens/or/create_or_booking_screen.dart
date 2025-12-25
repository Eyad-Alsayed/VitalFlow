import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';
import '../../models/or_booking.dart' as or_models;
import '../../widgets/app_bar_actions.dart';
import '../../utils/timezone_helper.dart';

class CreateORBookingScreen extends ConsumerStatefulWidget {
  const CreateORBookingScreen({super.key});

  @override
  ConsumerState<CreateORBookingScreen> createState() => _CreateORBookingScreenState();
}

class _CreateORBookingScreenState extends ConsumerState<CreateORBookingScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create OR Booking'),
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
                      name: 'procedure',
                      decoration: const InputDecoration(
                        labelText: 'Procedure',
                        prefixIcon: Icon(Icons.healing_outlined),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Urgency',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    FormBuilderDropdown<or_models.UrgencyLevel>(
                      name: 'urgencyLevel',
                      decoration: const InputDecoration(
                        labelText: 'Select urgency level',
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                      items: or_models.UrgencyLevel.values
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u.displayName),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Contacts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'anesthesiaTeamContact',
                      initialValue: '0566794987',
                      decoration: const InputDecoration(
                        labelText: 'Anesthesia Team On-call',
                        prefixIcon: Icon(Icons.medical_services_outlined),
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
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
                        label: Text(_isSubmitting ? 'Submitting...' : 'Create Booking'),
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
      // Load current user info for createdBy
      final userInfo = await ref.read(userInfoProvider.future);
      if (userInfo == null) {
        throw Exception('User info unavailable');
      }

      final values = _formKey.currentState!.value;
      final contact = or_models.ContactInfo(
        consultantName: values['consultantName'],
        consultantPhone: values['consultantPhone'],
        requestingPhysician: values['requestingPhysician'],
        requestingPhysicianPhone: values['requestingPhysicianPhone'],
        anesthesiaTeamContact: values['anesthesiaTeamContact'],
      );

      final createdBy = or_models.UserInfo(
        uid: userInfo.uid,
        role: userInfo.role,
        displayName: userInfo.displayName,
      );

      final booking = or_models.ORBooking(
        patientMrn: values['patientMrn'],
        patientName: values['patientName'] ?? '',
        patientWard: values['patientWard'] ?? '',
        procedure: values['procedure'],
        urgencyLevel: values['urgencyLevel'] as or_models.UrgencyLevel,
        contact: contact,
        requestedAt: DateTime.now(),
        // scheduledAt omitted for emergency request; rely on requestedAt
        status: or_models.ORBookingStatus.pending,
        createdBy: createdBy,
        lastUpdatedAt: nowRiyadh(),
      );

      final database = ref.read(databaseServiceProvider);
      final id = await database.createORBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OR booking created')),
        );
        context.push('/or-bookings/$id');
      }
    } catch (e, st) {
      LoggerService.error('Failed to create OR booking', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create booking: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
