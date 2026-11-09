using System;
using System.Data;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using TechNews.Models;
namespace TechNews.Services
{
    public class EditorialService {
        private readonly BLOGDBContext db;
        public EditorialService(BLOGDBContext db) {this.db=db;}
        public string Transition(int id,int actor,bool admin,string target,string note,DateTime? schedule=null) {
            using var tx=db.Database.BeginTransaction(IsolationLevel.Serializable);
            var a=db.Articles.SingleOrDefault(x=>x.Id==id);
            if(a==null) return "Bài viết không tồn tại.";
            if(!admin && a.AuthorId!=actor) return "Bạn không có quyền xử lý bài này.";
            var state=a.EditorialState;
            bool allowed=target switch {
                "Pending" => state is "Draft" or "Rejected",
                "Approved" => admin && state=="Pending",
                "Rejected" => admin && state=="Pending" && !string.IsNullOrWhiteSpace(note),
                "Published" => admin && state=="Approved",
                "Scheduled" => admin && state=="Approved" && schedule.HasValue && schedule.Value > DateTime.UtcNow,
                "Unpublished" => admin && state=="Published",
                "Draft" => state=="Pending" || (admin && state=="Unpublished"),
                "CancelSchedule" => admin && state=="Scheduled",
                _ => false
            };
            if(!allowed) return "Thao tác không phù hợp trạng thái/quyền, hoặc thiếu lý do/lịch đăng hợp lệ.";
            if(note?.Length > 1000) return "Lý do tối đa 1000 ký tự.";
            if(target=="Pending" && (string.IsNullOrWhiteSpace(a.ArticleTitle)||string.IsNullOrWhiteSpace(a.ArticleContent)||!a.CategoryId.HasValue)) return "Bài gửi duyệt cần tiêu đề, nội dung và chuyên mục.";
            a.EditorialState=target=="CancelSchedule" ? "Approved" : target;
            a.ScheduledUtc=target=="Scheduled"?schedule:null;
            a.ArticleStatus=a.EditorialState=="Published";
            if(a.ArticleStatus==true) a.ArticleDate=DateTime.UtcNow.AddHours(7).Date;
            db.EditorialEvents.Add(new EditorialEvent{ArticleId=id,ActorId=actor,FromState=state,ToState=a.EditorialState,Note=note,CreatedUtc=DateTime.UtcNow});
            db.SaveChanges();tx.Commit();return null;
        }
        public void PublishDue() {
            // One atomic SQL statement claims due articles and records history, including after restart.
            db.Database.ExecuteSqlRaw(@"SET XACT_ABORT ON; BEGIN TRANSACTION; DECLARE @published TABLE(ArticleId int, ActorId int, FromState nvarchar(20), ToState nvarchar(20), Note nvarchar(1000), CreatedUtc datetime2); UPDATE dbo.article SET EditorialState='Published', article_status=1,
article_date=CONVERT(date,DATEADD(hour,7,SYSUTCDATETIME())), ScheduledUtc=NULL
OUTPUT inserted.id, NULL, deleted.EditorialState, inserted.EditorialState, N'Hẹn giờ đăng', SYSUTCDATETIME()
INTO @published(ArticleId,ActorId,FromState,ToState,Note,CreatedUtc)
WHERE EditorialState='Scheduled' AND ScheduledUtc <= SYSUTCDATETIME(); INSERT dbo.EditorialEvents(ArticleId,ActorId,FromState,ToState,Note,CreatedUtc) SELECT * FROM @published; COMMIT;");
        }
    }
    public class PublicationWorker : BackgroundService {
        private readonly IServiceScopeFactory scopes; private readonly ILogger<PublicationWorker> logger;
        public PublicationWorker(IServiceScopeFactory scopes,ILogger<PublicationWorker> logger){this.scopes=scopes;this.logger=logger;}
        protected override async Task ExecuteAsync(CancellationToken stop) {
            while(!stop.IsCancellationRequested) {
                try {using var scope=scopes.CreateScope();scope.ServiceProvider.GetRequiredService<EditorialService>().PublishDue();}
                catch(Exception ex){logger.LogError(ex,"Không thể xử lý lịch đăng; sẽ thử lại.");}
                try {await Task.Delay(TimeSpan.FromSeconds(15),stop);}catch(OperationCanceledException){break;}
            }
        }
    }
}
