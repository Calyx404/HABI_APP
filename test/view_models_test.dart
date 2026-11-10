import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habi/data/account_store.dart';
import 'package:habi/data/message_store.dart';
import 'package:habi/data/repositories/support_repository.dart';
import 'package:habi/data/repositories/user_settings_repository.dart';
import 'package:habi/features/messaging/messages_view_model.dart';
import 'package:habi/features/settings/settings_view_model.dart';
import 'package:habi/features/settings/seeker_settings_view_model.dart';
import 'package:habi/features/support/support_view_model.dart';

void main() {
  group('ChatViewModel', () {
    test('trims and sends a message once', () async {
      final sender = _FakeSender();
      final viewModel = ChatViewModel(
        repository: sender,
        conversationId: 'job-1-seeker-1',
        senderName: 'Alex',
      );

      expect(await viewModel.send('  Hello there  '), isTrue);
      expect(sender.sent, [('job-1-seeker-1', 'Alex', 'Hello there')]);
      expect(viewModel.isSending, isFalse);
      viewModel.dispose();
    });

    test(
      'does not send blank messages and reports repository failures',
      () async {
        final sender = _FakeSender()..failure = StateError('offline');
        final viewModel = ChatViewModel(
          repository: sender,
          conversationId: 'conversation-1',
          senderName: 'Alex',
        );

        expect(await viewModel.send('  '), isFalse);
        expect(sender.sent, isEmpty);
        expect(await viewModel.send('Hello'), isFalse);
        expect(viewModel.error, contains('offline'));
        expect(viewModel.isSending, isFalse);
        viewModel.dispose();
      },
    );
  });

  group('SettingsViewModel', () {
    test('loads saved preferences and persists changes', () async {
      final repository = _FakeSettingsRepository()
        ..values = {'jobAlerts': false};
      final viewModel = SettingsViewModel(
        repository: repository,
        userId: 'user-1',
      );

      expect(await viewModel.load(), isTrue);
      expect(viewModel.value('jobAlerts'), isFalse);
      expect(await viewModel.setValue('messages', false), isTrue);
      expect(repository.values['messages'], isFalse);
      viewModel.dispose();
    });

    test('restores the prior value when persistence fails', () async {
      final repository = _FakeSettingsRepository()
        ..failure = StateError('denied');
      final viewModel = SettingsViewModel(
        repository: repository,
        userId: 'user-1',
      );

      expect(viewModel.value('jobAlerts'), isTrue);
      expect(await viewModel.setValue('jobAlerts', false), isFalse);
      expect(viewModel.value('jobAlerts'), isTrue);
      expect(viewModel.error, contains('denied'));
      viewModel.dispose();
    });

    test('saves profile visibility through the account repository', () async {
      final accountRepository = _FakeAccountRepository(_account());
      final viewModel = SettingsViewModel(
        repository: _FakeSettingsRepository(),
        userId: 'user-1',
        accountRepository: accountRepository,
      );

      expect(await viewModel.setProfileVisible(false), isTrue);
      expect(accountRepository.current?.visibility, isFalse);
      expect(accountRepository.saveCount, 1);
      viewModel.dispose();
      accountRepository.dispose();
    });
  });

  test('SeekerSettingsViewModel reports account save failures', () async {
    final repository = _FakeAccountRepository(_account())
      ..failure = StateError('permission-denied');
    final viewModel = SeekerSettingsViewModel(repository: repository);

    expect(await viewModel.saveProfile(), isFalse);
    expect(viewModel.error, contains('permission-denied'));
    viewModel.dispose();
    repository.dispose();
  });

  test('SupportViewModel validates and submits a support request', () async {
    final repository = _FakeSupportRepository();
    final viewModel = SupportViewModel(repository: repository);

    expect(
      await viewModel.submit(subject: 'Using the app', message: '  '),
      isFalse,
    );
    expect(repository.requests, isEmpty);
    expect(
      await viewModel.submit(
        subject: 'Using the app',
        message: 'I need help with my profile.',
      ),
      isTrue,
    );
    expect(repository.requests, [
      ('Using the app', 'I need help with my profile.'),
    ]);
    viewModel.dispose();
  });
}

Account _account() => Account(
  uid: 'user-1',
  firstName: 'Alex',
  lastName: 'Santos',
  birthDate: DateTime(2000),
  sex: 'Prefer not to say',
  email: 'alex@example.com',
  mobile: '09171234567',
  address: 'Address',
  cityProvince: 'Manila',
  barangay: 'Barangay 1',
);

class _FakeSender implements MessageSender {
  Object? failure;
  final sent = <(String, String, String)>[];

  @override
  Future<void> send(
    String conversationId,
    String senderName,
    String text,
  ) async {
    if (failure case final error?) throw error;
    sent.add((conversationId, senderName, text));
  }
}

class _FakeSettingsRepository implements UserSettingsRepository {
  Map<String, Object?> values = {};
  Object? failure;

  @override
  Future<Map<String, Object?>> load(String userId) async => values;

  @override
  Future<void> save(String userId, Map<String, Object?> values) async {
    if (failure case final error?) throw error;
    this.values.addAll(values);
  }
}

class _FakeAccountRepository extends ChangeNotifier
    implements AccountRepository {
  _FakeAccountRepository(this.current);

  @override
  Account? current;
  Object? failure;
  int saveCount = 0;

  @override
  Future<void> saveCurrent() async {
    if (failure case final error?) throw error;
    saveCount++;
  }
}

class _FakeSupportRepository implements SupportRepository {
  final requests = <(String, String)>[];

  @override
  Future<void> submit({
    required String subject,
    required String message,
  }) async {
    requests.add((subject, message));
  }
}
