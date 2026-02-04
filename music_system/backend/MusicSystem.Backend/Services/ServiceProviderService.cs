using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using MusicSystem.Backend.Models;

namespace MusicSystem.Backend.Services
{
    public interface IServiceProviderService
    {
        Task<List<ServiceModel>> GetAllServicesAsync();
        Task<List<ServiceModel>> GetServicesByProviderAsync(string providerId);
        Task<ServiceModel?> GetServiceByIdAsync(string serviceId);
        Task RegisterServiceAsync(ServiceModel service);
        Task UpdateServiceAsync(ServiceModel service);
        Task UpdateStatusAsync(string serviceId, string status);
        Task DeleteServiceAsync(string serviceId);
    }

    public class LocalServiceProviderService : IServiceProviderService
    {
        private const string DataFilePath = "Data/services.json";
        private readonly string _fullPath;

        public LocalServiceProviderService()
        {
            _fullPath = Path.Combine(Directory.GetCurrentDirectory(), DataFilePath);
            var directory = Path.GetDirectoryName(_fullPath);
            if (directory != null && !Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }
        }

        private async Task<List<ServiceModel>> LoadAllAsync()
        {
            if (!File.Exists(_fullPath)) return new List<ServiceModel>();

            var json = await File.ReadAllTextAsync(_fullPath);
            return JsonSerializer.Deserialize<List<ServiceModel>>(json) ?? new List<ServiceModel>();
        }

        private async Task SaveAllAsync(List<ServiceModel> services)
        {
            var json = JsonSerializer.Serialize(services, new JsonSerializerOptions { WriteIndented = true });
            await File.WriteAllTextAsync(_fullPath, json);
        }

        public async Task<List<ServiceModel>> GetAllServicesAsync()
        {
            return await LoadAllAsync();
        }

        public async Task<List<ServiceModel>> GetServicesByProviderAsync(string providerId)
        {
            var all = await LoadAllAsync();
            return all.Where(s => s.ProviderId == providerId).ToList();
        }

        public async Task<ServiceModel?> GetServiceByIdAsync(string serviceId)
        {
            var all = await LoadAllAsync();
            return all.FirstOrDefault(s => s.Id == serviceId);
        }

        public async Task RegisterServiceAsync(ServiceModel service)
        {
            var all = await LoadAllAsync();
            all.Add(service);
            await SaveAllAsync(all);
        }

        public async Task UpdateServiceAsync(ServiceModel service)
        {
            var all = await LoadAllAsync();
            var index = all.FindIndex(s => s.Id == service.Id);
            if (index != -1)
            {
                all[index] = service;
                await SaveAllAsync(all);
            }
        }

        public async Task UpdateStatusAsync(string serviceId, string status)
        {
            var all = await LoadAllAsync();
            var service = all.FirstOrDefault(s => s.Id == serviceId);
            if (service != null)
            {
                service.Status = status;
                await SaveAllAsync(all);
            }
        }

        public async Task DeleteServiceAsync(string serviceId)
        {
            var all = await LoadAllAsync();
            var service = all.FirstOrDefault(s => s.Id == serviceId);
            if (service != null)
            {
                all.Remove(service);
                await SaveAllAsync(all);
            }
        }
    }
}
