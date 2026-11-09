using System;
using System.IO;
using System.Linq;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TechNews.Models;
using TechNews.Services;
namespace TechNews.Controllers {
[Authorize(Roles="Admin,Editor")]
public class AssetsController:Controller {
 private readonly BLOGDBContext db;private readonly FileService files;private readonly IWebHostEnvironment env;
 public AssetsController(BLOGDBContext db,FileService files,IWebHostEnvironment env){this.db=db;this.files=files;this.env=env;}
 private int Actor=>int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
 [HttpGet("Admin/Assets")]
 public IActionResult Index()=>View(db.Assets.OrderByDescending(x=>x.Id).ToList());
 [HttpPost("Admin/Assets")]
 public IActionResult Upload(IFormFile file){try{var url=files.Upload(file);db.Assets.Add(new Asset{OwnerId=Actor,Url=url,FileName=Path.GetFileName(file.FileName).Substring(0,Math.Min(255,Path.GetFileName(file.FileName).Length)),Size=file.Length,CreatedUtc=DateTime.UtcNow});db.SaveChanges();TempData["Message"]="Đã tải ảnh lên.";}catch(ArgumentException ex){TempData["Message"]=ex.Message;}return Redirect("/Admin/Assets");}
 [HttpPost("Admin/Assets/{id:int}/Delete")]
 public IActionResult Delete(int id){var asset=db.Assets.Find(id);if(asset==null)return NotFound();if(!User.IsInRole("Admin")&&asset.OwnerId!=Actor)return Forbid();
  if(db.Articles.Any(a=>a.ArticleThumb==asset.Url||(a.ArticleContent!=null&&a.ArticleContent.Contains(asset.Url)))){TempData["Message"]="Ảnh đang được sử dụng; không thể xóa.";return Redirect("/Admin/Assets");}
  var folder=Path.GetFullPath(Path.Combine(env.WebRootPath,"uploads"))+Path.DirectorySeparatorChar;var path=Path.GetFullPath(Path.Combine(env.WebRootPath,asset.Url.TrimStart('/')));
  if(!path.StartsWith(folder,StringComparison.OrdinalIgnoreCase))return BadRequest();
  if(System.IO.File.Exists(path))System.IO.File.Delete(path);db.Assets.Remove(asset);db.SaveChanges();return Redirect("/Admin/Assets");
 }
}
}
