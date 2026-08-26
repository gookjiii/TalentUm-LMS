/// The review state of a submitted assignment from the teacher's perspective.
enum SubmissionFilter { all, needsReview, graded }

/// A submission is complete as soon as it has a grade.
///
/// Older documents only stored the `status` field, so it remains a fallback
/// while all newly graded submissions store both fields.
bool isSubmissionGraded(Map<String, dynamic> submission) {
  return submission['grade'] != null || submission['status'] == 'graded';
}

bool matchesSubmissionFilter(
  Map<String, dynamic> submission,
  SubmissionFilter filter,
) {
  switch (filter) {
    case SubmissionFilter.all:
      return true;
    case SubmissionFilter.needsReview:
      return !isSubmissionGraded(submission);
    case SubmissionFilter.graded:
      return isSubmissionGraded(submission);
  }
}
