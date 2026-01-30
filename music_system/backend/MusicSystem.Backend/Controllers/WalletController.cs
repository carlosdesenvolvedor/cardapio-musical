using Microsoft.AspNetCore.Mvc;
using MusicSystem.Backend.Services;
using MusicSystem.Backend.Models;
using System.Threading.Tasks;

namespace MusicSystem.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class WalletController : ControllerBase
    {
        private readonly IWalletService _walletService;

        public WalletController(IWalletService walletService)
        {
            _walletService = walletService;
        }

        [HttpGet("{userId}")]
        public async Task<IActionResult> GetWallet(string userId)
        {
            var wallet = await _walletService.GetOrCreateWalletAsync(userId);
            return Ok(wallet);
        }

        [HttpGet("{userId}/transactions")]
        public async Task<IActionResult> GetTransactions(string userId)
        {
            var wallet = await _walletService.GetOrCreateWalletAsync(userId);
            var transactions = await _walletService.GetTransactionsAsync(wallet.Id);
            return Ok(transactions);
        }

        [HttpPost("pix/generate")]
        public async Task<IActionResult> GeneratePix([FromBody] PixRequest request)
        {
            var payload = await _walletService.GeneratePixPaymentAsync(request.UserId, request.Amount);
            return Ok(new { pixPayload = payload });
        }
    }

    public class PixRequest
    {
        public required string UserId { get; set; }
        public decimal Amount { get; set; }
    }
}
