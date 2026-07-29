import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/employee_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'company/company_register_screen.dart';
import 'employee/quick_login_screen.dart';

class LoginScreen extends StatefulWidget {
  final String initialRole; // 'company' or 'employee'

  const LoginScreen({
    super.key,
    this.initialRole = 'employee',
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _hasQuickLogin = false;

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      if (widget.initialRole == 'company') {
        _emailController.text = 'company@gmail.com';
        _passwordController.text = '123456';
      } else {
        _emailController.text = 'employee@gmail.com';
        _passwordController.text = '123456';
      }
    }

    _checkQuickLoginAvailability();
  }

  Future<void> _checkQuickLoginAvailability() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool('has_quick_login_active') ?? false;
    final cachedUid = prefs.getString('cached_user_uid') ?? prefs.getString('last_quick_login_uid');

    if (cachedUid != null) {
      final isUserEnabled = prefs.getBool('quick_login_enabled_$cachedUid') ?? false;
      if (mounted) {
        setState(() => _hasQuickLogin = isActive || isUserEnabled);
      }
    } else if (isActive && mounted) {
      setState(() => _hasQuickLogin = true);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      isQuickLoginUnlockedThisSession = true;
      context.read<AuthBloc>().add(
            LoginSubmittedEvent(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              role: widget.initialRole,
            ),
          );
    }
  }

  void _openQuickLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('last_quick_login_uid') ?? prefs.getString('cached_user_uid');
    final email = prefs.getString('last_quick_login_email') ?? prefs.getString('cached_user_email');
    final name = prefs.getString('last_quick_login_name') ?? prefs.getString('cached_user_name');
    final role = prefs.getString('last_quick_login_role') ?? widget.initialRole;
    final companyId = prefs.getString('last_quick_login_company_id') ?? prefs.getString('cached_company_id');
    final companyName = prefs.getString('last_quick_login_company_name') ?? prefs.getString('cached_company_name');

    if (uid != null && email != null && mounted) {
      final quickUser = EmployeeEntity(
        uid: uid,
        email: email,
        name: name ?? email.split('@').first,
        role: role,
        companyId: companyId,
        companyName: companyName,
        isApproved: true,
        isFirstLogin: false,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QuickLoginScreen(user: quickUser),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in with email and password first.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = widget.initialRole == 'company';
    final primaryColor = isCompany ? Colors.indigo.shade800 : Colors.teal.shade800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isCompany ? 'Company Login' : 'Employee Login'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is CompanyPendingApprovalState || state is AuthenticatedState) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else if (state is UnauthenticatedState && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoadingState;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Role Icon Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompany ? Colors.indigo.shade50 : Colors.teal.shade50,
                        ),
                        child: Icon(
                          isCompany ? Icons.corporate_fare : Icons.person_pin_rounded,
                          size: 56,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        isCompany ? 'Company Login' : 'Employee Login',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isCompany
                            ? 'Sign in using company owner credentials'
                            : 'Sign in using credentials provided by your company',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 32),

                      // Email / User ID Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: isCompany ? 'Company Email Address' : 'Employee User ID / Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter your email or ID';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter password';
                          if (v.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text(
                                'LOG IN',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Quick PIN / Biometric Button if configured
                      if (_hasQuickLogin) ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('QUICK PIN / BIOMETRIC UNLOCK'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF047857),
                            side: const BorderSide(color: Color(0xFF047857)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _openQuickLogin,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Register Company Button if Company mode selected
                      if (isCompany) ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add_business),
                          label: const Text('REGISTER NEW COMPANY'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const CompanyRegisterScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
