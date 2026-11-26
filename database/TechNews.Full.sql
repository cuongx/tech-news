:ON ERROR EXIT
USE [master];
GO
IF DB_ID(N'TechNews') IS NOT NULL THROW 51000,'Database already exists. Choose a NEW database name; existing data is never overwritten.',1;
GO

GO
-- SOURCE: Database.sql
-- Clean development schema. No personal accounts or production data.
-- Run in SQL Server Management Studio or sqlcmd.
USE [master];
GO
IF DB_ID(N'TechNews') IS NULL CREATE DATABASE [TechNews];
GO
USE [TechNews];
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID(N'dbo.article', N'U') IS NOT NULL
   OR OBJECT_ID(N'dbo.category', N'U') IS NOT NULL
   OR OBJECT_ID(N'dbo.user', N'U') IS NOT NULL
    THROW 51000, 'TechNews already contains application tables. No changes applied.', 1;

CREATE TABLE dbo.[user] (
    id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    user_name nvarchar(50) NULL,
    user_email nvarchar(50) NULL,
    user_login nvarchar(50) NULL,
    user_password nvarchar(50) NULL,
    user_role varchar(10) NULL
);
CREATE TABLE dbo.category (
    id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    category_name nvarchar(50) NOT NULL,
    category_description nvarchar(100) NULL,
    show_on_menu bit NOT NULL DEFAULT(0),
    display_order int NOT NULL DEFAULT(100)
);
CREATE TABLE dbo.article (
    id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    article_title nvarchar(300) NULL,
    article_description nvarchar(300) NULL,
    article_content nvarchar(max) NULL,
    article_thumb nvarchar(100) NULL,
    article_date date NOT NULL DEFAULT(CONVERT(date,GETDATE())),
    category_id int NULL,
    author_id int NULL,
    article_priority int NULL DEFAULT(0),
    view_counts int NULL DEFAULT(0),
    like_counts int NULL DEFAULT(0),
    article_status bit NULL DEFAULT(0),
    source nvarchar(50) NULL,
    CONSTRAINT FK_article_category FOREIGN KEY(category_id) REFERENCES dbo.category(id),
    CONSTRAINT FK_article_user FOREIGN KEY(author_id) REFERENCES dbo.[user](id)
);
-- Keep the category identities used by the existing view themes.
SET IDENTITY_INSERT dbo.category ON;
INSERT dbo.category(id,category_name,category_description,show_on_menu,display_order) VALUES
(8,N'Trí tuệ nhân tạo',N'AI, mô hình ngôn ngữ và ứng dụng trí tuệ nhân tạo.',1,1),
(9,N'Điện thoại',N'Smartphone, hệ điều hành di động và công nghệ camera.',1,2),
(10,N'Máy tính',N'Laptop, PC, linh kiện và thiết bị ngoại vi.',1,3),
(11,N'An toàn thông tin',N'Bảo mật, quyền riêng tư và kỹ năng an toàn số.',1,5),
(12,N'Phần mềm',N'Ứng dụng, công cụ làm việc và lập trình.',1,4);
SET IDENTITY_INSERT dbo.category OFF;
COMMIT TRANSACTION;
GO

GO

GO
-- SOURCE: UpgradeSecurity.sql
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.[user]', 'user_password') < 512
    ALTER TABLE dbo.[user] ALTER COLUMN user_password nvarchar(256) NULL;
COMMIT;

GO
INSERT dbo.[user](user_name,user_email,user_login,user_password,user_role) VALUES (N'Quản trị demo',N'admin@example.test',N'admin',N'AQAAAAIAAYagAAAAEAMJFQKUj9iB642MnGoabvPMI18r6H2BHrzTEFuQMtnacRT2MSW6a73hKLWNmtoPuQ==',N'Admin'),(N'Khách hàng demo',N'customer@example.test',N'customer',N'AQAAAAIAAYagAAAAEAMJFQKUj9iB642MnGoabvPMI18r6H2BHrzTEFuQMtnacRT2MSW6a73hKLWNmtoPuQ==',N'Reader');
GO

GO
-- SOURCE: SeedTechnology.sql

