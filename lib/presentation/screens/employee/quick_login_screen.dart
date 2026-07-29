import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/employee_entity.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../company/company_dashboard_screen.dart';
import 'employee_dashboard.dart';

bool isQuickLoginUnlockedThisSession = false;

class QuickLoginScreen extends StatefulWidget {
  final EmployeeEntity user;

  const QuickLoginScreen({super.key, required this.user});

  @override
  State<QuickLoginScreen> createState() => _QuickLoginScreenState();
}

class _QuickLoginScreenState extends State<QuickLoginScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  String _pin = '';
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _attemptBiometricPrompt() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();

      if (canCheck || isSupported) {
        final didAuth = await _localAuth.authenticate(
          localizedReason: 'Authenticate using Fingerprint or Face ID to unlock app',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (didAuth && mounted) {
          _onUnlockSuccess();
        }
      }
    } catch (e) {
      debugPrint('Biometric prompt skipped: $e');
    }
  }

  void _onKeyPress(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('quick_login_pin_${widget.user.uid}');

    if (_pin == savedPin) {
      await _onUnlockSuccess();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect PIN. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _pin = '';
      });
    }
  }

  Future<void> _onUnlockSuccess() async {
    isQuickLoginUnlockedThisSession = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user_uid', widget.user.uid);
    await prefs.setString('cached_user_email', widget.user.email);
    await prefs.setString('cached_user_name', widget.user.name);
    await prefs.setString('cached_user_role', widget.user.role);
    if (widget.user.companyId != null) {
      await prefs.setString('cached_company_id', widget.user.companyId!);
    }
    if (widget.user.companyName != null) {
      await prefs.setString('cached_company_name', widget.user.companyName!);
    }
    await prefs.setBool('cached_is_approved', widget.user.isApproved);
    await prefs.setBool('cached_is_first_login', widget.user.isFirstLogin);

    if (mounted) {
      context.read<AuthBloc>().add(CheckAuthStatusEvent());
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _isUnlocked = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked || isQuickLoginUnlockedThisSession) {
      if (widget.user.isCompany) {
        return CompanyDashboardScreen(user: widget.user);
      }
      return EmployeeDashboardScreen(user: widget.user);
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UnauthenticatedState) {
          isQuickLoginUnlockedThisSession = false;
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          titleSpacing: 20,
          title: const Text('Quick PIN & Biometric Unlock'),
          backgroundColor: Colors.indigo.shade800,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Header Avatar Circle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 48,
                    color: Colors.indigo.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome Back, ${widget.user.name}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use Fingerprint / Face ID or enter your 4-digit PIN to unlock.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 32),

                // PIN Visual Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _pin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? Colors.indigo.shade800 : Colors.grey.shade300,
                        border: Border.all(
                          color: isFilled ? Colors.indigo.shade800 : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
                const Spacer(),

                // Custom Keypad
                _buildKeypad(),
                const SizedBox(height: 16),

                // Use Password Instead Option
                TextButton.icon(
                  icon: const Icon(Icons.password, size: 18),
                  label: const Text('USE PASSWORD INSTEAD'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.indigo.shade800,
                  ),
                  onPressed: () {
                    isQuickLoginUnlockedThisSession = false;
                    context.read<AuthBloc>().add(LogoutSubmittedEvent());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((d) => _buildKeypadButton(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((d) => _buildKeypadButton(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((d) => _buildKeypadButton(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 36,
              icon: Icon(Icons.fingerprint, color: Colors.indigo.shade800),
              tooltip: 'Scan Fingerprint / Face ID',
              onPressed: _attemptBiometricPrompt,
            ),
            _buildKeypadButton('0'),
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.backspace_outlined, color: Color(0xFF334155)),
              onPressed: _onBackspace,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String digit) {
    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 1,
        ),
        onPressed: () => _onKeyPress(digit),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
