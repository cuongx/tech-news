using BlogWebsite.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace BlogWebsite.Services
{
    public class CategoriesService
    {
        private readonly BLOGDBContext _dbContext;
        public CategoriesService(BLOGDBContext dbContext)
        {
            _dbContext = dbContext;
        }

        public List<Category> GetCategories()
        {
            var categories = _dbContext.Categories.OrderBy(c => c.DisplayOrder).ThenBy(c => c.Id).ToList();
            return categories;
        }

        public Category DetailsCategory(int id)
        {
            var category = _dbContext.Categories.Single(c => c.Id == id);
            return category;
        }

        public void CreateCategory(Category category)
        {
            _dbContext.Add(category);
            _dbContext.SaveChanges();
        }

        public void UpdateCategory(Category category)
        {
            var existing = _dbContext.Categories.Find(category.Id);
            existing.CategoryName = category.CategoryName;
            existing.CategoryDescription = category.CategoryDescription;
            existing.ShowOnMenu = category.ShowOnMenu;
            existing.DisplayOrder = category.DisplayOrder;
            _dbContext.SaveChanges();
        }

        public bool HasArticles(int id) => _dbContext.Articles.Any(a => a.CategoryId == id);
        public void DeleteCategory(int id)
        {
            var category = _dbContext.Categories.Find(id);
            if (category == null) return;
            _dbContext.Categories.Remove(category);
            _dbContext.SaveChanges();
        }

        public int GetCategoryId(string name)
        {
            var category = _dbContext.Categories.Single(c => c.CategoryName.Replace(" ", "-") == name);
            return category.Id;
        }
    }
}
