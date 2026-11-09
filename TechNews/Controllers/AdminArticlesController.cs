using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using TechNews.Models;
using TechNews.Services;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using PagedList;
using Microsoft.AspNetCore.Http;
using System.Diagnostics;

namespace TechNews.Controllers
{
    [Authorize(Roles = "Admin,Editor")]
    public class AdminArticlesController : Controller
    {
        private readonly ArticlesService _articlesService;
        private readonly CategoriesService _categoriesService;
        private readonly FileService _fileService;

        public AdminArticlesController(ArticlesService articlesService, CategoriesService categoriesService, FileService fileService)
        {
            _articlesService = articlesService;
            _categoriesService = categoriesService;
            _fileService = fileService;
        }

        [Route("Admin/Articles/{page?}")]
        public IActionResult Index(string q, string sortOrder, int? categoryId, int? page)
        {
            int pageNumber = (page ?? 1);
            int pageSize = 5;
            List<Article> articles;

            if (User.IsInRole("Admin"))
            {
                articles = _articlesService.GetArticles(q, sortOrder, categoryId, null, true);
            }
            else
            {
                int authorId = Int32.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
                articles = _articlesService.GetArticles(q, sortOrder, categoryId, authorId, true);
            }

            List<string> order = new List<string> { "date", "date_desc", "title", "title_desc" };

            ViewBag.SearchString = q;
            ViewBag.CategorySelectlist = new SelectList(_categoriesService.GetCategories(), "Id", "CategoryName", categoryId);
            ViewBag.OrderSelectlist = new SelectList(order, sortOrder);
            return View(articles.ToPagedList(Math.Clamp(pageNumber, 1, Math.Max(1, (int)Math.Ceiling(articles.Count / (double)pageSize))), pageSize));
        }

        [Route("Admin/EditArticle/{id}")]
        public IActionResult Edit(int id)
        {

            var article = _articlesService.DetailsArticle(id, true);
            if (article == null) return NotFound();
            if (!User.IsInRole("Admin") && article.AuthorId.ToString() != User.FindFirstValue(ClaimTypes.NameIdentifier)) return Forbid();

            ViewBag.CategorySelectlist = new SelectList(_categoriesService.GetCategories(), "Id", "CategoryName", article.CategoryId);

            article.TagsText = _articlesService.TagsFor(article.Id);
            return View(article);
        }

        [HttpPost]
        [Route("Admin/EditArticle/{id}")]
        public IActionResult Edit(int id, [Bind("Id,ArticleTitle,ArticleDescription,ArticleContent,ArticleThumb,CategoryId,Source,TagsText")] Article updateArticle)
        {
            int authorId = Int32.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            if (id != updateArticle.Id) return BadRequest();
            var existing = _articlesService.DetailsArticle(updateArticle.Id, true);
            if (existing == null) return NotFound();
            if (!User.IsInRole("Admin") && existing.AuthorId != authorId) return Forbid();
            updateArticle.AuthorId = authorId;
            ValidateArticle(updateArticle);
            if (!ModelState.IsValid)
            {
                ViewBag.CategorySelectlist = new SelectList(_categoriesService.GetCategories(), "Id", "CategoryName", updateArticle.CategoryId);
                return View(updateArticle);
            }
            if (User.IsInRole("Admin") || authorId == existing.AuthorId)
            {
                TempData["Message"] = "Sửa thành công";
                _articlesService.UpdateArticle(updateArticle);
            }
            else
            {
                return Redirect("/Admin/Articles");
            }

            return Redirect("/Admin/Articles"); ;
        }

        [HttpPost, Route("Admin/DeleteArticle/{id}")]
        public IActionResult Delete(int id)
        {
            int authorId = Int32.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            var article = _articlesService.DetailsArticle(id, true);
            if (article == null) return NotFound();
            if (!User.IsInRole("Admin") && article.AuthorId.ToString() != User.FindFirstValue(ClaimTypes.NameIdentifier)) return Forbid();
            if (User.IsInRole("Admin") || article.AuthorId == authorId)
            {
                TempData["Message"] = "Xoá thành công";
                _articlesService.DeleteArticle(id);
            }
            else
            {
                return Redirect("/Admin/Articles");
            }
            return Redirect("/Admin/Articles");
        }

