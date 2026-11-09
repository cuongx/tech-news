using System;
using System.Linq;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TechNews.Models;
namespace TechNews.Controllers {
public class SearchController:Controller {
 private readonly BLOGDBContext db;public SearchController(BLOGDBContext db){this.db=db;}
 [HttpGet("Search")]
 public IActionResult Index(string q,int? categoryId,int? tagId,DateTime? from,DateTime? to,int page=1){
  var query=db.Articles.Where(a=>a.ArticleStatus==true).Include(a=>a.Category).Include(a=>a.Author).AsQueryable();
  q=q?.Trim();if(!string.IsNullOrEmpty(q))query=query.Where(a=>a.ArticleTitle.Contains(q)||a.ArticleDescription.Contains(q));
  if(categoryId.HasValue)query=query.Where(a=>a.CategoryId==categoryId);
  if(tagId.HasValue)query=query.Where(a=>db.ArticleTags.Any(t=>t.ArticleId==a.Id&&t.TagId==tagId));
  if(from.HasValue)query=query.Where(a=>a.ArticleDate>=from.Value.Date);
  if(to.HasValue)query=query.Where(a=>a.ArticleDate<=to.Value.Date);
  if(!ModelState.IsValid || (from.HasValue&&to.HasValue&&from>to)){ModelState.AddModelError("","Khoảng ngày không hợp lệ.");query=query.Where(a=>false);}
  var count=query.Count();var pages=Math.Max(1,(int)Math.Ceiling(count/9d));page=Math.Clamp(page,1,pages);
  return View(new SearchViewModel{Q=q,CategoryId=categoryId,TagId=tagId,From=from,To=to,Page=page,Pages=pages,Total=count,Articles=query.OrderByDescending(a=>a.ArticleDate).ThenByDescending(a=>a.Id).Skip((page-1)*9).Take(9).ToList(),Categories=db.Categories.OrderBy(c=>c.DisplayOrder).ToList(),Tags=db.Tags.OrderBy(t=>t.Name).ToList()});
 }
}
}
