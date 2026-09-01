import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service class to handle all Firebase Firestore real-time operations
/// for Channels, Direct Messages, and User Management.
class FirebaseChatService {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;

  /// Get currently logged in user UID
  static String get currentUid => auth.currentUser?.uid ?? '';

  /// Get currently logged in user display name or email prefix
  static String get currentUserName {
    final user = auth.currentUser;
    if (user == null) return 'User';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }
    return 'User';
  }

  /// Stream of all channels in real time ordered by creation date
  static Stream<QuerySnapshot> channelsStream() {
    return firestore
        .collection('channels')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Create a new channel in Firestore
  static Future<void> createChannel({
    required String name,
    required bool isPrivate,
  }) async {
    final cleanName = name.trim().toLowerCase().replaceAll(' ', '-');
    await firestore.collection('channels').add({
      'name': cleanName,
      'isPrivate': isPrivate,
      'unreadCount': 0,
      'createdBy': currentUid,
      'members': [currentUid],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a channel and recursively clean up its messages subcollection
  static Future<void> deleteChannel(String channelId) async {
    final messagesRef = firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages');

    // Fetch and delete all messages in batches of 500
    while (true) {
      final messagesSnapshot = await messagesRef.limit(500).get();
      if (messagesSnapshot.docs.isEmpty) break;

      final batch = firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (messagesSnapshot.docs.length < 500) break;
    }

    // Delete the channel document itself
    await firestore.collection('channels').doc(channelId).delete();
  }

  /// Real-time stream for a single channel document
  static Stream<DocumentSnapshot> channelDocStream(String channelId) {
    return firestore.collection('channels').doc(channelId).snapshots();
  }

  /// Add a user to a channel's members list
  static Future<void> addMemberToChannel({
    required String channelId,
    required String userId,
  }) async {
    await firestore.collection('channels').doc(channelId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  /// Remove a user from a channel's members list
  static Future<void> removeMemberFromChannel({
    required String channelId,
    required String userId,
  }) async {
    await firestore.collection('channels').doc(channelId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
  }

  /// Real-time stream of messages for a specific channel
  static Stream<QuerySnapshot> channelMessagesStream(String channelId) {
    return firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Send a message inside a channel
  static Future<void> sendChannelMessage({
    required String channelId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    await firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .add({
      'senderId': currentUid,
      'senderName': currentUserName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a message from a channel
  static Future<void> deleteChannelMessage({
    required String channelId,
    required String messageId,
  }) async {
    await firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  /// Stream of registered workspace users in Firestore
  static Stream<QuerySnapshot> usersStream() {
    return firestore.collection('users').snapshots();
  }

  /// Generate a consistent, deterministic chat ID for 2 users
  static String getDirectChatId(String otherUid) {
    final myUid = currentUid;
    if (myUid.compareTo(otherUid) < 0) {
      return '${myUid}_$otherUid';
    } else {
      return '${otherUid}_$myUid';
    }
  }

  /// Real-time stream of direct messages between two users
  static Stream<QuerySnapshot> directMessagesStream(String chatId) {
    return firestore
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Send a direct message to a user
  static Future<void> sendDirectMessage({
    required String chatId,
    required String receiverId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    await firestore
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUid,
      'senderName': currentUserName,
      'receiverId': receiverId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a direct message
  static Future<void> deleteDirectMessage({
    required String chatId,
    required String messageId,
  }) async {
    await firestore
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  /// Ensure current user's profile is stored in the 'users' collection
  static Future<void> ensureCurrentUserProfile() async {
    final user = auth.currentUser;
    if (user == null) return;

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      await firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? user.email?.split('@').first ?? 'User',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
