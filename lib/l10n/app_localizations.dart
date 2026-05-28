import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @yourClassroomConnected.
  ///
  /// In en, this message translates to:
  /// **'Your classroom,\nconnected.'**
  String get yourClassroomConnected;

  /// No description provided for @onboardingWelcomeDesc.
  ///
  /// In en, this message translates to:
  /// **'School World brings together chat, homework, and announcements so you never miss a thing your teachers post.'**
  String get onboardingWelcomeDesc;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @whoIsJoining.
  ///
  /// In en, this message translates to:
  /// **'Who\'s joining today?'**
  String get whoIsJoining;

  /// No description provided for @pickRoleDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick your role. We will tailor the app to what you do most.'**
  String get pickRoleDesc;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @studentDesc.
  ///
  /// In en, this message translates to:
  /// **'Join classes, chat, submit homework'**
  String get studentDesc;

  /// No description provided for @teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacher;

  /// No description provided for @teacherDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage classes, post and pin materials'**
  String get teacherDesc;

  /// No description provided for @parent.
  ///
  /// In en, this message translates to:
  /// **'Parent / Guardian'**
  String get parent;

  /// No description provided for @parentDesc.
  ///
  /// In en, this message translates to:
  /// **'Follow your child\'s progress and grades'**
  String get parentDesc;

  /// No description provided for @continueAs.
  ///
  /// In en, this message translates to:
  /// **'Continue as {role}'**
  String continueAs(String role);

  /// No description provided for @chooseYourClasses.
  ///
  /// In en, this message translates to:
  /// **'Choose your classes'**
  String get chooseYourClasses;

  /// No description provided for @inviteCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your school invite code to preview and join your class.'**
  String get inviteCodeDesc;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @previewClass.
  ///
  /// In en, this message translates to:
  /// **'Preview class'**
  String get previewClass;

  /// No description provided for @joinClass.
  ///
  /// In en, this message translates to:
  /// **'Join class'**
  String get joinClass;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @homework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get homework;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @otp.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otp;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number.'**
  String get enterPhoneError;

  /// No description provided for @enterOtpError.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get enterOtpError;

  /// No description provided for @teacherWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Teacher workspace'**
  String get teacherWorkspace;

  /// No description provided for @createClass.
  ///
  /// In en, this message translates to:
  /// **'Create class'**
  String get createClass;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @joinAClass.
  ///
  /// In en, this message translates to:
  /// **'Join a class'**
  String get joinAClass;

  /// No description provided for @inviteCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Invite code not found.'**
  String get inviteCodeNotFound;

  /// No description provided for @hiName.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String hiName(String name);

  /// No description provided for @todaysClasses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s classes'**
  String get todaysClasses;

  /// No description provided for @quickLinks.
  ///
  /// In en, this message translates to:
  /// **'Quick links'**
  String get quickLinks;

  /// No description provided for @homeworkPortal.
  ///
  /// In en, this message translates to:
  /// **'Homework Portal'**
  String get homeworkPortal;

  /// No description provided for @myGrades.
  ///
  /// In en, this message translates to:
  /// **'My Grades'**
  String get myGrades;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @classRoster.
  ///
  /// In en, this message translates to:
  /// **'Class roster'**
  String get classRoster;

  /// No description provided for @learningStreak.
  ///
  /// In en, this message translates to:
  /// **'{count}-day learning streak'**
  String learningStreak(int count);

  /// No description provided for @homeworksDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} homeworks done today'**
  String homeworksDone(int done, int total);

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @pickClassToChat.
  ///
  /// In en, this message translates to:
  /// **'Pick a class to chat.'**
  String get pickClassToChat;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get noMessagesYet;

  /// No description provided for @messageYourClass.
  ///
  /// In en, this message translates to:
  /// **'Message your class'**
  String get messageYourClass;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @classChat.
  ///
  /// In en, this message translates to:
  /// **'Class chat'**
  String get classChat;

  /// No description provided for @classRoom.
  ///
  /// In en, this message translates to:
  /// **'Class room'**
  String get classRoom;

  /// No description provided for @studentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String studentsCount(int count);

  /// No description provided for @searchMessages.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get searchMessages;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @classmate.
  ///
  /// In en, this message translates to:
  /// **'Classmate'**
  String get classmate;

  /// No description provided for @pickClassToReadAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Pick a class to read announcements.'**
  String get pickClassToReadAnnouncements;

  /// No description provided for @noAnnouncementsYet.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet.'**
  String get noAnnouncementsYet;

  /// No description provided for @teacherUpdate.
  ///
  /// In en, this message translates to:
  /// **'Teacher update'**
  String get teacherUpdate;

  /// No description provided for @announcement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcement;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @commentsSoon.
  ///
  /// In en, this message translates to:
  /// **'Comments soon'**
  String get commentsSoon;

  /// No description provided for @pickClassToViewHomework.
  ///
  /// In en, this message translates to:
  /// **'Pick a class to view homework.'**
  String get pickClassToViewHomework;

  /// No description provided for @noHomeworkAssigned.
  ///
  /// In en, this message translates to:
  /// **'No homework assigned.'**
  String get noHomeworkAssigned;

  /// No description provided for @assignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get assignment;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @studentAccount.
  ///
  /// In en, this message translates to:
  /// **'Student account'**
  String get studentAccount;

  /// No description provided for @joinAnotherClass.
  ///
  /// In en, this message translates to:
  /// **'Join another class'**
  String get joinAnotherClass;

  /// No description provided for @inviteCodeFromTeacher.
  ///
  /// In en, this message translates to:
  /// **'Use an invite code from a teacher'**
  String get inviteCodeFromTeacher;

  /// No description provided for @unreadUpdates.
  ///
  /// In en, this message translates to:
  /// **'Unread class updates and reminders'**
  String get unreadUpdates;

  /// No description provided for @privacyAndSafety.
  ///
  /// In en, this message translates to:
  /// **'Privacy and safety'**
  String get privacyAndSafety;

  /// No description provided for @protectedFiles.
  ///
  /// In en, this message translates to:
  /// **'Class-only messaging and protected files'**
  String get protectedFiles;

  /// No description provided for @submitHomework.
  ///
  /// In en, this message translates to:
  /// **'Submit homework'**
  String get submitHomework;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @addNoteForTeacher.
  ///
  /// In en, this message translates to:
  /// **'Add a short note for your teacher'**
  String get addNoteForTeacher;

  /// No description provided for @joinYourFirstClass.
  ///
  /// In en, this message translates to:
  /// **'Join your first class'**
  String get joinYourFirstClass;

  /// No description provided for @joinFirstClassDesc.
  ///
  /// In en, this message translates to:
  /// **'Use a teacher invite code to unlock chat, feed, and homework.'**
  String get joinFirstClassDesc;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String due(String date);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create post'**
  String get createPost;

  /// No description provided for @createAssignment.
  ///
  /// In en, this message translates to:
  /// **'Create assignment'**
  String get createAssignment;

  /// No description provided for @noClassMessages.
  ///
  /// In en, this message translates to:
  /// **'No class messages yet.'**
  String get noClassMessages;

  /// No description provided for @messageThisClass.
  ///
  /// In en, this message translates to:
  /// **'Message this class'**
  String get messageThisClass;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get noPostsYet;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @noAssignmentsYet.
  ///
  /// In en, this message translates to:
  /// **'No assignments yet.'**
  String get noAssignmentsYet;

  /// No description provided for @createYourFirstClass.
  ///
  /// In en, this message translates to:
  /// **'Create your first class'**
  String get createYourFirstClass;

  /// No description provided for @teacherEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Classes include invite codes for student and parent onboarding.'**
  String get teacherEmptyDesc;

  /// No description provided for @className.
  ///
  /// In en, this message translates to:
  /// **'Class name'**
  String get className;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @parentDashboard.
  ///
  /// In en, this message translates to:
  /// **'Parent Dashboard'**
  String get parentDashboard;

  /// No description provided for @noClassesLinked.
  ///
  /// In en, this message translates to:
  /// **'No classes linked.'**
  String get noClassesLinked;

  /// No description provided for @teacherLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher: {name}'**
  String teacherLabel(String name);

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @notSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Not submitted'**
  String get notSubmitted;

  /// No description provided for @noGradesYet.
  ///
  /// In en, this message translates to:
  /// **'No grades yet.'**
  String get noGradesYet;

  /// No description provided for @noSubmissionsYet.
  ///
  /// In en, this message translates to:
  /// **'No submissions yet.'**
  String get noSubmissionsYet;

  /// No description provided for @ungraded.
  ///
  /// In en, this message translates to:
  /// **'Ungraded'**
  String get ungraded;

  /// No description provided for @gradeSubmission.
  ///
  /// In en, this message translates to:
  /// **'Grade submission'**
  String get gradeSubmission;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @classStatistics.
  ///
  /// In en, this message translates to:
  /// **'Class Statistics'**
  String get classStatistics;

  /// No description provided for @totalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get totalStudents;

  /// No description provided for @avgGrade.
  ///
  /// In en, this message translates to:
  /// **'Avg. Grade'**
  String get avgGrade;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @noStudentsInClass.
  ///
  /// In en, this message translates to:
  /// **'No students in this class yet.'**
  String get noStudentsInClass;

  /// No description provided for @assignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignments;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorGeneric;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @oneOff.
  ///
  /// In en, this message translates to:
  /// **'One-off'**
  String get oneOff;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @savedSchedule.
  ///
  /// In en, this message translates to:
  /// **'Saved schedule!'**
  String get savedSchedule;

  /// No description provided for @deleteSchedule.
  ///
  /// In en, this message translates to:
  /// **'Delete schedule?'**
  String get deleteSchedule;

  /// No description provided for @deleteScheduleDesc.
  ///
  /// In en, this message translates to:
  /// **'This will remove the slot and its overrides.'**
  String get deleteScheduleDesc;

  /// No description provided for @deletedSchedule.
  ///
  /// In en, this message translates to:
  /// **'Deleted schedule'**
  String get deletedSchedule;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated successfully'**
  String get avatarUpdated;

  /// No description provided for @failedToUploadAvatar.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload avatar: {error}'**
  String failedToUploadAvatar(Object error);

  /// No description provided for @nameEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameEmptyError;

  /// No description provided for @profileUpdatedDesc.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedDesc;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String failedToUpdateProfile(Object error);

  /// No description provided for @confirmSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get confirmSignOut;

  /// No description provided for @previewClassAction.
  ///
  /// In en, this message translates to:
  /// **'Preview Class'**
  String get previewClassAction;

  /// No description provided for @skipOnboardingTeacher.
  ///
  /// In en, this message translates to:
  /// **'I\'m a teacher, skip this step'**
  String get skipOnboardingTeacher;

  /// No description provided for @needsReviewToday.
  ///
  /// In en, this message translates to:
  /// **'Needs review today'**
  String get needsReviewToday;

  /// No description provided for @studentSubmissions.
  ///
  /// In en, this message translates to:
  /// **'{count} student submissions'**
  String studentSubmissions(int count);

  /// No description provided for @noClassesScheduled.
  ///
  /// In en, this message translates to:
  /// **'No classes scheduled for today'**
  String get noClassesScheduled;

  /// No description provided for @openWeeklySchedule.
  ///
  /// In en, this message translates to:
  /// **'Open weekly schedule'**
  String get openWeeklySchedule;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACTIONS'**
  String get quickActions;

  /// No description provided for @postAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Post announcement'**
  String get postAnnouncement;

  /// No description provided for @pinWorksheet.
  ///
  /// In en, this message translates to:
  /// **'Pin worksheet'**
  String get pinWorksheet;

  /// No description provided for @takeAttendance.
  ///
  /// In en, this message translates to:
  /// **'Take attendance'**
  String get takeAttendance;

  /// No description provided for @gradeSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Grade submissions'**
  String get gradeSubmissions;

  /// No description provided for @copyGuestChatLink.
  ///
  /// In en, this message translates to:
  /// **'Copy guest chat link'**
  String get copyGuestChatLink;

  /// No description provided for @deleteClass.
  ///
  /// In en, this message translates to:
  /// **'Delete class'**
  String get deleteClass;

  /// No description provided for @unpinPost.
  ///
  /// In en, this message translates to:
  /// **'Unpin post'**
  String get unpinPost;

  /// No description provided for @pinPost.
  ///
  /// In en, this message translates to:
  /// **'Pin post'**
  String get pinPost;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get deletePost;

  /// No description provided for @deletePostDesc.
  ///
  /// In en, this message translates to:
  /// **'This post and its comments will be permanently removed.'**
  String get deletePostDesc;

  /// No description provided for @publishPost.
  ///
  /// In en, this message translates to:
  /// **'Publish post'**
  String get publishPost;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @couldNotOpenAttachment.
  ///
  /// In en, this message translates to:
  /// **'Could not open attachment.'**
  String get couldNotOpenAttachment;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @assignmentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Assignment not found'**
  String get assignmentNotFound;

  /// No description provided for @submissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed: {error}'**
  String submissionFailed(String error);

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @studentPortalTerm3.
  ///
  /// In en, this message translates to:
  /// **'Student Portal · Term 3'**
  String get studentPortalTerm3;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'GENERAL SETTINGS'**
  String get generalSettings;

  /// No description provided for @accountAndClasses.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT & CLASSES'**
  String get accountAndClasses;

  /// No description provided for @helpAndAbout.
  ///
  /// In en, this message translates to:
  /// **'HELP & ABOUT'**
  String get helpAndAbout;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add a new classroom code'**
  String get addNote;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get done;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get upcoming;

  /// No description provided for @inMin.
  ///
  /// In en, this message translates to:
  /// **'IN {min} MIN'**
  String inMin(int min);

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get cancelled;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @teacherAttachments.
  ///
  /// In en, this message translates to:
  /// **'Teacher attachments'**
  String get teacherAttachments;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy Text'**
  String get copyText;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freePlan;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Your current plan'**
  String get currentPlan;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @soonAvailable.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get soonAvailable;

  /// No description provided for @contactSupportForEmail.
  ///
  /// In en, this message translates to:
  /// **'To change email, contact support'**
  String get contactSupportForEmail;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get noConnection;

  /// No description provided for @newTopic.
  ///
  /// In en, this message translates to:
  /// **'New topic'**
  String get newTopic;

  /// No description provided for @joinLessonSoon.
  ///
  /// In en, this message translates to:
  /// **'Join lesson will be available soon'**
  String get joinLessonSoon;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get now;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'LATER'**
  String get later;

  /// No description provided for @allChecked.
  ///
  /// In en, this message translates to:
  /// **'All checked!'**
  String get allChecked;

  /// No description provided for @selectClassFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a class first.'**
  String get selectClassFirst;

  /// No description provided for @classNotFound.
  ///
  /// In en, this message translates to:
  /// **'Class not found.'**
  String get classNotFound;

  /// No description provided for @removeFromClass.
  ///
  /// In en, this message translates to:
  /// **'Remove from class?'**
  String get removeFromClass;

  /// No description provided for @removeFromClassDesc.
  ///
  /// In en, this message translates to:
  /// **'The student will lose access to materials and chat of this class.'**
  String get removeFromClassDesc;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @copyInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Copy invite link'**
  String get copyInviteLink;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @teacherBadge.
  ///
  /// In en, this message translates to:
  /// **'TEACHER'**
  String get teacherBadge;

  /// No description provided for @totalParticipants.
  ///
  /// In en, this message translates to:
  /// **'{count} total participants'**
  String totalParticipants(int count);

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @publishedAt.
  ///
  /// In en, this message translates to:
  /// **'Published: {date}'**
  String publishedAt(String date);

  /// No description provided for @submittedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted: {date}'**
  String submittedAtLabel(String date);

  /// No description provided for @deleteAssignment.
  ///
  /// In en, this message translates to:
  /// **'Delete assignment?'**
  String get deleteAssignment;

  /// No description provided for @deleteAssignmentDesc.
  ///
  /// In en, this message translates to:
  /// **'All submitted works for this assignment will also be removed.'**
  String get deleteAssignmentDesc;

  /// No description provided for @editAssignment.
  ///
  /// In en, this message translates to:
  /// **'Edit assignment'**
  String get editAssignment;

  /// No description provided for @bookmarksSoon.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks will appear in the next update'**
  String get bookmarksSoon;

  /// No description provided for @initializationFailed.
  ///
  /// In en, this message translates to:
  /// **'Initialization failed.'**
  String get initializationFailed;

  /// No description provided for @topics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topics;

  /// No description provided for @mainChat.
  ///
  /// In en, this message translates to:
  /// **'General Chat'**
  String get mainChat;

  /// No description provided for @createTopic.
  ///
  /// In en, this message translates to:
  /// **'Create Topic'**
  String get createTopic;

  /// No description provided for @myClasses.
  ///
  /// In en, this message translates to:
  /// **'MY CLASSES'**
  String get myClasses;

  /// No description provided for @teacherConsole.
  ///
  /// In en, this message translates to:
  /// **'Teacher Console'**
  String get teacherConsole;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
