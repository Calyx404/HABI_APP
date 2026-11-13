import 'package:cloud_firestore/cloud_firestore.dart';

enum PortfolioProjectStatus { draft, published, archived }

class PortfolioProject {
  const PortfolioProject({
    this.id = '',
    required this.ownerUid,
    required this.title,
    required this.summary,
    required this.description,
    this.category = '',
    this.role = '',
    this.skills = const [],
    this.technologies = const [],
    this.responsibilities = '',
    this.outcomes = '',
    this.reflection = '',
    required this.startedAt,
    this.endedAt,
    this.ongoing = false,
    this.demoUrl = '',
    this.repositoryUrl = '',
    this.thumbnailUrl = '',
    this.thumbnailAltText = '',
    this.status = PortfolioProjectStatus.draft,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String title;
  final String summary;
  final String description;
  final String category;
  final String role;
  final List<String> skills;
  final List<String> technologies;
  final String responsibilities;
  final String outcomes;
  final String reflection;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool ongoing;
  final String demoUrl;
  final String repositoryUrl;
  final String thumbnailUrl;
  final String thumbnailAltText;
  final PortfolioProjectStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPublished => status == PortfolioProjectStatus.published;

  String? validate() {
    if (ownerUid.trim().isEmpty) return 'Project owner is required.';
    if (title.trim().isEmpty) return 'Add a project title.';
    if (title.trim().length > 120) {
      return 'Title must be 120 characters or fewer.';
    }
    if (summary.trim().isEmpty) return 'Add a short project summary.';
    if (summary.trim().length > 500) {
      return 'Summary must be 500 characters or fewer.';
    }
    if (description.trim().isEmpty) return 'Add a project description.';
    if (description.trim().length > 10000) {
      return 'Description must be 10,000 characters or fewer.';
    }
    if (category.length > 100 || role.length > 120) {
      return 'Category or role is too long.';
    }
    if (responsibilities.length > 2000 ||
        outcomes.length > 2000 ||
        reflection.length > 2000) {
      return 'Each project notes field must be 2,000 characters or fewer.';
    }
    if (skills.length > 20 || technologies.length > 20) {
      return 'Add no more than 20 skills and 20 technologies.';
    }
    if ([...skills, ...technologies].any((value) => value.trim().length > 80)) {
      return 'Each skill or technology must be 80 characters or fewer.';
    }
    if (ongoing && endedAt != null) {
      return 'An ongoing project cannot have an end date.';
    }
    if (!ongoing && endedAt != null && endedAt!.isBefore(startedAt)) {
      return 'End date must be on or after the start date.';
    }
    if (!_isAllowedUrl(demoUrl) || !_isAllowedUrl(repositoryUrl)) {
      return 'Project and repository links must be valid HTTPS URLs.';
    }
    if (!_isAllowedUrl(thumbnailUrl)) {
      return 'Thumbnail must be a valid HTTPS URL.';
    }
    if (thumbnailAltText.length > 200) {
      return 'Thumbnail description must be 200 characters or fewer.';
    }
    if (thumbnailUrl.trim().isNotEmpty && thumbnailAltText.trim().isEmpty) {
      return 'Describe the project thumbnail for people using assistive technology.';
    }
    return null;
  }

  Map<String, Object?> toFirestore({required String ownerUid}) => {
    'ownerUid': ownerUid,
    'title': title.trim(),
    'summary': summary.trim(),
    'description': description.trim(),
    'category': category.trim(),
    'role': role.trim(),
    'skills': _cleanList(skills),
    'technologies': _cleanList(technologies),
    'responsibilities': responsibilities.trim(),
    'outcomes': outcomes.trim(),
    'reflection': reflection.trim(),
    'startedAt': Timestamp.fromDate(startedAt),
    'endedAt': endedAt == null ? null : Timestamp.fromDate(endedAt!),
    'ongoing': ongoing,
    'demoUrl': demoUrl.trim(),
    'repositoryUrl': repositoryUrl.trim(),
    'thumbnailUrl': thumbnailUrl.trim(),
    'thumbnailAltText': thumbnailAltText.trim(),
    'status': status.name,
  };

  factory PortfolioProject.fromFirestore(String id, Map<String, dynamic> data) {
    final status = PortfolioProjectStatus.values.where(
      (value) => value.name == data['status'],
    );
    final startedAt = data['startedAt'];
    final endedAt = data['endedAt'];
    if (startedAt is! Timestamp ||
        (endedAt != null && endedAt is! Timestamp) ||
        status.isEmpty) {
      throw const FormatException('Project record is malformed.');
    }
    return PortfolioProject(
      id: id,
      ownerUid: _string(data['ownerUid']),
      title: _string(data['title']),
      summary: _string(data['summary']),
      description: _string(data['description']),
      category: _string(data['category']),
      role: _string(data['role']),
      skills: _stringList(data['skills']),
      technologies: _stringList(data['technologies']),
      responsibilities: _string(data['responsibilities']),
      outcomes: _string(data['outcomes']),
      reflection: _string(data['reflection']),
      startedAt: startedAt.toDate(),
      endedAt: endedAt is Timestamp ? endedAt.toDate() : null,
      ongoing: data['ongoing'] == true,
      demoUrl: _string(data['demoUrl']),
      repositoryUrl: _string(data['repositoryUrl']),
      thumbnailUrl: _string(data['thumbnailUrl']),
      thumbnailAltText: _string(data['thumbnailAltText']),
      status: status.first,
      createdAt: _timestamp(data['createdAt']),
      updatedAt: _timestamp(data['updatedAt']),
    );
  }
}

bool _isAllowedUrl(String raw) {
  if (raw.trim().isEmpty) return true;
  final uri = Uri.tryParse(raw.trim());
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

String _string(Object? value) => value is String ? value : '';

DateTime? _timestamp(Object? value) =>
    value is Timestamp ? value.toDate() : null;

List<String> _stringList(Object? value) => value is Iterable
    ? value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList()
    : const [];

List<String> _cleanList(List<String> values) => values
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toSet()
    .toList();
