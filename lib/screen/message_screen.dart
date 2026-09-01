import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/channel_model.dart';
import '../models/chat_message_model.dart';
import '../models/direct_message_model.dart';
import '../services/firebase_chat_service.dart';
import '../widgets/chat_message_tile.dart';

class MessageScreen extends StatefulWidget {
  final String targetId; // channelId for channel, or receiver's uid for DM
  final String title;
  final bool isChannel;
  final bool isPrivate;
  final String? subtitle;

  const MessageScreen({
    super.key,
    required this.targetId,
    required this.title,
    this.isChannel = true,
    this.isPrivate = false,
    this.subtitle,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late final String _chatId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isChannel) {
      _chatId = FirebaseChatService.getDirectChatId(widget.targetId);
    } else {
      _chatId = '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  /// Send a new message to Firestore
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();

    try {
      if (widget.isChannel) {
        await FirebaseChatService.sendChannelMessage(
          channelId: widget.targetId,
          text: text,
        );
      } else {
        await FirebaseChatService.sendDirectMessage(
          chatId: _chatId,
          receiverId: widget.targetId,
          text: text,
        );
      }

      // Smooth scroll to latest message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Delete message handler
  Future<void> _deleteMessage(String messageId) async {
    try {
      if (widget.isChannel) {
        await FirebaseChatService.deleteChannelMessage(
          channelId: widget.targetId,
          messageId: messageId,
        );
      } else {
        await FirebaseChatService.deleteDirectMessage(
          chatId: _chatId,
          messageId: messageId,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete message: $e')),
        );
      }
    }
  }

  /// Show Add / Invite Member Bottom Sheet
  void _showAddMemberSheet(BuildContext context, ChannelModel? channel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseChatService.channelDocStream(widget.targetId),
              builder: (context, channelDocSnap) {
                List<String> currentMembers = channel?.members ?? [];
                if (channelDocSnap.hasData && channelDocSnap.data!.exists) {
                  final liveChannel = ChannelModel.fromFirestore(channelDocSnap.data!);
                  currentMembers = liveChannel.members;
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseChatService.usersStream(),
                  builder: (context, usersSnap) {
                    final docs = usersSnap.data?.docs ?? [];
                    final allUsers = docs
                        .map((doc) => DirectMessageModel.fromFirestore(
                              doc,
                              FirebaseChatService.currentUid,
                            ))
                        .toList();

                    final filteredUsers = allUsers.where((u) {
                      if (searchQuery.trim().isEmpty) return true;
                      final q = searchQuery.toLowerCase();
                      return u.name.toLowerCase().contains(q) ||
                          u.email.toLowerCase().contains(q);
                    }).toList();

                    return Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      padding: EdgeInsets.only(
                        top: 20,
                        left: 16,
                        right: 16,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Add people to #${widget.title}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Search field
                          TextField(
                            onChanged: (val) {
                              setModalState(() => searchQuery = val);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by name or email',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Workspace Members (${filteredUsers.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // User list
                          Expanded(
                            child: usersSnap.connectionState ==
                                        ConnectionState.waiting &&
                                    !usersSnap.hasData
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF4A154B),
                                    ),
                                  )
                                : filteredUsers.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No members found',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: filteredUsers.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final user = filteredUsers[index];
                                          final isMember =
                                              currentMembers.contains(user.id);
                                          final isCreator =
                                              channel?.createdBy == user.id;

                                          return ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 4,
                                            ),
                                            leading: CircleAvatar(
                                              backgroundColor: user.avatarColor,
                                              child: Text(
                                                user.name.isNotEmpty
                                                    ? user.name[0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              user.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                            subtitle: user.email.isNotEmpty
                                                ? Text(
                                                    user.email,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  )
                                                : null,
                                            trailing: isMember
                                                ? Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade200,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.check,
                                                          size: 14,
                                                          color: Colors.black54,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          isCreator
                                                              ? 'Owner'
                                                              : 'Member',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                Colors.black54,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(0xFF4A154B),
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 6,
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      minimumSize: Size.zero,
                                                    ),
                                                    onPressed: () async {
                                                      final messenger =
                                                          ScaffoldMessenger.of(
                                                              context);
                                                      try {
                                                        await FirebaseChatService
                                                            .addMemberToChannel(
                                                          channelId:
                                                              widget.targetId,
                                                          userId: user.id,
                                                        );
                                                        messenger.showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Added ${user.name} to #${widget.title}'),
                                                            duration:
                                                                const Duration(
                                                                    seconds: 2),
                                                          ),
                                                        );
                                                      } catch (e) {
                                                        messenger.showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Failed to add member: $e'),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: const Text(
                                                      'Add',
                                                      style: TextStyle(
                                                          fontSize: 13),
                                                    ),
                                                  ),
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle = widget.title;
    if (widget.isChannel && !displayTitle.startsWith('#')) {
      displayTitle = '# $displayTitle';
    }

    final currentUid = FirebaseChatService.currentUid;

    // If it is a channel, observe channel doc to verify membership for private channels
    if (widget.isChannel) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseChatService.channelDocStream(widget.targetId),
        builder: (context, channelSnapshot) {
          // If the channel was deleted, automatically navigate back
          if (channelSnapshot.hasData && !channelSnapshot.data!.exists) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Channel "${widget.title}" has been deleted.'),
                    backgroundColor: const Color.fromARGB(255, 74, 21, 75),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            });
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF4A154B)),
              ),
            );
          }

          ChannelModel? channel;
          if (channelSnapshot.hasData && channelSnapshot.data!.exists) {
            channel = ChannelModel.fromFirestore(channelSnapshot.data!);
          }

          final isPrivate = channel?.isPrivate ?? widget.isPrivate;
          final hasAccess = channel == null || channel.hasAccess(currentUid);

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              foregroundColor: Colors.black87,
              titleSpacing: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPrivate) ...[
                        const Icon(Icons.lock_outline, size: 16, color: Colors.black87),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        displayTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    channel != null
                        ? '${channel.members.length} members • ${isPrivate ? "Private channel" : "Public channel"}'
                        : (widget.subtitle ?? 'Channel'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              actions: [
                if (hasAccess)
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1),
                    tooltip: 'Add member',
                    onPressed: () => _showAddMemberSheet(context, channel),
                  ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Details',
                  onPressed: () {},
                ),
              ],
            ),
            body: SafeArea(
              child: !hasAccess
                  ? _buildAccessDeniedView()
                  : _buildChatBody(FirebaseChatService.channelMessagesStream(widget.targetId)),
            ),
          );
        },
      );
    }

    // Direct Message View
    final directMessagesStream = FirebaseChatService.directMessagesStream(_chatId);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              widget.subtitle ?? 'Active now',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Details',
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: _buildChatBody(directMessagesStream),
      ),
    );
  }

  /// Access Denied View for uninvited private channel users
  Widget _buildAccessDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFEECEB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 48,
                color: Color(0xFFE02424),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This channel is private',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You need an invitation to access this channel. Ask a channel member or administrator to invite you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A154B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }

  /// Chat messages stream and input bar
  Widget _buildChatBody(Stream<QuerySnapshot> messagesStream) {
    final currentUid = FirebaseChatService.currentUid;

    return Column(
      children: [
        // Real-time Firestore Messages Stream
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: messagesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error loading messages: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A154B)),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isChannel ? Icons.tag : Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.isChannel
                              ? 'Welcome to # ${widget.title}!'
                              : 'Start a conversation with ${widget.title}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This is the beginning of the chat history.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final messages = docs
                  .map((doc) => ChatMessageModel.fromFirestore(doc, currentUid))
                  .toList();

              // Scroll to bottom on initial load and message updates
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (scrollController.hasClients) {
                  scrollController.jumpTo(scrollController.position.maxScrollExtent);
                }
              });

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return ChatMessageTile(
                    message: msg,
                    onDelete: () => _deleteMessage(msg.id),
                  );
                },
              );
            },
          ),
        ),

        // Message Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              // Attachment button
              IconButton(
                icon: const Icon(Icons.add, color: Colors.grey),
                onPressed: () {},
              ),
              // Text input
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _textController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: widget.isChannel
                          ? 'Message #${widget.title}'
                          : 'Message ${widget.title}',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Send button
              IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4A154B),
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Color(0xFF4A154B)),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
