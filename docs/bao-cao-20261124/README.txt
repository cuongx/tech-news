HỒ SƠ KIỂM CHỨNG TECHNEWS — 24/11/2026

results.json và test-logs/: 9 bộ tích hợp đạt trên database kiểm thử.
images/browser-results.json: luồng mua hàng, 21 tổ hợp trang/kích thước, không lỗi JS trong lần chạy.
images/editor-results.json: xác nhận jQuery/Summernote khởi tạo thành công.
images/*.png: 14 ảnh giao diện và 4 sơ đồ; *.svg là nguồn vector sơ đồ.
schema.txt: metadata các bảng SQL, không phải bản dump dữ liệu nghiệp vụ.
restored-static-files.txt: danh sách file tĩnh thiếu đã khôi phục từ bản Git sạch, không ghi đè file đang có.
Prepare-ReportData.sql: chỉ dùng database TechNews_Verification_*. Thêm bài minh họa và chuyển các bài QA_* về nháp để ảnh báo cáo dễ đọc; không chạy trên BLOGDB.

TẠO LẠI WORD
Tại thư mục này: npm install, sau đó npm run build.
Mặc định ghi vào output/. Có thể đặt TECHNEWS_REPORT_OUTPUT để chọn thư mục khác.
Mở Word, cập nhật toàn bộ trường/mục lục và xuất PDF. Trong phiên hoàn thiện đã dùng Word để cập nhật mục lục, phân trang và xuất PDF.

CHỤP LẠI GIAO DIỆN
Cài npm install trong thư mục này, máy cần Microsoft Edge.
Server phải trỏ tới database QA có tài khoản fixture và các sản phẩm [MẪU].
Đặt TEST_DATABASE và TEST_URL tương ứng server, rồi npm run capture.
Script thực hiện đặt một đơn minh họa, chỉ dùng dữ liệu kiểm thử. Có thể đặt TEST_PASSWORD cho tài khoản QA.

THAM CHIẾU
Bản chính: D:\IT43 - NHOM 7.029\Website\tech-news.
Các Word/PDF bản bàn giao: D:\IT43 - NHOM 7.029\*HoanChinh.*.
Không có thay đổi schema BLOGDB trong đợt hoàn thiện này.
