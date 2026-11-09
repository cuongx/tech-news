using System;
using System.Linq;
using System.Data;
using System.Security.Claims;
using TechNews.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TechNews.Models;
namespace TechNews.Controllers
{
    [Authorize(Roles = "Admin"), AutoValidateAntiforgeryToken]
    public class ShopAdminController : Controller
    {
        private readonly BLOGDBContext db; private readonly OrderWorkflow workflow; public ShopAdminController(BLOGDBContext db, OrderWorkflow workflow) { this.db = db; this.workflow = workflow; }
        [HttpGet("Admin/Products")]
        public IActionResult Products(string q, int page = 1) { var query = db.Products.AsNoTracking(); if (!string.IsNullOrWhiteSpace(q)) query = query.Where(p => p.Name.Contains(q)); ViewBag.Q = q; ViewBag.Pages = Math.Max(1, (int)Math.Ceiling(query.Count() / 30d)); ViewBag.Page = Math.Clamp(page, 1, (int)ViewBag.Pages); return View(query.OrderByDescending(p => p.Id).Skip(((int)ViewBag.Page - 1) * 30).Take(30).ToList()); }
        [HttpGet("Admin/Products/Create")]
        public IActionResult Create() => View("Edit", new Product());
        [HttpGet("Admin/Products/{id:int}/Edit")]
        public IActionResult Edit(int id) { var p = db.Products.AsNoTracking().FirstOrDefault(x => x.Id == id); return p == null ? NotFound() : View(p); }
        [HttpPost("Admin/Products/Save")]
        public IActionResult Save([Bind("Id,Name,Category,Description,ImageUrl,Price,Stock,IsActive,Version")] Product input)
        {
            input.Name = input.Name?.Trim(); input.Category = input.Category?.Trim(); input.ImageUrl = input.ImageUrl?.Trim();
            if (!string.IsNullOrEmpty(input.ImageUrl) && !(input.ImageUrl.StartsWith("/images/", StringComparison.Ordinal) && !input.ImageUrl.Contains("\\")) && !(Uri.TryCreate(input.ImageUrl, UriKind.Absolute, out var uri) && uri.Scheme == "https")) ModelState.AddModelError("ImageUrl", "Dùng đường dẫn /images/... hoặc URL ảnh HTTPS.");
            if (input.Price != decimal.Truncate(input.Price)) ModelState.AddModelError("Price", "Giá bán phải là số nguyên đồng.");
            if (!ModelState.IsValid) return View("Edit", input);
            if (input.Id == 0) { input.Version = null; db.Products.Add(input); }
            else { var p = db.Products.Find(input.Id); if (p == null) return NotFound(); if (input.Version == null) return BadRequest(); db.Entry(p).Property(x => x.Version).OriginalValue = input.Version; p.Name = input.Name; p.Category = input.Category; p.Description = input.Description; p.ImageUrl = input.ImageUrl; p.Price = input.Price; p.Stock = input.Stock; p.IsActive = input.IsActive; }
            try { db.SaveChanges(); } catch (DbUpdateConcurrencyException) { ModelState.AddModelError("", "Sản phẩm đã thay đổi (có thể vừa có đơn hàng). Mở lại trang để lấy tồn kho mới."); return View("Edit", input); }
            TempData["Message"] = "Đã lưu sản phẩm."; return RedirectToAction(nameof(Products));
        }
        [HttpGet("Admin/ShopOrders")]
        public IActionResult Orders(string status, int page = 1, string q = null, string from = null, string to = null)
        {
            var model = new AdminOrdersViewModel { Q = q?.Trim(), Status = status, From = from, To = to };
            var query = db.ShopOrders.AsNoTracking();
            if (!string.IsNullOrEmpty(status))
            {
                if (!new[] { "Pending", "Confirmed", "Shipping", "Completed", "Cancelled" }.Contains(status)) ModelState.AddModelError("status", "Trạng thái không hợp lệ.");
                query = query.Where(o => o.Status == status);
            }
            if (!string.IsNullOrEmpty(model.Q))
            {
                if (model.Q.Length > 100) ModelState.AddModelError("q", "Từ khóa tối đa 100 ký tự.");
                int.TryParse(model.Q.TrimStart('#'), out var orderId);
                query = query.Where(o => o.Id == orderId || o.Recipient.Contains(model.Q) || o.Phone.Contains(model.Q));
            }
            DateTime? ParseDay(string value, string key)
            {
                if (string.IsNullOrEmpty(value)) return null;
                if (DateTime.TryParseExact(value, "yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out var day) && day.Year >= 1900 && day.Year < 9999) return day;
                ModelState.AddModelError(key, "Ngày không hợp lệ (năm từ 1900 đến 9998)."); return null;
            }
            var start = ParseDay(from, "from"); var end = ParseDay(to, "to");
            if (start.HasValue && end.HasValue && start > end) ModelState.AddModelError("to", "Đến ngày phải bằng hoặc sau Từ ngày.");
            // The filter uses inclusive Vietnamese calendar days; persisted timestamps are UTC.
            if (start.HasValue) { var utc = start.Value.AddHours(-7); query = query.Where(o => o.CreatedUtc >= utc); }
            if (end.HasValue) { var utc = end.Value.AddDays(1).AddHours(-7); query = query.Where(o => o.CreatedUtc < utc); }
            if (!ModelState.IsValid) query = query.Where(o => false);
            model.Total = query.Count(); model.Pages = Math.Max(1, (int)Math.Ceiling(model.Total / 30d)); model.Page = Math.Clamp(page, 1, model.Pages);
            model.Orders = query.OrderByDescending(o => o.Id).Skip((model.Page - 1) * 30).Take(30).ToList(); return View(model);
        }
        [HttpGet("Admin/ShopOrders/{id:int}")]
        public IActionResult Order(int id, string returnUrl = null) { ViewBag.ReturnUrl = SafeOrdersReturn(returnUrl); var order = db.ShopOrders.AsNoTracking().Include(o => o.Items).Include(o => o.History).FirstOrDefault(o => o.Id == id); return order == null ? NotFound() : View(order); }
        private string SafeOrdersReturn(string url) => Url.IsLocalUrl(url) && (url == "/Admin/ShopOrders" || url.StartsWith("/Admin/ShopOrders?", StringComparison.Ordinal)) ? url : "/Admin/ShopOrders";
        [HttpPost("Admin/ShopOrders/{id:int}/Status")]
        public IActionResult Status(int id, string target, byte[] version, string reason, string returnUrl = null)
        {
            if (!ModelState.IsValid) return BadRequest();
            var message = workflow.Move(id, target, version, reason, int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)), true);
            if (message == null) return NotFound();
            TempData["Message"] = message; return RedirectToAction(nameof(Order), new { id, returnUrl = SafeOrdersReturn(returnUrl) });
        }
    }
}
