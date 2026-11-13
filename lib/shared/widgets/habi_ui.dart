import 'package:flutter/material.dart';

import '../theme/habi_design_system.dart';

class HabiProfileAvatar extends StatelessWidget {
  const HabiProfileAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.employer = false,
  });
  final String name;
  final double size;
  final bool employer;
  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: employer ? '$name organization' : '$name profile',
      image: true,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: employer
            ? scheme.secondaryContainer
            : scheme.primaryContainer,
        child: Text(
          initials.isEmpty ? 'H' : initials,
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
            fontSize: size * .32,
          ),
        ),
      ),
    );
  }
}

class HabiPrimaryButton extends StatelessWidget {
  const HabiPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 50,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabiRadius.sm),
        ),
      ),
    ),
  );
}

class HabiSectionHeader extends StatelessWidget {
  const HabiSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class HabiEmptyState extends StatelessWidget {
  const HabiEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.auto_awesome_outlined,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(HabiSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 42, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: HabiSpacing.md),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: HabiSpacing.xs),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}
