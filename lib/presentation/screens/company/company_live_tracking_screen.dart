import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/entities/employee_entity.dart';

class CompanyLiveTrackingScreen extends StatefulWidget {
  final EmployeeEntity companyUser;
  final String? initialSelectedEmployeeId;
  final String? initialSelectedEmployeeName;

  const CompanyLiveTrackingScreen({
    super.key,
    required this.companyUser,
    this.initialSelectedEmployeeId,
    this.initialSelectedEmployeeName,
  });

  @override
  State<CompanyLiveTrackingScreen> createState() => _CompanyLiveTrackingScreenState();
}

class _CompanyLiveTrackingScreenState extends State<CompanyLiveTrackingScreen> {
  final MapController _mapController = MapController();
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.initialSelectedEmployeeId;
    _selectedEmployeeName = widget.initialSelectedEmployeeName;
  }

  @override
  Widget build(BuildContext context) {
    final companyId = widget.companyUser.companyId ?? widget.companyUser.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Stream company employees for dropdown filter & name lookup
      stream: FirebaseFirestore.instance
          .collection('employees')
          .where('companyId', isEqualTo: companyId)
          .snapshots(),
      builder: (context, empSnapshot) {
        final empDocs = empSnapshot.data?.docs ?? [];
        final Map<String, String> employeeNamesMap = {};

        for (var doc in empDocs) {
          final data = doc.data();
          final email = (data['email'] as String? ?? '').toLowerCase();
          final name = data['name'] as String? ?? email;
          final uid = doc.id;

          if (email.isNotEmpty) employeeNamesMap[email] = name;
          if (uid.isNotEmpty) employeeNamesMap[uid] = name;
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          // Stream live attendance status (to detect who is ON BREAK or CHECKED OUT)
          stream: FirebaseFirestore.instance
              .collection('attendance')
              .snapshots(),
          builder: (context, attSnapshot) {
            final attDocs = attSnapshot.data?.docs ?? [];
            final Map<String, String> employeeStatusMap = {};

            for (var doc in attDocs) {
              final data = doc.data();
              final empId = (data['employeeId'] as String? ?? '').toLowerCase();
              final status = data['status'] as String? ?? 'not_started';
              if (empId.isNotEmpty) {
                employeeStatusMap[empId] = status;
              }
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Employee Tracking',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _selectedEmployeeName != null
                          ? 'Filtered: $_selectedEmployeeName'
                          : 'Showing All Active Employees',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
                backgroundColor: Colors.indigo.shade800,
                foregroundColor: Colors.white,
                actions: [
                  // Filter Dropdown Button in AppBar
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _selectedEmployeeId != null ? Colors.amber.shade700 : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 22),
                    ),
                    tooltip: 'Filter Employee',
                    onSelected: (value) {
                      setState(() {
                        if (value == 'ALL_EMPLOYEES') {
                          _selectedEmployeeId = null;
                          _selectedEmployeeName = null;
                        } else {
                          _selectedEmployeeId = value;
                          _selectedEmployeeName = employeeNamesMap[value.toLowerCase()] ?? value;
                          _moveMapToEmployeeLocation(value);
                        }
                      });
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'ALL_EMPLOYEES',
                          child: Row(
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                color: _selectedEmployeeId == null ? Colors.indigo.shade800 : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'All Employees',
                                  style: TextStyle(
                                    fontWeight: _selectedEmployeeId == null ? FontWeight.bold : FontWeight.normal,
                                    color: _selectedEmployeeId == null ? Colors.indigo.shade900 : Colors.black87,
                                  ),
                                ),
                              ),
                              if (_selectedEmployeeId == null)
                                Icon(Icons.check_rounded, color: Colors.indigo.shade800, size: 18),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        ...empDocs.map((doc) {
                          final data = doc.data();
                          final empEmail = data['email'] as String? ?? doc.id;
                          final empName = data['name'] as String? ?? empEmail;
                          final isSelected = _selectedEmployeeId?.toLowerCase() == empEmail.toLowerCase();
                          final status = employeeStatusMap[empEmail.toLowerCase()] ?? 'not_started';

                          return PopupMenuItem<String>(
                            value: empEmail,
                            child: Row(
                              children: [
                                Icon(
                                  status == 'on_break'
                                      ? Icons.free_breakfast_rounded
                                      : (status == 'active' ? Icons.person_pin_circle_rounded : Icons.person_off_rounded),
                                  color: status == 'on_break'
                                      ? Colors.amber.shade800
                                      : (status == 'active' ? Colors.red.shade500 : Colors.grey),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        empName,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.indigo.shade900 : Colors.black87,
                                        ),
                                      ),
                                      if (status == 'on_break')
                                        const Text(
                                          'On Break',
                                          style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_rounded, color: Colors.indigo.shade800, size: 18),
                              ],
                            ),
                          );
                        }),
                      ];
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: SafeArea(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _getLocationsStream(),
                  builder: (context, locSnapshot) {
                    if (locSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (locSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading live tracking data: ${locSnapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final rawDocs = locSnapshot.data?.docs ?? [];
                    final docs = rawDocs.toList();

                    // Client-side timestamp sorting (descending)
                    docs.sort((a, b) {
                      final tA = a.data()['timestamp'] as Timestamp?;
                      final tB = b.data()['timestamp'] as Timestamp?;
                      if (tA == null || tB == null) return 0;
                      return tB.compareTo(tA);
                    });

                    // Group latest location per employee (excluding those ON BREAK or CHECKED OUT)
                    final Map<String, Map<String, dynamic>> latestEmployeeLocations = {};

                    for (var doc in docs) {
                      final data = doc.data();
                      final empId = (data['employeeId'] as String? ?? '').toLowerCase();

                      if (empId.isEmpty || empId == 'emp_dummy_001') continue;

                      // ONLY include employees belonging to THIS company
                      if (!employeeNamesMap.containsKey(empId)) continue;

                      // HIDE marker if employee is currently ON BREAK or CHECKED OUT
                      final status = employeeStatusMap[empId];
                      if (status == 'on_break' || status == 'checked_out') {
                        continue;
                      }

                      if (!latestEmployeeLocations.containsKey(empId)) {
                        latestEmployeeLocations[empId] = data;
                      }
                    }

                    final locationsList = latestEmployeeLocations.values.toList();

                    if (locationsList.isEmpty) {
                      final isSelectedOnBreak = _selectedEmployeeId != null &&
                          employeeStatusMap[_selectedEmployeeId!.toLowerCase()] == 'on_break';

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSelectedOnBreak ? Icons.free_breakfast_rounded : Icons.location_off_rounded,
                                size: 64,
                                color: isSelectedOnBreak ? Colors.amber.shade700 : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isSelectedOnBreak
                                    ? '$_selectedEmployeeName is Currently on Break'
                                    : (_selectedEmployeeName != null
                                        ? 'No active location for $_selectedEmployeeName'
                                        : 'No active employee location logs found.'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isSelectedOnBreak
                                    ? 'Location tracking is automatically paused during break time.'
                                    : 'Locations update when employees start attendance.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Default initial center map on first active location
                    final firstLoc = locationsList.first;
                    final defaultCenter = LatLng(
                      (firstLoc['latitude'] as num).toDouble(),
                      (firstLoc['longitude'] as num).toDouble(),
                    );

                    return Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: defaultCenter,
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.attendance',
                            ),
                            MarkerLayer(
                              markers: locationsList.map((loc) {
                                final lat = (loc['latitude'] as num).toDouble();
                                final lng = (loc['longitude'] as num).toDouble();
                                final rawEmpId = (loc['employeeId'] as String? ?? '').toLowerCase();

                                final displayName = employeeNamesMap[rawEmpId] ??
                                    (rawEmpId.contains('@') ? rawEmpId.split('@')[0] : rawEmpId);

                                final time = loc['timestamp'] != null
                                    ? (loc['timestamp'] as Timestamp).toDate()
                                    : DateTime.now();
                                final speed = (loc['speed'] as num? ?? 0.0).toDouble();

                                final isSelected = _selectedEmployeeId?.toLowerCase() == rawEmpId;

                                return Marker(
                                  point: LatLng(lat, lng),
                                  width: 140,
                                  height: 60,
                                  child: GestureDetector(
                                    onTap: () {
                                      _showEmployeeDetailsModal(context, displayName, lat, lng, time, speed);
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.indigo.shade900 : Colors.black87,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: const [
                                              BoxShadow(color: Colors.black26, blurRadius: 4),
                                            ],
                                          ),
                                          child: Text(
                                            displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.person_pin_circle_rounded,
                                          color: Colors.redAccent,
                                          size: 32,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                        // Overlay Live Legend Badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 6),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, color: Colors.green, size: 10),
                                const SizedBox(width: 6),
                                Text(
                                  locationsList.length > 1
                                      ? '${locationsList.length} Active Employees Tracking'
                                      : '${locationsList.length} Active Employee Tracking',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getLocationsStream() {
    if (_selectedEmployeeId != null) {
      return FirebaseFirestore.instance
          .collection('location_logs')
          .where('employeeId', isEqualTo: _selectedEmployeeId)
          .limit(50)
          .snapshots();
    }

    return FirebaseFirestore.instance
        .collection('location_logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> _moveMapToEmployeeLocation(String empId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('location_logs')
          .where('employeeId', isEqualTo: empId)
          .limit(20)
          .get();

      if (snap.docs.isNotEmpty) {
        final docs = snap.docs.toList();
        docs.sort((a, b) {
          final tA = a.data()['timestamp'] as Timestamp?;
          final tB = b.data()['timestamp'] as Timestamp?;
          if (tA == null || tB == null) return 0;
          return tB.compareTo(tA);
        });
        final loc = docs.first.data();
        final lat = (loc['latitude'] as num).toDouble();
        final lng = (loc['longitude'] as num).toDouble();
        _mapController.move(LatLng(lat, lng), 16.5);
      }
    } catch (_) {}
  }

  void _showEmployeeDetailsModal(
    BuildContext context,
    String name,
    double lat,
    double lng,
    DateTime time,
    double speed,
  ) {
    final timeStr = DateFormat('hh:mm:ss a, MMM d').format(time);
    final speedKmH = (speed * 3.6).toStringAsFixed(1);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Icon(Icons.person, color: Colors.indigo.shade900),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Last Logged: $timeStr',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Latitude', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(lat.toStringAsFixed(5), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Longitude', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(lng.toStringAsFixed(5), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Speed', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('$speedKmH km/h', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
