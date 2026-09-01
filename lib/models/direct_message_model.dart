import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Simple data model representing a Direct Message user/conversation.
class DirectMessageModel {
  final String id;
  final String name;
  final String email;
  final Color avatarColor;
  final bool isOnline;
  final bool isCurrentUser; // true if this represents the current logged-in user
  final String? customAvatarText;

  const DirectMessageModel({
    required this.id,
    required this.name,
    this.email = '',
    this.avatarColor = const Color(0xFF00B4D8),
    this.isOnline = true,
    this.isCurrentUser = false,
    this.customAvatarText,
  });

  /// Factory method to construct a DirectMessageModel from a Firestore user document.
  factory DirectMessageModel.fromFirestore(DocumentSnapshot doc, String currentUid) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final uid = data['uid'] ?? doc.id;
    final isMe = uid == currentUid;
    final rawName = data['name'] ?? data['email']?.toString().split('@').first ?? 'User';
    final displayName = isMe ? '$rawName (you)' : rawName;

    // Pick a consistent nice avatar color based on the name's hash
    final colors = [
      const Color(0xFF00B4D8),
      const Color(0xFF2E7D32),
      const Color(0xFF5E35B1),
      const Color(0xFFE65100),
      const Color(0xFF00838F),
      const Color(0xFF3949AB),
    ];
    final colorIndex = rawName.hashCode.abs() % colors.length;

    return DirectMessageModel(
      id: uid,
      name: displayName,
      email: data['email'] ?? '',
      avatarColor: colors[colorIndex],
      isOnline: true,
      isCurrentUser: isMe,
    );
  }
}
