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
  String get onboardingWelcomeDesc => 'School World объединяет чат, домашние задания и объявления, чтобы вы не пропустили ничего важного от учителей.';

  @override
  String get getStarted => 'Начать';

  @override
  String get whoIsJoining => 'Кто присоединяется сегодня?';

  @override
  String get pickRoleDesc => 'Выберите свою роль. Мы адаптируем приложение под ваши задачи.';

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
  String get inviteCodeDesc => 'Введите код приглашения, чтобы просмотреть и вступить в класс.';

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
  String get homework => 'Домашнее задание';

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
  String get more => 'Ещё';

  @override
  String get additionalSections => 'Дополнительные разделы';

  @override
  String get loadingProfile => 'Загрузка профиля...';

  @override
  String get authCheck => 'Проверка авторизации...';

  @override
  String get technicalError => 'Техническая ошибка';

  @override
  String get close => 'Закрыть';

  @override
  String get viewErrorDetails => 'Показать детали ошибки';

  @override
  String get loginWithMainAccount => 'Войти через основной аккаунт';

  @override
  String get retry => 'Попробовать снова';

  @override
  String get joiningClass => 'Вступление в класс...';

  @override
  String get viewFullError => 'Посмотреть полную ошибку';

  @override
  String get unableToJoinServerErr => 'Не удалось вступить: ошибка сервера.';

  @override
  String get errorJoiningClass => 'Произошла ошибка при вступлении в класс.';

  @override
  String get invalidLinkOrExpired => 'Неверная ссылка или код приглашения истек.';

  @override
  String get classNotExists => 'Класс не существует.';

  @override
  String get networkError => 'Ошибка сети. Пожалуйста, проверьте интернет-соединение.';

  @override
  String get joiningWait => 'Вступление...';

  @override
  String get enterClassroom => 'Войти в класс';

  @override
  String totalAssignmentsCount(int count) {
    return '$count заданий всего';
  }

  @override
  String roomWithNumber(String number) {
    return 'Room $number';
  }

  @override
  String get editedPhotoAttached => 'Измененное фото прикреплено к сообщению';

  @override
  String get avatarUpdated => 'Аватар успешно обновлен';

  @override
  String errorPrefix(String error) {
    return 'Ошибка: $error';
  }

  @override
  String errorClearingChat(Object error) {
    return 'Ошибка при очистке чата: $error';
  }

  @override
  String errorDeletingClass(Object error) {
    return 'Ошибка при удалении класса: $error';
  }

  @override
  String get reload => 'Перезагрузить';

  @override
  String get loadingSystemSettings => 'Загрузка настроек системы...';

  @override
  String uploadError(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get searchMessages => 'Поиск сообщений';

  @override
  String get you => 'Вы';

  @override
  String get classmate => 'Одноклассник';

  @override
  String get pickClassToReadAnnouncements => 'Выберите класс для просмотра объявлений.';

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
  String get joinFirstClassDesc => 'Используйте код приглашения, чтобы открыть чат, ленту и задания.';

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
  String get teacherEmptyDesc => 'Классы включают коды приглашения для учеников и родителей.';

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
  String get deletePostDesc => 'Этот пост и комментарии к нему будут удалены навсегда.';

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
  String get removeFromClassDesc => 'Ученик потеряет доступ к материалам и чату этого класса.';

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
  String get deleteAssignmentDesc => 'Все сданные работы этого задания также будут удалены.';

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

  @override
  String get coolMagazine => 'Классный журнал';

  @override
  String get myGradesAndSubjects => 'Мои оценки и предметы';

  @override
  String get academicPerformanceAndSubjects => 'Успеваемость и предметы';

  @override
  String get addALesson => 'Добавить урок';

  @override
  String get ratings => 'Оценки';

  @override
  String get items => 'Предметы';

  @override
  String get date => 'Дата';

  @override
  String get item => 'Предмет';

  @override
  String get unknownKey => 'Отмена';

  @override
  String get noLessonsAddYourFirst => 'Нет уроков. Добавьте первый урок!';

  @override
  String get noTheme => 'Без темы';

  @override
  String get january => 'ЯНВАРЯ';

  @override
  String get february => 'ФЕВРАЛЯ';

  @override
  String get martha => 'МАРТА';

  @override
  String get april => 'АПРЕЛЯ';

  @override
  String get may => 'МАЯ';

  @override
  String get june => 'ИЮНЯ';

  @override
  String get july => 'ИЮЛЯ';

  @override
  String get august => 'АВГУСТА';

  @override
  String get september => 'СЕНТЯБРЯ';

  @override
  String get october => 'ОКТЯБРЯ';

  @override
  String get november => 'НОЯБРЯ';

  @override
  String get december => 'ДЕКАБРЯ';

  @override
  String get editLesson => 'Редактировать урок';

  @override
  String get deleteLesson => 'Удалить урок?';

  @override
  String get thisActionCannotBeUndone => 'Это действие нельзя отменить.';

  @override
  String get youDontHaveRatingsYet => 'У вас пока нет оценок.';

  @override
  String get theMagazineIsEmptyAdd => 'Журнал пуст. Добавьте первый урок!';

  @override
  String get myRatings => 'Мои оценки';

  @override
  String get unknownKey1 => 'Загрузка...';

  @override
  String get n => 'н';

  @override
  String get rate => 'Оценить';

  @override
  String get unknownKey2 => 'Отлично';

  @override
  String get unknownKey3 => 'Хорошо';

  @override
  String get unknownKey4 => 'Удовлетворительно';

  @override
  String get unknownKey5 => 'Плохо';

  @override
  String get n1 => 'Н';

  @override
  String get absent => 'Отсутствует';

  @override
  String get clearMark => 'Очистить отметку';

  @override
  String get adminPanel => 'Админ-панель';

  @override
  String get systemManagementAndActivityAnalytics => 'Управление системой и аналитика активности';

  @override
  String get totalUsers => 'Всего пользователей';

  @override
  String get activeChats => 'Активные чаты';

  @override
  String get postsToday => 'Сообщений сегодня';

  @override
  String get appBranding => 'Брендинг приложения';

  @override
  String get quickActions1 => 'Быстрые действия';

  @override
  String get users => 'Пользователи';

  @override
  String get roleManagementAndBan => 'Управление ролями и бан';

  @override
  String get allClasses => 'Все классы';

  @override
  String get reviewAndModeration => 'Просмотр и модерация';

  @override
  String get applicationsForTeachers => 'Заявки в учителя';

  @override
  String get moderationOfRequests => 'Модерация запросов';

  @override
  String get latestUsers => 'Последние пользователи';

  @override
  String get noData => 'Нет данных';

  @override
  String get registered => 'зарегистрировался';

  @override
  String get recently => 'недавно';

  @override
  String get logoLoaded => 'Логотип загружен';

  @override
  String get applicationName => 'Название приложения';

  @override
  String get enterAName => 'Введите название';

  @override
  String get settingsSaved => 'Настройки сохранены';

  @override
  String get saveChanges1 => 'Сохранить изменения';

  @override
  String get searchByNameEmailOr => 'Поиск по имени, email или ID...';

  @override
  String get noUsersFound => 'Пользователи не найдены';

  @override
  String get unknownKey6 => 'Без имени';

  @override
  String get noEmail => 'Нет email';

  @override
  String get makeAdmin => 'Сделать админом';

  @override
  String get makeItATeacher => 'Сделать учителем';

  @override
  String get makeAStudent => 'Сделать учеником';

  @override
  String get block => 'Заблокировать';

  @override
  String get unblock => 'Разблокировать';

  @override
  String get teachersLicenseIssued => 'Права учителя выданы';

  @override
  String get applicationRejected => 'Заявка отклонена';

  @override
  String get noApplications => 'Нет заявок';

  @override
  String get allRequestsProcessed => 'Все запросы обработаны';

  @override
  String get approve => 'Одобрить';

  @override
  String get reject => 'Отклонить';

  @override
  String get assignATeacher => 'Назначить учителя';

  @override
  String get classManagement => 'Управление классами';

  @override
  String get createClasses => 'Создать классы';

  @override
  String get searchByTitleOrSubject => 'Поиск по названию или предмету...';

  @override
  String get noClassesFound => 'Классы не найдены';

  @override
  String get unknownKey7 => 'Без названия';

  @override
  String get n57 => 'Школа №57';

  @override
  String get experience => 'СТАЖ';

  @override
  String get personalInformation => 'Личные данные';

  @override
  String get linkedAccounts => 'Связанные аккаунты';

  @override
  String get pushNotifications => 'Push-уведомления';

  @override
  String get allowedForChatAndTasks => 'Разрешены для чата и заданий';

  @override
  String get newMessages => 'Новые сообщения';

  @override
  String get soundVibration => 'Звук + вибрация';

  @override
  String get updates => 'Обновления';

  @override
  String get quietMode22000700 => 'Тихий режим: 22:00–07:00';

  @override
  String get confidentiality => 'Конфиденциальность';

  @override
  String get showNameToStudents => 'Показывать имя ученикам';

  @override
  String get personalMessages => 'Личные сообщения';

  @override
  String get allowStudentsToWriteDirectly => 'Разрешить ученикам писать напрямую';

  @override
  String get registration => 'Оформление';

  @override
  String get enabled => 'Включена';

  @override
  String get system => 'Системная';

  @override
  String get accentColor => 'Акцентный цвет';

  @override
  String get schoolBlue => 'Школьный синий';

  @override
  String get russianRu => 'Русский (ru)';

  @override
  String get tariffPlan => 'Тарифный план';

  @override
  String get safety => 'Безопасность';

  @override
  String get twofactorProtection => 'Двухфакторная защита';

  @override
  String get enabledAuthenticator => 'Включена · Authenticator';

  @override
  String get actively => 'Активно';

  @override
  String get downloadMyData => 'Скачать мои данные';

  @override
  String get exportToZip => 'Экспорт в ZIP';

  @override
  String get emailpassword => 'Email / Пароль';

  @override
  String get ready => 'Готово';

  @override
  String get related => 'Связано';

  @override
  String get notRelated => 'Не связано';

  @override
  String get languageChangedToRussian => 'Язык изменен на Русский';

  @override
  String get preparingAZipArchive => 'Подготовка ZIP-архива...';

  @override
  String get exportData => 'Экспорт данных';

  @override
  String get aZipArchiveWillBe => 'Будет создан ZIP-архив, содержащий все ваши личные данные, включая созданные вами классы, домашние задания, сообщения чата и профиль.';

  @override
  String get theArchiveWasSuccessfullySaved => 'Архив успешно сохранен в папку Загрузки';

  @override
  String get export => 'Экспортировать';

  @override
  String get verified => 'Проверен';

  @override
  String get postDeleted => 'Сообщение удалено';

  @override
  String get voiceMessage => 'Голосовое сообщение';

  @override
  String get teachersRoom => 'Учительская';

  @override
  String get classNotFound1 => 'Класс не найден';

  @override
  String get unknownKey8 => 'Чат класса';

  @override
  String get participant => 'Участник';

  @override
  String get newPoll => 'Новый опрос';

  @override
  String get question => 'Вопрос';

  @override
  String get addAnOption => 'Добавить вариант';

  @override
  String get attachment => 'Вложение';

  @override
  String get deleteMessage => 'Удалить сообщение?';

  @override
  String get areYouSureYouWant => 'Вы действительно хотите удалить это сообщение?';

  @override
  String get change => 'Изменить';

  @override
  String get image => '📷 Изображение';

  @override
  String get file => '📎 Файл';

  @override
  String get deleteTopic => 'Удалить тему?';

  @override
  String get teachersRoom1 => 'учительская';

  @override
  String get chats => 'Чаты';

  @override
  String get searchChats => 'Поиск чатов...';

  @override
  String get noChatsFound => 'Чаты не найдены';

  @override
  String get errorLoadingMessage => 'Ошибка загрузки сообщения';

  @override
  String get noMessagesYet1 => 'Сообщений пока нет';

  @override
  String get photography => '📷 Фотография';

  @override
  String get video => '🎥 Видео';

  @override
  String get file1 => '📁 Файл';

  @override
  String get voiceMessage1 => '🎤 Голосовое сообщение';

  @override
  String get clickToOpenChat => 'Нажмите, чтобы открыть чат';

  @override
  String get changed => 'изменено';

  @override
  String get sender => 'Отправитель';

  @override
  String get replyToAMessage => 'Ответ на сообщение';

  @override
  String get messageText => 'Текст сообщения';

  @override
  String get survey => 'ОПРОС';

  @override
  String get closed => 'ЗАКРЫТ';

  @override
  String get ov => 'ов';

  @override
  String get a => 'а';

  @override
  String get replyToMessage => 'ОТВЕТ НА СООБЩЕНИЕ';

  @override
  String get editing => 'РЕДАКТИРОВАНИЕ';

  @override
  String get failedToLoadVideo => 'Не удалось загрузить видео';

  @override
  String get video1 => 'Видео';

  @override
  String get attach => 'Прикрепить';

  @override
  String get camera => 'Камера';

  @override
  String get survey1 => 'Опрос';

  @override
  String get message => 'Сообщение';

  @override
  String get editMessage => 'Изменить сообщение';

  @override
  String get holdToRecordVoice => 'Удерживайте для записи голоса';

  @override
  String get micPermissionDenied => 'Доступ к микрофону запрещён. Включите его в настройках устройства.';

  @override
  String get releaseToView => 'Отпустите для просмотра';

  @override
  String get printing => 'Печатает...';

  @override
  String get failedToOpenCallRoom => 'Не удалось открыть комнату для звонка';

  @override
  String get clearChat1 => 'Очистить чат';

  @override
  String get areYouSureYouWant1 => 'Вы уверены, что хотите очистить всю историю чата Учительской? Это действие невозможно отменить.';

  @override
  String get clear => 'Очистить';

  @override
  String get clearingChat => 'Очистка чата...';

  @override
  String get teachersChatHasBeenSuccessfully => 'Чат Учительской успешно очищен';

  @override
  String get back => 'Назад';

  @override
  String get chatTopics => 'Темы чата';

  @override
  String get search => 'Поиск...';

  @override
  String get chatInformation => 'Информация о чате';

  @override
  String get call => 'Звонок';

  @override
  String get participants => 'Участники';

  @override
  String get mediaAndFiles => 'Медиа и файлы';

  @override
  String get searchMessages1 => 'Поиск сообщений...';

  @override
  String get startAVideoCall => 'Начать видеозвонок';

  @override
  String get clearTeachersChat => 'Очистить чат Учительской';

  @override
  String get photo => 'Фотография';

  @override
  String get pinnedMessage => 'Закреплённое сообщение';

  @override
  String get pinnedMessages => 'Закреплённые сообщения';

  @override
  String get noPinnedMessages => 'Нет закреплённых сообщений';

  @override
  String get toResources => 'К ресурсам';

  @override
  String get resources => 'Ресурсы';

  @override
  String get media => 'Медиа';

  @override
  String get files => 'Файлы';

  @override
  String get links => 'Ссылки';

  @override
  String get polls => 'Опросы';

  @override
  String get ai => 'ИИ';

  @override
  String get thereWasNoMediaYet => 'Медиа пока не было';

  @override
  String get thereAreNoFilesYet => 'Файлов пока не было';

  @override
  String get file2 => 'Файл';

  @override
  String get view => 'Просмотреть';

  @override
  String get open => 'Открыть';

  @override
  String get thereAreNoLinksYet => 'Ссылок пока не было';

  @override
  String get roomNotFound => 'Комната не найдена';

  @override
  String get noParticipantsYet => 'Участников пока нет';

  @override
  String get administrator => 'Администратор';

  @override
  String get parent1 => 'Родитель';

  @override
  String get removeAdmin => 'Убрать админа';

  @override
  String get areYouSureYouWant2 => 'Вы уверены, что хотите удалить этого ученика из класса?';

  @override
  String get cancellation => 'ОТМЕНА';

  @override
  String get delete1 => 'УДАЛИТЬ';

  @override
  String get thereAreNoPollsYet => 'Опросов пока не было';

  @override
  String get helloImYourTeachingAssistant => 'Привет! Я твой учебный ассистент. Я могу помочь тебе разобраться с материалами этого класса. Спрашивай!';

  @override
  String get interestingQuestionBasedOnThe => 'Интересный вопрос! Основываясь на материалах класса, я могу сказать, что данный аспект очень важен для понимания темы. Рекомендую обратить внимание на вторую главу учебника.';

  @override
  String get askAi => 'Спросить ИИ...';

  @override
  String get todaysGoalAchieved => 'Сегодняшняя цель достигнута';

  @override
  String get completeTheTaskSoAs => 'Выполни задание, чтобы не прервать серию';

  @override
  String get noLessonsForToday => 'Нет уроков на сегодня';

  @override
  String get library => 'Библиотека';

  @override
  String get webinars => 'Вебинары';

  @override
  String get areYouReadyFornnewKnowledge => 'Готовы к\\nновым знаниям?';

  @override
  String get canceled => 'ОТМЕНЕНО';

  @override
  String get soon => 'СКОРО';

  @override
  String get quickLinks1 => 'БЫСТРЫЕ ССЫЛКИ';

  @override
  String get magazine => 'Журнал';

  @override
  String get studentAnswer => 'Ответ ученика:';

  @override
  String get attachedFiles => 'Прикрепленные файлы:';

  @override
  String get scoreInOrPoints => 'Оценка (в % или баллах)';

  @override
  String get teachersReview => 'Отзыв учителя';

  @override
  String get pleaseEnterAValidRating => 'Пожалуйста, введите корректную оценку (число)';

  @override
  String get giveARating => 'Поставить оценку';

  @override
  String get addAStudent => 'Добавить ученика';

  @override
  String get editName => 'Редактировать имя';

  @override
  String get removeAdminRights => 'Убрать права админа';

  @override
  String get makeAsAdministrator => 'Сделать администратором';

  @override
  String get editStudentName => 'Редактировать имя ученика';

  @override
  String get studentName => 'Имя ученика';

  @override
  String get ivanIvanov => 'Иван Иванов';

  @override
  String get unknown => 'неизвестно';

  @override
  String get administrator1 => 'АДМИНИСТРАТОР';

  @override
  String get student1 => 'УЧЕНИК';

  @override
  String get userNotFound => 'Пользователь не найден';

  @override
  String get studentEmail => 'Email ученика';

  @override
  String get unknownKey9 => 'Неизвестный';

  @override
  String get add => 'Добавить';

  @override
  String get noWebinars => 'Нет вебинаров';

  @override
  String get lessonRecordingsAndVideosWill => 'Здесь будут отображаться записи уроков и видеоматериалы.';

  @override
  String get deleteWebinar => 'Удалить вебинар?';

  @override
  String get watchVideo => 'Смотреть видео';

  @override
  String get addAWebinar => 'Добавить вебинар';

  @override
  String get forExampleLesson1Basics => 'например: Урок 1. Основы';

  @override
  String get descriptionOptional => 'Описание (необязательно)';

  @override
  String get provideLink => 'Указать ссылку';

  @override
  String get uploadFile => 'Загрузить файл';

  @override
  String get videoLink => 'Ссылка на видео';

  @override
  String get httpsyoutubecomOrLinkToFile => 'https://youtube.com/... или ссылка на файл';

  @override
  String get selectVideoFile => 'Выбрать видеофайл';

  @override
  String get loadingVideo => 'Загрузка видео...';

  @override
  String get pleaseSelectAVideoFile => 'Пожалуйста, выберите видеофайл';

  @override
  String get theBuiltinPlayerIsAvailable => 'Встроенный плеер доступен в веб-версии.';

  @override
  String get parentsPanel => 'Панель родителей';

  @override
  String get monitoringYourChildrensProgress => 'Мониторинг успеваемости ваших детей';

  @override
  String get unknownKey10 => 'А';

  @override
  String get wedPoint => 'Ср. балл';

  @override
  String get attendance => 'Посещаемость';

  @override
  String get quests => 'Задания';

  @override
  String get latestRatings => 'Последние оценки';

  @override
  String get mat => 'Мат';

  @override
  String get rus => 'Рус';

  @override
  String get phys => 'Физ';

  @override
  String get east => 'Ист';

  @override
  String get allRatings => 'Все оценки';

  @override
  String get tieTheBaby => 'Привязать ребенка';

  @override
  String get enterYourChildsEmailTo => 'Введите Email вашего ребенка для привязки профиля.';

  @override
  String get snap => 'Привязать';

  @override
  String get userWithThisEmailWas => 'Пользователь с таким email не найден';

  @override
  String get theChildIsSuccessfullyAttached => 'Ребенок успешно привязан';

  @override
  String get childrenAreNotAttached => 'Дети не привязаны';

  @override
  String get useYourChildsCodeTo => 'Используйте код ребенка, чтобы привязать профиль';

  @override
  String get creatingClasses => 'Создание классов';

  @override
  String get coolFactory => 'Классная фабрика';

  @override
  String get enterTheNamesOfThe => 'Введите названия классов, которые вы хотите создать массово.';

  @override
  String get addMore => 'Добавить еще';

  @override
  String get createAllClasses => 'СОЗДАТЬ ВСЕ КЛАССЫ';

  @override
  String get classSettings => 'Настройки класса';

  @override
  String get generalSettings1 => 'Общие настройки';

  @override
  String get invitationCode => 'Код приглашения';

  @override
  String get unknownKey11 => 'Нет кода';

  @override
  String get studentPermissions => 'Разрешения для учеников';

  @override
  String get allowStudentsToWriteMessages => 'Разрешить ученикам писать сообщения в общий чат';

  @override
  String get publicationsInTheFeed => 'Публикации в ленте';

  @override
  String get allowStudentsToCreateNews => 'Разрешить ученикам создавать посты в ленте новостей';

  @override
  String get moderationOfEntry => 'Модерация вступления';

  @override
  String get requireTeacherApprovalForNew => 'Требовать одобрение учителя для новых участников';

  @override
  String get dangerZone => 'Опасная зона';

  @override
  String get thisActionCannotBeUndone1 => 'Это действие нельзя отменить. Все данные будут удалены.';

  @override
  String get changeName => 'Изменить название';

  @override
  String get deleteAClass => 'Удалить класс?';

  @override
  String get allMessagesAssignmentsAndGrades => 'Все сообщения, задания и оценки будут безвозвратно удалены.';

  @override
  String get theLibraryIsEmpty => 'Библиотека пуста';

  @override
  String get studyMaterialsAndLecturesWill => 'Здесь будут отображаться учебные материалы и лекции.';

  @override
  String get deleteMaterial => 'Удалить материал?';

  @override
  String get addMaterial => 'Добавить материал';

  @override
  String get forExampleLecture1Introduction => 'например: Лекция 1. Введение';

  @override
  String get selectFile => 'Выбрать файл';

  @override
  String get download => 'Загрузить';

  @override
  String get upcomingSchedule => 'ПРЕДСТОЯЩЕЕ РАСПИСАНИЕ';

  @override
  String get upcomingTasks => 'БЛИЖАЙШИЕ ЗАДАНИЯ';

  @override
  String get successInTheClass => 'УСПЕХИ В КЛАССЕ';

  @override
  String get adminMode => 'РЕЖИМ АДМИНА';

  @override
  String get logOut => 'Выйти';

  @override
  String get upcomingClasses => 'ПРЕДСТОЯЩИЕ ЗАНЯТИЯ';

  @override
  String get noClasses => 'Нет классов';

  @override
  String get tasksForTesting => 'ЗАДАНИЯ НА ПРОВЕРКУ';

  @override
  String get unknownKey12 => 'Без предмета';

  @override
  String get allTasksHaveBeenChecked => 'Все задания проверены ✨';

  @override
  String get newJob => 'Новая работа';

  @override
  String get studentPortal => 'Портал ученика';

  @override
  String get noClass => 'Без класса';

  @override
  String get n9bClass => '9Б класс';

  @override
  String get toChangeYourEmailContact => 'Для смены email обратитесь к учителю';

  @override
  String get useInvitationCode => 'Использовать код приглашения';

  @override
  String get teacherAccess => 'Доступ учителя';

  @override
  String get requestSent => 'Запрос отправлен';

  @override
  String get requestTeacherPermissions => 'Запросить права учителя';

  @override
  String get onlyFromTeachers => 'Только от учителей';

  @override
  String get submitARequestForA => 'Отправить запрос на получение прав учителя? Администратор должен будет одобрить его.';

  @override
  String get studyHomework => 'Учёба · Домашние задания';

  @override
  String get myTasks => 'Мои задания';

  @override
  String get searchForTasks => 'Поиск заданий...';

  @override
  String get focusMode => 'РЕЖИМ ФОКУСА';

  @override
  String get all => 'Все';

  @override
  String get waiting => 'Ожидают';

  @override
  String get delivered => 'Сдано';

  @override
  String get rated => 'Оценено';

  @override
  String get unknownKey13 => 'Задание';

  @override
  String get urgently => 'СРОЧНО';

  @override
  String get noDeadline => 'Без срока';

  @override
  String get startNow => 'Начать сейчас';

  @override
  String get expired => 'ПРОСРОЧЕНО';

  @override
  String get subjectGeneral => 'Предмет: общий';

  @override
  String get everythingIsDone => 'Всё выполнено!';

  @override
  String get thereAreNoTasksYet => 'Заданий пока нет.';

  @override
  String get tomorrow => 'Завтра';

  @override
  String get editTask => 'Редактировать задание';

  @override
  String get description => 'Описание';

  @override
  String get selectDueDate => 'Выберите дату сдачи';

  @override
  String get deleteTask => 'Удалить задание?';

  @override
  String get allSubmittedWorkForThis => 'Все сданные работы этого задания также будут удалены.';

  @override
  String get completedWorks => 'СДАННЫЕ РАБОТЫ';

  @override
  String get filter => 'Фильтр';

  @override
  String get createATask => 'Создать задание';

  @override
  String get jobFiles => 'Файлы задания:';

  @override
  String get noAttachments => 'Нет прикрепленных файлов';

  @override
  String get attachFiles => 'Прикрепить файлы';

  @override
  String get pleaseEnterATitleAnd => 'Пожалуйста, введите заголовок и выберите дату';

  @override
  String get active1 => 'Активные';

  @override
  String get actively1 => 'АКТИВНО';

  @override
  String get exportWillBeAvailableSoon => 'Экспорт скоро будет доступен';

  @override
  String get edit => 'Редактировать';

  @override
  String get deleteTask1 => 'Удалить задание';

  @override
  String get published => 'Опубликовано: —';

  @override
  String get term => 'Срок';

  @override
  String get points => 'Баллы';

  @override
  String get max => 'макс.';

  @override
  String get status => 'Статус';

  @override
  String get verified1 => 'проверено';

  @override
  String get noWorkYet => 'Работ пока нет';

  @override
  String get rated1 => 'ОЦЕНЕНО';

  @override
  String get underCheck => 'НА ПРОВЕРКЕ';

  @override
  String get noTasks => 'Нет заданий';

  @override
  String get createYourFirstAssignmentFor => 'Создайте свое первое задание для этого класса.';

  @override
  String get justNow1 => 'только что';

  @override
  String get bookmarksWillAppearInThe => 'Закладки появятся в следующем обновлении';

  @override
  String get comments => 'Комментарии';

  @override
  String get noCommentsYet => 'Комментариев пока нет.';

  @override
  String get user => 'Пользователь';

  @override
  String get addAComment => 'Добавить комментарий...';

  @override
  String get ribbon => 'Лента';

  @override
  String get announcementsFromYourTeachers => 'Объявления от ваших учителей';

  @override
  String get searchByAdvertisements => 'Поиск по объявлениям...';

  @override
  String get thereAreNoAnnouncementsYet => 'Объявлений пока нет.';

  @override
  String get declarationsForYourClasses => 'Объявления для ваших классов';

  @override
  String get newPost => 'Новый пост';

  @override
  String get postAnAnnouncementForClasses => 'Опубликуйте объявление для классов…';

  @override
  String get attachAnImage => 'Прикрепить изображение';

  @override
  String get pinThisAd => 'Закрепить объявление';

  @override
  String get publish => 'Опубликовать';

  @override
  String get mySchedule => 'Моё расписание';

  @override
  String get unknownKey14 => 'Классы';

  @override
  String get dayOfTheWeek => 'День недели';

  @override
  String get selectDate => 'Выберите дату';

  @override
  String get start => 'Начало';

  @override
  String get end => 'Конец';

  @override
  String get officenote => 'Кабинет / заметка';

  @override
  String get firstSelectAClass => 'Сначала выберите класс';

  @override
  String get theEndMustBeLater => 'Конец должен быть позже начала';

  @override
  String get selectDayOfWeek => 'Выберите день недели';

  @override
  String get violet => 'Фиолетовый';

  @override
  String get emerald => 'Изумрудный';

  @override
  String get amber => 'Янтарный';

  @override
  String get scarlet => 'Алый';

  @override
  String get darkTheme => 'Тёмная тема';

  @override
  String get aboutTheApplication => 'О приложении';

  @override
  String get version => 'Версия';

  @override
  String get youWillBeRedirectedTo => 'Вы будете перенаправлены на экран входа';

  @override
  String get notLoggedIn => 'Не вошли в систему';

  @override
  String get areYouATeacher => 'Вы учитель? ';

  @override
  String get loginAsTeacher => 'Войти как учитель';

  @override
  String get enterInvitationCode => 'Ввести код приглашения';

  @override
  String get codeNotFoundCheckAnd => 'Код не найден. Проверьте и попробуйте снова.';

  @override
  String get pleaseLoginFirst => 'Пожалуйста, сначала войдите.';

  @override
  String get schedule => 'Расписание';

  @override
  String get inviteToClass => 'Пригласить в класс';

  @override
  String get showThisQrCodeTo => 'Покажите этот QR-код ученикам или отправьте им прямую ссылку.';

  @override
  String get linkCopied => 'Ссылка скопирована!';

  @override
  String get copyLink => 'Копировать ссылку';

  @override
  String get chatHistoryCleared => 'История чата очищена';

  @override
  String get removingAClass => 'Удаление класса...';

  @override
  String get classDeletedSuccessfully => 'Класс успешно удален';

  @override
  String get createAClassToOpen => 'Создайте класс, чтобы открыть этот раздел.';

  @override
  String get youDontHaveAnyClasses => 'У вас пока нет классов';

  @override
  String get addStudentsAndGetStarted => 'Добавьте учеников и начинайте работу.';

  @override
  String get waitToBeAddedTo => 'Ожидайте, пока вас добавят в класс.';

  @override
  String get createAClass => 'Создать класс';

  @override
  String get empty => 'Пусто';

  @override
  String get newTask => 'Новое задание';

  @override
  String get jan => 'янв';

  @override
  String get feb => 'фев';

  @override
  String get mar => 'мар';

  @override
  String get apr => 'апр';

  @override
  String get may1 => 'мая';

  @override
  String get jun => 'июн';

  @override
  String get jul => 'июл';

  @override
  String get aug => 'авг';

  @override
  String get sep => 'сен';

  @override
  String get oct => 'окт';

  @override
  String get nov => 'ноя';

  @override
  String get dec => 'дек';

  @override
  String get setADeadline => 'Установить срок';

  @override
  String get yourWork => 'Ваша работа';

  @override
  String get notesForWork => 'Заметки к работе';

  @override
  String get addFiles => 'Добавить файлы';

  @override
  String get pleaseEnterYourEmailAnd => 'Пожалуйста, введите email и пароль';

  @override
  String get pleaseFillInAllFields => 'Пожалуйста, заполните все поля';

  @override
  String get enterYourEmailToReset => 'Введите email для сброса пароля';

  @override
  String get passwordResetError => 'Ошибка сброса пароля';

  @override
  String get invalidEmailOrPassword => 'Неверный email или пароль';

  @override
  String get thisEmailIsAlreadyRegistered => 'Этот email уже зарегистрирован';

  @override
  String get passwordIsTooWeakMinimum => 'Пароль слишком слабый (минимум 6 символов)';

  @override
  String get unknownKey15 => 'Нет подключения к сети';

  @override
  String get somethingWentWrongTryAgain => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get singleClassForChatnfeedAnd => 'Единый класс для чата,\\nленты и домашних заданий.';

  @override
  String get realtimeClassChat => 'Чат класса в реальном времени';

  @override
  String get adsAndFeed => 'Объявления и лента';

  @override
  String get assignmentsAndAssessments => 'Задания и оценки';

  @override
  String get createAnAccount => 'Создать аккаунт';

  @override
  String get welcomeBack => 'С возвращением 👋';

  @override
  String get fullName => 'Полное имя';

  @override
  String get emailMail => 'Эл. почта';

  @override
  String get forgotYourPassword => 'Забыли пароль?';

  @override
  String get alreadyHaveAnAccount => 'Уже есть аккаунт? ';

  @override
  String get dontHaveAnAccount => 'Нет аккаунта? ';

  @override
  String get login => 'Войти';

  @override
  String get register => 'Зарегистрироваться';

  @override
  String get joinTheClassToAccess => 'Вступите в класс, чтобы открыть этот раздел.';

  @override
  String get enterTheTeacherInvitationCode => 'Введите код приглашения от учителя, чтобы открыть чат, ленту и задания.';

  @override
  String get joinTheClass => 'Вступить в класс';

  @override
  String get or => '— ИЛИ —';

  @override
  String get theCameraWillBeAvailable => 'Камера будет доступна в следующем обновлении';

  @override
  String get scanQrCode => 'Сканировать QR-код';

  @override
  String get enterCode => 'Введите код';

  @override
  String get invalidCode => 'Неверный код';

  @override
  String get previewNotAvailableOnThis => 'Предпросмотр недоступен на этой платформе';

  @override
  String get teacher1 => 'УЧИТЕЛЬ';

  @override
  String get classText => 'Класс';

  @override
  String get cloudStorageManagement => 'Управление облачным хранилищем';

  @override
  String get loadingCloudStorageStats => 'Загрузка статистики облачного хранилища...';

  @override
  String get googleDriveSubtitle => 'Хранение ресурсов библиотеки и крупных уроков';

  @override
  String get cloudinarySubtitle => 'Хранение изображений, коротких видео и постов ленты';

  @override
  String get firebaseStorageSubtitle => 'Хранение вспомогательных файлов, аватаров и конфигурационных изображений';

  @override
  String get cleaningUpStorage => 'Очистка хранилища...';

  @override
  String get cleanUpRedundantData => 'Очистить избыточные данные в системе';

  @override
  String get confirmCleanup => 'Подтверждение очистки';

  @override
  String get confirmCleanupDesc => 'Система просканирует и удалит потерянные файлы (мусорные файлы), которые были удалены в приложении, но все еще существуют в облачных сервисах (Google Drive, Cloudinary, Firebase). Этот процесс может занять 1–2 минуты.';

  @override
  String get startCleanup => 'Начать очистку';

  @override
  String cleanupSuccess(String count, String size) {
    return 'Очистка выполнена успешно! Удалено $count избыточных файлов, освобождено $size.';
  }

  @override
  String cleanupFailed(String error) {
    return 'Ошибка очистки: $error';
  }

  @override
  String get searchTasks => 'Поиск задач';

  @override
  String get personalizationAndAccountManagement => 'Персонализация и управление аккаунтом';

  @override
  String cabinetWithNumber(String number) {
    return 'Кабинет $number';
  }
}
