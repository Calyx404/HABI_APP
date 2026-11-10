import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/data/employer_store.dart';
import 'package:habi/backend/auth_service.dart';
import 'package:habi/features/settings/settings_view_model.dart';
import 'package:habi/features/support/support_screen.dart';

/// Shared shell for employer account and preference pages.
class EmployerSettingsScaffold extends StatelessWidget {
  const EmployerSettingsScaffold({
    super.key,
    required this.title,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HabiColors.navy,
    appBar: AppBar(
      backgroundColor: HabiColors.navy,
      foregroundColor: HabiColors.cream,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Image.asset('assets/habi_logo.png', width: 34, height: 34),
        ),
      ],
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/habi_bg.jpg', fit: BoxFit.cover),
        Container(color: HabiColors.navy.withAlpha(225)),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (description != null) ...[
                  Text(
                    description!,
                    style: TextStyle(
                      color: HabiColors.cream.withAlpha(220),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                child,
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmployerPageBits {
  static Widget section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 8),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        color: HabiColors.gold,
        fontSize: 13,
        letterSpacing: 1,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  static InputDecoration input(String hint, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        hintStyle: TextStyle(color: HabiColors.cream.withAlpha(170)),
        filled: true,
        fillColor: HabiColors.navy.withAlpha(190),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: HabiColors.cream.withAlpha(50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: HabiColors.gold),
        ),
      );

  static Widget field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    int maxLines = 1,
    Widget? suffix,
    bool obscureText = false,
    bool readOnly = false,
  }) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    minLines: maxLines > 1 ? maxLines : null,
    maxLines: maxLines,
    obscureText: obscureText,
    readOnly: readOnly,
    style: TextStyle(color: HabiColors.cream, fontSize: 16),
    cursorColor: HabiColors.gold,
    decoration: input(hint, suffix: suffix),
  );

  static Widget select(
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    dropdownColor: HabiColors.navyMid,
    iconEnabledColor: HabiColors.gold,
    style: TextStyle(color: HabiColors.cream, fontSize: 16),
    decoration: input(value),
    items: options
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: onChanged,
  );

  static Widget saveButton(String label, VoidCallback onPressed) => SizedBox(
    height: 54,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: HabiColors.gold,
        foregroundColor: HabiColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      child: Text(label),
    ),
  );

  static void saved(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: HabiColors.navyLight,
        ),
      );
  }
}

class EmployerAccountSettingsScreen extends StatefulWidget {
  const EmployerAccountSettingsScreen({super.key, required this.companyName});
  final String companyName;

  @override
  State<EmployerAccountSettingsScreen> createState() =>
      _EmployerAccountSettingsScreenState();
}

