IF DB_NAME() NOT LIKE 'TechNews_Verification[_]%' THROW 50001, 'Verification database only', 1;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @author int=(SELECT id FROM dbo.[user] WHERE user_login='qa-admin');
IF @author IS NULL THROW 50002, 'QA fixture required', 1;
UPDATE dbo.article SET article_status=0,EditorialState='Draft',ScheduledUtc=NULL WHERE article_title LIKE N'QA[_]%';
IF NOT EXISTS(SELECT 1 FROM dbo.article WHERE source=N'TechNews Demo' AND article_title=N'TechNews: đọc tin công nghệ và mua sắm trực tuyến')
INSERT dbo.article(article_title,article_description,article_content,article_thumb,article_date,category_id,author_id,article_priority,view_counts,like_counts,article_status,source,EditorialState)
VALUES(N'TechNews: đọc tin công nghệ và mua sắm trực tuyến',N'Bài mẫu giới thiệu hai nhóm chức năng của đồ án: tin tức công nghệ và thương mại điện tử COD.',N'<p><em>Bài viết minh họa phục vụ báo cáo đồ án, không phải bản tin sự kiện.</em></p><h2>Đọc tin theo chủ đề</h2><p>TechNews tổ chức bài viết theo chuyên mục và tag. Người đọc có thể tìm kiếm, lưu bài và gửi bình luận. Nội dung được biên tập và duyệt trước khi xuất bản.</p><h2>Tìm hiểu sản phẩm công nghệ</h2><p>Cửa hàng giới thiệu sản phẩm mẫu với hình ảnh, thông tin, giá và tồn kho. Người dùng thêm sản phẩm vào giỏ, kiểm tra lại số lượng và đặt hàng thanh toán khi nhận hàng.</p><h2>Theo dõi đơn hàng</h2><p>Sau khi đặt hàng, người mua theo dõi trạng thái và lịch sử. Đơn được hủy trước khi giao cần lý do; hệ thống hoàn lại số lượng tồn kho. Toàn bộ sản phẩm, giá và giao dịch minh họa trong báo cáo chỉ dùng cho học tập.</p>',N'/images/tech-seed/laptop.svg','20261124',8,@author,3,0,0,1,N'TechNews Demo','Published');
COMMIT;
