SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.[user]', 'user_password') < 512
    ALTER TABLE dbo.[user] ALTER COLUMN user_password nvarchar(256) NULL;
COMMIT;
