using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using System;
using System.IO;
using System.Linq;
namespace TechNews.Services
{
    public class FileService
    {
        private readonly IWebHostEnvironment env;
        public FileService(IWebHostEnvironment env) { this.env = env; }
        public string Upload(IFormFile file)
        {
            if (file == null || file.Length == 0 || file.Length > 5 * 1024 * 1024)
                throw new ArgumentException("Chọn ảnh có dung lượng từ 1 byte đến 5 MB.");
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            using var input = file.OpenReadStream();
            var header = new byte[12];
            var count = input.Read(header, 0, header.Length);
            bool valid = count >= 8 && (
                ((extension == ".jpg" || extension == ".jpeg") && header[0] == 255 && header[1] == 216 && header[2] == 255) ||
                (extension == ".png" && header.Take(8).SequenceEqual(new byte[] {137,80,78,71,13,10,26,10})) ||
                (extension == ".gif" && System.Text.Encoding.ASCII.GetString(header,0,6) is "GIF87a" or "GIF89a") ||
                (extension == ".webp" && count == 12 && System.Text.Encoding.ASCII.GetString(header,0,4) == "RIFF" && System.Text.Encoding.ASCII.GetString(header,8,4) == "WEBP"));
            if (!valid) throw new ArgumentException("Chỉ chấp nhận ảnh JPEG, PNG, GIF hoặc WebP đúng định dạng.");
            var folder = Path.Combine(env.WebRootPath, "uploads");
            Directory.CreateDirectory(folder);
            var name = Guid.NewGuid().ToString("N") + extension;
            using (var output = new FileStream(Path.Combine(folder,name), FileMode.CreateNew)) file.CopyTo(output);
            return "/uploads/" + name;
        }
    }
}
