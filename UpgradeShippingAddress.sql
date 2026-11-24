-- Run after UpgradeCommerce.sql and UpgradeOrderHistory.sql on the chosen database.
-- Existing free-text addresses remain intact; do not guess old administrative codes.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.ShopOrders') IS NULL OR OBJECT_ID('dbo.ShopOrderEvents') IS NULL
    THROW 50001, 'Apply UpgradeCommerce.sql and UpgradeOrderHistory.sql first.', 1;
IF COL_LENGTH('dbo.ShopOrders','ProvinceCode') IS NULL
    ALTER TABLE dbo.ShopOrders ADD ProvinceCode int NULL;
IF COL_LENGTH('dbo.ShopOrders','WardCode') IS NULL
    ALTER TABLE dbo.ShopOrders ADD WardCode int NULL;
IF COL_LENGTH('dbo.ShopOrders','AddressLine') IS NULL
    ALTER TABLE dbo.ShopOrders ADD AddressLine nvarchar(300) NULL;
IF COL_LENGTH('dbo.ShopOrderEvents','AddressBefore') IS NULL
    ALTER TABLE dbo.ShopOrderEvents ADD AddressBefore nvarchar(500) NULL;
IF COL_LENGTH('dbo.ShopOrderEvents','AddressAfter') IS NULL
    ALTER TABLE dbo.ShopOrderEvents ADD AddressAfter nvarchar(500) NULL;
COMMIT;
