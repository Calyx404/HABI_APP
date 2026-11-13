import 'package:flutter_test/flutter_test.dart';
import 'package:habi/data/account_store.dart';
import 'package:habi/data/job_matcher.dart';
import 'package:habi/data/job_store.dart';

void main() {
  Account profile() =>
      Account(
          uid: 'seeker',
          firstName: 'Ari',
          lastName: 'Santos',
          birthDate: DateTime(2000),
          sex: '',
          email: 'ari@example.test',
          mobile: '',
          address: '',
          cityProvince: '',
          barangay: '',
        )
        ..skills = {'Flutter', 'Dart'}
        ..workExperience = '2 years'
        ..preferredLocation = 'Manila'
        ..workArrangement = 'Remote'
        ..employmentType = 'Full-time';

  Job job({required String id, required String location}) => Job(
    id: id,
    title: 'Flutter developer',
    setup: 'Remote',
    type: 'Full-time',
    location: location,
    pay: '',
    description: 'Build Flutter apps with Dart',
    requirements: 'Flutter Dart, 2 years experience',
    experience: '2 years',
    postedBy: 'Inclusive employer',
  );

  test('ranks compatible jobs higher and explains matching factors', () {
    final ranked = const JobMatcher().rank([
      job(id: 'far', location: 'Cebu'),
      job(id: 'near', location: 'Manila'),
    ], profile());

    expect(ranked.first.job.id, 'near');
    expect(ranked.first.score, 100);
    expect(ranked.first.reasons, contains('Skills match: flutter, dart'));
  });

  test('does not use accessibility or beneficiary details in ranking', () {
    final first = profile()..accessibility = {'Wheelchair access'};
    final second = profile()..accessibility = {'Sign language'};
    first.shareAccessibility = true;
    second.shareAccessibility = true;

    expect(
      const JobMatcher().score(job(id: 'one', location: 'Manila'), first).score,
      const JobMatcher()
          .score(job(id: 'two', location: 'Manila'), second)
          .score,
    );
  });

  test('renormalizes the score when profile factors are unknown', () {
    final sparse = profile()
      ..skills.clear()
      ..workExperience = '1 year'
      ..preferredLocation = ''
      ..workArrangement = ''
      ..employmentType = '';
    final result = const JobMatcher().score(
      job(id: 'one', location: 'Manila'),
      sparse,
    );

    expect(result.score, 50); // only the known experience factor contributes
    expect(result.missingFactors, contains('skills'));
  });

  test('shows unmet skill qualifications without using them as a protected trait proxy', () {
    final sparse = profile()..skills = {'Dart'};
    final result = const JobMatcher().score(
      job(id: 'one', location: 'Manila'),
      sparse,
    );

    expect(result.unmetQualifications, contains('Skills to review: flutter'));
    expect(
      result.incompatibilities,
      contains('Some listed skills are not in your profile'),
    );
  });
}
