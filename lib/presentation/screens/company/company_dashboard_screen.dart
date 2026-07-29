import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/employee_entity.dart';
import 'add_employee_screen.dart';
import 'attendance_policy_screen.dart';
import 'company_live_tracking_screen.dart';
import 'company_profile_screen.dart';
import 'employee_list_screen.dart';

import '../../widgets/quick_login_setup_dialog.dart';

class CompanyDashboardScreen extends StatefulWidget {
  final EmployeeEntity user;

  const CompanyDashboardScreen({super.key, required this.user});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      QuickLoginSetupDialog.checkAndPrompt(context, widget.user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('companies')
          .doc(user.companyId ?? user.uid)
          .get(),
      builder: (context, snapshot) {
        final compData = snapshot.data?.data();
        final companyName = compData?['companyName'] ?? user.name;
        final companyEmail = compData?['email'] ?? user.email;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Company Portal'),
            backgroundColor: Colors.indigo.shade800,
            foregroundColor: Colors.white,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Interactive Company Card
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CompanyProfileScreen(user: user),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFECFDF5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.verified_rounded, size: 36, color: Color(0xFF059669)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        companyName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD1FAE5),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Status: ACTIVE',
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
                                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
                              ],
                            ),
                            const Divider(height: 28),
                            Row(
                              children: [
                                Text(
                                  'Company Email: ',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                ),
                                Expanded(
                                  child: Text(
                                    companyEmail,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CATEGORY 1: Live Monitoring & GPS Tracking
                  _buildSectionHeader(
                    icon: Icons.map_rounded,
                    title: 'Live Operations & Tracking',
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map_rounded, size: 22),
                    label: const Text('LIVE LOCATION TRACKING MAP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CompanyLiveTrackingScreen(companyUser: user),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // CATEGORY 2: Team & Employee Management
                  _buildSectionHeader(
                    icon: Icons.people_alt_rounded,
                    title: 'Team & Employee Management',
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add_rounded, size: 22),
                    label: const Text('ADD NEW EMPLOYEE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddEmployeeScreen(companyUser: user),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.people_alt_outlined, size: 22),
                    label: const Text('VIEW ALL EMPLOYEES'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo.shade800,
                      side: BorderSide(color: Colors.indigo.shade800),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EmployeeListScreen(companyUser: user),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // CATEGORY 3: Company Setup & Policies
                  _buildSectionHeader(
                    icon: Icons.tune_rounded,
                    title: 'Policy & System Controls',
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings_outlined, size: 22),
                    label: const Text('ATTENDANCE POLICY SETUP'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo.shade900,
                      side: BorderSide(color: Colors.indigo.shade900),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AttendancePolicyScreen(companyUser: user),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF475569)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
