import 'package:flutter/material.dart';

import 'habi_background.dart';

import 'account_store.dart';
import 'job_store.dart';
import 'message_store.dart';
import 'notification_store.dart';
import 'form_widgets.dart';
import 'habi_colors.dart';
import 'ph_locations.dart';
import 'profile_setup_screen.dart';

const List<String> kSuffixes = ['None', 'Jr.', 'Sr.', 'II', 'III', 'IV', 'V'];
const List<String> kSexOptions = ['Male', 'Female', 'Prefer not to say'];
const List<String> kGenderIdentities = [
  'Man',
  'Woman',
  'Non-binary',
  'Transgender man',
  'Transgender woman',
  'Prefer to self-describe',
  'Prefer not to say',
];

/// Job Seeker Registration.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _last = TextEditingController();
  final _dob = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _address = TextEditingController();
  final _location = TextEditingController();
  final _barangay = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  DateTime? _birthDate;
  String _suffix = 'None';
  String? _sex;
  String? _gender;
  bool _isSubmitting = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _agreed = false;
  bool _consentError = false;

  static final _nameChars = RegExp(r"^[A-Za-zÀ-ÿ .'-]+$");
  static const _gap = SizedBox(height: 16);

  @override
  void dispose() {
    _first.dispose();
    _middle.dispose();
    _last.dispose();
    _dob.dispose();
    _email.dispose();
    _mobile.dispose();
    _address.dispose();
    _location.dispose();
    _barangay.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _nameValidator(String? v, String label, {bool required = true}) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return required ? 'Enter your $label' : null;
    if (!_nameChars.hasMatch(value)) return 'Use letters only';
    return null;
  }

  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Date of birth',
    );
    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
        _dob.text = formatDate(picked);
      });
    }
  }

  Future<void> _pickLocation() async {
    FocusScope.of(context).unfocus();
    final picked = await showSearchPicker(
      context,
      title: 'Province / City / Municipality',
      options: kPhLocations,
      trailing: const [kOtherLocation],
      selected: _location.text,
    );
    if (picked != null && mounted) {
      setState(() => _location.text = picked);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final valid = _formKey.currentState!.validate();
    if (!_agreed) setState(() => _consentError = true);
    if (!valid || !_agreed) return;

    final dob = _birthDate;
    final sex = _sex;
    if (dob == null || sex == null) return;

    final account = Account(
      firstName: _first.text.trim(),
      middleName: _middle.text.trim(),
      lastName: _last.text.trim(),
      suffix: _suffix == 'None' ? '' : _suffix,
      birthDate: dob,
      sex: sex,
      genderIdentity: _gender ?? '',
      email: _email.text.trim(),
      mobile: normalizePhone(_mobile.text),
      address: _address.text.trim(),
      cityProvince: _location.text.trim(),
      barangay: _barangay.text.trim(),
    );
    setState(() => _isSubmitting = true);
    try {
      final error = await AccountStore.instance.register(
        account,
        password: _password.text,
      );
      if (error != null) {
        if (mounted) showHabiSnack(context, error);
        return;
      }
      final signedIn = AccountStore.instance.current!;
      JobStore.instance.bindUser(
        signedIn.uid,
        displayName: signedIn.displayName,
      );
      MessageStore.instance.bindUser(
        signedIn.uid,
        displayName: signedIn.displayName,
      );
      NotificationStore.instance.bindUser(signedIn.uid);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(
            userName: account.displayName,
            firstTime: true,
          ),
        ),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helper,
    TextInputType? keyboard,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputAction action = TextInputAction.next,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textCapitalization: capitalization,
      textInputAction: action,
      obscureText: obscure,
      style: TextStyle(color: HabiColors.cream),
      cursorColor: HabiColors.gold,
      decoration: habiDecoration(
        label,
        hint: hint,
        helper: helper,
        suffix: suffix,
      ),
      validator: validator,
    );
  }

  Widget _tapField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: TextStyle(color: HabiColors.cream),
      decoration: habiDecoration(
        label,
        hint: hint,
        suffix: Icon(icon, color: HabiColors.cream),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabiColors.navy,
      appBar: AppBar(
        backgroundColor: HabiColors.navy,
        foregroundColor: HabiColors.cream,
        elevation: 0,
        title: Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
                      'Tell us a little about you. You can finish your '
                      'profile after signing up.',
                      style: TextStyle(
                        fontSize: 14,
                        color: HabiColors.cream.withAlpha(210),
                      ),
                    ),
                    SectionHeader('Personal information'),
                    _field(
                      controller: _first,
                      label: 'First name *',
                      capitalization: TextCapitalization.words,
                      validator: (v) => _nameValidator(v, 'first name'),
                    ),
                    _gap,
                    _field(
                      controller: _middle,
                      label: 'Middle name (optional)',
                      capitalization: TextCapitalization.words,
                      validator: (v) =>
                          _nameValidator(v, 'middle name', required: false),
                    ),
                    _gap,
                    _field(
                      controller: _last,
                      label: 'Last name *',
                      capitalization: TextCapitalization.words,
                      validator: (v) => _nameValidator(v, 'last name'),
                    ),
                    _gap,
                    habiDropdown(
                      label: 'Suffix (optional)',
                      value: _suffix,
                      items: kSuffixes,
                      onChanged: (v) => setState(() => _suffix = v),
                    ),
                    _gap,
                    _tapField(
                      controller: _dob,
                      label: 'Date of birth *',
                      hint: 'Select your date of birth',
                      icon: Icons.calendar_today_outlined,
                      onTap: _pickBirthDate,
                      validator: (v) {
                        final dob = _birthDate;
                        if (dob == null) return 'Select your date of birth';
                        if (ageOn(dob, DateTime.now()) < kMinimumAge) {
                          return 'You must be at least $kMinimumAge years '
                              'old to register';
                        }
                        return null;
                      },
                    ),
                    _gap,
                    habiDropdown(
                      label: 'Sex *',
                      value: _sex,
                      hint: 'Select',
                      items: kSexOptions,
                      onChanged: (v) => setState(() => _sex = v),
                      validator: (v) => v == null ? 'Select an option' : null,
                    ),
                    _gap,
                    habiDropdown(
                      label: 'Gender identity (optional)',
                      value: _gender,
                      hint: 'Select',
                      items: kGenderIdentities,
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    SectionHeader('Contact'),
                    _field(
                      controller: _email,
                      label: 'Email address *',
                      hint: 'you@example.com',
                      keyboard: TextInputType.emailAddress,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Enter your email address';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    _gap,
                    _field(
                      controller: _mobile,
                      label: 'Mobile number *',
                      hint: '0917 123 4567',
                      keyboard: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter your mobile number';
                        }
                        if (!isValidPhMobile(v)) {
                          return 'Use a Philippine number like 0917 123 4567';
                        }
                        return null;
                      },
                    ),
                    SectionHeader('Address'),
                    _field(
                      controller: _address,
                      label: 'Complete address *',
                      hint: 'House or unit no., street',
                      capitalization: TextCapitalization.words,
                      validator: (v) => (v?.trim().length ?? 0) < 5
                          ? 'Enter your complete address'
                          : null,
                    ),
                    _gap,
                    _tapField(
                      controller: _location,
                      label: 'Province / City / Municipality *',
                      hint: 'Select',
                      icon: Icons.arrow_drop_down,
                      onTap: _pickLocation,
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Select your province, city or municipality'
                          : null,
                    ),
                    _gap,
                    _field(
                      controller: _barangay,
                      label: 'Barangay *',
                      capitalization: TextCapitalization.words,
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Enter your barangay'
                          : null,
                    ),
                    SectionHeader('Account Security'),
                    _field(
                      controller: _password,
                      label: 'Password *',
                      helper:
                          'At least 8 characters, with a letter and a '
                          'number.',
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
                        final value = v ?? '';
                        if (value.length < 8 ||
                            !RegExp(r'[A-Za-z]').hasMatch(value) ||
                            !RegExp(r'\d').hasMatch(value)) {
                          return 'Use at least 8 characters, with a letter '
                              'and a number';
                        }
                        return null;
                      },
                    ),
                    _gap,
                    _field(
                      controller: _confirm,
                      label: 'Confirm password *',
                      obscure: _hideConfirm,
                      action: TextInputAction.done,
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
                      validator: (v) =>
                          v != _password.text ? 'Passwords do not match' : null,
                    ),
                    SizedBox(height: 20),
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
                          textStyle: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text('Create Account'),
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
  }

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
                  'I agree to the Terms of Use and Privacy Notice, and I '
                  'allow HABI to use my information to match me with jobs.',
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
