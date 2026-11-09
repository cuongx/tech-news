using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TechNews.Models;
namespace TechNews.ViewComponents
{
    public class HomeProductsViewComponent : ViewComponent
    {
        private readonly BLOGDBContext db;
        public HomeProductsViewComponent(BLOGDBContext db) { this.db = db; }
        public async Task<IViewComponentResult> InvokeAsync()
        {
            var products = await db.Products.AsNoTracking().Where(p => p.IsActive)
                .OrderByDescending(p => p.Id).Take(12).ToListAsync();
            if (products.Count == 0)
            {
                products.Add(new Product { Name = "Điện thoại", Category = "Điện thoại", ImageUrl = "/images/products/phone.svg" });
                products.Add(new Product { Name = "Tai nghe AirPods", Category = "Âm thanh", ImageUrl = "/images/products/earbuds.svg" });
                products.Add(new Product { Name = "Tai nghe chụp tai", Category = "Âm thanh", ImageUrl = "/images/products/headphones.svg" });
                products.Add(new Product { Name = "Laptop", Category = "Máy tính", ImageUrl = "/images/products/laptop.svg" });
                products.Add(new Product { Name = "Đồng hồ thông minh", Category = "Thiết bị đeo", ImageUrl = "/images/products/watch.svg" });
                products.Add(new Product { Name = "Máy tính bảng", Category = "Máy tính bảng", ImageUrl = "/images/products/tablet.svg" });
            }
            return View(products);
        }
    }
}