USE [TechNews];
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @author int = (SELECT TOP 1 id FROM dbo.[user] ORDER BY CASE WHEN user_role='Admin' THEN 0 ELSE 1 END,id);
IF @author IS NULL THROW 50001, 'An author is required.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'Trí tuệ nhân tạo') INSERT dbo.category(category_name,category_description) VALUES (N'Trí tuệ nhân tạo',N'Kiến thức và hướng dẫn về trí tuệ nhân tạo');
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'Điện thoại') INSERT dbo.category(category_name,category_description) VALUES (N'Điện thoại',N'Kiến thức và hướng dẫn về điện thoại');
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'Máy tính') INSERT dbo.category(category_name,category_description) VALUES (N'Máy tính',N'Kiến thức và hướng dẫn về máy tính');
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'An toàn thông tin') INSERT dbo.category(category_name,category_description) VALUES (N'An toàn thông tin',N'Kiến thức và hướng dẫn về an toàn thông tin');
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'Phần mềm') INSERT dbo.category(category_name,category_description) VALUES (N'Phần mềm',N'Kiến thức và hướng dẫn về phần mềm');
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'Điện toán đám mây') INSERT dbo.category(category_name,category_description) VALUES (N'Điện toán đám mây',N'Kiến thức và hướng dẫn về điện toán đám mây');
IF NOT EXISTS (SELECT 1 FROM dbo.article WHERE article_title=N'AI tạo sinh hoạt động như thế nào?' AND source=N'Tech Blog Demo') INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source) VALUES (N'AI tạo sinh hoạt động như thế nào?',N'Hiểu cách AI tạo văn bản và vì sao câu trả lời vẫn cần được kiểm chứng.',N'<p><em>Bài kiến thức mẫu biên soạn cho website demo.</em></p><h2>Tổng quan</h2><p>AI tạo sinh học các mẫu từ dữ liệu huấn luyện để tạo ra nội dung mới. Với mô hình ngôn ngữ, hệ thống dự đoán những phần văn bản tiếp theo dựa trên ngữ cảnh đầu vào. Câu trả lời trôi chảy không đồng nghĩa với việc mọi thông tin đều chính xác.</p><h2>Những điều cần hiểu</h2><p>Trong học tập, bạn có thể dùng AI để gợi ý dàn ý, diễn giải khái niệm hoặc tạo câu hỏi ôn tập. Yêu cầu càng rõ về mục tiêu, đối tượng và định dạng, kết quả càng dễ đánh giá. Hãy chia một công việc lớn thành các bước nhỏ để kiểm tra từng phần.</p><h2>Ứng dụng thực tế</h2><p>Trước khi sử dụng kết quả, hãy đối chiếu các dữ kiện với tài liệu gốc và tự kiểm tra ví dụ. Không đưa mật khẩu, khóa truy cập hay dữ liệu riêng tư vào lời nhắc. AI phù hợp với vai trò trợ lý; người sử dụng vẫn cần chịu trách nhiệm về nội dung cuối cùng.</p>',N'/images/tech-seed/ai.svg',CONVERT(date,GETDATE()),(SELECT TOP 1 id FROM dbo.category WHERE category_name=N'Trí tuệ nhân tạo' ORDER BY id),@author,1,0,0,1,N'Tech Blog Demo');
IF NOT EXISTS (SELECT 1 FROM dbo.article WHERE article_title=N'Viết yêu cầu cho AI rõ ràng hơn' AND source=N'Tech Blog Demo') INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source) VALUES (N'Viết yêu cầu cho AI rõ ràng hơn',N'Một cấu trúc đơn giản giúp lời nhắc có mục tiêu và dễ kiểm tra kết quả.',N'<p><em>Bài kiến thức mẫu biên soạn cho website demo.</em></p><h2>Tổng quan</h2><p>Một lời nhắc tốt bắt đầu bằng việc mô tả kết quả bạn cần. Thay vì yêu cầu chung chung như viết bài công nghệ, hãy nêu chủ đề, người đọc và độ dài mong muốn. Bạn cũng có thể xác định giọng văn và những nội dung cần tránh.</p><h2>Những điều cần hiểu</h2><p>Tiếp theo, cung cấp bối cảnh đủ dùng và chỉ rõ nguồn thông tin được phép sử dụng. Nếu cần bảng so sánh, hãy liệt kê các cột. Nếu cần giải thích cho người mới, yêu cầu định nghĩa thuật ngữ trước khi đưa ví dụ. Không nên cung cấp dữ liệu nhạy cảm chỉ để làm lời nhắc chi tiết hơn.</p><h2>Ứng dụng thực tế</h2><p>Cuối cùng, kiểm tra đầu ra theo một danh sách tiêu chí: đúng chủ đề, đủ ý, có căn cứ và dễ đọc. Khi kết quả chưa phù hợp, chỉ ra phần cần sửa thay vì thay đổi toàn bộ yêu cầu. Lưu lại những mẫu lời nhắc hiệu quả để tái sử dụng trong công việc tương tự.</p>',N'/images/tech-seed/ai.svg',CONVERT(date,GETDATE()),(SELECT TOP 1 id FROM dbo.category WHERE category_name=N'Trí tuệ nhân tạo' ORDER BY id),@author,0,0,0,1,N'Tech Blog Demo');
IF NOT EXISTS (SELECT 1 FROM dbo.article WHERE article_title=N'Hiểu đúng về RAM trên điện thoại' AND source=N'Tech Blog Demo') INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source) VALUES (N'Hiểu đúng về RAM trên điện thoại',N'RAM hỗ trợ đa nhiệm, nhưng không quyết định toàn bộ trải nghiệm sử dụng.',N'<p><em>Bài kiến thức mẫu biên soạn cho website demo.</em></p><h2>Tổng quan</h2><p>RAM là bộ nhớ làm việc tạm thời mà hệ điều hành và ứng dụng sử dụng khi hoạt động. Khi chuyển giữa nhiều ứng dụng, dung lượng RAM có thể ảnh hưởng đến việc ứng dụng được giữ trong bộ nhớ hay phải tải lại. RAM khác với bộ nhớ lưu trữ dùng để chứa ảnh, video và tệp.</p><h2>Những điều cần hiểu</h2><p>Trải nghiệm còn phụ thuộc vào bộ xử lý, tốc độ lưu trữ, phần mềm và cách quản lý tác vụ nền. Hai điện thoại có cùng lượng RAM không nhất thiết hoạt động giống nhau. Các tính năng mở rộng RAM bằng bộ nhớ lưu trữ cũng không có cùng đặc tính với RAM vật lý.</p><h2>Ứng dụng thực tế</h2><p>Để hiểu nhu cầu của bản thân, hãy quan sát các ứng dụng thường dùng và tần suất chúng phải tải lại. Người đọc tin, nhắn tin và chụp ảnh có kiểu sử dụng khác với người chơi trò chơi nặng hoặc chỉnh sửa video. Đánh giá thiết bị theo tác vụ thực tế sẽ có ý nghĩa hơn việc chỉ nhìn một con số.</p>',N'/images/tech-seed/phone.svg',CONVERT(date,GETDATE()),(SELECT TOP 1 id FROM dbo.category WHERE category_name=N'Điện thoại' ORDER BY id),@author,2,0,0,1,N'Tech Blog Demo');
IF NOT EXISTS (SELECT 1 FROM dbo.article WHERE article_title=N'Sắp xếp ảnh và giải phóng bộ nhớ' AND source=N'Tech Blog Demo') INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source) VALUES (N'Sắp xếp ảnh và giải phóng bộ nhớ',N'Giữ thư viện ảnh gọn gàng mà vẫn tránh mất những tệp quan trọng.',N'<p><em>Bài kiến thức mẫu biên soạn cho website demo.</em></p><h2>Tổng quan</h2><p>Ảnh chụp liên tiếp, video dài và tệp tải xuống có thể khiến bộ nhớ điện thoại đầy nhanh. Trước khi xóa, hãy kiểm tra dung lượng theo nhóm trong phần cài đặt của thiết bị. Cách này giúp xác định đúng loại dữ liệu đang chiếm nhiều chỗ.</p><h2>Những điều cần hiểu</h2><p>Hãy gom các ảnh quan trọng thành album và sao lưu sang một nơi độc lập. Mở thử một vài tệp trong bản sao để chắc chắn chúng đọc được. Đồng bộ và sao lưu không hoàn toàn giống nhau: ở một số dịch vụ, thao tác xóa trên thiết bị có thể được đồng bộ sang nơi lưu trực tuyến.</p><h2>Ứng dụng thực tế</h2><p>Sau khi xác nhận bản sao, bạn có thể dọn ảnh trùng, video không cần thiết và tệp tải về đã dùng xong. Đọc kỹ thông báo trước khi xóa vĩnh viễn hoặc làm trống thùng rác. Duy trì thói quen dọn thư viện định kỳ thường dễ hơn xử lý hàng nghìn tệp cùng một lúc.</p>',N'/images/tech-seed/phone.svg',CONVERT(date,GETDATE()),(SELECT TOP 1 id FROM dbo.category WHERE category_name=N'Điện thoại' ORDER BY id),@author,0,0,0,1,N'Tech Blog Demo');
IF NOT EXISTS (SELECT 1 FROM dbo.article WHERE article_title=N'SSD và HDD khác nhau ở điểm nào?' AND source=N'Tech Blog Demo') INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source) VALUES (N'SSD và HDD khác nhau ở điểm nào?',N'Tìm hiểu hai cách lưu trữ dữ liệu phổ biến trong máy tính.',N'<p><em>Bài kiến thức mẫu biên soạn cho website demo.</em></p><h2>Tổng quan</h2><p>HDD lưu dữ liệu trên đĩa từ quay và dùng đầu đọc cơ học. SSD sử dụng bộ nhớ flash, không cần cơ cấu quay để truy cập dữ liệu. Khác biệt này ảnh hưởng đến độ trễ truy cập, tiếng ồn và khả năng chịu rung khi thiết bị hoạt động.</p><h2>Những điều cần hiểu</h2><p>SSD thường giúp các tác vụ khởi động hệ điều hành và mở ứng dụng phản hồi nhanh hơn. Tuy nhiên, tốc độ thực tế còn liên quan đến chuẩn kết nối, bộ điều khiển, dung lượng trống và loại công việc. Sao chép một tệp lớn không phản ánh đầy đủ hiệu năng khi xử lý nhiều tệp nhỏ.</p><h2>Ứng dụng thực tế</h2><p>Dù dùng loại ổ nào, dữ liệu quan trọng vẫn cần bản sao độc lập. Thiết bị lưu trữ có thể hỏng mà không báo trước, và tốc độ cao không thay thế được việc sao lưu. Khi xem thông số, hãy phân biệt dung lượng, tốc độ tuần tự và điều kiện đo để tránh hiểu nhầm.</p>',N'/images/tech-seed/laptop.svg',CONVERT(date,GETDATE()),(SELECT TOP 1 id FROM dbo.category WHERE category_name=N'Máy tính' ORDER BY id),@author,3,0,0,1,N'Tech Blog Demo');
IF NOT EXISTS (SELECT 1 FROM dbo.article WHERE article_title=N'Vì sao laptop nóng khi chạy tác vụ nặng?' AND source=N'Tech Blog Demo') INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source) VALUES (N'Vì sao laptop nóng khi chạy tác vụ nặng?',N'Nhiệt độ liên quan đến tải xử lý, luồng khí và môi trường sử dụng.',N'<p><em>Bài kiến thức mẫu biên soạn cho website demo.</em></p><h2>Tổng quan</h2><p>Bộ xử lý và bộ xử lý đồ họa tiêu thụ điện khi tính toán, một phần năng lượng chuyển thành nhiệt. Trò chơi, dựng hình và xuất video thường tạo tải cao hơn đọc tài liệu. Hệ thống làm mát đưa nhiệt ra ngoài bằng các thành phần như ống dẫn nhiệt, khe thoát khí và quạt.</p><h2>Những điều cần hiểu</h2><p>Khi khe thông gió bị che bởi chăn hoặc mặt đệm, khả năng trao đổi không khí giảm. Đặt máy trên bề mặt cứng và thoáng giúp hệ thống làm mát hoạt động đúng thiết kế. Các tiến trình nền cũng có thể gây tải; hãy kiểm tra công cụ quản lý tác vụ trước khi kết luận máy có lỗi phần cứng.</p><h2>Ứng dụng thực tế</h2><p>Không có một ngưỡng nhiệt chung phù hợp với mọi mẫu máy và mọi cảm biến. Nếu máy thường xuyên tự tắt, có mùi bất thường hoặc quạt phát tiếng lạ, nên ngừng tác vụ và nhờ kỹ thuật kiểm tra. Không tự tháo thiết bị nếu chưa hiểu quy trình và điều kiện bảo hành.</p>',N'/images/tech-seed/laptop.svg',CONVERT(date,GETDATE()),(SELECT TOP 1 id FROM dbo.category WHERE category_name=N'Máy tính' ORDER BY id),@author,0,0,0,1,N'Tech Blog Demo');
IF NOT EXISTS (SELECT 1 FROM dbo.article WHERE article_title=N'Nhận diện email lừa đảo qua dấu hiệu nhỏ' AND source=N'Tech Blog Demo') INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source) VALUES (N'Nhận diện email lừa đảo qua dấu hiệu nhỏ',N'Kiểm tra địa chỉ, liên kết và yêu cầu bất thường trước khi hành động.',N'<p><em>Bài kiến thức mẫu biên soạn cho website demo.</em></p><h2>Tổng quan</h2><p>Email lừa đảo thường tạo cảm giác khẩn cấp để người nhận bấm liên kết hoặc cung cấp thông tin. Tên hiển thị có thể giống một tổ chức quen thuộc nhưng địa chỉ gửi lại khác. Lỗi chính tả là một dấu hiệu có thể gặp, tuy nhiên một email viết trôi chảy vẫn có thể là giả mạo.</p><h2>Những điều cần hiểu</h2><p>Hãy kiểm tra tên miền và tránh đăng nhập qua liên kết trong một thông báo đáng ngờ. Cách kiểm chứng hữu ích là tự mở ứng dụng hoặc nhập địa chỉ trang chính thức mà bạn đã biết. Không gửi mật khẩu hay mã xác thực cho người tự xưng là nhân viên hỗ trợ.</p><h2>Ứng dụng thực tế</h2><p>Nếu đã tương tác với email đáng ngờ, hãy kiểm tra hoạt động tài khoản từ một thiết bị tin cậy. Đổi mật khẩu bị lộ và thu hồi các phiên đăng nhập không nhận ra. Với tài khoản của trường hoặc công ty, báo cho bộ phận phụ trách để họ kiểm tra và hướng dẫn xử lý tiếp.</p>',N'/images/tech-seed/security.svg',CONVERT(date,GETDATE()),(SELECT TOP 1 id FROM dbo.category WHERE category_name=N'An toàn thông tin' ORDER BY id),@author,0,0,0,1,N'Tech Blog Demo');
IF NOT EXISTS (SELECT 1 FROM dbo.article WHERE article_title=N'Xác thực hai bước bảo vệ tài khoản ra sao?' AND source=N'Tech Blog Demo') INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source) VALUES (N'Xác thực hai bước bảo vệ tài khoản ra sao?',N'Thêm một lớp kiểm tra để giảm rủi ro khi mật khẩu bị lộ.',N'<p><em>Bài kiến thức mẫu biên soạn cho website demo.</em></p><h2>Tổng quan</h2><p>Xác thực nhiều yếu tố kết hợp các dạng bằng chứng khác nhau, chẳng hạn mật khẩu và một thiết bị bạn sở hữu. Mục tiêu là khiến việc biết mật khẩu thôi chưa đủ để đăng nhập. Không phải mọi cơ chế hai bước đều có mức bảo vệ giống nhau.</p><h2>Những điều cần hiểu</h2><p>Ứng dụng tạo mã, khóa bảo mật và các phương thức dựa trên thiết bị có cách hoạt động khác nhau. Một số phương thức vẫn có thể bị lừa lấy mã qua trang giả. Vì vậy, bạn cần kiểm tra ngữ cảnh đăng nhập và không chấp thuận yêu cầu xác thực mà mình không khởi tạo.</p><h2>Ứng dụng thực tế</h2><p>Khi bật tính năng, hãy thiết lập phương án khôi phục và giữ mã dự phòng ở nơi an toàn. Nếu đổi điện thoại, kiểm tra việc chuyển phương thức xác thực trước khi xóa máy cũ. Một lớp bảo vệ được cấu hình cẩn thận sẽ hữu ích hơn việc bật nhanh nhưng bỏ quên khả năng khôi phục.</p>',N'/images/tech-seed/security.svg',CONVERT(date,GETDATE()),(SELECT TOP 1 id FROM dbo.category WHERE category_name=N'An toàn thông tin' ORDER BY id),@author,0,0,0,1,N'Tech Blog Demo');
IF NOT EXISTS (SELECT 1 FROM dbo.article WHERE article_title=N'Git giúp nhóm làm đồ án như thế nào?' AND source=N'Tech Blog Demo') INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source) VALUES (N'Git giúp nhóm làm đồ án như thế nào?',N'Theo dõi thay đổi và phối hợp công việc bằng hệ thống quản lý phiên bản.',N'<p><em>Bài kiến thức mẫu biên soạn cho website demo.</em></p><h2>Tổng quan</h2><p>Git ghi lại các phiên bản của tệp để nhóm có thể xem ai thay đổi phần nào và vì sao. Mỗi commit nên thể hiện một thay đổi có mục đích rõ ràng. Lịch sử nhỏ, dễ đọc giúp việc rà soát và tìm nguyên nhân lỗi thuận tiện hơn.</p><h2>Những điều cần hiểu</h2><p>Các thành viên có thể làm trên nhánh riêng cho từng chức năng, sau đó gửi thay đổi để người khác xem xét. Trước khi hợp nhất, cần cập nhật nhánh và xử lý xung đột nếu nhiều người sửa cùng một vùng. Xung đột là tình huống phối hợp bình thường, không phải dấu hiệu mất toàn bộ công việc.</p><h2>Ứng dụng thực tế</h2><p>Nhóm nên thống nhất cách đặt tên nhánh, viết thông điệp commit và kiểm tra trước khi hợp nhất. Không đưa mật khẩu, tệp cấu hình bí mật hay dữ liệu cá nhân vào kho mã. Tài liệu khởi chạy ngắn gọn giúp thành viên mới dựng môi trường mà không phải hỏi lại từng bước.</p>',N'/images/tech-seed/software.svg',CONVERT(date,GETDATE()),(SELECT TOP 1 id FROM dbo.category WHERE category_name=N'Phần mềm' ORDER BY id),@author,0,0,0,1,N'Tech Blog Demo');
IF NOT EXISTS (SELECT 1 FROM dbo.article WHERE article_title=N'API là gì trong một ứng dụng web?' AND source=N'Tech Blog Demo') INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source) VALUES (N'API là gì trong một ứng dụng web?',N'Cách các thành phần phần mềm trao đổi dữ liệu qua giao diện thống nhất.',N'<p><em>Bài kiến thức mẫu biên soạn cho website demo.</em></p><h2>Tổng quan</h2><p>API là giao diện cho phép phần mềm yêu cầu chức năng hoặc dữ liệu từ thành phần khác. Trong ứng dụng web, trình duyệt có thể gửi yêu cầu đến máy chủ và nhận dữ liệu để hiển thị. Máy chủ quyết định dữ liệu nào được trả về dựa trên quy tắc của ứng dụng.</p><h2>Những điều cần hiểu</h2><p>Một yêu cầu thường gồm địa chỉ, phương thức và dữ liệu đầu vào. Phản hồi có trạng thái và nội dung, chẳng hạn danh sách bài viết hoặc thông báo không tìm thấy tài nguyên. Thiết kế nhất quán giúp phía giao diện xử lý kết quả và lỗi dễ dàng hơn.</p><h2>Ứng dụng thực tế</h2><p>API cần kiểm tra dữ liệu và quyền truy cập ở phía máy chủ. Việc ẩn một nút trên giao diện không ngăn người dùng gửi yêu cầu trực tiếp. Với đồ án tin tức, bạn có thể bắt đầu bằng luồng đọc danh sách bài, xem chi tiết và tìm kiếm trước khi mở rộng sang chức năng quản trị.</p>',N'/images/tech-seed/software.svg',CONVERT(date,GETDATE()),(SELECT TOP 1 id FROM dbo.category WHERE category_name=N'Phần mềm' ORDER BY id),@author,0,0,0,1,N'Tech Blog Demo');
IF NOT EXISTS (SELECT 1 FROM dbo.article WHERE article_title=N'Lưu trữ đám mây và sao lưu khác nhau' AND source=N'Tech Blog Demo') INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source) VALUES (N'Lưu trữ đám mây và sao lưu khác nhau',N'Hiểu sự khác biệt để tránh nhầm rằng tệp đồng bộ luôn có bản dự phòng.',N'<p><em>Bài kiến thức mẫu biên soạn cho website demo.</em></p><h2>Tổng quan</h2><p>Lưu trữ đám mây giúp truy cập tệp qua mạng từ nhiều thiết bị. Đồng bộ giữ nội dung giữa các vị trí theo quy tắc của dịch vụ. Nếu xóa hoặc sửa nhầm một tệp, thay đổi đó có thể được truyền tới các thiết bị khác.</p><h2>Những điều cần hiểu</h2><p>Sao lưu tập trung vào khả năng khôi phục dữ liệu tại một thời điểm. Một hệ thống sao lưu cần có chính sách lưu giữ và cách phục hồi rõ ràng. Lịch sử phiên bản hoặc thùng rác của dịch vụ có thể hữu ích, nhưng cần kiểm tra giới hạn thực tế thay vì mặc định chúng tồn tại mãi.</p><h2>Ứng dụng thực tế</h2><p>Với đồ án nhóm, hãy tách mã nguồn, tài liệu và bản sao cơ sở dữ liệu thành các phần có người phụ trách. Thử phục hồi trên môi trường riêng để biết bản sao có dùng được hay không. Một tệp sao lưu chưa từng được kiểm tra vẫn có thể thiếu dữ liệu cần thiết.</p>',N'/images/tech-seed/cloud.svg',CONVERT(date,GETDATE()),(SELECT TOP 1 id FROM dbo.category WHERE category_name=N'Điện toán đám mây' ORDER BY id),@author,0,0,0,1,N'Tech Blog Demo');
IF NOT EXISTS (SELECT 1 FROM dbo.article WHERE article_title=N'Tên miền và hosting đảm nhiệm việc gì?' AND source=N'Tech Blog Demo') INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source) VALUES (N'Tên miền và hosting đảm nhiệm việc gì?',N'Phân biệt địa chỉ truy cập với nơi chạy website và lưu dữ liệu.',N'<p><em>Bài kiến thức mẫu biên soạn cho website demo.</em></p><h2>Tổng quan</h2><p>Tên miền là tên dễ nhớ dùng để truy cập dịch vụ trên mạng. Hệ thống DNS cung cấp các bản ghi giúp xác định điểm đến phù hợp. Hosting là môi trường chứa hoặc vận hành các thành phần của website, tùy kiến trúc ứng dụng.</p><h2>Những điều cần hiểu</h2><p>Một website có thể dùng các dịch vụ riêng cho giao diện, máy chủ ứng dụng, cơ sở dữ liệu và ảnh. Vì vậy, sở hữu tên miền chưa có nghĩa là đã có môi trường chạy toàn bộ hệ thống. Cấu hình DNS cũng cần khớp với hướng dẫn của nơi triển khai.</p><h2>Ứng dụng thực tế</h2><p>Trước khi đưa đồ án lên mạng, hãy xác định runtime, cơ sở dữ liệu và vị trí lưu tệp tải lên. Cần cấu hình HTTPS, biến môi trường và bản sao dữ liệu phù hợp. Thử các luồng đăng nhập, đọc bài và tải ảnh trên môi trường triển khai vì chúng có thể khác máy phát triển.</p>',N'/images/tech-seed/cloud.svg',CONVERT(date,GETDATE()),(SELECT TOP 1 id FROM dbo.category WHERE category_name=N'Điện toán đám mây' ORDER BY id),@author,0,0,0,1,N'Tech Blog Demo');
COMMIT;
SELECT COUNT(*) AS SeedArticles FROM dbo.article WHERE source=N'Tech Blog Demo';

