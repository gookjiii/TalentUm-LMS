// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get yourClassroomConnected => 'Your classroom,\nconnected.';

  @override
  String get onboardingWelcomeDesc =>
      'School World brings together chat, homework, and announcements so you never miss a thing your teachers post.';

  @override
  String get getStarted => 'Get started';

  @override
  String get whoIsJoining => 'Who\'s joining today?';

  @override
  String get pickRoleDesc =>
      'Pick your role. We will tailor the app to what you do most.';

  @override
  String get student => 'Student';

  @override
  String get studentDesc => 'Join classes, chat, submit homework';

  @override
  String get teacher => 'Teacher';

  @override
  String get teacherDesc => 'Manage classes, post and pin materials';

  @override
  String get parent => 'Parent / Guardian';

  @override
  String get parentDesc => 'Follow your child\'s progress and grades';

  @override
  String continueAs(String role) {
    return 'Continue as $role';
  }

  @override
  String get chooseYourClasses => 'Choose your classes';

  @override
  String get inviteCodeDesc =>
      'Enter your school invite code to preview and join your class.';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get previewClass => 'Preview class';

  @override
  String get joinClass => 'Join class';

  @override
  String get cancel => 'Cancel';

  @override
  String get join => 'Join';

  @override
  String get signOut => 'Sign out';

  @override
  String get today => 'Today';

  @override
  String get chat => 'Chat';

  @override
  String get feed => 'Feed';

  @override
  String get homework => 'Homework';

  @override
  String get profile => 'Profile';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get sendCode => 'Send Code';

  @override
  String get verify => 'Verify';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create an account';

  @override
  String get otp => 'OTP';

  @override
  String get password => 'Password';

  @override
  String get enterPhoneError => 'Please enter your phone number.';

  @override
  String get enterOtpError => 'Enter the 6-digit code.';

  @override
  String get teacherWorkspace => 'Teacher workspace';

  @override
  String get createClass => 'Create class';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get russian => 'Russian';

  @override
  String get joinAClass => 'Join a class';

  @override
  String get inviteCodeNotFound => 'Invite code not found.';

  @override
  String hiName(String name) {
    return 'Hi, $name';
  }

  @override
  String get todaysClasses => 'Today\'s classes';

  @override
  String get quickLinks => 'Quick links';

  @override
  String get homeworkPortal => 'Homework Portal';

  @override
  String get myGrades => 'My Grades';

  @override
  String get notifications => 'Notifications';

  @override
  String get classRoster => 'Class roster';

  @override
  String learningStreak(int count) {
    return '$count-day learning streak';
  }

  @override
  String homeworksDone(int done, int total) {
    return '$done of $total homeworks done today';
  }

  @override
  String get selected => 'Selected';

  @override
  String get pickClassToChat => 'Pick a class to chat.';

  @override
  String get noMessagesYet => 'No messages yet.';

  @override
  String get messageYourClass => 'Message your class';

  @override
  String get send => 'Send';

  @override
  String get classChat => 'Class chat';

  @override
  String get classRoom => 'Class room';

  @override
  String studentsCount(int count) {
    return '$count students';
  }

  @override
  String get searchMessages => 'Search messages';

  @override
  String get you => 'You';

  @override
  String get classmate => 'Classmate';

  @override
  String get pickClassToReadAnnouncements =>
      'Pick a class to read announcements.';

  @override
  String get noAnnouncementsYet => 'No announcements yet.';

  @override
  String get teacherUpdate => 'Teacher update';

  @override
  String get announcement => 'Announcement';

  @override
  String get pinned => 'Pinned';

  @override
  String get commentsSoon => 'Comments soon';

  @override
  String get pickClassToViewHomework => 'Pick a class to view homework.';

  @override
  String get noHomeworkAssigned => 'No homework assigned.';

  @override
  String get assignment => 'Assignment';

  @override
  String get submit => 'Submit';

  @override
  String get studentAccount => 'Student account';

  @override
  String get joinAnotherClass => 'Join another class';

  @override
  String get inviteCodeFromTeacher => 'Use an invite code from a teacher';

  @override
  String get unreadUpdates => 'Unread class updates and reminders';

  @override
  String get privacyAndSafety => 'Privacy and safety';

  @override
  String get protectedFiles => 'Class-only messaging and protected files';

  @override
  String get submitHomework => 'Submit homework';

  @override
  String get notes => 'Notes';

  @override
  String get addNoteForTeacher => 'Add a short note for your teacher';

  @override
  String get joinYourFirstClass => 'Join your first class';

  @override
  String get joinFirstClassDesc =>
      'Use a teacher invite code to unlock chat, feed, and homework.';

  @override
  String get noDueDate => 'No due date';

  @override
  String due(String date) {
    return 'Due $date';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get post => 'Post';

  @override
  String get work => 'Work';

  @override
  String get createPost => 'Create post';

  @override
  String get createAssignment => 'Create assignment';

  @override
  String get noClassMessages => 'No class messages yet.';

  @override
  String get messageThisClass => 'Message this class';

  @override
  String get noPostsYet => 'No posts yet.';

  @override
  String get unpin => 'Unpin';

  @override
  String get pin => 'Pin';

  @override
  String get noAssignmentsYet => 'No assignments yet.';

  @override
  String get createYourFirstClass => 'Create your first class';

  @override
  String get teacherEmptyDesc =>
      'Classes include invite codes for student and parent onboarding.';

  @override
  String get className => 'Class name';

  @override
  String get subject => 'Subject';

  @override
  String get create => 'Create';

  @override
  String get title => 'Title';

  @override
  String get instructions => 'Instructions';

  @override
  String get dueDate => 'Due date';

  @override
  String get parentDashboard => 'Parent Dashboard';

  @override
  String get noClassesLinked => 'No classes linked.';

  @override
  String teacherLabel(String name) {
    return 'Teacher: $name';
  }

  @override
  String get grade => 'Grade';

  @override
  String get submitted => 'Submitted';

  @override
  String get notSubmitted => 'Not submitted';

  @override
  String get noGradesYet => 'No grades yet.';

  @override
  String get noSubmissionsYet => 'No submissions yet.';

  @override
  String get ungraded => 'Ungraded';

  @override
  String get gradeSubmission => 'Grade submission';

  @override
  String get feedback => 'Feedback';

  @override
  String get save => 'Save';

  @override
  String get name => 'Name';

  @override
  String get overdue => 'Overdue';

  @override
  String get classStatistics => 'Class Statistics';

  @override
  String get totalStudents => 'Total Students';

  @override
  String get avgGrade => 'Avg. Grade';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get noStudentsInClass => 'No students in this class yet.';

  @override
  String get assignments => 'Assignments';

  @override
  String get errorGeneric => 'An error occurred. Please try again.';

  @override
  String get recurring => 'Recurring';

  @override
  String get oneOff => 'One-off';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get savedSchedule => 'Saved schedule!';

  @override
  String get deleteSchedule => 'Delete schedule?';

  @override
  String get deleteScheduleDesc =>
      'This will remove the slot and its overrides.';

  @override
  String get deletedSchedule => 'Deleted schedule';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get avatarUpdated => 'Avatar updated successfully';

  @override
  String failedToUploadAvatar(Object error) {
    return 'Failed to upload avatar: $error';
  }

  @override
  String get nameEmptyError => 'Name cannot be empty';

  @override
  String get profileUpdatedDesc => 'Profile updated successfully';

  @override
  String failedToUpdateProfile(Object error) {
    return 'Failed to update profile: $error';
  }

  @override
  String get confirmSignOut => 'Are you sure you want to sign out?';

  @override
  String get previewClassAction => 'Preview Class';

  @override
  String get skipOnboardingTeacher => 'I\'m a teacher, skip this step';

  @override
  String get needsReviewToday => 'Needs review today';

  @override
  String studentSubmissions(int count) {
    return '$count student submissions';
  }

  @override
  String get noClassesScheduled => 'No classes scheduled for today';

  @override
  String get openWeeklySchedule => 'Open weekly schedule';

  @override
  String get quickActions => 'QUICK ACTIONS';

  @override
  String get postAnnouncement => 'Post announcement';

  @override
  String get pinWorksheet => 'Pin worksheet';

  @override
  String get takeAttendance => 'Take attendance';

  @override
  String get gradeSubmissions => 'Grade submissions';

  @override
  String get copyGuestChatLink => 'Copy guest chat link';

  @override
  String get deleteClass => 'Delete class';

  @override
  String get unpinPost => 'Unpin post';

  @override
  String get pinPost => 'Pin post';

  @override
  String get deletePost => 'Delete post';

  @override
  String get deletePostDesc =>
      'This post and its comments will be permanently removed.';

  @override
  String get publishPost => 'Publish post';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get couldNotOpenAttachment => 'Could not open attachment.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get assignmentNotFound => 'Assignment not found';

  @override
  String submissionFailed(String error) {
    return 'Submission failed: $error';
  }

  @override
  String get submitting => 'Submitting...';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get studentPortalTerm3 => 'Student Portal · Term 3';

  @override
  String get generalSettings => 'GENERAL SETTINGS';

  @override
  String get accountAndClasses => 'ACCOUNT & CLASSES';

  @override
  String get helpAndAbout => 'HELP & ABOUT';

  @override
  String get addNote => 'Add a new classroom code';

  @override
  String get viewAll => 'View all';

  @override
  String get live => 'LIVE';

  @override
  String get done => 'DONE';

  @override
  String get upcoming => 'UPCOMING';

  @override
  String inMin(int min) {
    return 'IN $min MIN';
  }

  @override
  String get cancelled => 'CANCELLED';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get teacherAttachments => 'Teacher attachments';

  @override
  String get reply => 'Reply';

  @override
  String get copyText => 'Copy Text';

  @override
  String get delete => 'Delete';

  @override
  String get freePlan => 'Free';

  @override
  String get currentPlan => 'Your current plan';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get soonAvailable => 'Coming soon';

  @override
  String get contactSupportForEmail => 'To change email, contact support';

  @override
  String get noConnection => 'No connection';

  @override
  String get newTopic => 'New topic';

  @override
  String get joinLessonSoon => 'Join lesson will be available soon';

  @override
  String get now => 'NOW';

  @override
  String get later => 'LATER';

  @override
  String get allChecked => 'All checked!';

  @override
  String get selectClassFirst => 'Select a class first.';

  @override
  String get classNotFound => 'Class not found.';

  @override
  String get removeFromClass => 'Remove from class?';

  @override
  String get removeFromClassDesc =>
      'The student will lose access to materials and chat of this class.';

  @override
  String get badges => 'Badges';

  @override
  String get copyInviteLink => 'Copy invite link';

  @override
  String get clearChat => 'Clear Chat';

  @override
  String get teacherBadge => 'TEACHER';

  @override
  String totalParticipants(int count) {
    return '$count total participants';
  }

  @override
  String get active => 'ACTIVE';

  @override
  String publishedAt(String date) {
    return 'Published: $date';
  }

  @override
  String submittedAtLabel(String date) {
    return 'Submitted: $date';
  }

  @override
  String get deleteAssignment => 'Delete assignment?';

  @override
  String get deleteAssignmentDesc =>
      'All submitted works for this assignment will also be removed.';

  @override
  String get editAssignment => 'Edit assignment';

  @override
  String get bookmarksSoon => 'Bookmarks will appear in the next update';

  @override
  String get initializationFailed => 'Initialization failed.';

  @override
  String get topics => 'Topics';

  @override
  String get mainChat => 'General Chat';

  @override
  String get createTopic => 'Create Topic';

  @override
  String get myClasses => 'MY CLASSES';

  @override
  String get teacherConsole => 'Teacher Console';
}
