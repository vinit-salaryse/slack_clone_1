import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Simple data model representing a message in a channel or direct chat.
class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final String time;
  final bool isMe;
  final Color avatarColor;
  final DateTime? timestamp;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.time,
    this.isMe = false,
    this.avatarColor = const Color.fromARGB(255, 28, 232, 212),
    this.timestamp,
  });

  /// Factory method to construct a ChatMessageModel from a Firestore message document.
  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc, String currentUid) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final senderId = data['senderId'] ?? '';
    final isMe = senderId == currentUid;
    final senderName = isMe ? 'You' : (data['senderName'] ?? 'User');

    // Parse time from Timestamp
    String formattedTime = '';
    DateTime? dt;
    if (data['createdAt'] is Timestamp) {
      dt = (data['createdAt'] as Timestamp).toDate();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      formattedTime = '$hour:$minute $period';
    } else {
      formattedTime = 'Just now';
    }

    // Pick consistent avatar color
    final colors = [
      const Color.fromARGB(255, 177, 54, 179),
      const Color.fromARGB(255, 104, 184, 200),
      const Color.fromARGB(255, 46, 125, 50),
      const Color.fromARGB(255, 94, 53, 177),
      const Color.fromARGB(255, 230, 81, 0),
    ];
    final colorIndex = senderName.hashCode.abs() % colors.length;

    return ChatMessageModel(
      id: doc.id,
      senderId: senderId,
      senderName: senderName,
      message: data['text'] ?? '',
      time: formattedTime,
      isMe: isMe,
      avatarColor: colors[colorIndex],
      timestamp: dt,
    );
  }

  /// Converts this message to a Map for saving in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': message,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
