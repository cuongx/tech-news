# Hướng dẫn chạy và trình bày TechNews

## Phạm vi

TechNews là website tin tức công nghệ có cửa hàng mô phỏng thanh toán khi nhận hàng (COD). Phần tin tức là nội dung chính; cửa hàng minh họa giỏ hàng, đặt hàng, quản lý trạng thái và tồn kho. Không có thanh toán ngân hàng hay kết nối đơn vị vận chuyển.

## Chạy trên máy

1. Cài .NET 8 SDK, SQL Server và SSMS hoặc sqlcmd. Bật dịch vụ SQL Server.
2. Mở terminal tại thư mục chứa `TechNews.sln`, chạy `dotnet restore TechNews.sln` và `dotnet build TechNews.sln --no-restore`.
3. Với database mới, chạy lần lượt các lệnh dưới đây. Nếu đã có BLOGDB, bỏ qua Database.sql. Không chạy lại script tạo schema lên dữ liệu đang dùng.

```powershell
sqlcmd -S localhost -E -C -b -f 65001 -i Database.sql
sqlcmd -S localhost -E -C -b -d BLOGDB -f 65001 -i UpgradeFeatures.sql
sqlcmd -S localhost -E -C -b -d BLOGDB -f 65001 -i UpgradeCommerce.sql
sqlcmd -S localhost -E -C -b -d BLOGDB -f 65001 -i UpgradeOrderHistory.sql
```

4. Tạo tài khoản quản trị riêng theo phần Database trong README.md. Không dùng tài khoản kiểm thử làm tài khoản chính; không đưa mật khẩu thật vào báo cáo hoặc Git.
5. Dữ liệu tùy chọn: `SeedTechnology.sql` thêm bài kiến thức mẫu; `SeedStorefrontDemo.sql` tạo sáu sản phẩm mô phỏng khi danh mục còn trống. Chạy sau bước nâng cấp database. Với sáu sản phẩm từ bản seed cũ, dùng `UpdateDemoCatalog.sql` để cập nhật tên và mô tả; script không đổi giá, tồn kho hay đơn hàng.
6. Chạy ứng dụng:

```powershell
$env:ConnectionStrings__BlogDatabase='Server=localhost;Database=BLOGDB;Trusted_Connection=True;TrustServerCertificate=True'
dotnet run --project TechNews --no-launch-profile --urls http://localhost:5000
```

Mở `http://localhost:5000`, đăng nhập tại `/Admin/Login`. Khi sửa C# hoặc Razor, dừng và chạy lại ứng dụng. Nếu cổng 5000 đã được dùng, dừng bản chạy cũ hoặc chọn cổng khác. Kết nối SQL mặc định dùng tài khoản Windows của người chạy ứng dụng.

## Đọc mã nguồn theo chức năng

| Thành phần | Vai trò | File bắt đầu đọc |
| --- | --- | --- |
| Controller | Nhận request, kiểm tra dữ liệu/quyền, gọi xử lý, trả view hoặc redirect | `TechNews/Controllers/ShopController.cs` |
| Model và DbContext | Ánh xạ đối tượng sang bảng, khai báo quan hệ | `TechNews/Models/Commerce.cs`, `BLOGDBContext.cs` |
| Service | Chia sẻ xử lý nghiệp vụ giữa nhiều controller | `TechNews/Services/OrderWorkflow.cs` |
| Razor view | Hiển thị dữ liệu và biểu mẫu HTML | `TechNews/Views/ShopAdmin/Orders.cshtml` |
| CSS/JavaScript | Bố cục, tương tác; kiểm tra phía trình duyệt không thay thế server | `TechNews/wwwroot/css`, `TechNews/wwwroot/js` |

Không cần ghi nhớ toàn bộ file. Khi trình bày một chức năng, đi theo request → controller → service/database → view.

## Các luồng nên nắm

### Đăng nhập và hồ sơ

`AdminUsersController.Login` gọi `UsersService.Login`, kiểm tra mật khẩu rồi tạo cookie đăng nhập chứa ID, tên và vai trò. `Authorize` giới hạn quyền truy cập phía server. Hồ sơ chỉ cho sửa tài khoản đang đăng nhập; đổi mật khẩu yêu cầu kiểm tra mật khẩu hiện tại. Mật khẩu mới được băm bằng PasswordHasher. Dữ liệu cũ được chuyển sang băm khi đăng nhập thành công.

### Đọc và quản lý bài viết

Đọc `HomeController`, `AdminArticlesController`, `EditorialController` và các view tương ứng. Phân biệt bản nháp, chờ duyệt và bài công khai. Biên tập viên tạo/sửa nội dung trong phạm vi quyền được cấp; quản trị viên duyệt, xuất bản và quản lý nội dung. Lịch đăng dùng worker nên ứng dụng phải chạy; không mô tả nó như một dịch vụ hoạt động độc lập.

