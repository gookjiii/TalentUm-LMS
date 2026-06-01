# TalentUm — Connected Learning Management System (LMS)

TalentUm (formerly *School World*) is a cross-platform educational ecosystem designed to seamlessly bridge the gap between **Teachers**, **Students**, and **Parents**. It integrates real-time communication, assignment management, grade books, and statistics into a high-performance, responsive, and visually stunning modern interface.

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
*   **Домашние задания и Вебинары:** Публикация заданий с дедлайнами и загрузка видеоуроков прямо в систему (с поддержкой потокового воспроизведения 16:9).

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
*   **Бэкенд и Инфраструктура:** 
    *   **Экосистема Firebase:** Cloud Firestore (БД реального времени), Авторизация (Phone/Email), Хостинг.
    *   **Cloudinary:** Высокоскоростная CDN для медиафайлов в чатах и аватарок.
    *   **Google Drive API и Vercel Proxy:** Надежное бесплатное хранилище для тяжелых файлов (видео, документы, ДЗ). Работает через собственный Node.js прокси на Vercel для безопасной докачки файлов (Resumable Uploads) и обхода CORS без утечки ключей.

---

### 🚦 Запуск проекта и Деплой

Для сборки проекта на Web, убедитесь, что у вас настроены переменные окружения. Вы можете использовать автоматический скрипт:

```bash
CLOUDINARY_CLOUD_NAME="your_name" \
CLOUDINARY_UPLOAD_PRESET="your_preset" \
GOOGLE_DRIVE_PROXY_URL="https://your-backend.vercel.app" \
./deploy_web.sh
```

---

## 🇺🇸 English

### 🚀 Key Features

#### 👨‍🏫 For Teachers
*   **Teacher Workspace (Teacher Today):** View today's teaching schedule, access quick actions, and track overall class progress from a responsive dashboard.
*   **Classroom Roster:** Easily manage classrooms, generate invite codes, and add students/parents.
*   **Digital Grade Book (Journal):** Streamlined entry for subject lessons (Предметы), grading grids, and interactive student lists.
*   **Assignment & Webinar Workflow:** Distribute homework with deadlines, attach files, and natively upload/embed 16:9 video lessons directly within the platform.

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
*   **Backend & Cloud Infrastructure:**
    *   **Firebase Ecosystem:** Cloud Firestore (Real-time NoSQL DB), Authentication, Web Hosting.
    *   **Cloudinary:** High-speed CDN for fast delivery of chat media and profile pictures.
    *   **Google Drive API & Vercel Proxy:** Secure, scalable, free storage for heavy educational materials (videos, documents, homework). Proxied through a custom Node.js Vercel backend to manage resumable uploads and bypass CORS seamlessly without exposing API keys.

---

### 🚦 Getting Started & Deployment

To deploy the Flutter Web frontend, use the provided deployment script with your infrastructure variables:

```bash
CLOUDINARY_CLOUD_NAME="your_name" \
CLOUDINARY_UPLOAD_PRESET="your_preset" \
GOOGLE_DRIVE_PROXY_URL="https://your-backend.vercel.app" \
./deploy_web.sh
```

---

## 🇻🇳 Tiếng Việt

### 🚀 Tính Năng Nổi Bật

#### 👨‍🏫 Dành Cho Giáo Viên
*   **Bảng điều khiển (Teacher Today):** Tổng hợp lịch dạy học trong ngày, phím tắt thao tác nhanh, số liệu thống kê sinh động.
*   **Quản lý Lớp Học:** Tạo lớp, cấp mã tham gia và quản lý học sinh & phụ huynh trực quan.
*   **Sổ Điểm & Chủ Đề (Журнал):** Quản lý tiến độ bài dạy theo Môn học (Предметы), bảng nhập điểm tiện lợi và danh sách lớp học thông minh.
*   **Giao Bài Tập & Bài Giảng Video:** Soạn bài tập đính kèm tệp tin đa phương tiện, theo dõi tiến độ nộp bài và tải trực tiếp Video bài giảng (hỗ trợ trình phát 16:9 tích hợp) lên thư viện lớp học.

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
*   **Giao Diện UI/UX:** Phong cách thiết kế **Glassmorphism** cao cấp, các thành phần UI co giãn linh hoạt trên mọi kích thước màn hình (Responsive Grid).
*   **Hạ Tầng Backend & Đám mây:**
    *   **Hệ sinh thái Firebase:** Cloud Firestore (Real-time DB), Authentication (Phone/Email), Hosting.
    *   **Cloudinary:** CDN tốc độ cao chuyên xử lý ảnh đại diện và tin nhắn đa phương tiện trong Chat.
    *   **Google Drive API & Vercel Proxy:** Trụ cột lưu trữ miễn phí, dung lượng khổng lồ cho tài liệu học tập nặng (Video bài giảng, File PDF bài làm). Kết nối qua máy chủ trung gian Node.js (Vercel Backend) để tự động hóa Tải lên an toàn (Resumable Uploads) và vượt rào cản CORS mà không lo lộ API Key.

---

### 🚦 Hướng Dẫn Cài Đặt & Triển Khai

Để biên dịch và đẩy dự án Web lên Firebase Hosting một cách chính xác nhất, bạn có thể chạy file Script tự động kèm theo cấu hình Backend của bạn:

```bash
CLOUDINARY_CLOUD_NAME="ten_cloudinary_cua_ban" \
CLOUDINARY_UPLOAD_PRESET="preset_cua_ban" \
GOOGLE_DRIVE_PROXY_URL="https://backend-cua-ban.vercel.app" \
./deploy_web.sh
```

---
Developed with ❤️ by **Do Quoc Chi** (@gookjiii) and the TalentUm Team.
