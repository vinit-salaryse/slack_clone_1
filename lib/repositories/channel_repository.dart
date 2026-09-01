import '../services/firebase_chat_service.dart';

/// Abstract repository defining operations for Slack Channels
abstract class ChannelRepository {
  Future<void> deleteChannel(String channelId);
}

/// Firebase Firestore implementation of [ChannelRepository]
class FirebaseChannelRepository implements ChannelRepository {
  const FirebaseChannelRepository();

  @override
  Future<void> deleteChannel(String channelId) async {
    await FirebaseChatService.deleteChannel(channelId);
  }
}