### Giỏ hàng và đặt hàng

`ShoppingCartStore` lưu ID và số lượng sản phẩm trong cookie được bảo vệ bằng Data Protection. Server đọc lại giá và tồn kho từ database khi đặt hàng. Tổng tiền không lấy từ số tiền mà trình duyệt gửi lên.

Trong `ShopController.Checkout`, kiểm tra token đặt hàng, sản phẩm đang bán, giá và tồn kho trước khi tạo đơn. Đơn, chi tiết đơn, lịch sử và thay đổi tồn kho được lưu trong transaction. Token duy nhất giúp yêu cầu gửi lại không tạo thêm đơn. Chi tiết đơn lưu tên và đơn giá tại lúc mua nên việc đổi giá/tên sản phẩm sau đó không sửa đơn cũ.

### Xử lý đơn và hoàn kho

Trạng thái hợp lệ nằm trong `OrderStates.CanMove`:

```text
Chờ xác nhận → Đã xác nhận → Đang giao → Đã giao / đã thu tiền
       ↓             ↓
     Đã hủy        Đã hủy
```

`OrderWorkflow.Move` được cả khách và admin sử dụng. Hàm kiểm tra quyền sở hữu, phiên bản rowversion, trạng thái và lý do hủy. Hoàn kho, đổi trạng thái và thêm sự kiện lịch sử nằm trong cùng transaction. Hai yêu cầu hủy cùng lúc không được hoàn kho hai lần. Đơn đang giao không có chức năng hủy/hoàn tiền sau giao trong phạm vi hiện tại.

### Tìm kiếm và phân trang admin

`ShopAdminController.Orders` lọc trên query trước khi đếm và lấy một trang 30 đơn. Ngày nhập là ngày Việt Nam; đổi về UTC để so sánh với CreatedUtc. Ngày kết thúc được tính bằng cận trên loại trừ của ngày kế tiếp. Các link chuyển trang và quay lại danh sách giữ bộ lọc. Đường dẫn quay lại chỉ chấp nhận danh sách đơn nội bộ.

## Kịch bản demo khoảng 10 phút

1. Mở trang chủ, chọn chuyên mục, tìm và đọc một bài; nói rõ bài mẫu hoặc nguồn của nội dung.
2. Đăng nhập biên tập viên, mở một bài nháp và giới thiệu bước gửi duyệt. Chuyển sang tài khoản admin để minh họa quyền duyệt.
3. Đăng nhập khách, thêm hai sản phẩm vào giỏ, đổi số lượng, đặt đơn COD.
4. Vào admin, tìm đơn theo mã; xác nhận và chuyển sang giao hàng. Chỉ đánh dấu hoàn tất khi mô phỏng đã thu tiền.
5. Tạo một đơn khác để minh họa hủy trước khi giao. Đối chiếu tồn kho và lịch sử đơn trước/sau hủy.
6. Mở hồ sơ, sửa tên rồi hoàn tác hoặc lưu; thu nhỏ màn hình để kiểm tra bố cục.

Không dùng số đơn thử làm doanh thu thật. Các sản phẩm gắn [MẪU] có thông số giả định. Không tự gán bài tổng hợp cho tác giả thật hoặc bỏ nguồn bài đã tham khảo. Tài khoản/đơn QA chỉ nằm trong database kiểm thử.

## Kiểm chứng và giới hạn

- Các script trong `tests/` chỉ chạy với database `TechNews_Verification_*`, có tài khoản QA riêng và server trỏ cùng database. README.md mô tả biến TEST_URL/TEST_DATABASE. Không chạy các script này trên BLOGDB.
- Bộ `commerce.cjs`, `cart.cjs`, `orders.cjs`, `admin-orders.cjs` kiểm tra giá, tồn kho, quyền, CSRF, đặt trùng, hủy và phân trang. Kiểm thử trình duyệt bổ sung cho bố cục và thao tác; không thay thế kiểm thử nghiệp vụ.
- Dự án còn cảnh báo tương thích hai gói PagedList cũ. Chưa có kiểm thử tải, thanh toán online, vận chuyển, hoàn tiền sau giao hoặc đồng bộ giỏ hàng giữa thiết bị.
- Khi được hỏi vì sao chọn transaction, rowversion hoặc token, giải thích vấn đề cụ thể mà chúng giải quyết; có thể mở bài kiểm thử tương ứng để minh họa.
- Nêu đúng phần đã tự triển khai, phần dùng thư viện và phần có công cụ hỗ trợ theo yêu cầu của trường. Không cần khẳng định một chức năng đã làm nếu chưa kiểm chứng.
