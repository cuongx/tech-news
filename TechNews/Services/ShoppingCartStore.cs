using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text.Json;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Http;
namespace TechNews.Services
{
    public class ShoppingCartStore
    {
        private const string CookieName = "TechNews.Cart";
        private readonly IHttpContextAccessor accessor;
        private readonly IDataProtector protector;
        private CartState state;
        public ShoppingCartStore(IHttpContextAccessor accessor, IDataProtectionProvider provider)
        { this.accessor = accessor; protector = provider.CreateProtector("TechNews.ShoppingCart.v1"); }
        private HttpContext Context => accessor.HttpContext;
        private CartState State
        {
            get
            {
                if (state != null) return state;
                state = new CartState();
                var cookie = Context.Request.Cookies[CookieName];
                if (!string.IsNullOrEmpty(cookie))
                {
                    try
                    {
                        var saved = JsonSerializer.Deserialize<CartState>(protector.Unprotect(cookie));
                        if (saved != null && saved.ExpiresUtc > DateTime.UtcNow && saved.Quantities != null && saved.Prices != null
                            && saved.Quantities.Count <= 50 && saved.Quantities.All(x => x.Key > 0 && x.Value >= 1 && x.Value <= 99)) state = saved;
                    }
                    catch (CryptographicException) { }
                    catch (JsonException) { }
                    catch (FormatException) { }
                }
                else
                {
                    // Preserve carts created by the earlier session-based version.
                    try
                    {
                        var legacy = JsonSerializer.Deserialize<Dictionary<int,int>>(Context.Session.GetString("ShopCart") ?? "{}");
                        if (legacy != null && legacy.Count <= 50 && legacy.All(x => x.Key > 0 && x.Value >= 1 && x.Value <= 99)) state.Quantities = legacy;
                    }
                    catch (JsonException) { }
                }
                return state;
            }
        }
        public Dictionary<int,int> Read() => new Dictionary<int,int>(State.Quantities);
        public int Count => State.Quantities.Values.Sum();
        public decimal? PreviousPrice(int id) => State.Prices.TryGetValue(id, out var price) ? price : (decimal?)null;
        public void RememberPrice(int id, decimal price) => State.Prices[id] = price;
        public void Save(Dictionary<int,int> quantities)
        {
            State.Quantities = new Dictionary<int,int>(quantities);
            State.Prices = State.Prices.Where(p => quantities.ContainsKey(p.Key)).ToDictionary(p => p.Key, p => p.Value);
            State.ExpiresUtc = DateTime.UtcNow.AddDays(30);
            var options = new CookieOptions { HttpOnly = true, Secure = Context.Request.IsHttps, SameSite = SameSiteMode.Lax,
                IsEssential = true, Path = "/", Expires = new DateTimeOffset(State.ExpiresUtc) };
            if (quantities.Count == 0) Context.Response.Cookies.Delete(CookieName, options);
            else Context.Response.Cookies.Append(CookieName, protector.Protect(JsonSerializer.Serialize(State)), options);
            Context.Session.Remove("ShopCart");
            Context.Session.Remove("CheckoutToken");
            Context.Session.Remove("CheckoutPrices");
        }
        public class CartState
        {
            public Dictionary<int,int> Quantities { get; set; } = new Dictionary<int,int>();
            public Dictionary<int,decimal> Prices { get; set; } = new Dictionary<int,decimal>();
            public DateTime ExpiresUtc { get; set; } = DateTime.UtcNow.AddDays(30);
        }
    }
}
