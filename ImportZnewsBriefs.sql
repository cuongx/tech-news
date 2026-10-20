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
