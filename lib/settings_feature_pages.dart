import 'package:flutter/material.dart';

import 'habi_background.dart';
import 'habi_colors.dart';

/// Preview preferences. Connect these values to your user settings storage.
class HabiSettingsPreferences {
  static bool jobAlerts = true;
  static bool applicationUpdates = true;
  static bool trainingReminders = false;
  static bool emailNotifications = true;
  static bool pushNotifications = true;
  static bool employerProfileVisibility = true;
  static bool personalizedMatching = true;
  static bool usageAnalytics = false;
  static String language = 'English';
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationSettingsPage> {
  Widget toggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return _Card(
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: HabiColors.gold),
        title: Text(
          title,
          style: TextStyle(
            color: HabiColors.cream,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: HabiColors.tan, fontSize: 11),
        ),
        value: value,
        activeThumbColor: HabiColors.gold,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _Page(
        title: 'Notification Settings',
        subtitle: 'Choose which HABi updates you want to receive.',
        children: [
          const _Label('ALERTS'),
          toggle(
            'Job Alerts',
            'New jobs matching your preferences',
            Icons.work_outline,
            HabiSettingsPreferences.jobAlerts,
            (v) => setState(() => HabiSettingsPreferences.jobAlerts = v),
          ),
          toggle(
            'Application Updates',
            'Changes to your applications',
            Icons.assignment_outlined,
            HabiSettingsPreferences.applicationUpdates,
            (v) => setState(
              () => HabiSettingsPreferences.applicationUpdates = v,
            ),
          ),
          toggle(
            'Training Reminders',
            'Course reminders and learning updates',
            Icons.school_outlined,
            HabiSettingsPreferences.trainingReminders,
            (v) => setState(
              () => HabiSettingsPreferences.trainingReminders = v,
            ),
          ),
          SizedBox(height: 16),
          const _Label('DELIVERY'),
          toggle(
            'Email Notifications',
            'Send updates to your email address',
            Icons.email_outlined,
            HabiSettingsPreferences.emailNotifications,
            (v) => setState(
              () => HabiSettingsPreferences.emailNotifications = v,
            ),
          ),
          toggle(
            'Push Notifications',
            'Show updates on this device',
            Icons.notifications_active_outlined,
            HabiSettingsPreferences.pushNotifications,
            (v) => setState(
              () => HabiSettingsPreferences.pushNotifications = v,
            ),
          ),
          const _Note(
            'Connect these preferences to your notification service to deliver alerts.',
          ),
        ],
      );
}

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacySecurityPage> {
  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: HabiColors.navyLight,
      ),
    );
  }

  Widget toggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return _Card(
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: HabiColors.gold),
        title: Text(
          title,
          style: TextStyle(
            color: HabiColors.cream,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: HabiColors.tan, fontSize: 11),
        ),
        value: value,
        activeThumbColor: HabiColors.gold,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _Page(
        title: 'Privacy and Security',
        subtitle: 'Manage what you share and how your profile is used.',
        children: [
          const _Label('PROFILE PRIVACY'),
          toggle(
            'Visible to Employers',
            'Allow employers to find your profile',
            Icons.visibility_outlined,
            HabiSettingsPreferences.employerProfileVisibility,
            (v) => setState(
              () => HabiSettingsPreferences.employerProfileVisibility = v,
            ),
          ),
          toggle(
            'Personalized Job Matching',
            'Use your profile for job suggestions',
            Icons.auto_awesome_outlined,
            HabiSettingsPreferences.personalizedMatching,
            (v) => setState(
              () => HabiSettingsPreferences.personalizedMatching = v,
            ),
          ),
          SizedBox(height: 16),
          const _Label('DATA'),
          toggle(
            'Anonymous Usage Data',
            'Help improve HABi with non-identifying activity',
            Icons.insights_outlined,
            HabiSettingsPreferences.usageAnalytics,
            (v) => setState(() => HabiSettingsPreferences.usageAnalytics = v),
          ),
          SizedBox(height: 12),
          _Action(
            'Change Password',
            'Update it from Account Settings',
            Icons.password_outlined,
            () => message(
              'Open Settings → Account Settings to change your password.',
            ),
          ),
          SizedBox(height: 8),
          _Action(
            'Request My Data',
            'Ask for a copy of your account information',
            Icons.download_outlined,
            () => message(
              'Connect this action to your account data service.',
            ),
          ),
          const _Note(
            'These choices stay in memory for this app session until connected to account storage.',
          ),
        ],
      );
}

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguageSettingsPage> {
  static const languages = ['English', 'Filipino', 'Cebuano'];

  @override
  Widget build(BuildContext context) => _Page(
        title: 'Language',
        subtitle: 'Choose your preferred language for HABi.',
        children: [
          const _Label('AVAILABLE LANGUAGES'),
          _Card(
            child: RadioGroup<String>(
              groupValue: HabiSettingsPreferences.language,
              onChanged: (value) {
                if (value == null) return;
                setState(() => HabiSettingsPreferences.language = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$value selected.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: HabiColors.navyLight,
                  ),
                );
              },
              child: Column(
                children: [
                  for (final language in languages)
                    RadioListTile<String>(
                      value: language,
                      activeColor: HabiColors.gold,
                      secondary: Icon(
                        Icons.language,
                        color: HabiColors.gold,
                      ),
                      title: Text(
                        language,
                        style: TextStyle(color: HabiColors.cream),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const _Note(
            'This saves your choice for the current session. App translations need to be added separately.',
          ),
        ],
      );
}

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpSupportPage> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void send() {
    final text = controller.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text.isEmpty
              ? 'Enter a message first.'
              : 'Connect this form to your support service to send the message.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: HabiColors.navyLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _Page(
        title: 'Help and Support',
        subtitle: 'Find answers or send a message to the HABi team.',
        children: [
          const _Label('COMMON QUESTIONS'),
          const _Faq(
            'How do I apply for a job?',
            'Open a job listing and follow its application instructions. You can review applications from your profile.',
          ),
          const _Faq(
            'How can I update my profile?',
            'Open Settings → Edit Profile to update skills, work preferences, accessibility needs, and resume details.',
          ),
          const _Faq(
            'How do I change account details?',
            'Open Settings → Account Settings to update identity, contact, address, and password details.',
          ),
          SizedBox(height: 16),
          const _Label('CONTACT SUPPORT'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Describe how we can help.',
                  style: TextStyle(color: HabiColors.cream),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  style: TextStyle(color: HabiColors.cream),
                  cursorColor: HabiColors.gold,
                  decoration: _input(
                    'Your message',
                    hint: 'Type your question or feedback…',
                  ),
                ),
                SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: send,
                  icon: Icon(Icons.send_outlined),
                  label: Text('Send Message'),
                  style: FilledButton.styleFrom(
                    backgroundColor: HabiColors.gold,
                    foregroundColor: HabiColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const _Note(
            'Connect this form to your support email or help desk to deliver messages.',
          ),
        ],
      );
}

class AboutHabiPage extends StatelessWidget {
  const AboutHabiPage({super.key});

  void showInfo(BuildContext context, String title, String text) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HabiColors.navyMid,
        title: Text(title, style: TextStyle(color: HabiColors.gold)),
        content: Text(text, style: TextStyle(color: HabiColors.cream)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _Page(
        title: 'About HABi',
        subtitle: 'Every skill has a place.',
        children: [
          _Card(
            child: Column(
              children: [
                Image.asset('assets/habi_logo.png', width: 76, height: 76),
                SizedBox(height: 8),
                Text(
                  'HABi',
                  style: TextStyle(
                    color: HabiColors.cream,
                    fontFamily: 'serif',
                    fontSize: 26,
                    letterSpacing: 5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Connecting skills with meaningful opportunities.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: HabiColors.tan, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          const _Label('APP INFORMATION'),
          const _InfoRow('Version', '1.0.0'),
          const _InfoRow('Build', '1'),
          SizedBox(height: 12),
          _Action(
            'Privacy Notice',
            'How account information is handled',
            Icons.privacy_tip_outlined,
            () => showInfo(
              context,
              'Privacy Notice',
              'Add your organization’s approved privacy notice here.',
            ),
          ),
          SizedBox(height: 8),
          _Action(
            'Terms of Use',
            'Guidelines for using HABi',
            Icons.article_outlined,
            () => showInfo(
              context,
              'Terms of Use',
              'Add your organization’s approved terms of use here.',
            ),
          ),
        ],
      );
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

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
                  _Header(title, () => Navigator.pop(context)),
                  Divider(height: 1, color: HabiColors.cream.withAlpha(40)),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(18, 17, 18, 24),
                      children: [
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: HabiColors.tan,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 16),
                        ...children,
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

class _Header extends StatelessWidget {
  const _Header(this.title, this.back);

  final String title;
  final VoidCallback back;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(10, 4, 18, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: back,
              icon: Icon(Icons.arrow_back, color: HabiColors.cream),
            ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: HabiColors.cream,
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

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: HabiColors.navyMid.withAlpha(245),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HabiColors.cream.withAlpha(38)),
        ),
        child: child,
      );
}

class _Action extends StatelessWidget {
  const _Action(this.title, this.subtitle, this.icon, this.onTap);

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Card(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: onTap,
          leading: Icon(icon, color: HabiColors.gold),
          title: Text(
            title,
            style: TextStyle(
              color: HabiColors.cream,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: HabiColors.tan, fontSize: 11),
          ),
          trailing: Icon(Icons.chevron_right, color: HabiColors.gold),
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Text(
          text,
          style: TextStyle(
            color: HabiColors.gold,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(4, 6, 4, 12),
        child: Text(
          text,
          style: TextStyle(
            color: HabiColors.tan,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      );
}

class _Faq extends StatelessWidget {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) => _Card(
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.only(bottom: 6),
          iconColor: HabiColors.gold,
          collapsedIconColor: HabiColors.gold,
          title: Text(
            question,
            style: TextStyle(
              color: HabiColors.cream,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                color: HabiColors.tan,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: HabiColors.tan)),
            Spacer(),
            Text(
              value,
              style: TextStyle(
                color: HabiColors.cream,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

InputDecoration _input(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: HabiColors.cream.withAlpha(190)),
      hintStyle: TextStyle(color: HabiColors.cream.withAlpha(110)),
      filled: true,
      fillColor: HabiColors.navy.withAlpha(185),
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
    );
