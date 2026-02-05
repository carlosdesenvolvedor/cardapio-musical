namespace MusicSystem.Backend.Services;

public interface IMigrationService
{
    Task<int> MigrateUsersFromFirestoreAsync();
}
