-- OPTIONAL: illustrative products for a local demo, not real offers or market prices.
-- Run UpgradeCommerce.sql first. Do not run this script on a real store.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM dbo.Products WHERE Name=N'[MẪU] Bàn phím cơ')
 INSERT dbo.Products(Name,Category,Description,Price,Stock,IsActive) VALUES
 (N'[MẪU] Bàn phím cơ',N'Phụ kiện',N'Sản phẩm minh họa. Giá dùng để thử giao diện, không phải giá bán thực tế.',790000,10,1),
 (N'[MẪU] Chuột không dây',N'Phụ kiện',N'Sản phẩm minh họa. Giá dùng để thử giao diện, không phải giá bán thực tế.',290000,20,1),
 (N'[MẪU] Tai nghe Bluetooth',N'Âm thanh',N'Sản phẩm minh họa. Giá dùng để thử giao diện, không phải giá bán thực tế.',590000,15,1);
COMMIT;
