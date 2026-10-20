# TechNews

Website tin tức công nghệ viết bằng ASP.NET Core MVC và SQL Server.
Giao diện đọc tin tham khảo cách tổ chức nội dung của trang Công nghệ Znews,
sử dụng thương hiệu và tài nguyên giao diện TechNews.

## Chức năng

- Trang chủ tin chính, tin mới, đọc nhiều và các khối chuyên mục.
- Năm chuyên mục công nghệ, tìm kiếm, phân trang, đọc bài và đánh dấu hữu ích.
- Đăng nhập, quản lý bài viết, ảnh, chuyên mục, người viết và tin nổi bật.
- Bật/tắt chuyên mục trên menu, điều chỉnh thứ tự và trạng thái bài viết.
- Giao diện responsive cho máy tính và điện thoại.

## Công nghệ

- .NET 8, ASP.NET Core MVC / Razor.
- Entity Framework Core 5.0.17 và SQL Server.
- Bootstrap, jQuery, Summernote.
- PagedList / PagedList.Mvc.

## Chạy trên máy

Yêu cầu .NET 8 SDK (hoặc SDK mới hơn hỗ trợ target .NET 8), SQL Server
và SSMS hoặc `sqlcmd`.

```powershell
git clone https://github.com/cuongx/tech-news.git
cd tech-news
dotnet restore BlogWebsite.sln
dotnet build BlogWebsite.sln --no-restore
```

### Database

Nếu máy đã có BLOGDB của project, giữ database đó và bỏ qua bước tạo schema.
Với database mới:

```powershell
sqlcmd -S localhost -E -C -b -f 65001 -i Database.sql
```

`Database.sql` tạo schema và 5 chuyên mục, không chứa tài khoản hay dữ liệu
cá nhân. Script dừng nếu các bảng ứng dụng đã tồn tại, không xóa dữ liệu.

Tạo tài khoản quản trị dành riêng cho máy phát triển trong SSMS. Thay các
giá trị bên dưới trước khi chạy; không commit mật khẩu thật:

```sql
USE BLOGDB;
INSERT dbo.[user](user_name,user_email,user_login,user_password,user_role)
VALUES (N'Tên của bạn',N'email@example.com',N'ten_dang_nhap',
        N'MAT_KHAU_RIENG_CHO_MAY_PHAT_TRIEN',N'Admin');
```

Sau khi có tài khoản, có thể thêm dữ liệu mẫu:

```powershell
sqlcmd -S localhost -E -C -d BLOGDB -b -f 65001 -i SeedTechnology.sql
sqlcmd -S localhost -E -C -d BLOGDB -b -f 65001 -i ImportZnewsBriefs.sql
```

`SeedTechnology.sql` chứa bài kiến thức mẫu do TechNews biên soạn.
`ImportZnewsBriefs.sql` chứa 5 bản tóm tắt được chuẩn bị ngày 21/10/2026,
giữ ngày đăng nguồn, kèm liên kết bài gốc và dùng ảnh minh họa TechNews.
Script bỏ qua bài đã nhập; không phải công cụ tự động lấy tin mới.

`UpdateTechnologyCategories.sql` là script hỗ trợ database cũ chưa có
các cột hiển thị và thứ tự chuyên mục; schema mới đã có các cột này.

### Kết nối và khởi động

Kết nối mặc định dùng Windows Authentication với `localhost`, database
`BLOGDB`. Để đổi SQL Server mà không sửa hoặc commit cấu hình riêng:

```powershell
$env:ConnectionStrings__BlogDatabase = 'Server=TEN_SQL_SERVER;Database=BLOGDB;Trusted_Connection=True;TrustServerCertificate=True;'
dotnet run --project BlogWebsite --no-launch-profile --urls http://localhost:5199
```

- Website: `http://localhost:5199`
- Đăng nhập: `http://localhost:5199/Admin/Login`
- Bài viết: `/Admin/Articles`
- Chuyên mục: `/Admin/Categories`
- Tin nổi bật: `/Admin/BreakingNews`

Có thể mở `BlogWebsite.sln` trong Visual Studio và chạy project `BlogWebsite`.
Tài khoản trên máy phát triển hiện có không được đưa vào repository.

## Cấu trúc

```text
BlogWebsite/
  Controllers/       Luồng đọc tin và quản trị
  Models/            Entity, DbContext và view model
  Services/          Truy vấn và xử lý dữ liệu
  Views/             Razor views
  wwwroot/           CSS, JavaScript, hình ảnh và thư viện
Database.sql         Schema sạch cho máy mới
SeedTechnology.sql   Bài kiến thức mẫu
ImportZnewsBriefs.sql Bản tóm tắt có liên kết nguồn
```

## Giới hạn hiện tại

Đây là project demo. Cơ chế tài khoản hiện tại lưu mật khẩu theo cách cũ,
chưa sử dụng password hashing. Cần nâng cấp xác thực trước khi triển khai
dịch vụ công khai. PagedList cũ còn phát sinh cảnh báo tương thích NuGet;
các thư viện chưa được nâng cấp trong lần chuẩn bị repository này.

Giữ các thông báo bản quyền và license của thư viện trong `wwwroot/vendor`
và `wwwroot/lib`. Không đưa bản sao database thật, khóa riêng, cấu hình máy,
thư mục `bin`, `obj`, `.vs`, bản backup hoặc bản chạy thử vào Git.
