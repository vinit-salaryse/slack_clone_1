import 'package:flutter/material.dart';
import '../models/channel_model.dart';

/// Reusable tile representing a single channel item in the Slack channel list.
class ChannelTile extends StatelessWidget {
  final ChannelModel channel;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isOwner;
  final bool isDeleting;

  const ChannelTile({
    super.key,
    required this.channel,
    required this.onTap,
    this.onDelete,
    this.isOwner = false,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDeleting ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            // Icon: Lock for private channels, '#' (tag) for public channels
            SizedBox(
              width: 16,
              height: 16,
              child: Center(
                child: Icon(
                  channel.isPrivate ? Icons.lock_outline : Icons.tag,
                  size: 15,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                channel.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: isDeleting ? Colors.grey : Colors.black87,
                ),
              ),
            ),
            if (channel.unreadCount > 0) ...[
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
              const SizedBox(width: 4),
            ],
            if (isDeleting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4A154B),
                ),
              )
            else if (isOwner && onDelete != null)
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                tooltip: 'Channel options',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete!();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 16),
                        SizedBox(width: 12),
                        Text(
                          'Delete Channel',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: Center(
                child: Icon(
                  Icons.add,
                  size: 15,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(width: 10),
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
