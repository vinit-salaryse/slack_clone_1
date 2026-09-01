import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slack_clone_1/models/channel_model.dart';
import 'package:slack_clone_1/widgets/channel_tile.dart';

void main() {
  group('ChannelTile Widget Tests', () {
    const ownerChannel = ChannelModel(
      id: 'c1',
      name: 'announcements',
      isPrivate: false,
      createdBy: 'user-1',
    );

    testWidgets('Shows 3-dot popup menu when isOwner is true', (WidgetTester tester) async {
      bool deleteTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelTile(
              channel: ownerChannel,
              isOwner: true,
              onTap: () {},
              onDelete: () {
                deleteTapped = true;
              },
            ),
          ),
        ),
      );

      // Verify channel name is displayed
      expect(find.text('announcements'), findsOneWidget);

      // Verify 3-dot icon is displayed
      final moreVertIcon = find.byIcon(Icons.more_vert);
      expect(moreVertIcon, findsOneWidget);

      // Tap 3-dot icon to open menu
      await tester.tap(moreVertIcon);
      await tester.pumpAndSettle();

      // Verify 'Delete Channel' option is in the popup menu
      expect(find.text('Delete Channel'), findsOneWidget);

      // Tap 'Delete Channel'
      await tester.tap(find.text('Delete Channel'));
      await tester.pumpAndSettle();

      expect(deleteTapped, isTrue);
    });

    testWidgets('Hides 3-dot popup menu when isOwner is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelTile(
              channel: ownerChannel,
              isOwner: false,
              onTap: () {},
              onDelete: null,
            ),
          ),
        ),
      );

      // Verify channel name is displayed
      expect(find.text('announcements'), findsOneWidget);

      // Verify 3-dot icon is NOT displayed
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('Shows loading spinner when isDeleting is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelTile(
              channel: ownerChannel,
              isOwner: true,
              isDeleting: true,
              onTap: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify CircularProgressIndicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Verify 3-dot icon is NOT shown during deletion
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });
  });
}
