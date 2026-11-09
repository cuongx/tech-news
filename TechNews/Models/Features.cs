using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;
namespace TechNews.Models
{
    public partial class Article {
        [StringLength(20)] public string EditorialState {get;set;} = "Draft";
        public DateTime? ScheduledUtc {get;set;}
        [NotMapped, StringLength(600)] public string TagsText {get;set;}
    }
    public class SavedArticle { public int UserId {get;set;} public int ArticleId {get;set;} public DateTime CreatedUtc {get;set;} public Article Article {get;set;} }
    public class Comment {
        public int Id {get;set;} public int UserId {get;set;} public int ArticleId {get;set;}
        [Required,StringLength(2000)] public string Body {get;set;}
        [Required,StringLength(20)] public string Status {get;set;} = "Pending";
        public DateTime CreatedUtc {get;set;} public int? ModeratorId {get;set;} public DateTime? ModeratedUtc {get;set;}
        public User User {get;set;} public Article Article {get;set;}
    }
    public class EditorialEvent {
        public int Id {get;set;} public int ArticleId {get;set;} public int? ActorId {get;set;}
        [Required,StringLength(20)] public string FromState {get;set;}
        [Required,StringLength(20)] public string ToState {get;set;}
        [StringLength(1000)] public string Note {get;set;} public DateTime CreatedUtc {get;set;}
    }
    public class Tag { public int Id {get;set;} [Required,StringLength(60)] public string Name {get;set;} }
    public class ArticleTag { public int ArticleId {get;set;} public int TagId {get;set;} public Tag Tag {get;set;} public Article Article {get;set;} }
    public class Asset {
        public int Id {get;set;} public int OwnerId {get;set;} [StringLength(100)] public string Url {get;set;}
        [StringLength(255)] public string FileName {get;set;} public long Size {get;set;} public DateTime CreatedUtc {get;set;}
    }
    public class DailyView { public int ArticleId {get;set;} [Column(TypeName="date")] public DateTime Day {get;set;} public int Views {get;set;} }
    public class SearchViewModel {
        public string Q {get;set;} public int? CategoryId {get;set;} public int? TagId {get;set;} public DateTime? From {get;set;} public DateTime? To {get;set;}
        public int Page {get;set;} public int Pages {get;set;} public int Total {get;set;}
        public List<Article> Articles {get;set;} public List<Category> Categories {get;set;} public List<Tag> Tags {get;set;}
    }
    public class DashboardViewModel {
        public DateTime From {get;set;} public DateTime To {get;set;}
        public Dictionary<string,int> States {get;set;} public Dictionary<string,int> Categories {get;set;}
        public int TotalViews {get;set;} public int PeriodViews {get;set;} public List<DailyView> Days {get;set;}
    }
    public partial class BLOGDBContext {
        public DbSet<SavedArticle> SavedArticles {get;set;}
        public DbSet<Comment> Comments {get;set;}
        public DbSet<EditorialEvent> EditorialEvents {get;set;}
        public DbSet<Tag> Tags {get;set;}
        public DbSet<ArticleTag> ArticleTags {get;set;}
        public DbSet<Asset> Assets {get;set;}
        public DbSet<DailyView> DailyViews {get;set;}
        partial void OnModelCreatingPartial(ModelBuilder modelBuilder) {
            modelBuilder.Entity<SavedArticle>().HasKey(x=>new{x.UserId,x.ArticleId});
            modelBuilder.Entity<ArticleTag>().HasKey(x=>new{x.ArticleId,x.TagId});
            modelBuilder.Entity<DailyView>().HasKey(x=>new{x.ArticleId,x.Day});
            modelBuilder.Entity<Tag>().HasIndex(x=>x.Name).IsUnique();
            modelBuilder.Entity<Comment>().HasOne(x=>x.User).WithMany().HasForeignKey(x=>x.UserId).OnDelete(DeleteBehavior.Restrict);
        }
    }
}
