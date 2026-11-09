using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using TechNews.Models;
using TechNews.Services;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;

namespace TechNews.Controllers
{
    
    public class AdminUsersController : Controller
    {
        private readonly UsersService _usersService;

        public AdminUsersController(UsersService usersService)
        {
            _usersService = usersService;
        }

        [Authorize(Roles = "Admin")]
        [Route("Admin/Users")]
        public IActionResult Index()
        {
            var users = _usersService.GetUsers();
            return View(users);
        }

        [Authorize]
        [Route("Admin/Profile/{id}")]
        public IActionResult Details(int id)
        {
            int authorId = Int32.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            if(authorId == id)
            {
                var user = _usersService.DetailsUser(id);
            if (user == null || (user.UserRole != "Admin" && user.UserRole != "Editor" && user.UserRole != "Reader")) return NotFound();
            user.UserPassword = null;
                return View(user);
            }

            return Redirect($"/Admin/Profile/{authorId}");
        }

        [Authorize]
        [HttpPost]
        [Route("Admin/Profile/{id}")]
        public IActionResult Details([Bind("Id,UserName,UserEmail,UserLogin")]User updateUser)
        {
            
            int authorId = Int32.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            if(authorId != updateUser.Id) return Forbid();
            var error = _usersService.Validate(updateUser, profile:true);
            if(error != null) ModelState.AddModelError(string.Empty,error);
            if(!ModelState.IsValid) return View(updateUser);
            if(authorId == updateUser.Id)
            {
                TempData["Message"] = "Sửa thông tin thành công";
                _usersService.ChangeProfile(updateUser);
            }
            return Redirect($"/Admin/Profile/{updateUser.Id}");
        }

        [Authorize]
        [HttpPost]
        [Route("Admin/ChangePassword")]
        public IActionResult ChangePassword(int id, string oldPassword, string newPassword)
        {
            int authorId = Int32.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            if(authorId != id) return Forbid();
            if(string.IsNullOrEmpty(newPassword) || newPassword.Length < 8 || newPassword.Length > 128 || !_usersService.CheckPassWord(id,oldPassword))
            { TempData["ProfilePasswordError"]="Mật khẩu hiện tại chưa đúng hoặc mật khẩu mới không đủ 8–128 ký tự."; return Redirect($"/Admin/Profile/{id}"); }
            if(authorId == id && _usersService.CheckPassWord(id, oldPassword))
            {
                TempData["Message"] = "Đổi mật khẩu thành công";
                _usersService.ChangePassword(id, newPassword);
            }
            return Redirect($"/Admin/Profile/{id}");
        }

        [AllowAnonymous]
        [Route("Admin/Login")]
        public IActionResult Login(string returnUrl)
        {
            return View();
        }

        [AllowAnonymous]
        [HttpPost]
        [Route("Admin/Login")]
        public async Task<IActionResult> Login(string name, string password, string returnUrl)
        {
            ViewData["ReturnUrl"] = returnUrl;
            var user = _usersService.Login(name, password);
            if (user == null || (user.UserRole != "Admin" && user.UserRole != "Editor" && user.UserRole != "Reader"))
            {
                ViewData["LoginName"] = name;
                ModelState.AddModelError(string.Empty, "Tên đăng nhập hoặc mật khẩu chưa đúng. Vui lòng thử lại.");
                return View();
            }
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.UserName ?? user.UserLogin ?? "Độc giả"),
                new Claim(ClaimTypes.Role, user.UserRole.ToString())
            };

            var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var claimsPrincipal = new ClaimsPrincipal(claimsIdentity);
            var authProperties = new AuthenticationProperties { };
            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, claimsPrincipal, authProperties);
            TempData["Message"] = "Đăng nhập thành công";
            if (Url.IsLocalUrl(returnUrl)) return LocalRedirect(returnUrl);
            return Redirect(user.UserRole=="Reader"?"/Account":"/Admin/Articles");
        }

        [Authorize]
        [HttpPost, Route("Admin/Logout")]
        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync();
            return Redirect("/Admin/Login");
        }

        [Authorize(Roles = "Admin")]
        [Route("Admin/CreateUser")]
        public IActionResult Create()
        {
            return View();
        }

        [Authorize(Roles = "Admin")]
        [HttpPost]
        [Route("Admin/CreateUser")]
        public IActionResult Create([Bind("UserName,UserEmail,UserLogin,UserPassword,UserRole")] User user)
        {
            var error = _usersService.Validate(user, true);
            if (error != null) ModelState.AddModelError(string.Empty,error);
            if (!ModelState.IsValid) return View(user);
            _usersService.CreateUser(user);
            TempData["Message"] = "Thêm người viết thành công";
            return Redirect("/Admin/Users");
        }


        [Authorize(Roles = "Admin")]
        [Route("Admin/EditUser/{id}")]
        public IActionResult Edit(int id)
        {
            var user = _usersService.DetailsUser(id);
            if (user == null || (user.UserRole != "Admin" && user.UserRole != "Editor" && user.UserRole != "Reader")) return NotFound();
            user.UserPassword = null;
            return View(user);
        }

        [Authorize(Roles = "Admin")]
        [HttpPost]
        [Route("Admin/EditUser/{id}")]
        public IActionResult Edit(int id, [Bind("Id,UserName,UserEmail,UserLogin,UserPassword,UserRole")] User updateUser)
        {

            if (id != updateUser.Id) return BadRequest();
            if (_usersService.DetailsUser(id) == null) return NotFound();
            var error = _usersService.Validate(updateUser);
            if (_usersService.IsLastAdmin(id) && updateUser.UserRole != "Admin") error = "Không thể hạ quyền Admin cuối cùng.";
            if (error != null) ModelState.AddModelError(string.Empty,error);
            if (!ModelState.IsValid) { updateUser.UserPassword = null; ModelState.Remove("UserPassword"); return View(updateUser); }
            _usersService.UpdateUser(updateUser);
            TempData["Message"] = "Sửa thông tin thành công";
            return Redirect("/Admin/Users");
        }

        [Authorize(Roles = "Admin")]
        [HttpPost, Route("Admin/DeleteUser/{id}")]
        public IActionResult Delete(int id)
        {
            if (User.FindFirstValue(ClaimTypes.NameIdentifier) == id.ToString()) { TempData["Message"]="Không thể tự xóa tài khoản đang đăng nhập."; return Redirect("/Admin/Users"); }
            var error = _usersService.DeleteUser(id);
            if (error != null) { TempData["Message"] = error; return Redirect("/Admin/Users"); }
            TempData["Message"] = "Xoá thành công";
            return Redirect("/Admin/Users");
        }

    }
}
