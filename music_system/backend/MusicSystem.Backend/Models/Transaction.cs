using System;

namespace MusicSystem.Backend.Models
{
    public enum TransactionType
    {
        Credit,
        Debit,
        PointExchange,
        PixIn,
        PixOut,
        MusicRequest,
        LiveTip,
        Contract
    }

    public enum TransactionStatus
    {
        Pending,
        Completed,
        Cancelled,
        Escrow
    }

    public class Transaction
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public required string WalletId { get; set; }
        public required decimal Amount { get; set; }
        public long PointsChange { get; set; } = 0;
        public TransactionType Type { get; set; }
        public TransactionStatus Status { get; set; } = TransactionStatus.Completed;
        public string? Description { get; set; }
        public string? ExternalReference { get; set; } // MP Payment ID, etc.
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
