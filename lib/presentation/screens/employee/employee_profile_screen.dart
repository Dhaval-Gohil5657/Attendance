import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/employee_entity.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import 'quick_login_setup_screen.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final EmployeeEntity user;

  const EmployeeProfileScreen({super.key, required this.user});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Employee Profile'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
          future: widget.user.companyId != null
              ? FirebaseFirestore.instance.collection('companies').doc(widget.user.companyId).get()
              : Future.value(null),
          builder: (context, snapshot) {
            final compData = snapshot.data?.data();
            final companyName = widget.user.companyName ?? compData?['companyName'] ?? 'Not assigned';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Avatar & Name Header Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 56,
                            color: Colors.indigo.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.user.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Status: ACTIVE EMPLOYEE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Profile Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Detail Tiles Card
                  Card(
                    color: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          _DetailTile(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            value: widget.user.name,
                          ),
                          const Divider(height: 1, indent: 56),
                          _DetailTile(
                            icon: Icons.email_outlined,
                            label: 'Email Address',
                            value: widget.user.email,
                          ),
                          const Divider(height: 1, indent: 56),
                          _DetailTile(
                            icon: Icons.business_outlined,
                            label: 'Company Name',
                            value: companyName,
                          ),
                          const Divider(height: 1, indent: 56),
                          _DetailTile(
                            icon: Icons.badge_outlined,
                            label: 'Account Role',
                            value: 'Employee',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Security & Quick Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Login Toggle Switch
                  FutureBuilder<bool>(
                    future: SharedPreferences.getInstance().then(
                      (p) => p.getBool('quick_login_enabled_${widget.user.uid}') ?? false,
                    ),
                    builder: (context, pinSnapshot) {
                      final isQuickLoginActive = pinSnapshot.data == true;

                      return Card(
                        color: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.fingerprint_rounded, color: Colors.indigo.shade800),
                          ),
                          title: const Text(
                            'Quick PIN & Biometrics',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          subtitle: Text(
                            isQuickLoginActive ? 'Quick unlock enabled' : 'Toggle to set up 4-digit PIN',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          value: isQuickLoginActive,
                          activeThumbColor: Colors.indigo.shade800,
                          onChanged: (bool value) async {
                            if (value) {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => QuickLoginSetupScreen(user: widget.user),
                                ),
                              );
                              if (mounted) setState(() {});
                            } else {
                              final messenger = ScaffoldMessenger.of(context);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('quick_login_enabled_${widget.user.uid}', false);
                              await prefs.setBool('has_quick_login_active', false);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Quick PIN & Biometric Login Disabled.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              if (mounted) setState(() {});
                            }
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Change Password Button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: const Text(
                      'CHANGE PASSWORD',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo.shade800,
                      side: BorderSide(color: Colors.indigo.shade800),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _showChangePasswordDialog(context);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Log Out Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'LOG OUT',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.read<AuthBloc>().add(LogoutSubmittedEvent());
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter new password';
                  if (v.length < 6) return 'At least 6 characters required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_clock_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Confirm new password';
                  if (v != newPassCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newPass = newPassCtrl.text.trim();
                Navigator.pop(dialogCtx);
                try {
                  final fbUser = FirebaseAuth.instance.currentUser;
                  if (fbUser != null) {
                    await fbUser.updatePassword(newPass);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password changed successfully!'),
                          backgroundColor: Color(0xFF047857),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to change password: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.indigo.shade800, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}
