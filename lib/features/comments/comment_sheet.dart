import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_provider.dart';
import 'comment_provider.dart';

/// Open the comment bottom sheet for any expense or settlement.
void showCommentsSheet(
  BuildContext context,
  WidgetRef ref,
  String targetId,
  String targetType,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CommentSheet(targetId: targetId, targetType: targetType),
  );
}

class CommentSheet extends ConsumerStatefulWidget {
  final String targetId;
  final String targetType;

  const CommentSheet(
      {super.key, required this.targetId, required this.targetType});

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendComment() {
    final msg = _msgController.text.trim();
    if (msg.isEmpty) return;
    final user = ref.read(authProvider);
    ref.read(commentProvider.notifier).addComment(
          targetId: widget.targetId,
          targetType: widget.targetType,
          userId: user?.id ?? 'u1',
          message: msg,
        );
    _msgController.clear();
    // Scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsForTargetProvider(widget.targetId));
    final user = ref.watch(authProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final users = usersAsync.value ?? [];
    final cs = Theme.of(context).colorScheme;


    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: SpendlyColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Text('Comments',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${comments.length}',
                      style: AppTextStyles.caption(
                          color: SpendlyColors.neutral500)),
                ],
              ),
            ),
            const Divider(height: 1),

            // Comment list
            Expanded(
              child: comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 40, color: SpendlyColors.neutral300),
                          const SizedBox(height: 8),
                          Text('No comments yet',
                              style: AppTextStyles.bodySecondary(
                                  color: SpendlyColors.neutral400)),
                          Text('Be the first to comment!',
                              style: AppTextStyles.caption(
                                  color: SpendlyColors.neutral400)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: comments.length,
                      itemBuilder: (_, i) {
                        final c = comments[i];
                        final isMe = c.userId == user?.id;
                        final commenter = users.cast<dynamic>().firstWhere(
                              (u) => u.id == c.userId,
                              orElse: () => null,
                            );
                        final name = commenter?.name?.toString() ??
                            c.userId;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                UserAvatar(
                                    name: name,
                                    userId: c.userId,
                                    size: 30),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 2, bottom: 2),
                                        child: Text(
                                          name.split(' ').first,
                                          style: AppTextStyles.caption(
                                              color: SpendlyColors
                                                  .neutral500),
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? SpendlyColors.primary
                                            : cs.surfaceContainerHighest,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: isMe
                                              ? const Radius.circular(16)
                                              : const Radius.circular(4),
                                          bottomRight: isMe
                                              ? const Radius.circular(4)
                                              : const Radius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        c.message,
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : cs.onSurface,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 2, left: 4, right: 4),
                                      child: Text(
                                        _timeAgo(c.timestamp),
                                        style: AppTextStyles.caption(
                                            color:
                                                SpendlyColors.neutral400),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                UserAvatar(
                                    name: user?.name ?? 'You',
                                    userId: user?.id ?? '',
                                    size: 30),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Input area
            const Divider(height: 1),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        focusNode: _focusNode,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Add a comment…',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                        ),
                        onSubmitted: (_) => _sendComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendComment,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: SpendlyColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}
