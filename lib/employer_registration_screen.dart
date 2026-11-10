import 'package:flutter/material.dart';

import 'habi_background.dart';

import 'account_store.dart';
import 'employer_profile_setup_screen.dart';
import 'employer_store.dart';
import 'job_store.dart';
import 'message_store.dart';
import 'notification_store.dart';
import 'form_widgets.dart';
import 'habi_colors.dart';
import 'ph_locations.dart';

const _organizationTypes = [
  'Private Company',
  'Small and Medium Enterprise (SME)',
  'Government Agency',
  'Non-Government Organization (NGO)',
  'Cooperative',
  'Social Enterprise',
  'Other',
];

const _industries = [
  'Agriculture',
  'Arts and Entertainment',
  'Construction',
  'Education',
  'Finance and Insurance',
  'Food and Hospitality',
  'Government',
  'Healthcare',
  'Information Technology',
  'Manufacturing',
  'Nonprofit',
  'Retail and Trade',
  'Transportation and Logistics',
  'Other',
];

class EmployerRegistrationScreen extends StatefulWidget {
  const EmployerRegistrationScreen({super.key});

  @override
  State<EmployerRegistrationScreen> createState() =>
      _EmployerRegistrationScreenState();
}

class _EmployerRegistrationScreenState
    extends State<EmployerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    for (final name in [
      'Company / Organization Name',
      'Company Email Address',
      "Contact Person's First Name",
      "Contact Person's Last Name",
      'Position / Designation',
      'Contact Number',
      'Company Address',
      'Company Description',
      'Password',
      'Confirm Password',
    ])
      name: TextEditingController(),
  };
  String? _organizationType;
  String? _industry;
  bool _isSubmitting = false;
  String? _city;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _agreed = false;
  bool _consentError = false;

  static const _requiredFields = {
    'Company / Organization Name',
    'Company Email Address',
    "Contact Person's First Name",
    "Contact Person's Last Name",
    'Position / Designation',
    'Contact Number',
    'Company Address',
    'Password',
    'Confirm Password',
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextFormField _field(
    String label, {
    String? hint,
    TextInputType? keyboard,
    int maxLines = 1,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    TextCapitalization capitalization = TextCapitalization.none,
  }) => TextFormField(
    controller: _controllers[label],
    keyboardType: keyboard,
    maxLines: obscure ? 1 : maxLines,
    obscureText: obscure,
    textCapitalization: capitalization,
    style: TextStyle(color: HabiColors.cream),
    cursorColor: HabiColors.gold,
    decoration: habiDecoration(
      '$label${_requiredFields.contains(label) ? ' *' : ''}',
      hint: hint,
      suffix: suffix,
    ),
    validator:
        validator ??
        (value) {
          final text = value?.trim() ?? '';
          if (_requiredFields.contains(label) && text.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
  );

  String? _emailValidator(String? value, {bool required = true}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'Enter an email address' : null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _pickCity() async {
    final city = await showSearchPicker(
      context,
      title: 'City / Municipality',
      options: kPhLocations,
      selected: _city ?? '',
    );
    if (city != null && mounted) setState(() => _city = city);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      setState(() => _consentError = true);
      return;
    }
    if (_organizationType == null || _industry == null || _city == null) {
      showHabiSnack(context, 'Select organization type, industry, and city.');
      return;
    }
    final password = _controllers['Password']!.text;
    if (password.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      showHabiSnack(
        context,
        'Password must have 8 characters, a letter, and a number.',
      );
      return;
    }
    if (password != _controllers['Confirm Password']!.text) {
      showHabiSnack(context, 'Passwords do not match.');
      return;
    }
    final phone = _controllers['Contact Number']!.text.trim();
    if (!isValidPhMobile(phone)) {
      showHabiSnack(context, 'Enter a valid Philippine contact number.');
      return;
    }
    final account = EmployerAccount(
      companyName: _controllers['Company / Organization Name']!.text.trim(),
      organizationType: _organizationType!,
      industry: _industry!,
      email: _controllers['Company Email Address']!.text.trim(),
      contactFirstName: _controllers["Contact Person's First Name"]!.text
          .trim(),
      contactLastName: _controllers["Contact Person's Last Name"]!.text.trim(),
      position: _controllers['Position / Designation']!.text.trim(),
      phone: normalizePhone(phone),
      address: _controllers['Company Address']!.text.trim(),
      city: _city!,
      description: _controllers['Company Description']!.text.trim(),
    );
    setState(() => _isSubmitting = true);
    try {
      final error = await EmployerStore.instance.register(
        account,
        password: password,
      );
      if (error != null) {
        if (mounted) showHabiSnack(context, error);
        return;
      }
      final uid = EmployerStore.instance
          .byCompanyName(account.companyName)
          ?.uid;
      if (uid == null || uid.isEmpty) {
        throw StateError('The employer account was created without a user ID.');
      }
      JobStore.instance.bindUser(uid, displayName: account.companyName);
      MessageStore.instance.bindUser(uid, displayName: account.companyName);
      NotificationStore.instance.bindUser(uid);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => EmployerProfileSetupScreen(
            companyName: account.companyName,
            isOnboarding: true,
          ),
        ),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) => habiDropdown(
    label: '$label *',
    value: value,
    items: options,
    hint: 'Select',
    onChanged: onChanged,
    validator: (value) => value == null ? 'Select an option' : null,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HabiColors.navy,
    appBar: AppBar(
      backgroundColor: HabiColors.navy,
      foregroundColor: HabiColors.cream,
      title: Text('Create Account'),
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        HabiBackground(),
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 28),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Register your organization and the person authorized to manage its vacancies.',
                    style: TextStyle(color: HabiColors.cream.withAlpha(210)),
                  ),
                  SectionHeader('Organization'),
                  _field(
                    'Company / Organization Name',
                    capitalization: TextCapitalization.words,
                  ),
                  SizedBox(height: 16),
                  _dropdown(
                    label: 'Organization Type',
                    value: _organizationType,
                    options: _organizationTypes,
                    onChanged: (v) => setState(() => _organizationType = v),
                  ),
                  SizedBox(height: 16),
                  _dropdown(
                    label: 'Industry',
                    value: _industry,
                    options: _industries,
                    onChanged: (v) => setState(() => _industry = v),
                  ),
                  SectionHeader('Contact person'),
                  _field(
                    'Company Email Address',
                    keyboard: TextInputType.emailAddress,
                    validator: (v) => _emailValidator(v),
                  ),
                  SizedBox(height: 16),
                  _field(
                    "Contact Person's First Name",
                    capitalization: TextCapitalization.words,
                  ),
                  SizedBox(height: 16),
                  _field(
                    "Contact Person's Last Name",
                    capitalization: TextCapitalization.words,
                  ),
                  SizedBox(height: 16),
                  _field(
                    'Position / Designation',
                    capitalization: TextCapitalization.words,
                  ),
                  SizedBox(height: 16),
                  _field(
                    'Contact Number',
                    keyboard: TextInputType.phone,
                    hint: '0917 123 4567',
                  ),
                  SectionHeader('Company address'),
                  _field(
                    'Company Address',
                    capitalization: TextCapitalization.words,
                    maxLines: 2,
                  ),
                  SizedBox(height: 16),
                  FormField<String>(
                    validator: (_) =>
                        _city == null ? 'Select a city or municipality' : null,
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: _pickCity,
                          child: InputDecorator(
                            decoration: habiDecoration(
                              'City / Municipality *',
                              suffix: Icon(
                                Icons.arrow_drop_down,
                                color: HabiColors.cream,
                              ),
                            ).copyWith(errorText: state.errorText),
                            child: Text(
                              _city ?? 'Select',
                              style: TextStyle(
                                color: _city == null
                                    ? HabiColors.cream.withAlpha(110)
                                    : HabiColors.cream,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _field('Company Description', maxLines: 4),
                  SectionHeader('Account security'),
                  _field(
                    'Password',
                    obscure: _hidePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: HabiColors.cream,
                      ),
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                    ),
                    validator: (v) {
                      final text = v ?? '';
                      if (text.isEmpty) return 'This field is required';
                      if (text.length < 8 ||
                          !RegExp(r'[A-Za-z]').hasMatch(text) ||
                          !RegExp(r'\d').hasMatch(text)) {
                        return 'Use at least 8 characters, with a letter and a number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _field(
                    'Confirm Password',
                    obscure: _hideConfirm,
                    suffix: IconButton(
                      icon: Icon(
                        _hideConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: HabiColors.cream,
                      ),
                      onPressed: () =>
                          setState(() => _hideConfirm = !_hideConfirm),
                    ),
                    validator: (v) => v != _controllers['Password']!.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  SizedBox(height: 14),
                  _buildConsent(),
                  SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: HabiColors.gold,
                        foregroundColor: HabiColors.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: HabiColors.cream.withAlpha(200),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: HabiColors.gold,
                        ),
                        child: Text('Log in'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildConsent() {
    void toggle() => setState(() {
      _agreed = !_agreed;
      if (_agreed) _consentError = false;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreed,
                onChanged: (_) => toggle(),
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
            SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: toggle,
                child: Text(
                  'I agree to the Terms of Use and Privacy Notice, and I allow HABI to use my organization’s information to manage job vacancies.',
                  style: TextStyle(
                    fontSize: 13,
                    color: HabiColors.cream.withAlpha(220),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_consentError && !_agreed)
          Padding(
            padding: EdgeInsets.only(top: 6, left: 34),
            child: Text(
              'Please agree to continue',
              style: TextStyle(fontSize: 12, color: Color(0xFFE5766B)),
            ),
          ),
      ],
    );
  }
}
