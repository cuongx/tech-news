:ON ERROR EXIT
USE [BLOGDB];
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'Trí tuệ nhân tạo') INSERT dbo.category(category_name,category_description) VALUES(N'Trí tuệ nhân tạo',N'AI, mô hình ngôn ngữ và ứng dụng trí tuệ nhân tạo.');
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'Điện thoại') INSERT dbo.category(category_name,category_description) VALUES(N'Điện thoại',N'Smartphone, hệ điều hành di động và công nghệ camera.');
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'Máy tính') INSERT dbo.category(category_name,category_description) VALUES(N'Máy tính',N'Laptop, PC, linh kiện và thiết bị ngoại vi.');
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'Phần mềm') INSERT dbo.category(category_name,category_description) VALUES(N'Phần mềm',N'Ứng dụng, công cụ làm việc, lập trình và điện toán đám mây.');
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'An toàn thông tin') INSERT dbo.category(category_name,category_description) VALUES(N'An toàn thông tin',N'Bảo mật, quyền riêng tư và phòng tránh lừa đảo trực tuyến.');
IF COL_LENGTH('dbo.category','display_order') IS NULL
BEGIN
    ALTER TABLE dbo.category ADD display_order int NOT NULL CONSTRAINT DF_category_display_order DEFAULT(100);
END;
IF COL_LENGTH('dbo.category','show_on_menu') IS NULL
BEGIN
    ALTER TABLE dbo.category ADD show_on_menu bit NOT NULL CONSTRAINT DF_category_show_on_menu DEFAULT(0);
    EXEC sp_executesql N'UPDATE dbo.category SET show_on_menu=1, display_order=CASE category_name WHEN N''Trí tuệ nhân tạo'' THEN 1 WHEN N''Điện thoại'' THEN 2 WHEN N''Máy tính'' THEN 3 WHEN N''Phần mềm'' THEN 4 WHEN N''An toàn thông tin'' THEN 5 END WHERE category_name IN (N''Trí tuệ nhân tạo'',N''Điện thoại'',N''Máy tính'',N''Phần mềm'',N''An toàn thông tin'');';
END;
COMMIT;
GO
SELECT id,category_name,show_on_menu,display_order FROM dbo.category ORDER BY display_order,id;
