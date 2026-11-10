import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_background.dart';

import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/data/account_store.dart';
import 'package:habi/shared/widgets/habi_nav_bar.dart';
import 'package:habi/features/jobs/jobs_screen.dart';
import 'package:habi/features/jobs/my_applications_screen.dart';
import 'package:habi/features/profile/resume_screen.dart';
import 'package:habi/features/settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.userName});

  final String userName;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String get _profileName {
    return AccountStore.instance.current?.displayName ?? widget.userName;
  }

  List<String> get _skills {
    final skills = AccountStore.instance.current?.skills.toList() ?? <String>[];
    skills.sort();
    return skills;
  }

  double get _completion {
    final account = AccountStore.instance.current;
    if (account == null) return 0;
    final checks = [
      account.firstName.isNotEmpty && account.lastName.isNotEmpty,
      account.mobile.isNotEmpty,
      account.cityProvince.isNotEmpty,
      account.education.isNotEmpty,
      account.skills.isNotEmpty,
      account.workExperience.isNotEmpty,
      account.preferredLocation.isNotEmpty,
      account.resumeName.isNotEmpty,
    ];
    return checks.where((done) => done).length / checks.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabiColors.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          HabiBackground(),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header(context)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(18, 8, 18, 24),
                  sliver: SliverList.list(
                    children: [
                      _profileCard(context),
                      SizedBox(height: 14),
                      _skillsCard(context),
                      SizedBox(height: 14),
                      _shortcutsCard(context),
                      SizedBox(height: 14),
                      _growthCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: HabiNavBar(
        userName: widget.userName,
        active: NavTab.profile,
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(18, 8, 16, 4),
    child: Row(
      children: [
        Image.asset('assets/habi_logo.png', width: 36, height: 36),
        SizedBox(width: 9),
        Text(
          'HABI',
          style: TextStyle(
            color: HabiColors.cream,
            fontFamily: 'serif',
            fontSize: 19,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
          ),
        ),
        Spacer(),
        IconButton(
          tooltip: 'Settings',
          onPressed: () => _openSettings(context),
          style: IconButton.styleFrom(
            backgroundColor: HabiColors.navyMid.withAlpha(220),
          ),
          icon: Icon(Icons.settings_outlined, color: HabiColors.gold),
        ),
      ],
    ),
  );

  Widget _profileCard(BuildContext context) => _Panel(
    child: Column(
      children: [
        Row(
          children: [
            HabiProfileAvatar(size: 72),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profileName,
                    style: TextStyle(
                      color: HabiColors.cream,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Job Seeker',
                    style: TextStyle(color: HabiColors.cream, fontSize: 13),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.verified, size: 15, color: HabiColors.gold),
                      SizedBox(width: 5),
                      Text(
                        'Profile ${(_completion * 100).round()}% complete',
                        style: TextStyle(
                          color: HabiColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit profile',
              onPressed: () => _openAccountSettings(context),
              icon: Icon(Icons.edit_outlined, color: HabiColors.gold),
            ),
          ],
        ),
        SizedBox(height: 15),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _completion,
            minHeight: 6,
            color: HabiColors.gold,
            backgroundColor: HabiColors.navyLight,
          ),
        ),
        SizedBox(height: 15),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HabiColors.navy.withAlpha(150),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: HabiColors.gold, size: 19),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Your next opportunity starts with a great profile.',
                  style: TextStyle(color: HabiColors.cream, fontSize: 12),
                ),
              ),
              Icon(Icons.chevron_right, color: HabiColors.gold),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _skillsCard(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Skills',
          action: 'Edit',
          onTap: () => _openEditProfile(context),
        ),
        SizedBox(height: 13),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _skills.map((skill) => _SkillChip(skill)).toList(),
        ),
        SizedBox(height: 13),
        Divider(color: HabiColors.cream.withAlpha(35), height: 1),
        SizedBox(height: 11),
        Row(
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              color: HabiColors.gold,
              size: 17,
            ),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'Add skills to improve your job matches',
                style: TextStyle(color: HabiColors.tan, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _shortcutsCard(BuildContext context) => _Panel(
    padding: EdgeInsets.symmetric(horizontal: 15),
    child: Column(
      children: [
        _ProfileLink(
          icon: Icons.description_outlined,
          title: 'My Applications',
          subtitle: 'Track your application progress',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MyApplicationsScreen(userName: widget.userName),
            ),
          ),
        ),
        _rule(),
        _ProfileLink(
          icon: Icons.bookmark_border,
          title: 'Saved Jobs',
          subtitle: 'Jobs you have bookmarked',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  JobsScreen(userName: widget.userName, initialTab: 2),
            ),
          ),
        ),
        _rule(),
        _ProfileLink(
          icon: Icons.article_outlined,
          title: 'Resume',
          subtitle: 'View or update your resume',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ResumeScreen(userName: widget.userName),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _growthCard() {
    final isDark = HabiColors.isDarkMode;
    final primaryText = isDark ? HabiColors.cream : HabiColors.ink;
    final secondaryText = isDark
        ? HabiColors.tan
        : HabiColors.ink.withAlpha(205);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [Color(0xFF182B58), Color(0xFF1B315E)]
              : [Color(0xFFE8D5B9), Color(0xFFD5E0ED)],
        ),
        border: Border.all(color: HabiColors.gold.withAlpha(110)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep growing!',
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your next opportunity could be just around the corner.',
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.groups, size: 32, color: HabiColors.gold),
        ],
      ),
    );
  }

  Widget _rule() => Divider(color: HabiColors.cream.withAlpha(35), height: 1);

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(userName: widget.userName),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openAccountSettings(BuildContext context) async {
    await Navigator.of(context)
        .push<void>(SettingsScreen.accountSettingsRoute(widget.userName));
    if (mounted) setState(() {});
  }

  Future<void> _openEditProfile(BuildContext context) async {
    await Navigator.of(context)
        .push<void>(SettingsScreen.editProfileRoute(widget.userName));
    if (mounted) setState(() {});
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: HabiColors.navyMid.withAlpha(245),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: HabiColors.cream.withAlpha(45)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(35),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onTap});

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: TextStyle(
          color: HabiColors.cream,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      Spacer(),
      if (action != null)
        InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Text(
                action!,
                style: TextStyle(
                  color: HabiColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.chevron_right, size: 17, color: HabiColors.gold),
            ],
          ),
        ),
    ],
  );
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: HabiColors.navyLight.withAlpha(190),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: HabiColors.gold.withAlpha(85)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: HabiColors.cream,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: HabiColors.gold, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: HabiColors.cream,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: HabiColors.tan, fontSize: 10),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: HabiColors.cream, size: 19),
        ],
      ),
    ),
  );
}
