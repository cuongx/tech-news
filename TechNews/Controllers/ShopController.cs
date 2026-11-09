using System;
using System.Collections.Generic;
using System.Linq;
using System.Data;
using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TechNews.Models;
using TechNews.Services;
namespace TechNews.Controllers {
 [AutoValidateAntiforgeryToken]
 public class ShopController:Controller {
  private readonly BLOGDBContext db;
  private readonly ShoppingCartStore store;
  private readonly OrderWorkflow workflow;
  public ShopController(BLOGDBContext db, ShoppingCartStore store, OrderWorkflow workflow){this.db=db;this.store=store;this.workflow=workflow;}
  private int Actor=>int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
  private Dictionary<int,int> ReadCart()=>store.Read();
  private void SaveCart(Dictionary<int,int> cart)=>store.Save(cart);
  private CartViewModel CartModel(){
   var cart=ReadCart();var ids=cart.Keys.ToList();var products=db.Products.AsNoTracking().Where(p=>ids.Contains(p.Id)).ToDictionary(p=>p.Id);
   return new CartViewModel{Lines=cart.OrderBy(x=>x.Key).Select(x=>new CartLine{Product=products.TryGetValue(x.Key,out var p)?p:new Product{Id=x.Key,Name="Sản phẩm không còn bán",IsActive=false},Quantity=x.Value,PreviousPrice=store.PreviousPrice(x.Key)}).ToList()};
  }
  private IActionResult CartResult(bool success,string message){
   if(Request.Headers["Accept"].ToString().Contains("application/json"))return StatusCode(success?200:400,new{success,message,count=store.Count});
   TempData["Message"]=message;return RedirectToAction(nameof(Cart));
  }
  [HttpGet("Shop")]
  public IActionResult Index(string q,string category,int page=1){
   var query=db.Products.AsNoTracking().Where(p=>p.IsActive);
   if(!string.IsNullOrWhiteSpace(q))query=query.Where(p=>p.Name.Contains(q));
   if(!string.IsNullOrWhiteSpace(category))query=query.Where(p=>p.Category==category);
   ViewBag.Categories=db.Products.Where(p=>p.IsActive).Select(p=>p.Category).Distinct().OrderBy(x=>x).ToList();
   ViewBag.Q=q;ViewBag.Category=category;ViewBag.Pages=Math.Max(1,(int)Math.Ceiling(query.Count()/12d));ViewBag.Page=Math.Clamp(page,1,(int)ViewBag.Pages);
   return View(query.OrderByDescending(p=>p.Id).Skip(((int)ViewBag.Page-1)*12).Take(12).ToList());
  }
  [HttpGet("Shop/Product/{id:int}")]
  public IActionResult Details(int id){var p=db.Products.AsNoTracking().FirstOrDefault(x=>x.Id==id&&x.IsActive);if(p==null)return NotFound();ViewBag.RelatedProducts=db.Products.AsNoTracking().Where(x=>x.IsActive&&x.Id!=id).OrderByDescending(x=>x.Category==p.Category).ThenByDescending(x=>x.Id).Take(3).ToList();return View(p);}
  [HttpGet("Shop/Cart"),ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)] public IActionResult Cart()=>View(CartModel());
  [HttpGet("Shop/Cart/Content"),ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)] public IActionResult CartContent()=>PartialView("_CartContent",CartModel());
  [HttpGet("Shop/Cart/Summary"),ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)] public IActionResult CartSummary()=>Json(new{count=store.Count});
  [HttpPost("Shop/Cart/Add/{id:int}")]
  public IActionResult Add(int id,int quantity=1){
   if(!ModelState.IsValid)return CartResult(false,"Số lượng không hợp lệ.");
   var p=db.Products.AsNoTracking().FirstOrDefault(x=>x.Id==id&&x.IsActive);if(p==null)return CartResult(false,"Sản phẩm không còn được bán.");
   var cart=ReadCart();cart.TryGetValue(id,out var current);
   if(quantity<1||quantity>99||current+quantity>Math.Min(99,p.Stock))return CartResult(false,"Số lượng vượt tồn kho hoặc giới hạn 99 sản phẩm.");
   if(!cart.ContainsKey(id)&&cart.Count>=50)return CartResult(false,"Giỏ hàng tối đa 50 loại sản phẩm.");
   // Keep the old price for an existing line so a price change is still disclosed in the cart.
   if(!cart.ContainsKey(id))store.RememberPrice(id,p.Price);
   cart[id]=current+quantity;SaveCart(cart);return CartResult(true,"Đã thêm sản phẩm vào giỏ hàng.");
  }
  [HttpPost("Shop/Cart/Update/{id:int}")]
  public IActionResult Update(int id,int quantity){
   if(!ModelState.IsValid)return CartResult(false,"Số lượng không hợp lệ.");
   var cart=ReadCart();if(!cart.ContainsKey(id))return CartResult(false,"Sản phẩm đã được xóa khỏi giỏ.");
   if(quantity==0){cart.Remove(id);SaveCart(cart);return CartResult(true,"Đã xóa sản phẩm khỏi giỏ.");}
   var p=db.Products.AsNoTracking().FirstOrDefault(x=>x.Id==id&&x.IsActive);
   if(p==null||quantity<1||quantity>Math.Min(99,p.Stock))return CartResult(false,"Số lượng không hợp lệ hoặc vượt tồn kho hiện tại.");
   cart[id]=quantity;store.RememberPrice(id,p.Price);SaveCart(cart);return CartResult(true,"Đã cập nhật giỏ hàng.");
  }
  [Authorize,HttpGet("Shop/Checkout")]
  public IActionResult Checkout(){
   var cart=CartModel();if(cart.Lines.Count==0)return RedirectToAction(nameof(Cart));if(cart.HasIssues){TempData["Message"]="Vui lòng kiểm tra thay đổi giá hoặc tồn kho trong giỏ trước khi đặt hàng.";return RedirectToAction(nameof(Cart));}ViewBag.Cart=cart;
   var token=HttpContext.Session.GetString("CheckoutToken");if(token==null){token=Guid.NewGuid().ToString();HttpContext.Session.SetString("CheckoutToken",token);}
   HttpContext.Session.SetString("CheckoutPrices",JsonSerializer.Serialize(cart.Lines.ToDictionary(x=>x.Product.Id,x=>x.Product.Price)));
   return View(new CheckoutInput{Token=Guid.Parse(token),Recipient=db.Users.Find(Actor)?.UserName});
  }
  [Authorize,HttpPost("Shop/Checkout")]
  public IActionResult Checkout(CheckoutInput input){
   var existing=db.ShopOrders.AsNoTracking().FirstOrDefault(o=>o.UserId==Actor&&o.CheckoutToken==input.Token);
   if(existing!=null)return RedirectToAction(nameof(Order),new{id=existing.Id});
   if(input.Token==Guid.Empty||HttpContext.Session.GetString("CheckoutToken")!=input.Token.ToString())return BadRequest("Phiên đặt hàng đã thay đổi. Vui lòng mở lại trang thanh toán.");
   ViewBag.Cart=CartModel();if(!ModelState.IsValid)return View(input);
   var cart=ReadCart();if(cart.Count==0)return RedirectToAction(nameof(Cart));
   try{
    using var tx=db.Database.BeginTransaction(IsolationLevel.Serializable);
    var ids=cart.Keys.ToList();var products=db.Products.Where(p=>ids.Contains(p.Id)).OrderBy(p=>p.Id).ToList();
    if(products.Count!=cart.Count||products.Any(p=>!p.IsActive||cart[p.Id]<1||cart[p.Id]>99||p.Stock<cart[p.Id])){ModelState.AddModelError("","Tồn kho đã thay đổi. Hãy cập nhật giỏ hàng trước khi đặt.");return View(input);}
    var prices=JsonSerializer.Deserialize<Dictionary<int,decimal>>(HttpContext.Session.GetString("CheckoutPrices")??"{}");
    if(products.Any(p=>!prices.TryGetValue(p.Id,out var price)||price!=p.Price)){
     HttpContext.Session.SetString("CheckoutPrices",JsonSerializer.Serialize(products.ToDictionary(p=>p.Id,p=>p.Price)));
     ViewBag.Cart=CartModel();ModelState.AddModelError("","Giá sản phẩm vừa thay đổi. Kiểm tra tổng tiền mới rồi xác nhận lại.");return View(input);
    }
    var order=new ShopOrder{UserId=Actor,CheckoutToken=input.Token,Recipient=input.Recipient.Trim(),Phone=input.Phone.Trim(),Address=input.Address.Trim(),Note=input.Note?.Trim()};
    foreach(var p in products){var qty=cart[p.Id];p.Stock-=qty;order.Items.Add(new ShopOrderItem{ProductId=p.Id,ProductName=p.Name,UnitPrice=p.Price,Quantity=qty});}
    order.History.Add(new ShopOrderEvent{Status="Pending",ActorRole="Customer",ActorId=Actor,CreatedUtc=order.CreatedUtc});
    order.Total=order.Items.Sum(i=>i.UnitPrice*i.Quantity);db.ShopOrders.Add(order);db.SaveChanges();tx.Commit();
    SaveCart(new Dictionary<int,int>());TempData["OrderPlaced"]=order.Id;TempData["Message"]="Đặt hàng thành công. Thanh toán khi nhận hàng (COD).";return RedirectToAction(nameof(Order),new{id=order.Id});
   }catch(Exception ex) when(ex is DbUpdateException || CommerceConflicts.IsRetryable(ex)){db.ChangeTracker.Clear();ViewBag.Cart=CartModel();ModelState.AddModelError("","Dữ liệu vừa thay đổi. Vui lòng kiểm tra đơn hàng và thử lại.");return View(input);}
  }
  [Authorize,HttpPost("Shop/Orders/{id:int}/Cancel")]
  public IActionResult Cancel(int id,byte[] version,string reason){
   if(!ModelState.IsValid)return BadRequest();
   var message=workflow.Move(id,"Cancelled",version,reason,Actor,false);
   if(message==null)return NotFound();
   TempData["Message"]=message;return RedirectToAction(nameof(Order),new{id});
  }
  [Authorize,HttpGet("Shop/Orders")]
  public IActionResult Orders(string status,int page=1){
   var query=db.ShopOrders.AsNoTracking().Where(o=>o.UserId==Actor);
   if(!string.IsNullOrEmpty(status))query=query.Where(o=>o.Status==status);
   const int pageSize=20;
   ViewBag.Status=status;ViewBag.Total=query.Count();
   ViewBag.Pages=Math.Max(1,(int)Math.Ceiling((int)ViewBag.Total/(double)pageSize));
   ViewBag.Page=Math.Clamp(page,1,(int)ViewBag.Pages);
   return View(query.OrderByDescending(o=>o.Id).Skip(((int)ViewBag.Page-1)*pageSize).Take(pageSize).ToList());
  }
  [Authorize,HttpGet("Shop/Orders/{id:int}")]
  public IActionResult Order(int id){var o=db.ShopOrders.AsNoTracking().Include(o=>o.Items).Include(o=>o.History).FirstOrDefault(o=>o.Id==id&&o.UserId==Actor);return o==null?NotFound():View(o);}
 }
}
