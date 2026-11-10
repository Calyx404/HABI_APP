import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:habi/features/employer/employer_screen.dart';
import 'package:habi/data/employer_store.dart';
import 'package:habi/shared/widgets/form_widgets.dart';
import 'package:habi/shared/theme/habi_background.dart';
import 'package:habi/shared/theme/habi_colors.dart';

const _businessRegistrationTypes = [
  'Private Company',
  'Small and Medium Enterprise (SME)',
  'Government Agency',
  'Non-Government Organization (NGO)',
  'Cooperative',
  'Social Enterprise',
  'Other',
];

class EmployerProfileSetupScreen extends StatefulWidget {
  const EmployerProfileSetupScreen({
    super.key,
    required this.companyName,
    this.isOnboarding = false,
  });

  final String companyName;
  final bool isOnboarding;

  @override
  State<EmployerProfileSetupScreen> createState() =>
      _EmployerProfileSetupScreenState();
}

class _EmployerProfileSetupScreenState
    extends State<EmployerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registrationNumber = TextEditingController();
  final _website = TextEditingController();
  final _verificationEmail = TextEditingController();
  String? _registrationType;
  String _documentName = '';
  Uint8List? _documentBytes;
  bool _isPicking = false;

  EmployerAccount? get _account =>
      EmployerStore.instance.byCompanyName(widget.companyName);

  @override
  void initState() {
    super.initState();
    final account = _account;
    if (account != null) {
      _registrationNumber.text = account.businessRegistrationNumber ?? '';
      _website.text = account.employerWebsite ?? '';
      _verificationEmail.text = account.verificationEmail ?? '';
      _documentName = account.supportingDocumentName ?? '';
      _documentBytes = account.supportingDocumentBytes;
      if (_businessRegistrationTypes.contains(
        account.businessRegistrationType ?? '',
      )) {
        _registrationType = account.businessRegistrationType;
      }
    }
  }

  @override
  void dispose() {
    _registrationNumber.dispose();
    _website.dispose();
    _verificationEmail.dispose();
    super.dispose();
  }

  Future<void> _chooseDocument() async {
    setState(() => _isPicking = true);
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Choose a supporting business document',
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
        windowsOptions: const WindowsOptions(lockParentWindow: true),
        linuxOptions: const LinuxOptions(lockParentWindow: true),
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        showHabiSnack(
          context,
          'The selected file could not be read. Choose it again.',
        );
        return;
      }
      setState(() {
        _documentName = file.name;
        _documentBytes = bytes;
      });
    } catch (error, stackTrace) {
      debugPrint('Business document picker failed: $error\n$stackTrace');
      if (mounted) {
        showHabiSnack(context, 'Could not open the file picker. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter a verification contact email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _websiteValidator(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    final candidate = raw.contains('://') ? raw : 'https://$raw';
    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
      return 'Enter a valid website or social media URL';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_registrationType == null) {
      showHabiSnack(context, 'Select a business registration type.');
      return;
    }
    try {
      await EmployerStore.instance.updateProfile(
        widget.companyName,
        businessRegistrationType: _registrationType!,
        businessRegistrationNumber: _registrationNumber.text.trim(),
        supportingDocumentName: _documentName,
        supportingDocumentBytes: _documentBytes,
        employerWebsite: _website.text.trim(),
        verificationEmail: _verificationEmail.text.trim(),
        profileComplete: true,
      );
      if (mounted) _finish();
    } catch (error) {
      if (mounted) {
        showHabiSnack(context, 'Could not save your business profile: $error');
      }
    }
  }

  void _skip() => _finish();

  void _finish() {
    if (widget.isOnboarding) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => EmployerScreen(companyName: widget.companyName),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
    String? hint,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    textCapitalization: TextCapitalization.none,
    style: TextStyle(color: HabiColors.cream),
    cursorColor: HabiColors.gold,
    decoration: habiDecoration(label, hint: hint),
    validator: validator,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HabiColors.navy,
    appBar: AppBar(
      backgroundColor: HabiColors.navy,
      foregroundColor: HabiColors.cream,
      title: Text(widget.isOnboarding ? 'Set Up Your Profile' : 'My Profile'),
      actions: [
        if (widget.isOnboarding)
          TextButton(onPressed: _skip, child: Text('Skip')),
      ],
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        HabiBackground(),
        SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HabiColors.navyMid,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: HabiColors.gold.withAlpha(120)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: HabiColors.gold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add the details used to verify ${widget.companyName}. Your information stays with your employer profile.',
                          style: TextStyle(
                            color: HabiColors.cream,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionHeader('Business verification'),
                habiDropdown(
                  label: 'Business Registration Type *',
                  value: _registrationType,
                  items: _businessRegistrationTypes,
                  hint: 'Select',
                  onChanged: (value) =>
                      setState(() => _registrationType = value),
                  validator: (value) =>
                      value == null ? 'Select a registration type' : null,
                ),
                const SizedBox(height: 16),
                _field(
                  _registrationNumber,
                  'Business Registration Number *',
                  hint: 'Enter the registration number',
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Enter the business registration number'
                      : null,
                ),
                const SizedBox(height: 18),
                SectionHeader('Supporting information'),
                OutlinedButton.icon(
                  onPressed: _isPicking ? null : _chooseDocument,
                  icon: _isPicking
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: HabiColors.gold,
                          ),
                        )
                      : Icon(Icons.upload_file_outlined),
                  label: Text(
                    _documentName.isEmpty
                        ? 'Upload Supporting Business Document'
                        : _documentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HabiColors.cream,
                    side: BorderSide(color: HabiColors.cream.withAlpha(90)),
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 16),
                _field(
                  _website,
                  'Employer Website / Social Media',
                  keyboard: TextInputType.url,
                  hint: 'https://example.com',
                  validator: _websiteValidator,
                ),
                const SizedBox(height: 16),
                _field(
                  _verificationEmail,
                  'Verification Contact Email *',
                  keyboard: TextInputType.emailAddress,
                  hint: 'verification@example.com',
                  validator: _emailValidator,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 54,
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: HabiColors.gold,
                  foregroundColor: HabiColors.ink,
                ),
                child: Text(
                  widget.isOnboarding ? 'Save and Continue' : 'Save Profile',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (widget.isOnboarding)
              TextButton(onPressed: _skip, child: Text('Skip for now')),
          ],
        ),
      ),
    ),
  );
}
