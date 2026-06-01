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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
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

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @additionalSections.
  ///
  /// In en, this message translates to:
  /// **'Additional sections'**
  String get additionalSections;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// No description provided for @authCheck.
  ///
  /// In en, this message translates to:
  /// **'Checking authorization...'**
  String get authCheck;

  /// No description provided for @technicalError.
  ///
  /// In en, this message translates to:
  /// **'Technical error'**
  String get technicalError;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @viewErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'View error details'**
  String get viewErrorDetails;

  /// No description provided for @loginWithMainAccount.
  ///
  /// In en, this message translates to:
  /// **'Log in with main account'**
  String get loginWithMainAccount;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @joiningClass.
  ///
  /// In en, this message translates to:
  /// **'Joining class...'**
  String get joiningClass;

  /// No description provided for @viewFullError.
  ///
  /// In en, this message translates to:
  /// **'View full error'**
  String get viewFullError;

  /// No description provided for @unableToJoinServerErr.
  ///
  /// In en, this message translates to:
  /// **'Unable to join: Server responded with error.'**
  String get unableToJoinServerErr;

  /// No description provided for @errorJoiningClass.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while joining the class.'**
  String get errorJoiningClass;

  /// No description provided for @invalidLinkOrExpired.
  ///
  /// In en, this message translates to:
  /// **'Invalid link or invite code has expired.'**
  String get invalidLinkOrExpired;

  /// No description provided for @classNotExists.
  ///
  /// In en, this message translates to:
  /// **'The class does not exist.'**
  String get classNotExists;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection.'**
  String get networkError;

  /// No description provided for @joiningWait.
  ///
  /// In en, this message translates to:
  /// **'Joining...'**
  String get joiningWait;

  /// No description provided for @enterClassroom.
  ///
  /// In en, this message translates to:
  /// **'Enter classroom'**
  String get enterClassroom;

  /// No description provided for @totalAssignmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} assignments total'**
  String totalAssignmentsCount(int count);

  /// No description provided for @roomWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Room {number}'**
  String roomWithNumber(String number);

  /// No description provided for @editedPhotoAttached.
  ///
  /// In en, this message translates to:
  /// **'Edited photo attached to message'**
  String get editedPhotoAttached;

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated successfully'**
  String get avatarUpdated;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);

  /// No description provided for @errorClearingChat.
  ///
  /// In en, this message translates to:
  /// **'Error clearing chat: {error}'**
  String errorClearingChat(Object error);

  /// No description provided for @errorDeletingClass.
  ///
  /// In en, this message translates to:
  /// **'Error deleting class: {error}'**
  String errorDeletingClass(Object error);

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @loadingSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading system settings...'**
  String get loadingSystemSettings;

  /// No description provided for @uploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload error: {error}'**
  String uploadError(String error);

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

  /// No description provided for @coolMagazine.
  ///
  /// In en, this message translates to:
  /// **'Cool magazine'**
  String get coolMagazine;

  /// No description provided for @myGradesAndSubjects.
  ///
  /// In en, this message translates to:
  /// **'My grades and subjects'**
  String get myGradesAndSubjects;

  /// No description provided for @academicPerformanceAndSubjects.
  ///
  /// In en, this message translates to:
  /// **'Academic performance and subjects'**
  String get academicPerformanceAndSubjects;

  /// No description provided for @addALesson.
  ///
  /// In en, this message translates to:
  /// **'Add a lesson'**
  String get addALesson;

  /// No description provided for @ratings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get ratings;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @unknownKey.
  ///
  /// In en, this message translates to:
  /// **'Отмена'**
  String get unknownKey;

  /// No description provided for @noLessonsAddYourFirst.
  ///
  /// In en, this message translates to:
  /// **'No lessons. Add your first lesson!'**
  String get noLessonsAddYourFirst;

  /// No description provided for @noTheme.
  ///
  /// In en, this message translates to:
  /// **'No theme'**
  String get noTheme;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'JANUARY'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'FEBRUARY'**
  String get february;

  /// No description provided for @martha.
  ///
  /// In en, this message translates to:
  /// **'MARTHA'**
  String get martha;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'APRIL'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'MAY'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'JUNE'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'JULY'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'AUGUST'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'SEPTEMBER'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'OCTOBER'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'NOVEMBER'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'DECEMBER'**
  String get december;

  /// No description provided for @editLesson.
  ///
  /// In en, this message translates to:
  /// **'Edit lesson'**
  String get editLesson;

  /// No description provided for @deleteLesson.
  ///
  /// In en, this message translates to:
  /// **'Delete lesson?'**
  String get deleteLesson;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @youDontHaveRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have ratings yet.'**
  String get youDontHaveRatingsYet;

  /// No description provided for @theMagazineIsEmptyAdd.
  ///
  /// In en, this message translates to:
  /// **'The magazine is empty. Add your first lesson!'**
  String get theMagazineIsEmptyAdd;

  /// No description provided for @myRatings.
  ///
  /// In en, this message translates to:
  /// **'My ratings'**
  String get myRatings;

  /// No description provided for @unknownKey1.
  ///
  /// In en, this message translates to:
  /// **'Загрузка...'**
  String get unknownKey1;

  /// No description provided for @n.
  ///
  /// In en, this message translates to:
  /// **'n'**
  String get n;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @unknownKey2.
  ///
  /// In en, this message translates to:
  /// **'Отлично'**
  String get unknownKey2;

  /// No description provided for @unknownKey3.
  ///
  /// In en, this message translates to:
  /// **'Хорошо'**
  String get unknownKey3;

  /// No description provided for @unknownKey4.
  ///
  /// In en, this message translates to:
  /// **'Удовлетворительно'**
  String get unknownKey4;

  /// No description provided for @unknownKey5.
  ///
  /// In en, this message translates to:
  /// **'Плохо'**
  String get unknownKey5;

  /// No description provided for @n1.
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get n1;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @clearMark.
  ///
  /// In en, this message translates to:
  /// **'Clear mark'**
  String get clearMark;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin panel'**
  String get adminPanel;

  /// No description provided for @systemManagementAndActivityAnalytics.
  ///
  /// In en, this message translates to:
  /// **'System management and activity analytics'**
  String get systemManagementAndActivityAnalytics;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total users'**
  String get totalUsers;

  /// No description provided for @activeChats.
  ///
  /// In en, this message translates to:
  /// **'Active chats'**
  String get activeChats;

  /// No description provided for @postsToday.
  ///
  /// In en, this message translates to:
  /// **'Posts today'**
  String get postsToday;

  /// No description provided for @appBranding.
  ///
  /// In en, this message translates to:
  /// **'App branding'**
  String get appBranding;

  /// No description provided for @quickActions1.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions1;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @roleManagementAndBan.
  ///
  /// In en, this message translates to:
  /// **'Role management and ban'**
  String get roleManagementAndBan;

  /// No description provided for @allClasses.
  ///
  /// In en, this message translates to:
  /// **'All classes'**
  String get allClasses;

  /// No description provided for @reviewAndModeration.
  ///
  /// In en, this message translates to:
  /// **'Review and moderation'**
  String get reviewAndModeration;

  /// No description provided for @applicationsForTeachers.
  ///
  /// In en, this message translates to:
  /// **'Applications for teachers'**
  String get applicationsForTeachers;

  /// No description provided for @moderationOfRequests.
  ///
  /// In en, this message translates to:
  /// **'Moderation of requests'**
  String get moderationOfRequests;

  /// No description provided for @latestUsers.
  ///
  /// In en, this message translates to:
  /// **'Latest users'**
  String get latestUsers;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @registered.
  ///
  /// In en, this message translates to:
  /// **'registered'**
  String get registered;

  /// No description provided for @recently.
  ///
  /// In en, this message translates to:
  /// **'recently'**
  String get recently;

  /// No description provided for @logoLoaded.
  ///
  /// In en, this message translates to:
  /// **'Logo loaded'**
  String get logoLoaded;

  /// No description provided for @applicationName.
  ///
  /// In en, this message translates to:
  /// **'Application name'**
  String get applicationName;

  /// No description provided for @enterAName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterAName;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @saveChanges1.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges1;

  /// No description provided for @searchByNameEmailOr.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email or ID...'**
  String get searchByNameEmailOr;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @unknownKey6.
  ///
  /// In en, this message translates to:
  /// **'Без имени'**
  String get unknownKey6;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get makeAdmin;

  /// No description provided for @makeItATeacher.
  ///
  /// In en, this message translates to:
  /// **'Make it a teacher'**
  String get makeItATeacher;

  /// No description provided for @makeAStudent.
  ///
  /// In en, this message translates to:
  /// **'Make a student'**
  String get makeAStudent;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @teachersLicenseIssued.
  ///
  /// In en, this message translates to:
  /// **'Teacher\'s license issued'**
  String get teachersLicenseIssued;

  /// No description provided for @applicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Application rejected'**
  String get applicationRejected;

  /// No description provided for @noApplications.
  ///
  /// In en, this message translates to:
  /// **'No applications'**
  String get noApplications;

  /// No description provided for @allRequestsProcessed.
  ///
  /// In en, this message translates to:
  /// **'All requests processed'**
  String get allRequestsProcessed;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @assignATeacher.
  ///
  /// In en, this message translates to:
  /// **'Assign a teacher'**
  String get assignATeacher;

  /// No description provided for @classManagement.
  ///
  /// In en, this message translates to:
  /// **'Class Management'**
  String get classManagement;

  /// No description provided for @createClasses.
  ///
  /// In en, this message translates to:
  /// **'Create classes'**
  String get createClasses;

  /// No description provided for @searchByTitleOrSubject.
  ///
  /// In en, this message translates to:
  /// **'Search by title or subject...'**
  String get searchByTitleOrSubject;

  /// No description provided for @noClassesFound.
  ///
  /// In en, this message translates to:
  /// **'No classes found'**
  String get noClassesFound;

  /// No description provided for @unknownKey7.
  ///
  /// In en, this message translates to:
  /// **'Без названия'**
  String get unknownKey7;

  /// No description provided for @n57.
  ///
  /// In en, this message translates to:
  /// **'Школа №57'**
  String get n57;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'EXPERIENCE'**
  String get experience;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInformation;

  /// No description provided for @linkedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Linked accounts'**
  String get linkedAccounts;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @allowedForChatAndTasks.
  ///
  /// In en, this message translates to:
  /// **'Allowed for chat and tasks'**
  String get allowedForChatAndTasks;

  /// No description provided for @newMessages.
  ///
  /// In en, this message translates to:
  /// **'New messages'**
  String get newMessages;

  /// No description provided for @soundVibration.
  ///
  /// In en, this message translates to:
  /// **'Sound + vibration'**
  String get soundVibration;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @quietMode22000700.
  ///
  /// In en, this message translates to:
  /// **'Quiet mode: 22:00–07:00'**
  String get quietMode22000700;

  /// No description provided for @confidentiality.
  ///
  /// In en, this message translates to:
  /// **'Confidentiality'**
  String get confidentiality;

  /// No description provided for @showNameToStudents.
  ///
  /// In en, this message translates to:
  /// **'Show name to students'**
  String get showNameToStudents;

  /// No description provided for @personalMessages.
  ///
  /// In en, this message translates to:
  /// **'Personal messages'**
  String get personalMessages;

  /// No description provided for @allowStudentsToWriteDirectly.
  ///
  /// In en, this message translates to:
  /// **'Allow students to write directly'**
  String get allowStudentsToWriteDirectly;

  /// No description provided for @registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @schoolBlue.
  ///
  /// In en, this message translates to:
  /// **'School blue'**
  String get schoolBlue;

  /// No description provided for @russianRu.
  ///
  /// In en, this message translates to:
  /// **'Russian (ru)'**
  String get russianRu;

  /// No description provided for @tariffPlan.
  ///
  /// In en, this message translates to:
  /// **'Tariff plan'**
  String get tariffPlan;

  /// No description provided for @safety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safety;

  /// No description provided for @twofactorProtection.
  ///
  /// In en, this message translates to:
  /// **'Two-factor protection'**
  String get twofactorProtection;

  /// No description provided for @enabledAuthenticator.
  ///
  /// In en, this message translates to:
  /// **'Enabled Authenticator'**
  String get enabledAuthenticator;

  /// No description provided for @actively.
  ///
  /// In en, this message translates to:
  /// **'Actively'**
  String get actively;

  /// No description provided for @downloadMyData.
  ///
  /// In en, this message translates to:
  /// **'Download my data'**
  String get downloadMyData;

  /// No description provided for @exportToZip.
  ///
  /// In en, this message translates to:
  /// **'Export to ZIP'**
  String get exportToZip;

  /// No description provided for @emailpassword.
  ///
  /// In en, this message translates to:
  /// **'Email/Password'**
  String get emailpassword;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @related.
  ///
  /// In en, this message translates to:
  /// **'Related'**
  String get related;

  /// No description provided for @notRelated.
  ///
  /// In en, this message translates to:
  /// **'Not related'**
  String get notRelated;

  /// No description provided for @languageChangedToRussian.
  ///
  /// In en, this message translates to:
  /// **'Language changed to Russian'**
  String get languageChangedToRussian;

  /// No description provided for @preparingAZipArchive.
  ///
  /// In en, this message translates to:
  /// **'Preparing a ZIP archive...'**
  String get preparingAZipArchive;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @aZipArchiveWillBe.
  ///
  /// In en, this message translates to:
  /// **'A ZIP archive will be created containing all of your personal data, including classes you\'ve created, homework assignments, chat messages, and profile.'**
  String get aZipArchiveWillBe;

  /// No description provided for @theArchiveWasSuccessfullySaved.
  ///
  /// In en, this message translates to:
  /// **'The archive was successfully saved to the Downloads folder'**
  String get theArchiveWasSuccessfullySaved;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get postDeleted;

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get voiceMessage;

  /// No description provided for @teachersRoom.
  ///
  /// In en, this message translates to:
  /// **'Teacher\'s room'**
  String get teachersRoom;

  /// No description provided for @classNotFound1.
  ///
  /// In en, this message translates to:
  /// **'Class not found'**
  String get classNotFound1;

  /// No description provided for @unknownKey8.
  ///
  /// In en, this message translates to:
  /// **'Чат класса'**
  String get unknownKey8;

  /// No description provided for @participant.
  ///
  /// In en, this message translates to:
  /// **'Participant'**
  String get participant;

  /// No description provided for @newPoll.
  ///
  /// In en, this message translates to:
  /// **'New poll'**
  String get newPoll;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @addAnOption.
  ///
  /// In en, this message translates to:
  /// **'Add an option'**
  String get addAnOption;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message?'**
  String get deleteMessage;

  /// No description provided for @areYouSureYouWant.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get areYouSureYouWant;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'📷 Image'**
  String get image;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'📎 File'**
  String get file;

  /// No description provided for @deleteTopic.
  ///
  /// In en, this message translates to:
  /// **'Delete topic?'**
  String get deleteTopic;

  /// No description provided for @teachersRoom1.
  ///
  /// In en, this message translates to:
  /// **'teacher\'s room'**
  String get teachersRoom1;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @searchChats.
  ///
  /// In en, this message translates to:
  /// **'Search chats...'**
  String get searchChats;

  /// No description provided for @noChatsFound.
  ///
  /// In en, this message translates to:
  /// **'No chats found'**
  String get noChatsFound;

  /// No description provided for @errorLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Error loading message'**
  String get errorLoadingMessage;

  /// No description provided for @noMessagesYet1.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet1;

  /// No description provided for @photography.
  ///
  /// In en, this message translates to:
  /// **'📷 Photography'**
  String get photography;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'🎥 Video'**
  String get video;

  /// No description provided for @file1.
  ///
  /// In en, this message translates to:
  /// **'📁 File'**
  String get file1;

  /// No description provided for @voiceMessage1.
  ///
  /// In en, this message translates to:
  /// **'🎤 Voice message'**
  String get voiceMessage1;

  /// No description provided for @clickToOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Click to open chat'**
  String get clickToOpenChat;

  /// No description provided for @changed.
  ///
  /// In en, this message translates to:
  /// **'changed'**
  String get changed;

  /// No description provided for @sender.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get sender;

  /// No description provided for @replyToAMessage.
  ///
  /// In en, this message translates to:
  /// **'Reply to a message'**
  String get replyToAMessage;

  /// No description provided for @messageText.
  ///
  /// In en, this message translates to:
  /// **'Message text'**
  String get messageText;

  /// No description provided for @survey.
  ///
  /// In en, this message translates to:
  /// **'SURVEY'**
  String get survey;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'CLOSED'**
  String get closed;

  /// No description provided for @ov.
  ///
  /// In en, this message translates to:
  /// **'ov'**
  String get ov;

  /// No description provided for @a.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get a;

  /// No description provided for @replyToMessage.
  ///
  /// In en, this message translates to:
  /// **'REPLY TO MESSAGE'**
  String get replyToMessage;

  /// No description provided for @editing.
  ///
  /// In en, this message translates to:
  /// **'EDITING'**
  String get editing;

  /// No description provided for @failedToLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to load video'**
  String get failedToLoadVideo;

  /// No description provided for @video1.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video1;

  /// No description provided for @attach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get attach;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @survey1.
  ///
  /// In en, this message translates to:
  /// **'Survey'**
  String get survey1;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessage;

  /// No description provided for @holdToRecordVoice.
  ///
  /// In en, this message translates to:
  /// **'Hold to record voice'**
  String get holdToRecordVoice;

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied. Please enable it in device settings.'**
  String get micPermissionDenied;

  /// No description provided for @releaseToView.
  ///
  /// In en, this message translates to:
  /// **'Release to view'**
  String get releaseToView;

  /// No description provided for @printing.
  ///
  /// In en, this message translates to:
  /// **'Printing...'**
  String get printing;

  /// No description provided for @failedToOpenCallRoom.
  ///
  /// In en, this message translates to:
  /// **'Failed to open call room'**
  String get failedToOpenCallRoom;

  /// No description provided for @clearChat1.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get clearChat1;

  /// No description provided for @areYouSureYouWant1.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all Teacher\'s chat history? This action cannot be undone.'**
  String get areYouSureYouWant1;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearingChat.
  ///
  /// In en, this message translates to:
  /// **'Clearing chat...'**
  String get clearingChat;

  /// No description provided for @teachersChatHasBeenSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Teacher\'s chat has been successfully cleared'**
  String get teachersChatHasBeenSuccessfully;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @chatTopics.
  ///
  /// In en, this message translates to:
  /// **'Chat topics'**
  String get chatTopics;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @chatInformation.
  ///
  /// In en, this message translates to:
  /// **'Chat information'**
  String get chatInformation;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @mediaAndFiles.
  ///
  /// In en, this message translates to:
  /// **'Media and files'**
  String get mediaAndFiles;

  /// No description provided for @searchMessages1.
  ///
  /// In en, this message translates to:
  /// **'Search messages...'**
  String get searchMessages1;

  /// No description provided for @startAVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Start a video call'**
  String get startAVideoCall;

  /// No description provided for @clearTeachersChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Teacher\'s chat'**
  String get clearTeachersChat;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @pinnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Pinned message'**
  String get pinnedMessage;

  /// No description provided for @pinnedMessages.
  ///
  /// In en, this message translates to:
  /// **'Pinned messages'**
  String get pinnedMessages;

  /// No description provided for @noPinnedMessages.
  ///
  /// In en, this message translates to:
  /// **'No pinned messages'**
  String get noPinnedMessages;

  /// No description provided for @toResources.
  ///
  /// In en, this message translates to:
  /// **'To resources'**
  String get toResources;

  /// No description provided for @resources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resources;

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get media;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @polls.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get polls;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @thereWasNoMediaYet.
  ///
  /// In en, this message translates to:
  /// **'There was no media yet'**
  String get thereWasNoMediaYet;

  /// No description provided for @thereAreNoFilesYet.
  ///
  /// In en, this message translates to:
  /// **'There are no files yet'**
  String get thereAreNoFilesYet;

  /// No description provided for @file2.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file2;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @thereAreNoLinksYet.
  ///
  /// In en, this message translates to:
  /// **'There are no links yet'**
  String get thereAreNoLinksYet;

  /// No description provided for @roomNotFound.
  ///
  /// In en, this message translates to:
  /// **'Room not found'**
  String get roomNotFound;

  /// No description provided for @noParticipantsYet.
  ///
  /// In en, this message translates to:
  /// **'No participants yet'**
  String get noParticipantsYet;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @parent1.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parent1;

  /// No description provided for @removeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove admin'**
  String get removeAdmin;

  /// No description provided for @areYouSureYouWant2.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this student from the class?'**
  String get areYouSureYouWant2;

  /// No description provided for @cancellation.
  ///
  /// In en, this message translates to:
  /// **'CANCELLATION'**
  String get cancellation;

  /// No description provided for @delete1.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get delete1;

  /// No description provided for @thereAreNoPollsYet.
  ///
  /// In en, this message translates to:
  /// **'There are no polls yet'**
  String get thereAreNoPollsYet;

  /// No description provided for @helloImYourTeachingAssistant.
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m your teaching assistant. I can help you understand the materials for this class. Ask!'**
  String get helloImYourTeachingAssistant;

  /// No description provided for @interestingQuestionBasedOnThe.
  ///
  /// In en, this message translates to:
  /// **'Interesting question! Based on the class materials, I can say that this aspect is very important for understanding the topic. I recommend paying attention to the second chapter of the textbook.'**
  String get interestingQuestionBasedOnThe;

  /// No description provided for @askAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI...'**
  String get askAi;

  /// No description provided for @todaysGoalAchieved.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goal achieved'**
  String get todaysGoalAchieved;

  /// No description provided for @completeTheTaskSoAs.
  ///
  /// In en, this message translates to:
  /// **'Complete the task so as not to break the streak'**
  String get completeTheTaskSoAs;

  /// No description provided for @noLessonsForToday.
  ///
  /// In en, this message translates to:
  /// **'No lessons for today'**
  String get noLessonsForToday;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @webinars.
  ///
  /// In en, this message translates to:
  /// **'Webinars'**
  String get webinars;

  /// No description provided for @areYouReadyFornnewKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Are you ready for\\nnew knowledge?'**
  String get areYouReadyFornnewKnowledge;

  /// No description provided for @canceled.
  ///
  /// In en, this message translates to:
  /// **'CANCELED'**
  String get canceled;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'SOON'**
  String get soon;

  /// No description provided for @quickLinks1.
  ///
  /// In en, this message translates to:
  /// **'QUICK LINKS'**
  String get quickLinks1;

  /// No description provided for @magazine.
  ///
  /// In en, this message translates to:
  /// **'Magazine'**
  String get magazine;

  /// No description provided for @studentAnswer.
  ///
  /// In en, this message translates to:
  /// **'Student answer:'**
  String get studentAnswer;

  /// No description provided for @attachedFiles.
  ///
  /// In en, this message translates to:
  /// **'Attached files:'**
  String get attachedFiles;

  /// No description provided for @scoreInOrPoints.
  ///
  /// In en, this message translates to:
  /// **'Score (in % or points)'**
  String get scoreInOrPoints;

  /// No description provided for @teachersReview.
  ///
  /// In en, this message translates to:
  /// **'Teacher\'s review'**
  String get teachersReview;

  /// No description provided for @pleaseEnterAValidRating.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid rating (number)'**
  String get pleaseEnterAValidRating;

  /// No description provided for @giveARating.
  ///
  /// In en, this message translates to:
  /// **'Give a rating'**
  String get giveARating;

  /// No description provided for @addAStudent.
  ///
  /// In en, this message translates to:
  /// **'Add a student'**
  String get addAStudent;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editName;

  /// No description provided for @removeAdminRights.
  ///
  /// In en, this message translates to:
  /// **'Remove admin rights'**
  String get removeAdminRights;

  /// No description provided for @makeAsAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Make as administrator'**
  String get makeAsAdministrator;

  /// No description provided for @editStudentName.
  ///
  /// In en, this message translates to:
  /// **'Edit student name'**
  String get editStudentName;

  /// No description provided for @studentName.
  ///
  /// In en, this message translates to:
  /// **'Student name'**
  String get studentName;

  /// No description provided for @ivanIvanov.
  ///
  /// In en, this message translates to:
  /// **'Ivan Ivanov'**
  String get ivanIvanov;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get unknown;

  /// No description provided for @administrator1.
  ///
  /// In en, this message translates to:
  /// **'ADMINISTRATOR'**
  String get administrator1;

  /// No description provided for @student1.
  ///
  /// In en, this message translates to:
  /// **'STUDENT'**
  String get student1;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @studentEmail.
  ///
  /// In en, this message translates to:
  /// **'Student email'**
  String get studentEmail;

  /// No description provided for @unknownKey9.
  ///
  /// In en, this message translates to:
  /// **'Неизвестный'**
  String get unknownKey9;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noWebinars.
  ///
  /// In en, this message translates to:
  /// **'No webinars'**
  String get noWebinars;

  /// No description provided for @lessonRecordingsAndVideosWill.
  ///
  /// In en, this message translates to:
  /// **'Lesson recordings and videos will be displayed here.'**
  String get lessonRecordingsAndVideosWill;

  /// No description provided for @deleteWebinar.
  ///
  /// In en, this message translates to:
  /// **'Delete webinar?'**
  String get deleteWebinar;

  /// No description provided for @watchVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch video'**
  String get watchVideo;

  /// No description provided for @addAWebinar.
  ///
  /// In en, this message translates to:
  /// **'Add a webinar'**
  String get addAWebinar;

  /// No description provided for @forExampleLesson1Basics.
  ///
  /// In en, this message translates to:
  /// **'for example: Lesson 1. Basics'**
  String get forExampleLesson1Basics;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @provideLink.
  ///
  /// In en, this message translates to:
  /// **'Provide link'**
  String get provideLink;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload file'**
  String get uploadFile;

  /// No description provided for @videoLink.
  ///
  /// In en, this message translates to:
  /// **'Video link'**
  String get videoLink;

  /// No description provided for @httpsyoutubecomOrLinkToFile.
  ///
  /// In en, this message translates to:
  /// **'https://youtube.com/... or link to file'**
  String get httpsyoutubecomOrLinkToFile;

  /// No description provided for @selectVideoFile.
  ///
  /// In en, this message translates to:
  /// **'Select video file'**
  String get selectVideoFile;

  /// No description provided for @loadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get loadingVideo;

  /// No description provided for @pleaseSelectAVideoFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a video file'**
  String get pleaseSelectAVideoFile;

  /// No description provided for @theBuiltinPlayerIsAvailable.
  ///
  /// In en, this message translates to:
  /// **'The built-in player is available in the web version.'**
  String get theBuiltinPlayerIsAvailable;

  /// No description provided for @parentsPanel.
  ///
  /// In en, this message translates to:
  /// **'Parents panel'**
  String get parentsPanel;

  /// No description provided for @monitoringYourChildrensProgress.
  ///
  /// In en, this message translates to:
  /// **'Monitoring your children\'s progress'**
  String get monitoringYourChildrensProgress;

  /// No description provided for @unknownKey10.
  ///
  /// In en, this message translates to:
  /// **'А'**
  String get unknownKey10;

  /// No description provided for @wedPoint.
  ///
  /// In en, this message translates to:
  /// **'Wed. point'**
  String get wedPoint;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @quests.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get quests;

  /// No description provided for @latestRatings.
  ///
  /// In en, this message translates to:
  /// **'Latest ratings'**
  String get latestRatings;

  /// No description provided for @mat.
  ///
  /// In en, this message translates to:
  /// **'Mat'**
  String get mat;

  /// No description provided for @rus.
  ///
  /// In en, this message translates to:
  /// **'Rus'**
  String get rus;

  /// No description provided for @phys.
  ///
  /// In en, this message translates to:
  /// **'Phys.'**
  String get phys;

  /// No description provided for @east.
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get east;

  /// No description provided for @allRatings.
  ///
  /// In en, this message translates to:
  /// **'All ratings'**
  String get allRatings;

  /// No description provided for @tieTheBaby.
  ///
  /// In en, this message translates to:
  /// **'Tie the baby'**
  String get tieTheBaby;

  /// No description provided for @enterYourChildsEmailTo.
  ///
  /// In en, this message translates to:
  /// **'Enter your child\'s Email to link the profile.'**
  String get enterYourChildsEmailTo;

  /// No description provided for @snap.
  ///
  /// In en, this message translates to:
  /// **'Snap'**
  String get snap;

  /// No description provided for @userWithThisEmailWas.
  ///
  /// In en, this message translates to:
  /// **'User with this email was not found'**
  String get userWithThisEmailWas;

  /// No description provided for @theChildIsSuccessfullyAttached.
  ///
  /// In en, this message translates to:
  /// **'The child is successfully attached'**
  String get theChildIsSuccessfullyAttached;

  /// No description provided for @childrenAreNotAttached.
  ///
  /// In en, this message translates to:
  /// **'Children are not attached'**
  String get childrenAreNotAttached;

  /// No description provided for @useYourChildsCodeTo.
  ///
  /// In en, this message translates to:
  /// **'Use your child\'s code to link your profile'**
  String get useYourChildsCodeTo;

  /// No description provided for @creatingClasses.
  ///
  /// In en, this message translates to:
  /// **'Creating classes'**
  String get creatingClasses;

  /// No description provided for @coolFactory.
  ///
  /// In en, this message translates to:
  /// **'Cool factory'**
  String get coolFactory;

  /// No description provided for @enterTheNamesOfThe.
  ///
  /// In en, this message translates to:
  /// **'Enter the names of the classes you want to bulk create.'**
  String get enterTheNamesOfThe;

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add more'**
  String get addMore;

  /// No description provided for @createAllClasses.
  ///
  /// In en, this message translates to:
  /// **'CREATE ALL CLASSES'**
  String get createAllClasses;

  /// No description provided for @classSettings.
  ///
  /// In en, this message translates to:
  /// **'Class Settings'**
  String get classSettings;

  /// No description provided for @generalSettings1.
  ///
  /// In en, this message translates to:
  /// **'General settings'**
  String get generalSettings1;

  /// No description provided for @invitationCode.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get invitationCode;

  /// No description provided for @unknownKey11.
  ///
  /// In en, this message translates to:
  /// **'Нет кода'**
  String get unknownKey11;

  /// No description provided for @studentPermissions.
  ///
  /// In en, this message translates to:
  /// **'Student Permissions'**
  String get studentPermissions;

  /// No description provided for @allowStudentsToWriteMessages.
  ///
  /// In en, this message translates to:
  /// **'Allow students to write messages in the general chat'**
  String get allowStudentsToWriteMessages;

  /// No description provided for @publicationsInTheFeed.
  ///
  /// In en, this message translates to:
  /// **'Publications in the feed'**
  String get publicationsInTheFeed;

  /// No description provided for @allowStudentsToCreateNews.
  ///
  /// In en, this message translates to:
  /// **'Allow students to create news feed posts'**
  String get allowStudentsToCreateNews;

  /// No description provided for @moderationOfEntry.
  ///
  /// In en, this message translates to:
  /// **'Moderation of entry'**
  String get moderationOfEntry;

  /// No description provided for @requireTeacherApprovalForNew.
  ///
  /// In en, this message translates to:
  /// **'Require teacher approval for new members'**
  String get requireTeacherApprovalForNew;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @thisActionCannotBeUndone1.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All data will be deleted.'**
  String get thisActionCannotBeUndone1;

  /// No description provided for @changeName.
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get changeName;

  /// No description provided for @deleteAClass.
  ///
  /// In en, this message translates to:
  /// **'Delete a class?'**
  String get deleteAClass;

  /// No description provided for @allMessagesAssignmentsAndGrades.
  ///
  /// In en, this message translates to:
  /// **'All messages, assignments and grades will be permanently deleted.'**
  String get allMessagesAssignmentsAndGrades;

  /// No description provided for @theLibraryIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'The library is empty'**
  String get theLibraryIsEmpty;

  /// No description provided for @studyMaterialsAndLecturesWill.
  ///
  /// In en, this message translates to:
  /// **'Study materials and lectures will be displayed here.'**
  String get studyMaterialsAndLecturesWill;

  /// No description provided for @deleteMaterial.
  ///
  /// In en, this message translates to:
  /// **'Delete material?'**
  String get deleteMaterial;

  /// No description provided for @addMaterial.
  ///
  /// In en, this message translates to:
  /// **'Add material'**
  String get addMaterial;

  /// No description provided for @forExampleLecture1Introduction.
  ///
  /// In en, this message translates to:
  /// **'for example: Lecture 1. Introduction'**
  String get forExampleLecture1Introduction;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select file'**
  String get selectFile;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @upcomingSchedule.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING SCHEDULE'**
  String get upcomingSchedule;

  /// No description provided for @upcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING TASKS'**
  String get upcomingTasks;

  /// No description provided for @successInTheClass.
  ///
  /// In en, this message translates to:
  /// **'SUCCESS IN THE CLASS'**
  String get successInTheClass;

  /// No description provided for @adminMode.
  ///
  /// In en, this message translates to:
  /// **'ADMIN MODE'**
  String get adminMode;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @upcomingClasses.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING CLASSES'**
  String get upcomingClasses;

  /// No description provided for @noClasses.
  ///
  /// In en, this message translates to:
  /// **'No classes'**
  String get noClasses;

  /// No description provided for @tasksForTesting.
  ///
  /// In en, this message translates to:
  /// **'TASKS FOR TESTING'**
  String get tasksForTesting;

  /// No description provided for @unknownKey12.
  ///
  /// In en, this message translates to:
  /// **'Без предмета'**
  String get unknownKey12;

  /// No description provided for @allTasksHaveBeenChecked.
  ///
  /// In en, this message translates to:
  /// **'All tasks have been checked ✨'**
  String get allTasksHaveBeenChecked;

  /// No description provided for @newJob.
  ///
  /// In en, this message translates to:
  /// **'New job'**
  String get newJob;

  /// No description provided for @studentPortal.
  ///
  /// In en, this message translates to:
  /// **'Student Portal'**
  String get studentPortal;

  /// No description provided for @noClass.
  ///
  /// In en, this message translates to:
  /// **'No class'**
  String get noClass;

  /// No description provided for @n9bClass.
  ///
  /// In en, this message translates to:
  /// **'9B class'**
  String get n9bClass;

  /// No description provided for @toChangeYourEmailContact.
  ///
  /// In en, this message translates to:
  /// **'To change your email, contact your teacher.'**
  String get toChangeYourEmailContact;

  /// No description provided for @useInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Use invitation code'**
  String get useInvitationCode;

  /// No description provided for @teacherAccess.
  ///
  /// In en, this message translates to:
  /// **'Teacher access'**
  String get teacherAccess;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get requestSent;

  /// No description provided for @requestTeacherPermissions.
  ///
  /// In en, this message translates to:
  /// **'Request teacher permissions'**
  String get requestTeacherPermissions;

  /// No description provided for @onlyFromTeachers.
  ///
  /// In en, this message translates to:
  /// **'Only from teachers'**
  String get onlyFromTeachers;

  /// No description provided for @submitARequestForA.
  ///
  /// In en, this message translates to:
  /// **'Submit a request for a teacher\'s license? An administrator will need to approve it.'**
  String get submitARequestForA;

  /// No description provided for @studyHomework.
  ///
  /// In en, this message translates to:
  /// **'Study · Homework'**
  String get studyHomework;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My tasks'**
  String get myTasks;

  /// No description provided for @searchForTasks.
  ///
  /// In en, this message translates to:
  /// **'Search for tasks...'**
  String get searchForTasks;

  /// No description provided for @focusMode.
  ///
  /// In en, this message translates to:
  /// **'FOCUS MODE'**
  String get focusMode;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @rated.
  ///
  /// In en, this message translates to:
  /// **'Rated'**
  String get rated;

  /// No description provided for @unknownKey13.
  ///
  /// In en, this message translates to:
  /// **'Задание'**
  String get unknownKey13;

  /// No description provided for @urgently.
  ///
  /// In en, this message translates to:
  /// **'URGENTLY'**
  String get urgently;

  /// No description provided for @noDeadline.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get noDeadline;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get startNow;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get expired;

  /// No description provided for @subjectGeneral.
  ///
  /// In en, this message translates to:
  /// **'Subject: general'**
  String get subjectGeneral;

  /// No description provided for @everythingIsDone.
  ///
  /// In en, this message translates to:
  /// **'Everything is done!'**
  String get everythingIsDone;

  /// No description provided for @thereAreNoTasksYet.
  ///
  /// In en, this message translates to:
  /// **'There are no tasks yet.'**
  String get thereAreNoTasksYet;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @selectDueDate.
  ///
  /// In en, this message translates to:
  /// **'Select due date'**
  String get selectDueDate;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get deleteTask;

  /// No description provided for @allSubmittedWorkForThis.
  ///
  /// In en, this message translates to:
  /// **'All submitted work for this assignment will also be deleted.'**
  String get allSubmittedWorkForThis;

  /// No description provided for @completedWorks.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED WORKS'**
  String get completedWorks;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @createATask.
  ///
  /// In en, this message translates to:
  /// **'Create a task'**
  String get createATask;

  /// No description provided for @jobFiles.
  ///
  /// In en, this message translates to:
  /// **'Job files:'**
  String get jobFiles;

  /// No description provided for @noAttachments.
  ///
  /// In en, this message translates to:
  /// **'No attachments'**
  String get noAttachments;

  /// No description provided for @attachFiles.
  ///
  /// In en, this message translates to:
  /// **'Attach files'**
  String get attachFiles;

  /// No description provided for @pleaseEnterATitleAnd.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title and select a date'**
  String get pleaseEnterATitleAnd;

  /// No description provided for @active1.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active1;

  /// No description provided for @actively1.
  ///
  /// In en, this message translates to:
  /// **'ACTIVELY'**
  String get actively1;

  /// No description provided for @exportWillBeAvailableSoon.
  ///
  /// In en, this message translates to:
  /// **'Export will be available soon'**
  String get exportWillBeAvailableSoon;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @deleteTask1.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get deleteTask1;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published: -'**
  String get published;

  /// No description provided for @term.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get term;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max.'**
  String get max;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @verified1.
  ///
  /// In en, this message translates to:
  /// **'verified'**
  String get verified1;

  /// No description provided for @noWorkYet.
  ///
  /// In en, this message translates to:
  /// **'No work yet'**
  String get noWorkYet;

  /// No description provided for @rated1.
  ///
  /// In en, this message translates to:
  /// **'RATED'**
  String get rated1;

  /// No description provided for @underCheck.
  ///
  /// In en, this message translates to:
  /// **'UNDER CHECK'**
  String get underCheck;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get noTasks;

  /// No description provided for @createYourFirstAssignmentFor.
  ///
  /// In en, this message translates to:
  /// **'Create your first assignment for this class.'**
  String get createYourFirstAssignmentFor;

  /// No description provided for @justNow1.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow1;

  /// No description provided for @bookmarksWillAppearInThe.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks will appear in the next update'**
  String get bookmarksWillAppearInThe;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noCommentsYet;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @addAComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addAComment;

  /// No description provided for @ribbon.
  ///
  /// In en, this message translates to:
  /// **'Ribbon'**
  String get ribbon;

  /// No description provided for @announcementsFromYourTeachers.
  ///
  /// In en, this message translates to:
  /// **'Announcements from your teachers'**
  String get announcementsFromYourTeachers;

  /// No description provided for @searchByAdvertisements.
  ///
  /// In en, this message translates to:
  /// **'Search by advertisements...'**
  String get searchByAdvertisements;

  /// No description provided for @thereAreNoAnnouncementsYet.
  ///
  /// In en, this message translates to:
  /// **'There are no announcements yet.'**
  String get thereAreNoAnnouncementsYet;

  /// No description provided for @declarationsForYourClasses.
  ///
  /// In en, this message translates to:
  /// **'Declarations for your classes'**
  String get declarationsForYourClasses;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get newPost;

  /// No description provided for @postAnAnnouncementForClasses.
  ///
  /// In en, this message translates to:
  /// **'Post an announcement for classes...'**
  String get postAnAnnouncementForClasses;

  /// No description provided for @attachAnImage.
  ///
  /// In en, this message translates to:
  /// **'Attach an image'**
  String get attachAnImage;

  /// No description provided for @pinThisAd.
  ///
  /// In en, this message translates to:
  /// **'Pin this ad'**
  String get pinThisAd;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @mySchedule.
  ///
  /// In en, this message translates to:
  /// **'My schedule'**
  String get mySchedule;

  /// No description provided for @unknownKey14.
  ///
  /// In en, this message translates to:
  /// **'Классы'**
  String get unknownKey14;

  /// No description provided for @dayOfTheWeek.
  ///
  /// In en, this message translates to:
  /// **'Day of the week'**
  String get dayOfTheWeek;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @officenote.
  ///
  /// In en, this message translates to:
  /// **'Office/note'**
  String get officenote;

  /// No description provided for @firstSelectAClass.
  ///
  /// In en, this message translates to:
  /// **'First select a class'**
  String get firstSelectAClass;

  /// No description provided for @theEndMustBeLater.
  ///
  /// In en, this message translates to:
  /// **'The end must be later than the beginning'**
  String get theEndMustBeLater;

  /// No description provided for @selectDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Select day of week'**
  String get selectDayOfWeek;

  /// No description provided for @violet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get violet;

  /// No description provided for @emerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get emerald;

  /// No description provided for @amber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get amber;

  /// No description provided for @scarlet.
  ///
  /// In en, this message translates to:
  /// **'Scarlet'**
  String get scarlet;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @aboutTheApplication.
  ///
  /// In en, this message translates to:
  /// **'About the application'**
  String get aboutTheApplication;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @youWillBeRedirectedTo.
  ///
  /// In en, this message translates to:
  /// **'You will be redirected to the login screen'**
  String get youWillBeRedirectedTo;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @areYouATeacher.
  ///
  /// In en, this message translates to:
  /// **'Are you a teacher?'**
  String get areYouATeacher;

  /// No description provided for @loginAsTeacher.
  ///
  /// In en, this message translates to:
  /// **'Login as teacher'**
  String get loginAsTeacher;

  /// No description provided for @enterInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter invitation code'**
  String get enterInvitationCode;

  /// No description provided for @codeNotFoundCheckAnd.
  ///
  /// In en, this message translates to:
  /// **'Code not found. Check and try again.'**
  String get codeNotFoundCheckAnd;

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please login first.'**
  String get pleaseLoginFirst;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @inviteToClass.
  ///
  /// In en, this message translates to:
  /// **'Invite to class'**
  String get inviteToClass;

  /// No description provided for @showThisQrCodeTo.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code to your students or send them a direct link.'**
  String get showThisQrCodeTo;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied!'**
  String get linkCopied;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @chatHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Chat history cleared'**
  String get chatHistoryCleared;

  /// No description provided for @removingAClass.
  ///
  /// In en, this message translates to:
  /// **'Removing a class...'**
  String get removingAClass;

  /// No description provided for @classDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Class deleted successfully'**
  String get classDeletedSuccessfully;

  /// No description provided for @createAClassToOpen.
  ///
  /// In en, this message translates to:
  /// **'Create a class to open this section.'**
  String get createAClassToOpen;

  /// No description provided for @youDontHaveAnyClasses.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any classes yet'**
  String get youDontHaveAnyClasses;

  /// No description provided for @addStudentsAndGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add students and get started.'**
  String get addStudentsAndGetStarted;

  /// No description provided for @waitToBeAddedTo.
  ///
  /// In en, this message translates to:
  /// **'Wait to be added to the class.'**
  String get waitToBeAddedTo;

  /// No description provided for @createAClass.
  ///
  /// In en, this message translates to:
  /// **'Create a class'**
  String get createAClass;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @may1.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may1;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @setADeadline.
  ///
  /// In en, this message translates to:
  /// **'Set a deadline'**
  String get setADeadline;

  /// No description provided for @yourWork.
  ///
  /// In en, this message translates to:
  /// **'Your work'**
  String get yourWork;

  /// No description provided for @notesForWork.
  ///
  /// In en, this message translates to:
  /// **'Notes for work'**
  String get notesForWork;

  /// No description provided for @addFiles.
  ///
  /// In en, this message translates to:
  /// **'Add files'**
  String get addFiles;

  /// No description provided for @pleaseEnterYourEmailAnd.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email and password'**
  String get pleaseEnterYourEmailAnd;

  /// No description provided for @pleaseFillInAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillInAllFields;

  /// No description provided for @enterYourEmailToReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset your password'**
  String get enterYourEmailToReset;

  /// No description provided for @passwordResetError.
  ///
  /// In en, this message translates to:
  /// **'Password reset error'**
  String get passwordResetError;

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidEmailOrPassword;

  /// No description provided for @thisEmailIsAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get thisEmailIsAlreadyRegistered;

  /// No description provided for @passwordIsTooWeakMinimum.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak (minimum 6 characters)'**
  String get passwordIsTooWeakMinimum;

  /// No description provided for @unknownKey15.
  ///
  /// In en, this message translates to:
  /// **'Нет подключения к сети'**
  String get unknownKey15;

  /// No description provided for @somethingWentWrongTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get somethingWentWrongTryAgain;

  /// No description provided for @singleClassForChatnfeedAnd.
  ///
  /// In en, this message translates to:
  /// **'Single class for chat,\\nfeed and homework.'**
  String get singleClassForChatnfeedAnd;

  /// No description provided for @realtimeClassChat.
  ///
  /// In en, this message translates to:
  /// **'Real-time class chat'**
  String get realtimeClassChat;

  /// No description provided for @adsAndFeed.
  ///
  /// In en, this message translates to:
  /// **'Ads and feed'**
  String get adsAndFeed;

  /// No description provided for @assignmentsAndAssessments.
  ///
  /// In en, this message translates to:
  /// **'Assignments and assessments'**
  String get assignmentsAndAssessments;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back 👋'**
  String get welcomeBack;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @emailMail.
  ///
  /// In en, this message translates to:
  /// **'Email mail'**
  String get emailMail;

  /// No description provided for @forgotYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotYourPassword;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAnAccount;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAnAccount;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @joinTheClassToAccess.
  ///
  /// In en, this message translates to:
  /// **'Join the class to access this section.'**
  String get joinTheClassToAccess;

  /// No description provided for @enterTheTeacherInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the teacher invitation code to open the chat, feed, and assignments.'**
  String get enterTheTeacherInvitationCode;

  /// No description provided for @joinTheClass.
  ///
  /// In en, this message translates to:
  /// **'Join the class'**
  String get joinTheClass;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'- OR -'**
  String get or;

  /// No description provided for @theCameraWillBeAvailable.
  ///
  /// In en, this message translates to:
  /// **'The camera will be available in the next update'**
  String get theCameraWillBeAvailable;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQrCode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get enterCode;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// No description provided for @previewNotAvailableOnThis.
  ///
  /// In en, this message translates to:
  /// **'Preview not available on this platform'**
  String get previewNotAvailableOnThis;

  /// No description provided for @teacher1.
  ///
  /// In en, this message translates to:
  /// **'TEACHER'**
  String get teacher1;

  /// No description provided for @classText.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classText;

  /// No description provided for @cloudStorageManagement.
  ///
  /// In en, this message translates to:
  /// **'Cloud Storage Management'**
  String get cloudStorageManagement;

  /// No description provided for @loadingCloudStorageStats.
  ///
  /// In en, this message translates to:
  /// **'Loading cloud storage statistics...'**
  String get loadingCloudStorageStats;

  /// No description provided for @googleDriveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stores library resources and large lessons'**
  String get googleDriveSubtitle;

  /// No description provided for @cloudinarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stores images, short videos, and feed posts'**
  String get cloudinarySubtitle;

  /// No description provided for @firebaseStorageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stores auxiliary files, avatars, and configuration images'**
  String get firebaseStorageSubtitle;

  /// No description provided for @cleaningUpStorage.
  ///
  /// In en, this message translates to:
  /// **'Cleaning up storage...'**
  String get cleaningUpStorage;

  /// No description provided for @cleanUpRedundantData.
  ///
  /// In en, this message translates to:
  /// **'Clean up redundant data on system'**
  String get cleanUpRedundantData;

  /// No description provided for @confirmCleanup.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cleanup'**
  String get confirmCleanup;

  /// No description provided for @confirmCleanupDesc.
  ///
  /// In en, this message translates to:
  /// **'The system will scan and clean up orphan files (garbage files) that have been deleted in the app but still exist on cloud services (Google Drive, Cloudinary, Firebase). This process may take 1-2 minutes.'**
  String get confirmCleanupDesc;

  /// No description provided for @startCleanup.
  ///
  /// In en, this message translates to:
  /// **'Start Cleanup'**
  String get startCleanup;

  /// No description provided for @cleanupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cleanup successful! Deleted {count} redundant files, freed up {size}.'**
  String cleanupSuccess(String count, String size);

  /// No description provided for @cleanupFailed.
  ///
  /// In en, this message translates to:
  /// **'Cleanup failed: {error}'**
  String cleanupFailed(String error);

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks'**
  String get searchTasks;

  /// No description provided for @personalizationAndAccountManagement.
  ///
  /// In en, this message translates to:
  /// **'Personalization and account management'**
  String get personalizationAndAccountManagement;

  /// No description provided for @cabinetWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Room {number}'**
  String cabinetWithNumber(String number);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
