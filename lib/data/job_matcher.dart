import 'package:habi/data/account_store.dart';
import 'package:habi/data/job_store.dart';

/// Explainable baseline recommendation weights. Sensitive traits and
/// accommodation information are intentionally excluded from ranking.
const Map<String, double> jobMatchWeights = {
  'skills': .35,
  'experience': .20,
  'education': .10,
  'location': .15,
  'workArrangement': .10,
  'employmentTypeAndSchedule': .10,
};

class JobMatchResult {
  const JobMatchResult({
    required this.job,
    required this.score,
    required this.reasons,
    required this.missingFactors,
    required this.incompatibilities,
    required this.unmetQualifications,
  });

  final Job job;
  final int score;
  final List<String> reasons;
  final List<String> missingFactors;
  final List<String> incompatibilities;
  final List<String> unmetQualifications;
}

class JobMatcher {
  const JobMatcher();

  List<JobMatchResult> rank(Iterable<Job> jobs, Account? account) {
    final results = jobs.map((job) => score(job, account)).toList();
    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0
          ? byScore
          : a.job.postedAt.compareTo(b.job.postedAt) * -1;
    });
    return results;
  }

  JobMatchResult score(Job job, Account? account) {
    final known = <String, double>{};
    final reasons = <String>[];
    final missing = <String>[];
    final incompatibilities = <String>[];
    final unmetQualifications = <String>[];
    final profile = account;
    void factor(
      String key,
      double? value,
      String reason,
      String mismatch, {
      bool hasUnmetRequirement = false,
    }) {
      if (value == null) {
        missing.add(key);
      } else {
        known[key] = value;
        if (value >= .5) {
          reasons.add(reason);
        }
        if (value < .5 || hasUnmetRequirement) {
          incompatibilities.add(mismatch);
        }
      }
    }

    final jobSkills = _terms(job.requirements)
        .where((term) => term.length > 2)
        .toSet();
    final seekerSkills =
        profile?.skills.map(_normalize).where((s) => s.isNotEmpty).toSet() ??
        {};
    final skillOverlap = seekerSkills.intersection(jobSkills);
    final missingSkills = jobSkills.difference(seekerSkills);
    if (missingSkills.isNotEmpty) {
      unmetQualifications.add(
        'Skills to review: ${missingSkills.take(4).join(', ')}',
      );
    }
    factor(
      'skills',
      jobSkills.isEmpty || seekerSkills.isEmpty
          ? null
          : seekerSkills.intersection(jobSkills).length / jobSkills.length,
      seekerSkills.intersection(jobSkills).isEmpty
          ? 'Review required skills'
          : 'Skills match: ${seekerSkills.intersection(jobSkills).take(3).join(', ')}',
      skillOverlap.isEmpty
          ? 'No listed skill overlap'
          : 'Some listed skills are not in your profile',
      hasUnmetRequirement: missingSkills.isNotEmpty,
    );

    final requiredYears = _years(job.experience);
    final actualYears = _years(profile?.workExperience ?? '');
    if (requiredYears != null &&
        actualYears != null &&
        actualYears < requiredYears) {
      unmetQualifications.add(
        'Experience listed: ${_formatYears(requiredYears)} years',
      );
    }
    factor(
      'experience',
      requiredYears == null || actualYears == null
          ? null
          : (actualYears >= requiredYears ? 1.0 : actualYears / requiredYears)
                .clamp(0.0, 1.0)
                .toDouble(),
      'Experience is compatible with the listing',
      'Experience listed: ${requiredYears == null ? 'not specified' : '${_formatYears(requiredYears)} years'}',
    );

    final educationRequirement = _educationTerm(job.requirements);
    final education = _normalize(profile?.education ?? '');
    if (educationRequirement != null &&
        education.isNotEmpty &&
        !education.contains(educationRequirement)) {
      unmetQualifications.add('Education listed: $educationRequirement');
    }
    factor(
      'education',
      educationRequirement == null || education.isEmpty
          ? null
          : (education.contains(educationRequirement) ? 1 : 0),
      'Education appears to meet the stated requirement',
      'Education listed: ${educationRequirement ?? 'not specified'}',
    );

    final preferredLocation = _normalize(profile?.preferredLocation ?? '');
    final jobLocation = _normalize(job.location);
    factor(
      'location',
      preferredLocation.isEmpty || jobLocation.isEmpty
          ? null
          : (jobLocation.contains(preferredLocation) ||
                    preferredLocation.contains(jobLocation)
                ? 1
                : 0),
      'Location matches your preference',
      'Location differs from your preference',
    );

    final arrangement = _normalize(profile?.workArrangement ?? '');
    final jobArrangement = _normalize(job.setup);
    factor(
      'workArrangement',
      arrangement.isEmpty || jobArrangement.isEmpty
          ? null
          : (arrangement == jobArrangement ||
                    jobArrangement.contains(arrangement)
                ? 1
                : 0),
      'Work arrangement matches your preference',
      'Work arrangement differs from your preference',
    );

    final type = _normalize(profile?.employmentType ?? '');
    final jobType = _normalize(job.type);
    final schedule = profile?.availabilityTime.trim() ?? '';
    final jobSchedule = _normalize(job.workSchedule);
    final typeKnown = type.isNotEmpty && jobType.isNotEmpty;
    final scheduleKnown = schedule.isNotEmpty && jobSchedule.isNotEmpty;
    factor(
      'employmentTypeAndSchedule',
      !typeKnown && !scheduleKnown
          ? null
          : ((typeKnown && (jobType.contains(type) || type.contains(jobType))
                        ? .5
                        : 0) +
                    (scheduleKnown && _normalize(schedule) == jobSchedule
                        ? .5
                        : 0)) /
                ((typeKnown ? .5 : 0) + (scheduleKnown ? .5 : 0)),
      'Employment type or schedule aligns with your preferences',
      'Employment type or schedule differs from your preferences',
    );

    final availableWeight = known.keys.fold<double>(
      0,
      (sum, key) => sum + jobMatchWeights[key]!,
    );
    final weighted = known.entries.fold<double>(
      0,
      (sum, entry) => sum + entry.value * jobMatchWeights[entry.key]!,
    );
    final score = availableWeight == 0
        ? 0
        : (100 * weighted / availableWeight).round();
    return JobMatchResult(
      job: job,
      score: score,
      reasons: List.unmodifiable(reasons),
      missingFactors: List.unmodifiable(missing),
      incompatibilities: List.unmodifiable(incompatibilities),
      unmetQualifications: List.unmodifiable(unmetQualifications),
    );
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9+# ]'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  static Set<String> _terms(String value) => _normalize(value)
      .split(' ')
      .where(
        (term) =>
            term.length > 2 &&
            !const {
              'and',
              'the',
              'with',
              'for',
              'years',
              'year',
              'experience',
              'required',
              'preferred',
              'knowledge',
              'ability',
            }.contains(term),
      )
      .toSet();

  static double? _years(String value) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*\+?\s*years?',
      caseSensitive: false,
    ).firstMatch(value);
    return match == null ? null : double.tryParse(match.group(1)!);
  }

  static String _formatYears(double value) =>
      value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

  static String? _educationTerm(String value) {
    final normalized = _normalize(value);
    for (final level in [
      'doctoral',
      'master',
      'bachelor',
      'associate',
      'diploma',
      'high school',
    ]) {
      if (normalized.contains(level)) return level;
    }
    return null;
  }
}
