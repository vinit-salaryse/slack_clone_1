import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service class to handle all Firebase Firestore real-time operations
/// for Channels, Direct Messages, and User Management.
class FirebaseChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get currently logged in user UID
  static String get currentUid => _auth.currentUser?.uid ?? '';

  /// Get currently logged in user display name or email prefix
  static String get currentUserName {
    final user = _auth.currentUser;
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
    return _firestore
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
    await _firestore.collection('channels').add({
      'name': cleanName,
      'isPrivate': isPrivate,
      'unreadCount': 0,
      'createdBy': currentUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real-time stream of messages for a specific channel
  static Stream<QuerySnapshot> channelMessagesStream(String channelId) {
    return _firestore
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

    await _firestore
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

  /// Stream of registered workspace users in Firestore
  static Stream<QuerySnapshot> usersStream() {
    return _firestore.collection('users').snapshots();
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
    return _firestore
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

    await _firestore
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

  /// Ensure current user's profile is stored in the 'users' collection
  static Future<void> ensureCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? user.email?.split('@').first ?? 'User',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
