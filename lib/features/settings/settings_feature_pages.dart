import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_background.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/features/settings/settings_view_model.dart';
import 'package:habi/features/support/support_screen.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  State<NotificationSettingsPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationSettingsPage> {
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

  Widget toggle(String key, String title, String subtitle, IconData icon) {
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
        value: widget.viewModel.value(key),
        activeThumbColor: HabiColors.gold,
        onChanged: (value) => widget.viewModel.setValue(key, value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) => _Page(
      title: 'Notification Settings',
      subtitle: 'Choose which optional alerts are sent to this device.',
      children: [
        const _Label('ALERTS'),
        toggle(
          'pushEnabled',
          'Push Notifications',
          'Send selected HABI updates to this device',
          Icons.notifications_active_outlined,
        ),
        toggle(
          'jobAlerts',
          'Job Alerts',
          'New jobs matching your preferences',
          Icons.work_outline,
        ),
        toggle(
          'applicationUpdates',
          'Application Updates',
          'Changes to your applications',
          Icons.assignment_outlined,
        ),
        toggle(
          'messages',
          'Messages',
          'New employer and applicant messages',
          Icons.chat_bubble_outline,
        ),
        toggle(
          'trainingReminders',
          'Training Reminders',
          'Course reminders and learning updates',
          Icons.school_outlined,
        ),
        if (widget.viewModel.error != null) _Note(widget.viewModel.error!),
      ],
    ),
  );
}

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  State<PrivacySecurityPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacySecurityPage> {
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) => _Page(
      title: 'Privacy and Security',
      subtitle: 'Choose whether employers can discover your profile.',
      children: [
        const _Label('PROFILE PRIVACY'),
        toggle(
          'Visible to Employers',
          'You can still apply for jobs when your profile is hidden.',
          Icons.visibility_outlined,
          widget.viewModel.profileVisible,
          (value) => widget.viewModel.setProfileVisible(value),
        ),
        const _Note(
          'Beneficiary and accessibility details are shared only when you opt in under Edit Profile.',
        ),
      ],
    ),
  );
}

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key, required this.userName});

  final String userName;

  @override
  State<HelpSupportPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpSupportPage> {
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
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SupportScreen(userName: widget.userName),
            ),
          ),
          icon: Icon(Icons.support_agent),
          label: Text('Open support center'),
          style: FilledButton.styleFrom(
            backgroundColor: HabiColors.gold,
            foregroundColor: HabiColors.ink,
          ),
        ),
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
                      style: TextStyle(color: HabiColors.tan, height: 1.4),
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
      style: TextStyle(color: HabiColors.tan, fontSize: 11, height: 1.4),
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
          style: TextStyle(color: HabiColors.tan, fontSize: 12, height: 1.4),
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
