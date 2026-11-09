-- Local demo catalogue: illustrative prices, not market quotations.
-- Only populates an empty catalogue; existing products are never replaced.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM dbo.Products WITH (UPDLOCK,HOLDLOCK))
BEGIN
 INSERT dbo.Products(Name,Category,Description,ImageUrl,Price,Stock,IsActive) VALUES
 (N'[MẪU] Điện thoại 128 GB',N'Điện thoại',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Điện thoại phục vụ học tập và liên lạc; bộ nhớ 128 GB, màn hình 6,5 inch, sạc USB-C.',N'/images/products/phone.svg',7990000,20,1),
 (N'[MẪU] Tai nghe Bluetooth kèm hộp sạc',N'Âm thanh',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Tai nghe không dây kèm hộp sạc, kết nối Bluetooth, có micro cho cuộc gọi.',N'/images/products/earbuds.svg',2490000,25,1),
 (N'[MẪU] Tai nghe chụp tai có micro',N'Âm thanh',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Tai nghe chụp tai có dây 3,5 mm, micro dùng cho học trực tuyến.',N'/images/products/headphones.svg',1290000,18,1),
 (N'[MẪU] Laptop học tập 15 inch',N'Máy tính',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Laptop mô phỏng cho học tập: màn hình 15,6 inch, RAM 8 GB, SSD 256 GB.',N'/images/products/laptop.svg',15990000,12,1),
 (N'[MẪU] Đồng hồ thông minh dây silicon',N'Thiết bị đeo',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Đồng hồ mô phỏng có hiển thị thông báo, đếm bước chân và dây silicon.',N'/images/products/watch.svg',1990000,30,1),
 (N'[MẪU] Máy tính bảng Wi-Fi 64 GB',N'Máy tính bảng',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Máy tính bảng mô phỏng có màn hình 10 inch, bộ nhớ 64 GB và Wi-Fi, phục vụ đọc tài liệu.',N'/images/products/tablet.svg',5990000,15,1);
END;
COMMIT;
