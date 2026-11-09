SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.[user]', 'user_password') < 512 ALTER TABLE dbo.[user] ALTER COLUMN user_password nvarchar(256) NULL;
IF COL_LENGTH('dbo.article','EditorialState') IS NULL BEGIN
 ALTER TABLE dbo.article ADD EditorialState nvarchar(20) NOT NULL CONSTRAINT DF_article_state DEFAULT 'Draft', ScheduledUtc datetime2 NULL;
 EXEC('UPDATE dbo.article SET EditorialState = CASE WHEN article_status = 1 THEN ''Published'' ELSE ''Draft'' END');
END;
IF OBJECT_ID('dbo.SavedArticles') IS NULL CREATE TABLE dbo.SavedArticles (
 UserId int NOT NULL REFERENCES dbo.[user](id), ArticleId int NOT NULL REFERENCES dbo.article(id) ON DELETE CASCADE,
 CreatedUtc datetime2 NOT NULL, CONSTRAINT PK_SavedArticles PRIMARY KEY(UserId,ArticleId));
IF OBJECT_ID('dbo.Comments') IS NULL CREATE TABLE dbo.Comments (
 Id int IDENTITY PRIMARY KEY, UserId int NOT NULL REFERENCES dbo.[user](id), ArticleId int NOT NULL REFERENCES dbo.article(id) ON DELETE CASCADE,
 Body nvarchar(2000) NOT NULL, Status nvarchar(20) NOT NULL, CreatedUtc datetime2 NOT NULL, ModeratorId int NULL REFERENCES dbo.[user](id), ModeratedUtc datetime2 NULL);
IF OBJECT_ID('dbo.EditorialEvents') IS NULL CREATE TABLE dbo.EditorialEvents (
 Id int IDENTITY PRIMARY KEY, ArticleId int NOT NULL REFERENCES dbo.article(id) ON DELETE CASCADE, ActorId int NULL REFERENCES dbo.[user](id),
 FromState nvarchar(20) NOT NULL, ToState nvarchar(20) NOT NULL, Note nvarchar(1000) NULL, CreatedUtc datetime2 NOT NULL);
IF OBJECT_ID('dbo.Tags') IS NULL CREATE TABLE dbo.Tags (Id int IDENTITY PRIMARY KEY, Name nvarchar(60) NOT NULL UNIQUE);
IF OBJECT_ID('dbo.ArticleTags') IS NULL CREATE TABLE dbo.ArticleTags (
 ArticleId int NOT NULL REFERENCES dbo.article(id) ON DELETE CASCADE, TagId int NOT NULL REFERENCES dbo.Tags(Id), CONSTRAINT PK_ArticleTags PRIMARY KEY(ArticleId,TagId));
IF OBJECT_ID('dbo.Assets') IS NULL CREATE TABLE dbo.Assets (
 Id int IDENTITY PRIMARY KEY, OwnerId int NOT NULL REFERENCES dbo.[user](id), Url nvarchar(100) NOT NULL UNIQUE,
 FileName nvarchar(255) NOT NULL, Size bigint NOT NULL, CreatedUtc datetime2 NOT NULL);
IF OBJECT_ID('dbo.DailyViews') IS NULL CREATE TABLE dbo.DailyViews (
 ArticleId int NOT NULL REFERENCES dbo.article(id) ON DELETE CASCADE, Day date NOT NULL, Views int NOT NULL, CONSTRAINT PK_DailyViews PRIMARY KEY(ArticleId,Day));
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Comments_Article_Status') CREATE INDEX IX_Comments_Article_Status ON dbo.Comments(ArticleId,Status,CreatedUtc);
COMMIT;
