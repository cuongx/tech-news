using System;
using System.Linq;
using System.Data;
using Microsoft.EntityFrameworkCore;
using TechNews.Models;
namespace TechNews.Services
{
    public class OrderWorkflow
    {
        private readonly BLOGDBContext db;
        public OrderWorkflow(BLOGDBContext db) { this.db = db; }
        // Null means the order does not exist or is not owned by this customer.
        public string Move(int id, string target, byte[] version, string reason, int actorId, bool admin)
        {
            try
            {
                using var tx = db.Database.BeginTransaction(IsolationLevel.Serializable);
                var order = db.ShopOrders.Include(o => o.Items).FirstOrDefault(o => o.Id == id && (admin || o.UserId == actorId));
                if (order == null) return null;
                if (version == null || !order.Version.SequenceEqual(version)) return "Đơn hàng đã thay đổi. Vui lòng kiểm tra trạng thái mới.";
                if ((!admin && target != "Cancelled") || !OrderStates.CanMove(order.Status, target)) return "Không thể chuyển trạng thái. Chỉ được hủy đơn trước khi giao.";
                reason = reason?.Trim();
                if (target == "Cancelled" && (string.IsNullOrWhiteSpace(reason) || reason.Length > 500)) return "Vui lòng nhập lý do hủy đơn (tối đa 500 ký tự).";
                if (target == "Cancelled")
                {
                    var ids = order.Items.Select(i => i.ProductId).ToList();
                    var products = db.Products.Where(p => ids.Contains(p.Id)).OrderBy(p => p.Id).ToList();
                    foreach (var p in products) p.Stock += order.Items.Where(i => i.ProductId == p.Id).Sum(i => i.Quantity);
                }
                order.Status = target;
                order.History.Add(new ShopOrderEvent { Status = target, ActorRole = admin ? "Admin" : "Customer", ActorId = actorId, Reason = target == "Cancelled" ? reason : null });
                db.SaveChanges(); tx.Commit(); return target == "Cancelled" ? "Đã hủy đơn hàng và hoàn lại tồn kho." : "Đã cập nhật đơn hàng.";
            }
            catch (Exception ex) when (ex is DbUpdateException || CommerceConflicts.IsRetryable(ex))
            {
                db.ChangeTracker.Clear(); return "Dữ liệu vừa thay đổi. Vui lòng tải lại đơn hàng và thử lại.";
            }
        }
    }
}