GO

GO
-- SOURCE: ImportZnewsBriefs.sql
-- TechNews: five independently written briefs, verified 2026-10-21.
-- Original publication dates are retained. No source photos or full articles copied.
-- Re-running skips existing source URLs or matching titles. Existing records are not changed.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @AuthorId int = (SELECT TOP(1) id FROM dbo.[user] WHERE user_role=N'Admin' ORDER BY id);
IF @AuthorId IS NULL THROW 51000, 'No admin account found; import cancelled.', 1;
DECLARE @Items TABLE (title nvarchar(300), description nvarchar(300), body nvarchar(max), published date, category nvarchar(50), thumb nvarchar(100), url nvarchar(500));
INSERT @Items VALUES
(N'Vivo chọn camera và pin làm điểm nhấn',N'Dòng máy cao cấp của Vivo tập trung vào trải nghiệm chụp ảnh, màn hình và thời lượng pin.',
 N'<p>Theo bài viết của Znews ngày 20/10, thế hệ điện thoại cao cấp mới của Vivo chú trọng nâng cấp camera và pin trong bối cảnh chi phí bộ nhớ tăng. Các phiên bản được giới thiệu đều sử dụng RAM 12 GB nhưng khác nhau về kích thước màn hình và hệ thống chụp ảnh.</p><p>Bản cao nhất hướng đến nhu cầu chụp xa và quay video, trong khi các mẫu còn lại có cấu hình, kích thước và thị trường phân phối riêng. Bạn có thể xem bảng thông số và phân tích chi tiết tại bài gốc.</p>',
 '2026-10-20',N'Điện thoại',N'/images/tech-seed/phone.svg',N'https://tech.zingnews.vn/smartphone-cao-cap-trung-quoc-dau-iphone-bang-gi-post1684596.html'),
