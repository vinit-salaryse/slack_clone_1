import 'package:flutter_test/flutter_test.dart';
import 'package:slack_clone_1/cubits/channel_cubit.dart';
import 'package:slack_clone_1/cubits/channel_state.dart';
import 'package:slack_clone_1/repositories/channel_repository.dart';

class FakeSuccessChannelRepository implements ChannelRepository {
  String? lastDeletedId;

  @override
  Future<void> deleteChannel(String channelId) async {
    lastDeletedId = channelId;
  }
}

class FakeFailureChannelRepository implements ChannelRepository {
  @override
  Future<void> deleteChannel(String channelId) async {
    throw Exception('Firestore network failure');
  }
}

void main() {
  group('ChannelCubit Tests', () {
    test('Initial state is ChannelInitial', () {
      final repo = FakeSuccessChannelRepository();
      final cubit = ChannelCubit(repository: repo);
      expect(cubit.state, isA<ChannelInitial>());
    });

    test('deleteChannel emits ChannelDeleting then ChannelDeleteSuccess on success', () async {
      final repo = FakeSuccessChannelRepository();
      final cubit = ChannelCubit(repository: repo);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ChannelDeleting>().having((s) => s.channelId, 'channelId', 'chan-123'),
          isA<ChannelDeleteSuccess>()
              .having((s) => s.channelId, 'channelId', 'chan-123')
              .having((s) => s.channelName, 'channelName', 'general'),
        ]),
      );

      await cubit.deleteChannel(channelId: 'chan-123', channelName: 'general');
      await expectation;

      expect(repo.lastDeletedId, equals('chan-123'));
    });

    test('deleteChannel emits ChannelDeleting then ChannelDeleteError on failure', () async {
      final repo = FakeFailureChannelRepository();
      final cubit = ChannelCubit(repository: repo);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ChannelDeleting>().having((s) => s.channelId, 'channelId', 'chan-123'),
          isA<ChannelDeleteError>()
              .having((s) => s.channelId, 'channelId', 'chan-123')
              .having((s) => s.error, 'error', contains('Firestore network failure')),
        ]),
      );

      await cubit.deleteChannel(channelId: 'chan-123', channelName: 'general');
      await expectation;
    });

    test('resetState returns cubit to ChannelInitial', () async {
      final repo = FakeSuccessChannelRepository();
      final cubit = ChannelCubit(repository: repo);

      await cubit.deleteChannel(channelId: 'chan-123', channelName: 'general');
      expect(cubit.state, isA<ChannelDeleteSuccess>());

      cubit.resetState();
      expect(cubit.state, isA<ChannelInitial>());
    });
  });
}
