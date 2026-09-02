/// States for Channel operations (e.g. deletion)
abstract class ChannelState {
  const ChannelState();
}

/// Initial / idle state
class ChannelInitial extends ChannelState {
  const ChannelInitial();
}

/// State emitted while a channel is being deleted
class ChannelDeleting extends ChannelState {
  final String channelId;

  const ChannelDeleting(this.channelId);
}

/// State emitted when a channel is successfully deleted
class ChannelDeleteSuccess extends ChannelState {
  final String channelId;
  final String channelName;

  const ChannelDeleteSuccess({
    required this.channelId,
    required this.channelName,
  });
}

class ChannelDeleteError extends ChannelState {
  final String error;
  final String? channelId;

  const ChannelDeleteError({
    required this.error,
    this.channelId,
  });
}
