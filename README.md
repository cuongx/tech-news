# TechNews

Website tin tức công nghệ viết bằng ASP.NET Core MVC và SQL Server.
Giao diện đọc tin tham khảo cách tổ chức nội dung của trang Công nghệ Znews,
sử dụng thương hiệu và tài nguyên giao diện TechNews.

## Chức năng

- Trang chủ tin chính, tin mới, đọc nhiều và các khối chuyên mục.
- Chuyên mục lấy từ database, tìm kiếm kết hợp, phân trang, đọc bài và đánh dấu hữu ích.
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
dotnet restore TechNews.sln
dotnet build TechNews.sln --no-restore
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
dotnet run --project TechNews --no-launch-profile --urls http://localhost:5199
```

- Website: `http://localhost:5199`
- Đăng nhập: `http://localhost:5199/Admin/Login`
- Bài viết: `/Admin/Articles`
- Chuyên mục: `/Admin/Categories`
- Tin nổi bật: `/Admin/BreakingNews`

Có thể mở `TechNews.sln` trong Visual Studio và chạy project `TechNews`.
Tài khoản trên máy phát triển hiện có không được đưa vào repository.

## Cấu trúc

```text
TechNews/
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

Đây là project demo. Mật khẩu mới được băm; tài khoản cũ chuyển sang mật khẩu
băm khi đăng nhập thành công sau khi áp dụng UpgradeFeatures.sql.
PagedList cũ còn phát sinh cảnh báo tương thích NuGet;
các thư viện chưa được nâng cấp trong lần chuẩn bị repository này.

Giữ các thông báo bản quyền và license của thư viện trong `wwwroot/vendor`
và `wwwroot/lib`. Không đưa bản sao database thật, khóa riêng, cấu hình máy,
thư mục `bin`, `obj`, `.vs`, bản backup hoặc bản chạy thử vào Git.

## Cập nhật chức năng ngày 25/10/2026

Chạy `UpgradeFeatures.sql` trên database đã sao lưu trước khi chạy phiên bản này (bao gồm nâng cấp cột mật khẩu; không cần chạy riêng UpgradeSecurity.sql). Script có thể chạy lại; không xóa dữ liệu cũ. Với máy mới, chạy Database.sql và seed trước, sau đó chạy UpgradeFeatures.sql.

```powershell
sqlcmd -S localhost -E -C -d BLOGDB -b -f 65001 -i UpgradeFeatures.sql
```

- Độc giả: `/Account/Register`, đăng nhập tại `/Admin/Login`, hồ sơ `/Account`, bài đã lưu `/Account/Saved`, bình luận `/Account/Comments`.
- Biên tập: `/Admin/Workflow` để gửi duyệt, xem phản hồi và lịch sử; Admin duyệt/từ chối/xuất bản/gỡ bài/hẹn giờ hoặc hủy lịch. Sửa nội dung đưa bài về Nháp, hủy lịch và yêu cầu duyệt lại. Công tắc hiển thị cũ là thao tác duyệt/xuất bản trực tiếp của Admin, có ghi lịch sử.
- Bình luận chỉ hiển thị khi Admin duyệt tại `/Admin/Comments`; nội dung được mã hóa HTML khi hiển thị.
- Tag: quản lý tại `/Admin/Tags`, nhập tối đa 10 tag trong form bài viết; không xóa tag còn liên kết.
- Tìm kiếm `/Search` kết hợp từ khóa, chuyên mục, tag và ngày; bài liên quan chỉ lấy bài công khai.
- Ảnh: `/Admin/Assets`, giới hạn 5 MB, JPEG/PNG/GIF/WebP; chọn lại ảnh trong form bài. Chỉ chủ sở hữu hoặc Admin xóa được ảnh chưa sử dụng. Thư viện ghi nhận ảnh tải lên từ phiên bản này.
- Thống kê `/Admin/Dashboard`: phân biệt tổng tích lũy và lượt xem trong kỳ. Dữ liệu từng ngày được ghi từ lúc triển khai, không dựng lịch sử giả từ tổng cũ.
- Lịch đăng nhập giờ Việt Nam (UTC+7), lưu UTC. Worker chạy mỗi 15 giây, xử lý lịch quá hạn khi khởi động lại. Ứng dụng cần đang chạy để xuất bản; nếu dừng sẽ đăng khi ứng dụng chạy lại.
- Mật khẩu mới được băm; mật khẩu cũ được chuyển sang dạng băm khi đăng nhập thành công. Không sửa trực tiếp mật khẩu đã băm bằng SQL. Tài khoản đăng ký công khai luôn là Reader.

### Kiểm thử

Các script trong `tests/` chỉ chạy với database bản sao và ba tài khoản thử `qa-admin`, `qa-editor1`, `qa-editor2`. Mật khẩu fixture chỉ dành cho database thử; có thể đặt biến `TEST_PASSWORD`. Không tạo các tài khoản thử trên BLOGDB đang dùng.

```powershell
dotnet build TechNews.sln --no-restore -p:OutputPath=bin/Verification/
powershell -File tests/Run-Verification.ps1 -Database TechNews_Verification_20261025
```

Đã kiểm thử HTTP: quyền sở hữu bài/ảnh; bài nháp/ẩn; CSRF; validation; HTML; phân trang; đăng ký/đổi mật khẩu/đăng xuất; lưu bài không trùng; bình luận chờ duyệt; quy trình duyệt, từ chối, gửi lại, hẹn giờ và gỡ bài; tìm kiếm; dashboard; upload giả ảnh và xóa ảnh đang sử dụng.

Build vẫn có cảnh báo NU1701 do hai gói PagedList cũ. Kiểm thử chức năng không thay thế đo tải hoặc đánh giá bảo mật toàn diện.
## Cửa hàng công nghệ (COD)

- `/Shop`: sản phẩm, tìm kiếm, lọc danh mục và giá VNĐ.
- `/Shop/Cart`: giỏ hàng được bảo vệ bằng cookie HttpOnly, lưu 30 ngày trên cùng trình duyệt; tối đa 50 loại và 99 sản phẩm mỗi loại.
- `/Shop/Checkout`: đăng nhập và nhập thông tin giao hàng; thanh toán khi nhận hàng, phí giao hàng hiện tại là 0 đồng.
- `/Shop/Orders`: lịch sử và chi tiết đơn hàng của tài khoản hiện tại; lọc trạng thái và phân trang 20 đơn/trang, không giới hạn ở 100 đơn gần nhất.
- `/Admin/Products`: Admin nhập tên, danh mục, ảnh, giá, tồn kho; bỏ chọn hiển thị để ngừng bán.
- `/Admin/ShopOrders`: xác nhận, giao, hoàn tất thu COD hoặc hủy trước khi giao. Hủy trả tồn kho đúng một lần.

Chạy `UpgradeCommerce.sql` trên database trong `ConnectionStrings:BlogDatabase` trước khi chạy bản code mới. Script chỉ thêm bảng/index, có thể chạy lại. Ví dụ máy dùng SQL Server localhost và BLOGDB:

```powershell
sqlcmd -S localhost -E -C -b -d BLOGDB -i UpgradeCommerce.sql
dotnet build TechNews/TechNews.csproj
```

Cửa hàng mới chưa có sản phẩm: đăng nhập Admin và vào `/Admin/Products/Create` để nhập giá bán. `SeedCommerceDemo.sql` là dữ liệu minh họa tùy chọn cho demo cục bộ, không tự chạy; mọi sản phẩm mẫu đều có tiền tố `[MẪU]`.

Giá đơn hàng lấy từ database và lưu tại thời điểm mua. Nếu giá thay đổi ở bước thanh toán, khách phải xác nhận tổng mới. Tồn kho và đơn hàng lưu cùng transaction; rowversion chống ghi đè tồn kho và trạng thái cũ; token duy nhất chống tạo trùng đơn. Chỉ chủ đơn đọc được thông tin giao hàng, chỉ Admin quản trị sản phẩm và đơn. Chưa tích hợp thanh toán online, vận chuyển hoặc hoàn tiền sau giao.

Kiểm thử `tests/commerce.cjs` cần server chạy với database riêng tên bắt đầu `TechNews_Verification_`, đã áp dụng các script upgrade và có tài khoản `qa-admin`, `qa-editor1` như bộ kiểm thử hiện tại. Đặt `TEST_DATABASE`, `TEST_URL`, `TEST_PASSWORD` nếu khác mặc định. Test tạo dữ liệu riêng, kiểm tra CSRF, phân quyền, giá, tồn kho, replay, chuyển trạng thái và hai khách mua sản phẩm cuối cùng. Không chạy trên BLOGDB. `tests/commerce-visual.cjs` kiểm tra desktop/mobile qua Edge CDP cổng 9337 và server kiểm thử cổng 5307.

Giỏ hàng: thêm hàng không chuyển trang, badge cập nhật số lượng, trang giỏ có tăng/giảm và xóa, cảnh báo thay đổi giá/tồn kho. Khách thêm hàng trước khi đăng nhập; chỉ đăng nhập khi đặt hàng. Giỏ chưa đồng bộ giữa các thiết bị. Chạy `node tests/cart.cjs` với `TEST_URL` trỏ tới server dùng database kiểm thử riêng để kiểm tra persistence, giá, tồn kho và bảo vệ cookie.

### Lịch sử và hủy đơn hàng
Chạy UpgradeOrderHistory.sql sau UpgradeCommerce.sql trước khi dùng phiên bản này. Lịch sử trạng thái, người thực hiện và lý do hủy được lưu trong ShopOrderEvents cùng giao dịch cập nhật tồn kho. Đơn cũ chỉ ghi nhận trạng thái lúc nâng cấp, không suy diễn lịch sử trước đó. Khách chỉ hủy đơn của mình ở trạng thái Pending/Confirmed; quản trị cũng phải nhập lý do hủy. Các cập nhật kiểm tra rowversion để tránh hủy/hoàn kho trùng. Trang thanh toán có bước kiểm tra thông tin trước khi xác nhận (JavaScript); khi không có JavaScript, dùng biểu mẫu xác nhận trên trang hiện tại.

Kiểm thử tích hợp: trỏ ứng dụng và `TEST_DATABASE` vào cùng database `TechNews_Verification_*`, chạy script nâng cấp trên database đó và đặt `TEST_URL` theo địa chỉ ứng dụng. Chạy `node tests/commerce.cjs`, `node tests/cart.cjs`, `node tests/orders.cjs`. Bộ kiểm thử dùng tài khoản `qa-admin`, `qa-editor1` có sẵn trong dữ liệu kiểm thử và tự tạo khách/sản phẩm/đơn thử. `orders.cjs` kiểm tra quyền sở hữu, CSRF, lý do hủy, phiên bản cũ, hai yêu cầu hủy đồng thời, hoàn kho đúng một lần, lịch sử và giới hạn hủy trước khi giao. Không chạy các bài kiểm thử này trên BLOGDB.

### Quản lý đơn hàng admin (09/11/2026)
- `/Admin/ShopOrders`: tìm theo mã đơn (có hoặc không có #), tên người nhận hoặc số điện thoại; kết hợp trạng thái và khoảng ngày; phân trang 30 đơn/trang.
- Khoảng ngày tính theo giờ Việt Nam, bao gồm cả ngày bắt đầu và kết thúc. Ngày/trạng thái sai hiển thị lỗi, không trả danh sách rộng hơn bộ lọc.
- Trang chi tiết hiển thị thông tin giao hàng, đơn giá/số lượng/thành tiền, COD, lịch sử và thao tác hợp lệ theo trạng thái. Quay lại danh sách giữ nguyên bộ lọc và trang.
- Xác nhận chuyển trạng thái trước khi gửi; hủy yêu cầu lý do. Kiểm tra quyền Admin, CSRF, rowversion và hoàn kho dùng cơ chế hiện có.
- Menu admin có icon và đánh dấu mục đang mở. Font Awesome Free 5.15.4 được lưu cục bộ trong `TechNews/wwwroot/vendor/fontawesome-free`, kèm LICENSE.txt; lấy từ gói npm `@fortawesome/fontawesome-free@5.15.4`.
- Bản cập nhật này không thay đổi bảng/cột hoặc dữ liệu nghiệp vụ; không cần migration SQL mới. Máy mới vẫn cần `UpgradeFeatures.sql`, `UpgradeCommerce.sql`, `UpgradeOrderHistory.sql` như hướng dẫn ở trên.
- Kiểm thử riêng: đặt `TEST_URL` trỏ tới bản chạy thử và `TEST_DATABASE=TechNews_Verification_20261025`, rồi chạy `node tests/admin-orders.cjs`, `node tests/orders.cjs`, `node tests/commerce.cjs`. Không chạy trên BLOGDB.
- Kiểm thử trình duyệt: chạy `admin-orders.cjs` trước để tạo fixture, mở Edge với CDP cổng 9342 rồi chạy `node tests/admin-orders-ui.cjs` từ thư mục lưu ảnh kiểm thử. Script mặc định dùng server 5313, hỗ trợ `TEST_URL`, `TEST_DATABASE`, `TEST_CDP_URL`; ảnh chụp lưu ở thư mục chạy lệnh. Kiểm tra desktop/mobile, icon, giữ bộ lọc, xác nhận thao tác, lý do hủy và lịch sử.

### Giao diện hồ sơ cá nhân
Trang `/Admin/Profile/{id}` dùng bố cục thẻ tài khoản, form thông tin và khu vực đổi mật khẩu riêng; hỗ trợ desktop/tablet/mobile, hoàn tác nội dung, hiện/ẩn mật khẩu và thông báo lỗi ngay trong form. Không thay đổi cấu trúc database, không cần SQL bổ sung.

## Hướng dẫn đồ án
Xem [Hướng dẫn chạy, đọc code và kịch bản demo](docs/HUONG_DAN_DO_AN.md). Giao diện admin dùng nhãn tiếng Việt, màu thao tác thống nhất và hạn chế trang trí. `SeedStorefrontDemo.sql` có sáu sản phẩm mô phỏng với tên/mô tả cụ thể. `UpdateDemoCatalog.sql` cập nhật dữ liệu từ bản seed cũ, không đổi giá, tồn kho hay chi tiết đơn hàng; không thay đổi schema.

### Tài khoản độc giả `/Account`
Trang tài khoản phía khách dùng menu hồ sơ, đơn hàng, bài lưu và bình luận; form lưu/hoàn tác thông tin, đổi mật khẩu có xác nhận và hiện/ẩn mật khẩu. Lỗi đổi mật khẩu hiển thị ngay tại form. CSS/JS nằm trong `account.css` và `account.js`. Không thay đổi database. Khi chạy bằng IIS Express tại cổng 44387, cần build và khởi động lại IIS Express để nhận Razor/controller mới.

### Hoàn thiện danh sách cá nhân và sản phẩm
- `/Account/Saved`, `/Account/Comments`: menu tài khoản, trạng thái trống, ngày giờ, trạng thái duyệt tiếng Việt và xác nhận bỏ lưu/xóa. Bài không công khai không lộ tiêu đề/nội dung trong các danh sách này.
- Form sản phẩm tách thông tin và ảnh; xem trước ảnh, thông báo ảnh lỗi, hướng dẫn giá/tồn kho và lỗi bắt buộc bằng tiếng Việt. Không thêm chức năng upload hoặc thay đổi schema.
- Thông báo chung admin dùng nhãn trung tính “Thông báo”, mã hóa chuỗi khi đưa vào JavaScript; lỗi form hiển thị tại form.
- `tests/account-lists.cjs` bổ sung kiểm tra trạng thái trống, quyền sở hữu, CSRF, HTML trong bình luận, email trùng và dữ liệu sản phẩm không hợp lệ. Chạy cùng quy tắc TEST_URL/TEST_DATABASE và database riêng như các bộ test hiện có.
