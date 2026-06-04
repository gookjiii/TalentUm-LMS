# Bản đồ Hành trình Người dùng & Kế hoạch Tối ưu (User Journeys & Optimization Plan)

## 1. Mục tiêu (Goals)
Xây dựng bản đồ hành trình người dùng (User Journey Map) cho 3 nhóm đối tượng chính (Giáo viên, Học sinh, Phụ huynh) và đề xuất các cải tiến UX theo phong cách "Elite Digital Campus" để giảm thiểu ma sát (friction) và tăng cường hiệu quả sử dụng.

---

## 2. Hành trình của Giáo viên (Teacher Journey)
### Luồng hiện tại: Thiết lập lớp học (Class Setup)
1.  Đăng nhập -> Màn hình chính Giáo viên.
2.  Mở Menu/Sidebar -> Chọn "Classes" (Lớp học).
3.  Chọn "Bulk Create" (Tạo hàng loạt).
4.  Nhập danh sách tên lớp vào các ô TextField.
5.  Nhấn "Create All" và đợi thông báo thành công.

### Điểm nghẽn (Friction Points):
- Giao diện nhập liệu đơn điệu, không có hình ảnh minh họa.
- Không biết trước lớp học sẽ trông như thế nào (màu sắc, icon đại diện).
- Phải nhập tay từng lớp, chưa hỗ trợ dán (paste) danh sách lớn.

### Đề xuất Tối ưu (Optimizations):
- **Visual Factory:** Hiển thị preview `ClassBadge` (màu sắc và chữ cái đại diện) ngay lập tức khi giáo viên đang gõ tên lớp.
- **Smart Import:** Thêm tính năng "Paste list" để giáo viên có thể dán danh sách tên lớp từ Excel/Word vào một ô duy nhất, hệ thống tự động tách dòng thành các lớp riêng biệt.
- **Color Overrides:** Cho phép chọn màu đại diện cho lớp ngay trong luồng tạo hàng loạt thay vì phải vào từng lớp để sửa.

---

## 3. Hành trình của Học sinh (Student Journey)
### Luồng hiện tại: Nộp bài tập (Homework Submission)
1.  Đăng nhập -> Tab "Homework" hoặc từ thẻ "Focus Mode" ở trang Today.
2.  Chọn bài tập cụ thể -> Chuyển sang màn hình Chi tiết (Detail Screen).
3.  Đọc hướng dẫn, tải file đính kèm của giáo viên (nếu có).
4.  Nhập nội dung bài làm (text) và chọn file đính kèm từ máy.
5.  Nhấn "Submit" và đợi quá trình upload hoàn tất.

### Điểm nghẽn (Friction Points):
- Luôn phải chuyển màn hình (Navigate) ngay cả với các bài tập đơn giản (chỉ cần nộp 1 câu trả lời ngắn hoặc 1 tấm ảnh).
- Thiếu phản hồi về tiến trình tải lên (upload progress) nếu file nặng, khiến học sinh cảm thấy ứng dụng đang bị "treo".

### Đề xuất Tối ưu (Optimizations):
- **Quick Submit Bottom-Sheet:** Với các bài tập không yêu cầu nhiều file, cho phép mở một Bottom Sheet nộp bài ngay tại màn hình danh sách (không cần chuyển màn hình).
- **Voice Submission:** Tích hợp ghi âm trực tiếp vào form nộp bài (phù hợp với các môn ngoại ngữ hoặc trả bài miệng).
- **Persistent Upload Bar:** Hiển thị thanh tiến trình tải lên nhỏ ở dưới cùng màn hình, cho phép học sinh tiếp tục xem các bài tập khác trong khi bài làm đang được upload.

---

## 4. Hành trình của Phụ huynh (Parent Journey)
### Luồng hiện tại: Theo dõi con (Monitoring Progress)
1.  Đăng nhập (với vai trò Phụ huynh).
2.  Vào phần "Link Child" (Liên kết với con).
3.  Nhập chính xác địa chỉ Email của con.
4.  Nhấn "Snap" để hệ thống tìm kiếm và liên kết.
5.  Xem thẻ Dashboard của con với các chỉ số thống kê.

### Điểm nghẽn (Friction Points):
- Việc nhập Email dễ sai sót, yêu cầu phụ huynh phải nhớ chính xác Email của con đã đăng ký.
- Dữ liệu hiện tại đang là Mock (giả lập) ở nhiều chỉ số quan trọng (Điểm trung bình, Chuyên cần).
- Phải nhấn vào từng con để xem chi tiết, chưa có cái nhìn tổng quan nếu có nhiều con.

### Đề xuất Tối ưu (Optimizations):
- **QR Code Linking:** Sinh mã QR trên hồ sơ của Học sinh. Phụ huynh chỉ cần dùng điện thoại quét mã này để liên kết tức thì (Zero-typing flow).
- **Unified Family Feed:** Thay vì chỉ xem thẻ từng con, xây dựng một "Dòng thời gian gia đình" hiển thị các thông báo mới nhất, bài tập sắp đến hạn và điểm số vừa nhận được của tất cả các con trên cùng một luồng.
- **Live Metrics:** Kết nối Dashboard phụ huynh với các hàm tính toán thật từ Firestore (tính điểm trung bình theo thời gian thực từ sổ điểm).

---

## 5. Kế hoạch Triển khai (Next Steps)
1.  [ ] Cập nhật `BulkClassCreateScreen` với tính năng preview Badge.
2.  [ ] Nâng cấp `StudentHomework` card để hỗ trợ nộp bài nhanh qua Bottom Sheet.
3.  [ ] Triển khai cơ chế quét mã QR để liên kết Phụ huynh - Học sinh.
4.  [ ] Xây dựng Widget `FamilyActivityFeed` cho Dashboard Phụ huynh.
