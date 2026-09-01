import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple data model representing a Slack Channel.
class ChannelModel {
  final String id;
  final String name;
  final bool isPrivate; // true = locked channel, false = public '#' channel
  final int unreadCount;
  final String createdBy;
  final List<String> members;

  const ChannelModel({
    required this.id,
    required this.name,
    this.isPrivate = false,
    this.unreadCount = 0,
    this.createdBy = '',
    this.members = const [],
  });

  /// Checks if a user with [uid] has access to this channel.
  bool hasAccess(String uid) {
    if (!isPrivate) return true;
    if (uid.isEmpty) return false;
    return createdBy == uid || members.contains(uid);
  }

  /// Factory method to construct a ChannelModel from a Firestore document.
  factory ChannelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final createdBy = data['createdBy'] ?? '';
    final rawMembers = data['members'];
    List<String> membersList = [];
    if (rawMembers is List) {
      membersList = rawMembers.map((e) => e.toString()).toList();
    } else if (createdBy.isNotEmpty) {
      membersList = [createdBy];
    }

    return ChannelModel(
      id: doc.id,
      name: data['name'] ?? 'general',
      isPrivate: data['isPrivate'] ?? false,
      unreadCount: data['unreadCount'] ?? 0,
      createdBy: createdBy,
      members: membersList,
    );
  }

  /// Converts this ChannelModel to a Map for saving in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isPrivate': isPrivate,
      'unreadCount': unreadCount,
      'createdBy': createdBy,
      'members': members,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
