using System.Collections.Generic;
using PagedList;

namespace BlogWebsite.Models
{
    public class NewsHomeViewModel
    {
        public IPagedList<Article> Articles { get; set; }
        public List<Article> Headlines { get; set; } = new List<Article>();
        public List<NewsTopicSection> Sections { get; set; } = new List<NewsTopicSection>();
        public string Query { get; set; }
    }
    public class NewsTopicSection
    {
        public Category Category { get; set; }
        public List<Article> Articles { get; set; }
    }
}
