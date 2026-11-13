import 'package:flutter/material.dart';

import '../theme/habi_colors.dart';
import '../theme/habi_design_system.dart';
import 'habi_ui.dart';
import 'habi_notification_button.dart';

class HabiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HabiAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.notificationUserName,
  });
  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final String? notificationUserName;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    leading: leading,
    actions: [
      ...actions,
      if (notificationUserName != null)
        HabiNotificationButton(userName: notificationUserName!),
    ],
    backgroundColor: Theme.of(context).colorScheme.surface,
    foregroundColor: Theme.of(context).colorScheme.onSurface,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: Theme.of(context).textTheme.titleLarge,
  );
}

class HabiSearchBar extends StatelessWidget {
  const HabiSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search HABI',
    this.onChanged,
    this.onSubmitted,
  });
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged, onSubmitted;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    ),
  );
}

class HabiTextField extends StatelessWidget {
  const HabiTextField({
    super.key,
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.validator,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    validator: validator,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      alignLabelWithHint: maxLines > 1,
    ),
  );
}

class HabiPostCard extends StatefulWidget {
  const HabiPostCard({
    super.key,
    required this.author,
    required this.headline,
    required this.body,
    this.skills = const [],
    this.projectTitle,
  });
  final String author, headline, body;
  final List<String> skills;
  final String? projectTitle;
  @override
  State<HabiPostCard> createState() => _HabiPostCardState();
}

class _HabiPostCardState extends State<HabiPostCard> {
  bool liked = false;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HabiSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HabiProfileAvatar(name: widget.author),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.author,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        widget.headline,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz, color: scheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 14),
            Text(widget.body, style: Theme.of(context).textTheme.bodyLarge),
            if (widget.projectTitle != null)
              Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(HabiRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.work_outline, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.projectTitle!,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.skills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: widget.skills
                      .map((s) => HabiFilterChip(label: s))
                      .toList(),
                ),
              ),
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => liked = !liked),
                icon: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? scheme.secondary : null,
                ),
                label: Text(liked ? 'Liked' : 'Like'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HabiJobCard extends StatelessWidget {
  const HabiJobCard({
    super.key,
    required this.title,
    required this.organization,
    required this.details,
    this.onTap,
  });
  final String title, organization, details;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.business_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text('$organization\n$details'),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class HabiPortfolioCard extends StatelessWidget {
  const HabiPortfolioCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.folder_open,
    this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HabiRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 38,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

class HabiAchievementBadge extends StatelessWidget {
  const HabiAchievementBadge({
    super.key,
    required this.title,
    this.icon = Icons.workspace_premium,
  });
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          shape: BoxShape.circle,
          border: Border.all(color: HabiColors.wovenGold, width: 2),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onTertiaryContainer,
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(
        width: 76,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    ],
  );
}

class HabiQuestCard extends StatelessWidget {
  const HabiQuestCard({
    super.key,
    required this.title,
    required this.description,
    required this.progress,
    required this.reward,
  });
  final String title, description, reward;
  final double progress;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                reward,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(description),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ],
      ),
    ),
  );
}

class HabiProfileHeader extends StatelessWidget {
  const HabiProfileHeader({
    super.key,
    required this.name,
    required this.headline,
    required this.level,
    required this.xp,
  });
  final String name, headline;
  final int level, xp;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(HabiRadius.lg),
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),
          HabiProfileAvatar(name: name, size: 84),
          const SizedBox(height: 12),
          Text(
            name,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: scheme.onPrimary),
          ),
          Text(
            headline,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onPrimary.withAlpha(210)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars, color: scheme.onPrimary),
              Text(
                '  Level $level · $xp XP',
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HabiTabBar extends StatelessWidget {
  const HabiTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    this.onSelected,
  });
  final List<String> tabs;
  final int selected;
  final ValueChanged<int>? onSelected;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: List.generate(
      tabs.length,
      (i) => ChoiceChip(
        label: Text(tabs[i]),
        selected: selected == i,
        onSelected: onSelected == null ? null : (_) => onSelected!(i),
        selectedColor: Theme.of(context).colorScheme.secondaryContainer,
        side: BorderSide(
          color: selected == i
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    ),
  );
}

class HabiFilterChip extends StatelessWidget {
  const HabiFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: false,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    selectedColor: Theme.of(context).colorScheme.secondaryContainer,
    side: BorderSide(
      color: selected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.outlineVariant,
    ),
  );
}

class HabiNotificationTile extends StatelessWidget {
  const HabiNotificationTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.notifications_none,
  });
  final String title, subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    ),
    title: Text(title, style: Theme.of(context).textTheme.titleMedium),
    subtitle: Text(subtitle),
  );
}

class HabiLoadingSkeleton extends StatelessWidget {
  const HabiLoadingSkeleton({super.key, this.height = 88});
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(HabiRadius.md),
    ),
  );
}

class HabiErrorState extends StatelessWidget {
  const HabiErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      HabiEmptyState(
        title: 'Something went wrong',
        message: message,
        icon: Icons.cloud_off_outlined,
      ),
      if (onRetry != null)
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
    ],
  );
}

class HabiConfirmationDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirm = 'Continue',
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirm),
            ),
          ],
        ),
      ) ??
      false;
}

class HabiBottomNavigation extends StatelessWidget {
  const HabiBottomNavigation({
    super.key,
    required this.index,
    required this.onSelect,
    required this.onCreate,
    this.unreadCount = 0,
  });
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;
  final int unreadCount;
  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: index,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    onDestinationSelected: (i) {
      if (i == 2) {
        onCreate();
      } else {
        onSelect(i);
      }
    },
    destinations: [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore_rounded),
        label: 'Explore',
      ),
      const NavigationDestination(
        icon: Icon(Icons.add_circle_outline_rounded),
        selectedIcon: Icon(Icons.add_circle_rounded),
        label: 'Create',
      ),
      NavigationDestination(
        icon: _NotificationNavIcon(count: unreadCount),
        selectedIcon: _NotificationNavIcon(count: unreadCount, selected: true),
        label: 'Messages',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ],
  );
}

class _NotificationNavIcon extends StatelessWidget {
  const _NotificationNavIcon({required this.count, this.selected = false});
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) => Badge(
    isLabelVisible: count > 0,
    label: Text(count > 9 ? '9+' : '$count'),
    child: Icon(
      selected ? Icons.chat_rounded : Icons.chat_bubble_outline_rounded,
    ),
  );
}
