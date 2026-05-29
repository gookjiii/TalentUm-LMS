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
  String get onboardingWelcomeDesc => 'School World brings together chat, homework, and announcements so you never miss a thing your teachers post.';

  @override
  String get getStarted => 'Get started';

  @override
  String get whoIsJoining => 'Who\'s joining today?';

  @override
  String get pickRoleDesc => 'Pick your role. We will tailor the app to what you do most.';

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
  String get inviteCodeDesc => 'Enter your school invite code to preview and join your class.';

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
  String get pickClassToReadAnnouncements => 'Pick a class to read announcements.';

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
  String get joinFirstClassDesc => 'Use a teacher invite code to unlock chat, feed, and homework.';

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
  String get teacherEmptyDesc => 'Classes include invite codes for student and parent onboarding.';

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
  String get deleteScheduleDesc => 'This will remove the slot and its overrides.';

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
  String get deletePostDesc => 'This post and its comments will be permanently removed.';

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
  String get removeFromClassDesc => 'The student will lose access to materials and chat of this class.';

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
  String get deleteAssignmentDesc => 'All submitted works for this assignment will also be removed.';

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

  @override
  String get coolMagazine => 'Cool magazine';

  @override
  String get myGradesAndSubjects => 'My grades and subjects';

  @override
  String get academicPerformanceAndSubjects => 'Academic performance and subjects';

  @override
  String get addALesson => 'Add a lesson';

  @override
  String get ratings => 'Ratings';

  @override
  String get items => 'Items';

  @override
  String get date => 'Date';

  @override
  String get item => 'Item';

  @override
  String get unknownKey => 'Отмена';

  @override
  String get noLessonsAddYourFirst => 'No lessons. Add your first lesson!';

  @override
  String get noTheme => 'No theme';

  @override
  String get january => 'JANUARY';

  @override
  String get february => 'FEBRUARY';

  @override
  String get martha => 'MARTHA';

  @override
  String get april => 'APRIL';

  @override
  String get may => 'MAY';

  @override
  String get june => 'JUNE';

  @override
  String get july => 'JULY';

  @override
  String get august => 'AUGUST';

  @override
  String get september => 'SEPTEMBER';

  @override
  String get october => 'OCTOBER';

  @override
  String get november => 'NOVEMBER';

  @override
  String get december => 'DECEMBER';

  @override
  String get editLesson => 'Edit lesson';

  @override
  String get deleteLesson => 'Delete lesson?';

  @override
  String get thisActionCannotBeUndone => 'This action cannot be undone.';

  @override
  String get youDontHaveRatingsYet => 'You don\'t have ratings yet.';

  @override
  String get theMagazineIsEmptyAdd => 'The magazine is empty. Add your first lesson!';

  @override
  String get myRatings => 'My ratings';

  @override
  String get unknownKey1 => 'Загрузка...';

  @override
  String get n => 'n';

  @override
  String get rate => 'Rate';

  @override
  String get unknownKey2 => 'Отлично';

  @override
  String get unknownKey3 => 'Хорошо';

  @override
  String get unknownKey4 => 'Удовлетворительно';

  @override
  String get unknownKey5 => 'Плохо';

  @override
  String get n1 => 'N';

  @override
  String get absent => 'Absent';

  @override
  String get clearMark => 'Clear mark';

  @override
  String get adminPanel => 'Admin panel';

  @override
  String get systemManagementAndActivityAnalytics => 'System management and activity analytics';

  @override
  String get totalUsers => 'Total users';

  @override
  String get activeChats => 'Active chats';

  @override
  String get postsToday => 'Posts today';

  @override
  String get appBranding => 'App branding';

  @override
  String get quickActions1 => 'Quick Actions';

  @override
  String get users => 'Users';

  @override
  String get roleManagementAndBan => 'Role management and ban';

  @override
  String get allClasses => 'All classes';

  @override
  String get reviewAndModeration => 'Review and moderation';

  @override
  String get applicationsForTeachers => 'Applications for teachers';

  @override
  String get moderationOfRequests => 'Moderation of requests';

  @override
  String get latestUsers => 'Latest users';

  @override
  String get noData => 'No data';

  @override
  String get registered => 'registered';

  @override
  String get recently => 'recently';

  @override
  String get logoLoaded => 'Logo loaded';

  @override
  String get applicationName => 'Application name';

  @override
  String get enterAName => 'Enter a name';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get saveChanges1 => 'Save changes';

  @override
  String get searchByNameEmailOr => 'Search by name, email or ID...';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get unknownKey6 => 'Без имени';

  @override
  String get noEmail => 'No email';

  @override
  String get makeAdmin => 'Make admin';

  @override
  String get makeItATeacher => 'Make it a teacher';

  @override
  String get makeAStudent => 'Make a student';

  @override
  String get block => 'Block';

  @override
  String get unblock => 'Unblock';

  @override
  String get teachersLicenseIssued => 'Teacher\'s license issued';

  @override
  String get applicationRejected => 'Application rejected';

  @override
  String get noApplications => 'No applications';

  @override
  String get allRequestsProcessed => 'All requests processed';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get assignATeacher => 'Assign a teacher';

  @override
  String get classManagement => 'Class Management';

  @override
  String get createClasses => 'Create classes';

  @override
  String get searchByTitleOrSubject => 'Search by title or subject...';

  @override
  String get noClassesFound => 'No classes found';

  @override
  String get unknownKey7 => 'Без названия';

  @override
  String get n57 => 'Школа №57';

  @override
  String get experience => 'EXPERIENCE';

  @override
  String get personalInformation => 'Personal information';

  @override
  String get linkedAccounts => 'Linked accounts';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get allowedForChatAndTasks => 'Allowed for chat and tasks';

  @override
  String get newMessages => 'New messages';

  @override
  String get soundVibration => 'Sound + vibration';

  @override
  String get updates => 'Updates';

  @override
  String get quietMode22000700 => 'Quiet mode: 22:00–07:00';

  @override
  String get confidentiality => 'Confidentiality';

  @override
  String get showNameToStudents => 'Show name to students';

  @override
  String get personalMessages => 'Personal messages';

  @override
  String get allowStudentsToWriteDirectly => 'Allow students to write directly';

  @override
  String get registration => 'Registration';

  @override
  String get enabled => 'Enabled';

  @override
  String get system => 'System';

  @override
  String get accentColor => 'Accent color';

  @override
  String get schoolBlue => 'School blue';

  @override
  String get russianRu => 'Russian (ru)';

  @override
  String get tariffPlan => 'Tariff plan';

  @override
  String get safety => 'Safety';

  @override
  String get twofactorProtection => 'Two-factor protection';

  @override
  String get enabledAuthenticator => 'Enabled Authenticator';

  @override
  String get actively => 'Actively';

  @override
  String get downloadMyData => 'Download my data';

  @override
  String get exportToZip => 'Export to ZIP';

  @override
  String get emailpassword => 'Email/Password';

  @override
  String get ready => 'Ready';

  @override
  String get related => 'Related';

  @override
  String get notRelated => 'Not related';

  @override
  String get languageChangedToRussian => 'Language changed to Russian';

  @override
  String get preparingAZipArchive => 'Preparing a ZIP archive...';

  @override
  String get exportData => 'Export data';

  @override
  String get aZipArchiveWillBe => 'A ZIP archive will be created containing all of your personal data, including classes you\'ve created, homework assignments, chat messages, and profile.';

  @override
  String get theArchiveWasSuccessfullySaved => 'The archive was successfully saved to the Downloads folder';

  @override
  String get export => 'Export';

  @override
  String get verified => 'Verified';

  @override
  String get postDeleted => 'Post deleted';

  @override
  String get voiceMessage => 'Voice message';

  @override
  String get teachersRoom => 'Teacher\'s room';

  @override
  String get classNotFound1 => 'Class not found';

  @override
  String get unknownKey8 => 'Чат класса';

  @override
  String get participant => 'Participant';

  @override
  String get newPoll => 'New poll';

  @override
  String get question => 'Question';

  @override
  String get addAnOption => 'Add an option';

  @override
  String get attachment => 'Attachment';

  @override
  String get deleteMessage => 'Delete message?';

  @override
  String get areYouSureYouWant => 'Are you sure you want to delete this message?';

  @override
  String get change => 'Change';

  @override
  String get image => '📷 Image';

  @override
  String get file => '📎 File';

  @override
  String get deleteTopic => 'Delete topic?';

  @override
  String get teachersRoom1 => 'teacher\'s room';

  @override
  String get chats => 'Chats';

  @override
  String get searchChats => 'Search chats...';

  @override
  String get noChatsFound => 'No chats found';

  @override
  String get errorLoadingMessage => 'Error loading message';

  @override
  String get noMessagesYet1 => 'No messages yet';

  @override
  String get photography => '📷 Photography';

  @override
  String get video => '🎥 Video';

  @override
  String get file1 => '📁 File';

  @override
  String get voiceMessage1 => '🎤 Voice message';

  @override
  String get clickToOpenChat => 'Click to open chat';

  @override
  String get changed => 'changed';

  @override
  String get sender => 'Sender';

  @override
  String get replyToAMessage => 'Reply to a message';

  @override
  String get messageText => 'Message text';

  @override
  String get survey => 'SURVEY';

  @override
  String get closed => 'CLOSED';

  @override
  String get ov => 'ov';

  @override
  String get a => 'A';

  @override
  String get replyToMessage => 'REPLY TO MESSAGE';

  @override
  String get editing => 'EDITING';

  @override
  String get failedToLoadVideo => 'Failed to load video';

  @override
  String get video1 => 'Video';

  @override
  String get attach => 'Attach';

  @override
  String get camera => 'Camera';

  @override
  String get survey1 => 'Survey';

  @override
  String get message => 'Message';

  @override
  String get editMessage => 'Edit message';

  @override
  String get holdToRecordVoice => 'Hold to record voice';

  @override
  String get micPermissionDenied => 'Microphone permission denied. Please enable it in device settings.';

  @override
  String get releaseToView => 'Release to view';

  @override
  String get printing => 'Printing...';

  @override
  String get failedToOpenCallRoom => 'Failed to open call room';

  @override
  String get clearChat1 => 'Clear chat';

  @override
  String get areYouSureYouWant1 => 'Are you sure you want to clear all Teacher\'s chat history? This action cannot be undone.';

  @override
  String get clear => 'Clear';

  @override
  String get clearingChat => 'Clearing chat...';

  @override
  String get teachersChatHasBeenSuccessfully => 'Teacher\'s chat has been successfully cleared';

  @override
  String get back => 'Back';

  @override
  String get chatTopics => 'Chat topics';

  @override
  String get search => 'Search...';

  @override
  String get chatInformation => 'Chat information';

  @override
  String get call => 'Call';

  @override
  String get participants => 'Participants';

  @override
  String get mediaAndFiles => 'Media and files';

  @override
  String get searchMessages1 => 'Search messages...';

  @override
  String get startAVideoCall => 'Start a video call';

  @override
  String get clearTeachersChat => 'Clear Teacher\'s chat';

  @override
  String get photo => 'Photo';

  @override
  String get pinnedMessage => 'Pinned message';

  @override
  String get pinnedMessages => 'Pinned messages';

  @override
  String get noPinnedMessages => 'No pinned messages';

  @override
  String get toResources => 'To resources';

  @override
  String get resources => 'Resources';

  @override
  String get media => 'Media';

  @override
  String get files => 'Files';

  @override
  String get links => 'Links';

  @override
  String get polls => 'Polls';

  @override
  String get ai => 'AI';

  @override
  String get thereWasNoMediaYet => 'There was no media yet';

  @override
  String get thereAreNoFilesYet => 'There are no files yet';

  @override
  String get file2 => 'File';

  @override
  String get view => 'View';

  @override
  String get open => 'Open';

  @override
  String get thereAreNoLinksYet => 'There are no links yet';

  @override
  String get roomNotFound => 'Room not found';

  @override
  String get noParticipantsYet => 'No participants yet';

  @override
  String get administrator => 'Administrator';

  @override
  String get parent1 => 'Parent';

  @override
  String get removeAdmin => 'Remove admin';

  @override
  String get areYouSureYouWant2 => 'Are you sure you want to remove this student from the class?';

  @override
  String get cancellation => 'CANCELLATION';

  @override
  String get delete1 => 'DELETE';

  @override
  String get thereAreNoPollsYet => 'There are no polls yet';

  @override
  String get helloImYourTeachingAssistant => 'Hello! I\'m your teaching assistant. I can help you understand the materials for this class. Ask!';

  @override
  String get interestingQuestionBasedOnThe => 'Interesting question! Based on the class materials, I can say that this aspect is very important for understanding the topic. I recommend paying attention to the second chapter of the textbook.';

  @override
  String get askAi => 'Ask AI...';

  @override
  String get todaysGoalAchieved => 'Today\'s goal achieved';

  @override
  String get completeTheTaskSoAs => 'Complete the task so as not to break the streak';

  @override
  String get noLessonsForToday => 'No lessons for today';

  @override
  String get library => 'Library';

  @override
  String get webinars => 'Webinars';

  @override
  String get areYouReadyFornnewKnowledge => 'Are you ready for\\nnew knowledge?';

  @override
  String get canceled => 'CANCELED';

  @override
  String get soon => 'SOON';

  @override
  String get quickLinks1 => 'QUICK LINKS';

  @override
  String get magazine => 'Magazine';

  @override
  String get studentAnswer => 'Student answer:';

  @override
  String get attachedFiles => 'Attached files:';

  @override
  String get scoreInOrPoints => 'Score (in % or points)';

  @override
  String get teachersReview => 'Teacher\'s review';

  @override
  String get pleaseEnterAValidRating => 'Please enter a valid rating (number)';

  @override
  String get giveARating => 'Give a rating';

  @override
  String get addAStudent => 'Add a student';

  @override
  String get editName => 'Edit name';

  @override
  String get removeAdminRights => 'Remove admin rights';

  @override
  String get makeAsAdministrator => 'Make as administrator';

  @override
  String get editStudentName => 'Edit student name';

  @override
  String get studentName => 'Student name';

  @override
  String get ivanIvanov => 'Ivan Ivanov';

  @override
  String get unknown => 'unknown';

  @override
  String get administrator1 => 'ADMINISTRATOR';

  @override
  String get student1 => 'STUDENT';

  @override
  String get userNotFound => 'User not found';

  @override
  String get studentEmail => 'Student email';

  @override
  String get unknownKey9 => 'Неизвестный';

  @override
  String get add => 'Add';

  @override
  String get noWebinars => 'No webinars';

  @override
  String get lessonRecordingsAndVideosWill => 'Lesson recordings and videos will be displayed here.';

  @override
  String get deleteWebinar => 'Delete webinar?';

  @override
  String get watchVideo => 'Watch video';

  @override
  String get addAWebinar => 'Add a webinar';

  @override
  String get forExampleLesson1Basics => 'for example: Lesson 1. Basics';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get provideLink => 'Provide link';

  @override
  String get uploadFile => 'Upload file';

  @override
  String get videoLink => 'Video link';

  @override
  String get httpsyoutubecomOrLinkToFile => 'https://youtube.com/... or link to file';

  @override
  String get selectVideoFile => 'Select video file';

  @override
  String get loadingVideo => 'Loading video...';

  @override
  String get pleaseSelectAVideoFile => 'Please select a video file';

  @override
  String get theBuiltinPlayerIsAvailable => 'The built-in player is available in the web version.';

  @override
  String get parentsPanel => 'Parents panel';

  @override
  String get monitoringYourChildrensProgress => 'Monitoring your children\'s progress';

  @override
  String get unknownKey10 => 'А';

  @override
  String get wedPoint => 'Wed. point';

  @override
  String get attendance => 'Attendance';

  @override
  String get quests => 'Quests';

  @override
  String get latestRatings => 'Latest ratings';

  @override
  String get mat => 'Mat';

  @override
  String get rus => 'Rus';

  @override
  String get phys => 'Phys.';

  @override
  String get east => 'East';

  @override
  String get allRatings => 'All ratings';

  @override
  String get tieTheBaby => 'Tie the baby';

  @override
  String get enterYourChildsEmailTo => 'Enter your child\'s Email to link the profile.';

  @override
  String get snap => 'Snap';

  @override
  String get userWithThisEmailWas => 'User with this email was not found';

  @override
  String get theChildIsSuccessfullyAttached => 'The child is successfully attached';

  @override
  String get childrenAreNotAttached => 'Children are not attached';

  @override
  String get useYourChildsCodeTo => 'Use your child\'s code to link your profile';

  @override
  String get creatingClasses => 'Creating classes';

  @override
  String get coolFactory => 'Cool factory';

  @override
  String get enterTheNamesOfThe => 'Enter the names of the classes you want to bulk create.';

  @override
  String get addMore => 'Add more';

  @override
  String get createAllClasses => 'CREATE ALL CLASSES';

  @override
  String get classSettings => 'Class Settings';

  @override
  String get generalSettings1 => 'General settings';

  @override
  String get invitationCode => 'Invitation code';

  @override
  String get unknownKey11 => 'Нет кода';

  @override
  String get studentPermissions => 'Student Permissions';

  @override
  String get allowStudentsToWriteMessages => 'Allow students to write messages in the general chat';

  @override
  String get publicationsInTheFeed => 'Publications in the feed';

  @override
  String get allowStudentsToCreateNews => 'Allow students to create news feed posts';

  @override
  String get moderationOfEntry => 'Moderation of entry';

  @override
  String get requireTeacherApprovalForNew => 'Require teacher approval for new members';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get thisActionCannotBeUndone1 => 'This action cannot be undone. All data will be deleted.';

  @override
  String get changeName => 'Change name';

  @override
  String get deleteAClass => 'Delete a class?';

  @override
  String get allMessagesAssignmentsAndGrades => 'All messages, assignments and grades will be permanently deleted.';

  @override
  String get theLibraryIsEmpty => 'The library is empty';

  @override
  String get studyMaterialsAndLecturesWill => 'Study materials and lectures will be displayed here.';

  @override
  String get deleteMaterial => 'Delete material?';

  @override
  String get addMaterial => 'Add material';

  @override
  String get forExampleLecture1Introduction => 'for example: Lecture 1. Introduction';

  @override
  String get selectFile => 'Select file';

  @override
  String get download => 'Download';

  @override
  String get upcomingSchedule => 'UPCOMING SCHEDULE';

  @override
  String get upcomingTasks => 'UPCOMING TASKS';

  @override
  String get successInTheClass => 'SUCCESS IN THE CLASS';

  @override
  String get adminMode => 'ADMIN MODE';

  @override
  String get logOut => 'Log out';

  @override
  String get upcomingClasses => 'UPCOMING CLASSES';

  @override
  String get noClasses => 'No classes';

  @override
  String get tasksForTesting => 'TASKS FOR TESTING';

  @override
  String get unknownKey12 => 'Без предмета';

  @override
  String get allTasksHaveBeenChecked => 'All tasks have been checked ✨';

  @override
  String get newJob => 'New job';

  @override
  String get studentPortal => 'Student Portal';

  @override
  String get noClass => 'No class';

  @override
  String get n9bClass => '9B class';

  @override
  String get toChangeYourEmailContact => 'To change your email, contact your teacher.';

  @override
  String get useInvitationCode => 'Use invitation code';

  @override
  String get teacherAccess => 'Teacher access';

  @override
  String get requestSent => 'Request sent';

  @override
  String get requestTeacherPermissions => 'Request teacher permissions';

  @override
  String get onlyFromTeachers => 'Only from teachers';

  @override
  String get submitARequestForA => 'Submit a request for a teacher\'s license? An administrator will need to approve it.';

  @override
  String get studyHomework => 'Study · Homework';

  @override
  String get myTasks => 'My tasks';

  @override
  String get searchForTasks => 'Search for tasks...';

  @override
  String get focusMode => 'FOCUS MODE';

  @override
  String get all => 'All';

  @override
  String get waiting => 'Waiting';

  @override
  String get delivered => 'Delivered';

  @override
  String get rated => 'Rated';

  @override
  String get unknownKey13 => 'Задание';

  @override
  String get urgently => 'URGENTLY';

  @override
  String get noDeadline => 'No deadline';

  @override
  String get startNow => 'Start now';

  @override
  String get expired => 'EXPIRED';

  @override
  String get subjectGeneral => 'Subject: general';

  @override
  String get everythingIsDone => 'Everything is done!';

  @override
  String get thereAreNoTasksYet => 'There are no tasks yet.';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get editTask => 'Edit task';

  @override
  String get description => 'Description';

  @override
  String get selectDueDate => 'Select due date';

  @override
  String get deleteTask => 'Delete task?';

  @override
  String get allSubmittedWorkForThis => 'All submitted work for this assignment will also be deleted.';

  @override
  String get completedWorks => 'COMPLETED WORKS';

  @override
  String get filter => 'Filter';

  @override
  String get createATask => 'Create a task';

  @override
  String get jobFiles => 'Job files:';

  @override
  String get noAttachments => 'No attachments';

  @override
  String get attachFiles => 'Attach files';

  @override
  String get pleaseEnterATitleAnd => 'Please enter a title and select a date';

  @override
  String get active1 => 'Active';

  @override
  String get actively1 => 'ACTIVELY';

  @override
  String get exportWillBeAvailableSoon => 'Export will be available soon';

  @override
  String get edit => 'Edit';

  @override
  String get deleteTask1 => 'Delete task';

  @override
  String get published => 'Published: -';

  @override
  String get term => 'Term';

  @override
  String get points => 'Points';

  @override
  String get max => 'Max.';

  @override
  String get status => 'Status';

  @override
  String get verified1 => 'verified';

  @override
  String get noWorkYet => 'No work yet';

  @override
  String get rated1 => 'RATED';

  @override
  String get underCheck => 'UNDER CHECK';

  @override
  String get noTasks => 'No tasks';

  @override
  String get createYourFirstAssignmentFor => 'Create your first assignment for this class.';

  @override
  String get justNow1 => 'just now';

  @override
  String get bookmarksWillAppearInThe => 'Bookmarks will appear in the next update';

  @override
  String get comments => 'Comments';

  @override
  String get noCommentsYet => 'No comments yet.';

  @override
  String get user => 'User';

  @override
  String get addAComment => 'Add a comment...';

  @override
  String get ribbon => 'Ribbon';

  @override
  String get announcementsFromYourTeachers => 'Announcements from your teachers';

  @override
  String get searchByAdvertisements => 'Search by advertisements...';

  @override
  String get thereAreNoAnnouncementsYet => 'There are no announcements yet.';

  @override
  String get declarationsForYourClasses => 'Declarations for your classes';

  @override
  String get newPost => 'New post';

  @override
  String get postAnAnnouncementForClasses => 'Post an announcement for classes...';

  @override
  String get attachAnImage => 'Attach an image';

  @override
  String get pinThisAd => 'Pin this ad';

  @override
  String get publish => 'Publish';

  @override
  String get mySchedule => 'My schedule';

  @override
  String get unknownKey14 => 'Классы';

  @override
  String get dayOfTheWeek => 'Day of the week';

  @override
  String get selectDate => 'Select date';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get officenote => 'Office/note';

  @override
  String get firstSelectAClass => 'First select a class';

  @override
  String get theEndMustBeLater => 'The end must be later than the beginning';

  @override
  String get selectDayOfWeek => 'Select day of week';

  @override
  String get violet => 'Violet';

  @override
  String get emerald => 'Emerald';

  @override
  String get amber => 'Amber';

  @override
  String get scarlet => 'Scarlet';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get aboutTheApplication => 'About the application';

  @override
  String get version => 'Version';

  @override
  String get youWillBeRedirectedTo => 'You will be redirected to the login screen';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get areYouATeacher => 'Are you a teacher?';

  @override
  String get loginAsTeacher => 'Login as teacher';

  @override
  String get enterInvitationCode => 'Enter invitation code';

  @override
  String get codeNotFoundCheckAnd => 'Code not found. Check and try again.';

  @override
  String get pleaseLoginFirst => 'Please login first.';

  @override
  String get schedule => 'Schedule';

  @override
  String get inviteToClass => 'Invite to class';

  @override
  String get showThisQrCodeTo => 'Show this QR code to your students or send them a direct link.';

  @override
  String get close => 'Close';

  @override
  String get linkCopied => 'Link copied!';

  @override
  String get copyLink => 'Copy link';

  @override
  String get chatHistoryCleared => 'Chat history cleared';

  @override
  String get removingAClass => 'Removing a class...';

  @override
  String get classDeletedSuccessfully => 'Class deleted successfully';

  @override
  String get createAClassToOpen => 'Create a class to open this section.';

  @override
  String get youDontHaveAnyClasses => 'You don\'t have any classes yet';

  @override
  String get addStudentsAndGetStarted => 'Add students and get started.';

  @override
  String get waitToBeAddedTo => 'Wait to be added to the class.';

  @override
  String get createAClass => 'Create a class';

  @override
  String get empty => 'Empty';

  @override
  String get newTask => 'New task';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Apr';

  @override
  String get may1 => 'May';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aug';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dec';

  @override
  String get setADeadline => 'Set a deadline';

  @override
  String get yourWork => 'Your work';

  @override
  String get notesForWork => 'Notes for work';

  @override
  String get addFiles => 'Add files';

  @override
  String get pleaseEnterYourEmailAnd => 'Please enter your email and password';

  @override
  String get pleaseFillInAllFields => 'Please fill in all fields';

  @override
  String get enterYourEmailToReset => 'Enter your email to reset your password';

  @override
  String get passwordResetError => 'Password reset error';

  @override
  String get invalidEmailOrPassword => 'Invalid email or password';

  @override
  String get thisEmailIsAlreadyRegistered => 'This email is already registered';

  @override
  String get passwordIsTooWeakMinimum => 'Password is too weak (minimum 6 characters)';

  @override
  String get unknownKey15 => 'Нет подключения к сети';

  @override
  String get somethingWentWrongTryAgain => 'Something went wrong. Try again.';

  @override
  String get singleClassForChatnfeedAnd => 'Single class for chat,\\nfeed and homework.';

  @override
  String get realtimeClassChat => 'Real-time class chat';

  @override
  String get adsAndFeed => 'Ads and feed';

  @override
  String get assignmentsAndAssessments => 'Assignments and assessments';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get welcomeBack => 'Welcome back 👋';

  @override
  String get fullName => 'Full name';

  @override
  String get emailMail => 'Email mail';

  @override
  String get forgotYourPassword => 'Forgot your password?';

  @override
  String get alreadyHaveAnAccount => 'Already have an account?';

  @override
  String get dontHaveAnAccount => 'Don\'t have an account?';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get joinTheClassToAccess => 'Join the class to access this section.';

  @override
  String get enterTheTeacherInvitationCode => 'Enter the teacher invitation code to open the chat, feed, and assignments.';

  @override
  String get joinTheClass => 'Join the class';

  @override
  String get or => '- OR -';

  @override
  String get theCameraWillBeAvailable => 'The camera will be available in the next update';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String get enterCode => 'Enter code';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get previewNotAvailableOnThis => 'Preview not available on this platform';

  @override
  String get teacher1 => 'TEACHER';

  @override
  String get classText => 'Class';
}
