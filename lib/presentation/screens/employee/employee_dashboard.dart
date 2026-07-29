import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/entities/employee_entity.dart';
import '../../bloc/attendance_bloc.dart';
import '../../bloc/attendance_event.dart';
import '../../bloc/attendance_state.dart';
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
        title: const Text(
          'Attendance & Live Tracking',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Now',
            onPressed: () {
              context.read<AttendanceBloc>().add(const SyncNowEvent(isManualSync: true));
            },
          ),
        ],
      ),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
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
          final isActive = activeAttendance != null;
          final isOnBreak = activeAttendance?.status == 'on_break';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Employee Info Profile Card
                _buildEmployeeCard(context),

                const SizedBox(height: 16),

                // 2. PRIMARY ACTION CONTROLS (Placed right below Profile Card as per Option 1)
                _buildActionControls(context, isActive, isOnBreak),

                const SizedBox(height: 20),

                // 3. Main Attendance Status & Dynamic Timer Banner
                _buildAttendanceStatusBanner(context, isActive, isOnBreak, state),

                const SizedBox(height: 16),

                // 4. Live Network & Sync Status Row
                _buildNetworkStatusRow(context, state),

                const SizedBox(height: 16),

                // 5. Live Location Telemetry Info Card
                _buildLocationCard(state, isOnBreak),

                const SizedBox(height: 16),

                // 6. Collapsible Live Interactive Map View (CLOSED BY DEFAULT)
                _buildCollapsibleMapCard(state),
              ],
            ),
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

  Widget _buildActionControls(BuildContext context, bool isActive, bool isOnBreak) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isActive) ...[
          // Slide to Start Attendance
          SlideToConfirmWidget(
            text: 'SLIDE TO MARK ATTENDANCE',
            icon: Icons.play_arrow_rounded,
            backgroundColor: Colors.indigo.shade50,
            sliderColor: Colors.indigo.shade800,
            textColor: Colors.indigo.shade900,
            onConfirmed: () {
              context.read<AttendanceBloc>().add(CheckInEvent(employeeId: widget.user.email));
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

          // Slide to Close Attendance with EOD Popup Confirmation
          SlideToConfirmWidget(
            text: 'SLIDE TO CLOSE ATTENDANCE',
            icon: Icons.stop_rounded,
            backgroundColor: Colors.red.shade50,
            sliderColor: Colors.red.shade700,
            textColor: Colors.red.shade900,
            onConfirmed: () {
              _showCheckOutConfirmationDialog(context);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildNetworkStatusRow(BuildContext context, AttendanceState state) {
    return Row(
      children: [
        // Internet Status Chip
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: state.isOnline ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Unsynced Items Count Chip (Tappable for Manual Sync)
        Expanded(
          child: InkWell(
            onTap: () {
              context.read<AttendanceBloc>().add(const SyncNowEvent(isManualSync: true));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pending: ${state.unsyncedCount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: state.unsyncedCount > 0 ? Colors.amber.shade900 : Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStatusBanner(
    BuildContext context,
    bool isActive,
    bool isOnBreak,
    AttendanceState state,
  ) {
    final checkInFormatted = state.activeAttendance != null
        ? DateFormat('hh:mm a').format(state.activeAttendance!.checkInTime)
        : '--:--';

    String statusText = 'CHECKED OUT';
    Color badgeColor = Colors.grey.shade600;
    Color badgeBg = Colors.grey.shade200;

    if (isOnBreak) {
      statusText = 'ON BREAK';
      badgeColor = Colors.amber.shade900;
      badgeBg = Colors.amber.shade100;
    } else if (isActive) {
      statusText = 'ACTIVE';
      badgeColor = Colors.green.shade800;
      badgeBg = Colors.green.shade100;
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
            isOnBreak
                ? 'On Break (Tracking Paused)'
                : (isActive ? 'Workday Active (Live Tracking)' : 'Not Checked In'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (isActive && state.activeAttendance != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Check-in Time', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(checkInFormatted, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Workday Duration', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 2),
                    _WorkdayTimerWidget(startTime: state.activeAttendance!.checkInTime),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