(N'Chuẩn hóa dữ liệu văn bằng cho VNeID',N'Dữ liệu văn bằng được rà soát để kết nối với định danh cá nhân và hỗ trợ tra cứu điện tử.',
 N'<p>Znews đưa tin ngày 20/10 về yêu cầu rà soát 12 triệu hồ sơ văn bằng, chứng chỉ để phục vụ kết nối với VNeID. Trọng tâm là sửa thông tin thiếu hoặc chưa nhất quán và liên kết hồ sơ với định danh cá nhân.</p><p>Đây là bước hoàn thiện chất lượng dữ liệu, không đồng nghĩa toàn bộ số hồ sơ nói trên chưa từng được số hóa. Khi được xác thực và tích hợp, thông tin có thể giúp việc đối chiếu bằng cấp thuận tiện hơn. Bài gốc trình bày thêm tiến độ và phạm vi triển khai.</p>',
 '2026-10-20',N'Phần mềm',N'/images/tech-seed/software.svg',N'https://tech.zingnews.vn/12-trieu-du-lieu-bang-cap-se-duoc-chuan-hoa-de-tich-hop-len-vneid-post1689672.html'),
(N'Giúp trẻ tự bảo vệ mình trên Internet',N'Kỹ năng nhận diện rủi ro và sự đồng hành của người lớn là trọng tâm của giáo dục an toàn số.',
 N'<p>Bài viết ngày 19/10 của Znews ghi nhận quan điểm tại chương trình giáo dục an toàn số ở Hà Nội: bảo vệ trẻ không chỉ là hạn chế truy cập Internet. Học sinh cần biết kiểm tra thông tin, cân nhắc trước khi chia sẻ dữ liệu và tìm người lớn hỗ trợ khi gặp tình huống bất an.</p><p>Chương trình cũng nhấn mạnh trách nhiệm phối hợp giữa gia đình, nhà trường và doanh nghiệp công nghệ. Các hoạt động thực hành được sử dụng để giúp trẻ nhận ra rủi ro trong tình huống gần gũi với cuộc sống.</p>',
 '2026-10-19',N'An toàn thông tin',N'/images/tech-seed/security.svg',N'https://tech.zingnews.vn/khong-the-bao-ve-tre-bang-cach-cam-len-internet-post1690623.html'),
