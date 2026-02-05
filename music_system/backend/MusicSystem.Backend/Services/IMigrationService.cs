namespace MusicSystem.Backend.Services;

public interface IMigrationService
{
    Task<int> MigrateUsersFromFirestoreAsync();
    Task<int> MigratePostsFromFirestoreAsync();
    Task<int> MigrateStoriesFromFirestoreAsync();
}
