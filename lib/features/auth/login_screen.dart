import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:habi/shared/theme/habi_background.dart';

import 'package:habi/data/account_store.dart';
import 'package:habi/backend/auth_service.dart';
import 'package:habi/features/employer/employer_screen.dart';
import 'package:habi/features/admin/admin_screen.dart';
import 'package:habi/data/employer_store.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/features/home/job_seeker_shell.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/data/message_store.dart';
import 'package:habi/data/notification_store.dart';
import 'package:habi/features/auth/registration_role_screen.dart';

/// Screen 2: Login (Welcome Back).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _rememberMe = false;
  bool _isSigningIn = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: HabiColors.navyLight,
        ),
      );
  }

  Future<void> _logIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSigningIn = true);
    try {
      final credential = await HabiAuthService.instance.signIn(
        email: _idController.text,
        password: _passwordController.text,
      );
      final user = credential.user;
      if (user == null) throw StateError('Firebase returned no user session.');
      final token = await user.getIdTokenResult();
      final profile = await HabiAuthService.instance.userDocument(user.uid);
      final data = profile.data();
      if (data == null) {
        throw StateError('Your HABI account profile is missing.');
      }
      if (data['accountStatus'] == 'suspended') {
        await HabiAuthService.instance.signOut();
        if (mounted) {
          _showMessage(
            'Your account is currently suspended. Contact HABI support.',
          );
        }
        return;
      }
      await HabiAuthService.instance.ensureAdminDirectoryEntry(user.uid, data);
      if (token.claims?['admin'] == true) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AdminScreen()),
          (_) => false,
        );
        return;
      }
      final role = data['role'] as String?;
      MessageStore.instance.bindUser(user.uid);
      NotificationStore.instance.bindUser(user.uid);
      if (role == HabiAccountRole.jobSeeker.name) {
        await AccountStore.instance.load(user.uid);
        final account = AccountStore.instance.current!;
        JobStore.instance.bindUser(
          user.uid,
          displayName: account.displayName,
          asEmployer: false,
        );
        MessageStore.instance.bindUser(
          user.uid,
          displayName: account.displayName,
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => JobSeekerShell(userName: account.displayName),
          ),
          (_) => false,
        );
      } else if (role == HabiAccountRole.employer.name) {
        await EmployerStore.instance.load(user.uid);
        final employer = EmployerStore.instance.byCompanyName(
          data['displayName'] as String? ?? '',
        );
        if (employer == null) throw StateError('Employer profile is missing.');
        JobStore.instance.bindUser(
          user.uid,
          displayName: employer.companyName,
          asEmployer: true,
        );
        MessageStore.instance.bindUser(
          user.uid,
          displayName: employer.companyName,
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => EmployerScreen(companyName: employer.companyName),
          ),
          (_) => false,
        );
      } else {
        await HabiAuthService.instance.signOut();
        throw StateError('This account has no valid HABI role.');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) _showMessage(firebaseAuthMessage(error));
    } on FirebaseException catch (error) {
      if (mounted) {
        _showMessage('Could not load your profile (${error.code}). Try again.');
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _idController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Enter a valid email address first.');
      return;
    }
    try {
      await HabiAuthService.instance.sendPasswordReset(email);
      if (mounted) {
        _showMessage('If an account uses that email, a reset link was sent.');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) _showMessage(firebaseAuthMessage(error));
    } catch (_) {
      if (mounted) _showMessage('Could not send the reset email. Try again.');
    }
  }

  void _createAccount() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => RegistrationRoleScreen()));
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 1),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: TextStyle(
        color: HabiColors.cream.withAlpha(170),
        fontSize: 15,
      ),
      floatingLabelStyle: TextStyle(color: HabiColors.gold),
      hintStyle: TextStyle(color: HabiColors.cream.withAlpha(110)),
      filled: true,
      fillColor: HabiColors.navy.withAlpha(200),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: border(HabiColors.cream.withAlpha(70)),
      focusedBorder: border(HabiColors.gold),
      errorBorder: border(Color(0xFFE5766B)),
      focusedErrorBorder: border(Color(0xFFE5766B)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabiColors.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          HabiBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset('assets/habi_logo.png', width: 84),
                      ),
                      SizedBox(height: 6),
                      Center(
                        child: Text(
                          'HABI',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 38,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 8,
                            color: HabiColors.cream,
                          ),
                        ),
                      ),
                      SizedBox(height: 22),
                      Center(
                        child: Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: HabiColors.cream,
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Sign in to continue your journey.',
                          style: TextStyle(
                            fontSize: 14,
                            color: HabiColors.cream.withAlpha(200),
                          ),
                        ),
                      ),
                      SizedBox(height: 26),
                      TextFormField(
                        controller: _idController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(color: HabiColors.cream),
                        cursorColor: HabiColors.gold,
                        decoration: _fieldDecoration(
                          label: 'Email address',
                          hint: 'you@example.com',
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) {
                            return 'Enter your email address';
                          }
                          final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value);
                          if (!isEmail) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _logIn(),
                        style: TextStyle(color: HabiColors.cream),
                        cursorColor: HabiColors.gold,
                        decoration: _fieldDecoration(
                          label: 'Password',
                          suffix: IconButton(
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: HabiColors.cream.withAlpha(190),
                            ),
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Enter your password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 14),
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v ?? false),
                              activeColor: HabiColors.gold,
                              checkColor: HabiColors.ink,
                              side: BorderSide(
                                color: HabiColors.cream.withAlpha(160),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          InkWell(
                            onTap: () =>
                                setState(() => _rememberMe = !_rememberMe),
                            child: Text(
                              'Remember me',
                              style: TextStyle(
                                color: HabiColors.cream,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Spacer(),
                          TextButton(
                            onPressed: _sendPasswordReset,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: HabiColors.cream,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 22),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _isSigningIn ? null : _logIn,
                          style: FilledButton.styleFrom(
                            backgroundColor: HabiColors.gold,
                            foregroundColor: HabiColors.ink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: _isSigningIn
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('Log In'),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _createAccount,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: HabiColors.cream,
                            side: BorderSide(
                              color: HabiColors.cream.withAlpha(90),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                          child: Text('Create New Account'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
