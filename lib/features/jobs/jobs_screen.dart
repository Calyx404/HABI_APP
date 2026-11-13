import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_background.dart';

import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/shared/widgets/habi_nav_bar.dart';
import 'package:habi/features/jobs/job_card.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/features/jobs/jobs_view_model.dart';
import 'package:habi/data/account_store.dart';
import 'package:habi/shared/widgets/habi_notification_button.dart';

/// The Jobs tab: every posted job, with Active, Nearby and Saved tabs.
class JobsScreen extends StatefulWidget {
  const JobsScreen({
    super.key,
    required this.userName,
    this.initialTab = 0,
    this.initialQuery = '',
    this.showFiltersOnOpen = false,
  });

  final String userName;
  final int initialTab;
  final String initialQuery;
  final bool showFiltersOnOpen;

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  static const _labels = ['Active', 'Nearby', 'Saved'];
  late final JobsViewModel _viewModel;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _viewModel = JobsViewModel(
      repository: JobStore.instance,
      preferredLocation: AccountStore.instance.current?.preferredLocation ?? '',
    );
    _viewModel.setQuery(widget.initialQuery);
    _searchController = TextEditingController(text: widget.initialQuery);
    final tab = widget.initialTab.clamp(0, _labels.length - 1).toInt();
    _viewModel.setTab(JobsTab.values[tab]);
    if (widget.showFiltersOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFilters());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabiColors.navy,
      appBar: AppBar(
        backgroundColor: HabiColors.navy,
        foregroundColor: HabiColors.cream,
        elevation: 0,
        title: Text('Jobs', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [HabiNotificationButton(userName: widget.userName)],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          HabiBackground(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  _buildSearchField(),
                  SizedBox(height: 12),
                  ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, _) => _buildTabs(),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _viewModel,
                      builder: (context, _) {
                        if (_viewModel.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Loading jobs',
                            ),
                          );
                        }
                        if (_viewModel.loadError != null) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.cloud_off_outlined,
                                    size: 42,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _viewModel.loadError!,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: _viewModel.retryLoad,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Try again'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final jobs = _viewModel.jobs;
                        if (jobs.isEmpty) return _buildEmpty();
                        return ListView.builder(
                          padding: EdgeInsets.only(bottom: 16),
                          itemCount: jobs.length,
                          itemBuilder: (context, i) =>
                              JobCard(job: jobs[i], userName: widget.userName),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HabiNavBar(
        userName: widget.userName,
        active: NavTab.jobs,
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: HabiColors.navy.withAlpha(200),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HabiColors.cream.withAlpha(60)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: _viewModel.tab.index == i,
                label: '${_labels[i]} jobs',
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _viewModel.setTab(JobsTab.values[i]),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _viewModel.tab.index == i
                          ? Color(0xFFE2BB6C)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _labels[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _viewModel.tab.index == i
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _viewModel.tab.index == i
                            ? HabiColors.ink
                            : HabiColors.cream,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final details = _viewModel.locationRequired
        ? (
            'Add your preferred location',
            'Set a preferred location in your profile to find nearby jobs.',
            Icons.location_on_outlined,
          )
        : switch (_viewModel.tab) {
            JobsTab.active => (
              'No matching jobs',
              'Try another search or clear your filters.',
              Icons.work_outline,
            ),
            JobsTab.nearby => (
              'No nearby jobs yet',
              'Try another search or check back for new opportunities.',
              Icons.near_me_outlined,
            ),
            JobsTab.saved => (
              'No saved jobs yet',
              'Tap the bookmark on a job to keep it here.',
              Icons.bookmark_border,
            ),
          };
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(details.$3, color: HabiColors.gold, size: 44),
            SizedBox(height: 12),
            Text(
              details.$1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: HabiColors.cream,
              ),
            ),
            SizedBox(height: 6),
            Text(
              details.$2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: HabiColors.cream.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: _viewModel.setQuery,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: HabiColors.cream),
            cursorColor: HabiColors.gold,
            decoration: InputDecoration(
              hintText: 'Search jobs, skills, or companies',
              hintStyle: TextStyle(color: HabiColors.cream.withAlpha(150)),
              prefixIcon: Icon(Icons.search, color: HabiColors.cream),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        _viewModel.setQuery('');
                      },
                      icon: Icon(Icons.close, color: HabiColors.cream),
                    ),
              filled: true,
              fillColor: HabiColors.navy.withAlpha(200),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: HabiColors.cream.withAlpha(70)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: HabiColors.cream.withAlpha(70)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: HabiColors.gold),
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Filter jobs',
          onPressed: _showFilters,
          icon: Icon(Icons.tune),
        ),
      ],
    ),
  );

  Future<void> _showFilters() async {
    final arrangements =
        JobStore.instance.jobs
            .map((job) => job.setup.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final types =
        JobStore.instance.jobs
            .map((job) => job.type.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    var arrangement = arrangements.contains(_viewModel.arrangement)
        ? _viewModel.arrangement
        : null;
    var type = types.contains(_viewModel.employmentType)
        ? _viewModel.employmentType
        : null;
    final experiences =
        JobStore.instance.jobs
            .map((job) => job.experience.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final schedules =
        JobStore.instance.jobs
            .map((job) => job.workSchedule.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    var experience = experiences.contains(_viewModel.experience)
        ? _viewModel.experience
        : null;
    var schedule = schedules.contains(_viewModel.workSchedule)
        ? _viewModel.workSchedule
        : null;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HabiColors.navyMid,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filter jobs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: arrangement,
                    decoration: InputDecoration(labelText: 'Work arrangement'),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Any'),
                      ),
                      ...arrangements.map(
                        (value) => DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => arrangement = value),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: type,
                    decoration: InputDecoration(labelText: 'Job type'),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Any'),
                      ),
                      ...types.map(
                        (value) => DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value),
                        ),
                      ),
                    ],
                    onChanged: (value) => setModalState(() => type = value),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: experience,
                    decoration: InputDecoration(labelText: 'Experience level'),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Any'),
                      ),
                      ...experiences.map(
                        (value) => DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => experience = value),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: schedule,
                    decoration: InputDecoration(labelText: 'Work schedule'),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Any'),
                      ),
                      ...schedules.map(
                        (value) => DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value),
                        ),
                      ),
                    ],
                    onChanged: (value) => setModalState(() => schedule = value),
                  ),
                  SizedBox(height: 18),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          _viewModel.clearFilters();
                          _searchController.clear();
                          Navigator.pop(context);
                        },
                        child: Text('Clear filters'),
                      ),
                      Spacer(),
                      FilledButton(
                        onPressed: () {
                          _viewModel
                            ..setArrangement(arrangement)
                            ..setEmploymentType(type)
                            ..setExperience(experience)
                            ..setWorkSchedule(schedule);
                          Navigator.pop(context);
                        },
                        child: Text('Show jobs'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
