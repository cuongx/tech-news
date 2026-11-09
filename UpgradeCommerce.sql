SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.Products') IS NULL CREATE TABLE dbo.Products (
 Id int IDENTITY PRIMARY KEY, Name nvarchar(160) NOT NULL, Category nvarchar(80) NOT NULL,
 Description nvarchar(4000) NULL, ImageUrl nvarchar(500) NULL, Price decimal(18,0) NOT NULL CHECK(Price>=1000),
 Stock int NOT NULL CHECK(Stock>=0), IsActive bit NOT NULL, Version rowversion NOT NULL);
IF OBJECT_ID('dbo.ShopOrders') IS NULL CREATE TABLE dbo.ShopOrders (
 Id int IDENTITY PRIMARY KEY, UserId int NOT NULL REFERENCES dbo.[user](id), CheckoutToken uniqueidentifier NOT NULL,
 Recipient nvarchar(100) NOT NULL, Phone nvarchar(20) NOT NULL, Address nvarchar(500) NOT NULL, Note nvarchar(1000) NULL,
 Status nvarchar(20) NOT NULL CHECK(Status IN ('Pending','Confirmed','Shipping','Completed','Cancelled')),
 CreatedUtc datetime2 NOT NULL, Total decimal(18,0) NOT NULL CHECK(Total>=0), Version rowversion NOT NULL);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_ShopOrders_CheckoutToken' AND object_id=OBJECT_ID('dbo.ShopOrders'))
 CREATE UNIQUE INDEX IX_ShopOrders_CheckoutToken ON dbo.ShopOrders(CheckoutToken);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_ShopOrders_UserId' AND object_id=OBJECT_ID('dbo.ShopOrders'))
 CREATE INDEX IX_ShopOrders_UserId ON dbo.ShopOrders(UserId,Id);
IF OBJECT_ID('dbo.ShopOrderItems') IS NULL CREATE TABLE dbo.ShopOrderItems (
 Id int IDENTITY PRIMARY KEY, ShopOrderId int NOT NULL REFERENCES dbo.ShopOrders(Id) ON DELETE CASCADE,
 ProductId int NOT NULL REFERENCES dbo.Products(Id), ProductName nvarchar(160) NOT NULL,
 Quantity int NOT NULL CHECK(Quantity BETWEEN 1 AND 99), UnitPrice decimal(18,0) NOT NULL CHECK(UnitPrice>=1000));
COMMIT;
