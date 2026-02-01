import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/moderation/report.dart';
import 'package:gamer_flick/repositories/moderation/report_repository.dart';
import 'package:gamer_flick/repositories/notification/notification_repository.dart';

class ReportService {
  final IReportRepository _reportRepository;
  final INotificationRepository _notificationRepository;

  ReportService(
    this._reportRepository,
    this._notificationRepository,
  );

  // === Report Submission ===

  Future<ContentReport?> submitReport({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? customReason,
    String? description,
    String? communityId,
  }) async {
    try {
      // In a real implementation, the repository would handle the DB insertion
      // For now, mapping the service logic to repository methods
      await _reportRepository.reportContent(
        reporterId: reporterId,
        targetId: targetId,
        targetType: targetType.name,
        reason: reason.name,
        details: description ?? customReason,
      );

      // Return a mock report object for the UI if needed
      return ContentReport(
        id: 'new-report',
        reporterId: reporterId,
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        customReason: customReason,
        description: description,
        status: ReportStatus.pending,
        communityId: communityId,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) =>
      _reportRepository.blockUser(blockerId: blockerId, blockedId: blockedId);

  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) =>
      _reportRepository.unblockUser(blockerId: blockerId, blockedId: blockedId);

  Future<bool> isUserBlocked(String userId, String targetUserId) =>
      _reportRepository.isUserBlocked(userId, targetUserId);

  Future<List<String>> getBlockedUserIds(String userId) =>
      _reportRepository.getBlockedUserIds(userId);
}

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(
    ref.watch(reportRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
  );
});
