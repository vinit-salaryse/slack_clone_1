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
    this.avatarColor = const Color.fromARGB(255, 0, 180, 216),
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

    final colors = [
      const Color.fromARGB(255, 1, 160, 192),
      const Color.fromARGB(255, 46, 125, 50),
      const Color.fromARGB(255, 94, 53, 177),
      const Color.fromARGB(255, 230, 81, 0),
      const Color.fromARGB(255, 0, 131, 143),
      const Color.fromARGB(255, 57, 73, 171),
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
