import 'package:flutter/material.dart';

import 'habi_colors.dart';
import 'message_store.dart';
import 'notification_store.dart';

/// The messages and the text box of a chat. Used by the full chat screen
/// and by the half-height chat on the Job Details screen.
class ChatPanel extends StatefulWidget {
  const ChatPanel({
    super.key,
    required this.conversationId,
    required this.userName,
    this.emptyState,
    this.quickReplies = const [],
  });

  final String conversationId;
  final String userName;

  /// Shown while there are no messages yet.
  final Widget? emptyState;

  /// Tap-to-send greetings shown while there are no messages yet.
  final List<String> quickReplies;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _showQuick = true;
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await MessageStore.instance.send(
        widget.conversationId,
        widget.userName,
        text,
      );
      if (preset == null) _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Message could not be sent. Try again.'),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MessageStore.instance,
      builder: (context, _) {
        final conv = MessageStore.instance.byId(widget.conversationId);
        if (conv == null) return SizedBox.shrink();
        final messages = conv.messagesFor(widget.userName);

        if (conv.unreadFor(widget.userName) > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            MessageStore.instance
                .markRead(conv.id, widget.userName)
                .catchError(
                  (Object error) =>
                      debugPrint('Could not mark chat as read: $error'),
                );
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });

        final showQuick =
            messages.isEmpty && _showQuick && widget.quickReplies.isNotEmpty;

        return Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child:
                            widget.emptyState ??
                            Text(
                              'No messages yet.',
                              style: TextStyle(
                                fontSize: 15,
                                color: HabiColors.cream.withAlpha(200),
                              ),
                            ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) => _Bubble(
                        message: messages[i],
                        mine: messages[i].from == widget.userName,
                      ),
                    ),
            ),
            if (showQuick) _buildQuick(),
            _buildInput(),
          ],
        );
      },
    );
  }

  Widget _buildQuick() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Say hello.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: HabiColors.cream,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _showQuick = false),
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: HabiColors.cream.withAlpha(200),
                ),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final reply in widget.quickReplies)
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _send(reply),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: HabiColors.navyMid,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: HabiColors.gold.withAlpha(140),
                          ),
                        ),
                        child: Text(
                          reply,
                          style: TextStyle(
                            fontSize: 14,
                            color: HabiColors.cream,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      color: HabiColors.navy,
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: HabiColors.cream),
              cursorColor: HabiColors.gold,
              decoration: InputDecoration(
                hintText: 'Message',
                hintStyle: TextStyle(color: HabiColors.cream.withAlpha(130)),
                filled: true,
                fillColor: HabiColors.navyMid,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: HabiColors.cream.withAlpha(60)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: HabiColors.gold),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: FilledButton(
              onPressed: _isSending ? null : _send,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Color(0xFFE2BB6C),
                foregroundColor: HabiColors.ink,
                shape: CircleBorder(),
              ),
              child: _isSending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: mine ? Color(0xFFE2BB6C) : HabiColors.navyMid,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine
              ? null
              : Border.all(color: HabiColors.cream.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: mine ? HabiColors.ink : HabiColors.cream,
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              formatTimeAgo(message.time),
              style: TextStyle(
                fontSize: 10,
                color: mine
                    ? HabiColors.navy.withAlpha(170)
                    : HabiColors.cream.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
