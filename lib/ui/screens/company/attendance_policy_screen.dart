import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../backend/models/employee_model.dart';

class AttendancePolicyScreen extends StatefulWidget {
  final EmployeeEntity companyUser;

  const AttendancePolicyScreen({super.key, required this.companyUser});

  @override
  State<AttendancePolicyScreen> createState() => _AttendancePolicyScreenState();
}

class _AttendancePolicyScreenState extends State<AttendancePolicyScreen> {
  bool _isLoading = true;
  bool _enableLiveTracking = true;
  bool _enableTravelMode = true;
  bool _enableImageVerification = false;
  String _imageVerificationType = 'Selfie'; // Selfie, Odometer, Both

  @override
  void initState() {
    super.initState();
    _loadCurrentPolicy();
  }

  Future<void> _loadCurrentPolicy() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyUser.companyId ?? widget.companyUser.uid)
          .get();

      final data = doc.data();
      if (data != null && data.containsKey('attendancePolicy')) {
        final policy = data['attendancePolicy'] as Map<String, dynamic>;
        setState(() {
          _enableLiveTracking = policy['enableLiveTracking'] ?? true;
          _enableTravelMode = policy['enableTravelMode'] ?? true;
          _enableImageVerification = policy['enableImageVerification'] ?? false;
          _imageVerificationType = policy['imageVerificationType'] ?? 'Selfie';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePolicy() async {
    setState(() => _isLoading = true);

    try {
      final companyId = widget.companyUser.companyId ?? widget.companyUser.uid;
      await FirebaseFirestore.instance.collection('companies').doc(companyId).set({
        'attendancePolicy': {
          'enableLiveTracking': _enableLiveTracking,
          'enableTravelMode': _enableTravelMode,
          'enableImageVerification': _enableImageVerification,
          'imageVerificationType': _imageVerificationType,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company Attendance Policy updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save policy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Attendance Policy Setup'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Policy Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade800, Colors.indigo.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.policy_rounded, color: Colors.white, size: 28),
                              SizedBox(width: 10),
                              Text(
                                'Verification Rules',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Customize attendance requirements for employees (Location Tracking, Travel Mode, Verification).',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Configurable Modules',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1. Continuous Live Location Tracking Policy
                    Card(
                      color: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.all(10),
                        title: const Text(
                          'Background Live GPS Tracking',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Continuously tracks employee location in background during working hours.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.location_on_rounded, color: Colors.indigo.shade800),
                        ),
                        value: _enableLiveTracking,
                        activeThumbColor: Colors.indigo.shade800,
                        onChanged: (val) {
                          setState(() => _enableLiveTracking = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Travel Mode Selection Policy
                    Card(
                      color: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: const Text(
                          'Travel Mode Requirement',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Prompt employee to select mode of transit (Bike, Car, Public Transport, Walking, Office) upon check-in.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.directions_bike_rounded, color: Colors.green.shade800),
                        ),
                        value: _enableTravelMode,
                        activeThumbColor: Colors.indigo.shade800,
                        onChanged: (val) {
                          setState(() => _enableTravelMode = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Image / Photo Verification Policy (Pending Backend API)
                    Card(
                      color: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.camera_alt_rounded, color: Colors.amber.shade900),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Photo Verification (Selfie / Odometer)',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Will be enabled when Custom Backend API is connected.',
                                        style: TextStyle(fontSize: 12, color: Colors.amber),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _enableImageVerification,
                                  onChanged: null, // Disabled until backend API is ready
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton.icon(
                      onPressed: _savePolicy,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text(
                        'SAVE POLICY CONFIGURATION',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