(N'Dán sticker laptop: cần chú ý vị trí',N'Hình dán nên tránh khe thông gió và các bộ phận chức năng; việc tháo keo cũng cần cẩn thận.',
 N'<p>Theo bài tổng hợp của Znews ngày 18/10, trang trí laptop bằng hình dán có thể gây vấn đề nếu che mất đường lưu thông không khí hoặc cản trở các bộ phận của máy. Mặt ngoài nắp máy thường ít ảnh hưởng đến chức năng hơn các vị trí như khe gió, micro hay bàn di chuột.</p><p>Keo và thao tác tháo hình dán có thể để lại dấu hoặc tác động đến lớp hoàn thiện. Người dùng nên đối chiếu hướng dẫn vệ sinh của hãng và tránh dung môi mạnh hoặc dụng cụ sắc. Bài gốc giải thích thêm những yếu tố cần cân nhắc.</p>',
 '2026-10-18',N'Máy tính',N'/images/tech-seed/laptop.svg',N'https://tech.zingnews.vn/sai-lam-khi-dan-sticker-len-laptop-post1689132.html'),
(N'Nhân tài AI 17 tuổi được chú ý sau khi rời Kimi',N'Znews đưa tin về bến đỗ được đồn đoán của Trần Quảng Vũ; các bên chưa chính thức xác nhận.',
 N'<p>Znews ngày 20/10 đề cập thông tin Trần Quảng Vũ, nhà nghiên cứu AI trẻ từng làm việc tại Moonshot AI, có thể chuyển sang Discovery Loop. Theo bài viết, đây là công ty do một nhóm chuyên gia từng làm tại Google thành lập, trong đó có Lê Viết Quốc.</p><p>Thông tin chuyển việc vẫn chưa được cá nhân và doanh nghiệp liên quan xác nhận chính thức. Bài viết cũng điểm lại công trình nghiên cứu và quá trình phát triển của nhân vật này. Độc giả nên theo dõi nguồn gốc để cập nhật các xác nhận tiếp theo.</p>',
 '2026-10-20',N'Trí tuệ nhân tạo',N'/images/tech-seed/ai.svg',N'https://tech.zingnews.vn/than-dong-trung-quoc-17-tuoi-gia-nhap-cong-ty-cua-quai-kiet-ai-viet-nam-post1690944.html');
IF EXISTS (SELECT 1 FROM @Items i WHERE NOT EXISTS (SELECT 1 FROM dbo.category c WHERE c.category_name=i.category))
    THROW 51001, 'Missing category; import cancelled.', 1;
DECLARE @Added TABLE (id int,title nvarchar(300));
INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source)
OUTPUT inserted.id,inserted.article_title INTO @Added
SELECT i.title,i.description,
    i.body+N'<p><a href="'+i.url+N'" target="_blank" rel="noopener noreferrer">Đọc bài gốc trên Znews ↗</a></p>',
    i.thumb,i.published,c.id,@AuthorId,0,0,0,1,N'Znews (bản tóm tắt)'
FROM @Items i JOIN dbo.category c ON c.category_name=i.category
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.article a WITH(UPDLOCK,HOLDLOCK)
    WHERE a.article_title=i.title OR CHARINDEX(i.url,ISNULL(a.article_content,N''))>0
);
SELECT id,title FROM @Added;
SELECT COUNT(*) AS InsertedBriefs FROM @Added;
COMMIT TRANSACTION;

GO

GO
-- SOURCE: UpdateTechnologyCategories.sql

