using System.Linq;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using BlogWebsite.Models;
using BlogWebsite.Services;
namespace BlogWebsite.Controllers
{
    [Authorize(Roles = "Admin")]
    public class AdminCategoriesController : Controller
    {
        private readonly CategoriesService _categoriesService;
        public AdminCategoriesController(CategoriesService categoriesService) { _categoriesService = categoriesService; }
        [Route("Admin/Categories")]
        public IActionResult Index() => View(_categoriesService.GetCategories());
        [Route("Admin/EditCategory/{id}")]
        public IActionResult Edit(int id)
        {
            var category = _categoriesService.GetCategories().FirstOrDefault(c => c.Id == id);
            if (category == null) return NotFound();
            return View(category);
        }
        [HttpPost, ValidateAntiForgeryToken]
        [Route("Admin/EditCategory/{id}")]
        public IActionResult Edit(int id, [Bind("Id,CategoryName,CategoryDescription,ShowOnMenu,DisplayOrder")] Category category)
        {
            if (id != category.Id) return BadRequest();
            if (!_categoriesService.GetCategories().Any(c => c.Id == id)) return NotFound();
            ValidateCategory(category);
            if (!ModelState.IsValid) return View(category);
            _categoriesService.UpdateCategory(category);
            TempData["Message"] = "Đã cập nhật chuyên mục và menu website.";
            return RedirectToAction(nameof(Index));
        }
        [Route("Admin/CreateCategory")]
        public IActionResult Create() => View(new Category());
        [HttpPost, ValidateAntiForgeryToken]
        [Route("Admin/CreateCategory")]
        public IActionResult Create([Bind("CategoryName,CategoryDescription,ShowOnMenu,DisplayOrder")] Category category)
        {
            ValidateCategory(category);
            if (!ModelState.IsValid) return View(category);
            _categoriesService.CreateCategory(category);
            TempData["Message"] = "Đã thêm chuyên mục.";
            return RedirectToAction(nameof(Index));
        }
        [HttpPost, ValidateAntiForgeryToken]
        [Route("Admin/DeleteCategory/{id}")]
        public IActionResult Delete(int id)
        {
            if (!_categoriesService.GetCategories().Any(c => c.Id == id)) return NotFound();
            if (_categoriesService.HasArticles(id))
            {
                TempData["Message"] = "Chuyên mục còn bài viết. Hãy chuyển bài sang chuyên mục khác hoặc ẩn chuyên mục trên menu.";
                return RedirectToAction(nameof(Index));
            }
            _categoriesService.DeleteCategory(id);
            TempData["Message"] = "Đã xóa chuyên mục trống.";
            return RedirectToAction(nameof(Index));
        }
        private void ValidateCategory(Category category)
        {
            category.CategoryName = category.CategoryName?.Trim();
            category.CategoryDescription = category.CategoryDescription?.Trim();
            if (string.IsNullOrWhiteSpace(category.CategoryName))
                ModelState.AddModelError(nameof(category.CategoryName), "Vui lòng nhập tên chuyên mục.");
            else if (_categoriesService.GetCategories().Any(c => c.Id != category.Id && string.Equals(c.CategoryName, category.CategoryName, System.StringComparison.OrdinalIgnoreCase)))
                ModelState.AddModelError(nameof(category.CategoryName), "Tên chuyên mục đã tồn tại.");
        }
    }
}
