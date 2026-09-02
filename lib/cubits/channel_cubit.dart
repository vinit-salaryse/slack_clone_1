import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/channel_repository.dart';
import 'channel_state.dart';

class ChannelCubit extends Cubit<ChannelState> {
  final ChannelRepository repository;

  ChannelCubit({required this.repository}) : super(const ChannelInitial());

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

  // Reset cubit state back to initial state 
  void resetState() {
    emit(const ChannelInitial());
  }
}
