using System;

namespace MusicSystem.Backend.Models
{
    public class Wallet
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public required string UserId { get; set; }
        public decimal Balance { get; set; } = 0;
        public long Points { get; set; } = 0;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
