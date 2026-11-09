using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using Microsoft.EntityFrameworkCore;
namespace TechNews.Models {
 public class Product {
  public int Id {get;set;}
  [Required(ErrorMessage="Nhập tên sản phẩm."),StringLength(160,ErrorMessage="Tên sản phẩm tối đa 160 ký tự.")] public string Name {get;set;}
  [Required(ErrorMessage="Nhập danh mục sản phẩm."),StringLength(80,ErrorMessage="Danh mục tối đa 80 ký tự.")] public string Category {get;set;}
  [StringLength(4000)] public string Description {get;set;}
  [StringLength(500)] public string ImageUrl {get;set;}
  [Column(TypeName="decimal(18,0)"),Range(1000,1000000000,ErrorMessage="Giá bán phải từ 1.000 đến 1.000.000.000 đồng.")] public decimal Price {get;set;}
  [Range(0,1000000,ErrorMessage="Tồn kho phải từ 0 đến 1.000.000.")] public int Stock {get;set;}
  public bool IsActive {get;set;}=true;
  [Timestamp] public byte[] Version {get;set;}
 }
 public class ShopOrder {
  public int Id {get;set;} public int UserId {get;set;} public User User {get;set;}
  public Guid CheckoutToken {get;set;}
  [Required,StringLength(100)] public string Recipient {get;set;}
  [Required,StringLength(20)] public string Phone {get;set;}
  [Required,StringLength(500)] public string Address {get;set;}
  [StringLength(1000)] public string Note {get;set;}
  [Required,StringLength(20)] public string Status {get;set;}="Pending";
  public DateTime CreatedUtc {get;set;}=DateTime.UtcNow;
  [Column(TypeName="decimal(18,0)")] public decimal Total {get;set;}
  [Timestamp] public byte[] Version {get;set;}
  public List<ShopOrderEvent> History {get;set;}=new List<ShopOrderEvent>();
  public List<ShopOrderItem> Items {get;set;}=new List<ShopOrderItem>();
 }
 public class ShopOrderEvent {
  public int Id {get;set;} public int ShopOrderId {get;set;}
  [Required,StringLength(20)] public string Status {get;set;}
  [Required,StringLength(20)] public string ActorRole {get;set;}
  public int? ActorId {get;set;}
  [StringLength(500)] public string Reason {get;set;}
  public DateTime CreatedUtc {get;set;}=DateTime.UtcNow;
 }
 public class ShopOrderItem {
  public int Id {get;set;} public int ShopOrderId {get;set;} public int ProductId {get;set;} public Product Product {get;set;}
  [Required,StringLength(160)] public string ProductName {get;set;}
  public int Quantity {get;set;}
  [Column(TypeName="decimal(18,0)")] public decimal UnitPrice {get;set;}
 }
 public class CheckoutInput {
  public Guid Token {get;set;}
  [Required(ErrorMessage="Nhập tên người nhận."),StringLength(100)] public string Recipient {get;set;}
  [Required,StringLength(20),RegularExpression(@"\+?[0-9][0-9 .-]{8,18}[0-9]",ErrorMessage="Số điện thoại không hợp lệ.")] public string Phone {get;set;}
  [Required(ErrorMessage="Nhập địa chỉ giao hàng."),StringLength(500)] public string Address {get;set;}
  [StringLength(1000)] public string Note {get;set;}
 }
 public class CartLine {public Product Product {get;set;} public int Quantity {get;set;} public decimal? PreviousPrice {get;set;} public bool PriceChanged=>PreviousPrice.HasValue&&PreviousPrice.Value!=Product.Price; public bool Unavailable=>!Product.IsActive||Quantity>Product.Stock||Product.Stock<1; public decimal Total=>Product.Price*Quantity;}
 public class CartViewModel {public List<CartLine> Lines {get;set;}=new List<CartLine>(); public decimal Total=>Lines.Sum(x=>x.Total); public int Count=>Lines.Sum(x=>x.Quantity); public bool HasIssues=>Lines.Any(x=>x.Unavailable||x.PriceChanged);}
 public static class OrderStates {
  public static string Label(string s)=>s switch {"Pending"=>"Chờ xác nhận","Confirmed"=>"Đã xác nhận","Shipping"=>"Đang giao","Completed"=>"Đã giao / đã thu tiền","Cancelled"=>"Đã hủy",_=>s};
  public static bool CanMove(string a,string b)=>(a=="Pending"&&(b=="Confirmed"||b=="Cancelled"))||(a=="Confirmed"&&(b=="Shipping"||b=="Cancelled"))||(a=="Shipping"&&b=="Completed");
 }
 public partial class BLOGDBContext {
  public DbSet<ShopOrderEvent> ShopOrderEvents {get;set;}
  public DbSet<Product> Products {get;set;} public DbSet<ShopOrder> ShopOrders {get;set;} public DbSet<ShopOrderItem> ShopOrderItems {get;set;}
 }
}
