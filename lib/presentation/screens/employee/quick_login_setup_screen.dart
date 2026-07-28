import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/employee_entity.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';

class QuickLoginSetupScreen extends StatefulWidget {
  final EmployeeEntity user;

  const QuickLoginSetupScreen({super.key, required this.user});

  @override
  State<QuickLoginSetupScreen> createState() => _QuickLoginSetupScreenState();
}

class _QuickLoginSetupScreenState extends State<QuickLoginSetupScreen> {
  String _pin = '';
  String _firstPin = '';
  bool _isConfirming = false;
  bool _isSaving = false;

  void _onKeyPress(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
      });

      if (_pin.length == 4) {
        _processPinComplete();
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

  void _processPinComplete() async {
    if (!_isConfirming) {
      // First PIN entry complete -> switch to confirmation
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _isConfirming = true;
      });
    } else {
      // Confirmation PIN entry complete
      if (_pin == _firstPin) {
        // Matching PIN! Save to SharedPreferences
        _savePinAndFinish(_pin);
      } else {
        // Mismatch error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PINs do not match. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _pin = '';
          _firstPin = '';
          _isConfirming = false;
        });
      }
    }
  }

  Future<void> _savePinAndFinish(String pin) async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('quick_login_pin_${widget.user.uid}', pin);
      await prefs.setBool('quick_login_enabled_${widget.user.uid}', true);
      await prefs.setBool('has_quick_login_active', true);
      await prefs.setString('last_quick_login_uid', widget.user.uid);
      await prefs.setString('last_quick_login_email', widget.user.email);
      await prefs.setString('last_quick_login_name', widget.user.name);
      await prefs.setString('last_quick_login_role', widget.user.role);
      if (widget.user.companyId != null) {
        await prefs.setString('last_quick_login_company_id', widget.user.companyId!);
      }
      if (widget.user.companyName != null) {
        await prefs.setString('last_quick_login_company_name', widget.user.companyName!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('4-Digit Security PIN configured successfully!'),
            backgroundColor: Color(0xFF047857),
          ),
        );

        // Refresh auth status or pop
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.read<AuthBloc>().add(CheckAuthStatusEvent());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PIN: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _skipQuickLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quick_login_enabled_${widget.user.uid}', false);
    await prefs.setBool('has_quick_login_active', false);

    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.read<AuthBloc>().add(CheckAuthStatusEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Set Up Quick PIN Login'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Header Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pin_rounded,
                  size: 48,
                  color: Colors.indigo.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isConfirming ? 'Confirm Your 4-Digit PIN' : 'Create 4-Digit PIN',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirming
                    ? 'Re-enter your 4-digit PIN to confirm.'
                    : 'Set a 4-digit PIN for quick daily login without typing your full password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // PIN Visual Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
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

              // Custom Numeric Keypad
              _buildKeypad(),
              const SizedBox(height: 16),

              // Skip Button
              TextButton(
                onPressed: _isSaving ? null : _skipQuickLogin,
                child: const Text(
                  'SKIP FOR NOW',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
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
            const SizedBox(width: 72, height: 72),
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
