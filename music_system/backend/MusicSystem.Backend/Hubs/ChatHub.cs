using Microsoft.AspNetCore.SignalR;
using MusicSystem.Backend.Models;

namespace MusicSystem.Backend.Hubs
{
    public class ChatHub : Hub
    {
        // Join a private conversation group
        public async Task JoinConversation(string currentUserId, string otherUserId)
        {
            var pair = new List<string> { currentUserId, otherUserId };
            pair.Sort();
            string groupName = $"chat_{pair[0]}_{pair[1]}";
            await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
        }

        // Leave a conversation group
        public async Task LeaveConversation(string currentUserId, string otherUserId)
        {
            var pair = new List<string> { currentUserId, otherUserId };
            pair.Sort();
            string groupName = $"chat_{pair[0]}_{pair[1]}";
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);
        }

        // Send message to the specific group
        public async Task SendMessageToGroup(string currentUserId, string otherUserId, ChatMessage message)
        {
            var pair = new List<string> { currentUserId, otherUserId };
            pair.Sort();
            string groupName = $"chat_{pair[0]}_{pair[1]}";
            await Clients.Group(groupName).SendAsync("ReceiveMessage", message);
            
            // Also notify the receiver globally if they're not in the group
            await Clients.User(otherUserId).SendAsync("NewMessageNotification", message);
        }
    }
}
