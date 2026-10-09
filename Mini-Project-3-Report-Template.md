# MINI-PROJECT SHORT TECHNICAL REPORT
**Course:** Cross-Platform Mobile App Development (VKU)  
**Mini-Project Title:** Mini-Project 3: Smart Receipt Scanner & Expense Manager  
**Student Name:** Trần Văn Pháp  
**Student ID:** 23IT.B161  
**Submission Date:** 09/10/2026  

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS
* **Team Members:**
  1. **Trần Văn Pháp** — Student ID: **23IT.B161** — Role: Full-Stack Mobile Architecture, ML Kit OCR Engine, UI/UX & State Management — Contribution: **100%**
* **🔗 Live Demo URL:** [https://github.com/phap321/miniproject3](https://github.com/phap321/miniproject3) *(Hỗ trợ chạy trên Android APK, Web Preview & Windows Desktop)*
* **💻 GitHub Repository:** [https://github.com/phap321/miniproject3](https://github.com/phap321/miniproject3)
* **🎥 Video Demo (Optional):** [https://youtu.be/xxx] *(Đính kèm file demo hoặc link video nếu có)*

---

## 2. FEATURE IMPLEMENTATION CHECKLIST
| # | Required Feature | Status | Implementation Details & Acceptance Level |
|:---:|---|:---:|---|
| 1 | **AI/OCR Receipt Scanning & Heuristic Engine** | ✅ Complete | Tích hợp Camera trực tiếp với khung căn chỉnh hóa đơn (`CropOverlayPainter`) và chọn ảnh từ thư viện (`image_picker`). Sử dụng `google_mlkit_text_recognition` kết hợp bộ bóc tách thông minh `OCRHeuristicEngine` tự động trích xuất: Tên cửa hàng/thương hiệu, Ngày giao dịch, Tổng tiền chính xác (lọc số điện thoại & tiền thối), và phân loại danh mục tự động. |
| 2 | **Local Offline Persistence & CRUD Management** | ✅ Complete | Lưu trữ dữ liệu cục bộ an toàn, hoạt động hoàn toàn offline thông qua SQLite (`sqflite` + `database_helper.dart`). Hỗ trợ đầy đủ thêm, sửa, xóa, xem chi tiết và lọc hóa đơn theo danh mục/thời gian. |
| 3 | **Interactive Analytics & Data Visualization** | ✅ Complete | Biểu đồ cột chi tiêu 7 ngày trong tuần (`WeeklyBarChart`) với hiệu ứng tương tác chạm; Biểu đồ Donut tỷ trọng chi tiêu (`CategoryDonutChart`) tùy biến vẽ bằng Canvas `CustomPainter`. Theo dõi tiến độ hạn mức ngân sách tháng với thanh cảnh báo trực quan. |
| 4 | **Responsive UI & Modern UX Design** | ✅ Complete | Giao diện hiện đại chuẩn Material 3, bảng màu tươi sáng (`Emerald Green / Indigo / Amber`), hiệu ứng bo tròn thẻ Card cao cấp, hỗ trợ phản hồi haptic & thông báo trạng thái tức thì. |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE

### 3.1 Cấu trúc thư mục dự án (`lib/`)
```text
lib/
├── main.dart                          # Điểm khởi chạy ứng dụng (Entry Point & Theme configuration)
├── models/
│   └── transaction_model.dart         # Data Model cho hóa đơn & Enum ReceiptCategory
├── services/
│   ├── database_helper.dart           # Lớp quản lý SQLite database (CRUD operations, fallback memory)
│   ├── ocr_heuristic_engine.dart      # Bộ lọc Heuristic Regex tách tên quán, số tiền, ngày & danh mục
│   └── storage_service.dart          # Service quản lý lưu trữ & cấu hình người dùng
├── screens/
│   ├── home_screen.dart               # Màn hình chính: Tổng quan số dư, biểu đồ tuần, danh sách hóa đơn
│   ├── camera_scanner_screen.dart     # Giao diện camera quét hóa đơn thời gian thực & chọn ảnh gallery
│   ├── review_receipt_screen.dart     # Màn hình kiểm tra & chỉnh sửa thông tin trích xuất trước khi lưu
│   ├── transaction_detail_screen.dart # Xem chi tiết biên lai và các mặt hàng
│   └── analytics_screen.dart          # Phân tích chi tiêu chi tiết theo tuần, tháng và danh mục
├── widgets/
│   ├── crop_overlay_painter.dart      # CustomPainter vẽ khung ngắm chữ nhật bo góc với góc quét sáng
│   ├── weekly_bar_chart.dart          # CustomPainter vẽ biểu đồ cột 7 ngày chi tiêu có tooltip
│   ├── category_donut_chart.dart      # CustomPainter biểu đồ tròn Donut phân bổ danh mục chi tiêu
│   ├── category_chip.dart             # Chip danh mục bộ lọc nhanh
│   └── transaction_card.dart          # Thẻ hiển thị giao dịch trực quan với icon và màu phân loại
└── utils/
    ├── app_theme.dart                 # Hệ thống theme màu (Primary Green, Surface, Card shadows)
    └── currency_formatter.dart        # Định dạng tiền tệ chuẩn VNĐ (vd: 95.000 đ)
```

### 3.2 Luồng dữ liệu & Quản lý trạng thái (State Flow)
1. **Camera/Input:** Người dùng chụp ảnh hóa đơn hoặc tải ảnh lên.
2. **OCR Recognition:** Ảnh được chuyển qua `google_mlkit_text_recognition` để lấy các khối văn bản thô (`RecognizedText`).
3. **Heuristic Parsing:** `OCRHeuristicEngine` áp dụng các thuật toán:
   - **Tên cửa hàng:** Đối soát kho từ điển các chuỗi siêu thị/tiện lợi (WinMart, Co.opmart, Highlands, Bách Hóa Xanh...) hoặc lấy tiêu đề hóa đơn loại trừ các dòng thông tin hành chính.
   - **Số tiền:** Quét theo từ khóa tổng tiền (`Tổng cộng`, `Thành tiền`, `T.Tiền`), tự động bỏ qua dòng `Khách trả` và `Tiền thừa`; phương án dự phòng tính tổng cột thành tiền các món hàng.
   - **Danh mục:** Phân tích ngữ cảnh từ khóa trong biên lai để gắn tag (`Ăn uống`, `Học tập`, `Di chuyển`, `Thiết bị`, `Giải trí`).
4. **User Verification:** Màn hình `ReviewReceiptScreen` cho phép kiểm tra lại và chỉnh sửa số liệu trước khi lưu.
5. **Persistence & UI Update:** Bản ghi được lưu vào SQLite và tự động cập nhật lại Dashboard cùng biểu đồ thống kê.

---

## 4. EMPIRICAL EVIDENCE & SCREENSHOTS
* *Các màn hình tiêu biểu của ứng dụng chạy trên thiết bị Android (Samsung Galaxy / Emulator) hoặc Web Preview:*
1. **Màn hình Tổng quan Dashboard (`home_screen.dart`):** Hiển thị tổng chi tiêu tháng, thanh tiến độ hạn mức ngân sách, biểu đồ cột tương tác 7 ngày và danh sách các hóa đơn gần nhất với phân loại màu sắc rõ ràng.
2. **Màn hình Camera quét hóa đơn (`camera_scanner_screen.dart`):** Giao diện máy ảnh toàn màn hình với khung viền quét neon xanh lá (`CropOverlayPainter`), nút chụp hóa đơn và nút nhập ảnh từ thư viện Gallery.
3. **Màn hình Duyệt & Xác nhận biên lai (`review_receipt_screen.dart`):** Hiển thị kết quả bóc tách tự động (Tên quán, Số tiền VNĐ, Ngày thanh toán, Danh mục, Ghi chú chi tiết) cùng tính năng xem lại ảnh gốc.
4. **Màn hình Thống kê Phân tích (`analytics_screen.dart`):** Biểu đồ tròn Donut trực quan phân bổ % chi tiêu theo từng nhóm danh mục sinh viên và danh sách chi tiết từng khoản.

---

## 5. TECHNICAL CHALLENGES & RESOLUTIONS

### Thách thức 1: Xử lý nhiễu văn bản OCR và nhầm lẫn giữa Số tiền tổng và Tiền khách trả/Số điện thoại
* **Vấn đề:** Các hóa đơn bán lẻ tại Việt Nam thường chứa số điện thoại cửa hàng, mã số thuế và mục `Tiền khách đưa: 500.000 đ` kèm `Tiền thừa: 350.000 đ`. Nếu chỉ tìm số lớn nhất, ứng dụng sẽ lấy nhầm tiền khách đưa thay vì số tiền thực tế của hóa đơn (150.000 đ).
* **Giải pháp:** Xây dựng quy trình bóc tách 3 tầng ưu tiên trong `OCRHeuristicEngine`:
  1. *Tầng 1 (Keyword Total Anchors):* Ưu tiên các dòng chứa từ khóa chốt hóa đơn (`Tổng cộng`, `Tổng tiền`, `Thành tiền`) và loại trừ dòng có chứa `khách trả`, `tiền thối`, `tiền thừa`.
  2. *Tầng 2 (Column Subtotal Sum):* Nếu không có từ khóa tổng, tính tổng các giá trị nằm bên phải cột thành tiền của từng món hàng.
  3. *Tầng 3 (Regex Candidate Filter):* Loại bỏ hoàn toàn số có độ dài dạng số điện thoại (10 số, bắt đầu bằng 0) hoặc mã số thuế trước khi tính giá trị cực đại.

### Thách thức 2: Khắc phục xung đột môi trường Build Gradle & Java SDK trên hệ điều hành Windows
* **Vấn đề:** Khi biên dịch Android trên Windows với Android SDK 35 và plugin Camera/ML Kit, xuất hiện lỗi xung đột phiên bản Gradle cũ với JDK 21, cũng như hiện tượng khóa file tài nguyên (`The process cannot access the file because it is being used by another process`).
* **Giải pháp:** 
  - Nâng cấp Gradle Wrapper lên bản **8.7** và Android Gradle Plugin (AGP) lên **8.5.2** tương thích hoàn toàn với JDK 21.
  - Tinh chỉnh `gradle.properties` vô hiệu hóa AAPT2 daemon đa luồng (`android.enableAapt2Daemon=false`, `org.gradle.parallel=false`) để ngăn chặn việc tranh chấp khóa file trên hệ thống tập tin NTFS của Windows.
