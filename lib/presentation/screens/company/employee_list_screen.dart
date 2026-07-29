import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/employee_entity.dart';
import 'add_employee_screen.dart';
import 'company_live_tracking_screen.dart';

class EmployeeListScreen extends StatelessWidget {
  final EmployeeEntity companyUser;

  const EmployeeListScreen({super.key, required this.companyUser});

  @override
  Widget build(BuildContext context) {
    final companyId = companyUser.companyId ?? companyUser.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Company Employees'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddEmployeeScreen(companyUser: companyUser),
            ),
          );
        },
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('employees')
              .where('companyId', isEqualTo: companyId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error loading employee list: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: Colors.indigo.shade400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No Employees Added Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap "Add Employee" below to create credentials and invite team members.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('ADD FIRST EMPLOYEE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddEmployeeScreen(companyUser: companyUser),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Employee Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.badge_outlined, color: Colors.indigo.shade800),
                            const SizedBox(width: 8),
                            const Text(
                              'Total Employees',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${docs.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Employee List View with Real-time Attendance Status
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('companies')
                          .doc(companyUser.companyId ?? companyUser.uid)
                          .snapshots(),
                      builder: (context, compSnapshot) {
                        final compData = compSnapshot.data?.data();
                        final policy = compData?['attendancePolicy'] as Map<String, dynamic>?;
                        final enableTravelMode = policy?['enableTravelMode'] ?? false;

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data();
                            final empName = data['name'] ?? 'Employee';
                            final empEmail = data['email'] ?? 'No email';

                        final initial = empName.isNotEmpty ? empName[0].toUpperCase() : 'E';

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.indigo.shade50,
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade800,
                                ),
                              ),
                            ),
                            title: Text(
                              empName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            subtitle: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              // Query live attendance status for this employee
                              stream: FirebaseFirestore.instance
                                  .collection('attendance')
                                  .where('employeeId', isEqualTo: empEmail)
                                  .limit(20)
                                  .snapshots(),
                              builder: (context, attSnapshot) {
                                final rawAttDocs = attSnapshot.data?.docs ?? [];
                                final attList = rawAttDocs.toList();

                                // Client-side sort by checkInTime descending
                                attList.sort((a, b) {
                                  final tA = a.data()['checkInTime'] as Timestamp?;
                                  final tB = b.data()['checkInTime'] as Timestamp?;
                                  if (tA == null || tB == null) return 0;
                                  return tB.compareTo(tA);
                                });

                                final latestAtt = attList.isNotEmpty ? attList.first.data() : null;
                                final isTracking = latestAtt?['isTracking'] ?? false;
                                final status = latestAtt?['status'] ?? 'not_started';
                                final travelMode = latestAtt?['travelMode'] as String? ?? 'Four-Wheeler';

                                IconData travelIcon = Icons.directions_car_rounded;
                                if (travelMode == 'Walking') {
                                  travelIcon = Icons.directions_walk_rounded;
                                } else if (travelMode == 'Two-Wheeler') {
                                  travelIcon = Icons.two_wheeler_rounded;
                                }

                                String attStatusText = 'NOT STARTED';
                                Color attColor = Colors.grey.shade700;
                                Color attBg = Colors.grey.shade100;
                                Color attBorder = Colors.grey.shade300;

                                if (status == 'on_break') {
                                  attStatusText = 'ON BREAK';
                                  attColor = Colors.amber.shade900;
                                  attBg = Colors.amber.shade50;
                                  attBorder = Colors.amber.shade300;
                                } else if (status == 'active' || isTracking) {
                                  attStatusText = 'CHECKED IN';
                                  attColor = const Color(0xFF047857);
                                  attBg = const Color(0xFFECFDF5);
                                  attBorder = const Color(0xFFA5D6A7);
                                } else if (status == 'checked_out') {
                                  attStatusText = 'CHECKED OUT';
                                  attColor = Colors.blue.shade900;
                                  attBg = Colors.blue.shade50;
                                  attBorder = Colors.blue.shade200;
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 1),
                                    Row(
                                      children: [
                                        Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            empEmail,
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Status Badge & Travel Mode Icon Row
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: attBg,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: attBorder),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.circle, size: 8, color: attColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                attStatusText,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: attColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (enableTravelMode && latestAtt != null && status != 'not_started') ...[
                                          const SizedBox(width: 6),
                                          Tooltip(
                                            message: 'Travel Mode: $travelMode',
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.indigo.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.indigo.shade100),
                                              ),
                                              child: Icon(
                                                travelIcon,
                                                size: 14,
                                                color: Colors.indigo.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 26),
                              tooltip: 'Track Live Location',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CompanyLiveTrackingScreen(
                                      companyUser: companyUser,
                                      initialSelectedEmployeeId: empEmail,
                                      initialSelectedEmployeeName: empName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
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
