# Talentum — Connected Learning Management System (LMS)

Talentum (formerly *School World*) is a cross-platform educational ecosystem designed to seamlessly bridge the gap between **Teachers**, **Students**, and **Parents**. It integrates real-time communication, assignment management, grade books, and statistics into a high-performance, responsive, and visually stunning modern interface.

### 🌐 Live Demo: **[talentum.web.app](https://talentum.web.app)**

---

## 📸 Screenshots / Галерея / Giao Diện Ứng Dụng

<p align="center">
  <img src="./screenshots/Screenshot%202026-05-29%20at%2001.27.48.png" width="32%" alt="Screen 1" />
  <img src="./screenshots/Screenshot%202026-05-29%20at%2001.28.31.png" width="32%" alt="Screen 2" />
  <img src="./screenshots/Screenshot%202026-05-29%20at%2001.29.23.png" width="32%" alt="Screen 3" />
</p>


---

## 🌐 Language Selector / Выберите язык / Chọn ngôn ngữ
* [🇷🇺 Русский (Russian)](#-русский)
* [🇺🇸 English](#-english)
* [🇻🇳 Tiếng Việt (Vietnamese)](#-tiếng-việt)

---

## 🇷🇺 Русский

### 🚀 Ключевые возможности

#### 👨‍🏫 Для учителей
*   **Панель управления (Teacher Today):** Интуитивный дашборд с расписанием уроков на сегодня, быстрыми действиями и персональной статистикой.
*   **Управление классами:** Создание учебных групп с уникальными кодами для быстрого входа учеников и родителей.
*   **Электронный журнал (Журнал):** Заполнение тем уроков, выставление оценок по предметам (Предметы) и удобная навигация по списку класса.
*   **Домашние задания:** Публикация заданий с дедлайнами, вложениями, проверка и выставление обратной связи.

#### 🎓 Для учеников
*   **Интерактивный чат класса:** Чат в современном стиле *Glassmorphism*. Поддержка голосовых сообщений, вложений изображений и файлов, реакций эмодзи и быстрого поиска сообщений без перекрытия экрана.
*   **Портал домашних заданий:** Просмотр активных заданий, инструкций и отправка решений прямо со смартфона.
*   **Мониторинг успеваемости:** Мгновенный доступ к оценкам и подробным комментариям учителя.

#### 👪 Для родителей
*   **Родительский контроль:** Отслеживание статуса домашних заданий и оценок всех детей в разных классах.
*   **Информированность:** Лента школьных объявлений и прямой доступ к сообщениям от учителей.

---

### 🛠 Стек технологий
*   **Фронтенд:** **Flutter (Dart 3+)** — Кроссплатформенный интерфейс с поддержкой Web, Android, iOS, macOS.
*   **Дизайн:** Ультрасовременный стиль **Glassmorphism**, отзывчивые сетки (Responsive Grid) для идеального отображения на любых размерах экранов, плавная микроанимация.
*   **Бэкенд:** **Firebase**
    *   **Firebase Authentication:** Авторизация по номеру телефона и Email.
    *   **Cloud Firestore:** База данных реального времени NoSQL для чатов, оценок и контента.
    *   **Firebase Hosting:** Быстрый хостинг с настроенными правилами кэширования заголовков.
    *   **Firebase Storage / Teldrive:** Облачное хранилище учебных материалов и интеграция с безлимитным Telegram Cloud Storage (Teldrive) для больших файлов.

---

### 🚦 Запуск проекта

1. Перейдите в папку проекта:
   ```bash
   cd school_world
   ```
2. Установите зависимости:
   ```bash
   flutter pub get
   ```
3. Сгенерируйте локализацию:
   ```bash
   flutter gen-l10n
   ```
4. Запустите приложение:
   ```bash
   flutter run -d chrome  # Для Web
   # или
   flutter run            # Для мобильного/эмулятора
   ```

---

## 🇺🇸 English

### 🚀 Key Features

#### 👨‍🏫 For Teachers
*   **Teacher Workspace (Teacher Today):** View today's teaching schedule, access quick actions, and track overall class progress from a responsive dashboard.
*   **Classroom Roster:** Easily manage classrooms, generate invite codes, and add students/parents.
*   **Digital Grade Book (Journal):** Streamlined entry for subject lessons (Предметы), grading grids, and interactive student lists.
*   **Assignment Workflow:** Distribute homework with deadlines, attach files, review submissions, and provide structured feedback.

#### 🎓 For Students
*   **Interactive Class Chat:** Glassmorphism-style chat UI. Supports voice notes, file/image uploads, interactive emoji reactions, and non-blocking inline search.
*   **Homework Portal:** Keep track of upcoming due dates, view teacher instructions, and submit work directly from a mobile device.
*   **Grade Book:** Stay updated with real-time academic progress and personal feedback.

#### 👪 For Parents
*   **Parent Dashboard:** Monitor multiple children across different classes in a consolidated view.
*   **Academic Progress:** Real-time visibility into assignment statuses, marks, and announcements.

---

### 🛠 Tech Stack
*   **Frontend:** **Flutter (Dart 3+)** — High-performance cross-platform application for Web, iOS, Android, and macOS.
*   **UI/UX:** Premium Glassmorphism visual styles, fluid layouts that adapt down to small mobile viewports, and custom widgets.
*   **Backend & Cloud Services:** **Firebase**
    *   **Firebase Authentication:** Phone & Email-based secure logins.
    *   **Cloud Firestore:** Real-time NoSQL database for messages, homework, and grade sheets.
    *   **Firebase Hosting:** Production-ready web distribution with custom headers for security and speed.
    *   **Firebase Storage:** Secure media and file uploads.
*   **Telegram Cloud Storage (Teldrive):** High-capacity external file server optimized for large classroom materials.

---

### 🚦 Getting Started

1. Navigate to the project directory:
   ```bash
   cd school_world
   ```
2. Install external pub dependencies:
   ```bash
   flutter pub get
   ```
3. Generate localized assets:
   ```bash
   flutter gen-l10n
   ```
4. Run the debug build:
   ```bash
   flutter run -d chrome  # For Web browsers
   # OR
   flutter run            # For mobile/desktop native devices
   ```

---

## 🇻🇳 Tiếng Việt

### 🚀 Tính Năng Nổi Bật

#### 👨‍🏫 Dành Cho Giáo Viên
*   **Bảng điều khiển (Teacher Today):** Tổng hợp lịch dạy học trong ngày, phím tắt thao tác nhanh, số liệu thống kê sinh động.
*   **Quản lý Lớp Học:** Tạo lớp, cấp mã tham gia và quản lý học sinh & phụ huynh trực quan.
*   **Sổ Điểm & Chủ Đề (Журнал):** Quản lý tiến độ bài dạy theo Môn học (Предметы), bảng nhập điểm tiện lợi và danh sách lớp học thông minh.
*   **Giao Bài Tập:** Soạn bài tập đính kèm tệp tin đa phương tiện, theo dõi tiến độ nộp bài và nhận xét điểm số trực tiếp.

#### 🎓 Dành Cho Học Sinh
*   **Trò Chuyện Lớp Học:** Kênh chat nhóm phong cách *Glassmorphism* sang trọng. Hỗ trợ tin nhắn thoại, đính kèm tệp, thả cảm xúc tương tác và tìm kiếm tin nhắn tích hợp sẵn trên Header không gây che khuất màn hình.
*   **Cổng Nộp Bài:** Theo dõi thời hạn bài tập về nhà, xem hướng dẫn chi tiết và gửi bài làm chỉ với vài lượt chạm.
*   **Theo Dõi Kết Quả:** Cập nhật điểm số nhanh chóng cùng nhận xét từ giáo viên ngay khi có kết quả.

#### 👪 Dành Cho Phụ Huynh
*   **Bảng Điều Khiển Tổng Hợp:** Theo dõi sát sao việc học tập, lịch nộp bài và điểm số của tất cả các con trên một giao diện thống nhất.
*   **Kênh Thông Tin:** Nhận thông báo mới nhất từ giáo viên chủ nhiệm và nhà trường.

---

### 🛠 Công Nghệ Sử Dụng
*   **Frontend:** **Flutter (Dart 3+)** — Chạy mượt mà, đồng bộ trên Web, iOS, Android và macOS.
*   **Giao Diện UI/UX:** Phong cách thiết kế **Glassmorphism** cao cấp, các thành phần UI (Stats, Action Tiles) co giãn linh hoạt trên mọi kích thước màn hình responsive.
*   **Hạ Tầng Backend:** **Firebase**
    *   **Firebase Auth:** Xác thực qua Số điện thoại hoặc Email bảo mật.
    *   **Cloud Firestore:** Đồng bộ tin nhắn thời gian thực và dữ liệu bảng điểm.
    *   **Firebase Hosting:** Triển khai Web hiệu năng cao, tối ưu hóa các quy tắc Cache.
    *   **Firebase Storage:** Quản lý tài liệu và bài làm trực tiếp.
*   **Telegram Cloud Storage (Teldrive):** Lưu trữ không giới hạn tài liệu học tập dung lượng nặng tối ưu băng thông.

---

### 🚦 Hướng Dẫn Cài Đặt

1. Di chuyển vào thư mục:
   ```bash
   cd school_world
   ```
2. Cài đặt thư viện:
   ```bash
   flutter pub get
   ```
3. Biên dịch đa ngôn ngữ:
   ```bash
   flutter gen-l10n
   ```
4. Khởi chạy dự án:
   ```bash
   flutter run -d chrome  # Chạy trên trình duyệt Web
   # HOẶC
   flutter run            # Chạy trên thiết bị di động / giả lập
   ```

---
Developed with ❤️ by **Do Quoc Chi** (@gookjiii) and the Talentum Team.
