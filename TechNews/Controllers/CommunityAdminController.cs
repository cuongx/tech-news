using System;
using System.Linq;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TechNews.Models;
namespace TechNews.Controllers {
[Authorize(Roles="Admin")]
public class CommunityAdminController:Controller {
 private readonly BLOGDBContext db;public CommunityAdminController(BLOGDBContext db){this.db=db;}
 [HttpGet("Admin/Comments")]
 public IActionResult Comments(string status){var query=db.Comments.Include(x=>x.User).Include(x=>x.Article).AsQueryable();if(!string.IsNullOrEmpty(status))query=query.Where(x=>x.Status==status);return View(query.OrderByDescending(x=>x.Id).ToList());}
 [HttpPost("Admin/Comments/{id:int}")]
 public IActionResult Moderate(int id,string status){var c=db.Comments.Find(id);if(c==null)return NotFound();if(status!="Approved"&&status!="Rejected"&&status!="Hidden")return BadRequest();c.Status=status;c.ModeratorId=int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));c.ModeratedUtc=DateTime.UtcNow;db.SaveChanges();return Redirect("/Admin/Comments");}
 [HttpGet("Admin/Tags")]
 public IActionResult Tags()=>View(db.Tags.OrderBy(x=>x.Name).ToList());
 [HttpPost("Admin/Tags")]
 public IActionResult Tag(int id,string name,bool delete=false){
  var tag=id==0?new Tag():db.Tags.Find(id);if(tag==null)return NotFound();
  if(delete){if(db.ArticleTags.Any(x=>x.TagId==id)){TempData["Message"]="Tag đang gắn với bài viết; hãy bỏ liên kết trước khi xóa.";}else{db.Tags.Remove(tag);db.SaveChanges();}return Redirect("/Admin/Tags");}
  name=name?.Trim();if(string.IsNullOrEmpty(name)||name.Length>60||db.Tags.Any(x=>x.Id!=id&&x.Name==name)){TempData["Message"]="Tên tag trống, dài quá 60 ký tự hoặc đã tồn tại.";return Redirect("/Admin/Tags");}
  tag.Name=name;if(id==0)db.Tags.Add(tag);db.SaveChanges();return Redirect("/Admin/Tags");
 }
 [HttpGet("Admin/Dashboard")]
 public IActionResult Dashboard(DateTime? from,DateTime? to){
  var today=DateTime.UtcNow.AddHours(7).Date;var start=(from??today.AddDays(-29)).Date;var end=(to??today).Date;
  if(!ModelState.IsValid||end<start||end>today||(end-start).TotalDays>366){ModelState.AddModelError("","Khoảng ngày không hợp lệ; chọn tối đa 366 ngày đến hôm nay.");start=today.AddDays(-29);end=today;}
  var days=db.DailyViews.Where(x=>x.Day>=start&&x.Day<=end).GroupBy(x=>x.Day).Select(g=>new DailyView{Day=g.Key,Views=g.Sum(x=>x.Views)}).OrderBy(x=>x.Day).ToList();
  var model=new DashboardViewModel{From=start,To=end,States=db.Articles.GroupBy(x=>x.EditorialState).Select(g=>new{Key=g.Key,Count=g.Count()}).ToDictionary(x=>x.Key,x=>x.Count),Categories=db.Articles.GroupBy(x=>x.Category.CategoryName).Select(g=>new{Key=g.Key,Count=g.Count()}).ToList().ToDictionary(x=>x.Key??"Chưa phân loại",x=>x.Count),TotalViews=db.Articles.Sum(x=>x.ViewCounts??0),PeriodViews=days.Sum(x=>x.Views),Days=days};return View(model);
 }
}
}