class _EmployerAccountSettingsScreenState
    extends State<EmployerAccountSettingsScreen> {
  late final _company = TextEditingController(text: widget.companyName);
  EmployerAccount? get _account => EmployerStore.instance.current;
  late final _email = TextEditingController(text: _account?.email ?? '');
  late final _first = TextEditingController(
    text: _account?.contactFirstName ?? '',
  );
  late final _last = TextEditingController(
    text: _account?.contactLastName ?? '',
  );
  late final _position = TextEditingController(text: _account?.position ?? '');
  late final _phone = TextEditingController(text: _account?.phone ?? '');
  late final _address = TextEditingController(text: _account?.address ?? '');
  final _organizationOther = TextEditingController();
  final _industryOther = TextEditingController();
  final _cityOther = TextEditingController();
  final _currentPassword = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _organization =
      EmployerStore.instance.current?.organizationType ?? 'Organization Type';
  String _industry = EmployerStore.instance.current?.industry ?? 'Industry';
  String _city = EmployerStore.instance.current?.city ?? 'City / Municipality';
  bool _hidePassword = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    for (final controller in [
      _company,
      _email,
      _first,
      _last,
      _position,
      _phone,
      _address,
      _organizationOther,
      _industryOther,
      _cityOther,
      _currentPassword,
      _password,
      _confirm,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _gap() => const SizedBox(height: 14);

  Future<void> _save() async {
    if (_company.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      _EmployerPageBits.saved(
        context,
        'Enter an organization name and contact number.',
      );
      return;
    }
    if (_password.text.isNotEmpty) {
      if (_password.text.length < 8 || _password.text != _confirm.text) {
        _EmployerPageBits.saved(
          context,
          'Check the new password and confirmation.',
        );
        return;
      }
      if (_currentPassword.text.isEmpty) {
        _EmployerPageBits.saved(context, 'Enter your current password first.');
        return;
      }
      try {
        await HabiAuthService.instance.changePassword(
          currentPassword: _currentPassword.text,
          newPassword: _password.text,
        );
      } catch (_) {
        if (mounted) {
          _EmployerPageBits.saved(
            context,
            'Password was not changed. Check your current password.',
          );
        }
        return;
      }
    }
    try {
      await EmployerStore.instance.saveAccountDetails(
        companyName: _company.text,
        organizationType: _organization == 'Other'
            ? _organizationOther.text
            : _organization,
        industry: _industry == 'Other' ? _industryOther.text : _industry,
        contactFirstName: _first.text,
        contactLastName: _last.text,
        position: _position.text,
        phone: _phone.text,
        address: _address.text,
        city: _city == 'Other' ? _cityOther.text : _city,
      );
      if (!mounted) return;
      _EmployerPageBits.saved(context, 'Account details saved.');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        _EmployerPageBits.saved(
          context,
          'Could not save account details. Check your connection and try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => EmployerSettingsScaffold(
    title: 'Account Settings',
    description:
        'View and update your organization and authorized contact details.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EmployerPageBits.section('Organization Details'),
        _EmployerPageBits.field(_company, 'Company / Organization Name'),
        _gap(),
        _EmployerPageBits.select(_organization, const [
          'Organization Type',
          'Corporation',
          'Partnership',
          'Sole Proprietorship',
          'Non-profit',
          'Government',
          'Private Company',
          'Small and Medium Enterprises',
          'Non Government Organization',
          'Cooperative',
          'Social Enterprise',
          'Other',
        ], (value) => setState(() => _organization = value ?? _organization)),
        if (_organization == 'Other') ...[
          _gap(),
          _EmployerPageBits.field(
            _organizationOther,
            'Specify organization type',
          ),
        ],
        _gap(),
        _EmployerPageBits.select(_industry, const [
          'Industry',
          'Information Technology',
          'Healthcare',
          'Education',
          'Retail and Sales',
          'Manufacturing',
          'Hospitality and Tourism',
          'Finance and Banking',
          'Construction',
          'Agriculture',
          'Transportation and Logistics',
          'Other',
        ], (value) => setState(() => _industry = value ?? _industry)),
        if (_industry == 'Other') ...[
          _gap(),
          _EmployerPageBits.field(_industryOther, 'Specify industry'),
        ],
        _gap(),
        _EmployerPageBits.field(
          _email,
          'Account Email Address',
          readOnly: true,
        ),
        const SizedBox(height: 20),
        _EmployerPageBits.section('Authorized Contact Person'),
        _EmployerPageBits.field(_first, "Contact Person's First Name"),
        _gap(),
        _EmployerPageBits.field(_last, "Contact Person's Last Name"),
        _gap(),
        _EmployerPageBits.field(_position, 'Position / Designation'),
        _gap(),
        _EmployerPageBits.field(
          _phone,
          'Contact Number',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        _EmployerPageBits.section('Company Address'),
        _EmployerPageBits.field(_address, 'Company Address', maxLines: 2),
        _gap(),
        _EmployerPageBits.select(_city, const [
          'City / Municipality',
          'Quezon City',
          'Manila',
          'Makati',
          'Cebu City',
          'Davao City',
          'Other',
        ], (value) => setState(() => _city = value ?? _city)),
        if (_city == 'Other') ...[
          _gap(),
          _EmployerPageBits.field(_cityOther, 'Enter city / municipality'),
        ],
        const SizedBox(height: 20),
        _EmployerPageBits.section('Change Password (Optional)'),
        _EmployerPageBits.field(
          _currentPassword,
          'Current Password',
          obscureText: true,
        ),
        _gap(),
        _EmployerPageBits.field(
          _password,
          'New Password',
          obscureText: _hidePassword,
          suffix: IconButton(
            onPressed: () => setState(() => _hidePassword = !_hidePassword),
            icon: Icon(
              _hidePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: HabiColors.cream,
            ),
          ),
        ),
        _gap(),
        _EmployerPageBits.field(
          _confirm,
          'Confirm New Password',
          obscureText: _hideConfirm,
          suffix: IconButton(
            onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
            icon: Icon(
              _hideConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: HabiColors.cream,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Leave both password fields blank to keep your current password.',
          style: TextStyle(
            color: HabiColors.cream.withAlpha(180),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 22),
        _EmployerPageBits.saveButton('Save Account Details', _save),
      ],
    ),
  );
}

class EmployerProfileEditScreen extends StatefulWidget {
  const EmployerProfileEditScreen({super.key, required this.companyName});
  final String companyName;

  @override
  State<EmployerProfileEditScreen> createState() =>
      _EmployerProfileEditScreenState();
}

class _EmployerProfileEditScreenState extends State<EmployerProfileEditScreen> {
  EmployerAccount? get _account => EmployerStore.instance.current;
  late final _description = TextEditingController(
    text: _account?.description ?? '',
  );
  late final _registrationNumber = TextEditingController(
    text: _account?.businessRegistrationNumber ?? '',
  );
  late final _document = TextEditingController(
    text: _account?.supportingDocumentName ?? '',
  );
  late final _website = TextEditingController(
    text: _account?.employerWebsite ?? '',
  );
  late final _verificationEmail = TextEditingController(
    text: _account?.verificationEmail ?? '',
  );
  String _registrationType =
      EmployerStore.instance.current?.businessRegistrationType ??
      'Business Registration Type';
  Uint8List? _documentBytes;

  @override
  void dispose() {
    _description.dispose();
    _registrationNumber.dispose();
    _document.dispose();
    _website.dispose();
    _verificationEmail.dispose();
    super.dispose();
  }

  Widget _gap() => const SizedBox(height: 14);

  Future<void> _chooseDocument() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final bytes = await file.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        if (mounted) {
          _EmployerPageBits.saved(context, 'Choose a file under 10 MB.');
        }
        return;
      }
      setState(() {
        _documentBytes = bytes;
        _document.text = file.name;
      });
    } catch (_) {
      if (mounted) {
        _EmployerPageBits.saved(context, 'Could not open the file picker.');
      }
    }
  }

  Future<void> _save() async {
    final account = _account;
    if (account == null) {
      _EmployerPageBits.saved(context, 'Employer profile could not be loaded.');
      return;
    }
    try {
      await EmployerStore.instance.updateProfile(
        widget.companyName,
        businessRegistrationType: _registrationType == 'Other'
            ? 'Other'
            : _registrationType,
        businessRegistrationNumber: _registrationNumber.text.trim(),
        supportingDocumentName: _document.text.trim(),
        supportingDocumentBytes: _documentBytes,
        employerWebsite: _website.text.trim(),
        verificationEmail: _verificationEmail.text.trim(),
        profileComplete: true,
      );
      if (!mounted) return;
      _EmployerPageBits.saved(context, 'Employer profile saved.');
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        final storageUnavailable =
            error.toString().contains('bucket') ||
            error.toString().contains('object-not-found');
        _EmployerPageBits.saved(
          context,
          storageUnavailable
              ? 'Profile details could not be saved with the document. Set up Firebase Storage and try again.'
              : 'Could not save employer profile. Check your connection and try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => EmployerSettingsScaffold(
    title: 'Edit Profile',
    description: 'Update the public company profile and verification details.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Employer profile for ${widget.companyName}',
          style: TextStyle(color: HabiColors.gold, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 22),
        _EmployerPageBits.section('Company Description'),
        _EmployerPageBits.field(
          _description,
          'Company Description',
          maxLines: 5,
        ),
        const SizedBox(height: 20),
        _EmployerPageBits.section('Business Verification'),
        _EmployerPageBits.select(
          _registrationType,
          const [
            'Business Registration Type',
            'SEC Registration',
            'DTI Registration',
            'CDA Registration',
            'Government Agency',
            'Other',
          ],
          (value) =>
              setState(() => _registrationType = value ?? _registrationType),
        ),
        _gap(),
        _EmployerPageBits.field(
          _registrationNumber,
          'Business Registration Number',
        ),
        _gap(),
        OutlinedButton.icon(
          onPressed: _chooseDocument,
          icon: Icon(Icons.upload_file_outlined),
          label: Text(
            _document.text.isEmpty
                ? 'Choose supporting document'
                : _document.text,
          ),
          style: OutlinedButton.styleFrom(foregroundColor: HabiColors.gold),
        ),
        const SizedBox(height: 6),
        Text(
          'PDF, PNG or JPG. Maximum size 10 MB.',
          style: TextStyle(
            color: HabiColors.cream.withAlpha(180),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 20),
        _EmployerPageBits.section('Online Presence and Verification'),
        _EmployerPageBits.field(_website, 'Employer Website / Social Media'),
        _gap(),
        _EmployerPageBits.field(
          _verificationEmail,
          'Verification Contact Email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 22),
        _EmployerPageBits.saveButton('Save Employer Profile', _save),
      ],
    ),
  );
}

class EmployerNotificationSettingsScreen extends StatefulWidget {
  const EmployerNotificationSettingsScreen({
    super.key,
    required this.viewModel,
  });

  final SettingsViewModel viewModel;

  @override
  State<EmployerNotificationSettingsScreen> createState() =>
      _EmployerNotificationSettingsScreenState();
}

class _EmployerNotificationSettingsScreenState
    extends State<EmployerNotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  Widget _toggle(String key, String title, String subtitle, IconData icon) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: HabiColors.navyMid,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HabiColors.cream.withAlpha(45)),
        ),
        child: SwitchListTile(
          value: widget.viewModel.value(key),
          onChanged: (value) => widget.viewModel.setValue(key, value),
          activeThumbColor: HabiColors.gold,
          activeTrackColor: HabiColors.goldDark,
          secondary: Icon(icon, color: HabiColors.gold),
          title: Text(
            title,
            style: TextStyle(
              color: HabiColors.cream,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: HabiColors.cream.withAlpha(190),
              fontSize: 12,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) => EmployerSettingsScaffold(
      title: 'Notification Settings',
      description: 'Choose which HABI updates you want to receive.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EmployerPageBits.section('Alerts'),
          _toggle(
            'messages',
            'Messages',
            'New messages from applicants',
            Icons.chat_bubble_outline,
          ),
          _toggle(
            'applicationUpdates',
            'Application Updates',
            'Changes to candidate applications',
            Icons.assignment_outlined,
          ),
          _toggle(
            'trainingReminders',
            'Training Reminders',
            'Course reminders and learning updates',
            Icons.school_outlined,
          ),
          if (widget.viewModel.error != null)
            const Text('Could not save this setting. Check your connection.'),
        ],
      ),
    ),
  );
}

class EmployerHelpScreen extends StatefulWidget {
  const EmployerHelpScreen({super.key, required this.companyName});
  final String companyName;

  @override
  State<EmployerHelpScreen> createState() => _EmployerHelpScreenState();
}

class _EmployerHelpScreenState extends State<EmployerHelpScreen> {
  final _faqs = const [
    (
      'How do I post a job?',
      'Tap the HABI logo in the bottom navigation and complete the job form.',
    ),
    (
      'How can I review applicants?',
      'Open Applicants from the bottom navigation or choose View Applicants on a job posting.',
    ),
    (
      'How do I update my company profile?',
      'Open Profile, then choose Edit in the Company Profile card.',
    ),
  ];

  @override
  Widget build(BuildContext context) => EmployerSettingsScaffold(
    title: 'Help and Support',
    description: 'Find answers or send a message to the HABI team.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EmployerPageBits.section('Common Questions'),
        for (final faq in _faqs)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: HabiColors.navyMid,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HabiColors.cream.withAlpha(45)),
            ),
            child: Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  faq.$1,
                  style: TextStyle(
                    color: HabiColors.cream,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                iconColor: HabiColors.gold,
                collapsedIconColor: HabiColors.gold,
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(
                    faq.$2,
                    style: TextStyle(color: HabiColors.cream.withAlpha(200)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 18),
        _EmployerPageBits.section('Contact Support'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HabiColors.navyMid,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HabiColors.cream.withAlpha(45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Send a request to the HABI support team.',
                style: TextStyle(color: HabiColors.cream),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SupportScreen(userName: widget.companyName),
                  ),
                ),
                icon: Icon(Icons.support_agent),
                label: Text('Open support center'),
                style: FilledButton.styleFrom(
                  backgroundColor: HabiColors.gold,
                  foregroundColor: HabiColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class EmployerAboutScreen extends StatelessWidget {
  const EmployerAboutScreen({super.key});

  @override
  Widget build(BuildContext context) => EmployerSettingsScaffold(
    title: 'About HABI',
    description: 'Every skill has a place.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: HabiColors.navyMid,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: HabiColors.cream.withAlpha(45)),
          ),
          child: Column(
            children: [
              Image.asset('assets/habi_logo.png', width: 82, height: 82),
              const SizedBox(height: 8),
              Text(
                'HABi',
                style: TextStyle(
                  color: HabiColors.cream,
                  fontSize: 32,
                  letterSpacing: 7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connecting skills with meaningful opportunities.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HabiColors.cream.withAlpha(210),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _EmployerPageBits.section('App Information'),
        ListTile(
          title: Text('Version', style: TextStyle(color: HabiColors.cream)),
          trailing: Text(
            '1.0.0',
            style: TextStyle(
              color: HabiColors.cream,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ListTile(
          title: Text('Build', style: TextStyle(color: HabiColors.cream)),
          trailing: Text(
            '1',
            style: TextStyle(
              color: HabiColors.cream,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
