import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:music_system/features/community/data/models/post_model.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new post
  Future<void> createPost(Post post) async {
    await _firestore.collection('posts').add(post.toFirestore());
  }

  // Stream of all posts
  Stream<List<Post>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  // Like / Unlike a post
  Future<void> toggleLike(String postId, String userId) async {
    final docRef = _firestore.collection('posts').doc(postId);
    final doc = await docRef.get();
    
    if (doc.exists) {
      final likes = List<String>.from(doc.data()?['likes'] ?? []);
      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }
      await docRef.update({'likes': likes});
    }
  }

  // Follow / Unfollow a user
  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    final targetUserRef = _firestore.collection('users').doc(targetUserId);

    final currentUserDoc = await currentUserRef.get();
    final following = List<String>.from(currentUserDoc.data()?['following'] ?? []);

    if (following.contains(targetUserId)) {
      // Unfollow
      await currentUserRef.update({
        'following': FieldValue.arrayRemove([targetUserId])
      });
      await targetUserRef.update({
        'followers': FieldValue.arrayRemove([currentUserId])
      });
    } else {
      // Follow
      await currentUserRef.update({
        'following': FieldValue.arrayUnion([targetUserId])
      });
      await targetUserRef.update({
        'followers': FieldValue.arrayUnion([currentUserId])
      });
    }
  }

  // Add a comment
  Future<void> addComment(String postId, Map<String, dynamic> comment) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add(comment);
  }

  // Stream of comments for a post
  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- CHAT METHODS ---

  // Send a message
  Future<void> sendMessage(String senderId, String receiverId, String text) async {
    final chatId = getChatId(senderId, receiverId);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update the last message in the chat document
    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'participants': [senderId, receiverId],
    }, SetOptions(merge: true));
  }

  // Get messages stream
  Stream<QuerySnapshot> getMessages(String senderId, String receiverId) {
    final chatId = getChatId(senderId, receiverId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Helper to get a unique chat ID between two users
  String getChatId(String id1, String id2) {
    if (id1.compareTo(id2) > 0) {
      return '${id1}_$id2';
    } else {
      return '${id2}_$id1';
    }
  }
}
