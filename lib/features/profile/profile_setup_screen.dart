import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_background.dart';

import 'package:habi/data/account_store.dart';
import 'package:habi/shared/widgets/form_widgets.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/features/home/home_screen.dart';
import 'package:habi/shared/data/ph_locations.dart';
import 'package:habi/shared/pickers/resume_picker.dart';

const String kPreferNotDisclose = 'Other / Prefer not to disclose';
const List<String> kBeneficiaryCategories = [
  'Person with Disability (PWD)',
  'Solo Parent',
  'Low-Income Job Seeker',
  'Undercredentialed Job Seeker',
  'Displaced Worker',
  kPreferNotDisclose,
];

const String kNoAccommodation = 'No specific accommodation required';
const List<String> kAccessibilityOptions = [
  'Wheelchair-accessible workplace',
  'Screen-reader-compatible tools',
  'Flexible working arrangements',
  'Assistive technology',
  'Modified work schedule',
  'Accessible communication',
  'Other accommodations',
  kNoAccommodation,
  'Prefer to discuss with employer',
];

const List<String> kEducationLevels = [
  'No formal education',
  'Elementary',
  'Junior High School',
  'Senior High School',
  'Vocational / Technical',
  'Some College',
  'College Graduate',
  'Post-graduate',
];

const List<String> kCommonSkills = [
  'Customer Service',
  'Data Entry',
  'Typing',
  'Communication',
  'Computer Skills',
  'Microsoft Office',
  'Bookkeeping',
  'Sales',
  'Graphic Design',
  'Teaching',
  'Caregiving',
  'Cooking',
  'Driving',
  'Sewing',
  'Carpentry',
];

const List<String> kEmploymentTypes = [
  'Full Time',
  'Part Time',
  'One-time task',
  'No preference',
];
const List<String> kWorkArrangements = [
  'On-site',
  'Remote',
  'Hybrid',
  'No preference',
];
const List<String> kDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> kTimesOfDay = [
  'Morning (6 AM - 12 PM)',
  'Afternoon (12 PM - 6 PM)',
  'Evening (6 PM - 12 AM)',
  'Flexible / Any time',
];

