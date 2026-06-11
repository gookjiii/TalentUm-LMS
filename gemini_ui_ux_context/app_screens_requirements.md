# TalentUm LMS - UI/UX Design Context cho Gemini Canvas

Dưới đây là bản tóm tắt cấu trúc Theme chủ đạo và chi tiết các màn hình (Screens) cùng với những thông tin (Data/UI Elements) cần hiển thị trên mỗi màn hình. Vui lòng sử dụng thông tin này để thiết kế ra các giao diện UI/UX tối ưu và đồng nhất.

## 1. Theme & Design System (Hệ thống Thiết kế Chủ đạo)

*   **Design Style**: **Glassmorphism** (Phong cách Kính mờ) hiện đại, cao cấp. Không thiết kế dạng "phẳng" (flat) truyền thống.
*   **Colors (Màu sắc)**:
    *   **Primary Gradient**: Xanh dương đậm (`#2563EB`) sang Chàm (`#6366F1`).
    *   **Backgrounds**: Không dùng màu trắng tinh/đen tuyền. Sử dụng màu xám rất nhạt (light mode) hoặc xám đen sâu (dark mode).
    *   **Cards (Thẻ nội dung)**: Nền trong suốt một phần (translucent) kết hợp blur (mờ) đằng sau `sigma: 10px` để tạo hiệu ứng kính, viền (border) mỏng nửa trong suốt.
*   **Typography (Font chữ)**:
    *   Chính (Văn bản thông thường, tiêu đề): **Inter**.
    *   Phụ (Số liệu, thời gian, code): **JetBrains Mono**.
*   **Shapes & Spacing**:
    *   Bo góc nhiều (Rounded corners): `12px` cho nút nhỏ, `16px - 24px` cho các Cards lớn và Modal.
    *   Padding: Căn lề rộng rãi, có không gian thở (Whitespace). Các màn hình luôn có lề 2 bên đều nhau (Responsive Padding).

---

## 2. Chi tiết các Màn hình (Screens & Required Info)

### 2.1. Authentication & Onboarding (Đăng nhập & Thiết lập)
*   **Auth Screen**:
    *   Logo ứng dụng (TalentUm).
    *   Form đăng nhập/đăng ký: Email, Password.
    *   Chọn Vai trò (Role Selector): Học sinh (Student), Giáo viên (Teacher), Phụ huynh (Parent).
    *   Nút: "Đăng nhập", "Tham gia bằng Mã lớp (Guest)", "Quên mật khẩu?".
*   **Onboarding Screen**:
    *   Upload/Chọn ảnh đại diện (Profile Picture).
    *   Nhập Họ và Tên (Full Name).
    *   Checkbox xác nhận độ tuổi (dành cho Giáo viên).

### 2.2. Navigation Shells (Khung Điều hướng)
*   **Student Shell** (Học sinh): 
    *   Sidebar (trên PC/Tablet) hoặc Bottom Navigation (trên Mobile).
    *   Các Tab chính: Today (Hôm nay), Feed (Bảng tin), Homework (Bài tập), Library (Thư viện), Webinars.
*   **Teacher Workspace** (Giáo viên):
    *   Các Tab chính: Today (Hôm nay), Schedule (Thời khóa biểu), Classes (Quản lý Lớp), Chat.

### 2.3. Today Screen (Tổng quan Hôm nay)
*   **Lời chào**: "Chào buổi sáng, [Tên]!"
*   **Lịch học sắp tới (Upcoming Classes)**:
    *   Tên môn học/Lớp.
    *   Thời gian (Vd: 08:00 - 09:30).
    *   Phòng học (Room) / Link online.
    *   Nút tham gia (Join).
*   **Công việc cần làm (To-Do / Homework)**:
    *   Danh sách bài tập sắp đến hạn.
    *   Màu sắc cảnh báo (Đỏ cho trễ hạn, Vàng cho sắp đến hạn).

### 2.4. Feed Screen (Bảng tin)
*   **Tạo bài viết mới** (Chỉ Giáo viên mới có nút này ở mức nổi bật).
*   **Post Card (Thẻ bài viết)**:
    *   Avatar và Tên tác giả (Author).
    *   Thời gian đăng (Timestamp).
    *   Tag tên Lớp học (Màu sắc riêng theo từng lớp).
    *   Nội dung văn bản (Text content).
    *   Đính kèm: Hình ảnh, File tài liệu (Hiển thị dạng grid hoặc carousel nếu có nhiều ảnh).
    *   Hành động: Nút Like (số lượng), Nút Bình luận (số lượng).
    *   Trạng thái đặc biệt: Bài viết được ghim (Pinned post - biểu tượng chiếc ghim nổi bật).

### 2.5. Homework / Assignments (Bài tập)
*   **Homework List**:
    *   Icon bài tập.
    *   Tiêu đề bài tập.
    *   Ngày hết hạn (Due date).
    *   Trạng thái (Chưa làm, Đã nộp, Đã chấm điểm).
*   **Homework Detail (Chi tiết bài tập)**:
    *   Đề bài chi tiết / Mô tả.
    *   Các file tài liệu đính kèm từ giáo viên.
    *   Phu vực nộp bài: Upload file đính kèm của học sinh.
    *   Khung điểm số / Phản hồi từ giáo viên (nếu đã chấm).

### 2.6. Teacher Schedule (Thời khóa biểu Giáo viên)
*   **Lịch dạng Lưới (Weekly Grid)**:
    *   Cột thời gian bên trái (08:00 đến 18:00).
    *   Các cột ngày trong tuần (Thứ 2 đến Chủ nhật).
    *   Các ô học (Slots): Hiển thị màu sắc theo môn, Tên Lớp, Giờ bắt đầu/kết thúc, Phòng học.
*   **Bộ lọc (Filters)**: Dropdown chọn xem lịch của 1 lớp cụ thể hoặc tất cả các lớp.

### 2.7. Parent Dashboard (Bảng theo dõi của Phụ huynh)
*   **Tổng quan con cái (Child Overview)**:
    *   Tên, Lớp của con.
    *   Điểm danh (Attendance rate).
    *   Điểm số trung bình (Grades).
*   **Hoạt động gần đây (Activity Feed)**:
    *   Bài tập con vừa nộp.
    *   Điểm số vừa được chấm.
    *   Thông báo từ giáo viên chủ nhiệm.

### 2.8. Profile & Settings (Cá nhân & Cài đặt)
*   **Thẻ Profile**: Avatar, Tên, Email.
*   **Thống kê (Stats Cards)**:
    *   Số lớp đã tham gia.
    *   Số bài tập hoàn thành.
    *   Điểm tích lũy (Karma / Points).
*   **Tùy chọn Cài đặt**:
    *   Đổi Theme (Light/Dark/System).
    *   Đổi Ngôn ngữ (English/Tiếng Việt/etc).
    *   Cài đặt thông báo.