USE [TechNews];
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'Trí tuệ nhân tạo') INSERT dbo.category(category_name,category_description) VALUES(N'Trí tuệ nhân tạo',N'AI, mô hình ngôn ngữ và ứng dụng trí tuệ nhân tạo.');
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'Điện thoại') INSERT dbo.category(category_name,category_description) VALUES(N'Điện thoại',N'Smartphone, hệ điều hành di động và công nghệ camera.');
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'Máy tính') INSERT dbo.category(category_name,category_description) VALUES(N'Máy tính',N'Laptop, PC, linh kiện và thiết bị ngoại vi.');
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'Phần mềm') INSERT dbo.category(category_name,category_description) VALUES(N'Phần mềm',N'Ứng dụng, công cụ làm việc, lập trình và điện toán đám mây.');
IF NOT EXISTS (SELECT 1 FROM dbo.category WHERE category_name=N'An toàn thông tin') INSERT dbo.category(category_name,category_description) VALUES(N'An toàn thông tin',N'Bảo mật, quyền riêng tư và phòng tránh lừa đảo trực tuyến.');
IF COL_LENGTH('dbo.category','display_order') IS NULL
BEGIN
    ALTER TABLE dbo.category ADD display_order int NOT NULL CONSTRAINT DF_category_display_order DEFAULT(100);
END;
IF COL_LENGTH('dbo.category','show_on_menu') IS NULL
BEGIN
    ALTER TABLE dbo.category ADD show_on_menu bit NOT NULL CONSTRAINT DF_category_show_on_menu DEFAULT(0);
    EXEC sp_executesql N'UPDATE dbo.category SET show_on_menu=1, display_order=CASE category_name WHEN N''Trí tuệ nhân tạo'' THEN 1 WHEN N''Điện thoại'' THEN 2 WHEN N''Máy tính'' THEN 3 WHEN N''Phần mềm'' THEN 4 WHEN N''An toàn thông tin'' THEN 5 END WHERE category_name IN (N''Trí tuệ nhân tạo'',N''Điện thoại'',N''Máy tính'',N''Phần mềm'',N''An toàn thông tin'');';
END;
COMMIT;
GO
SELECT id,category_name,show_on_menu,display_order FROM dbo.category ORDER BY display_order,id;

GO

GO
-- SOURCE: UpgradeFeatures.sql
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.[user]', 'user_password') < 512 ALTER TABLE dbo.[user] ALTER COLUMN user_password nvarchar(256) NULL;
IF COL_LENGTH('dbo.article','EditorialState') IS NULL BEGIN
 ALTER TABLE dbo.article ADD EditorialState nvarchar(20) NOT NULL CONSTRAINT DF_article_state DEFAULT 'Draft', ScheduledUtc datetime2 NULL;
 EXEC('UPDATE dbo.article SET EditorialState = CASE WHEN article_status = 1 THEN ''Published'' ELSE ''Draft'' END');
END;
IF OBJECT_ID('dbo.SavedArticles') IS NULL CREATE TABLE dbo.SavedArticles (
 UserId int NOT NULL REFERENCES dbo.[user](id), ArticleId int NOT NULL REFERENCES dbo.article(id) ON DELETE CASCADE,
 CreatedUtc datetime2 NOT NULL, CONSTRAINT PK_SavedArticles PRIMARY KEY(UserId,ArticleId));
IF OBJECT_ID('dbo.Comments') IS NULL CREATE TABLE dbo.Comments (
 Id int IDENTITY PRIMARY KEY, UserId int NOT NULL REFERENCES dbo.[user](id), ArticleId int NOT NULL REFERENCES dbo.article(id) ON DELETE CASCADE,
 Body nvarchar(2000) NOT NULL, Status nvarchar(20) NOT NULL, CreatedUtc datetime2 NOT NULL, ModeratorId int NULL REFERENCES dbo.[user](id), ModeratedUtc datetime2 NULL);
IF OBJECT_ID('dbo.EditorialEvents') IS NULL CREATE TABLE dbo.EditorialEvents (
 Id int IDENTITY PRIMARY KEY, ArticleId int NOT NULL REFERENCES dbo.article(id) ON DELETE CASCADE, ActorId int NULL REFERENCES dbo.[user](id),
 FromState nvarchar(20) NOT NULL, ToState nvarchar(20) NOT NULL, Note nvarchar(1000) NULL, CreatedUtc datetime2 NOT NULL);
IF OBJECT_ID('dbo.Tags') IS NULL CREATE TABLE dbo.Tags (Id int IDENTITY PRIMARY KEY, Name nvarchar(60) NOT NULL UNIQUE);
IF OBJECT_ID('dbo.ArticleTags') IS NULL CREATE TABLE dbo.ArticleTags (
 ArticleId int NOT NULL REFERENCES dbo.article(id) ON DELETE CASCADE, TagId int NOT NULL REFERENCES dbo.Tags(Id), CONSTRAINT PK_ArticleTags PRIMARY KEY(ArticleId,TagId));
IF OBJECT_ID('dbo.Assets') IS NULL CREATE TABLE dbo.Assets (
 Id int IDENTITY PRIMARY KEY, OwnerId int NOT NULL REFERENCES dbo.[user](id), Url nvarchar(100) NOT NULL UNIQUE,
 FileName nvarchar(255) NOT NULL, Size bigint NOT NULL, CreatedUtc datetime2 NOT NULL);
IF OBJECT_ID('dbo.DailyViews') IS NULL CREATE TABLE dbo.DailyViews (
 ArticleId int NOT NULL REFERENCES dbo.article(id) ON DELETE CASCADE, Day date NOT NULL, Views int NOT NULL, CONSTRAINT PK_DailyViews PRIMARY KEY(ArticleId,Day));
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Comments_Article_Status') CREATE INDEX IX_Comments_Article_Status ON dbo.Comments(ArticleId,Status,CreatedUtc);
COMMIT;

GO

GO
-- SOURCE: UpgradeCommerce.sql
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.Products') IS NULL CREATE TABLE dbo.Products (
 Id int IDENTITY PRIMARY KEY, Name nvarchar(160) NOT NULL, Category nvarchar(80) NOT NULL,
 Description nvarchar(4000) NULL, ImageUrl nvarchar(500) NULL, Price decimal(18,0) NOT NULL CHECK(Price>=1000),
 Stock int NOT NULL CHECK(Stock>=0), IsActive bit NOT NULL, Version rowversion NOT NULL);
IF OBJECT_ID('dbo.ShopOrders') IS NULL CREATE TABLE dbo.ShopOrders (
 Id int IDENTITY PRIMARY KEY, UserId int NOT NULL REFERENCES dbo.[user](id), CheckoutToken uniqueidentifier NOT NULL,
 Recipient nvarchar(100) NOT NULL, Phone nvarchar(20) NOT NULL, Address nvarchar(500) NOT NULL, Note nvarchar(1000) NULL,
 Status nvarchar(20) NOT NULL CHECK(Status IN ('Pending','Confirmed','Shipping','Completed','Cancelled')),
 CreatedUtc datetime2 NOT NULL, Total decimal(18,0) NOT NULL CHECK(Total>=0), Version rowversion NOT NULL);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_ShopOrders_CheckoutToken' AND object_id=OBJECT_ID('dbo.ShopOrders'))
 CREATE UNIQUE INDEX IX_ShopOrders_CheckoutToken ON dbo.ShopOrders(CheckoutToken);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_ShopOrders_UserId' AND object_id=OBJECT_ID('dbo.ShopOrders'))
 CREATE INDEX IX_ShopOrders_UserId ON dbo.ShopOrders(UserId,Id);
