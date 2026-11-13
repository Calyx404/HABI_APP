import 'package:cloud_firestore/cloud_firestore.dart';

enum HabiThreadType {
  projectShowcase,
  learningJourney,
  professionalInsight,
  careerMilestone,
  questionDiscussion,
  collaborationOpportunity,
  communityContribution,
}

extension HabiThreadTypeLabel on HabiThreadType {
  String get label => switch (this) {
    HabiThreadType.projectShowcase => 'Project Showcase',
    HabiThreadType.learningJourney => 'Learning Journey',
    HabiThreadType.professionalInsight => 'Professional Insight',
    HabiThreadType.careerMilestone => 'Career Milestone',
    HabiThreadType.questionDiscussion => 'Question or Discussion',
    HabiThreadType.collaborationOpportunity => 'Collaboration Opportunity',
    HabiThreadType.communityContribution => 'Community Contribution',
  };
}

enum HabiThreadPublication { draft, published, deleted }

class HabiThread {
  const HabiThread({
    this.id = '',
    required this.authorUid,
    required this.authorName,
    this.authorHeadline = '',
    required this.type,
    this.title = '',
    this.content = '',
    this.skills = const [],
    this.topics = const [],
    this.externalUrl = '',
    this.portfolioProjectId,
    this.challenge = '',
    this.approach = '',
    this.outcome = '',
    this.learning = '',
    this.collaboration = '',
    this.publication = HabiThreadPublication.draft,
    this.moderationStatus = 'visible',
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String authorHeadline;
  final HabiThreadType type;
  final String title;
  final String content;
  final List<String> skills;
  final List<String> topics;
  final String externalUrl;
  final String? portfolioProjectId;
  final String challenge;
  final String approach;
  final String outcome;
  final String learning;
  final String collaboration;
  final HabiThreadPublication publication;
  final String moderationStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  bool get isPublished => publication == HabiThreadPublication.published;
  bool get isDraft => publication == HabiThreadPublication.draft;

  String? validate({bool forPublication = false}) {
    if (authorUid.trim().isEmpty) return 'Sign in to write a Thread.';
    if (authorName.trim().isEmpty || authorName.trim().length > 120) {
      return 'Your profile needs a valid display name.';
    }
    if (authorHeadline.length > 240) return 'Your headline is too long.';
    if (title.trim().length > 160) {
      return 'Title must be 160 characters or fewer.';
    }
    if (content.trim().length > 10000) {
      return 'Thread text must be 10,000 characters or fewer.';
    }
    if (forPublication && content.trim().isEmpty) {
      return 'Add some text before publishing.';
    }
    if (type == HabiThreadType.projectShowcase &&
        forPublication &&
        title.trim().isEmpty &&
        portfolioProjectId == null) {
      return 'Add a title or attach a portfolio project to your showcase.';
    }
    if (skills.length > 12 || topics.length > 12) {
      return 'Add no more than 12 skills and 12 topics.';
    }
    if ([
      ...skills,
      ...topics,
    ].any((value) => value.trim().isEmpty || value.trim().length > 48)) {
      return 'Each skill and topic must be 1–48 characters.';
    }
    if (!_validOptionalHttpsUrl(externalUrl)) {
      return 'Use a valid HTTPS link.';
    }
    if ((portfolioProjectId ?? '').length > 128) {
      return 'The portfolio project reference is invalid.';
    }
    if ([
      challenge,
      approach,
      outcome,
      learning,
      collaboration,
    ].any((value) => value.length > 3000)) {
      return 'Each story section must be 3,000 characters or fewer.';
    }
    return null;
  }

  HabiThread copyWith({
    String? id,
    String? authorUid,
    String? authorName,
    String? authorHeadline,
    HabiThreadType? type,
    String? title,
    String? content,
    List<String>? skills,
    List<String>? topics,
    String? externalUrl,
    String? portfolioProjectId,
    bool clearPortfolioProject = false,
    String? challenge,
    String? approach,
    String? outcome,
    String? learning,
    String? collaboration,
    HabiThreadPublication? publication,
    String? moderationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) => HabiThread(
    id: id ?? this.id,
    authorUid: authorUid ?? this.authorUid,
    authorName: authorName ?? this.authorName,
    authorHeadline: authorHeadline ?? this.authorHeadline,
    type: type ?? this.type,
    title: title ?? this.title,
    content: content ?? this.content,
    skills: skills ?? this.skills,
    topics: topics ?? this.topics,
    externalUrl: externalUrl ?? this.externalUrl,
    portfolioProjectId: clearPortfolioProject
        ? null
        : portfolioProjectId ?? this.portfolioProjectId,
    challenge: challenge ?? this.challenge,
    approach: approach ?? this.approach,
    outcome: outcome ?? this.outcome,
    learning: learning ?? this.learning,
    collaboration: collaboration ?? this.collaboration,
    publication: publication ?? this.publication,
    moderationStatus: moderationStatus ?? this.moderationStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    publishedAt: publishedAt ?? this.publishedAt,
  );

  Map<String, Object?> toFirestore() => {
    'authorUid': authorUid,
    'authorName': authorName.trim(),
    'authorHeadline': authorHeadline.trim(),
    'contentType': type.name,
    'title': title.trim(),
    'content': content.trim(),
    'skills': _cleanTags(skills),
    'topics': _cleanTags(topics),
    'externalUrl': externalUrl.trim(),
    'portfolioProjectId': portfolioProjectId,
    'challenge': challenge.trim(),
    'approach': approach.trim(),
    'outcome': outcome.trim(),
    'learning': learning.trim(),
    'collaboration': collaboration.trim(),
    'publicationStatus': publication.name,
    'moderationStatus': moderationStatus,
  };

  factory HabiThread.fromFirestore(String id, Map<String, dynamic> data) {
    final typeName = data['contentType'];
    final publicationName = data['publicationStatus'];
    final type = HabiThreadType.values.where((value) => value.name == typeName);
    final publication = HabiThreadPublication.values.where(
      (value) => value.name == publicationName,
    );
    if (type.isEmpty || publication.isEmpty) {
      throw const FormatException('Thread record has an unsupported status.');
    }
    return HabiThread(
      id: id,
      authorUid: _string(data['authorUid']),
      authorName: _string(data['authorName']),
      authorHeadline: _string(data['authorHeadline']),
      type: type.first,
      title: _string(data['title']),
      content: _string(data['content']),
      skills: _stringList(data['skills']),
      topics: _stringList(data['topics']),
      externalUrl: _string(data['externalUrl']),
      portfolioProjectId: data['portfolioProjectId'] is String
          ? data['portfolioProjectId'] as String
          : null,
      challenge: _string(data['challenge']),
      approach: _string(data['approach']),
      outcome: _string(data['outcome']),
      learning: _string(data['learning']),
      collaboration: _string(data['collaboration']),
      publication: publication.first,
      moderationStatus: _string(data['moderationStatus']),
      createdAt: _timestamp(data['createdAt']),
      updatedAt: _timestamp(data['updatedAt']),
      publishedAt: _timestamp(data['publishedAt']),
    );
  }
}

bool _validOptionalHttpsUrl(String raw) {
  if (raw.trim().isEmpty) return true;
  final uri = Uri.tryParse(raw.trim());
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

List<String> _cleanTags(List<String> values) => values
    .map((value) => value.trim().replaceFirst(RegExp(r'^#'), ''))
    .where((value) => value.isNotEmpty)
    .toSet()
    .toList(growable: false);

String _string(Object? value) => value is String ? value : '';

DateTime? _timestamp(Object? value) =>
    value is Timestamp ? value.toDate() : null;

List<String> _stringList(Object? value) => value is Iterable
    ? value.whereType<String>().map((value) => value.trim()).toList()
    : const [];
