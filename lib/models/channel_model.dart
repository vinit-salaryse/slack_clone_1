import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple data model representing a Slack Channel.
class ChannelModel {
  final String id;
  final String name;
  final bool isPrivate; // true = locked channel, false = public '#' channel
  final int unreadCount;
  final String createdBy;

  const ChannelModel({
    required this.id,
    required this.name,
    this.isPrivate = false,
    this.unreadCount = 0,
    this.createdBy = '',
  });

  /// Factory method to construct a ChannelModel from a Firestore document.
  factory ChannelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChannelModel(
      id: doc.id,
      name: data['name'] ?? 'general',
      isPrivate: data['isPrivate'] ?? false,
      unreadCount: data['unreadCount'] ?? 0,
      createdBy: data['createdBy'] ?? '',
    );
  }

  /// Converts this ChannelModel to a Map for saving in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isPrivate': isPrivate,
      'unreadCount': unreadCount,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
