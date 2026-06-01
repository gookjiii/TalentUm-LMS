import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase/push_notification_manager.dart';

class SchoolAppState extends ChangeNotifier {
  SchoolAppState() {
    final box = Hive.box('app_settings');
    currentRole = box.get('role') as String?;
    selectedClassId = box.get('selectedClassId') as String?;
    lastChatClassId = box.get('lastChatClassId') as String?;
    _isDarkMode = box.get('isDarkMode', defaultValue: false) as bool;
    _accentColorValue = box.get('accentColor') as int?;
    final localeCode = box.get('locale') as String?;
    _locale = localeCode != null ? Locale(localeCode) : const Locale('ru');
    _pushNotifications = box.get('pushNotifications', defaultValue: true) as bool;
    _soundAndVibe = box.get('soundAndVibe', defaultValue: true) as bool;
    _quietModeUpdates = box.get('quietModeUpdates', defaultValue: true) as bool;
    _performanceMode = box.get('performanceMode', defaultValue: false) as bool;

    // Set initial image cache bounds reactively based on stored performanceMode
    _applyImageCacheLimits();
  }

  String? currentRole;
  String? selectedClassId;
  String? lastChatClassId;
  String? lastChatTopicId;
  String? selectedAssignmentId;
  String? selectedChildId;
  String onboardingRole = 'student';
  bool joinedClassRecently = false;
  Locale? _locale;
  bool _isDarkMode = false;
  bool _pushNotifications = true;
  bool _soundAndVibe = true;
  bool _quietModeUpdates = true;
  bool _performanceMode = false;

  String? get role => currentRole;
  bool get isLeadTeacher =>
      currentRole == 'leadTeacher' || currentRole == 'admin';
  bool get isTeacher => currentRole == 'teacher' || isLeadTeacher;
  bool get isStudent => currentRole == 'student';
  bool get isParent => currentRole == 'parent';
  Locale? get locale => _locale;
  bool get isDarkMode => _isDarkMode;
  bool get performanceMode => _performanceMode;

  int _teacherTabIndex = 0;
  int get teacherTabIndex => _teacherTabIndex;

  void setTeacherTabIndex(int index) {
    if (_teacherTabIndex == index) return;
    _teacherTabIndex = index;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    Hive.box('app_settings').put('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  void setRole(String? role) {
    if (currentRole == role) return;
    currentRole = role;
    Hive.box('app_settings').put('role', role);
    notifyListeners();
  }

  void markJoined() {
    joinedClassRecently = true;
    notifyListeners();
  }

  void selectClass(String? classId) {
    if (selectedClassId == classId) return;
    selectedClassId = classId;
    Hive.box('app_settings').put('selectedClassId', classId);
    notifyListeners();
  }

  void saveChatContext({required String? classId, required String? topicId}) {
    if (lastChatClassId == classId && lastChatTopicId == topicId) return;
    lastChatClassId = classId;
    lastChatTopicId = topicId;
    final box = Hive.box('app_settings');
    box.put('lastChatClassId', classId);
    box.put('lastChatTopicId', topicId);
    notifyListeners();
  }

  void clearChatContext() {
    if (lastChatClassId == null && lastChatTopicId == null) return;
    lastChatClassId = null;
    lastChatTopicId = null;
    final box = Hive.box('app_settings');
    box.delete('lastChatClassId');
    box.delete('lastChatTopicId');
    notifyListeners();
  }

  void resetSession() {
    currentRole = null;
    selectedClassId = null;
    selectedAssignmentId = null;
    selectedChildId = null;
    joinedClassRecently = false;
    final box = Hive.box('app_settings');
    box.delete('role');
    box.delete('selectedClassId');
    box.delete('lastChatClassId');
    box.delete('lastChatTopicId');
    notifyListeners();
  }

  void setOnboardingRole(String role) {
    onboardingRole = role;
    notifyListeners();
  }

  void setLocale(Locale? locale) {
    if (_locale == locale) return;
    _locale = locale;
    Hive.box('app_settings').put('locale', locale?.languageCode);
    notifyListeners();
  }

  int? _accentColorValue;
  Color get accentColor => _accentColorValue != null
      ? Color(_accentColorValue!)
      : const Color(0xFF2563EB);

  void setAccentColor(Color color) {
    if (color.value == _accentColorValue) return;
    _accentColorValue = color.value;
    Hive.box('app_settings').put('accentColor', color.value);
    notifyListeners();
  }

  bool get pushNotifications => _pushNotifications;
  bool get soundAndVibe => _soundAndVibe;
  bool get quietModeUpdates => _quietModeUpdates;

  void setPushNotifications(bool value) {
    if (_pushNotifications == value) return;
    _pushNotifications = value;
    Hive.box('app_settings').put('pushNotifications', value);
    notifyListeners();
    
    // Reactively register or unregister the device push token on toggle
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      PushNotificationManager.syncTokenSubscription(
        userId: uid,
        enabled: value,
      );
    }
  }

  void setSoundAndVibe(bool value) {
    if (_soundAndVibe == value) return;
    _soundAndVibe = value;
    Hive.box('app_settings').put('soundAndVibe', value);
    notifyListeners();
  }

  void setQuietModeUpdates(bool value) {
    if (_quietModeUpdates == value) return;
    _quietModeUpdates = value;
    Hive.box('app_settings').put('quietModeUpdates', value);
    notifyListeners();
  }

  void setPerformanceMode(bool value) {
    if (_performanceMode == value) return;
    _performanceMode = value;
    Hive.box('app_settings').put('performanceMode', value);
    _applyImageCacheLimits();
    notifyListeners();
  }

  void _applyImageCacheLimits() {
    try {
      if (_performanceMode) {
        // High performance / Low-end graphics mode: limit RAM usage
        PaintingBinding.instance.imageCache.maximumSize = 400; // items
        PaintingBinding.instance.imageCache.maximumSizeBytes = 40 * 1024 * 1024; // 40 MB
      } else {
        // Normal mode
        PaintingBinding.instance.imageCache.maximumSize = 2000; // items
        PaintingBinding.instance.imageCache.maximumSizeBytes = 200 * 1024 * 1024; // 200 MB
      }
    } catch (e) {
      debugPrint('Error applying image cache limits: $e');
    }
  }
}
