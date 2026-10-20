using BlogWebsite.Models;
using BlogWebsite.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using PagedList;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Text.Json;

namespace BlogWebsite.Controllers
{

    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly ArticlesService _articlesService;
        private readonly CategoriesService _categoriesService;

        public HomeController(ILogger<HomeController> logger, ArticlesService articlesService, CategoriesService categoriesService)
        {
            _logger = logger;
            _articlesService = articlesService;
            _categoriesService = categoriesService;
        }

        [Route("/{page?}")]
        public IActionResult Index(string q, int page = 1)
        {
            var categories = _categoriesService.GetCategories().Where(c => c.ShowOnMenu).ToList();
            var categoryIds = categories.Select(c => c.Id).ToHashSet();
            var articles = _articlesService.GetArticles(q, null, null, null)
                .Where(a => a.CategoryId.HasValue && categoryIds.Contains(a.CategoryId.Value))
                .OrderByDescending(a => a.ArticleDate).ThenByDescending(a => a.Id).ToList();
            var model = new NewsHomeViewModel { Query = q };
            if (string.IsNullOrWhiteSpace(q))
            {
                var priority = _articlesService.GetPriorityArticles()
                    .Where(a => a.CategoryId.HasValue && categoryIds.Contains(a.CategoryId.Value));
                model.Headlines = articles.Take(1).Concat(priority).Concat(articles)
                    .GroupBy(a => a.Id).Select(g => g.First()).Take(7).ToList();
                model.Sections = categories.Select(c => new NewsTopicSection {
                    Category = c, Articles = articles.Where(a => a.CategoryId == c.Id).Take(4).ToList()
                }).Where(s => s.Articles.Count > 0).ToList();
            }
            var headlineIds = model.Headlines.Select(a => a.Id).ToHashSet();
            var feed = articles.Where(a => !headlineIds.Contains(a.Id)).ToList();
            const int pageSize = 8;
            int lastPage = Math.Max(1, (int)Math.Ceiling(feed.Count / (double)pageSize));
            model.Articles = feed.ToPagedList(Math.Clamp(page, 1, lastPage), pageSize);
            ViewBag.SearchString = q;
            return View(model);
        }
        [Route("{slug}-ar{id:int}")]
        public IActionResult DetailsArticle(string slug, int id)
        {
            var article = _articlesService.DetailsArticle(id);
            string articleSlug = article.ArticleTitle.Replace(" ", "-");
            if (slug.Equals(articleSlug))
            {
                ViewBag.ActiveCategoryId = article.CategoryId;
                ViewBag.IsLiked = IsLiked(id);
                ViewArticle(id);
                return View(article);
            }
            else
            {
                return RedirectToAction(nameof(DetailsArticle), new { slug = articleSlug, id });
            }
        }

        [Route("{slug}-{id:int}/{page:int?}")]
        public IActionResult GetArticlesByCategory(string slug, int id, int? page)
        {
            var category = _categoriesService.DetailsCategory(id);
            ViewBag.ActiveCategoryId = category.Id;
            ViewBag.CategoryName = category.CategoryName;
            ViewBag.CategoryDescription = category.CategoryDescription;
            string categorySlug = category.CategoryName.Replace(" ","-");
            if (slug.Equals(categorySlug))
            {
                int pageNumber = (page ?? 1);
                int pageSize = 9;
                var articles = _articlesService.GetArticles(null, null, id, null);
                pageNumber = Math.Clamp(pageNumber, 1, Math.Max(1, (int)Math.Ceiling(articles.Count / (double)pageSize)));
                return View(articles.ToPagedList(pageNumber, pageSize));
            }
            else
            {
                return RedirectToAction(nameof(GetArticlesByCategory), new { slug = categorySlug, id });
            }
            
        }

        [HttpPost]
        [Route("Like/{id}")]
        public IActionResult Like(int id)
        {
            LikeArticle(id);
            return Ok();
        }

        private void ViewArticle(int id)
        {
            var idList = HttpContext.Session.Get("view");
            if(idList != null)
            {
                Console.WriteLine("Da ton tai!");
                var articleIds = JsonSerializer.Deserialize<List<int>>(Encoding.ASCII.GetString(idList));
                if (!articleIds.Contains(id))
                {
                    _articlesService.AddViewCount(id);
                    articleIds.Add(id);
                    idList = Encoding.ASCII.GetBytes(JsonSerializer.Serialize(articleIds));
                }
            }
            else
            {
                Console.WriteLine("Tao moi!");
                List<int> articleIds = new List<int>();
                _articlesService.AddViewCount(id);
                articleIds.Add(id);
                idList = Encoding.ASCII.GetBytes(JsonSerializer.Serialize(articleIds));
            }
            
            HttpContext.Session.Set("view", idList);
            
        }

        private bool IsLiked(int id)
        {
            var idList = HttpContext.Session.Get("like");
            if (idList != null)
            {
                var articleIds = JsonSerializer.Deserialize<List<int>>(Encoding.ASCII.GetString(idList));
                if (articleIds.Contains(id))
                {
                    return true;
                }
                return false;
            }
            else
            {
                List<int> articleIds = new List<int>();
                idList = Encoding.ASCII.GetBytes(JsonSerializer.Serialize(articleIds));
                HttpContext.Session.Set("like", idList);
                return false;
            }
        }

        private void LikeArticle(int id)
        {
            var idList = HttpContext.Session.Get("like");
            if (idList != null)
            {
                var articleIds = JsonSerializer.Deserialize<List<int>>(Encoding.ASCII.GetString(idList));
                if (!articleIds.Contains(id))
                {
                    _articlesService.LikeArticle(id, true);
                    articleIds.Add(id);
                    idList = Encoding.ASCII.GetBytes(JsonSerializer.Serialize(articleIds));
                }
                else
                {
                    _articlesService.LikeArticle(id, false);
                    articleIds.Remove(id);
                    idList = Encoding.ASCII.GetBytes(JsonSerializer.Serialize(articleIds));
                }
            }
            else
            {
                List<int> articleIds = new List<int>();
                _articlesService.LikeArticle(id, true);
                articleIds.Add(id);
                idList = Encoding.ASCII.GetBytes(JsonSerializer.Serialize(articleIds));
            }
            HttpContext.Session.Set("like", idList);
        }


        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
