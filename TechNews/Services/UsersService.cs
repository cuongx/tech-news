using TechNews.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
namespace TechNews.Services
{
    public class UsersService
    {
        private readonly BLOGDBContext db;
        private readonly PasswordHasher<User> hasher = new PasswordHasher<User>();
        public UsersService(BLOGDBContext db) { this.db = db; }
        public List<User> GetUsers() => db.Users.AsNoTracking().ToList();
        public User DetailsUser(int id) => db.Users.AsNoTracking().SingleOrDefault(u => u.Id == id);
        public string Validate(User user, bool passwordRequired = false, bool profile = false)
        {
            user.UserName = user.UserName?.Trim(); user.UserLogin = user.UserLogin?.Trim(); user.UserEmail = user.UserEmail?.Trim();
            if (string.IsNullOrWhiteSpace(user.UserName) || user.UserName.Length > 50 || string.IsNullOrWhiteSpace(user.UserLogin) || user.UserLogin.Length > 50)
                return "Tên hiển thị và tên đăng nhập bắt buộc, tối đa 50 ký tự.";
            if (string.IsNullOrWhiteSpace(user.UserEmail) || user.UserEmail.Length > 50 || !new EmailAddressAttribute().IsValid(user.UserEmail)) return "Email không hợp lệ.";
            if (db.Users.Any(u => u.Id != user.Id && (u.UserLogin == user.UserLogin || u.UserEmail == user.UserEmail || u.UserLogin == user.UserEmail || u.UserEmail == user.UserLogin)))
                return "Tên đăng nhập hoặc email đã được sử dụng.";
            if (!profile && user.UserRole != "Admin" && user.UserRole != "Editor" && user.UserRole != "Reader") return "Vai trò không hợp lệ.";
            if ((passwordRequired || !string.IsNullOrEmpty(user.UserPassword)) && (user.UserPassword == null || user.UserPassword.Length < 8 || user.UserPassword.Length > 128))
                return "Mật khẩu cần từ 8 đến 128 ký tự.";
            return null;
        }
        public void CreateUser(User user) { user.UserPassword = hasher.HashPassword(user,user.UserPassword); db.Users.Add(user); db.SaveChanges(); }
        public void UpdateUser(User update)
        {
            var user=db.Users.Find(update.Id);
            user.UserName=update.UserName; user.UserEmail=update.UserEmail; user.UserLogin=update.UserLogin; user.UserRole=update.UserRole;
            if (!string.IsNullOrEmpty(update.UserPassword)) user.UserPassword=hasher.HashPassword(user,update.UserPassword);
            db.SaveChanges();
        }
        public void ChangeProfile(User update)
        {
            var user=db.Users.Find(update.Id); user.UserName=update.UserName; user.UserEmail=update.UserEmail; user.UserLogin=update.UserLogin; db.SaveChanges();
        }
        public void ChangePassword(int id,string password) { var user=db.Users.Find(id); user.UserPassword=hasher.HashPassword(user,password); db.SaveChanges(); }
        public string DeleteUser(int id)
        {
            var user=db.Users.Find(id);
            if(user == null) return "Tài khoản không tồn tại.";
            if(db.ShopOrders.Any(o=>o.UserId==id)) return "Tài khoản đã có đơn hàng; không thể xóa.";
            if(db.Articles.Any(a=>a.AuthorId==id)) return "Không thể xóa tác giả đang có bài viết.";
            if(user.UserRole=="Admin" && db.Users.Count(u=>u.UserRole=="Admin")<=1) return "Không thể xóa Admin cuối cùng.";
            if(db.SavedArticles.Any(x=>x.UserId==id)||db.Comments.Any(x=>x.UserId==id||x.ModeratorId==id)||db.EditorialEvents.Any(x=>x.ActorId==id)||db.Assets.Any(x=>x.OwnerId==id)) return "Tài khoản còn dữ liệu liên quan; không thể xóa.";
            db.Users.Remove(user); db.SaveChanges(); return null;
        }
        public bool IsLastAdmin(int id) => db.Users.Any(u=>u.Id==id && u.UserRole=="Admin") && db.Users.Count(u=>u.UserRole=="Admin")<=1;
        private bool Verify(User user,string password)
        {
            if(user==null || string.IsNullOrEmpty(password) || string.IsNullOrEmpty(user.UserPassword)) return false;
            if(user.UserPassword.Length <= 50) return user.UserPassword == password;
            try { return hasher.VerifyHashedPassword(user,user.UserPassword,password) != PasswordVerificationResult.Failed; }
            catch(FormatException) { return false; }
        }
        public User Login(string name,string password)
        {
            if(string.IsNullOrWhiteSpace(name) || string.IsNullOrEmpty(password)) return null;
            name=name.Trim(); var user=db.Users.FirstOrDefault(u=>u.UserLogin==name || u.UserEmail==name);
            if(!Verify(user,password)) return null;
            if(user.UserPassword.Length <= 50) { user.UserPassword=hasher.HashPassword(user,password); db.SaveChanges(); }
            return user;
        }
        public bool CheckPassWord(int id,string password) => Verify(db.Users.Find(id),password);
    }
}
