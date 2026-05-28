// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get yourClassroomConnected => 'Твой класс,\nвсегда на связи.';

  @override
  String get onboardingWelcomeDesc =>
      'School World объединяет чат, домашние задания и объявления, чтобы вы не пропустили ничего важного от учителей.';

  @override
  String get getStarted => 'Начать';

  @override
  String get whoIsJoining => 'Кто присоединяется сегодня?';

  @override
  String get pickRoleDesc =>
      'Выберите свою роль. Мы адаптируем приложение под ваши задачи.';

  @override
  String get student => 'Ученик';

  @override
  String get studentDesc => 'Вступайте в классы, общайтесь, сдавайте задания';

  @override
  String get teacher => 'Учитель';

  @override
  String get teacherDesc => 'Управляйте классами, публикуйте материалы';

  @override
  String get parent => 'Родитель';

  @override
  String get parentDesc => 'Следите за успехами и оценками вашего ребенка';

  @override
  String continueAs(String role) {
    return 'Продолжить как $role';
  }

  @override
  String get chooseYourClasses => 'Выберите ваши классы';

  @override
  String get inviteCodeDesc =>
      'Введите код приглашения, чтобы просмотреть и вступить в класс.';

  @override
  String get inviteCode => 'Код приглашения';

  @override
  String get previewClass => 'Просмотр класса';

  @override
  String get joinClass => 'Вступить в класс';

  @override
  String get cancel => 'Отмена';

  @override
  String get join => 'Вступить';

  @override
  String get signOut => 'Выйти';

  @override
  String get today => 'Сегодня';

  @override
  String get chat => 'Чат';

  @override
  String get feed => 'Лента';

  @override
  String get homework => 'Задания';

  @override
  String get profile => 'Профиль';

  @override
  String get phone => 'Телефон';

  @override
  String get email => 'Эл. почта';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get verify => 'Проверить';

  @override
  String get signIn => 'Войти';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get otp => 'Код из СМС';

  @override
  String get password => 'Пароль';

  @override
  String get enterPhoneError => 'Пожалуйста, введите номер телефона.';

  @override
  String get enterOtpError => 'Введите 6-значный код.';

  @override
  String get teacherWorkspace => 'Рабочая область учителя';

  @override
  String get createClass => 'Создать класс';

  @override
  String get settings => 'Настройки';

  @override
  String get language => 'Язык';

  @override
  String get english => 'Английский';

  @override
  String get russian => 'Русский';

  @override
  String get joinAClass => 'Вступить в класс';

  @override
  String get inviteCodeNotFound => 'Код приглашения не найден.';

  @override
  String hiName(String name) {
    return 'Привет, $name';
  }

  @override
  String get todaysClasses => 'Занятия на сегодня';

  @override
  String get quickLinks => 'Быстрые ссылки';

  @override
  String get homeworkPortal => 'Портал заданий';

  @override
  String get myGrades => 'Мои оценки';

  @override
  String get notifications => 'Уведомления';

  @override
  String get classRoster => 'Список класса';

  @override
  String learningStreak(int count) {
    return 'Ударный режим: $count дн.';
  }

  @override
  String homeworksDone(int done, int total) {
    return 'Выполнено: $done из $total';
  }

  @override
  String get selected => 'Выбрано';

  @override
  String get pickClassToChat => 'Выберите класс для общения.';

  @override
  String get noMessagesYet => 'Сообщений пока нет.';

  @override
  String get messageYourClass => 'Напишите классу';

  @override
  String get send => 'Отправить';

  @override
  String get classChat => 'Чат класса';

  @override
  String get classRoom => 'Классная комната';

  @override
  String studentsCount(int count) {
    return 'Учеников: $count';
  }

  @override
  String get searchMessages => 'Поиск сообщений';

  @override
  String get you => 'Вы';

  @override
  String get classmate => 'Одноклассник';

  @override
  String get pickClassToReadAnnouncements =>
      'Выберите класс для просмотра объявлений.';

  @override
  String get noAnnouncementsYet => 'Объявлений пока нет.';

  @override
  String get teacherUpdate => 'Обновление учителя';

  @override
  String get announcement => 'Объявление';

  @override
  String get pinned => 'Закреплено';

  @override
  String get commentsSoon => 'Комментарии скоро появятся';

  @override
  String get pickClassToViewHomework => 'Выберите класс для просмотра заданий.';

  @override
  String get noHomeworkAssigned => 'Заданий пока нет.';

  @override
  String get assignment => 'Задание';

  @override
  String get submit => 'Сдать';

  @override
  String get studentAccount => 'Аккаунт ученика';

  @override
  String get joinAnotherClass => 'Вступить в другой класс';

  @override
  String get inviteCodeFromTeacher => 'Используйте код приглашения от учителя';

  @override
  String get unreadUpdates => 'Непрочитанные обновления и напоминания';

  @override
  String get privacyAndSafety => 'Приватность и безопасность';

  @override
  String get protectedFiles => 'Обмен сообщениями и защищенные файлы';

  @override
  String get submitHomework => 'Сдать задание';

  @override
  String get notes => 'Заметки';

  @override
  String get addNoteForTeacher => 'Добавьте короткую заметку для учителя';

  @override
  String get joinYourFirstClass => 'Вступите в свой первый класс';

  @override
  String get joinFirstClassDesc =>
      'Используйте код приглашения, чтобы открыть чат, ленту и задания.';

  @override
  String get noDueDate => 'Срок сдачи не установлен';

  @override
  String due(String date) {
    return 'Срок: $date';
  }

  @override
  String get justNow => 'Только что';

  @override
  String get post => 'Пост';

  @override
  String get work => 'Работа';

  @override
  String get createPost => 'Создать пост';

  @override
  String get createAssignment => 'Создать задание';

  @override
  String get noClassMessages => 'Сообщений в классе пока нет.';

  @override
  String get messageThisClass => 'Напишите этому классу';

  @override
  String get noPostsYet => 'Постов пока нет.';

  @override
  String get unpin => 'Открепить';

  @override
  String get pin => 'Закрепить';

  @override
  String get noAssignmentsYet => 'Заданий пока нет.';

  @override
  String get createYourFirstClass => 'Создайте свой первый класс';

  @override
  String get teacherEmptyDesc =>
      'Классы включают коды приглашения для учеников и родителей.';

  @override
  String get className => 'Название класса';

  @override
  String get subject => 'Предмет';

  @override
  String get create => 'Создать';

  @override
  String get title => 'Заголовок';

  @override
  String get instructions => 'Инструкции';

  @override
  String get dueDate => 'Срок сдачи';

  @override
  String get parentDashboard => 'Панель родителя';

  @override
  String get noClassesLinked => 'Нет связанных классов.';

  @override
  String teacherLabel(String name) {
    return 'Учитель: $name';
  }

  @override
  String get grade => 'Оценка';

  @override
  String get submitted => 'Сдано';

  @override
  String get notSubmitted => 'Не сдано';

  @override
  String get noGradesYet => 'Оценок пока нет.';

  @override
  String get noSubmissionsYet => 'Пока нет сданных работ.';

  @override
  String get ungraded => 'Не оценено';

  @override
  String get gradeSubmission => 'Оценить работу';

  @override
  String get feedback => 'Отзыв';

  @override
  String get save => 'Сохранить';

  @override
  String get name => 'Имя';

  @override
  String get overdue => 'Просрочено';

  @override
  String get classStatistics => 'Статистика класса';

  @override
  String get totalStudents => 'Всего студентов';

  @override
  String get avgGrade => 'Средний балл';

  @override
  String get profileUpdated => 'Профиль обновлен';

  @override
  String get noStudentsInClass => 'В этом классе пока нет студентов.';

  @override
  String get assignments => 'Задания';

  @override
  String get errorGeneric => 'Произошла ошибка. Повторите попытку.';

  @override
  String get recurring => 'Повторяющийся';

  @override
  String get oneOff => 'Разовый';

  @override
  String get monday => 'Понедельник';

  @override
  String get tuesday => 'Вторник';

  @override
  String get wednesday => 'Среда';

  @override
  String get thursday => 'Четверг';

  @override
  String get friday => 'Пятница';

  @override
  String get saturday => 'Суббота';

  @override
  String get sunday => 'Воскресенье';

  @override
  String get savedSchedule => 'Расписание сохранено!';

  @override
  String get deleteSchedule => 'Удалить расписание?';

  @override
  String get deleteScheduleDesc => 'Это удалит слот и его переопределения.';

  @override
  String get deletedSchedule => 'Расписание удалено';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get avatarUpdated => 'Аватар успешно обновлен';

  @override
  String failedToUploadAvatar(Object error) {
    return 'Не удалось загрузить аватар: $error';
  }

  @override
  String get nameEmptyError => 'Имя не может быть пустым';

  @override
  String get profileUpdatedDesc => 'Профиль успешно обновлен';

  @override
  String failedToUpdateProfile(Object error) {
    return 'Не удалось обновить профиль: $error';
  }

  @override
  String get confirmSignOut => 'Вы уверены, что хотите выйти?';

  @override
  String get previewClassAction => 'Предварительный просмотр';

  @override
  String get skipOnboardingTeacher => 'Я учитель, пропустить этот шаг';

  @override
  String get needsReviewToday => 'Нужно проверить сегодня';

  @override
  String studentSubmissions(int count) {
    return 'Сдано работ: $count';
  }

  @override
  String get noClassesScheduled => 'На сегодня занятий не запланировано';

  @override
  String get openWeeklySchedule => 'Открыть недельное расписание';

  @override
  String get quickActions => 'БЫСТРЫЕ ДЕЙСТВИЯ';

  @override
  String get postAnnouncement => 'Опубликовать объявление';

  @override
  String get pinWorksheet => 'Закрепить материал';

  @override
  String get takeAttendance => 'Отметить посещаемость';

  @override
  String get gradeSubmissions => 'Оценить работы';

  @override
  String get copyGuestChatLink => 'Копировать гостевую ссылку';

  @override
  String get deleteClass => 'Удалить класс';

  @override
  String get unpinPost => 'Открепить пост';

  @override
  String get pinPost => 'Закрепить пост';

  @override
  String get deletePost => 'Удалить пост';

  @override
  String get deletePostDesc =>
      'Этот пост и комментарии к нему будут удалены навсегда.';

  @override
  String get publishPost => 'Опубликовать пост';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get couldNotOpenAttachment => 'Не удалось открыть вложение.';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get assignmentNotFound => 'Задание не найдено';

  @override
  String submissionFailed(String error) {
    return 'Ошибка сдачи: $error';
  }

  @override
  String get submitting => 'Отправка...';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get helpCenter => 'Справочный центр';

  @override
  String get darkMode => 'Темная тема';

  @override
  String get studentPortalTerm3 => 'Портал ученика · 3 четверть';

  @override
  String get generalSettings => 'ОБЩИЕ НАСТРОЙКИ';

  @override
  String get accountAndClasses => 'АККАУНТ И КЛАССЫ';

  @override
  String get helpAndAbout => 'ПОМОЩЬ И О ПРИЛОЖЕНИИ';

  @override
  String get addNote => 'Добавить новый код класса';

  @override
  String get viewAll => 'Смотреть все';

  @override
  String get live => 'В ЭФИРЕ';

  @override
  String get done => 'ЗАВЕРШЕНО';

  @override
  String get upcoming => 'ПРЕДСТОЯЩИЕ';

  @override
  String inMin(int min) {
    return 'ЧЕРЕЗ $min МИН';
  }

  @override
  String get cancelled => 'ОТМЕНЕНО';

  @override
  String get goodMorning => 'Доброе утро';

  @override
  String get goodAfternoon => 'Добрый день';

  @override
  String get goodEvening => 'Добрый вечер';

  @override
  String get teacherAttachments => 'Вложения учителя';

  @override
  String get reply => 'Ответить';

  @override
  String get copyText => 'Копировать текст';

  @override
  String get delete => 'Удалить';

  @override
  String get freePlan => 'Бесплатный';

  @override
  String get currentPlan => 'Ваш текущий план';

  @override
  String get upgrade => 'Улучшить';

  @override
  String get soonAvailable => 'Скоро доступно';

  @override
  String get contactSupportForEmail => 'Для смены email обратитесь в поддержку';

  @override
  String get noConnection => 'Нет подключения';

  @override
  String get newTopic => 'Новая тема';

  @override
  String get joinLessonSoon => 'Вход в урок скоро будет доступен';

  @override
  String get now => 'СЕЙЧАС';

  @override
  String get later => 'ПОЗЖЕ';

  @override
  String get allChecked => 'Всё проверено!';

  @override
  String get selectClassFirst => 'Сначала выберите класс.';

  @override
  String get classNotFound => 'Класс не найден.';

  @override
  String get removeFromClass => 'Удалить из класса?';

  @override
  String get removeFromClassDesc =>
      'Ученик потеряет доступ к материалам и чату этого класса.';

  @override
  String get badges => 'Значков';

  @override
  String get copyInviteLink => 'Скопировать ссылку';

  @override
  String get clearChat => 'Очистить чат';

  @override
  String get teacherBadge => 'ПРЕПОДАВАТЕЛЬ';

  @override
  String totalParticipants(int count) {
    return '$count участников всего';
  }

  @override
  String get active => 'АКТИВНО';

  @override
  String publishedAt(String date) {
    return 'Опубликовано: $date';
  }

  @override
  String submittedAtLabel(String date) {
    return 'Сдано: $date';
  }

  @override
  String get deleteAssignment => 'Удалить задание?';

  @override
  String get deleteAssignmentDesc =>
      'Все сданные работы этого задания также будут удалены.';

  @override
  String get editAssignment => 'Редактировать задание';

  @override
  String get bookmarksSoon => 'Закладки появятся в следующем обновлении';

  @override
  String get initializationFailed => 'Ошибка инициализации.';

  @override
  String get topics => 'Темы';

  @override
  String get mainChat => 'Общий чат';

  @override
  String get createTopic => 'Создать тему';

  @override
  String get myClasses => 'МОИ КЛАССЫ';

  @override
  String get teacherConsole => 'Панель учителя';
}
