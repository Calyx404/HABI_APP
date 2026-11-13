import 'package:flutter_test/flutter_test.dart';
import 'package:habi/data/job_store.dart';

void main() {
  test(
    'recruitment status transitions keep shortlist separate from interview',
    () {
      expect(
        canTransitionApplicationStatus('Submitted', 'Under Review'),
        isTrue,
      );
      expect(
        canTransitionApplicationStatus('Submitted', 'Shortlisted'),
        isFalse,
      );
      expect(
        canTransitionApplicationStatus('Under Review', 'Shortlisted'),
        isTrue,
      );
      expect(
        canTransitionApplicationStatus('Shortlisted', 'Interview Scheduled'),
        isTrue,
      );
    },
  );

  test('interview cancellation returns the applicant to shortlisted', () {
    expect(
      canTransitionApplicationStatus('Interview Scheduled', 'Shortlisted'),
      isTrue,
    );
    expect(
      canTransitionApplicationStatus(
        'Interview Scheduled',
        'Interview Completed',
      ),
      isTrue,
    );
  });

  test(
    'legacy interview status is presented using the structured stage name',
    () {
      expect(applicationStatusLabel('Interview'), 'Interview Scheduled');
    },
  );
}