IF OBJECT_ID('dbo.ShopOrderItems') IS NULL CREATE TABLE dbo.ShopOrderItems (
 Id int IDENTITY PRIMARY KEY, ShopOrderId int NOT NULL REFERENCES dbo.ShopOrders(Id) ON DELETE CASCADE,
 ProductId int NOT NULL REFERENCES dbo.Products(Id), ProductName nvarchar(160) NOT NULL,
 Quantity int NOT NULL CHECK(Quantity BETWEEN 1 AND 99), UnitPrice decimal(18,0) NOT NULL CHECK(UnitPrice>=1000));
COMMIT;

GO

GO
-- SOURCE: UpgradeOrderHistory.sql
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.ShopOrderEvents') IS NULL
BEGIN
 CREATE TABLE dbo.ShopOrderEvents (
  Id int IDENTITY PRIMARY KEY, ShopOrderId int NOT NULL REFERENCES dbo.ShopOrders(Id) ON DELETE CASCADE,
  Status nvarchar(20) NOT NULL, ActorRole nvarchar(20) NOT NULL, ActorId int NULL,
  Reason nvarchar(500) NULL, CreatedUtc datetime2 NOT NULL);
 CREATE INDEX IX_ShopOrderEvents_ShopOrderId ON dbo.ShopOrderEvents(ShopOrderId,Id);
 -- Preserve current state only; earlier transitions were not recorded.
 INSERT INTO dbo.ShopOrderEvents(ShopOrderId,Status,ActorRole,Reason,CreatedUtc)
 SELECT Id,Status,'System',N'Trạng thái tại thời điểm bắt đầu lưu lịch sử.',SYSUTCDATETIME() FROM dbo.ShopOrders;
END;
COMMIT;

GO

GO
-- SOURCE: UpgradeShippingAddress.sql
-- Run after UpgradeCommerce.sql and UpgradeOrderHistory.sql on the chosen database.
-- Existing free-text addresses remain intact; do not guess old administrative codes.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.ShopOrders') IS NULL OR OBJECT_ID('dbo.ShopOrderEvents') IS NULL
    THROW 50001, 'Apply UpgradeCommerce.sql and UpgradeOrderHistory.sql first.', 1;
IF COL_LENGTH('dbo.ShopOrders','ProvinceCode') IS NULL
    ALTER TABLE dbo.ShopOrders ADD ProvinceCode int NULL;
IF COL_LENGTH('dbo.ShopOrders','WardCode') IS NULL
    ALTER TABLE dbo.ShopOrders ADD WardCode int NULL;
IF COL_LENGTH('dbo.ShopOrders','AddressLine') IS NULL
    ALTER TABLE dbo.ShopOrders ADD AddressLine nvarchar(300) NULL;
IF COL_LENGTH('dbo.ShopOrderEvents','AddressBefore') IS NULL
    ALTER TABLE dbo.ShopOrderEvents ADD AddressBefore nvarchar(500) NULL;
IF COL_LENGTH('dbo.ShopOrderEvents','AddressAfter') IS NULL
    ALTER TABLE dbo.ShopOrderEvents ADD AddressAfter nvarchar(500) NULL;
COMMIT;

GO

