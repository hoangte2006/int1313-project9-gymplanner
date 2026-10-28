# Hướng dẫn Java (1 trang) – thêm màn hình phần của mình

Ứng dụng Java Swing nối thẳng vào CSDL `GymPlanner_dev` trên SQL Server. Phần **Thiết bị** (Te) đã làm sẵn làm mẫu. Quang và Phương làm theo đúng mẫu đó cho phần của mình.

## 1. Chạy thử (2 phút)

1. Chạy `sql/01_create_tables.sql`, `sql/02_triggers.sql`, `sql/03_sample_data.sql` trong SSMS (database `GymPlanner_dev`).
2. Trong `src/main/resources/`, sao chép `db.properties.example` thành `db.properties`, điền tài khoản SQL của bạn. **Không commit file `db.properties`** (đã có trong `.gitignore`).
3. Mở terminal ở thư mục dự án, chạy:
   `mvn -q compile exec:java -Dexec.mainClass=com.gym.App`
4. Cửa sổ chính hiện ra, tab **Equipment** liệt kê 10 thiết bị. Có lọc theo trạng thái và nút Refresh.

## 2. Cấu trúc 4 lớp (mỗi lớp một việc)

| Lớp | Thư mục | Việc của lớp | Mẫu (phần Te) |
|---|---|---|---|
| Giao diện | `ui/` | Chỉ hiển thị, nhận thao tác. Không viết SQL. | `EquipmentPanel` |
| Service | `service/` | Logic nghiệp vụ: lọc, đếm, kiểm tra trước khi ghi. | `EquipmentService` |
| DAO | `dao/` | Chỉ cầu nối SQL: SELECT, INSERT, UPDATE. | `EquipmentDao` |
| Model | `model/` | Một dòng của bảng = một đối tượng. | `Equipment` |

Luồng gọi: `ui` → `service` → `dao` → `db/DbConnection` → SQL Server. Không nhảy cách lớp (ví dụ giao diện gọi thẳng DAO).

## 3. Thêm màn hình của mình (5 bước)

1. **Model:** tạo `model/Member.java` (hoặc `Session`, `ClassRegistration`…) với các cột của bảng.
2. **DAO:** tạo `dao/MemberDao.java`, viết `findAll()` giống `EquipmentDao.findAll()` (dùng `try (Connection c = DbConnection.get())` để tự đóng kết nối).
3. **Service:** tạo `service/MemberService.java`, gọi DAO và thêm logic của bạn.
4. **Giao diện:** tạo `ui/MemberPanel.java`, copy `EquipmentPanel` rồi đổi cột và dữ liệu.
5. **Gắn vào cửa sổ chính:** trong `ui/MainFrame.java`, bỏ dấu `//` ở dòng gợi ý và sửa thành
   `tabs.addTab("Members", new MemberPanel(new MemberService()));`

## 4. Ghi dữ liệu và lỗi do trigger

- Ghi dữ liệu (INSERT, UPDATE) viết trong DAO bằng `PreparedStatement` (dấu `?`), **không nối chuỗi** vào câu SQL.
- Khi một luật bị vi phạm, trigger ném lỗi với mã `BR-...` trong thông báo (ví dụ `BR-FAC-06: this equipment is Broken...`). Java nhận được là `SQLException`; `e.getMessage()` chính là câu đó. Giao diện hiện lên bằng `JOptionPane` (xem `EquipmentPanel.load()`).
- Đọc CSDL chạy trong `SwingWorker` để cửa sổ không bị đứng.

## 5. Quy tắc làm việc nhóm

- Mỗi người chỉ sửa file của phần mình; riêng `MainFrame.java` chỉ thêm đúng **một dòng** `tabs.addTab(...)`.
- Trước khi push: biên dịch được (`mvn -q compile`), chạy được màn hình của mình, và chụp ảnh lưu vào `anh_kiem_chung/`.
- Ghi kết quả vào trang sheet của mình (cột Bằng chứng).
