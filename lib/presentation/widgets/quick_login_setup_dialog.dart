import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/employee_entity.dart';
import '../screens/employee/quick_login_screen.dart';

class QuickLoginSetupDialog {
  static Future<void> checkAndPrompt(BuildContext context, EmployeeEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    final hasPrompted = prefs.getBool('has_prompted_quick_login_setup_${user.uid}') ?? false;
    final isAlreadyEnabled = prefs.getBool('quick_login_enabled_${user.uid}') ?? false;

    if (!hasPrompted && !isAlreadyEnabled) {
      await prefs.setBool('has_prompted_quick_login_setup_${user.uid}', true);

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _QuickLoginPromptDialogWidget(user: user),
        );
      }
    }
  }
}

class _QuickLoginPromptDialogWidget extends StatefulWidget {
  final EmployeeEntity user;

  const _QuickLoginPromptDialogWidget({required this.user});

  @override
  State<_QuickLoginPromptDialogWidget> createState() => _QuickLoginPromptDialogWidgetState();
}

class _QuickLoginPromptDialogWidgetState extends State<_QuickLoginPromptDialogWidget> {
  int _step = 1; // 1: Prompt Question, 2: Enter PIN, 3: Confirm PIN
  String _firstPin = '';
  String _confirmPin = '';
  String _errorMessage = '';

  void _onKeyPress(String digit) {
    setState(() {
      _errorMessage = '';
      if (_step == 2) {
        if (_firstPin.length < 4) {
          _firstPin += digit;
          if (_firstPin.length == 4) {
            _step = 3;
          }
        }
      } else if (_step == 3) {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
          if (_confirmPin.length == 4) {
            _verifyAndSave();
          }
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = '';
      if (_step == 2 && _firstPin.isNotEmpty) {
        _firstPin = _firstPin.substring(0, _firstPin.length - 1);
      } else if (_step == 3) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _step = 2;
          _firstPin = '';
        }
      }
    });
  }

  Future<void> _verifyAndSave() async {
    if (_firstPin == _confirmPin) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('quick_login_enabled_${widget.user.uid}', true);
      await prefs.setString('quick_login_pin_${widget.user.uid}', _firstPin);

      // Save user meta for quick unlock on cold launch
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

      isQuickLoginUnlockedThisSession = true;

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quick PIN & Biometrics enabled successfully!'),
            backgroundColor: Color(0xFF047857),
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _step = 2;
        _firstPin = '';
        _confirmPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 1) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const Text(
              'Set Up Quick Login?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set a 4-digit PIN or use Fingerprint / Face ID for fast and secure access on future app launches.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('SKIP FOR NOW'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() {
                        _step = 2;
                      });
                    },
                    child: const Text('SET UP NOW'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Step 2 & 3: PIN Entry & Confirmation Dialog
    final currentPin = _step == 2 ? _firstPin : _confirmPin;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _step == 2 ? 'Create 4-Digit PIN' : 'Confirm 4-Digit PIN',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _step == 2 ? 'Enter a 4-digit PIN for quick unlock' : 'Re-enter your 4-digit PIN to confirm',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < currentPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
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

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],

            const SizedBox(height: 24),

            // Keypad Grid
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['1', '2', '3'].map((d) => _buildKeypadBtn(d)).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['4', '5', '6'].map((d) => _buildKeypadBtn(d)).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['7', '8', '9'].map((d) => _buildKeypadBtn(d)).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 54),
                    _buildKeypadBtn('0'),
                    IconButton(
                      icon: Icon(Icons.backspace_outlined, color: Colors.grey.shade700),
                      onPressed: _onBackspace,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadBtn(String digit) {
    return SizedBox(
      width: 54,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.grey.shade100,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        onPressed: () => _onKeyPress(digit),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
