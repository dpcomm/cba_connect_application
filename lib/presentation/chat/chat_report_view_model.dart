import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/dto/chat_report_dto.dart';
import 'package:cba_connect_application/repositories/chat_report_repository.dart';
import 'package:cba_connect_application/core/provider.dart';

enum ReportStatus { initial, submitting, success, error }

class ChatReportState {
  final ReportStatus status;
  final String? message;

  const ChatReportState({
    this.status = ReportStatus.initial,
    this.message,
  });

  ChatReportState copyWith({
    ReportStatus? status,
    String? message,
  }) {
    return ChatReportState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

class ChatReportParam {
  final int roomId;
  final int reportedUserId;
  final int reporterId;

  ChatReportParam({
    required this.roomId,
    required this.reportedUserId,
    required this.reporterId,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatReportParam &&
            other.roomId == roomId &&
            other.reportedUserId == reportedUserId &&
            other.reporterId == reporterId;
  }

  @override
  int get hashCode => Object.hash(roomId, reportedUserId, reporterId);
}
class ChatReportViewModel extends StateNotifier<ChatReportState> {
  final ChatreportRepository _repository;
  final int roomId;
  final int reportedUserId;
  final int reporterId;

  ChatReportViewModel({
    required ChatreportRepository repository,
    required this.roomId,
    required this.reportedUserId,
    required this.reporterId,
  })  : _repository = repository,
        super(const ChatReportState());

  Future<void> submitReport(String reason) async {
    if (reason.trim().isEmpty) {
      state = state.copyWith(
        status: ReportStatus.error,
        message: '신고 사유를 입력하세요.',
      );
      return;
    }

    state = state.copyWith(status: ReportStatus.submitting);

    print('[ChatReportViewModel] Setting status to SUBMITTING.');

    try {
      final dto = ReportChatDto(
        reporter: reporterId,
        reported: reportedUserId,
        roomId: roomId,
        reason: reason,
      );

      print('[ChatReportViewModel] dto ${dto.reporter} -> ${dto.reported}');
      print('[ChatReportViewModel] Calling repository.report...');

      await _repository.report(dto);

      print('[ChatReportViewModel] repository.report SUCCESS. Setting status to SUCCESS.');

      state = state.copyWith(status: ReportStatus.success, message: '신고가 접수되었습니다.');
    } catch (e) {
      if (!mounted) {
        print('[ChatReportViewModel] ViewModel disposed on error. Aborting error state update.');
        return; // 이미 dispose되었으면 더 이상 진행하지 않음
      }

      state = state.copyWith(status: ReportStatus.error, message: e.toString());
    }
  }
}

// 프로바이더 생성 - 파라미터가 여러 개라 family 사용
final chatReportViewModelProvider = StateNotifierProvider.family<ChatReportViewModel, ChatReportState, ChatReportParam>((ref, params) {
  final repository = ref.read(chatreportRepositoryProvider);
  return ChatReportViewModel(
    repository: repository,
    roomId: params.roomId,
    reportedUserId: params.reportedUserId,
    reporterId: params.reporterId,
  );
});