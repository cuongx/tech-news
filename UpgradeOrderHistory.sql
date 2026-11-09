SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.ShopOrderEvents') IS NULL
BEGIN
 CREATE TABLE dbo.ShopOrderEvents (
  Id int IDENTITY PRIMARY KEY, ShopOrderId int NOT NULL REFERENCES dbo.ShopOrders(Id) ON DELETE CASCADE,
  Status nvarchar(20) NOT NULL, ActorRole nvarchar(20) NOT NULL, ActorId int NULL,
  Reason nvarchar(500) NULL, CreatedUtc datetime2 NOT NULL);
 CREATE INDEX IX_ShopOrderEvents_ShopOrderId ON dbo.ShopOrderEvents(ShopOrderId,Id);
 -- Preserve current state only; earlier transitions were not recorded.
 INSERT INTO dbo.ShopOrderEvents(ShopOrderId,Status,ActorRole,Reason,CreatedUtc)
 SELECT Id,Status,'System',N'Trạng thái tại thời điểm bắt đầu lưu lịch sử.',SYSUTCDATETIME() FROM dbo.ShopOrders;
END;
COMMIT;
