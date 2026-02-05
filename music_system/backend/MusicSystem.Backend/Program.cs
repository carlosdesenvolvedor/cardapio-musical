using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

builder.Services.AddControllers();

// Configure EF Core with PostgreSQL
builder.Services.AddDbContext<MusicSystem.Backend.Data.AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("PostgreSql")));

// Configure Firebase JWT Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = "https://securetoken.google.com/music-system-421ee";
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = "https://securetoken.google.com/music-system-421ee",
            ValidateAudience = true,
            ValidAudience = "music-system-421ee",
            ValidateLifetime = true
        };
    });

// Register Storage Service
builder.Services.AddSingleton<MusicSystem.Backend.Services.IStorageService, MusicSystem.Backend.Services.MinioStorageService>();

// Register Wallet Service
builder.Services.AddSingleton<MusicSystem.Backend.Services.IWalletService, MusicSystem.Backend.Services.WalletService>();

// Register Service Provider Service
builder.Services.AddSingleton<MusicSystem.Backend.Services.IServiceProviderService, MusicSystem.Backend.Services.LocalServiceProviderService>();

// Register Profile Service (Scoped because it uses DbContext)
builder.Services.AddScoped<MusicSystem.Backend.Services.IProfileService, MusicSystem.Backend.Services.ProfileService>();

// Register Migration Service
builder.Services.AddScoped<MusicSystem.Backend.Services.IMigrationService, MusicSystem.Backend.Services.MigrationService>();

// Register Chat Service
builder.Services.AddSingleton<MusicSystem.Backend.Services.IChatService, MusicSystem.Backend.Services.MongoChatService>();

// Add SignalR
builder.Services.AddSignalR();

// Configure Kestrel limits for large uploads (500MB)
builder.Services.Configure<Microsoft.AspNetCore.Server.Kestrel.Core.KestrelServerOptions>(options =>
{
    options.Limits.MaxRequestBodySize = 524288000; // 500 MB
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.SetIsOriginAllowed(_ => true) // Allow any origin with credentials
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials()
              .WithExposedHeaders("Content-Disposition");
    });
});



var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

// Automatically apply migrations
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<MusicSystem.Backend.Data.AppDbContext>();
    // Wait a bit for postgres container to be ready in production docker flow
    // (In a more robust setup, we'd use a retry policy)
    db.Database.Migrate();
}

app.MapControllers();
app.MapHub<MusicSystem.Backend.Hubs.ChatHub>("/chathub");




// app.UseHttpsRedirection();

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
{
    var forecast =  Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
    return forecast;
})
.WithName("GetWeatherForecast");

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
