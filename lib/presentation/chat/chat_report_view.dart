import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';
import 'chat_report_view_model.dart';

class ChatReportView extends ConsumerStatefulWidget {
  final int roomId;
  final int reportedUserId;
  final String reportedUserName;

  const ChatReportView({
    Key? key,
    required this.roomId,
    required this.reportedUserId,
    required this.reportedUserName,
  }) : super(key: key);

  @override
  ConsumerState<ChatReportView> createState() => _ChatReportViewState();
}

class _ChatReportViewState extends ConsumerState<ChatReportView> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(loginViewModelProvider).user?.id;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: const [
              Text('사용자 신고'),
            ],
          ),
        ),
        body: const Center(child: Text('로그인이 필요합니다.')),
      );
    }

    final chatReportViewModel = ref.watch(chatReportViewModelProvider(
      ChatReportParam(
        roomId: widget.roomId,
        reportedUserId: widget.reportedUserId,
        reporterId: currentUserId,
      ),
    ).notifier);

    final chatReportState = ref.watch(chatReportViewModelProvider(
      ChatReportParam(
        roomId: widget.roomId,
        reportedUserId: widget.reportedUserId,
        reporterId: currentUserId,
      ),
    ));

    ref.listen<ChatReportState>(chatReportViewModelProvider(
      ChatReportParam(
        roomId: widget.roomId,
        reportedUserId: widget.reportedUserId,
        reporterId: currentUserId,
      ),
    ), (previous, next) {

      if (!mounted) {
        print('[ChatReportView] ref.listen: Widget is not mounted. Returning early.');
        return;
      }

      if (next.status == ReportStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고가 접수되었습니다.')),
        );
        Navigator.pop(context);
      }
      else if (next.status == ReportStatus.error && next.message != null) {
        print('[ChatReportView] ref.listen: Status is ERROR. Message: ${next.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              '사용자 신고',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: Colors.black87),
                const SizedBox(width: 6),
                Text(
                  '신고 대상 : ${widget.reportedUserName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.edit_note, size: 20, color: Colors.black87),
                SizedBox(width: 6),
                Text(
                  '신고 사유',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '신고 사유를 입력해주세요',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: chatReportState.status == ReportStatus.submitting
                    ? null
                    : () async {
                        final reason = _reasonController.text.trim();

                        if (reason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('신고 사유를 입력해주세요.')),
                          );
                          return;
                        }

                        final shouldSubmit = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('신고 확인'),
                            content: const Text('정말 신고하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('아니오'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('예'),
                              ),
                            ],
                          ),
                        );

                        if (shouldSubmit != true) return;

                        chatReportViewModel.submitReport(reason);
                      },
                child: chatReportState.status == ReportStatus.submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        '신고하기',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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