using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using TechNews.Models;

namespace TechNews.Services
{
    public class AddressWard { public int Code { get; set; } public string Name { get; set; } }
    public class AddressProvince : AddressWard { public List<AddressWard> Wards { get; set; } }

    // A versioned local snapshot: checkout never calls a third-party address API.
    public class AddressCatalog
    {
        public IReadOnlyList<AddressProvince> Provinces { get; }
        public AddressCatalog(IWebHostEnvironment env)
        {
            var json = File.ReadAllText(Path.Combine(env.ContentRootPath, "Data", "vietnam-addresses.json"));
            Provinces = JsonSerializer.Deserialize<List<AddressProvince>>(json, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            if (Provinces == null || Provinces.Count == 0 || Provinces.Any(p => p.Wards == null || p.Wards.Count == 0))
                throw new InvalidDataException("Address catalogue is empty or invalid.");
        }

        public string ValidateAndFormat(ShippingAddressInput input, ModelStateDictionary state)
        {
            var province = Provinces.FirstOrDefault(p => p.Code == input.ProvinceCode);
            var ward = province?.Wards.FirstOrDefault(w => w.Code == input.WardCode);
            if (province == null) state.AddModelError(nameof(input.ProvinceCode), "Chọn tỉnh/thành phố trong danh sách.");
            if (ward == null) state.AddModelError(nameof(input.WardCode), "Phường/xã không thuộc tỉnh/thành phố đã chọn.");
            input.Address = Regex.Replace(input.Address ?? "", @"\s+", " ").Trim();
            if (input.Address.Length < 5 || input.Address.Length > 300 || !input.Address.Any(char.IsLetterOrDigit) || input.Address.Any(char.IsControl))
                state.AddModelError(nameof(input.Address), "Nhập địa chỉ chi tiết từ 5 đến 300 ký tự, có số nhà/tên đường hoặc thôn/xóm.");
            if (!state.IsValid) return null;
            var full = $"{input.Address}, {ward.Name}, {province.Name}";
            if (full.Length > 500) { state.AddModelError(nameof(input.Address), "Địa chỉ nhận hàng quá dài."); return null; }
            return full;
        }
    }
}
