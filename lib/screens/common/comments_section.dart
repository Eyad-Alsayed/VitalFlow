import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/booking_comment.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../utils/timezone_helper.dart';

class CommentsSection extends ConsumerStatefulWidget {
  final String bookingId;
  final BookingContext contextType;

  const CommentsSection({
    super.key,
    required this.bookingId,
    required this.contextType,
  });

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final userInfo = await ref.read(userInfoProvider.future);
      final author = CommentAuthor(
        uid: userInfo?.uid ?? 'user',
        displayName: userInfo?.displayName ?? 'User',
        role: userInfo?.role ?? 'applicant',
      );

      final comment = BookingComment(
        bookingId: widget.bookingId,
        context: widget.contextType,
        author: author,
        text: text,
        createdAt: nowRiyadh(),
      );

      await ref.read(databaseServiceProvider).createComment(comment);
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('y-MM-dd HH:mm');
    final commentsAsync = ref.watch(
      commentsStreamProvider((widget.bookingId, widget.contextType.name)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Comments', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        commentsAsync.when(
          data: (comments) {
            // Filter by context defensively (query now only uses bookingId)
            comments = comments
                .where((c) => c.context == widget.contextType)
                .toList(growable: false);
            if (comments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No comments yet.'),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (context, index) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final c = comments[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.author.displayName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.text),
                      const SizedBox(height: 4),
                      Text(
                        '${c.author.role} • ${df.format(c.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
          error: (e, st) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: Text('Failed to load comments: $e')),
                IconButton(
                  onPressed: () => ref.invalidate(commentsStreamProvider((widget.bookingId, widget.contextType.name))),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Retry',
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Add a comment…',
                ),
                minLines: 1,
                maxLines: 3,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: const Icon(Icons.send),
              label: _sending ? const Text('Sending…') : const Text('Send'),
            ),
          ],
        ),
      ],
    );
  }
}
