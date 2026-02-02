using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace MusicSystem.Backend.Models
{
    public class ServiceModel
    {
        [JsonPropertyName("id")]
        public string Id { get; set; } = string.Empty;

        [JsonPropertyName("providerId")]
        public string ProviderId { get; set; } = string.Empty;

        [JsonPropertyName("name")]
        public string Name { get; set; } = string.Empty;

        [JsonPropertyName("description")]
        public string Description { get; set; } = string.Empty;

        [JsonPropertyName("category")]
        public string Category { get; set; } = string.Empty; // Store as string for flexibility

        [JsonPropertyName("basePrice")]
        public double BasePrice { get; set; }

        [JsonPropertyName("priceDescription")]
        public string PriceDescription { get; set; } = string.Empty;

        [JsonPropertyName("status")]
        public string Status { get; set; } = "pending";

        [JsonPropertyName("technicalDetails")]
        public JsonElement TechnicalDetails { get; set; }

        [JsonPropertyName("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
