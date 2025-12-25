import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  String _selectedAuthMethod = 'applicant';
  UserRole _staffRole = UserRole.anesthesia;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VitalFlow Login'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // App Logo/Header
            const Icon(
              Icons.local_hospital,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to VitalFlow',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Emergency OR & ICU Bed Management System',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Auth Method Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login Method',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Method Selection
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'applicant',
                          label: Text('Applicant'),
                          icon: Icon(Icons.person),
                        ),
                        ButtonSegment(
                          value: 'staff',
                          label: Text('Staff Login'),
                          icon: Icon(Icons.lock),
                        ),
                      ],
                      selected: {_selectedAuthMethod},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedAuthMethod = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    if (_selectedAuthMethod == 'staff') 
                      _buildStaffLoginForm()
                    else 
                      _buildApplicantLoginForm(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffLoginForm() {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            'For Anesthesia & ICU Team Members',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Staff Role Selector (moved up)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Role',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<UserRole>(
            segments: const [
              ButtonSegment(
                value: UserRole.anesthesia,
                label: Text('Anesthesia'),
                icon: Icon(Icons.medical_services),
              ),
              ButtonSegment(
                value: UserRole.icuTeam,
                label: Text('ICU Team'),
                icon: Icon(Icons.bed),
              ),
              ButtonSegment(
                value: UserRole.admin,
                label: Text('Admin'),
                icon: Icon(Icons.admin_panel_settings),
              ),
            ],
            selected: {_staffRole},
            onSelectionChanged: (s) => setState(() => _staffRole = s.first),
          ),
          const SizedBox(height: 16),
          
          // Staff Name
          FormBuilderTextField(
            name: 'name',
            decoration: const InputDecoration(
              labelText: 'Your Name',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(2),
            ]),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          
          FormBuilderTextField(
            name: 'password',
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: FormBuilderValidators.required(),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleStaffLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple, // darker background
                foregroundColor: Colors.white, // lighter text/icon color
              ),
              child: _isLoading 
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign In'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantLoginForm() {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            'For Surgeons & Physicians requesting services',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Applicant Name
          FormBuilderTextField(
            name: 'name',
            decoration: const InputDecoration(
              labelText: 'Your Name',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(2),
            ]),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleApplicantLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: _isLoading 
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStaffLogin() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final formData = _formKey.currentState!.value;
      final authService = ref.read(authServiceProvider.notifier);
      await authService.signInStaff(
        name: formData['name'],
        password: formData['password'],
        role: _staffRole,
      );

      if (mounted) {
        // Admin goes directly to admin dashboard, others to home
        if (_staffRole == UserRole.admin) {
          context.go('/admin');
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      LoggerService.error('Staff login error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleApplicantLogin() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final formData = _formKey.currentState!.value;
      final authService = ref.read(authServiceProvider.notifier);
      await authService.signInApplicant(name: formData['name']);

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      LoggerService.error('Applicant login error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
