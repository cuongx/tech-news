IF DB_NAME() NOT LIKE N'TechNews[_]Verification[_]%' THROW 50000,'Use verification database only',1;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @Fixture TABLE(Id int);
INSERT Products(Name,Category,Description,ImageUrl,Price,Stock,IsActive) OUTPUT INSERTED.Id INTO @Fixture VALUES(N'[MẪU] Điện thoại 128 GB',N'Điện thoại',N'QA catalog fixture',N'/images/products/phone.svg',123000,7,1);
INSERT Products(Name,Category,Description,ImageUrl,Price,Stock,IsActive) OUTPUT INSERTED.Id INTO @Fixture VALUES(N'[MẪU] Tai nghe Bluetooth kèm hộp sạc',N'Âm thanh',N'QA catalog fixture',N'/images/products/earbuds.svg',123000,7,1);
INSERT Products(Name,Category,Description,ImageUrl,Price,Stock,IsActive) OUTPUT INSERTED.Id INTO @Fixture VALUES(N'[MẪU] Tai nghe chụp tai có micro',N'Âm thanh',N'QA catalog fixture',N'/images/products/headphones.svg',123000,7,1);
INSERT Products(Name,Category,Description,ImageUrl,Price,Stock,IsActive) OUTPUT INSERTED.Id INTO @Fixture VALUES(N'[MẪU] Laptop học tập 15 inch',N'Máy tính',N'QA catalog fixture',N'/images/products/laptop.svg',123000,7,1);
INSERT Products(Name,Category,Description,ImageUrl,Price,Stock,IsActive) OUTPUT INSERTED.Id INTO @Fixture VALUES(N'[MẪU] Đồng hồ thông minh dây silicon',N'Thiết bị đeo',N'QA catalog fixture',N'/images/products/watch.svg',123000,7,1);
INSERT Products(Name,Category,Description,ImageUrl,Price,Stock,IsActive) OUTPUT INSERTED.Id INTO @Fixture VALUES(N'[MẪU] Máy tính bảng Wi-Fi 64 GB',N'Máy tính bảng',N'QA catalog fixture',N'/images/products/tablet.svg',123000,7,1);
SELECT Id,Price,Stock,IsActive INTO #Before FROM Products;
SELECT * INTO #ItemsBefore FROM ShopOrderItems;
SELECT Id INTO #Fixtures FROM @Fixture;
GO
:r UpdateRealProductCatalog.sql
GO
SELECT * INTO #AfterFirst FROM Products;
GO
:r UpdateRealProductCatalog.sql
GO
IF EXISTS(SELECT Id,Price,Stock,IsActive FROM Products EXCEPT SELECT * FROM #Before) THROW 50001,'Price/stock/visibility changed',1;
IF EXISTS(SELECT * FROM ShopOrderItems EXCEPT SELECT * FROM #ItemsBefore) THROW 50002,'Order items changed',1;
IF EXISTS(SELECT * FROM Products EXCEPT SELECT * FROM #AfterFirst) THROW 50003,'Rerun modified rows',1;
IF (SELECT COUNT(*) FROM Products p JOIN #Fixtures f ON p.Id=f.Id WHERE ImageUrl LIKE '/images/products/official/%')<>6 THROW 50004,'Fixture update incomplete',1;
ROLLBACK;
PRINT 'PASS: all six fixtures replaced, repeat-safe, prices/stock/visibility/order snapshots preserved; QA transaction rolled back.';
