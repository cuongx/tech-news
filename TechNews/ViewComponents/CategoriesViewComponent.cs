using TechNews.Services;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace TechNews.Views.ViewComponents
{
    public class CategoriesViewComponent : ViewComponent
    {
        private readonly CategoriesService _categoriesService;
        public CategoriesViewComponent(CategoriesService categoriesService)
        {
            _categoriesService = categoriesService;
        }
        public IViewComponentResult Invoke()
        {
            var categories = _categoriesService.GetCategories();
            return View(categories);
        }
    }
}
