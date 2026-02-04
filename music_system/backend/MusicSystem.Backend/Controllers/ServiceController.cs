using Microsoft.AspNetCore.Mvc;
using MusicSystem.Backend.Services;
using MusicSystem.Backend.Models;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Text.Json;

namespace MusicSystem.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ServiceController : ControllerBase
    {
        private readonly IServiceProviderService _serviceProviderService;

        public ServiceController(IServiceProviderService serviceProviderService)
        {
            _serviceProviderService = serviceProviderService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] ServiceModel service)
        {
            await _serviceProviderService.RegisterServiceAsync(service);
            return Ok(new { message = "Service registered successfully" });
        }

        [HttpGet("all")]
        public async Task<IActionResult> GetAll()
        {
            var services = await _serviceProviderService.GetAllServicesAsync();
            return Ok(services);
        }

        [HttpGet("list/{providerId}")]
        public async Task<IActionResult> GetList(string providerId)
        {
            var services = await _serviceProviderService.GetServicesByProviderAsync(providerId);
            return Ok(services);
        }

        [HttpPut("status/{serviceId}")]
        public async Task<IActionResult> UpdateStatus(string serviceId, [FromBody] JsonElement body)
        {
            if (body.TryGetProperty("status", out var statusProperty))
            {
                var status = statusProperty.GetString();
                if (!string.IsNullOrEmpty(status))
                {
                    await _serviceProviderService.UpdateStatusAsync(serviceId, status);
                    return Ok(new { message = "Status updated successfully" });
                }
            }
            return BadRequest("Status is required");
        }

        [HttpPut("update")]
        public async Task<IActionResult> Update([FromBody] ServiceModel service)
        {
            await _serviceProviderService.UpdateServiceAsync(service);
            return Ok(new { message = "Service updated successfully" });
        }

        [HttpDelete("{serviceId}")]
        public async Task<IActionResult> Delete(string serviceId)
        {
            await _serviceProviderService.DeleteServiceAsync(serviceId);
            return Ok(new { message = "Service deleted successfully" });
        }
    }
}
