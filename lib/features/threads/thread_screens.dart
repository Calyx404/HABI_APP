import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/account_store.dart';
import '../../data/habi_thread.dart';
import '../../data/habi_thread_repository.dart';
import '../../data/portfolio_project.dart';
import '../../data/portfolio_repository.dart';
import '../../shared/theme/habi_background.dart';
import '../../shared/widgets/habi_components.dart';
import '../../shared/widgets/habi_ui.dart';
import '../profile/public_professional_profile_screen.dart';
import 'thread_widgets.dart';

class CreateThreadScreen extends StatefulWidget {
  const CreateThreadScreen({
    super.key,
    this.userName = '',
    this.draftId,
    this.repository,
    this.openedAsRoute = false,
  });

  final String userName;
  final String? draftId;
  final HabiThreadRepository? repository;
  final bool openedAsRoute;

  @override
  State<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends State<CreateThreadScreen> {
  late final HabiThreadRepository _repository =
      widget.repository ?? HabiThreadRepository();
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _skills = TextEditingController();
  final _topics = TextEditingController();
  final _externalUrl = TextEditingController();
  final _challenge = TextEditingController();
  final _approach = TextEditingController();
  final _outcome = TextEditingController();
  final _learning = TextEditingController();
  final _collaboration = TextEditingController();
  final _portfolioRepository = PortfolioRepository();
  late final Stream<List<HabiThread>> _draftStream = _repository.watchDrafts();
  HabiThreadType _type = HabiThreadType.projectShowcase;
  String? _editingId;
  HabiThreadPublication? _editingPublication;
  String? _projectId;
  bool _busy = false;
  bool _loadingThread = false;
  String? _loadError;
  bool _showStoryFields = false;

  @override
  void initState() {
    super.initState();
    if (widget.draftId != null) _loadThread(widget.draftId!);
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _content,
      _skills,
      _topics,
      _externalUrl,
      _challenge,
      _approach,
      _outcome,
      _learning,
      _collaboration,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadThread(String id) async {
    setState(() {
      _loadingThread = true;
      _loadError = null;
    });
    try {
      final thread = await _repository.getThread(id);
      if (!mounted) return;
      if (thread == null || thread.authorUid != _repository.currentUid) {
        setState(() {
          _loadError = 'This Thread is unavailable or belongs to another user.';
          _loadingThread = false;
        });
        return;
      }
      _fill(thread);
      setState(() {
        _editingId = thread.id;
        _editingPublication = thread.publication;
        _loadingThread = false;
        _showStoryFields = [
          thread.challenge,
          thread.approach,
          thread.outcome,
          thread.learning,
          thread.collaboration,
        ].any((value) => value.isNotEmpty);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = 'This Thread could not be loaded. Check your connection and retry.';
          _loadingThread = false;
        });
      }
    }
  }

  void _fill(HabiThread thread) {
    _title.text = thread.title;
    _content.text = thread.content;
    _skills.text = thread.skills.join(', ');
    _topics.text = thread.topics.join(', ');
    _externalUrl.text = thread.externalUrl;
    _challenge.text = thread.challenge;
    _approach.text = thread.approach;
    _outcome.text = thread.outcome;
    _learning.text = thread.learning;
    _collaboration.text = thread.collaboration;
    _type = thread.type;
    _projectId = thread.portfolioProjectId;
  }

  HabiThread _compose() {
    final account = AccountStore.instance.current;
    final auth = FirebaseAuth.instance.currentUser;
    final displayName =
        account?.displayName ?? auth?.displayName ?? widget.userName;
    return HabiThread(
      id: _editingId ?? '',
      authorUid: _repository.currentUid,
      authorName: displayName.trim(),
      authorHeadline: account?.professionalSummary.trim() ?? '',
      type: _type,
      title: _title.text,
      content: _content.text,
      skills: _parseTags(_skills.text),
      topics: _parseTags(_topics.text),
      externalUrl: _externalUrl.text,
      portfolioProjectId: _projectId,
      challenge: _challenge.text,
      approach: _approach.text,
      outcome: _outcome.text,
      learning: _learning.text,
      collaboration: _collaboration.text,
      publication: _editingPublication ?? HabiThreadPublication.draft,
    );
  }

  Future<void> _saveDraft() async {
    if (_busy) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;
    setState(() => _busy = true);
    try {
      final id = await _repository.saveDraft(_compose());
      if (!mounted) return;
      setState(() {
        _editingId = id;
        _editingPublication = HabiThreadPublication.draft;
      });
      _message('Draft saved. You can return to it from Create.');
    } catch (error) {
      if (mounted) _message(_safeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final invalid = _compose().validate(forPublication: true);
    if (invalid != null) {
      _message(invalid);
      return;
    }
    setState(() => _busy = true);
    try {
      await _repository.publish(_compose());
      if (!mounted) return;
      _message('Your Thread is now in HABI Feed.');
      if (widget.openedAsRoute) {
        Navigator.of(context).pop(true);
      } else {
        _clearForm();
      }
    } catch (error) {
      if (mounted) _message(_safeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteDraft(HabiThread thread) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this draft?'),
        content: const Text(
          'This draft will be removed from your private drafts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteThread(thread.id);
    } catch (error) {
      if (mounted) _message(_safeError(error));
    }
  }

  void _clearForm() {
    _title.clear();
    _content.clear();
    _skills.clear();
    _topics.clear();
    _externalUrl.clear();
    _challenge.clear();
    _approach.clear();
    _outcome.clear();
    _learning.clear();
    _collaboration.clear();
    setState(() {
      _editingId = null;
      _editingPublication = null;
      _projectId = null;
      _type = HabiThreadType.projectShowcase;
      _showStoryFields = false;
    });
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HabiAppBar(
      title: _editingId == null ? 'Create a HABI Thread' : 'Edit your Thread',
      notificationUserName: widget.userName,
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        const HabiBackground(),
        if (_loadingThread)
          const Center(child: CircularProgressIndicator())
        else if (_loadError != null)
          Center(
            child: HabiErrorState(
              message: _loadError!,
              onRetry: () => _loadThread(widget.draftId!),
            ),
          )
        else
          Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                if (_editingId == null) _drafts(),
                Row(
                  children: [
                    HabiProfileAvatar(
                      name: widget.userName.isEmpty ? 'You' : widget.userName,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Tell the story behind your work',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<HabiThreadType>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Thread category',
                  ),
                  items: HabiThreadType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _type = value ?? _type),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  maxLength: 160,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: _type == HabiThreadType.projectShowcase
                        ? 'Project title'
                        : 'Title (optional)',
                    hintText: 'Give your story a clear title',
                  ),
                  validator: (value) => (value?.length ?? 0) > 160
                      ? 'Title must be 160 characters or fewer.'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _content,
                  minLines: 5,
                  maxLines: 12,
                  maxLength: 10000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Your Thread',
                    hintText: 'Share a project, insight, milestone, question, or contribution…',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value?.length ?? 0) > 10000
                      ? 'Thread text must be 10,000 characters or fewer.'
                      : null,
                ),
                const SizedBox(height: 12),
                _ProjectSelector(
                  portfolioRepository: _portfolioRepository,
                  selectedId: _projectId,
                  onChanged: (value) => setState(() => _projectId = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _skills,
                  decoration: const InputDecoration(
                    labelText: 'Skills',
                    hintText: 'Flutter, Accessibility, Research',
                  ),
                  validator: (value) => _validateTags(value, 'skills'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _topics,
                  decoration: const InputDecoration(
                    labelText: 'Topics',
                    hintText: 'Inclusive design, Portfolio',
                  ),
                  validator: (value) => _validateTags(value, 'topics'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _externalUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'External link (optional)',
                    hintText: 'https://…',
                  ),
                  validator: (value) =>
                      _validUrl(value ?? '') ? null : 'Use a valid HTTPS link.',
                ),
                const SizedBox(height: 8),
                ExpansionTile(
                  initiallyExpanded: _showStoryFields,
                  onExpansionChanged: (value) =>
                      setState(() => _showStoryFields = value),
                  title: const Text('Add story details (optional)'),
                  subtitle: const Text(
                    'Challenge, approach, outcome, learning, or collaboration',
                  ),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  children: [
                    _storyField(
                      _challenge,
                      'The challenge',
                      'What problem or opportunity led to this work?',
                    ),
                    _storyField(_approach, 'My approach', 'What did you do?'),
                    _storyField(
                      _outcome,
                      'The outcome',
                      'What changed or was accomplished?',
                    ),
                    _storyField(
                      _learning,
                      'What I learned',
                      'What will you carry forward?',
                    ),
                    _storyField(
                      _collaboration,
                      'Collaboration',
                      'What feedback or support are you seeking?',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_busy) const LinearProgressIndicator(),
                Row(
                  children: [
                    if (_editingPublication != HabiThreadPublication.published)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _saveDraft,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save draft'),
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _publish,
                        icon: const Icon(Icons.send_rounded),
                        label: Text(
                          _editingPublication == HabiThreadPublication.published
                              ? 'Save changes'
                              : _editingId == null
                              ? 'Publish'
                              : 'Publish draft',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  'Drafts are private. Published Threads are visible to signed-in HABI members while they remain visible.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _drafts() => StreamBuilder<List<HabiThread>>(
    stream: _draftStream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return HabiErrorState(
          message: 'Your private drafts could not be loaded.',
          onRetry: () => setState(() {}),
        );
      }
      if (!snapshot.hasData) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: LinearProgressIndicator(),
        );
      }
      final drafts = snapshot.data!;
      if (drafts.isEmpty) {
        return Card(
          margin: const EdgeInsets.only(bottom: 18),
          child: ListTile(
            leading: const Icon(Icons.edit_note_rounded),
            title: const Text('Your drafts'),
            subtitle: const Text(
              'Saved drafts are private and will appear here.',
            ),
          ),
        );
      }
      return Card(
        margin: const EdgeInsets.only(bottom: 18),
        child: ExpansionTile(
          title: Text('Your drafts · ${drafts.length}'),
          subtitle: const Text('Only you can see these'),
          children: drafts
              .map(
                (thread) => ListTile(
                  leading: const Icon(Icons.edit_note_rounded),
                  title: Text(
                    thread.title.isEmpty ? thread.type.label : thread.title,
                  ),
                  subtitle: Text(
                    thread.content.isEmpty ? 'No text yet' : thread.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _loadDraft(thread),
                  trailing: IconButton(
                    tooltip: 'Delete draft',
                    onPressed: _busy ? null : () => _deleteDraft(thread),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              )
              .toList(),
        ),
      );
    },
  );

  Future<void> _loadDraft(HabiThread thread) async {
    _fill(thread);
    setState(() {
      _editingId = thread.id;
      _editingPublication = HabiThreadPublication.draft;
    });
  }

  Widget _storyField(
    TextEditingController controller,
    String label,
    String hint,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: TextFormField(
      controller: controller,
      maxLength: 3000,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
      ),
      validator: (value) => (value?.length ?? 0) > 3000
          ? '$label must be 3,000 characters or fewer.'
          : null,
    ),
  );
}

class _ProjectSelector extends StatefulWidget {
  const _ProjectSelector({
    required this.portfolioRepository,
    required this.selectedId,
    required this.onChanged,
  });
  final PortfolioRepository portfolioRepository;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  State<_ProjectSelector> createState() => _ProjectSelectorState();
}

class _ProjectSelectorState extends State<_ProjectSelector> {
  late final String? _ownerUid = widget.portfolioRepository.currentUid;
  late final Stream<List<PortfolioProject>>? _projects = _ownerUid == null
      ? null
      : widget.portfolioRepository.watchOwnerProjects(_ownerUid);

  @override
  Widget build(BuildContext context) {
    if (_projects == null) return const SizedBox.shrink();
    return StreamBuilder<List<PortfolioProject>>(
      stream: _projects,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Portfolio projects are unavailable right now.',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        final projects = (snapshot.data ?? const <PortfolioProject>[])
            .where((project) => project.isPublished)
            .toList();
        if (projects.isEmpty) {
          return InputDecorator(
            decoration: const InputDecoration(labelText: 'Portfolio project'),
            child: Text(
              'Publish a portfolio project to attach it here.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        return DropdownButtonFormField<String>(
          initialValue:
              widget.selectedId != null &&
                  projects.any((p) => p.id == widget.selectedId)
              ? widget.selectedId
              : '',
          decoration: const InputDecoration(
            labelText: 'Portfolio project (optional)',
          ),
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('No project attached'),
            ),
            ...projects.map(
              (project) => DropdownMenuItem(
                value: project.id,
                child: Text(project.title, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (value) =>
              widget.onChanged(value == null || value.isEmpty ? null : value),
        );
      },
    );
  }
}

String? _validateTags(String? input, String label) {
  final tags = _parseTags(input ?? '');
  if (tags.length > 12) return 'Use 12 or fewer $label.';
  if (tags.any((tag) => tag.length > 48)) {
    return 'Each $label entry must be 48 characters or fewer.';
  }
  return null;
}

List<String> _parseTags(String input) => input
    .split(',')
    .map((value) => value.trim().replaceFirst(RegExp(r'^#'), ''))
    .where((value) => value.isNotEmpty)
    .toSet()
    .toList(growable: false);

bool _validUrl(String value) {
  if (value.trim().isEmpty) return true;
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

String _safeError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'Firestore denied this action. Check your account access and try again.',
      'unavailable' || 'network-request-failed' => 'The network is unavailable. Your text is still here; retry when you reconnect.',
      _ =>
        'The Thread could not be saved. Your text is still here; please retry.',
    };
  }
  return error is ArgumentError || error is StateError
      ? error.toString().replaceFirst('Invalid argument(s): ', '')
      : 'The Thread could not be saved. Your text is still here; please retry.';
}

class HabiThreadDetailsScreen extends StatefulWidget {
  const HabiThreadDetailsScreen({
    super.key,
    required this.postId,
    required this.repository,
  });
  final String postId;
  final HabiThreadRepository repository;

  @override
  State<HabiThreadDetailsScreen> createState() =>
      _HabiThreadDetailsScreenState();
}

class _HabiThreadDetailsScreenState extends State<HabiThreadDetailsScreen> {
  late Future<HabiThread?> _thread = widget.repository.getThread(widget.postId);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HabiAppBar(
      title: 'HABI Thread',
      notificationUserName:
          FirebaseAuth.instance.currentUser?.displayName ?? '',
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        const HabiBackground(),
        FutureBuilder<HabiThread?>(
          future: _thread,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: HabiErrorState(
                  message: 'This Thread could not be opened or is no longer available.',
                  onRetry: () => setState(
                    () => _thread = widget.repository.getThread(widget.postId),
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final thread = snapshot.data;
            if (thread == null) return const _UnavailableThread();
            return _ThreadDetailContent(
              thread: thread,
              repository: widget.repository,
            );
          },
        ),
      ],
    ),
  );
}

class _ThreadDetailContent extends StatefulWidget {
  const _ThreadDetailContent({required this.thread, required this.repository});
  final HabiThread thread;
  final HabiThreadRepository repository;

  @override
  State<_ThreadDetailContent> createState() => _ThreadDetailContentState();
}

class _ThreadDetailContentState extends State<_ThreadDetailContent> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final List<HabiComment> _comments = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  bool _sending = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.loadComments(
        widget.thread.id,
        after: _cursor,
      );
      if (!mounted) return;
      setState(() {
        _comments.addAll(page.comments);
        _cursor = page.cursor;
        _hasMore = page.hasMore && page.cursor != null;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Comments could not be loaded. Check your connection and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.repository.addComment(widget.thread.id, text);
      _commentController.clear();
      _cursor = null;
      _hasMore = true;
      _comments.clear();
      await _loadMore();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_safeError(error))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editComment(HabiComment comment) async {
    final controller = TextEditingController(text: comment.body);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit comment'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 6,
          maxLength: 2000,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) return;
    try {
      await widget.repository.updateComment(comment, text);
      if (mounted) {
        setState(() {
          final index = _comments.indexWhere((item) => item.id == comment.id);
          if (index >= 0) {
            _comments[index] = HabiComment(
              id: comment.id,
              postId: comment.postId,
              authorUid: comment.authorUid,
              authorName: comment.authorName,
              body: text,
              createdAt: comment.createdAt,
              updatedAt: DateTime.now(),
            );
          }
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_safeError(error))));
      }
    }
  }

  Future<void> _deleteComment(HabiComment comment) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      await widget.repository.deleteComment(comment);
      if (mounted) {
        setState(() => _comments.removeWhere((item) => item.id == comment.id));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_safeError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 300) _loadMore();
            return false;
          },
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            children: [
              HabiThreadCard(
                thread: widget.thread,
                repository: widget.repository,
                showCommentsAction: false,
              ),
              Text('Comments', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              if (!_loaded && _loading) const HabiLoadingSkeleton(height: 75),
              if (_error != null)
                HabiErrorState(message: _error!, onRetry: _loadMore),
              if (_loaded && _comments.isEmpty && _error == null)
                const _EmptyComments(),
              ..._comments.map(_commentTile),
              if (_loading && _loaded)
                const Center(child: CircularProgressIndicator()),
              if (!_hasMore && _comments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'You’re all caught up.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Add a thoughtful comment',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Post comment',
                onPressed: _sending ? null : _sendComment,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _commentTile(HabiComment comment) {
    final own = comment.authorUid == widget.repository.currentUid;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        isThreeLine: true,
        leading: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PublicProfessionalProfileScreen(
                uid: comment.authorUid,
                fallbackName: comment.authorName,
                repository: widget.repository,
              ),
            ),
          ),
          child: HabiProfileAvatar(name: comment.authorName, size: 40),
        ),
        title: Text(
          comment.authorName,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          '${comment.body}\n${_time(comment.createdAt)}${comment.updatedAt != null && comment.createdAt != null && comment.updatedAt!.isAfter(comment.createdAt!) ? ' · edited' : ''}',
        ),
        trailing: own
            ? PopupMenuButton<String>(
                onSelected: (value) => value == 'edit'
                    ? _editComment(comment)
                    : _deleteComment(comment),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              )
            : null,
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 26),
    child: Text(
      'Start a thoughtful conversation.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}

class _UnavailableThread extends StatelessWidget {
  const _UnavailableThread();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: HabiEmptyState(
        icon: Icons.article_outlined,
        title: 'Thread unavailable',
        message:
            'This Thread may have been deleted or hidden by HABI governance.',
      ),
    ),
  );
}

String _time(DateTime? value) {
  if (value == null) return 'Just now';
  final age = DateTime.now().difference(value);
  if (age.inMinutes < 1) return 'Just now';
  if (age.inHours < 1) return '${age.inMinutes} min ago';
  if (age.inDays < 1) return '${age.inHours} hr ago';
  if (age.inDays < 7) return '${age.inDays} days ago';
  return '${value.month}/${value.day}/${value.year}';
}
