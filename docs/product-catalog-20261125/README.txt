CATALOG SẢN PHẨM THỰC — 25/11/2026

Ảnh tải nguyên gốc từ trang hãng/CDN được trang hãng tham chiếu, lưu tại TechNews/wwwroot/images/products/official. Thông số được biên soạn lại bằng tiếng Việt, không sao chép nguyên bài giới thiệu. products.json ghi URL trang thông số, URL ảnh, ngày tải và SHA-256.

Chạy UpdateRealProductCatalog.sql sau SeedStorefrontDemo.sql và UpdateDemoCatalog.sql. Chỉ thay sản phẩm còn đúng tên/ảnh mẫu, không đổi giá/tồn kho/trạng thái/ID hoặc chi tiết đơn cũ. Chạy lại không ghi đè dữ liệu đã sửa.

Giá và tồn kho vẫn là dữ liệu cửa hàng/đồ án đang có, không phải báo giá hay tình trạng kho của hãng. Các ảnh dòng máy có nhiều màu không thể hiện lựa chọn biến thể trong hệ thống hiện tại. Quyền đối với ảnh và nhãn hiệu thuộc chủ sở hữu; việc ghi nguồn không đồng nghĩa có giấy phép sử dụng thương mại.

Apple iPhone 16 128 GB
Thông số: https://support.apple.com/en-us/121029
Trang ảnh: https://support.apple.com/en-us/121029
File: /images/products/official/apple-iphone-16.png

Apple AirPods 4 – hộp sạc USB-C
Thông số: https://support.apple.com/en-ie/121203
Trang ảnh: https://support.apple.com/en-ie/121203
File: /images/products/official/apple-airpods-4.png

Sony WH-CH520 – tai nghe không dây màu đen
Thông số: https://www.sony.com.vn/electronics/support/wireless-headphones-bluetooth-headphones/wh-ch520/specifications
Trang ảnh: https://partners.sony.com.vn/products/wh-ch520
File: /images/products/official/sony-wh-ch520-black.jpg

MacBook Air M2 13,6 inch – 8 GB / 256 GB
Thông số: https://support.apple.com/en-us/111867
Trang ảnh: https://www.apple.com/newsroom/2022/06/apple-unveils-all-new-macbook-air-supercharged-by-the-new-m2-chip/
File: /images/products/official/apple-macbook-air-m2.jpg

Xiaomi Smart Band 9
Thông số: https://www.mi.com/vn/product/xiaomi-smart-band-9/specs/
Trang ảnh: https://www.mi.com/vn/product/xiaomi-smart-band-9/specs/
File: /images/products/official/xiaomi-smart-band-9.png

Apple iPad Gen 10 Wi-Fi 64 GB
Thông số: https://support.apple.com/en-us/111840
Trang ảnh: https://support.apple.com/en-us/111840
File: /images/products/official/apple-ipad-gen-10.png

Kiểm tra SQL trên database kiểm thử: sqlcmd -S localhost -E -C -b -d TechNews_Verification_20261025 -i tests/real-product-catalog.sql (chạy từ thư mục gốc repo). Test tạo fixture trong giao dịch và rollback toàn bộ.
