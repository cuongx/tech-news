-- Chuẩn hóa 6 sản phẩm do SeedStorefrontDemo.sql phiên bản cũ tạo.
-- Chỉ đổi tên và mô tả của dữ liệu mẫu chưa được người dùng biên tập.
-- Không đổi giá, tồn kho, ảnh, ID hoặc tên/giá lưu trong chi tiết đơn hàng cũ.
-- Chạy sau UpgradeCommerce.sql. Chạy lại không cập nhật thêm.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @Samples TABLE (OldName nvarchar(160), NewName nvarchar(160), Description nvarchar(4000));
INSERT @Samples VALUES
 (N'Điện thoại',N'[MẪU] Điện thoại 128 GB',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Điện thoại phục vụ học tập và liên lạc; bộ nhớ 128 GB, màn hình 6,5 inch, sạc USB-C.'),
 (N'Tai nghe AirPods',N'[MẪU] Tai nghe Bluetooth kèm hộp sạc',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Tai nghe không dây kèm hộp sạc, kết nối Bluetooth, có micro cho cuộc gọi.'),
 (N'Tai nghe chụp tai',N'[MẪU] Tai nghe chụp tai có micro',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Tai nghe chụp tai có dây 3,5 mm, micro dùng cho học trực tuyến.'),
 (N'Laptop',N'[MẪU] Laptop học tập 15 inch',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Laptop mô phỏng cho học tập: màn hình 15,6 inch, RAM 8 GB, SSD 256 GB.'),
 (N'Đồng hồ thông minh',N'[MẪU] Đồng hồ thông minh dây silicon',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Đồng hồ mô phỏng có hiển thị thông báo, đếm bước chân và dây silicon.'),
 (N'Máy tính bảng',N'[MẪU] Máy tính bảng Wi-Fi 64 GB',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Máy tính bảng mô phỏng có màn hình 10 inch, bộ nhớ 64 GB và Wi-Fi, phục vụ đọc tài liệu.');
UPDATE p
SET Name=s.NewName, Description=s.Description
OUTPUT INSERTED.Id, INSERTED.Name
FROM dbo.Products p JOIN @Samples s ON p.Name=s.OldName
WHERE p.Description LIKE N'Sản phẩm mẫu. Giá minh họa để trải nghiệm giao diện và luồng đặt hàng, không phải báo giá thương mại.%';
COMMIT;
