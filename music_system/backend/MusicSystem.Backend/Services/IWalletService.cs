using System.Collections.Generic;
using System.Threading.Tasks;
using MusicSystem.Backend.Models;

namespace MusicSystem.Backend.Services
{
    public interface IWalletService
    {
        Task<Wallet> GetOrCreateWalletAsync(string userId);
        Task<IEnumerable<Transaction>> GetTransactionsAsync(string walletId);
        Task<bool> ProcessTransactionAsync(string userId, decimal amount, TransactionType type, string description, long points = 0);
        Task<string> GeneratePixPaymentAsync(string userId, decimal amount);
        Task<bool> ConfirmPixPaymentAsync(string paymentId);
    }
}