GO
-- SOURCE: SeedStorefrontDemo.sql
-- Local demo catalogue: illustrative prices, not market quotations.
-- Only populates an empty catalogue; existing products are never replaced.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM dbo.Products WITH (UPDLOCK,HOLDLOCK))
BEGIN
 INSERT dbo.Products(Name,Category,Description,ImageUrl,Price,Stock,IsActive) VALUES
 (N'[MẪU] Điện thoại 128 GB',N'Điện thoại',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Điện thoại phục vụ học tập và liên lạc; bộ nhớ 128 GB, màn hình 6,5 inch, sạc USB-C.',N'/images/products/phone.svg',7990000,20,1),
 (N'[MẪU] Tai nghe Bluetooth kèm hộp sạc',N'Âm thanh',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Tai nghe không dây kèm hộp sạc, kết nối Bluetooth, có micro cho cuộc gọi.',N'/images/products/earbuds.svg',2490000,25,1),
 (N'[MẪU] Tai nghe chụp tai có micro',N'Âm thanh',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Tai nghe chụp tai có dây 3,5 mm, micro dùng cho học trực tuyến.',N'/images/products/headphones.svg',1290000,18,1),
 (N'[MẪU] Laptop học tập 15 inch',N'Máy tính',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Laptop mô phỏng cho học tập: màn hình 15,6 inch, RAM 8 GB, SSD 256 GB.',N'/images/products/laptop.svg',15990000,12,1),
 (N'[MẪU] Đồng hồ thông minh dây silicon',N'Thiết bị đeo',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Đồng hồ mô phỏng có hiển thị thông báo, đếm bước chân và dây silicon.',N'/images/products/watch.svg',1990000,30,1),
 (N'[MẪU] Máy tính bảng Wi-Fi 64 GB',N'Máy tính bảng',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Máy tính bảng mô phỏng có màn hình 10 inch, bộ nhớ 64 GB và Wi-Fi, phục vụ đọc tài liệu.',N'/images/products/tablet.svg',5990000,15,1);
END;
COMMIT;

GO

GO
-- SOURCE: UpdateDemoCatalog.sql
-- Chuẩn hóa 6 sản phẩm do SeedStorefrontDemo.sql phiên bản cũ tạo.
-- Chỉ đổi tên và mô tả của dữ liệu mẫu chưa được người dùng biên tập.
-- Không đổi giá, tồn kho, ảnh, ID hoặc tên/giá lưu trong chi tiết đơn hàng cũ.
-- Chạy sau UpgradeCommerce.sql. Chạy lại không cập nhật thêm.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @Samples TABLE (OldName nvarchar(160), NewName nvarchar(160), Description nvarchar(4000));
INSERT @Samples VALUES
 (N'Điện thoại',N'[MẪU] Điện thoại 128 GB',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Điện thoại phục vụ học tập và liên lạc; bộ nhớ 128 GB, màn hình 6,5 inch, sạc USB-C.'),
 (N'Tai nghe AirPods',N'[MẪU] Tai nghe Bluetooth kèm hộp sạc',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Tai nghe không dây kèm hộp sạc, kết nối Bluetooth, có micro cho cuộc gọi.'),
 (N'Tai nghe chụp tai',N'[MẪU] Tai nghe chụp tai có micro',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Tai nghe chụp tai có dây 3,5 mm, micro dùng cho học trực tuyến.'),
 (N'Laptop',N'[MẪU] Laptop học tập 15 inch',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Laptop mô phỏng cho học tập: màn hình 15,6 inch, RAM 8 GB, SSD 256 GB.'),
 (N'Đồng hồ thông minh',N'[MẪU] Đồng hồ thông minh dây silicon',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Đồng hồ mô phỏng có hiển thị thông báo, đếm bước chân và dây silicon.'),
 (N'Máy tính bảng',N'[MẪU] Máy tính bảng Wi-Fi 64 GB',N'Sản phẩm mô phỏng cho đồ án; thông số và giá là dữ liệu giả định, không phải báo giá thực tế.
Máy tính bảng mô phỏng có màn hình 10 inch, bộ nhớ 64 GB và Wi-Fi, phục vụ đọc tài liệu.');
UPDATE p
SET Name=s.NewName, Description=s.Description
OUTPUT INSERTED.Id, INSERTED.Name
FROM dbo.Products p JOIN @Samples s ON p.Name=s.OldName
WHERE p.Description LIKE N'Sản phẩm mẫu. Giá minh họa để trải nghiệm giao diện và luồng đặt hàng, không phải báo giá thương mại.%';
COMMIT;

GO

GO
-- SOURCE: UpdateRealProductCatalog.sql
-- Real product descriptions and manufacturer images for the six storefront samples.
-- Run after SeedStorefrontDemo.sql and UpdateDemoCatalog.sql.
-- Copy TechNews/wwwroot/images/products/official with the application first.
-- Matches the exact sample name and image; preserves edited products, IDs, prices,
-- stock, visibility and order-item snapshots. Safe to run again (zero matches).
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @Catalog TABLE(OldName nvarchar(160),OldImage nvarchar(500),Name nvarchar(160),Category nvarchar(80),Description nvarchar(4000),ImageUrl nvarchar(500));
INSERT @Catalog VALUES
(N'[MẪU] Điện thoại 128 GB',N'/images/products/phone.svg',N'Apple iPhone 16 128 GB',N'Điện thoại',N'iPhone 16 sử dụng chip Apple A18 và bộ nhớ 128 GB, phù hợp cho liên lạc, chụp ảnh và các ứng dụng hằng ngày.
• Màn hình OLED Super Retina XDR 6,1 inch, độ phân giải 2556 × 1179.
• Camera chính Fusion 48 MP và camera góc siêu rộng 12 MP.
• Có Dynamic Island, Face ID và nút Điều Khiển Camera.
• Kết nối USB-C, hỗ trợ Wi-Fi 7 và Bluetooth 5.3.
Ảnh hãng giới thiệu các lựa chọn màu của dòng máy.',N'/images/products/official/apple-iphone-16.png'),
(N'[MẪU] Tai nghe Bluetooth kèm hộp sạc',N'/images/products/earbuds.svg',N'Apple AirPods 4 – hộp sạc USB-C',N'Âm thanh',N'AirPods 4 bản tiêu chuẩn có thiết kế không dây, chip H2 và hộp sạc USB-C. Đây là phiên bản không có chống ồn chủ động (ANC).
• Có tính năng Cách Ly Giọng Nói và Âm Thanh Không Gian cá nhân hóa trên thiết bị tương thích.
• Nghe nhạc tối đa 5 giờ mỗi lần sạc; tổng thời lượng tối đa 30 giờ khi dùng cùng hộp sạc theo điều kiện thử nghiệm của Apple.
• Tai nghe và hộp sạc đạt mức kháng bụi, mồ hôi và nước IP54; không dùng để bơi.
Thời lượng sử dụng thực tế phụ thuộc âm lượng, thiết bị và cách sử dụng.',N'/images/products/official/apple-airpods-4.png'),
(N'[MẪU] Tai nghe chụp tai có micro',N'/images/products/headphones.svg',N'Sony WH-CH520 – tai nghe không dây màu đen',N'Âm thanh',N'Sony WH-CH520 là tai nghe không dây với kiểu đeo trên tai, phù hợp nghe nhạc và đàm thoại.
• Màng loa 30 mm, hỗ trợ xử lý âm thanh DSEE.
• Bluetooth 5.2, hỗ trợ codec SBC và AAC.
• Sạc qua USB-C, thời gian sạc đầy khoảng 3 giờ theo thông số hãng.
• Có điều khiển âm lượng và micro cho cuộc gọi.
• Không có cổng âm thanh đầu vào để nghe bằng dây.
Ảnh sản phẩm là phiên bản màu đen.',N'/images/products/official/sony-wh-ch520-black.jpg'),
(N'[MẪU] Laptop học tập 15 inch',N'/images/products/laptop.svg',N'MacBook Air M2 13,6 inch – 8 GB / 256 GB',N'Máy tính',N'MacBook Air M2 (2022), cấu hình bộ nhớ hợp nhất 8 GB và SSD 256 GB, dành cho học tập và công việc di động.
• Chip Apple M2 với CPU 8 lõi và GPU 8 lõi.
• Màn hình Liquid Retina 13,6 inch, độ phân giải 2560 × 1664, độ sáng 500 nit.
• Sạc MagSafe 3, hai cổng Thunderbolt / USB 4 và giắc tai nghe 3,5 mm.
• Có Touch ID và camera FaceTime HD 1080p.
Ảnh giới thiệu của Apple thể hiện máy màu Midnight.',N'/images/products/official/apple-macbook-air-m2.jpg'),
(N'[MẪU] Đồng hồ thông minh dây silicon',N'/images/products/watch.svg',N'Xiaomi Smart Band 9',N'Thiết bị đeo',N'Xiaomi Smart Band 9 là vòng đeo tay thông minh kết nối với ứng dụng Mi Fitness.
• Màn hình cảm ứng AMOLED 1,62 inch, độ phân giải 192 × 490, độ sáng tối đa 1200 nit.
• Pin 233 mAh, sạc từ tính; thời gian sử dụng thông thường lên đến 21 ngày theo điều kiện thử nghiệm của hãng.
• Có cảm biến nhịp tim quang học, gia tốc, con quay hồi chuyển và ánh sáng xung quanh.
• Kháng nước 5 ATM; hỗ trợ điện thoại Android 8.0 hoặc iOS 12.0 trở lên.
• Dây đeo TPU. Ảnh hãng giới thiệu các lựa chọn màu.
Thiết bị theo dõi vận động và sức khỏe không thay thế thiết bị chẩn đoán y tế.',N'/images/products/official/xiaomi-smart-band-9.png'),
(N'[MẪU] Máy tính bảng Wi-Fi 64 GB',N'/images/products/tablet.svg',N'Apple iPad Gen 10 Wi-Fi 64 GB',N'Máy tính bảng',N'iPad thế hệ thứ 10 (2022), phiên bản Wi-Fi 64 GB, hỗ trợ học tập, đọc tài liệu và giải trí.
• Chip A14 Bionic, CPU 6 lõi và GPU 4 lõi.
• Màn hình Liquid Retina 10,9 inch, độ phân giải 2360 × 1640 và True Tone.
• Camera sau góc rộng 12 MP, camera trước nằm ngang.
• Touch ID tích hợp ở nút nguồn; cổng kết nối USB-C.
• Hỗ trợ Apple Pencil USB-C và Apple Pencil thế hệ 1 với bộ chuyển đổi phù hợp; phụ kiện bán riêng.
Ảnh hãng giới thiệu các lựa chọn màu của dòng iPad này.',N'/images/products/official/apple-ipad-gen-10.png');
UPDATE p SET Name=c.Name, Category=c.Category, Description=c.Description, ImageUrl=c.ImageUrl
OUTPUT INSERTED.Id, INSERTED.Name
FROM dbo.Products p JOIN @Catalog c ON p.Name=c.OldName AND p.ImageUrl=c.OldImage;
COMMIT;

GO
SELECT COUNT(*) AS TablesCreated FROM sys.tables; SELECT COUNT(*) AS Articles FROM dbo.article; SELECT COUNT(*) AS Products FROM dbo.Products; PRINT 'TechNews demo database ready. Login: admin / 12345 or customer / 12345';
