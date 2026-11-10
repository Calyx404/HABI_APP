import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_background.dart';

import 'package:habi/data/account_store.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/shared/widgets/habi_nav_bar.dart';
import 'package:habi/features/jobs/job_card.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/features/jobs/jobs_screen.dart';
import 'package:habi/features/jobs/my_applications_screen.dart';
import 'package:habi/features/jobs/my_jobs_screen.dart';
import 'package:habi/data/notification_store.dart';
import 'package:habi/features/notifications/notifications_screen.dart';
import 'package:habi/features/profile/profile_screen.dart';
import 'package:habi/features/profile/profile_setup_screen.dart';
import 'package:habi/features/support/support_screen.dart';

/// Home / Dashboard.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.userName});

  final String userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String get _firstName =>
      AccountStore.instance.byDisplayName(widget.userName)?.firstName ??
      widget.userName;

  String get _initial => _firstName.isEmpty ? 'H' : _firstName[0].toUpperCase();

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

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openProfile() {
    _push(ProfileScreen(userName: widget.userName));
  }

  Future<void> _openProfileSetup() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(userName: widget.userName),
      ),
    );
    if (saved == true && mounted) _message('Profile saved.');
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
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 18),
                  _buildSearchBar(),
                  SizedBox(height: 20),
                  _buildBanner(),
                  SizedBox(height: 22),
                  _buildShortcuts(),
                  SizedBox(height: 24),
                  _buildProfilePrompt(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recommended for You',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: HabiColors.cream,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _push(JobsScreen(userName: widget.userName)),
                        style: TextButton.styleFrom(
                          foregroundColor: HabiColors.gold,
                        ),
                        child: Text('View All'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildRecommended(),
                  SizedBox(height: 20),
                  _buildGrowthCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HabiNavBar(
        userName: widget.userName,
        active: NavTab.home,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting,',
                style: TextStyle(
                  fontSize: 18,
                  color: HabiColors.cream.withAlpha(230),
                ),
              ),
              Text(
                '$_firstName!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: HabiColors.cream,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Discover opportunities that fit you.',
                style: TextStyle(
                  fontSize: 14,
                  color: HabiColors.cream.withAlpha(210),
                ),
              ),
            ],
          ),
        ),
        ListenableBuilder(
          listenable: NotificationStore.instance,
          builder: (context, _) {
            final unread = NotificationStore.instance.unreadCount(
              widget.userName,
            );
            return IconButton(
              tooltip: 'Notifications',
              onPressed: () =>
                  _push(NotificationsScreen(userName: widget.userName)),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_none,
                    color: HabiColors.cream,
                    size: 28,
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: HabiColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: HabiColors.ink, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: EdgeInsets.only(left: 4, top: 4),
          child: Tooltip(
            message: 'Open profile',
            child: InkWell(
              onTap: _openProfile,
              customBorder: CircleBorder(),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: HabiColors.gold,
                child: Text(
                  _initial,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: HabiColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: HabiColors.navy.withAlpha(200),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HabiColors.cream.withAlpha(70)),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: HabiColors.cream),
        cursorColor: HabiColors.gold,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _openJobs(),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search jobs, skills, or companies...',
          hintStyle: TextStyle(
            color: HabiColors.cream.withAlpha(150),
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.search, color: HabiColors.cream),
          suffixIcon: IconButton(
            icon: Icon(Icons.tune, color: HabiColors.cream.withAlpha(200)),
            tooltip: 'Filter jobs',
            onPressed: () => _openJobs(showFilters: true),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _openJobs({bool showFilters = false}) => _push(
    JobsScreen(
      userName: widget.userName,
      initialQuery: _searchController.text,
      showFiltersOnOpen: showFilters,
    ),
  );

  Widget _buildBanner() {
    final isDark = HabiColors.isDarkMode;
    return Container(
      padding: EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HabiColors.gold, width: 3),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(18, 18, 14, 18),
        decoration: BoxDecoration(
          color: HabiColors.navy.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? HabiColors.navyLight.withAlpha(180)
                : HabiColors.gold.withAlpha(110),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your skills are in demand',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: HabiColors.cream,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Administrative roles near you',
                    style: TextStyle(
                      fontSize: 15,
                      color: HabiColors.cream.withAlpha(220),
                    ),
                  ),
                  SizedBox(height: 14),
                  FilledButton(
                    onPressed: () =>
                        _push(JobsScreen(userName: widget.userName)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Color(0xFFE2BB6C),
                      foregroundColor: HabiColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Explore Jobs',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.shopping_basket_outlined,
              size: 84,
              color: HabiColors.gold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthCard() {
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

  Widget _shortcut(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: HabiColors.navy.withAlpha(200),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HabiColors.cream.withAlpha(70)),
              ),
              child: Icon(icon, color: HabiColors.gold, size: 30),
            ),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: 12, color: HabiColors.cream),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcuts() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shortcut(
          Icons.work_outline,
          'Jobs',
          () => _push(MyJobsScreen(userName: widget.userName)),
        ),
        _shortcut(
          Icons.support_agent,
          'Support',
          () => _push(SupportScreen(userName: widget.userName)),
        ),
        _shortcut(
          Icons.description_outlined,
          'My Applications',
          () => _push(MyApplicationsScreen(userName: widget.userName)),
        ),
      ],
    );
  }

  Widget _buildProfilePrompt() {
    return ListenableBuilder(
      listenable: AccountStore.instance,
      builder: (context, _) {
        final account = AccountStore.instance.byDisplayName(widget.userName);
        if (account == null || account.profileDone) {
          return SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HabiColors.navy.withAlpha(200),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HabiColors.gold.withAlpha(140)),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: HabiColors.gold, size: 30),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete your profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: HabiColors.cream,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Add your skills, work preferences and accessibility '
                        'needs.',
                        style: TextStyle(
                          fontSize: 13,
                          color: HabiColors.cream.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                FilledButton(
                  onPressed: _openProfileSetup,
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(0xFFE2BB6C),
                    foregroundColor: HabiColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Start',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommended() {
    return ListenableBuilder(
      listenable: JobStore.instance,
      builder: (context, _) {
        final jobs = JobStore.instance.jobs.take(5).toList();
        if (jobs.isEmpty) return _buildEmpty();
        return Column(
          children: [
            for (final job in jobs)
              JobCard(job: job, userName: widget.userName),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        color: HabiColors.navy.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HabiColors.cream.withAlpha(60)),
      ),
      child: Column(
        children: [
          Icon(Icons.work_outline, color: HabiColors.gold, size: 34),
          SizedBox(height: 10),
          Text(
            'No jobs posted yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: HabiColors.cream,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Jobs that people post will show up here. Tap the round HABI button below to post one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: HabiColors.cream.withAlpha(190),
            ),
          ),
        ],
      ),
    );
  }
}
