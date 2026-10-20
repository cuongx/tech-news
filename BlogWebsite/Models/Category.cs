using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
#nullable disable
namespace BlogWebsite.Models
{
    [Table("category")]
    public partial class Category
    {
        public Category() { Articles = new HashSet<Article>(); }
        [Key]
        [Column("id")]
        public int Id { get; set; }
        [Column("category_name")]
        [Required(ErrorMessage = "Vui lòng nhập tên chuyên mục.")]
        [StringLength(50)]
        [Display(Name = "Tên chuyên mục")]
        public string CategoryName { get; set; }
        [Column("category_description")]
        [StringLength(100)]
        [Display(Name = "Mô tả")]
        public string CategoryDescription { get; set; }
        [Column("show_on_menu")]
        [Display(Name = "Hiện trên menu")]
        public bool ShowOnMenu { get; set; } = true;
        [Column("display_order")]
        [Range(0, 999, ErrorMessage = "Thứ tự phải từ 0 đến 999.")]
        [Display(Name = "Thứ tự hiển thị")]
        public int DisplayOrder { get; set; } = 100;
        [InverseProperty(nameof(Article.Category))]
        public virtual ICollection<Article> Articles { get; set; }
    }
}
