import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habi/data/account_store.dart';
import 'package:habi/features/jobs/application_resume_dialog.dart';

void main() {
  testWidgets('application can be submitted without selecting a resume', (
    tester,
  ) async {
    bool? confirmed;
    final account = Account(
      uid: 'seeker-1',
      firstName: 'Jamie',
      lastName: 'Reyes',
      birthDate: DateTime(2000),
      sex: 'Prefer not to say',
      email: 'jamie@example.com',
      mobile: '09170000000',
      address: 'Manila',
      cityProvince: 'Manila',
      barangay: 'Barangay 1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => ApplicationResumeDialog(
                    account: account,
                    companyName: 'Inclusive Employer',
                  ),
                );
              },
              child: const Text('Open application'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open application'));
    await tester.pumpAndSettle();

    final submit = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Submit application'),
    );
    expect(submit.onPressed, isNotNull);
    expect(
      find.textContaining('attachments are temporarily unavailable'),
      findsOneWidget,
    );

    await tester.tap(find.text('Submit application'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });
}
