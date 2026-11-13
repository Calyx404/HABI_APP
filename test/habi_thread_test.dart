import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habi/data/habi_thread.dart';
import 'package:habi/data/habi_thread_repository.dart';

void main() {
  final publishedAt = DateTime.utc(2026, 5, 4, 12);

  HabiThread thread({
    HabiThreadType type = HabiThreadType.projectShowcase,
    String title = 'Accessible learning app',
    String content = 'I built a learning experience with accessible controls.',
    String externalUrl = 'https://example.org/project',
  }) => HabiThread(
    authorUid: 'seeker-1',
    authorName: 'Maria Santos',
    authorHeadline: 'Product designer',
    type: type,
    title: title,
    content: content,
    skills: const ['Flutter', 'Accessibility'],
    topics: const ['Inclusive Tech'],
    externalUrl: externalUrl,
    portfolioProjectId: 'project-1',
    challenge: 'Make learning usable by more people.',
    approach: 'Tested keyboard and screen reader flows.',
    outcome: 'Created an accessible learning app.',
    learning: 'Early testing improved the product.',
    collaboration: 'Looking for educators to review it.',
    publication: HabiThreadPublication.published,
    createdAt: publishedAt.subtract(const Duration(days: 1)),
    updatedAt: publishedAt,
    publishedAt: publishedAt,
  );

  test('Thread serialization round-trips supported content and timestamps', () {
    final source = thread();
    final data = source.toFirestore()
      ..['createdAt'] = Timestamp.fromDate(source.createdAt!)
      ..['updatedAt'] = Timestamp.fromDate(source.updatedAt!)
      ..['publishedAt'] = Timestamp.fromDate(source.publishedAt!);

    final restored = HabiThread.fromFirestore('thread-1', data);

    expect(restored.id, 'thread-1');
    expect(restored.authorUid, source.authorUid);
    expect(restored.type, source.type);
    expect(restored.publication, HabiThreadPublication.published);
    expect(restored.skills, source.skills);
    expect(restored.topics, source.topics);
    expect(restored.portfolioProjectId, source.portfolioProjectId);
    expect(restored.challenge, source.challenge);
    expect(restored.publishedAt!.isAtSameMomentAs(publishedAt), isTrue);
  });

  test(
    'drafts allow incomplete content while publication requires content',
    () {
      expect(thread(content: '').validate(), isNull);
      expect(
        thread(content: '').validate(forPublication: true),
        contains('text'),
      );
      expect(
        thread(
          type: HabiThreadType.projectShowcase,
          title: '',
          content: 'Work',
        ).copyWith(clearPortfolioProject: true).validate(forPublication: true),
        contains('title or attach'),
      );
    },
  );

  test('validates supported HTTPS URLs and content length', () {
    expect(
      thread(externalUrl: 'http://example.org').validate(),
      contains('HTTPS'),
    );
    expect(thread(externalUrl: 'https://').validate(), contains('HTTPS'));
    expect(
      thread(title: List.filled(161, 'x').join()).validate(),
      contains('160'),
    );
    expect(
      thread(content: List.filled(10001, 'x').join()).validate(),
      contains('10,000'),
    );
  });

  test('normalizes and deduplicates tags on serialization', () {
    final data = thread()
        .copyWith(
          skills: const [' Flutter ', 'Flutter', ''],
          topics: const ['#Inclusive Tech', 'Inclusive Tech'],
        )
        .toFirestore();

    expect(data['skills'], ['Flutter']);
    expect(data['topics'], ['Inclusive Tech']);
  });

  test('rejects unknown stored category or publication state', () {
    expect(
      () => HabiThread.fromFirestore('bad', {
        ...thread().toFirestore(),
        'contentType': 'unsupported',
      }),
      throwsFormatException,
    );
  });

  test('comment content is required and bounded', () {
    const valid = HabiComment(
      id: 'comment-1',
      postId: 'thread-1',
      authorUid: 'seeker-1',
      authorName: 'Maria',
      body: 'Helpful insight.',
      createdAt: null,
      updatedAt: null,
    );

    expect(valid.validate(), isNull);
    expect(
      HabiComment(
        id: valid.id,
        postId: valid.postId,
        authorUid: valid.authorUid,
        authorName: valid.authorName,
        body: ' ',
        createdAt: null,
        updatedAt: null,
      ).validate(),
      contains('comment'),
    );
    expect(
      HabiComment(
        id: valid.id,
        postId: valid.postId,
        authorUid: valid.authorUid,
        authorName: valid.authorName,
        body: List.filled(2001, 'x').join(),
        createdAt: null,
        updatedAt: null,
      ).validate(),
      contains('2,000'),
    );
  });
}
