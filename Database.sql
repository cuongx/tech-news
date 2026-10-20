-- Clean development schema. No personal accounts or production data.
-- Run in SQL Server Management Studio or sqlcmd.
USE [master];
GO
IF DB_ID(N'BLOGDB') IS NULL CREATE DATABASE [BLOGDB];
GO
USE [BLOGDB];
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID(N'dbo.article', N'U') IS NOT NULL
   OR OBJECT_ID(N'dbo.category', N'U') IS NOT NULL
   OR OBJECT_ID(N'dbo.user', N'U') IS NOT NULL
    THROW 51000, 'BLOGDB already contains application tables. No changes applied.', 1;

CREATE TABLE dbo.[user] (
    id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    user_name nvarchar(50) NULL,
    user_email nvarchar(50) NULL,
    user_login nvarchar(50) NULL,
    user_password nvarchar(50) NULL,
    user_role varchar(10) NULL
);
CREATE TABLE dbo.category (
    id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    category_name nvarchar(50) NOT NULL,
    category_description nvarchar(100) NULL,
    show_on_menu bit NOT NULL DEFAULT(0),
    display_order int NOT NULL DEFAULT(100)
);
CREATE TABLE dbo.article (
    id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    article_title nvarchar(300) NULL,
    article_description nvarchar(300) NULL,
    article_content nvarchar(max) NULL,
    article_thumb nvarchar(100) NULL,
    article_date date NOT NULL DEFAULT(CONVERT(date,GETDATE())),
    category_id int NULL,
    author_id int NULL,
    article_priority int NULL DEFAULT(0),
    view_counts int NULL DEFAULT(0),
    like_counts int NULL DEFAULT(0),
    article_status bit NULL DEFAULT(0),
    source nvarchar(50) NULL,
    CONSTRAINT FK_article_category FOREIGN KEY(category_id) REFERENCES dbo.category(id),
    CONSTRAINT FK_article_user FOREIGN KEY(author_id) REFERENCES dbo.[user](id)
);
-- Keep the category identities used by the existing view themes.
SET IDENTITY_INSERT dbo.category ON;
INSERT dbo.category(id,category_name,category_description,show_on_menu,display_order) VALUES
(8,N'Trí tuệ nhân tạo',N'AI, mô hình ngôn ngữ và ứng dụng trí tuệ nhân tạo.',1,1),
(9,N'Điện thoại',N'Smartphone, hệ điều hành di động và công nghệ camera.',1,2),
(10,N'Máy tính',N'Laptop, PC, linh kiện và thiết bị ngoại vi.',1,3),
(11,N'An toàn thông tin',N'Bảo mật, quyền riêng tư và kỹ năng an toàn số.',1,5),
(12,N'Phần mềm',N'Ứng dụng, công cụ làm việc và lập trình.',1,4);
SET IDENTITY_INSERT dbo.category OFF;
COMMIT TRANSACTION;
GO
