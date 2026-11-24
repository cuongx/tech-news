-- Real product descriptions and manufacturer images for the six storefront samples.
-- Run after SeedStorefrontDemo.sql and UpdateDemoCatalog.sql.
-- Copy TechNews/wwwroot/images/products/official with the application first.
-- Matches the exact sample name and image; preserves edited products, IDs, prices,
-- stock, visibility and order-item snapshots. Safe to run again (zero matches).
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @Catalog TABLE(OldName nvarchar(160),OldImage nvarchar(500),Name nvarchar(160),Category nvarchar(80),Description nvarchar(4000),ImageUrl nvarchar(500));
INSERT @Catalog VALUES
(N'[MẪU] Điện thoại 128 GB',N'/images/products/phone.svg',N'Apple iPhone 16 128 GB',N'Điện thoại',N'iPhone 16 sử dụng chip Apple A18 và bộ nhớ 128 GB, phù hợp cho liên lạc, chụp ảnh và các ứng dụng hằng ngày.
• Màn hình OLED Super Retina XDR 6,1 inch, độ phân giải 2556 × 1179.
• Camera chính Fusion 48 MP và camera góc siêu rộng 12 MP.
• Có Dynamic Island, Face ID và nút Điều Khiển Camera.
• Kết nối USB-C, hỗ trợ Wi-Fi 7 và Bluetooth 5.3.
Ảnh hãng giới thiệu các lựa chọn màu của dòng máy.',N'/images/products/official/apple-iphone-16.png'),
(N'[MẪU] Tai nghe Bluetooth kèm hộp sạc',N'/images/products/earbuds.svg',N'Apple AirPods 4 – hộp sạc USB-C',N'Âm thanh',N'AirPods 4 bản tiêu chuẩn có thiết kế không dây, chip H2 và hộp sạc USB-C. Đây là phiên bản không có chống ồn chủ động (ANC).
• Có tính năng Cách Ly Giọng Nói và Âm Thanh Không Gian cá nhân hóa trên thiết bị tương thích.
• Nghe nhạc tối đa 5 giờ mỗi lần sạc; tổng thời lượng tối đa 30 giờ khi dùng cùng hộp sạc theo điều kiện thử nghiệm của Apple.
• Tai nghe và hộp sạc đạt mức kháng bụi, mồ hôi và nước IP54; không dùng để bơi.
Thời lượng sử dụng thực tế phụ thuộc âm lượng, thiết bị và cách sử dụng.',N'/images/products/official/apple-airpods-4.png'),
(N'[MẪU] Tai nghe chụp tai có micro',N'/images/products/headphones.svg',N'Sony WH-CH520 – tai nghe không dây màu đen',N'Âm thanh',N'Sony WH-CH520 là tai nghe không dây với kiểu đeo trên tai, phù hợp nghe nhạc và đàm thoại.
• Màng loa 30 mm, hỗ trợ xử lý âm thanh DSEE.
• Bluetooth 5.2, hỗ trợ codec SBC và AAC.
• Sạc qua USB-C, thời gian sạc đầy khoảng 3 giờ theo thông số hãng.
• Có điều khiển âm lượng và micro cho cuộc gọi.
• Không có cổng âm thanh đầu vào để nghe bằng dây.
Ảnh sản phẩm là phiên bản màu đen.',N'/images/products/official/sony-wh-ch520-black.jpg'),
(N'[MẪU] Laptop học tập 15 inch',N'/images/products/laptop.svg',N'MacBook Air M2 13,6 inch – 8 GB / 256 GB',N'Máy tính',N'MacBook Air M2 (2022), cấu hình bộ nhớ hợp nhất 8 GB và SSD 256 GB, dành cho học tập và công việc di động.
• Chip Apple M2 với CPU 8 lõi và GPU 8 lõi.
• Màn hình Liquid Retina 13,6 inch, độ phân giải 2560 × 1664, độ sáng 500 nit.
• Sạc MagSafe 3, hai cổng Thunderbolt / USB 4 và giắc tai nghe 3,5 mm.
• Có Touch ID và camera FaceTime HD 1080p.
Ảnh giới thiệu của Apple thể hiện máy màu Midnight.',N'/images/products/official/apple-macbook-air-m2.jpg'),
(N'[MẪU] Đồng hồ thông minh dây silicon',N'/images/products/watch.svg',N'Xiaomi Smart Band 9',N'Thiết bị đeo',N'Xiaomi Smart Band 9 là vòng đeo tay thông minh kết nối với ứng dụng Mi Fitness.
• Màn hình cảm ứng AMOLED 1,62 inch, độ phân giải 192 × 490, độ sáng tối đa 1200 nit.
• Pin 233 mAh, sạc từ tính; thời gian sử dụng thông thường lên đến 21 ngày theo điều kiện thử nghiệm của hãng.
• Có cảm biến nhịp tim quang học, gia tốc, con quay hồi chuyển và ánh sáng xung quanh.
• Kháng nước 5 ATM; hỗ trợ điện thoại Android 8.0 hoặc iOS 12.0 trở lên.
• Dây đeo TPU. Ảnh hãng giới thiệu các lựa chọn màu.
Thiết bị theo dõi vận động và sức khỏe không thay thế thiết bị chẩn đoán y tế.',N'/images/products/official/xiaomi-smart-band-9.png'),
(N'[MẪU] Máy tính bảng Wi-Fi 64 GB',N'/images/products/tablet.svg',N'Apple iPad Gen 10 Wi-Fi 64 GB',N'Máy tính bảng',N'iPad thế hệ thứ 10 (2022), phiên bản Wi-Fi 64 GB, hỗ trợ học tập, đọc tài liệu và giải trí.
• Chip A14 Bionic, CPU 6 lõi và GPU 4 lõi.
• Màn hình Liquid Retina 10,9 inch, độ phân giải 2360 × 1640 và True Tone.
• Camera sau góc rộng 12 MP, camera trước nằm ngang.
• Touch ID tích hợp ở nút nguồn; cổng kết nối USB-C.
• Hỗ trợ Apple Pencil USB-C và Apple Pencil thế hệ 1 với bộ chuyển đổi phù hợp; phụ kiện bán riêng.
Ảnh hãng giới thiệu các lựa chọn màu của dòng iPad này.',N'/images/products/official/apple-ipad-gen-10.png');
UPDATE p SET Name=c.Name, Category=c.Category, Description=c.Description, ImageUrl=c.ImageUrl
OUTPUT INSERTED.Id, INSERTED.Name
FROM dbo.Products p JOIN @Catalog c ON p.Name=c.OldName AND p.ImageUrl=c.OldImage;
COMMIT;
