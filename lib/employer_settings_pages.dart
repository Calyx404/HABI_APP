import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'habi_colors.dart';
import 'logo_picker.dart';

class EmployerSessionPreferences {
  static final notifications = <String, bool>{
    'Messages': true,
    'Application Updates': true,
    'Training Reminders': false,
    'Email Notifications': true,
    'Push Notifications': true,
  };
  static bool profileVisible = true;
  static bool personalizedMatching = true;
  static bool anonymousUsage = false;
  static String language = 'English';
  static Uint8List? companyLogoBytes;
}

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
  }) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    minLines: maxLines > 1 ? maxLines : null,
    maxLines: maxLines,
    obscureText: obscureText,
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
  final _email = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _position = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _organizationOther = TextEditingController();
  final _industryOther = TextEditingController();
  final _cityOther = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _organization = 'Organization Type';
  String _industry = 'Industry';
  String _city = 'City / Municipality';
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
      _password,
      _confirm,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _gap() => const SizedBox(height: 14);

  Future<void> _chooseLogo() async {
    final bytes = await pickCompanyLogo();
    if (!mounted) return;
    if (bytes == null) {
      _EmployerPageBits.saved(context, 'No logo was selected.');
      return;
    }
    EmployerSessionPreferences.companyLogoBytes = bytes;
    setState(() {});
    _EmployerPageBits.saved(context, 'Company logo updated.');
  }

  @override
  Widget build(BuildContext context) => EmployerSettingsScaffold(
    title: 'Account Settings',
    description:
        'View and update your organization and authorized contact details.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF283652),
                border: Border.all(color: HabiColors.gold, width: 2),
              ),
              child: EmployerSessionPreferences.companyLogoBytes == null
                  ? Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 44,
                    )
                  : ClipOval(
                      child: Image.memory(
                        EmployerSessionPreferences.companyLogoBytes!,
                        fit: BoxFit.cover,
                        width: 94,
                        height: 94,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company logo (optional)',
                    style: TextStyle(
                      color: HabiColors.cream,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Add or change the image shown on your employer profile.',
                    style: TextStyle(
                      color: HabiColors.cream.withAlpha(190),
                      fontSize: 12,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _chooseLogo,
                    icon: Icon(Icons.image_outlined),
                    label: Text('Choose logo'),
                    style: TextButton.styleFrom(
                      foregroundColor: HabiColors.gold,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
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
          'Company Email Address',
          keyboardType: TextInputType.emailAddress,
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
        _EmployerPageBits.saveButton('Save Account Details', () {
          if (_password.text.isNotEmpty && _password.text != _confirm.text) {
            _EmployerPageBits.saved(context, 'The passwords do not match.');
            return;
          }
          _EmployerPageBits.saved(
            context,
            'Account details saved for this session.',
          );
          Navigator.of(context).pop();
        }),
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
  final _description = TextEditingController();
  final _registrationNumber = TextEditingController();
  final _document = TextEditingController();
  final _website = TextEditingController();
  final _verificationEmail = TextEditingController();
  String _registrationType = 'Business Registration Type';

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

  @override
  Widget build(BuildContext context) => EmployerSettingsScaffold(
    title: 'Edit Profile',
    description: 'Update the public company profile and verification details.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Employer profile for ${widget.companyName}',
          style: TextStyle(
            color: HabiColors.gold,
            fontWeight: FontWeight.w700,
          ),
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
        _EmployerPageBits.field(
          _document,
          'Supporting Business Document',
          suffix: IconButton(
            onPressed: () => _EmployerPageBits.saved(
              context,
              'Document upload can be connected to your verification service.',
            ),
            icon: Icon(
              Icons.upload_file_outlined,
              color: HabiColors.gold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Upload storage can be connected to your verification service.',
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
        _EmployerPageBits.saveButton('Save Employer Profile', () {
          _EmployerPageBits.saved(
            context,
            'Employer profile saved for this session.',
          );
          Navigator.of(context).pop();
        }),
      ],
    ),
  );
}

class EmployerNotificationSettingsScreen extends StatefulWidget {
  const EmployerNotificationSettingsScreen({super.key});

  @override
  State<EmployerNotificationSettingsScreen> createState() =>
      _EmployerNotificationSettingsScreenState();
}

class _EmployerNotificationSettingsScreenState
    extends State<EmployerNotificationSettingsScreen> {
  late final Map<String, bool> _values;

  @override
  void initState() {
    super.initState();
    final preferences = EmployerSessionPreferences.notifications;
    final previousJobAlerts = preferences.remove('Job Alerts');
    preferences.putIfAbsent('Messages', () => previousJobAlerts ?? true);
    _values = preferences;
  }

  Widget _toggle(String title, String subtitle, IconData icon) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: HabiColors.navyMid,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HabiColors.cream.withAlpha(45)),
    ),
    child: SwitchListTile(
      value: _values[title]!,
      onChanged: (value) => setState(() => _values[title] = value),
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
        style: TextStyle(color: HabiColors.cream.withAlpha(190), fontSize: 12),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => EmployerSettingsScaffold(
    title: 'Notification Settings',
    description: 'Choose which HABI updates you want to receive.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EmployerPageBits.section('Alerts'),
        _toggle(
          'Messages',
          'New messages from applicants',
          Icons.chat_bubble_outline,
        ),
        _toggle(
          'Application Updates',
          'Changes to candidate applications',
          Icons.assignment_outlined,
        ),
        _toggle(
          'Training Reminders',
          'Course reminders and learning updates',
          Icons.school_outlined,
        ),
        const SizedBox(height: 18),
        _EmployerPageBits.section('Delivery'),
        _toggle(
          'Email Notifications',
          'Send updates to your email address',
          Icons.mail_outline,
        ),
        _toggle(
          'Push Notifications',
          'Show updates on this device',
          Icons.notifications_active_outlined,
        ),
        const SizedBox(height: 6),
        Text(
          'Connect these preferences to your notification service to deliver alerts.',
          style: TextStyle(
            color: HabiColors.cream.withAlpha(180),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class EmployerPrivacySettingsScreen extends StatefulWidget {
  const EmployerPrivacySettingsScreen({super.key});

  @override
  State<EmployerPrivacySettingsScreen> createState() =>
      _EmployerPrivacySettingsScreenState();
}

class _EmployerPrivacySettingsScreenState
    extends State<EmployerPrivacySettingsScreen> {
  bool get _profileVisible => EmployerSessionPreferences.profileVisible;
  bool get _matching => EmployerSessionPreferences.personalizedMatching;
  bool get _analytics => EmployerSessionPreferences.anonymousUsage;

  Widget _toggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: HabiColors.navyMid,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HabiColors.cream.withAlpha(45)),
    ),
    child: SwitchListTile(
      value: value,
      onChanged: onChanged,
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
        style: TextStyle(color: HabiColors.cream.withAlpha(190), fontSize: 12),
      ),
    ),
  );

  Widget _action(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: HabiColors.navyMid,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HabiColors.cream.withAlpha(45)),
    ),
    child: ListTile(
      leading: Icon(icon, color: HabiColors.gold),
      title: Text(
        title,
        style: TextStyle(
          color: HabiColors.cream,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: HabiColors.cream.withAlpha(190), fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: HabiColors.gold),
      onTap: onTap,
    ),
  );

  @override
  Widget build(BuildContext context) => EmployerSettingsScaffold(
    title: 'Privacy and Security',
    description: 'Manage what you share and how your profile is used.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EmployerPageBits.section('Profile Privacy'),
        _toggle(
          'Visible to Job Seekers',
          'Allow job seekers to find your company profile',
          Icons.visibility_outlined,
          _profileVisible,
          (v) => setState(() => EmployerSessionPreferences.profileVisible = v),
        ),
        _toggle(
          'Personalized Candidate Matching',
          'Use your hiring preferences for suggestions',
          Icons.auto_awesome,
          _matching,
          (v) => setState(
            () => EmployerSessionPreferences.personalizedMatching = v,
          ),
        ),
        const SizedBox(height: 18),
        _EmployerPageBits.section('Data'),
        _toggle(
          'Anonymous Usage Data',
          'Help improve HABI with non-identifying activity',
          Icons.insights_outlined,
          _analytics,
          (v) => setState(() => EmployerSessionPreferences.anonymousUsage = v),
        ),
        _action(
          context,
          'Change Password',
          'Update it from Account Settings',
          Icons.password_outlined,
          () => _EmployerPageBits.saved(
            context,
            'Open Account Settings to change your password.',
          ),
        ),
        _action(
          context,
          'Request My Data',
          'Ask for a copy of your account information',
          Icons.download_outlined,
          () => _EmployerPageBits.saved(
            context,
            'Your data request is ready to connect to account storage.',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'These choices stay in memory for this app session until connected to account storage.',
          style: TextStyle(
            color: HabiColors.cream.withAlpha(180),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class EmployerLanguageSettingsScreen extends StatefulWidget {
  const EmployerLanguageSettingsScreen({super.key});

  @override
  State<EmployerLanguageSettingsScreen> createState() =>
      _EmployerLanguageSettingsScreenState();
}

class _EmployerLanguageSettingsScreenState
    extends State<EmployerLanguageSettingsScreen> {
  String _language = EmployerSessionPreferences.language;

  @override
  Widget build(BuildContext context) => EmployerSettingsScaffold(
    title: 'Language',
    description: 'Choose your preferred language for HABI.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EmployerPageBits.section('Available Languages'),
        Container(
          decoration: BoxDecoration(
            color: HabiColors.navyMid,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HabiColors.cream.withAlpha(45)),
          ),
          child: Column(
            children: [
              for (final language in const ['English', 'Filipino', 'Cebuano'])
                ListTile(
                  onTap: () => setState(() {
                    _language = language;
                    EmployerSessionPreferences.language = language;
                  }),
                  leading: Icon(
                    _language == language
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _language == language
                        ? HabiColors.gold
                        : HabiColors.cream,
                  ),
                  title: Text(
                    language,
                    style: TextStyle(color: HabiColors.cream),
                  ),
                  trailing: Icon(Icons.language, color: HabiColors.gold),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your choice is kept for this app session. App translations need to be added separately.',
          style: TextStyle(
            color: HabiColors.cream.withAlpha(180),
            fontSize: 12,
          ),
        ),
      ],
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
  final _message = TextEditingController();
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
  void dispose() {
    _message.dispose();
    super.dispose();
  }

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
                'Describe how we can help.',
                style: TextStyle(color: HabiColors.cream),
              ),
              const SizedBox(height: 12),
              _EmployerPageBits.field(_message, 'Your message', maxLines: 5),
              const SizedBox(height: 12),
              _EmployerPageBits.saveButton('➤  Send Message', () {
                if (_message.text.trim().isEmpty) {
                  _EmployerPageBits.saved(context, 'Enter a message first.');
                  return;
                }
                _EmployerPageBits.saved(
                  context,
                  'Support messaging will be connected to the HABI help desk.',
                );
                _message.clear();
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Connect this form to your support email or help desk to deliver messages.',
          style: TextStyle(
            color: HabiColors.cream.withAlpha(180),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class EmployerAboutScreen extends StatelessWidget {
  const EmployerAboutScreen({super.key});

  Widget _legalRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: HabiColors.navyMid,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HabiColors.cream.withAlpha(45)),
    ),
    child: ListTile(
      leading: Icon(icon, color: HabiColors.gold),
      title: Text(
        title,
        style: TextStyle(
          color: HabiColors.cream,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: HabiColors.cream.withAlpha(190)),
      ),
      trailing: Icon(Icons.chevron_right, color: HabiColors.gold),
      onTap: () => _EmployerPageBits.saved(
        context,
        '$title will be available when the policy content is added.',
      ),
    ),
  );

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
            style: TextStyle(color: HabiColors.cream, fontWeight: FontWeight.w700),
          ),
        ),
        ListTile(
          title: Text('Build', style: TextStyle(color: HabiColors.cream)),
          trailing: Text(
            '1',
            style: TextStyle(color: HabiColors.cream, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        _legalRow(
          context,
          Icons.shield_outlined,
          'Privacy Notice',
          'How account information is handled',
        ),
        _legalRow(
          context,
          Icons.article_outlined,
          'Terms of Use',
          'Guidelines for using HABI',
        ),
      ],
    ),
  );
}
