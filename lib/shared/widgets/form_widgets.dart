import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_colors.dart';

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "May 12, 1995".
String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

void showHabiSnack(BuildContext context, String text) {
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

InputDecoration habiDecoration(
  String label, {
  String? hint,
  Widget? suffix,
  String? helper,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: 3,
    errorMaxLines: 3,
    suffixIcon: suffix,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: TextStyle(color: HabiColors.cream.withAlpha(170)),
    floatingLabelStyle: TextStyle(color: HabiColors.gold),
    hintStyle: TextStyle(color: HabiColors.cream.withAlpha(110)),
    helperStyle: TextStyle(color: HabiColors.cream.withAlpha(150)),
    filled: true,
    fillColor: HabiColors.navy.withAlpha(200),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: border(HabiColors.cream.withAlpha(70)),
    focusedBorder: border(HabiColors.gold),
    errorBorder: border(Color(0xFFE5766B)),
    focusedErrorBorder: border(Color(0xFFE5766B)),
  );
}

Widget habiDropdown({
  required String label,
  required String? value,
  required List<String> items,
  required ValueChanged<String> onChanged,
  String? hint,
  String? Function(String?)? validator,
}) {
  final uniqueItems = items.toSet().toList(growable: false);
  final selectedCount = uniqueItems.where((item) => item == value).length;
  return DropdownButtonFormField<String>(
    initialValue: selectedCount == 1 ? value : null,
    isExpanded: true,
    dropdownColor: HabiColors.navyMid,
    iconEnabledColor: HabiColors.cream,
    style: TextStyle(color: HabiColors.cream, fontSize: 16),
    decoration: habiDecoration(label),
    hint: hint == null
        ? null
        : Text(
            hint,
            style: TextStyle(
              color: HabiColors.cream.withAlpha(110),
              fontSize: 16,
            ),
          ),
    validator: validator,
    items: [
      for (final item in uniqueItems)
        DropdownMenuItem(value: item, child: Text(item)),
    ],
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: HabiColors.cream,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: HabiColors.cream.withAlpha(180),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A rounded card with a title, used for each part of the profile setup.
class HabiCard extends StatelessWidget {
  const HabiCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HabiColors.navy.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HabiColors.cream.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: HabiColors.cream,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: HabiColors.cream.withAlpha(180),
                ),
              ),
            ),
          SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: HabiColors.cream,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: HabiColors.cream.withAlpha(170),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? HabiColors.ink
                : HabiColors.cream,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? HabiColors.gold
                : HabiColors.cream.withAlpha(60),
          ),
        ),
      ],
    );
  }
}

/// Tap-to-select chips. Options in [exclusive] clear all the others when
/// chosen, and choosing any other option removes them.
class ChipMultiSelect extends StatelessWidget {
  const ChipMultiSelect({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.exclusive = const {},
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final Set<String> exclusive;

  void _toggle(String option) {
    final next = {...selected};
    if (next.contains(option)) {
      next.remove(option);
    } else if (exclusive.contains(option)) {
      next
        ..clear()
        ..add(option);
    } else {
      next
        ..removeAll(exclusive)
        ..add(option);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(option),
            selected: selected.contains(option),
            onSelected: (_) => _toggle(option),
            showCheckmark: true,
            checkmarkColor: HabiColors.ink,
            selectedColor: HabiColors.gold,
            backgroundColor: HabiColors.navyMid,
            side: BorderSide(color: HabiColors.cream.withAlpha(70)),
            shape: StadiumBorder(),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: selected.contains(option)
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: selected.contains(option)
                  ? HabiColors.ink
                  : HabiColors.cream,
            ),
          ),
      ],
    );
  }
}

/// A searchable list in a bottom sheet. Returns the chosen item.
Future<String?> showSearchPicker(
  BuildContext context, {
  required String title,
  required List<String> options,
  List<String> extras = const [],
  List<String> trailing = const [],
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: HabiColors.navyMid,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _SearchPickerSheet(
      title: title,
      options: options,
      extras: extras,
      trailing: trailing,
      selected: selected,
    ),
  );
}

class _SearchPickerSheet extends StatefulWidget {
  const _SearchPickerSheet({
    required this.title,
    required this.options,
    required this.extras,
    required this.trailing,
    required this.selected,
  });

  final String title;
  final List<String> options;
  final List<String> extras;
  final List<String> trailing;
  final String? selected;

  @override
  State<_SearchPickerSheet> createState() => _SearchPickerSheetState();
}

class _SearchPickerSheetState extends State<_SearchPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final q = _query.trim().toLowerCase();
    final sorted = [...widget.options]..sort();
    final all = [...widget.extras, ...sorted, ...widget.trailing];
    final shown = q.isEmpty
        ? all
        : all.where((o) => o.toLowerCase().contains(q)).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.75,
        child: Column(
          children: [
            SizedBox(height: 8),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: HabiColors.cream.withAlpha(80),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: HabiColors.cream,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: HabiColors.cream),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(color: HabiColors.cream),
                cursorColor: HabiColors.gold,
                decoration: habiDecoration('Search', hint: 'Type to search')
                    .copyWith(
                      prefixIcon: Icon(Icons.search, color: HabiColors.cream),
                    ),
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Text(
                        'No match. Try another spelling.',
                        style: TextStyle(
                          color: HabiColors.cream.withAlpha(180),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final option = shown[i];
                        final isSelected = option == widget.selected;
                        return ListTile(
                          title: Text(
                            option,
                            style: TextStyle(
                              color: isSelected
                                  ? HabiColors.gold
                                  : HabiColors.cream,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check, color: HabiColors.gold)
                              : null,
                          onTap: () => Navigator.of(context).pop(option),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
