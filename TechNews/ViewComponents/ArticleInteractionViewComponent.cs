using System.Linq;
using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TechNews.Models;
namespace TechNews.ViewComponents {
public class ArticleInteractionViewComponent:ViewComponent {
 private readonly BLOGDBContext db;public ArticleInteractionViewComponent(BLOGDBContext db){this.db=db;}
 public IViewComponentResult Invoke(int id){
  var article=db.Articles.Find(id);var tags=db.ArticleTags.Where(x=>x.ArticleId==id).Select(x=>x.Tag).ToList();var tagIds=tags.Select(t=>t.Id).ToList();
  int.TryParse(HttpContext.User.FindFirstValue(ClaimTypes.NameIdentifier),out var userId);
  return View(new ArticleInteractionViewModel{ArticleId=id,Saved=db.SavedArticles.Any(x=>x.ArticleId==id&&x.UserId==userId),Tags=tags,Comments=db.Comments.Where(x=>x.ArticleId==id&&x.Status=="Approved").Include(x=>x.User).OrderByDescending(x=>x.Id).Take(100).ToList(),Related=db.Articles.Where(a=>a.Id!=id&&a.ArticleStatus==true&&(a.CategoryId==article.CategoryId||db.ArticleTags.Any(t=>t.ArticleId==a.Id&&tagIds.Contains(t.TagId)))).OrderByDescending(a=>a.ArticleDate).ThenByDescending(a=>a.Id).Take(4).ToList()});
 }
}
}