        private void ValidateArticle(Article article)
        {
            article.ArticleContent = new Ganss.Xss.HtmlSanitizer().Sanitize(article.ArticleContent ?? "");
            var tags=(article.TagsText??"").Split(',');
            if(tags.Length>10 || System.Linq.Enumerable.Any(tags,t=>t.Trim().Length>60)) ModelState.AddModelError("TagsText","Tối đa 10 tag, mỗi tag tối đa 60 ký tự.");
            if (!string.IsNullOrWhiteSpace(article.ArticleThumb) && !(article.ArticleThumb.StartsWith("/") && !article.ArticleThumb.StartsWith("//")) && !(Uri.TryCreate(article.ArticleThumb,UriKind.Absolute,out var imageUri) && (imageUri.Scheme=="https"||imageUri.Scheme=="http"))) ModelState.AddModelError("ArticleThumb","Đường dẫn ảnh không hợp lệ.");
            if (string.IsNullOrWhiteSpace(article.ArticleTitle)) ModelState.AddModelError(nameof(article.ArticleTitle), "Vui lòng nhập tiêu đề.");
            if (string.IsNullOrWhiteSpace(article.ArticleContent)) ModelState.AddModelError(nameof(article.ArticleContent), "Vui lòng nhập nội dung.");
            if (!article.CategoryId.HasValue || _categoriesService.DetailsCategory(article.CategoryId.Value) == null)
                ModelState.AddModelError(nameof(article.CategoryId), "Chuyên mục không hợp lệ.");
        }

        [Route("Admin/CreateArticle")]
        public IActionResult Create()
        {
            ViewBag.CategorySelectlist = new SelectList(_categoriesService.GetCategories(), "Id", "CategoryName");
            return View();
        }


        [HttpPost]
        [Route("Admin/CreateArticle")]
        public IActionResult Create([Bind("ArticleTitle,ArticleDescription,ArticleContent,ArticleThumb,CategoryId,Source,TagsText")] Article article)
        {
            int authorId = Int32.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            ValidateArticle(article);
            if (!ModelState.IsValid)
            {
                ViewBag.CategorySelectlist = new SelectList(_categoriesService.GetCategories(), "Id", "CategoryName", article.CategoryId);
                article.TagsText = _articlesService.TagsFor(article.Id);
            return View(article);
            }
            article.AuthorId = authorId;
            article.ArticleStatus = false;
            _articlesService.CreateArticle(article);
            TempData["Message"] = "Tạo thành công";
            return Redirect("/Admin/Articles");
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        [Route("Admin/ActiveArticle/{id}")]
        public IActionResult Active(int id)
        {
            if (_articlesService.DetailsArticle(id, true) == null) return NotFound();
            var db=HttpContext.RequestServices.GetService(typeof(BLOGDBContext)) as BLOGDBContext;
            var article=db.Articles.Find(id);
            var previous=article.EditorialState;
            article.ArticleStatus=article.ArticleStatus!=true;
            article.EditorialState=article.ArticleStatus==true?"Published":"Unpublished";
            article.ScheduledUtc=null;
            db.EditorialEvents.Add(new EditorialEvent{ArticleId=id,ActorId=int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)),FromState=previous,ToState=article.EditorialState,Note="Admin trực tiếp duyệt và thay đổi hiển thị",CreatedUtc=DateTime.UtcNow});
            db.SaveChanges();
            return Ok("Thay đổi trạng thái bài viết thành công");
        }
        [Authorize(Roles = "Admin")]
        [Route("Admin/BreakingNews")]
        public IActionResult ChangePriority()
        {
            var articles = _articlesService.GetPriorityArticles(true);
            return View(articles);
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        [Route("Admin/ChangePriority")]
        public IActionResult ChangePriority(int id, int priority)
        {
            if (_articlesService.DetailsArticle(id, true) == null) return NotFound();
            if (priority < 0 || priority > 999) return BadRequest();
            _articlesService.ChangePriority(id, priority);
            if(priority != 0)
            {
                TempData["Message"] = "Thay đổi thành công";
            }
            else
            {
                TempData["Message"] = "Xoá thành công";
            }
            return Redirect("/Admin/BreakingNews");
        }

        [HttpPost]
        [Authorize(Roles = "Admin,Editor")]
        [Route("Admin/UploadImage")]
        public IActionResult UploadImage(IFormFile file)
        {
            try {
                var url=_fileService.Upload(file);
                var db=HttpContext.RequestServices.GetService(typeof(BLOGDBContext)) as BLOGDBContext;
                db.Assets.Add(new Asset{OwnerId=int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)),Url=url,FileName=System.IO.Path.GetFileName(file.FileName).Substring(0,Math.Min(255,System.IO.Path.GetFileName(file.FileName).Length)),Size=file.Length,CreatedUtc=DateTime.UtcNow});
                db.SaveChanges(); return Ok(url);
            } catch (ArgumentException ex) { return BadRequest(ex.Message); }
        }

    }
}
