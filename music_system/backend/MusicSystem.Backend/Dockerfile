# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["MusicSystem.Backend/MusicSystem.Backend.csproj", "MusicSystem.Backend/"]
RUN dotnet restore "MusicSystem.Backend/MusicSystem.Backend.csproj"
COPY . .
WORKDIR "/src/MusicSystem.Backend"
RUN dotnet build "MusicSystem.Backend.csproj" -c Release -o /app/build

# Publish Stage
FROM build AS publish
RUN dotnet publish "MusicSystem.Backend.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Final Stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "MusicSystem.Backend.dll"]
