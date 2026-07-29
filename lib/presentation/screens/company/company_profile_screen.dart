import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/employee_entity.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../employee/quick_login_setup_screen.dart';

class CompanyProfileScreen extends StatefulWidget {
  final EmployeeEntity user;

  const CompanyProfileScreen({super.key, required this.user});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Company Profile'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('companies')
              .doc(widget.user.companyId ?? widget.user.uid)
              .get(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();

            final companyName = data?['companyName'] ?? widget.user.name;
            final ownerName = data?['ownerName'] ?? widget.user.name;
            final email = data?['email'] ?? widget.user.email;
            final phone = data?['phone'] ?? 'Not provided';
            final gstNumber = data?['gstNumber'] ?? 'Not provided';
            final address = data?['address'] ?? 'Not provided';
            final isApproved = data?['isApproved'] ?? widget.user.isApproved;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Company Profile Avatar & Name Header
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
                            Icons.business_rounded,
                            size: 56,
                            color: Colors.indigo.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          companyName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isApproved ? const Color(0xFFD1FAE5) : Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isApproved ? 'Status: ACTIVE' : 'Status: PENDING APPROVAL',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isApproved ? const Color(0xFF047857) : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Company Details',
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
                            icon: Icons.business_outlined,
                            label: 'Company Name',
                            value: companyName,
                          ),
                          const Divider(height: 1, indent: 56),
                          _DetailTile(
                            icon: Icons.person_outline,
                            label: 'Owner / Authorized Name',
                            value: ownerName,
                          ),
                          const Divider(height: 1, indent: 56),
                          _DetailTile(
                            icon: Icons.email_outlined,
                            label: 'Email Address',
                            value: email,
                          ),
                          const Divider(height: 1, indent: 56),
                          _DetailTile(
                            icon: Icons.phone_outlined,
                            label: 'Contact Number',
                            value: phone,
                          ),
                          const Divider(height: 1, indent: 56),
                          _DetailTile(
                            icon: Icons.assignment_outlined,
                            label: 'GST / Registration No.',
                            value: gstNumber,
                          ),
                          const Divider(height: 1, indent: 56),
                          _DetailTile(
                            icon: Icons.location_on_outlined,
                            label: 'Address',
                            value: address,
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(height: 16),

                  // Logout Button inside Profile
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
