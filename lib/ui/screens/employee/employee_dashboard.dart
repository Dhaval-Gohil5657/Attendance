import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../backend/models/employee_model.dart';
import '../../bloc/attendance/attendance_bloc.dart';
import '../../bloc/attendance/attendance_event.dart';
import '../../bloc/attendance/attendance_state.dart';
import '../../widgets/quick_login_setup_dialog.dart';
import '../../widgets/slide_to_confirm_widget.dart';
import 'employee_profile_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final EmployeeEntity user;

  const EmployeeDashboardScreen({super.key, required this.user});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  bool _isMapOpen = false; // Closed by default as per requirement
  String _selectedTravelMode = 'Four-Wheeler';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceBloc>().add(
            InitializeAttendance(employeeId: widget.user.email),
          );
      QuickLoginSetupDialog.checkAndPrompt(context, widget.user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.badge_rounded, color: Colors.white, size: 25),
            ),
            const SizedBox(width: 12),
            const Text(
              'Employee Workspace',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.user.companyId ?? widget.user.uid)
            .snapshots(),
        builder: (context, compSnapshot) {
          final compData = compSnapshot.data?.data();
          final policy = compData?['attendancePolicy'] as Map<String, dynamic>?;
          final enableTravelMode = policy?['enableTravelMode'] ?? false;

          return BlocConsumer<AttendanceBloc, AttendanceState>(
            listener: (context, state) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
              if (state.successMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.successMessage!),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final activeAttendance = state.activeAttendance;
              final isCheckedIn = activeAttendance != null &&
                  (activeAttendance.status == 'active' || activeAttendance.status == 'on_break');
              final isCheckedOut = activeAttendance != null && activeAttendance.status == 'checked_out';
              final isOnBreak = activeAttendance?.status == 'on_break';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Employee Info Profile Card
                    _buildEmployeeCard(context),

                    const SizedBox(height: 16),

                    // 2. PRIMARY ACTION CONTROLS
                    _buildActionControls(context, isCheckedIn, isCheckedOut, isOnBreak, enableTravelMode),

                    const SizedBox(height: 20),

                    // 3. Main Attendance Status & Dynamic Timer Banner
                    _buildAttendanceStatusBanner(context, isCheckedIn, isCheckedOut, isOnBreak, state, enableTravelMode),

                    const SizedBox(height: 16),

                    // 4. Live Network & Sync Status Row
                    _buildNetworkStatusRow(context, state),

                    const SizedBox(height: 16),

                    // 5. Live Location Telemetry Info Card
                    _buildLocationCard(state, isOnBreak),

                    const SizedBox(height: 16),

                    // 6. Collapsible Live Interactive Map View
                    _buildCollapsibleMapCard(state),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EmployeeProfileScreen(user: widget.user),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade800, Colors.indigo.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 34, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.name.isNotEmpty ? widget.user.name : 'Employee User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.email,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionControls(
    BuildContext context,
    bool isCheckedIn,
    bool isCheckedOut,
    bool isOnBreak,
    bool enableTravelMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isCheckedOut) ...[
          // Workday Completed Pill Badge (Matching 55px Slider Size & Handle Shape)
          Container(
            height: 55,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(27.5),
              border: Border.all(color: Colors.blue.shade200,width: 0.6),
            ),
            child: Row(
              children: [
                // Flush 55px Circle Handle at Far Left
                Container(
                  width: 53.5,
                  height: 53.5,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'WORKDAY COMPLETED FOR TODAY',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ] else if (!isCheckedIn) ...[
          if (enableTravelMode) ...[
            // Travel Mode Selection Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.directions_transit_filled_rounded, size: 18, color: Color(0xFF334155)),
                      SizedBox(width: 6),
                      Text(
                        'Select Travel Mode Requirement',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildTravelChip('Walking', Icons.directions_walk_rounded),
                      const SizedBox(width: 8),
                      _buildTravelChip('Two-Wheeler', Icons.two_wheeler_rounded),
                      const SizedBox(width: 8),
                      _buildTravelChip('Four-Wheeler', Icons.directions_car_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Slide to Start Attendance
          SlideToConfirmWidget(
            text: 'SLIDE TO MARK ATTENDANCE',
            icon: Icons.play_arrow_rounded,
            backgroundColor: Colors.indigo.shade50,
            sliderColor: Colors.indigo.shade800,
            textColor: Colors.indigo.shade900,
            onConfirmed: () {
              context.read<AttendanceBloc>().add(
                    CheckInEvent(
                      employeeId: widget.user.email,
                      travelMode: _selectedTravelMode,
                    ),
                  );
            },
          ),
        ] else ...[
          // Break Toggle Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (isOnBreak) {
                      context.read<AttendanceBloc>().add(EndBreakEvent());
                    } else {
                      context.read<AttendanceBloc>().add(StartBreakEvent());
                    }
                  },
                  icon: Icon(
                    isOnBreak ? Icons.play_arrow_rounded : Icons.free_breakfast_rounded,
                    size: 22,
                  ),
                  label: Text(
                    isOnBreak ? 'END BREAK' : 'START BREAK',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOnBreak ? Colors.green.shade700 : Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Slide to Close Attendance with EOD Popup Confirmation (Right-to-Left Reverse Slide)
          SlideToConfirmWidget(
            text: 'SLIDE TO CLOSE ATTENDANCE',
            icon: Icons.stop_rounded,
            backgroundColor: Colors.red.shade50,
            sliderColor: Colors.red.shade700,
            textColor: Colors.red.shade900,
            isReversed: true,
            onConfirmed: () {
              _showCheckOutConfirmationDialog(context);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTravelChip(String mode, IconData icon) {
    final isSelected = _selectedTravelMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTravelMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.indigo.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.indigo.shade800 : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.indigo.shade900 : Colors.grey.shade600,
              ),
              const SizedBox(height: 2),
              Text(
                mode,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.indigo.shade900 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkStatusRow(BuildContext context, AttendanceState state) {
    return Row(
      children: [
        // Internet Status Chip
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: state.isOnline ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: state.isOnline ? Colors.green.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  state.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: state.isOnline ? Colors.green.shade700 : Colors.orange.shade700,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    state.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: state.isOnline ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Unsynced Items Count Chip
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: state.unsyncedCount > 0 ? Colors.amber.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: state.unsyncedCount > 0 ? Colors.amber.shade300 : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: state.unsyncedCount > 0 ? Colors.amber.shade900 : Colors.blue.shade700,
                  size: 18,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Pending: ${state.unsyncedCount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      color: state.unsyncedCount > 0 ? Colors.amber.shade900 : Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Sync Now Button (Right side of Online & Pending status)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.read<AttendanceBloc>().add(const SyncNowEvent(isManualSync: true));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.indigo.shade600,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sync_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStatusBanner(
    BuildContext context,
    bool isCheckedIn,
    bool isCheckedOut,
    bool isOnBreak,
    AttendanceState state,
    bool enableTravelMode,
  ) {
    final active = state.activeAttendance;
    final checkInFormatted = active != null
        ? DateFormat('hh:mm a').format(active.checkInTime)
        : '--:--';
    final checkOutFormatted = (active != null && active.checkOutTime != null)
        ? DateFormat('hh:mm a').format(active.checkOutTime!)
        : '--:--';

    String statusText = 'NOT STARTED';
    Color badgeColor = Colors.grey.shade700;
    Color badgeBg = Colors.grey.shade100;
    String bannerTitle = 'Not Checked In Today';

    if (isOnBreak) {
      statusText = 'ON BREAK';
      badgeColor = Colors.amber.shade900;
      badgeBg = Colors.amber.shade50;
      bannerTitle = 'On Break (Tracking Paused)';
    } else if (isCheckedIn) {
      statusText = 'CHECKED IN';
      badgeColor = const Color(0xFF047857);
      badgeBg = const Color(0xFFECFDF5);
      bannerTitle = 'Workday Active (Live Tracking)';
    } else if (isCheckedOut) {
      statusText = 'CHECKED OUT';
      badgeColor = Colors.blue.shade900;
      badgeBg = Colors.blue.shade50;
      bannerTitle = 'Workday Completed';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Workday Lifecycle',
                style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: badgeColor),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bannerTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if ((isCheckedIn || isCheckedOut) && active != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Check-in', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(checkInFormatted, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                if (isCheckedOut)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Check-out', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(checkOutFormatted, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                if (enableTravelMode)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Mode', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        active.travelMode,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo.shade900),
                      ),
                    ],
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Duration', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 2),
                    isCheckedOut
                        ? Text(
                            _formatDuration(active.checkOutTime!.difference(active.checkInTime)),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo.shade900),
                          )
                        : _WorkdayTimerWidget(startTime: active.checkInTime),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Widget _buildLocationCard(AttendanceState state, bool isOnBreak) {
    final latText = state.currentLatitude != null
        ? state.currentLatitude!.toStringAsFixed(6)
        : 'Fetching location...';
    final longText = state.currentLongitude != null
        ? state.currentLongitude!.toStringAsFixed(6)
        : 'Fetching location...';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: isOnBreak ? Colors.grey : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOnBreak
                      ? 'Live Location (Paused during Break)'
                      : 'Live Location Stream (5s Interval)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Latitude', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(latText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Longitude', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(longText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleMapCard(AttendanceState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tappable Header to Open / Close Map View
          InkWell(
            onTap: () {
              setState(() {
                _isMapOpen = !_isMapOpen;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.map_rounded, color: Colors.indigo.shade800, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Location Map View',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isMapOpen ? 'Tap to hide live map view' : 'Tap to open live map view',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isMapOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Map Content (Hidden when _isMapOpen is false)
          if (_isMapOpen) ...[
            const Divider(height: 1),
            _buildLiveMapCard(state),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveMapCard(AttendanceState state) {
    if (state.currentLatitude == null || state.currentLongitude == null) {
      return Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Acquiring satellite GPS map location...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final userLatLng = LatLng(state.currentLatitude!, state.currentLongitude!);

    return Container(
      height: 260,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: userLatLng,
              initialZoom: 17.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.attendance',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: userLatLng,
                    width: 40,
                    height: 40,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                      child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.map, color: Colors.amberAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Live Movement Map',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckOutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Close Attendance?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your workday? All background location tracking will be stopped and your session finalized for today.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AttendanceBloc>().add(CheckOutEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm & Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _WorkdayTimerWidget extends StatefulWidget {
  final DateTime startTime;

  const _WorkdayTimerWidget({required this.startTime});

  @override
  State<_WorkdayTimerWidget> createState() => _WorkdayTimerWidgetState();
}

class _WorkdayTimerWidgetState extends State<_WorkdayTimerWidget> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _calculateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _calculateElapsed();
        });
      }
    });
  }

  void _calculateElapsed() {
    _elapsed = DateTime.now().difference(widget.startTime);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Text(
      '$hours:$minutes:$seconds',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Colors.indigo,
        fontFamily: 'monospace',
      ),
    );
  }
}
