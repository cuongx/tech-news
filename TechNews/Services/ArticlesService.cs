using TechNews.Models;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;

namespace TechNews.Services
{
    public class ArticlesService
    {
        private readonly BLOGDBContext _dbContext;
        public ArticlesService(BLOGDBContext dbContext)
        {
            _dbContext = dbContext;
        }

        public List<Article> GetArticles(string searchString, string sortOrder, int? categoryId, int? authorId, bool allowHidden = false)
        {
            var articles = _dbContext.Articles
                .Include(a => a.Author)
                .Include(a => a.Category)
                .Select(a => a)
                ;

            if (!allowHidden)
            {
                articles = articles.Where(a => a.ArticleStatus == true);
            }

            if (!string.IsNullOrEmpty(searchString))
            {
                articles = articles.Where(a => a.ArticleTitle.Contains(searchString));
            }

            if (categoryId != null)
            {
                articles = articles.Where(a => a.CategoryId == categoryId);
            }

            if (authorId != null)
            {
                articles = articles.Where(a => a.AuthorId == authorId);
            }

            switch (sortOrder)
            {
                case "date":
                    articles = articles.OrderByDescending(a => a.ArticleDate).ThenByDescending(a => a.Id);
                    break;
                case "title":
                    articles = articles.OrderBy(a => a.ArticleTitle);
                    break;
                case "date_desc":
                    articles = articles.OrderBy(a => a.ArticleDate);
                    break;
                case "title_desc":
                    articles = articles.OrderByDescending(a => a.ArticleTitle);
                    break;
                default:
                    articles = articles.OrderByDescending(a => a.ArticleDate).ThenByDescending(a => a.Id);
                    break;
            }

            var result = articles.ToList();

            return result;
        }

        public List<Article> GetPriorityArticles(bool allowHidden = false)
        {
            var articles = _dbContext.Articles
                .Where(a => a.ArticlePriority > 0 
                && ((allowHidden==false)?(a.ArticleStatus == true):true))
                .OrderBy(a => a.ArticlePriority)
                .Include(a => a.Category)
                .Include(a => a.Author)
                .ToList();
            return articles;
        }

        public List<Article> GetTopViewArticles()
        {
            var articles = _dbContext.Articles
                .Where(a => a.ArticleStatus == true)
                .Where(a => a.Category != null && a.Category.ShowOnMenu)
                .OrderByDescending(a => a.ViewCounts).ThenByDescending(a => a.ArticleDate)
                .Take(4)
                .ToList();
            return articles;
        }

        public Article DetailsArticle(int id, bool allowHidden = false)
        {

            var article = _dbContext.Articles
                .Include(a => a.Author)
                .Include(a => a.Category)
                .AsNoTracking()
                .SingleOrDefault(a => a.Id == id && (allowHidden || a.ArticleStatus == true));
            return article;
        }

        public string TagsFor(int id) => string.Join(", ",_dbContext.ArticleTags.Where(x=>x.ArticleId==id).Select(x=>x.Tag.Name).ToList());
        private void SaveTags(int id,string text) {
            var names=(text??"").Split(',').Select(x=>x.Trim()).Where(x=>x.Length>0).Distinct(StringComparer.OrdinalIgnoreCase).ToList();
            if(names.Count>10 || names.Any(x=>x.Length>60)) throw new ArgumentException("Tối đa 10 tag, mỗi tag tối đa 60 ký tự.");
            var existing=_dbContext.ArticleTags.Where(x=>x.ArticleId==id).Include(x=>x.Tag).ToList();
            _dbContext.ArticleTags.RemoveRange(existing.Where(x=>!names.Contains(x.Tag.Name,StringComparer.OrdinalIgnoreCase)));
            foreach(var name in names) {
                if(existing.Any(x=>string.Equals(x.Tag.Name,name,StringComparison.OrdinalIgnoreCase))) continue;
                var tag=_dbContext.Tags.FirstOrDefault(x=>x.Name==name) ?? new Tag{Name=name};
                _dbContext.ArticleTags.Add(new ArticleTag{ArticleId=id,Tag=tag});
            }
            _dbContext.SaveChanges();
        }
        public void CreateArticle(Article article)
        {
            using var transaction = _dbContext.Database.BeginTransaction();

            article.ArticleContent = new Ganss.Xss.HtmlSanitizer().Sanitize(article.ArticleContent ?? "");
            _dbContext.Add(article);
            _dbContext.SaveChanges();
            SaveTags(article.Id, article.TagsText);
            transaction.Commit();
        }

        public void UpdateArticle(Article updateArticle)
        {
            using var transaction = _dbContext.Database.BeginTransaction();
            var article = _dbContext.Articles.Single(a => a.Id == updateArticle.Id);

            article.ArticleTitle = updateArticle.ArticleTitle;
            article.ArticleDescription = updateArticle.ArticleDescription;
            article.ArticleContent = new Ganss.Xss.HtmlSanitizer().Sanitize(updateArticle.ArticleContent ?? "");
            article.ArticleThumb = updateArticle.ArticleThumb;
            article.CategoryId = updateArticle.CategoryId;
            article.Source = updateArticle.Source;
            var previous=article.EditorialState;
            article.EditorialState="Draft"; article.ArticleStatus=false; article.ScheduledUtc=null;
            if(previous!="Draft") _dbContext.EditorialEvents.Add(new EditorialEvent{ArticleId=article.Id,ActorId=updateArticle.AuthorId,FromState=previous,ToState="Draft",Note="Chỉnh sửa nội dung; cần duyệt lại",CreatedUtc=DateTime.UtcNow});
            SaveTags(article.Id, updateArticle.TagsText);
            transaction.Commit();

            _dbContext.SaveChanges();

        }

        public void DeleteArticle(int id)
        {
            var article = new Article { Id = id };
            _dbContext.Remove<Article>(article);
            _dbContext.SaveChanges();
        }

        public void ChangeStatus(int id)
        {
            var article = _dbContext.Articles.Find(id);
            article.ArticleStatus = !article.ArticleStatus;
            _dbContext.SaveChanges();
        }

        public void ChangePriority(int id, int priority)
        {
            var article = _dbContext.Articles.Find(id);
            article.ArticlePriority = priority;
            _dbContext.SaveChanges();
        }

        public void AddViewCount(int id)
        {
            var article = _dbContext.Articles.Find(id);
            var day=DateTime.UtcNow.AddHours(7).Date;
            _dbContext.Database.ExecuteSqlInterpolated($@"SET XACT_ABORT ON; BEGIN TRANSACTION;
UPDATE dbo.article SET view_counts=ISNULL(view_counts,0)+1 WHERE id={id};
IF EXISTS(SELECT 1 FROM dbo.DailyViews WITH(UPDLOCK,HOLDLOCK) WHERE ArticleId={id} AND Day={day})
 UPDATE dbo.DailyViews SET Views=Views+1 WHERE ArticleId={id} AND Day={day};
ELSE INSERT dbo.DailyViews(ArticleId,Day,Views) VALUES({id},{day},1);
COMMIT;");
            _dbContext.SaveChanges();
        }

        public void LikeArticle(int id, bool like)
        {
            var article = _dbContext.Articles.Find(id);
            if (like)
            {
                article.LikeCounts = (article.LikeCounts ?? 0) + 1;
            }
            else if(article.LikeCounts > 0)
            {
                article.LikeCounts--;
            }
            _dbContext.SaveChanges();
        }
    }
}
