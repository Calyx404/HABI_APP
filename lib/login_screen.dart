import 'package:flutter/material.dart';

import 'habi_background.dart';

import 'account_store.dart';
import 'employer_screen.dart';
import 'employer_store.dart';
import 'habi_colors.dart';
import 'home_screen.dart';
import 'registration_role_screen.dart';

/// Screen 2: Login (Welcome Back).
class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _rememberMe = false;

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

  void _logIn() {
    if (!_formKey.currentState!.validate()) return;

    // TODO (backend): log in on the server.
    final account = AccountStore.instance.findByLoginId(_idController.text);
    if (account == null) {
      final employer = EmployerStore.instance.findByLoginId(_idController.text);
      if (employer == null) {
        _showMessage('No account found. Tap Create New Account to sign up.');
        return;
      }
      if (employer.password != _passwordController.text) {
        _showMessage('Incorrect password. Please try again.');
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => EmployerScreen(companyName: employer.companyName),
        ),
      );
      return;
    }
    if (account.password != _passwordController.text) {
      _showMessage('Incorrect password. Please try again.');
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(userName: account.displayName),
      ),
    );
  }

  void _createAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RegistrationRoleScreen()),
    );
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

  Widget _socialButton({required Widget child, required String name}) {
    return SizedBox(
      width: 72,
      height: 52,
      child: OutlinedButton(
        onPressed: () => _showMessage('$name sign-in is coming soon.'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: HabiColors.cream.withAlpha(90)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
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
                padding:
                    EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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
                          label: 'Email or Phone',
                          hint: 'you@example.com',
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) {
                            return 'Enter your email or phone';
                          }
                          final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value);
                          if (!isEmail && !isValidPhMobile(value)) {
                            return 'Enter a valid email or phone number';
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
                            onPressed: () => _showMessage(
                              'Password reset is coming soon.',
                            ),
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
                          onPressed: _logIn,
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
                          child: Text('Log In'),
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
                      SizedBox(height: 22),
                      Center(
                        child: Text(
                          'Or continue with',
                          style: TextStyle(
                            fontSize: 13,
                            color: HabiColors.cream.withAlpha(190),
                          ),
                        ),
                      ),
                      SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialButton(
                            name: 'Google',
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: HabiColors.cream,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          _socialButton(
                            name: 'Apple',
                            child: Icon(
                              Icons.apple,
                              size: 30,
                              color: HabiColors.cream,
                            ),
                          ),
                        ],
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
