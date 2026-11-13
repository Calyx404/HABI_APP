import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_background.dart';

import 'package:habi/data/account_store.dart';
import 'package:habi/data/repositories/user_settings_repository.dart';
import 'package:habi/shared/theme/habi_appearance.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/backend/logout_flow.dart';
import 'package:habi/backend/auth_service.dart';
import 'package:habi/features/settings/settings_feature_pages.dart';
import 'package:habi/features/settings/seeker_settings_view_model.dart';
import 'package:habi/features/settings/settings_view_model.dart';
import 'package:habi/features/profile/resume_screen.dart';
import 'package:habi/shared/widgets/habi_notification_button.dart';

/// Shared avatar used by the profile and account settings screens.
class HabiProfileAvatar extends StatelessWidget {
  const HabiProfileAvatar({super.key, required this.size});

  final double size;

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
      child: Icon(Icons.person_outline, color: HabiColors.cream, size: 42),
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

  SettingsViewModel _settingsViewModel() => SettingsViewModel(
    repository: FirestoreUserSettingsRepository(),
    userId: AccountStore.instance.current?.uid ?? '',
    accountRepository: AccountStore.instance,
  );

  Future<void> _setAppearance(BuildContext context, bool value) async {
    final previous = HabiAppearance.instance.isDarkMode;
    final viewModel = _settingsViewModel();
    HabiAppearance.instance.setDarkMode(value);
    final saved = await viewModel.setValue('darkMode', value);
    viewModel.dispose();
    if (!saved && context.mounted) {
      HabiAppearance.instance.setDarkMode(previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save appearance preference.')),
      );
    }
  }

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
                          builder: (_) => NotificationSettingsPage(
                            viewModel: _settingsViewModel(),
                          ),
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
                          builder: (_) => PrivacySecurityPage(
                            viewModel: _settingsViewModel(),
                          ),
                        ),
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: 'Switch between beige and blue backgrounds',
                      trailingWidget: _AppearanceToggle(
                        onChanged: (value) => _setAppearance(context, value),
                      ),
                      onTap: () => _setAppearance(
                        context,
                        !HabiAppearance.instance.isDarkMode,
                      ),
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
                          builder: (_) => HelpSupportPage(userName: userName),
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
      await logoutAndReturnToLogin(context);
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
  final _viewModel = SeekerSettingsViewModel(repository: AccountStore.instance);
  Account? get _account => AccountStore.instance.current;
  late final _firstName = TextEditingController(
    text: _account?.firstName ?? _namePart(0),
  );
  late final _middleName = TextEditingController(
    text: _account?.middleName ?? '',
  );
  late final _lastName = TextEditingController(
    text: _account?.lastName ?? _namePart(1),
  );
  late final _email = TextEditingController(text: _account?.email ?? '');
  late final _mobile = TextEditingController(text: _account?.mobile ?? '');
  late final _address = TextEditingController(text: _account?.address ?? '');
  late final _barangay = TextEditingController(text: _account?.barangay ?? '');
  late final _location = TextEditingController(
    text: _account?.cityProvince ?? '',
  );
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  String? _suffix = AccountStore.instance.current?.suffix;
  String? _sex = AccountStore.instance.current?.sex;
  String? _gender = AccountStore.instance.current?.genderIdentity;
  DateTime? _dateOfBirth = AccountStore.instance.current?.birthDate;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

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
    _location.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_dateOfBirth == null) {
      _message('Please select your date of birth.');
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
      if (_currentPassword.text.isEmpty) {
        _message('Enter your current password to change it.');
        return;
      }
      final passwordChanged = await _viewModel.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (!passwordChanged || !mounted) {
        if (mounted) {
          _message(
            'Password was not changed. Check your current password and try again.',
          );
        }
        return;
      }
    }
    final account = _account;
    if (account == null) {
      _message('Your account profile could not be loaded.');
      return;
    }
    account
      ..firstName = _firstName.text.trim()
      ..middleName = _middleName.text.trim()
      ..lastName = _lastName.text.trim()
      ..suffix = _suffix ?? ''
      ..birthDate = _dateOfBirth!
      ..sex = _sex ?? account.sex
      ..genderIdentity = _gender ?? account.genderIdentity
      ..mobile = _mobile.text.trim()
      ..address = _address.text.trim()
      ..cityProvince = _location.text.trim()
      ..barangay = _barangay.text.trim();
    final saved = await _viewModel.saveProfile();
    if (!mounted) return;
    if (!saved) {
      _message('Could not save account details. Try again.');
      return;
    }
    _message('Account details saved.');
    Navigator.of(context).pop();
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
    bool readOnly = false,
    String? helper,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    validator: validator,
    maxLines: obscure ? 1 : maxLines,
    obscureText: obscure,
    readOnly: readOnly,
    cursorColor: HabiColors.gold,
    style: TextStyle(color: HabiColors.cream),
    decoration: _decoration(
      label,
      hint: hint,
      helper: helper,
    ).copyWith(suffixIcon: suffix),
  );

  Widget _dropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    bool required = false,
    String? helper,
  }) {
    final uniqueOptions = options.toSet().toList(growable: false);
    final initialValue =
        uniqueOptions.where((option) => option == value).length == 1
        ? value
        : null;
    return DropdownButtonFormField<String>(
      // Ignore blank, duplicate, or outdated values so Flutter doesn't assert.
      initialValue: initialValue,
      dropdownColor: HabiColors.navyMid,
      style: TextStyle(color: HabiColors.cream),
      decoration: _decoration(label, helper: helper),
      iconEnabledColor: HabiColors.gold,
      items: uniqueOptions
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: onChanged,
      validator: required
          ? (selected) => selected == null ? 'Please select $label.' : null
          : null,
    );
  }

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
          const _FormSection('ACCOUNT EMAIL'),
          _textField(
            _email,
            'Email Address',
            readOnly: true,
            helper: 'Used for sign-in. Contact support to update it.',
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
          _textField(
            _location,
            'Province / City / Municipality',
            validator: (v) => _required(v, 'Location'),
          ),
          SizedBox(height: 12),
          _textField(
            _barangay,
            'Barangay',
            validator: (v) => _required(v, 'Barangay'),
          ),
          SizedBox(height: 20),
          const _FormSection('PASSWORD'),
          _textField(_currentPassword, 'Current Password', obscure: true),
          SizedBox(height: 12),
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
  final _viewModel = SeekerSettingsViewModel(repository: AccountStore.instance);
  Account? get _account => AccountStore.instance.current;
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
    text: _account?.skills.join(', ') ?? '',
  );
  late final _summary = TextEditingController(
    text: _account?.professionalSummary ?? '',
  );
  late final _certifications = TextEditingController(
    text: _account?.certifications.join(', ') ?? '',
  );
  late final _experience = TextEditingController(
    text: _account?.workExperience ?? '',
  );
  late final _preferredLocation = TextEditingController(
    text: _account?.preferredLocation ?? '',
  );
  late final _otherAccommodation = TextEditingController(
    text: _account?.accessibilityDetails ?? '',
  );
  final _beneficiaries = <String>{
    ...?AccountStore.instance.current?.beneficiaryCategories,
  };
  final _accessNeeds = <String>{
    ...?AccountStore.instance.current?.accessibility,
  };

  String? _education = AccountStore.instance.current?.education;
  String? _employmentType = AccountStore.instance.current?.employmentType;
  String? _workArrangement = AccountStore.instance.current?.workArrangement;
  String? _availability = AccountStore.instance.current?.availabilityTime;
  bool _shareBeneficiaries =
      AccountStore.instance.current?.shareBeneficiary ?? false;
  bool _shareAccessibility =
      AccountStore.instance.current?.shareAccessibility ?? false;

  @override
  void dispose() {
    _skills.dispose();
    _summary.dispose();
    _certifications.dispose();
    _experience.dispose();
    _preferredLocation.dispose();
    _otherAccommodation.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final account = _account;
    if (account == null) {
      _showSaved('Your profile could not be loaded.');
      return;
    }
    account
      ..professionalSummary = _summary.text.trim()
      ..education = _education ?? ''
      ..certifications = _certifications.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
      ..skills = _skills.text
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toSet()
      ..workExperience = _experience.text.trim()
      ..employmentType = _employmentType ?? ''
      ..workArrangement = _workArrangement ?? ''
      ..preferredLocation = _preferredLocation.text.trim()
      ..availabilityTime = _availability ?? ''
      ..beneficiaryCategories = {..._beneficiaries}
      ..accessibility = {..._accessNeeds}
      ..accessibilityDetails = _otherAccommodation.text.trim()
      ..shareBeneficiary = _shareBeneficiaries
      ..shareAccessibility = _shareAccessibility;
    final saved = await _viewModel.saveProfile();
    if (!mounted) return;
    if (!saved) {
      _showSaved(
        _viewModel.error == null
            ? 'Could not save profile details. Try again.'
            : firebaseProfileErrorMessage(_viewModel.error!),
      );
      return;
    }
    _showSaved('Profile details saved.');
    Navigator.of(context).pop();
  }

  void _showSaved(String text) {
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

  Widget _dropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    final uniqueOptions = options.toSet().toList(growable: false);
    final initialValue =
        uniqueOptions.where((option) => option == value).length == 1
        ? value
        : null;
    return DropdownButtonFormField<String>(
      // Ignore blank, duplicate, or outdated values so Flutter doesn't assert.
      initialValue: initialValue,
      dropdownColor: HabiColors.navyMid,
      style: TextStyle(color: HabiColors.cream),
      decoration: _formDecoration(label),
      iconEnabledColor: HabiColors.gold,
      items: uniqueOptions
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

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
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Share selected beneficiary categories',
            style: TextStyle(color: HabiColors.cream),
          ),
          subtitle: Text(
            'Employers only see these if you turn this on.',
            style: TextStyle(color: HabiColors.tan, fontSize: 12),
          ),
          value: _shareBeneficiaries,
          activeThumbColor: HabiColors.gold,
          onChanged: (value) => setState(() => _shareBeneficiaries = value),
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
          controller: _summary,
          maxLength: 500,
          maxLines: 3,
          style: TextStyle(color: HabiColors.cream),
          decoration: _formDecoration(
            'Professional Summary (optional)',
            hint: 'A short introduction to your strengths and goals',
          ),
        ),
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
        TextFormField(
          controller: _certifications,
          maxLines: 2,
          style: TextStyle(color: HabiColors.cream),
          decoration: _formDecoration(
            'Certifications and qualifications (optional)',
            hint: 'Separate items with commas',
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
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Share accessibility preferences',
            style: TextStyle(color: HabiColors.cream),
          ),
          subtitle: Text(
            'These details are optional and remain private until shared.',
            style: TextStyle(color: HabiColors.tan, fontSize: 12),
          ),
          value: _shareAccessibility,
          activeThumbColor: HabiColors.gold,
          onChanged: (value) => setState(() => _shareAccessibility = value),
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
        Text(
          _account?.resumeName.isNotEmpty == true
              ? 'Current file: ${_account!.resumeName}'
              : 'No resume uploaded',
          style: TextStyle(color: HabiColors.tan, fontSize: 12),
        ),
        SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ResumeScreen(userName: widget.userName),
            ),
          ),
          icon: Icon(Icons.upload_file_outlined),
          label: Text('Manage resume'),
          style: OutlinedButton.styleFrom(foregroundColor: HabiColors.gold),
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
          HabiNotificationButton(
            userName: AccountStore.instance.current?.displayName ?? '',
          ),
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

class _AppearanceToggle extends StatelessWidget {
  const _AppearanceToggle({required this.onChanged});

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: HabiAppearance.instance,
    builder: (context, _) => Switch.adaptive(
      value: HabiAppearance.instance.isDarkMode,
      activeThumbColor: HabiColors.ink,
      activeTrackColor: HabiColors.gold,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Color(0xFF718096),
      onChanged: onChanged,
    ),
  );
}
