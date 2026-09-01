import 'package:flutter/material.dart';
import '../models/channel_model.dart';

/// Reusable tile representing a single channel item in the Slack channel list.
class ChannelTile extends StatelessWidget {
  final ChannelModel channel;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ChannelTile({
    super.key,
    required this.channel,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Icon: Lock for private channels, '#' (tag) for public channels
            SizedBox(
              width: 24,
              child: channel.isPrivate
                  ? const Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: Colors.black87,
                    )
                  : const Icon(
                      Icons.tag,
                      size: 20,
                      color: Colors.black87,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                channel.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ),
            if (channel.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A154B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${channel.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Optional delete/menu button
            if (onDelete != null)
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete!();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable tile for the "+ Add channel" button
class AddChannelTile extends StatelessWidget {
  final VoidCallback onTap;

  const AddChannelTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Icon(
                Icons.add,
                size: 22,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 16),
            Text(
              'Add channel',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
