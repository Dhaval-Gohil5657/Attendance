import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../backend/models/employee_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';

class AddEmployeeScreen extends StatefulWidget {
  final EmployeeEntity companyUser;

  const AddEmployeeScreen({super.key, required this.companyUser});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController(text: '123456');

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAndSendWhatsApp() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() => _isSubmitting = true);

      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final password = _passwordController.text;

      try {
        // Fetch official companyName from Firestore companies collection
        String displayCompanyName = widget.companyUser.name;
        try {
          final compDoc = await FirebaseFirestore.instance
              .collection('companies')
              .doc(widget.companyUser.companyId ?? widget.companyUser.uid)
              .get();
          if (compDoc.exists && compDoc.data() != null) {
            displayCompanyName = compDoc.data()!['companyName'] ?? displayCompanyName;
          }
        } catch (_) {}

        // Register employee in Firestore / Firebase via BLoC with companyName
        if (mounted) {
          context.read<AuthBloc>().add(
                EmployeeRegisterSubmittedEvent(
                  email: email,
                  password: password,
                  name: name,
                  companyId: widget.companyUser.companyId ?? widget.companyUser.uid,
                  companyName: displayCompanyName,
                ),
              );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Employee "$name" registered successfully!'),
              backgroundColor: const Color(0xFF047857),
            ),
          );
        }

        // App Download Link (Update with production URL when published)
        const String appLink = 'https://play.google.com/store/apps/details?id=karma.attendance';

        // Format WhatsApp Message
        final message = '👋 *Welcome to $displayCompanyName!*\n\n'
            'Your Employee HRMS Portal account has been created.\n\n'
            '🔑 *User ID / Email:* $email\n'
            '🔒 *Password:* $password\n\n'
            '📱 *Download App:* $appLink\n\n'
            'Please download the app, select *Login as Employee*, and sign in to mark your daily attendance.';

        final whatsappUrl = Uri.parse(
          'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
        );

        // Attempt WhatsApp Launch with fallback
        try {
          final launched = await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
          if (!launched) {
            await launchUrl(
              Uri.parse('https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(message)}'),
              mode: LaunchMode.externalApplication,
            );
          }
        } catch (e) {
          debugPrint('WhatsApp launch error: $e');
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding employee: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Add New Employee'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF25D366),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_outlined, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WhatsApp Credential Dispatch',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Registration creates the account and launches WhatsApp to share credentials.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Employee Full Name
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  decoration: _inputDecoration('Employee Full Name', Icons.person_outline),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Full Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Employee Email
                TextFormField(
                  controller: _emailController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Employee Email / Login ID', Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // WhatsApp Phone Number
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('WhatsApp Mobile Number', Icons.phone_outlined).copyWith(
                    hintText: 'e.g. 919876543210',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'WhatsApp Phone Number is required';
                    if (v.replaceAll(RegExp(r'[^0-9]'), '').length < 8) {
                      return 'Enter a valid mobile number with country code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Initial Password
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isSubmitting,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration('Initial Password', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit & Send Button
                ElevatedButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isSubmitting ? 'REGISTERING...' : 'REGISTER & SEND VIA WHATSAPP',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isSubmitting ? null : _submitAndSendWhatsApp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.indigo.shade700),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
