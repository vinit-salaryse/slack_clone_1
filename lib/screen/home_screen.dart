import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/channel_cubit.dart';
import '../cubits/channel_state.dart';
import '../models/channel_model.dart';
import '../models/direct_message_model.dart';
import '../services/firebase_chat_service.dart';
import '../widgets/channel_tile.dart';
import '../widgets/dm_tile.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_header.dart';
import 'message_screen.dart';

/// Main Slack Home Screen connected in real-time to Firebase Firestore.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Navigation index
  int currentNavIndex = 0;

  // Section collapse/expand states
  bool _isChannelsExpanded = true;
  bool _isDMsExpanded = true;

  @override
  void initState() {
    super.initState();
    // Ensure current user profile exists in Firestore
    FirebaseChatService.ensureCurrentUserProfile();
  }

  /// Navigate to message / chat screen
  void _openChat({
    required String targetId,
    required String title,
    required bool isChannel,
    bool isPrivate = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageScreen(
          targetId: targetId,
          title: title,
          isChannel: isChannel,
          isPrivate: isPrivate,
        ),
      ),
    );
  }

  /// Show simple dialog to add a new channel in Firestore
  void showAddChannelDialog() {
    final nameController = TextEditingController();
    bool isPrivate = false;
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Create Channel',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Channel Name',
                      hintText: 'project',
                      prefixIcon: Icon(Icons.tag),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Make Private',
                        style: TextStyle(fontSize: 15),
                      ),
                      Switch(
                        value: isPrivate,
                        activeColor: const Color(0xFF4A154B),
                        onChanged: (val) {
                          setDialogState(() => isPrivate = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isCreating ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A154B),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isCreating
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isNotEmpty) {
                            setDialogState(() => isCreating = true);
                            try {
                              await FirebaseChatService.createChannel(
                                name: name,
                                isPrivate: isPrivate,
                              );
                              if (context.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setDialogState(() => isCreating = false);
                              }
                            }
                          }
                        },
                  child: isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Show User Profile & Logout Bottom Sheet
  void showProfileSheet() {
    final user = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF00B4D8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, size: 36, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                user?.displayName ?? FirebaseChatService.currentUserName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                user?.email ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show confirmation dialog for deleting a channel
  void _showDeleteChannelConfirmationDialog(
    BuildContext context,
    ChannelModel channel,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete #${channel.name}?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete #${channel.name}? This will permanently remove the channel and all its messages. This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black87),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.read<ChannelCubit>().deleteChannel(
                      channelId: channel.id,
                      channelName: channel.name,
                    );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseChatService.currentUid;

    return BlocConsumer<ChannelCubit, ChannelState>(
      listener: (context, state) {
        if (state is ChannelDeleteSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Channel #${state.channelName} deleted successfully'),
              backgroundColor: const Color(0xFF4A154B),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ChannelCubit>().resetState();
        } else if (state is ChannelDeleteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete channel: ${state.error}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ChannelCubit>().resetState();
        }
      },
      builder: (context, channelState) {
        final deletingChannelId =
            channelState is ChannelDeleting ? channelState.channelId : null;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            top: false, // Let custom header extend to status bar
            child: Column(
              children: [

            // Top Slack Purple App Bar / Header
            Container(
              color: const Color(0xFF481349), 
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 0.0,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  // Slack icon representation
                  Container(
                    width: 28,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E0620),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Workspace Name with dropdown chevron
                  const Text(
                    'SalarySe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const Spacer(),
                  // History button
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.history,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Profile Avatar with Online Dot
                  GestureDetector(
                    onTap: showProfileSheet,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B4D8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2BAC76),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF481349),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),

                    // 1. Quick Action Cards (Horizontal List)
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          QuickActionCard(
                            icon: Icons.chat_bubble_outline,
                            title: 'Threads',
                            subtitle: 'Caught up',
                            onTap: () {},
                          ),
                          const SizedBox(width: 10),
                          QuickActionCard(
                            icon: Icons.bookmark_border_rounded,
                            title: 'Later',
                            subtitle: '0 items',
                            onTap: () {},
                          ),
                          const SizedBox(width: 10),
                          QuickActionCard(
                            icon: Icons.send_outlined,
                            title: 'Drafts & sent',
                            subtitle: '1 draft',
                            onTap: () {},
                          ),
                          const SizedBox(width: 10),
                          QuickActionCard(
                            icon: Icons.headphones_outlined,
                            title: 'Huddles',
                            subtitle: '0 live',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),

                    // 2. Channels Section (Connected with Firestore)
                    SectionHeader(
                      leading: const Icon(
                        Icons.tag,
                        size: 15,
                        color: Colors.black87,
                      ),
                      title: 'Channels',
                      isExpanded: _isChannelsExpanded,
                      onToggle: () {
                        setState(() {
                          _isChannelsExpanded = !_isChannelsExpanded;
                        });
                      },
                    ),

                    if (_isChannelsExpanded) ...[
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseChatService.channelsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF4A154B),
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];
                          final channels = docs
                              .map((doc) => ChannelModel.fromFirestore(doc))
                              .where((channel) => channel.hasAccess(currentUid))
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: channels.map((channel) {
                              final isOwner = channel.createdBy.isNotEmpty &&
                                  channel.createdBy == currentUid;
                              final isDeleting =
                                  deletingChannelId == channel.id;

                              return ChannelTile(
                                channel: channel,
                                isOwner: isOwner,
                                isDeleting: isDeleting,
                                onDelete: isOwner
                                    ? () => _showDeleteChannelConfirmationDialog(
                                          context,
                                          channel,
                                        )
                                    : null,
                                onTap: () => _openChat(
                                  targetId: channel.id,
                                  title: channel.name,
                                  isChannel: true,
                                  isPrivate: channel.isPrivate,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      // Add channel button
                      AddChannelTile(
                        onTap: showAddChannelDialog,
                      ),
                    ],

                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),

                    // 3. Direct Messages Section (Connected with Firestore Users)
                    SectionHeader(
                      leading: const Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: Colors.black87,
                      ),
                      title: 'Direct messages',
                      isExpanded: _isDMsExpanded,
                      onToggle: () {
                        setState(() {
                          _isDMsExpanded = !_isDMsExpanded;
                        });
                      },
                    ),

                    if (_isDMsExpanded) ...[
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseChatService.usersStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF4A154B),
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];
                          final dms = docs
                              .map((doc) => DirectMessageModel.fromFirestore(doc, currentUid))
                              .toList();

                          // Sort so current user (you) is listed at the top
                          dms.sort((a, b) {
                            if (a.isCurrentUser) return -1;
                            if (b.isCurrentUser) return 1;
                            return a.name.compareTo(b.name);
                          });

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: dms.map((dm) {
                              return DirectMessageTile(
                                dm: dm,
                                onTap: () => _openChat(
                                  targetId: dm.id,
                                  title: dm.name,
                                  isChannel: false,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ], // Bottom padding for FAB and Nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button (+ icon)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A154B),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: showAddChannelDialog,
        child: const Icon(Icons.add, size: 28),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentNavIndex,
          onDestinationSelected: (index) {
            setState(() => currentNavIndex = index);
          },
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFEDE3ED), // Light purple highlight
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF4A154B)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF4A154B)),
              label: 'DMs',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications, color: Color(0xFF4A154B)),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.search, color: Color(0xFF4A154B)),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz),
              selectedIcon: Icon(Icons.more_horiz, color: Color(0xFF4A154B)),
              label: 'More',
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
