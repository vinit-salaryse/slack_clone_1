import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/channel_repository.dart';
import 'channel_state.dart';

/// Cubit managing Channel state and lifecycle actions
class ChannelCubit extends Cubit<ChannelState> {
  final ChannelRepository repository;

  ChannelCubit({required this.repository}) : super(const ChannelInitial());

  /// Delete a channel by its ID and clean up subcollections via the repository
  Future<void> deleteChannel({
    required String channelId,
    required String channelName,
  }) async {
    emit(ChannelDeleting(channelId));
    try {
      await repository.deleteChannel(channelId);
      emit(ChannelDeleteSuccess(
        channelId: channelId,
        channelName: channelName,
      ));
    } catch (e) {
      emit(ChannelDeleteError(
        error: e.toString(),
        channelId: channelId,
      ));
    }
  }

  /// Reset cubit state back to initial idle
  void resetState() {
    emit(const ChannelInitial());
  }
}
