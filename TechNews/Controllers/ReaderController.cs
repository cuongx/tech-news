using System;
using System.Linq;
using System.Security.Claims;
using System.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TechNews.Models;
using TechNews.Services;
namespace TechNews.Controllers {
[Authorize]
public class ReaderController:Controller {
 private readonly BLOGDBContext db;private readonly UsersService users;
 public ReaderController(BLOGDBContext db,UsersService users){this.db=db;this.users=users;}
 private int Actor=>int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
 [AllowAnonymous,HttpGet("Account/Register")]
 public IActionResult Register()=>View(new User());
 [AllowAnonymous,HttpPost("Account/Register")]
 public IActionResult Register([Bind("UserName,UserLogin,UserEmail,UserPassword")]User user,string confirmPassword){
  user.UserRole="Reader";
  using var tx=db.Database.BeginTransaction(IsolationLevel.Serializable);
  var error=users.Validate(user,true);
  if(error!=null)ModelState.AddModelError("",error);
  if(user.UserPassword!=confirmPassword)ModelState.AddModelError("","Mật khẩu xác nhận không khớp.");
  if(!ModelState.IsValid){user.UserPassword=null;ModelState.Remove("UserPassword");return View(user);}
  users.CreateUser(user);tx.Commit();TempData["Message"]="Đăng ký thành công. Hãy đăng nhập.";return Redirect("/Admin/Login");
 }
 [HttpGet("Account")]
 public IActionResult Profile(){var user=users.DetailsUser(Actor);if(user==null)return NotFound();user.UserPassword=null;return View(user);}
 [HttpPost("Account")]
 public IActionResult Profile([Bind("UserName,UserLogin,UserEmail")]User user){
  user.Id=Actor;var error=users.Validate(user,profile:true);if(error!=null)ModelState.AddModelError("",error);
  if(!ModelState.IsValid)return View(user);users.ChangeProfile(user);TempData["Message"]="Đã lưu hồ sơ.";return Redirect("/Account");
 }
 [HttpPost("Account/Password")]
 public IActionResult Password(string oldPassword,string newPassword,string confirmPassword){
  if(newPassword==null||newPassword.Length<8||newPassword.Length>128||newPassword!=confirmPassword||!users.CheckPassWord(Actor,oldPassword))
   TempData["AccountPasswordError"]="Mật khẩu hiện tại chưa đúng, hoặc mật khẩu mới/xác nhận chưa hợp lệ (8–128 ký tự).";
  else {users.ChangePassword(Actor,newPassword);TempData["Message"]="Đã đổi mật khẩu.";}
  return Redirect("/Account");
 }
 [HttpGet("Account/Saved")]
 public IActionResult Saved()=>View(db.SavedArticles.Where(x=>x.UserId==Actor).Include(x=>x.Article).OrderByDescending(x=>x.CreatedUtc).ToList());
 [HttpPost("Account/Save/{id:int}")]
 public IActionResult Save(int id,bool saved){
  using var tx=db.Database.BeginTransaction(IsolationLevel.Serializable);
  var existing=db.SavedArticles.Find(Actor,id);
  if(saved){if(!db.Articles.Any(a=>a.Id==id&&a.ArticleStatus==true))return NotFound();if(existing==null)db.SavedArticles.Add(new SavedArticle{UserId=Actor,ArticleId=id,CreatedUtc=DateTime.UtcNow});}
  else if(existing!=null)db.SavedArticles.Remove(existing);
  db.SaveChanges();tx.Commit();TempData["Message"]=saved?"Đã lưu bài viết.":"Đã bỏ lưu bài viết.";return Redirect("/Account/Saved");
 }
 [HttpPost("Articles/{id:int}/Comments")]
 public IActionResult Comment(int id,string body){
  var article=db.Articles.Find(id);if(article==null||article.ArticleStatus!=true)return NotFound();
  body=body?.Trim();
  if(string.IsNullOrEmpty(body)||body.Length>2000)TempData["Message"]="Bình luận cần từ 1 đến 2000 ký tự.";
  else {db.Comments.Add(new Comment{UserId=Actor,ArticleId=id,Body=body,CreatedUtc=DateTime.UtcNow});db.SaveChanges();TempData["Message"]="Bình luận đã gửi và đang chờ duyệt.";}
  return RedirectToAction("DetailsArticle","Home",new{slug=article.ArticleTitle.Replace(" ","-"),id});
 }
 [HttpPost("Account/Comments/{id:int}/Delete")]
 public IActionResult DeleteComment(int id){var comment=db.Comments.Find(id);if(comment==null)return NotFound();if(comment.UserId!=Actor)return Forbid();db.Comments.Remove(comment);db.SaveChanges();TempData["Message"]="Đã xóa bình luận.";return Redirect("/Account/Comments");}
 [HttpGet("Account/Comments")]
 public IActionResult Comments()=>View(db.Comments.Where(x=>x.UserId==Actor).Include(x=>x.Article).OrderByDescending(x=>x.Id).ToList());
}
}
