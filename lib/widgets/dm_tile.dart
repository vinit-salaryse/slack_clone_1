import 'package:flutter/material.dart';
import '../models/direct_message_model.dart';

/// Reusable tile representing a Direct Message user item in the Slack Home Screen.
class DirectMessageTile extends StatelessWidget {
  final DirectMessageModel dm;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const DirectMessageTile({
    super.key,
    required this.dm,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Avatar with Online Status Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: dm.avatarColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: dm.customAvatarText != null
                      ? Text(
                          dm.customAvatarText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.white,
                        ),
                ),
                // Green Online Dot / Hollow offline dot
                if (dm.isOnline)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2BAC76), // Slack online green
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  )
                else if (!dm.isCurrentUser)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // User Name
            Expanded(
              child: Text(
                dm.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ),
            if (onDelete != null)
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'delete') onDelete!();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
