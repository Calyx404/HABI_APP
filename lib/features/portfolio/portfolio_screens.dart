import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/portfolio_project.dart';
import '../../data/portfolio_repository.dart';
import '../../shared/widgets/habi_notification_button.dart';
import '../../data/message_store.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({
    super.key,
    this.ownerUid,
    this.repository,
    this.userName = '',
  });

  final String? ownerUid;
  final PortfolioRepository? repository;
  final String userName;

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late final PortfolioRepository _repository =
      widget.repository ?? PortfolioRepository();

  @override
  Widget build(BuildContext context) {
    final signedInUid = _repository.currentUid;
    final ownerUid = widget.ownerUid ?? signedInUid;
    final isOwner = ownerUid != null && ownerUid == signedInUid;
    return Scaffold(
      appBar: AppBar(
        title: Text(isOwner ? 'My Portfolio' : 'Portfolio'),
        actions: [
          if (widget.userName.isNotEmpty)
            HabiNotificationButton(userName: widget.userName),
        ],
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Add project'),
            )
          : null,
      body: ownerUid == null
          ? const _PortfolioMessage(
              icon: Icons.lock_outline,
              title: 'Sign in to view a portfolio',
            )
          : StreamBuilder<List<PortfolioProject>>(
              stream: isOwner
                  ? _repository.watchOwnerProjects(ownerUid)
                  : _repository.watchPublishedProjects(ownerUid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _PortfolioMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Portfolio could not be loaded',
                    detail: _errorText(snapshot.error!),
                    action: TextButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final projects = snapshot.data ?? const <PortfolioProject>[];
                if (projects.isEmpty) {
                  return _PortfolioMessage(
                    icon: Icons.work_outline,
                    title: isOwner
                        ? 'Your portfolio is ready to grow'
                        : 'No published projects yet',
                    detail: isOwner
                        ? 'Add a project to document your contribution, skills, and outcomes.'
                        : 'Published projects will appear here when this profile is visible.',
                    action: isOwner
                        ? FilledButton.icon(
                            onPressed: () => _openForm(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add a project'),
                          )
                        : null,
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    mainAxisExtent: 330,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: projects.length,
                  itemBuilder: (context, index) => _PortfolioProjectCard(
                    project: projects[index],
                    isOwner: isOwner,
                    repository: _repository,
                    onOpen: () => Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailsScreen(
                          projectId: projects[index].id,
                          ownerUid: ownerUid,
                          repository: _repository,
                          userName: widget.userName,
                        ),
                      ),
                    ),
                    onChanged: () => setState(() {}),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openForm(
    BuildContext context, [
    PortfolioProject? project,
  ]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PortfolioProjectFormScreen(
          project: project,
          repository: _repository,
        ),
      ),
    );
    if (changed == true && mounted) setState(() {});
  }
}

class _PortfolioProjectCard extends StatelessWidget {
  const _PortfolioProjectCard({
    required this.project,
    required this.isOwner,
    required this.repository,
    required this.onOpen,
    required this.onChanged,
  });

  final PortfolioProject project;
  final bool isOwner;
  final PortfolioRepository repository;
  final VoidCallback onOpen;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PortfolioThumbnail(project: project, height: 132),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (isOwner)
                      PopupMenuButton<String>(
                        tooltip: 'Project actions',
                        onSelected: (action) => _handleAction(context, action),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          if (project.status !=
                              PortfolioProjectStatus.archived) ...[
                            PopupMenuItem(
                              value: 'publish',
                              child: Text(
                                project.isPublished ? 'Unpublish' : 'Publish',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'archive',
                              child: Text('Archive'),
                            ),
                          ],
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                  ],
                ),
                Text(
                  project.category.isEmpty ? project.role : project.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 7),
                Text(
                  project.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: project.skills
                      .take(3)
                      .map(
                        (skill) => Chip(
                          label: Text(skill),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
                Row(
                  children: [
                    Chip(
                      label: Text(_statusLabel(project.status)),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                    const Icon(Icons.open_in_new, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _handleAction(BuildContext context, String action) async {
    try {
      switch (action) {
        case 'edit':
          final edited = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => PortfolioProjectFormScreen(
                project: project,
                repository: repository,
              ),
            ),
          );
          if (edited == true) onChanged();
          return;
        case 'publish':
          await repository.setPublished(
            project.id,
            published: !project.isPublished,
          );
          break;
        case 'archive':
          if (!await _confirm(
            context,
            'Archive this project?',
            'It will no longer appear in published portfolios.',
          )) {
            return;
          }
          await repository.archiveProject(project.id);
          break;
        case 'delete':
          if (!await _confirm(
            context,
            'Delete this project?',
            'This permanently removes the project from Firestore.',
          )) {
            return;
          }
          await repository.deleteProject(project.id);
          break;
      }
      onChanged();
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({
    super.key,
    required this.projectId,
    required this.ownerUid,
    this.userName = '',
    this.repository,
  });

  final String projectId;
  final String ownerUid;
  final String userName;
  final PortfolioRepository? repository;

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  late final PortfolioRepository _repository =
      widget.repository ?? PortfolioRepository();
  late Future<PortfolioProject?> _project = _repository.getProject(
    widget.projectId,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project details'),
        actions: [
          if (widget.userName.isNotEmpty)
            HabiNotificationButton(userName: widget.userName),
        ],
      ),
      body: FutureBuilder<PortfolioProject?>(
        future: _project,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _PortfolioMessage(
              icon: Icons.lock_outline,
              title: 'Project could not be opened',
              detail: _errorText(snapshot.error!),
              action: TextButton(
                onPressed: () => setState(
                  () => _project = _repository.getProject(widget.projectId),
                ),
                child: const Text('Try again'),
              ),
            );
          }
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final project = snapshot.data;
          if (project == null) {
            return const _PortfolioMessage(
              icon: Icons.search_off,
              title: 'Project not found',
              detail: 'This project may have been deleted or is no longer available.',
            );
          }
          final isProjectOwner = _repository.currentUid == project.ownerUid;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            children: [
              _PortfolioThumbnail(project: project, height: 220),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (isProjectOwner)
                    Chip(label: Text(_statusLabel(project.status))),
                ],
              ),
              if (project.category.isNotEmpty || project.role.isNotEmpty)
                Text(
                  [
                    project.category,
                    project.role,
                  ].where((value) => value.isNotEmpty).join(' · '),
                ),
              const SizedBox(height: 10),
              Text(
                project.summary,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(project.description),
              _detailSection(context, 'Skills', project.skills.join(' · ')),
              _detailSection(
                context,
                'Tools and technologies',
                project.technologies.join(' · '),
              ),
              _detailSection(
                context,
                'Responsibilities',
                project.responsibilities,
              ),
              _detailSection(context, 'Outcomes', project.outcomes),
              _detailSection(context, 'What I learned', project.reflection),
              _detailSection(context, 'Timeline', _projectTimeline(project)),
              if (project.demoUrl.isNotEmpty)
                _ExternalProjectLink(
                  label: 'Open project demonstration',
                  url: project.demoUrl,
                ),
              if (project.repositoryUrl.isNotEmpty)
                _ExternalProjectLink(
                  label: 'Open source repository',
                  url: project.repositoryUrl,
                ),
              if (isProjectOwner &&
                  project.status != PortfolioProjectStatus.archived) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => _edit(project),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit project'),
                ),
                FilledButton.tonal(
                  onPressed: () => _changePublication(project),
                  child: Text(
                    project.isPublished ? 'Return to draft' : 'Publish project',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _archive(project),
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archive project'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _detailSection(BuildContext context, String title, String value) =>
      value.trim().isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(value),
            ],
          ),
        );

  Future<void> _edit(PortfolioProject project) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PortfolioProjectFormScreen(
          project: project,
          repository: _repository,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _project = _repository.getProject(widget.projectId));
    }
  }

  Future<void> _changePublication(PortfolioProject project) async {
    try {
      await _repository.setPublished(
        project.id,
        published: !project.isPublished,
      );
      if (mounted) {
        setState(() => _project = _repository.getProject(widget.projectId));
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  Future<void> _archive(PortfolioProject project) async {
    if (!await _confirm(
      context,
      'Archive this project?',
      'It will no longer appear in published portfolios.',
    )) {
      return;
    }
    try {
      await _repository.archiveProject(project.id);
      if (mounted) {
        setState(() => _project = _repository.getProject(widget.projectId));
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }
}

class PortfolioProjectFormScreen extends StatefulWidget {
  const PortfolioProjectFormScreen({super.key, this.project, this.repository});

  final PortfolioProject? project;
  final PortfolioRepository? repository;

  @override
  State<PortfolioProjectFormScreen> createState() =>
      _PortfolioProjectFormScreenState();
}

class _PortfolioProjectFormScreenState
    extends State<PortfolioProjectFormScreen> {
  final _form = GlobalKey<FormState>();
  late final PortfolioRepository _repository =
      widget.repository ?? PortfolioRepository();
  late final Map<String, TextEditingController> _fields = {
    'title': TextEditingController(text: widget.project?.title ?? ''),
    'summary': TextEditingController(text: widget.project?.summary ?? ''),
    'description': TextEditingController(
      text: widget.project?.description ?? '',
    ),
    'category': TextEditingController(text: widget.project?.category ?? ''),
    'role': TextEditingController(text: widget.project?.role ?? ''),
    'skills': TextEditingController(
      text: widget.project?.skills.join(', ') ?? '',
    ),
    'technologies': TextEditingController(
      text: widget.project?.technologies.join(', ') ?? '',
    ),
    'responsibilities': TextEditingController(
      text: widget.project?.responsibilities ?? '',
    ),
    'outcomes': TextEditingController(text: widget.project?.outcomes ?? ''),
    'reflection': TextEditingController(text: widget.project?.reflection ?? ''),
    'demoUrl': TextEditingController(text: widget.project?.demoUrl ?? ''),
    'repositoryUrl': TextEditingController(
      text: widget.project?.repositoryUrl ?? '',
    ),
    'thumbnailUrl': TextEditingController(
      text: widget.project?.thumbnailUrl ?? '',
    ),
    'thumbnailAltText': TextEditingController(
      text: widget.project?.thumbnailAltText ?? '',
    ),
  };
  late DateTime _startedAt = widget.project?.startedAt ?? DateTime.now();
  late DateTime? _endedAt = widget.project?.endedAt;
  late bool _ongoing = widget.project?.ongoing ?? true;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _value(String field) => _fields[field]!.text.trim();

  PortfolioProject _makeProject(PortfolioProjectStatus status) =>
      PortfolioProject(
        id: widget.project?.id ?? '',
        ownerUid: widget.project?.ownerUid ?? _repository.currentUid ?? '',
        title: _value('title'),
        summary: _value('summary'),
        description: _value('description'),
        category: _value('category'),
        role: _value('role'),
        skills: _splitValues(_value('skills')),
        technologies: _splitValues(_value('technologies')),
        responsibilities: _value('responsibilities'),
        outcomes: _value('outcomes'),
        reflection: _value('reflection'),
        startedAt: _startedAt,
        endedAt: _ongoing ? null : _endedAt,
        ongoing: _ongoing,
        demoUrl: _value('demoUrl'),
        repositoryUrl: _value('repositoryUrl'),
        thumbnailUrl: _value('thumbnailUrl'),
        thumbnailAltText: _value('thumbnailAltText'),
        status: status,
        createdAt: widget.project?.createdAt,
        updatedAt: widget.project?.updatedAt,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.project == null ? 'Add project' : 'Edit project'),
      actions: [
        HabiNotificationButton(userName: MessageStore.instance.currentUserName),
      ],
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          _textField('title', 'Project title', required: true, maxLength: 120),
          _textField(
            'summary',
            'Short summary',
            required: true,
            maxLength: 500,
            maxLines: 2,
          ),
          _textField(
            'description',
            'Project description',
            required: true,
            maxLength: 10000,
            maxLines: 5,
          ),
          _textField('category', 'Category', maxLength: 100),
          _textField('role', 'Your role', maxLength: 120),
          _textField(
            'skills',
            'Skills demonstrated',
            hint: 'Separate items with commas',
            maxLength: 1000,
          ),
          _textField(
            'technologies',
            'Tools and technologies',
            hint: 'Separate items with commas',
            maxLength: 1000,
          ),
          _textField(
            'responsibilities',
            'Responsibilities',
            maxLength: 2000,
            maxLines: 3,
          ),
          _textField(
            'outcomes',
            'Outcomes and accomplishments',
            maxLength: 2000,
            maxLines: 3,
          ),
          _textField(
            'reflection',
            'Learning reflection',
            maxLength: 2000,
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Start date'),
            subtitle: Text(_dateLabel(_startedAt)),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: _pickStartDate,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('This project is ongoing'),
            value: _ongoing,
            onChanged: (value) => setState(() {
              _ongoing = value;
              if (value) _endedAt = null;
            }),
          ),
          if (!_ongoing)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End date'),
              subtitle: Text(
                _endedAt == null ? 'Select an end date' : _dateLabel(_endedAt!),
              ),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _pickEndDate,
            ),
          _textField(
            'demoUrl',
            'Project demonstration URL',
            hint: 'https://…',
            maxLength: 2048,
            validator: _urlValidator,
          ),
          _textField(
            'repositoryUrl',
            'Source code URL',
            hint: 'https://…',
            maxLength: 2048,
            validator: _urlValidator,
          ),
          _textField(
            'thumbnailUrl',
            'External thumbnail URL',
            hint: 'https://…',
            maxLength: 2048,
            validator: _urlValidator,
          ),
          _textField(
            'thumbnailAltText',
            'Thumbnail description',
            maxLength: 200,
          ),
          const SizedBox(height: 18),
          if (widget.project == null) ...[
            OutlinedButton(
              onPressed: _saving
                  ? null
                  : () => _save(PortfolioProjectStatus.draft),
              child: const Text('Save as draft'),
            ),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () => _save(PortfolioProjectStatus.published),
              child: const Text('Publish project'),
            ),
          ] else ...[
            FilledButton(
              onPressed: _saving ? null : () => _save(widget.project!.status),
              child: const Text('Save changes'),
            ),
            if (widget.project!.status != PortfolioProjectStatus.archived)
              OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => _save(
                        widget.project!.isPublished
                            ? PortfolioProjectStatus.draft
                            : PortfolioProjectStatus.published,
                      ),
                child: Text(
                  widget.project!.isPublished
                      ? 'Save and unpublish'
                      : 'Save and publish',
                ),
              ),
          ],
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    ),
  );

  Widget _textField(
    String key,
    String label, {
    bool required = false,
    String? hint,
    int maxLength = 1000,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: _fields[key],
      maxLength: maxLength,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator:
          validator ??
          (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'Required';
            }
            return null;
          },
    ),
  );

  String? _urlValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'Enter a complete HTTPS URL.';
    }
    return null;
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null && mounted) setState(() => _startedAt = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endedAt ?? _startedAt,
      firstDate: _startedAt,
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null && mounted) setState(() => _endedAt = picked);
  }

  Future<void> _save(PortfolioProjectStatus status) async {
    if (!_form.currentState!.validate()) return;
    final project = _makeProject(status);
    final validation = project.validate();
    if (validation != null) {
      _showError(context, ArgumentError(validation));
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.project == null) {
        await _repository.createProject(project);
      } else {
        await _repository.updateProject(project);
        if (status != widget.project!.status) {
          await _repository.setPublished(
            project.id,
            published: status == PortfolioProjectStatus.published,
          );
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == PortfolioProjectStatus.published
                ? 'Project published.'
                : 'Project saved.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PortfolioThumbnail extends StatelessWidget {
  const _PortfolioThumbnail({required this.project, required this.height});
  final PortfolioProject project;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = project.thumbnailUrl;
    if (url.isEmpty) return _placeholder(context);
    return Image.network(
      url,
      height: height,
      fit: BoxFit.cover,
      semanticLabel: project.thumbnailAltText,
      errorBuilder: (_, _, _) => _placeholder(context),
      frameBuilder: (context, child, frame, _) => frame == null
          ? SizedBox(
              height: height,
              child: const Center(child: CircularProgressIndicator()),
            )
          : child,
    );
  }

  Widget _placeholder(BuildContext context) => Container(
    height: height,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: const Icon(Icons.work_outline, size: 48),
  );
}

class _ExternalProjectLink extends StatelessWidget {
  const _ExternalProjectLink({required this.label, required this.url});
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        const Icon(Icons.link, size: 20),
        const SizedBox(width: 8),
        Expanded(child: SelectableText(url)),
        IconButton(
          tooltip: 'Copy $label',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Project link copied.')),
              );
            }
          },
          icon: const Icon(Icons.content_copy),
        ),
      ],
    ),
  );
}

