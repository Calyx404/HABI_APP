import 'package:flutter/material.dart';

import 'habi_background.dart';

import 'habi_colors.dart';
import 'employer_registration_screen.dart';
import 'registration_screen.dart';

class RegistrationRoleScreen extends StatelessWidget {
  const RegistrationRoleScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: HabiColors.navy,
        appBar: AppBar(
          backgroundColor: HabiColors.navy,
          foregroundColor: HabiColors.cream,
          title: Text('Create Account'),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            HabiBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Join HABi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: HabiColors.cream,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Choose the account that fits what you need to do.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: HabiColors.cream.withAlpha(210)),
                      ),
                      SizedBox(height: 26),
                      _RoleCard(
                        icon: Icons.person_outline,
                        title: 'Job Seeker',
                        description: 'Find opportunities and build your profile.',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RegistrationScreen(),
                          ),
                        ),
                      ),
                      SizedBox(height: 14),
                      _RoleCard(
                        icon: Icons.business_outlined,
                        title: 'Job Employer',
                        description: 'Represent an organization and manage vacancies.',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => EmployerRegistrationScreen(),
                          ),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        color: HabiColors.navyMid.withAlpha(240),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: HabiColors.cream.withAlpha(60)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: HabiColors.gold, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: HabiColors.cream, fontSize: 18, fontWeight: FontWeight.w700)),
                      SizedBox(height: 5),
                      Text(description, style: TextStyle(color: HabiColors.cream.withAlpha(200))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: HabiColors.gold),
              ],
            ),
          ),
        ),
      );
}
