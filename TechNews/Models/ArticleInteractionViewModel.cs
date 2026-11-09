using System.Collections.Generic;
namespace TechNews.Models {
 public class ArticleInteractionViewModel {
  public int ArticleId {get;set;} public bool Saved {get;set;}
  public List<Comment> Comments {get;set;} public List<Tag> Tags {get;set;} public List<Article> Related {get;set;}
 }
}