class _PortfolioMessage extends StatelessWidget {
  const _PortfolioMessage({
    required this.icon,
    required this.title,
    this.detail,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(detail!, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}

List<String> _splitValues(String value) => value
    .split(',')
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toSet()
    .toList();

String _statusLabel(PortfolioProjectStatus status) => switch (status) {
  PortfolioProjectStatus.draft => 'Draft · Private',
  PortfolioProjectStatus.published => 'Published',
  PortfolioProjectStatus.archived => 'Archived',
};

String _dateLabel(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _projectTimeline(PortfolioProject project) => project.ongoing
    ? '${_dateLabel(project.startedAt)} · Ongoing'
    : '${_dateLabel(project.startedAt)} · ${project.endedAt == null ? 'End date not set' : _dateLabel(project.endedAt!)}';

String _errorText(Object error) => error is FirebaseException
    ? switch (error.code) {
        'permission-denied' =>
          'This project is private or your account cannot access it.',
        'unavailable' => 'Check your connection and try again.',
        _ => 'Firestore could not load this project (${error.code}).',
      }
    : 'Please try again. ${error.runtimeType}';

void _showError(BuildContext context, Object error) {
  final message = error is ArgumentError || error is StateError
      ? error.toString().replaceFirst('Invalid argument(s): ', '')
      : _errorText(error);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String description,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ??
    false;