/// Profile setup: the extra information used to match jobs and
/// accommodations. Everything here is optional.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    required this.userName,
    this.firstTime = false,
  });

  final String userName;

  /// True right after sign-up. Shows a Skip button and goes to Home.
  final bool firstTime;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  Account? _account;

  Set<String> _beneficiary = {};
  bool _shareBeneficiary = false;
  String? _education;
  Set<String> _skills = {};
  final _skillInput = TextEditingController();
  final _experience = TextEditingController();
  String? _employmentType;
  String? _arrangement;
  final _location = TextEditingController();
  Set<String> _days = {};
  String? _time;
  Set<String> _accessibility = {};
  bool _shareAccessibility = false;
  String _resume = '';

  @override
  void initState() {
    super.initState();
    final a = AccountStore.instance.byDisplayName(widget.userName);
    _account = a;
    if (a == null) return;
    _beneficiary = {...a.beneficiaryCategories};
    _shareBeneficiary = a.shareBeneficiary;
    _education = a.education.isEmpty ? null : a.education;
    _skills = {...a.skills};
    _experience.text = a.workExperience;
    _employmentType = a.employmentType.isEmpty ? null : a.employmentType;
    _arrangement = a.workArrangement.isEmpty ? null : a.workArrangement;
    _location.text = a.preferredLocation;
    _days = {...a.availabilityDays};
    _time = a.availabilityTime.isEmpty ? null : a.availabilityTime;
    _accessibility = {...a.accessibility};
    _shareAccessibility = a.shareAccessibility;
    _resume = a.resumeName;
  }

  @override
  void dispose() {
    _skillInput.dispose();
    _experience.dispose();
    _location.dispose();
    super.dispose();
  }

  List<String> get _skillOptions => [
    ...kCommonSkills,
    ..._skills.where((s) => !kCommonSkills.contains(s)),
  ];

  void _addSkill() {
    final text = _skillInput.text.trim();
    if (text.isEmpty) return;
    final value = text.length > 40 ? text.substring(0, 40) : text;
    String? existing;
    for (final s in _skillOptions) {
      if (s.toLowerCase() == value.toLowerCase()) existing = s;
    }
    setState(() {
      _skills = {..._skills, existing ?? value};
      _skillInput.clear();
    });
  }

  Future<void> _pickLocation() async {
    FocusScope.of(context).unfocus();
    final picked = await showSearchPicker(
      context,
      title: 'Preferred work location',
      options: kPhLocations,
      extras: const ['Anywhere in the Philippines', 'Remote only'],
      selected: _location.text,
    );
    if (picked != null && mounted) {
      setState(() => _location.text = picked);
    }
  }

  Future<void> _pickResume() async {
    final name = await pickResumeFile(context);
    if (name != null && mounted) setState(() => _resume = name);
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(userName: widget.userName)),
      (route) => false,
    );
  }

  Future<void> _save() async {
    final a = _account;
    if (a == null) return;
    a.beneficiaryCategories = {..._beneficiary};
    a.shareBeneficiary = _shareBeneficiary;
    a.education = _education ?? '';
    a.skills = {..._skills};
    a.workExperience = _experience.text.trim();
    a.employmentType = _employmentType ?? '';
    a.workArrangement = _arrangement ?? '';
    a.preferredLocation = _location.text.trim();
    a.availabilityDays = {..._days};
    a.availabilityTime = _time ?? '';
    a.accessibility = {..._accessibility};
    a.shareAccessibility = _shareAccessibility;
    a.resumeName = _resume;
    a.profileDone = true;
    try {
      await AccountStore.instance.saveCurrent();
    } catch (error) {
      if (mounted) {
        showHabiSnack(
          context,
          'Could not save your profile. Please try again.',
        );
      }
      return;
    }

    if (!mounted) return;
    if (widget.firstTime) {
      _goHome();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_account == null) {
      return Scaffold(
        backgroundColor: HabiColors.navy,
        appBar: AppBar(
          backgroundColor: HabiColors.navy,
          foregroundColor: HabiColors.cream,
        ),
        body: Center(
          child: Text(
            'We could not find your account.',
            style: TextStyle(color: HabiColors.cream),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !widget.firstTime,
      child: Scaffold(
        backgroundColor: HabiColors.navy,
        appBar: AppBar(
          backgroundColor: HabiColors.navy,
          foregroundColor: HabiColors.cream,
          elevation: 0,
          automaticallyImplyLeading: !widget.firstTime,
          title: Text(
            widget.firstTime ? 'Set Up Your Profile' : 'My Profile',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            if (widget.firstTime)
              TextButton(
                onPressed: _goHome,
                style: TextButton.styleFrom(foregroundColor: HabiColors.gold),
                child: Text('Skip'),
              ),
            SizedBox(width: 4),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            HabiBackground(),
            SafeArea(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  _buildPrivacyNote(),
                  _buildBeneficiary(),
                  _buildEducation(),
                  _buildSkills(),
                  _buildExperience(),
                  _buildPreferences(),
                  _buildAvailability(),
                  _buildAccessibility(),
                  _buildResume(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          color: HabiColors.ink,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: Color(0xFFE2BB6C),
                        foregroundColor: HabiColors.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(
                        widget.firstTime ? 'Save and Continue' : 'Save Profile',
                      ),
                    ),
                  ),
                  if (widget.firstTime)
                    TextButton(
                      onPressed: _goHome,
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          color: HabiColors.cream.withAlpha(220),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HabiColors.navyMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HabiColors.gold.withAlpha(120)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: HabiColors.gold),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your privacy comes first',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HabiColors.cream,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Everything on this page is optional. You never have to '
                  'share a medical diagnosis, only what you need at work. '
                  'Disability and solo-parent information stays private '
                  'unless you choose to share it.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: HabiColors.cream.withAlpha(220),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiary() {
    final showShare = _beneficiary.any((c) => c != kPreferNotDisclose);
    return HabiCard(
      title: 'Beneficiary category',
      subtitle: 'Choose any that apply to you.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChipMultiSelect(
            options: kBeneficiaryCategories,
            selected: _beneficiary,
            exclusive: const {kPreferNotDisclose},
            onChanged: (v) => setState(() => _beneficiary = v),
          ),
          if (showShare) ...[
            SizedBox(height: 16),
            Divider(height: 1, color: HabiColors.cream.withAlpha(40)),
            SizedBox(height: 12),
            SwitchRow(
              label: 'Share with employers',
              subtitle:
                  'Off by default. This stays private unless you turn '
                  'it on.',
              value: _shareBeneficiary,
              onChanged: (v) => setState(() => _shareBeneficiary = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducation() {
    return HabiCard(
      title: 'Highest educational attainment',
      child: habiDropdown(
        label: 'Education',
        value: _education,
        hint: 'Select',
        items: kEducationLevels,
        onChanged: (v) => setState(() => _education = v),
      ),
    );
  }

  Widget _buildSkills() {
    return HabiCard(
      title: 'Skills and competencies',
      subtitle: 'Tap the ones you have, or add your own.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChipMultiSelect(
            options: _skillOptions,
            selected: _skills,
            onChanged: (v) => setState(() => _skills = v),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillInput,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addSkill(),
                  style: TextStyle(color: HabiColors.cream),
                  cursorColor: HabiColors.gold,
                  decoration: habiDecoration(
                    'Add a skill',
                    hint: 'e.g. Baking',
                  ),
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _addSkill,
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(0xFFE2BB6C),
                    foregroundColor: HabiColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExperience() {
    return HabiCard(
      title: 'Work experience',
      subtitle: 'Optional. Tell us about jobs or tasks you have done.',
      child: TextField(
        controller: _experience,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(color: HabiColors.cream),
        cursorColor: HabiColors.gold,
        decoration: habiDecoration(
          'Experience',
          hint: 'e.g. 2 years as a cashier at a grocery store',
        ),
      ),
    );
  }

  Widget _buildPreferences() {
    return HabiCard(
      title: 'Work preferences',
      child: Column(
        children: [
          habiDropdown(
            label: 'Preferred employment type',
            value: _employmentType,
            hint: 'Select',
            items: kEmploymentTypes,
            onChanged: (v) => setState(() => _employmentType = v),
          ),
          SizedBox(height: 16),
          habiDropdown(
            label: 'Preferred work arrangement',
            value: _arrangement,
            hint: 'Select',
            items: kWorkArrangements,
            onChanged: (v) => setState(() => _arrangement = v),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _location,
            readOnly: true,
            onTap: _pickLocation,
            style: TextStyle(color: HabiColors.cream),
            decoration: habiDecoration(
              'Preferred work location',
              hint: 'Select',
              suffix: Icon(Icons.arrow_drop_down, color: HabiColors.cream),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailability() {
    return HabiCard(
      title: 'Work availability',
      subtitle: 'Which days and times can you work?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChipMultiSelect(
            options: kDays,
            selected: _days,
            onChanged: (v) => setState(() => _days = v),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () =>
                    setState(() => _days = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'}),
                style: TextButton.styleFrom(foregroundColor: HabiColors.gold),
                child: Text('Weekdays'),
              ),
              TextButton(
                onPressed: () => setState(() => _days = {'Sat', 'Sun'}),
                style: TextButton.styleFrom(foregroundColor: HabiColors.gold),
                child: Text('Weekends'),
              ),
              TextButton(
                onPressed: () => setState(() => _days = {...kDays}),
                style: TextButton.styleFrom(foregroundColor: HabiColors.gold),
                child: Text('Every day'),
              ),
            ],
          ),
          SizedBox(height: 8),
          habiDropdown(
            label: 'Time of day',
            value: _time,
            hint: 'Select',
            items: kTimesOfDay,
            onChanged: (v) => setState(() => _time = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibility() {
    final showShare = _accessibility.any((a) => a != kNoAccommodation);
    return HabiCard(
      title: 'Accessibility requirements',
      subtitle:
          'Optional. Only tell us what you need at work. You never '
          'have to share a diagnosis.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChipMultiSelect(
            options: kAccessibilityOptions,
            selected: _accessibility,
            exclusive: const {kNoAccommodation},
            onChanged: (v) => setState(() => _accessibility = v),
          ),
          if (showShare) ...[
            SizedBox(height: 16),
            Divider(height: 1, color: HabiColors.cream.withAlpha(40)),
            SizedBox(height: 12),
            SwitchRow(
              label: 'Share with employers',
              subtitle:
                  'Off by default. Employers only see this if you turn '
                  'it on.',
              value: _shareAccessibility,
              onChanged: (v) => setState(() => _shareAccessibility = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResume() {
    return HabiCard(
      title: 'Resume / CV',
      subtitle: 'Optional. A PDF or Word file.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_resume.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, color: HabiColors.gold),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _resume,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: HabiColors.cream),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove file',
                    onPressed: () => setState(() => _resume = ''),
                    icon: Icon(Icons.close, color: HabiColors.cream),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'No file added yet.',
                style: TextStyle(color: HabiColors.cream.withAlpha(170)),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _pickResume,
            icon: Icon(Icons.upload_file),
            label: Text(_resume.isEmpty ? 'Upload resume' : 'Replace file'),
            style: OutlinedButton.styleFrom(
              foregroundColor: HabiColors.gold,
              side: BorderSide(color: HabiColors.gold),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
