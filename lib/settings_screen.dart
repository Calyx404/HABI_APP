import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'habi_background.dart';

import 'package:image_picker/image_picker.dart';

import 'habi_appearance.dart';
import 'habi_colors.dart';
import 'login_screen.dart';
import 'backend/session_controller.dart';
import 'settings_feature_pages.dart';

/// In-memory settings values for this UI prototype.
/// Replace this with your app's user model or backend when available.
class HabiSettingsData {
  static final account = <String, String>{};
  static final profile = <String, String>{};
  static final beneficiaryCategories = <String>{};
  static final accessibilityNeeds = <String>{};
  static Uint8List? profileImageBytes;
}

/// Shared avatar used by the profile and account settings screens.
class HabiProfileAvatar extends StatelessWidget {
  const HabiProfileAvatar({super.key, required this.size, this.imageBytes});

  final double size;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HabiColors.gold.withAlpha(35),
        border: Border.all(color: HabiColors.gold, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageBytes != null
          ? Image.memory(
              imageBytes!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.person_outline, color: HabiColors.cream, size: 42),
            )
          : Icon(Icons.person_outline, color: HabiColors.cream, size: 42),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.userName});

  final String userName;

  static Route<void> accountSettingsRoute(String userName) =>
      MaterialPageRoute<void>(
        builder: (_) => _AccountSettingsPage(initialName: userName),
      );

  static Route<void> editProfileRoute(String userName) =>
      MaterialPageRoute<void>(
        builder: (_) => _EditProfilePage(userName: userName),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HabiAppearance.instance.isDarkMode
        ? HabiColors.navy
        : Color(0xFFE8D5B9),
    body: Stack(
      fit: StackFit.expand,
      children: [
        HabiBackground(),
        SafeArea(
          child: Column(
            children: [
              _SettingsHeader(
                title: 'Settings',
                onBack: () => Navigator.of(context).pop(),
              ),
              Divider(
                height: 1,
                color: HabiAppearance.instance.isDarkMode
                    ? HabiColors.cream.withAlpha(40)
                    : HabiColors.ink.withAlpha(45),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(18, 16, 18, 24),
                  children: [
                    const _GroupLabel('ACCOUNT'),
                    _SettingRow(
                      icon: Icons.person_outline,
                      title: 'Account Settings',
                      subtitle:
                          'View and update identity, contact and password',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              _AccountSettingsPage(initialName: userName),
                        ),
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Edit Profile',
                      subtitle: 'Update skills, preferences and accessibility',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _EditProfilePage(userName: userName),
                        ),
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.notifications_none,
                      title: 'Notification Settings',
                      subtitle: 'Manage job alerts and updates',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => NotificationSettingsPage(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    const _GroupLabel('PREFERENCES'),
                    _SettingRow(
                      icon: Icons.shield_outlined,
                      title: 'Privacy and Security',
                      subtitle: 'Control your data and account security',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => PrivacySecurityPage(),
                        ),
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'Change app language',
                      trailing: 'English',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => LanguageSettingsPage(),
                        ),
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: 'Switch between beige and blue backgrounds',
                      trailingWidget: const _AppearanceToggle(),
                      onTap: () {},
                    ),
                    SizedBox(height: 16),
                    const _GroupLabel('SUPPORT'),
                    _SettingRow(
                      icon: Icons.help_outline,
                      title: 'Help and Support',
                      subtitle: 'Contact customer support',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => HelpSupportPage(),
                        ),
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.info_outline,
                      title: 'About HABi',
                      subtitle: 'App information and version',
                      trailing: '1.0.0',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => AboutHabiPage(),
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => _confirmLogout(context),
                      icon: Icon(Icons.logout, size: 18),
                      label: Text('Log Out'),
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFFD9363E),
                        minimumSize: Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    SizedBox(height: 22),
                    Center(
                      child: Text(
                        'Signed in as $userName',
                        style: TextStyle(
                          color: HabiAppearance.instance.isDarkMode
                              ? HabiColors.tan
                              : HabiColors.tan.withAlpha(220),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: HabiColors.navyMid,
        title: Text('Log out?', style: TextStyle(color: HabiColors.cream)),
        content: Text(
          'You will return to the HABi login screen.',
          style: TextStyle(color: HabiColors.cream),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: TextStyle(color: HabiColors.cream)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Log Out', style: TextStyle(color: HabiColors.gold)),
          ),
        ],
      ),
    );
    if (shouldLogout == true && context.mounted) {
      await HabiSessionController.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }
}

class _AccountSettingsPage extends StatefulWidget {
  const _AccountSettingsPage({required this.initialName});

  final String initialName;

  @override
  State<_AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<_AccountSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(
    text: HabiSettingsData.account['firstName'] ?? _namePart(0),
  );
  late final _middleName = TextEditingController(
    text: HabiSettingsData.account['middleName'] ?? '',
  );
  late final _lastName = TextEditingController(
    text: HabiSettingsData.account['lastName'] ?? _namePart(1),
  );
  late final _email = TextEditingController(
    text: HabiSettingsData.account['email'] ?? '',
  );
  late final _mobile = TextEditingController(
    text: HabiSettingsData.account['mobile'] ?? '',
  );
  late final _address = TextEditingController(
    text: HabiSettingsData.account['address'] ?? '',
  );
  late final _barangay = TextEditingController(
    text: HabiSettingsData.account['barangay'] ?? '',
  );
  late final _otherLocation = TextEditingController(
    text: HabiSettingsData.account['otherLocation'] ?? '',
  );
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  String? _suffix = HabiSettingsData.account['suffix'];
  String? _sex = HabiSettingsData.account['sex'];
  String? _gender = HabiSettingsData.account['gender'];
  String? _location = HabiSettingsData.account['location'];
  DateTime? _dateOfBirth = DateTime.tryParse(
    HabiSettingsData.account['dateOfBirth'] ?? '',
  );
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  Uint8List? _profileImageBytes = HabiSettingsData.profileImageBytes;
  final ImagePicker _imagePicker = ImagePicker();

  String _namePart(int index) {
    final parts = widget.initialName.trim().split(RegExp(r'\s+'));
    if (widget.initialName.trim().isEmpty || index >= parts.length) return '';
    if (index == 1 && parts.length > 2) return parts.last;
    return parts[index];
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _email.dispose();
    _mobile.dispose();
    _address.dispose();
    _barangay.dispose();
    _otherLocation.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_dateOfBirth == null) {
      _message('Please select your date of birth.');
      return;
    }
    if (_location == 'Other / not listed' &&
        _otherLocation.text.trim().isEmpty) {
      _message('Please enter your province, city, or municipality.');
      return;
    }
    if (_newPassword.text.isNotEmpty || _confirmPassword.text.isNotEmpty) {
      if (_newPassword.text.length < 8) {
        _message('Use at least 8 characters for your new password.');
        return;
      }
      if (_newPassword.text != _confirmPassword.text) {
        _message('The passwords do not match.');
        return;
      }
    }

    HabiSettingsData.account.addAll({
      'firstName': _firstName.text.trim(),
      'middleName': _middleName.text.trim(),
      'lastName': _lastName.text.trim(),
      'suffix': _suffix ?? '',
      'dateOfBirth': _dateOfBirth!.toIso8601String(),
      'sex': _sex ?? '',
      'gender': _gender ?? '',
      'email': _email.text.trim(),
      'mobile': _mobile.text.trim(),
      'address': _address.text.trim(),
      'location': _location ?? '',
      'otherLocation': _otherLocation.text.trim(),
      'barangay': _barangay.text.trim(),
    });
    HabiSettingsData.profileImageBytes = _profileImageBytes;
    _message('Account details updated.');
    Navigator.of(context).pop();
  }

  Future<void> _chooseProfilePicture() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image != null && mounted) {
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _profileImageBytes = bytes);
    }
  }

  void _message(String text) {
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select date of birth',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: HabiColors.gold,
            onPrimary: HabiColors.ink,
            surface: HabiColors.navyMid,
            onSurface: HabiColors.cream,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  String _dateLabel() {
    final date = _dateOfBirth;
    if (date == null) return 'Select date of birth';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;

  InputDecoration _decoration(String label, {String? hint, String? helper}) =>
      _formDecoration(label, hint: hint, helper: helper);

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool obscure = false,
    Widget? suffix,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    validator: validator,
    maxLines: obscure ? 1 : maxLines,
    obscureText: obscure,
    cursorColor: HabiColors.gold,
    style: TextStyle(color: HabiColors.cream),
    decoration: _decoration(label, hint: hint).copyWith(suffixIcon: suffix),
  );

  Widget _dropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    bool required = false,
    String? helper,
  }) => DropdownButtonFormField<String>(
    // Ignore blank or outdated values so Flutter doesn't assert on reopen.
    initialValue: options.contains(value) ? value : null,
    dropdownColor: HabiColors.navyMid,
    style: TextStyle(color: HabiColors.cream),
    decoration: _decoration(label, helper: helper),
    iconEnabledColor: HabiColors.gold,
    items: options
        .map((option) => DropdownMenuItem(value: option, child: Text(option)))
        .toList(),
    onChanged: onChanged,
    validator: required
        ? (selected) => selected == null ? 'Please select $label.' : null
        : null,
  );

  @override
  Widget build(BuildContext context) => _FormShell(
    title: 'Account Settings',
    subtitle: 'View and update your identity, contact and account details.',
    saveLabel: 'Save Account Details',
    onSave: _save,
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FormSection('PROFILE PICTURE'),
          Row(
            children: [
              HabiProfileAvatar(size: 76, imageBytes: _profileImageBytes),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your profile photo',
                      style: TextStyle(
                        color: HabiColors.cream,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      _profileImageBytes == null
                          ? 'Add a photo so employers can recognize you.'
                          : 'You can change or remove this photo anytime.',
                      style: TextStyle(color: HabiColors.tan, fontSize: 11),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: _chooseProfilePicture,
                          icon: Icon(Icons.photo_library_outlined),
                          label: Text(
                            _profileImageBytes == null ? 'Add photo' : 'Change',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: HabiColors.gold,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        if (_profileImageBytes != null)
                          TextButton(
                            onPressed: () =>
                                setState(() => _profileImageBytes = null),
                            style: TextButton.styleFrom(
                              foregroundColor: HabiColors.cream,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text('Remove'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          const _FormSection('PERSONAL INFORMATION'),
          _textField(
            _firstName,
            'First Name',
            validator: (v) => _required(v, 'First name'),
          ),
          SizedBox(height: 12),
          _textField(_middleName, 'Middle Name (optional)'),
          SizedBox(height: 12),
          _textField(
            _lastName,
            'Last Name',
            validator: (v) => _required(v, 'Last name'),
          ),
          SizedBox(height: 12),
          _dropdown('Suffix (optional)', _suffix, const [
            'Jr.',
            'Sr.',
            'II',
            'III',
            'IV',
            'Other',
          ], (v) => setState(() => _suffix = v)),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: Icon(Icons.calendar_month_outlined),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text('Date of Birth  •  ${_dateLabel()}'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: HabiColors.cream,
              side: BorderSide(
                color: _dateOfBirth == null
                    ? HabiColors.cream.withAlpha(70)
                    : HabiColors.gold,
              ),
              minimumSize: Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
          SizedBox(height: 12),
          _dropdown(
            'Sex (for project reporting)',
            _sex,
            const ['Female', 'Male', 'Intersex', 'Prefer not to say'],
            (v) => setState(() => _sex = v),
            required: true,
          ),
          SizedBox(height: 12),
          _dropdown('Gender Identity (optional)', _gender, const [
            'Woman',
            'Man',
            'Non-binary',
            'Prefer to self-describe',
            'Prefer not to say',
          ], (v) => setState(() => _gender = v)),
          SizedBox(height: 20),
          const _FormSection('CONTACT AND ADDRESS'),
          _textField(
            _email,
            'Email Address',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Email address is required.';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return 'Enter a valid email address.';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          _textField(
            _mobile,
            'Mobile Number',
            keyboardType: TextInputType.phone,
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Mobile number is required.';
              if (!RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(value)) {
                return 'Enter a valid mobile number.';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          _textField(
            _address,
            'Complete Address',
            maxLines: 2,
            validator: (v) => _required(v, 'Complete address'),
          ),
          SizedBox(height: 12),
          _dropdown(
            'Province / City / Municipality',
            _location,
            const ['Baguio City', 'La Trinidad, Benguet', 'Other / not listed'],
            (v) => setState(() => _location = v),
            required: true,
            helper:
                'The location options can be replaced with your official list.',
          ),
          if (_location == 'Other / not listed') ...[
            SizedBox(height: 12),
            _textField(
              _otherLocation,
              'Enter Province / City / Municipality',
              validator: (v) => _required(v, 'Location'),
            ),
          ],
          SizedBox(height: 12),
          _textField(
            _barangay,
            'Barangay',
            validator: (v) => _required(v, 'Barangay'),
          ),
          SizedBox(height: 20),
          const _FormSection('PASSWORD'),
          _textField(
            _newPassword,
            'New Password (leave blank to keep current)',
            obscure: _hidePassword,
            validator: (v) => (v == null || v.isEmpty || v.length >= 8)
                ? null
                : 'Use at least 8 characters.',
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
          SizedBox(height: 12),
          _textField(
            _confirmPassword,
            'Confirm New Password',
            obscure: _hideConfirmPassword,
            validator: (v) {
              if (_newPassword.text.isEmpty && (v == null || v.isEmpty)) {
                return null;
              }
              return v == _newPassword.text
                  ? null
                  : 'The passwords do not match.';
            },
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _hideConfirmPassword = !_hideConfirmPassword),
              icon: Icon(
                _hideConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: HabiColors.cream,
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Password fields are optional. Leave them blank to keep your current password.',
            style: TextStyle(color: HabiColors.tan, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _EditProfilePage extends StatefulWidget {
  const _EditProfilePage({required this.userName});

  final String userName;

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  static const _beneficiaryOptions = [
    'Person with Disability (PWD)',
    'Solo Parent',
    'Low-Income Job Seeker',
    'Undercredentialed Job Seeker',
    'Displaced Worker',
    'Other / Prefer not to disclose',
  ];

  static const _accessibilityOptions = [
    'Wheelchair-accessible workplace',
    'Screen-reader-compatible tools',
    'Flexible working arrangements',
    'Assistive technology',
    'Modified work schedule',
    'Accessible communication',
    'Other accommodations',
    'No specific accommodation required',
    'Prefer to discuss with employer',
  ];

  late final _skills = TextEditingController(
    text: HabiSettingsData.profile['skills'] ?? '',
  );
  late final _experience = TextEditingController(
    text: HabiSettingsData.profile['experience'] ?? '',
  );
  late final _preferredLocation = TextEditingController(
    text: HabiSettingsData.profile['preferredLocation'] ?? '',
  );
  late final _resume = TextEditingController(
    text: HabiSettingsData.profile['resume'] ?? '',
  );
  late final _otherAccommodation = TextEditingController(
    text: HabiSettingsData.profile['otherAccommodation'] ?? '',
  );
  final _beneficiaries = <String>{...HabiSettingsData.beneficiaryCategories};
  final _accessNeeds = <String>{...HabiSettingsData.accessibilityNeeds};

  String? _education = HabiSettingsData.profile['education'];
  String? _employmentType = HabiSettingsData.profile['employmentType'];
  String? _workArrangement = HabiSettingsData.profile['workArrangement'];
  String? _availability = HabiSettingsData.profile['availability'];

  @override
  void dispose() {
    _skills.dispose();
    _experience.dispose();
    _preferredLocation.dispose();
    _resume.dispose();
    _otherAccommodation.dispose();
    super.dispose();
  }

  void _save() {
    HabiSettingsData.profile.addAll({
      'education': _education ?? '',
      'skills': _skills.text.trim(),
      'experience': _experience.text.trim(),
      'employmentType': _employmentType ?? '',
      'workArrangement': _workArrangement ?? '',
      'preferredLocation': _preferredLocation.text.trim(),
      'availability': _availability ?? '',
      'resume': _resume.text.trim(),
      'otherAccommodation': _otherAccommodation.text.trim(),
    });
    HabiSettingsData.beneficiaryCategories
      ..clear()
      ..addAll(_beneficiaries);
    HabiSettingsData.accessibilityNeeds
      ..clear()
      ..addAll(_accessNeeds);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Profile details updated.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: HabiColors.navyLight,
        ),
      );
    Navigator.of(context).pop();
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    // Ignore blank or outdated saved values so Flutter doesn't assert on reopen.
    initialValue: options.contains(value) ? value : null,
    dropdownColor: HabiColors.navyMid,
    style: TextStyle(color: HabiColors.cream),
    decoration: _formDecoration(label),
    iconEnabledColor: HabiColors.gold,
    items: options
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: onChanged,
  );

  Widget _multiSelect(
    String title,
    List<String> options,
    Set<String> values,
    ValueChanged<String> onToggle,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FormSection(title),
      Wrap(
        spacing: 7,
        runSpacing: 2,
        children: options.map((item) {
          final selected = values.contains(item);
          return FilterChip(
            label: Text(item),
            selected: selected,
            onSelected: (_) => onToggle(item),
            selectedColor: HabiColors.gold.withAlpha(65),
            checkmarkColor: HabiColors.gold,
            backgroundColor: HabiColors.navyMid,
            side: BorderSide(
              color: selected
                  ? HabiColors.gold
                  : HabiColors.cream.withAlpha(55),
            ),
            labelStyle: TextStyle(
              color: selected ? HabiColors.gold : HabiColors.cream,
              fontSize: 11,
            ),
          );
        }).toList(),
      ),
    ],
  );

  void _toggleAccessibility(String item) {
    const exclusive = {
      'No specific accommodation required',
      'Prefer to discuss with employer',
    };
    setState(() {
      if (_accessNeeds.contains(item)) {
        _accessNeeds.remove(item);
      } else if (exclusive.contains(item)) {
        _accessNeeds
          ..clear()
          ..add(item);
      } else {
        _accessNeeds.removeAll(exclusive);
        _accessNeeds.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) => _FormShell(
    title: 'Edit Profile',
    subtitle:
        'Update the optional details used to match you with suitable work.',
    saveLabel: 'Save Profile',
    onSave: _save,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Profile for ${widget.userName}',
          style: TextStyle(color: HabiColors.gold, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 18),
        _multiSelect(
          'BENEFICIARY CATEGORY (OPTIONAL)',
          _beneficiaryOptions,
          _beneficiaries,
          (item) {
            setState(
              () => _beneficiaries.contains(item)
                  ? _beneficiaries.remove(item)
                  : _beneficiaries.add(item),
            );
          },
        ),
        SizedBox(height: 15),
        _dropdown('Highest Educational Attainment', _education, const [
          'No formal schooling',
          'Elementary',
          'Junior High School',
          'Senior High School',
          'TVET / Certificate',
          'Some College',
          'College Graduate',
          'Postgraduate',
          'Other',
        ], (v) => setState(() => _education = v)),
        SizedBox(height: 12),
        TextFormField(
          controller: _skills,
          maxLines: 3,
          style: TextStyle(color: HabiColors.cream),
          decoration: _formDecoration(
            'Skills and Competencies',
            hint: 'Separate skills with commas',
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _experience,
          maxLines: 4,
          style: TextStyle(color: HabiColors.cream),
          decoration: _formDecoration(
            'Work Experience (optional)',
            hint: 'Roles, employers, and relevant experience',
          ),
        ),
        SizedBox(height: 12),
        _dropdown('Preferred Employment Type', _employmentType, const [
          'Full-time',
          'Part-time',
          'Contract',
          'Temporary',
          'Internship',
          'Any / Flexible',
        ], (v) => setState(() => _employmentType = v)),
        SizedBox(height: 12),
        _dropdown('Preferred Work Arrangement', _workArrangement, const [
          'On-site',
          'Remote',
          'Hybrid',
          'Flexible',
        ], (v) => setState(() => _workArrangement = v)),
        SizedBox(height: 12),
        TextFormField(
          controller: _preferredLocation,
          style: TextStyle(color: HabiColors.cream),
          decoration: _formDecoration(
            'Preferred Work Location',
            hint: 'City, municipality, or preferred area',
          ),
        ),
        SizedBox(height: 12),
        _dropdown('Work Availability', _availability, const [
          'Weekdays',
          'Weekends',
          'Day shift',
          'Evening shift',
          'Night shift',
          'Flexible schedule',
        ], (v) => setState(() => _availability = v)),
        SizedBox(height: 16),
        _multiSelect(
          'ACCESSIBILITY REQUIREMENTS (OPTIONAL)',
          _accessibilityOptions,
          _accessNeeds,
          _toggleAccessibility,
        ),
        if (_accessNeeds.contains('Other accommodations')) ...[
          SizedBox(height: 8),
          TextFormField(
            controller: _otherAccommodation,
            maxLines: 2,
            style: TextStyle(color: HabiColors.cream),
            decoration: _formDecoration('Describe other accommodations'),
          ),
        ],
        SizedBox(height: 18),
        const _FormSection('RESUME / CV'),
        TextFormField(
          controller: _resume,
          style: TextStyle(color: HabiColors.cream),
          decoration: _formDecoration(
            'Resume / CV file name',
            hint: 'Add a file name or link',
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Connect a file picker and storage service to upload a document.',
          style: TextStyle(color: HabiColors.tan, fontSize: 11),
        ),
      ],
    ),
  );
}

class _FormShell extends StatelessWidget {
  const _FormShell({
    required this.title,
    required this.subtitle,
    required this.saveLabel,
    required this.onSave,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String saveLabel;
  final VoidCallback onSave;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HabiColors.navy,
    body: Stack(
      fit: StackFit.expand,
      children: [
        HabiBackground(),
        SafeArea(
          child: Column(
            children: [
              _SettingsHeader(
                title: title,
                onBack: () => Navigator.of(context).pop(),
              ),
              Divider(height: 1, color: HabiColors.cream.withAlpha(40)),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(18, 17, 18, 22),
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(color: HabiColors.tan, height: 1.4),
                    ),
                    SizedBox(height: 17),
                    child,
                    SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: HabiColors.gold,
                          foregroundColor: HabiColors.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(saveLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final foreground = HabiAppearance.instance.isDarkMode
        ? HabiColors.cream
        : HabiColors.ink;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 4, 18, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: foreground),
          ),
          SizedBox(width: 3),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: foreground,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Image.asset('assets/habi_logo.png', width: 32, height: 32),
        ],
      ),
    );
  }
}

InputDecoration _formDecoration(String label, {String? hint, String? helper}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      labelStyle: TextStyle(color: HabiColors.cream.withAlpha(190)),
      hintStyle: TextStyle(color: HabiColors.cream.withAlpha(110)),
      helperStyle: TextStyle(color: HabiColors.tan, fontSize: 10),
      filled: true,
      fillColor: HabiColors.navy.withAlpha(185),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: HabiColors.cream.withAlpha(55)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: HabiColors.cream.withAlpha(55)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: HabiColors.gold),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Color(0xFFE5766B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Color(0xFFE5766B)),
      ),
    );

class _FormSection extends StatelessWidget {
  const _FormSection(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: TextStyle(
        color: HabiAppearance.instance.isDarkMode
            ? HabiColors.gold
            : HabiColors.goldDark,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
    ),
  );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(4, 3, 4, 8),
    child: Text(
      text,
      style: TextStyle(
        color: HabiAppearance.instance.isDarkMode
            ? HabiColors.gold
            : HabiColors.goldDark,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    ),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.trailingWidget,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailing;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    final isDark = HabiAppearance.instance.isDarkMode;
    final foreground = HabiColors.cream;
    final secondary = HabiColors.tan;
    final accent = isDark ? HabiColors.gold : HabiColors.goldDark;
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? HabiColors.navyMid.withAlpha(245) : Color(0xFFF3E4CF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark
              ? HabiColors.cream.withAlpha(38)
              : HabiColors.ink.withAlpha(45),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark
                ? HabiColors.gold.withAlpha(30)
                : HabiColors.ink.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(color: secondary, fontSize: 10),
          ),
        ),
        trailing:
            trailingWidget ??
            (trailing == null
                ? Icon(Icons.chevron_right, color: accent, size: 19)
                : Text(
                    trailing!,
                    style: TextStyle(color: secondary, fontSize: 10),
                  )),
      ),
    );
  }
}

class _AppearanceToggle extends StatefulWidget {
  const _AppearanceToggle();

  @override
  State<_AppearanceToggle> createState() => _AppearanceToggleState();
}

class _AppearanceToggleState extends State<_AppearanceToggle> {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: HabiAppearance.instance,
    builder: (context, _) => Switch.adaptive(
      value: HabiAppearance.instance.isDarkMode,
      activeThumbColor: HabiColors.ink,
      activeTrackColor: HabiColors.gold,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Color(0xFF718096),
      onChanged: HabiAppearance.instance.setDarkMode,
    ),
  );
}
