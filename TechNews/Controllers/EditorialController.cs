using System;
using System.Linq;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TechNews.Models;
using TechNews.Services;
namespace TechNews.Controllers {
[Authorize(Roles="Admin,Editor")]
public class EditorialController:Controller {
 private readonly BLOGDBContext db; private readonly EditorialService service;
 public EditorialController(BLOGDBContext db,EditorialService service){this.db=db;this.service=service;}
 private int Actor=>int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
 [HttpGet("Admin/Workflow")]
 public IActionResult Index(string state=null) {
  var query=db.Articles.AsQueryable();if(!User.IsInRole("Admin")) query=query.Where(a=>a.AuthorId==Actor);
  if(!string.IsNullOrEmpty(state))query=query.Where(a=>a.EditorialState==state);
  ViewBag.State=state;return View(query.OrderByDescending(a=>a.Id).ToList());
 }
 [HttpGet("Admin/Workflow/{id:int}")]
 public IActionResult Details(int id) {
  var a=db.Articles.Find(id);if(a==null)return NotFound();if(!User.IsInRole("Admin")&&a.AuthorId!=Actor)return Forbid();
  ViewBag.History=db.EditorialEvents.Where(x=>x.ArticleId==id).OrderByDescending(x=>x.Id).ToList();return View(a);
 }
 [HttpPost("Admin/Workflow/{id:int}")]
 public IActionResult Transition(int id,string target,string note,DateTime? schedule) {
  var a=db.Articles.Find(id);if(a==null)return NotFound();if(!User.IsInRole("Admin")&&a.AuthorId!=Actor)return Forbid();
  if(!ModelState.IsValid){TempData["Message"]="Lịch đăng không hợp lệ.";return RedirectToAction("Details",new{id});}
  DateTime? utc=schedule.HasValue?DateTime.SpecifyKind(schedule.Value.AddHours(-7),DateTimeKind.Utc):null;
  TempData["Message"]=service.Transition(id,Actor,User.IsInRole("Admin"),target,note,utc)??"Đã cập nhật trạng thái bài.";
  return RedirectToAction("Details",new{id});
 }
}
}
