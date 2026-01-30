using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MusicSystem.Backend.Models;
using MercadoPago.Client.Payment;
using MercadoPago.Config;
using MercadoPago.Resource.Payment;
using Microsoft.Extensions.Configuration;

namespace MusicSystem.Backend.Services
{
    public class WalletService : IWalletService
    {
        private readonly IConfiguration _configuration;
        // Mock storage (Persistence will be handled by DB in next step)
        private static readonly List<Wallet> _wallets = new();
        private static readonly List<Transaction> _transactions = new();

        public WalletService(IConfiguration configuration)
        {
            _configuration = configuration;
            var accessToken = _configuration["MercadoPago:AccessToken"];
            if (!string.IsNullOrEmpty(accessToken))
            {
                MercadoPagoConfig.AccessToken = accessToken;
            }
        }

        public Task<Wallet> GetOrCreateWalletAsync(string userId)
        {
            var wallet = _wallets.FirstOrDefault(w => w.UserId == userId);
            if (wallet == null)
            {
                wallet = new Wallet { UserId = userId };
                _wallets.Add(wallet);
            }
            return Task.FromResult(wallet);
        }

        public Task<IEnumerable<Transaction>> GetTransactionsAsync(string walletId)
        {
            return Task.FromResult(_transactions.Where(t => t.WalletId == walletId).OrderByDescending(t => t.CreatedAt).AsEnumerable());
        }

        public async Task<bool> ProcessTransactionAsync(string userId, decimal amount, TransactionType type, string description, long points = 0)
        {
            var wallet = await GetOrCreateWalletAsync(userId);
            
            if (amount < 0 && wallet.Balance < Math.Abs(amount))
                return false;

            wallet.Balance += amount;
            wallet.Points += points;
            wallet.UpdatedAt = DateTime.UtcNow;

            _transactions.Add(new Transaction
            {
                WalletId = wallet.Id,
                Amount = amount,
                PointsChange = points,
                Type = type,
                Description = description,
                Status = TransactionStatus.Completed
            });

            return true;
        }

        public async Task<string> GeneratePixPaymentAsync(string userId, decimal amount)
        {
            try 
            {
                var client = new PaymentClient();
                var request = new PaymentCreateRequest
                {
                    TransactionAmount = amount,
                    Description = "Recarga de Carteira - MixArt",
                    PaymentMethodId = "pix",
                    Payer = new PaymentPayerRequest
                    {
                        Email = "test_user_payer@testuser.com", // Em produção, usar email do usuário
                    },
                    Metadata = new Dictionary<string, object>
                    {
                        { "user_id", userId }
                    }
                };

                var payment = await client.CreateAsync(request);
                
                if (payment?.PointOfInteraction?.TransactionData?.QrCode != null)
                {
                    // Log transaction as pending
                    var wallet = await GetOrCreateWalletAsync(userId);
                    _transactions.Add(new Transaction
                    {
                        WalletId = wallet.Id,
                        Amount = amount,
                        Type = TransactionType.PixIn,
                        Status = TransactionStatus.Pending,
                        Description = "Aguardando pagamento Pix",
                        ExternalReference = payment.Id.ToString()
                    });

                    return payment.PointOfInteraction.TransactionData.QrCode;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Erro ao gerar Pix MP: {ex.Message}");
            }

            return "error_generating_pix";
        }

        public Task<bool> ConfirmPixPaymentAsync(string paymentId)
        {
            // Webhook logic will go here
            return Task.FromResult(true);
        }
    }
}
