import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_background.dart';

import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/data/job_store.dart';

const List<String> kExperienceOptions = [
  'No experience needed',
  'Less than 1 year experience',
  '1+ years experience',
  '2+ years experience',
  '3+ years experience',
  '5+ years experience',
];

/// Post a Job form. Pass [job] to edit an existing job instead.
class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key, required this.userName, this.job});

  final String userName;
  final Job? job;

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _pay = TextEditingController();
  final _schedule = TextEditingController();
  final _accessibility = TextEditingController();
  final _requirements = TextEditingController();
  final _description = TextEditingController();
  String _setup = 'On-site';
  String _type = 'Full Time';
  String _experience = kExperienceOptions.first;

  bool get _isEditing => widget.job != null;

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    if (job != null) {
      _title.text = job.title;
      _location.text = job.location == 'Anywhere' ? '' : job.location;
      _pay.text = job.pay;
      _schedule.text = job.workSchedule;
      _accessibility.text = job.accessibility;
      _requirements.text = job.requirements;
      _description.text = job.description;
      _setup = job.setup;
      _type = job.type;
      if (kExperienceOptions.contains(job.experience)) {
        _experience = job.experience;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _pay.dispose();
    _schedule.dispose();
    _accessibility.dispose();
    _requirements.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final location = _location.text.trim();
    final job = Job(
      id: widget.job?.id,
      title: _title.text.trim(),
      setup: _setup,
      type: _type,
      location: location.isEmpty ? 'Anywhere' : location,
      pay: _pay.text.trim(),
      description: _description.text.trim(),
      postedBy: widget.job?.postedBy ?? widget.userName,
      experience: _experience,
      workSchedule: _schedule.text.trim(),
      accessibility: _accessibility.text.trim(),
      requirements: _requirements.text.trim(),
    );
    if (_isEditing) {
      JobStore.instance.update(job);
    } else {
      JobStore.instance.add(job);
    }
    Navigator.of(context).pop(true);
  }

  InputDecoration _dec(String label, {String? hint}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: TextStyle(color: HabiColors.cream.withAlpha(170)),
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

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: HabiColors.navyMid,
      iconEnabledColor: HabiColors.cream,
      style: TextStyle(color: HabiColors.cream, fontSize: 16),
      decoration: _dec(label),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _text({
    required TextEditingController controller,
    required String label,
    String? hint,
    int minLines = 1,
    int maxLines = 1,
    TextCapitalization capitalization = TextCapitalization.sentences,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      textCapitalization: capitalization,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      style: TextStyle(color: HabiColors.cream),
      cursorColor: HabiColors.gold,
      decoration: _dec(label, hint: hint),
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
          _isEditing ? 'Edit Job' : 'Post a Job',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          HabiBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isEditing
                          ? 'Update the details of your job.'
                          : 'Tell people what you need done.',
                      style: TextStyle(
                        fontSize: 14,
                        color: HabiColors.cream.withAlpha(210),
                      ),
                    ),
                    SizedBox(height: 20),
                    _text(
                      controller: _title,
                      label: 'Job title',
                      hint: 'e.g. Administrative Assistant',
                      capitalization: TextCapitalization.words,
                      validator: (v) {
                        if ((v?.trim().length ?? 0) < 3) {
                          return 'Enter a job title';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _dropdown(
                      label: 'Work arrangement',
                      value: _setup,
                      items: const ['On-site', 'Remote', 'Hybrid'],
                      onChanged: (v) => setState(() => _setup = v),
                    ),
                    SizedBox(height: 16),
                    _dropdown(
                      label: 'Job type',
                      value: _type,
                      items: const ['Full Time', 'Part Time', 'One-time task'],
                      onChanged: (v) => setState(() => _type = v),
                    ),
                    SizedBox(height: 16),
                    _dropdown(
                      label: 'Experience required',
                      value: _experience,
                      items: kExperienceOptions,
                      onChanged: (v) => setState(() => _experience = v),
                    ),
                    SizedBox(height: 16),
                    _text(
                      controller: _location,
                      label: 'Location',
                      hint: 'City or area',
                      capitalization: TextCapitalization.words,
                      validator: (v) {
                        if (_setup != 'Remote' && (v?.trim().isEmpty ?? true)) {
                          return 'Enter the location';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _text(
                      controller: _pay,
                      label: 'Pay',
                      hint: 'e.g. \$18,000 - \$25,000',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter the pay';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _text(
                      controller: _schedule,
                      label: 'Work schedule',
                      hint: 'e.g. Mon-Fri, 8:00 AM - 5:00 PM',
                      validator: (v) {
                        if ((v?.trim().length ?? 0) < 3) {
                          return 'Enter the work schedule';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _text(
                      controller: _accessibility,
                      label: 'Accessibility (optional)',
                      hint: 'e.g. Step-free entrance, accessible restrooms',
                      minLines: 2,
                      maxLines: 4,
                    ),
                    SizedBox(height: 16),
                    _text(
                      controller: _requirements,
                      label: 'Requirements (optional)',
                      hint: 'One per line, e.g. Basic computer skills',
                      minLines: 3,
                      maxLines: 6,
                    ),
                    SizedBox(height: 16),
                    _text(
                      controller: _description,
                      label: 'About the job',
                      hint: 'What does the person need to do?',
                      minLines: 4,
                      maxLines: 6,
                      validator: (v) {
                        if ((v?.trim().length ?? 0) < 10) {
                          return 'Add a short description (10+ characters)';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 26),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _submit,
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
                        child: Text(_isEditing ? 'Save Changes' : 'Post Job'),
                      ),
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
}
