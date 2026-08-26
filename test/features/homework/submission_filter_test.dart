import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_world/src/features/homework/domain/submission_filter.dart';
import 'package:school_world/src/firebase/school_repository_assignments.dart';

void main() {
  group('submission review filtering', () {
    test('keeps ungraded work in the review queue', () {
      expect(
        matchesSubmissionFilter({
          'status': 'submitted',
        }, SubmissionFilter.needsReview),
        isTrue,
      );
    });

    test('recognises legacy graded status and new numeric grades', () {
      expect(
        matchesSubmissionFilter({'status': 'graded'}, SubmissionFilter.graded),
        isTrue,
      );
      expect(
        matchesSubmissionFilter({'grade': 0}, SubmissionFilter.graded),
        isTrue,
      );
    });
  });

  group('submission grade validation', () {
    test(
      'only accepts finite percentage grades from zero through one hundred',
      () {
        expect(isValidSubmissionGrade(0), isTrue);
        expect(isValidSubmissionGrade(100), isTrue);
        expect(isValidSubmissionGrade(-0.1), isFalse);
        expect(isValidSubmissionGrade(100.1), isFalse);
        expect(isValidSubmissionGrade(double.nan), isFalse);
      },
    );
  });

  test('grading persists a complete review in Firestore', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('submissions').doc('submission-1').set({
      'status': 'submitted',
      'studentId': 'student-1',
    });
    final repository = _AssignmentsRepository(
      firestore: firestore,
      uid: 'teacher-1',
    );

    await repository.gradeSubmission(
      submissionId: 'submission-1',
      grade: 92.5,
      feedback: '  Great work!  ',
    );

    final data =
        (await firestore.collection('submissions').doc('submission-1').get())
            .data()!;
    expect(data['grade'], 92.5);
    expect(data['feedback'], 'Great work!');
    expect(data['status'], 'graded');
    expect(data['gradedBy'], 'teacher-1');
    expect(data['gradedAt'], isA<Timestamp>());
    expect(data['updatedAt'], isA<Timestamp>());
  });
}

class _AssignmentsRepository with SchoolRepositoryAssignments {
  _AssignmentsRepository({required this.firestore, required this.uid});

  @override
  final FirebaseFirestore firestore;

  @override
  final String? uid;

  @override
  FirebaseFunctions get functions => throw UnimplementedError();
}
