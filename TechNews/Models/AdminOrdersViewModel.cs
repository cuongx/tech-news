using System.Collections.Generic;

namespace TechNews.Models
{
    public class AdminOrdersViewModel
    {
        public List<ShopOrder> Orders { get; set; } = new List<ShopOrder>();
        public string Q { get; set; }
        public string Status { get; set; }
        public string From { get; set; }
        public string To { get; set; }
        public int Page { get; set; }
        public int Pages { get; set; }
        public int Total { get; set; }
    }
}
