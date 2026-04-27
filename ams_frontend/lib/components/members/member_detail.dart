import 'dart:convert';
import 'dart:typed_data';

import 'package:ccc_ojt_schedule/components/export_excel.dart';
import 'package:ccc_ojt_schedule/components/members/add_schedule.dart';
import 'package:ccc_ojt_schedule/components/members/delete_schedule.dart';
import 'package:ccc_ojt_schedule/components/members/edit_member.dart';
import 'package:ccc_ojt_schedule/components/members/edit_schedule.dart';
import 'package:ccc_ojt_schedule/components/schedule/proof_image.dart';
import 'package:ccc_ojt_schedule/components/schedule/schedule_record.dart';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/screen/ar.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:ccc_ojt_schedule/store/member_detail_store.dart';
import 'package:ccc_ojt_schedule/store/member_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MemberDetailScreen extends StatefulWidget {
  final Member member;
  final Function onClose;
  const MemberDetailScreen({super.key, required this.member, required this.onClose});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final MemberDetailStore _detailStore = MemberDetailStore();
  final LoginStore _loginStore = LoginStore();
  late Member _localMember;

  String? selectedStatus;
  String? selectedSort;
  String searchQuery = '';
  bool _isInfoExpanded = true;
  bool _isStatusUpdating = false;

  final List<String> statusOptions = ['All', 'Completed', 'Active'];
  final List<String> sortOptions = ['Newest', 'Oldest', 'Earliest In', 'Latest In'];

  // Semantic colors — fixed regardless of mode
  static const _warning = Color(0xFFD97706);
  static const _danger = Color(0xFFDC2626);
  static const _success = Color(0xFF16A34A);
  static const _violet = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _localMember = widget.member;
    _detailStore.addListener(_onStoreUpdate);
    _loadData();
  }

  @override
  void dispose() {
    _detailStore.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() => setState(() {});

  Future<void> _loadData() async {
    await _detailStore.loadFromLocal(_localMember.cccId);
    await _detailStore.fetchSchedules(_localMember.cccId);
  }

  Future<void> _refreshData() => _detailStore.fetchSchedules(_localMember.cccId);

  List<ScheduleRecord> _getFilteredAndSortedRecords() {
    List<ScheduleRecord> filtered = List.from(_detailStore.schedules);
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final dateStr = '${r.date.year}-${r.date.month}-${r.date.day}';
        return dateStr.contains(searchQuery.toLowerCase());
      }).toList();
    }
    switch (selectedStatus) {
      case 'Completed':
        filtered = filtered.where((r) => r.timeOut != null).toList();
        break;
      case 'Active':
        filtered = filtered.where((r) => r.timeOut == null).toList();
        break;
    }
    switch (selectedSort ?? 'Newest') {
      case 'Newest':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Earliest In':
        filtered.sort((a, b) => (a.timeIn.hour * 60 + a.timeIn.minute).compareTo(b.timeIn.hour * 60 + b.timeIn.minute));
        break;
      case 'Latest In':
        filtered.sort((a, b) => (b.timeIn.hour * 60 + b.timeIn.minute).compareTo(a.timeIn.hour * 60 + a.timeIn.minute));
        break;
    }
    return filtered;
  }

  bool get _memberIsPendingDelete => _localMember.status == 'pending_for_delete';
  bool get _memberIsDeleted => _localMember.status == 'deleted';
  bool get _memberIsActive => !_memberIsPendingDelete && !_memberIsDeleted;

  Future<void> _updateMemberStatus(String newStatus) async {
    final requesterCccId = _loginStore.user.value['ccc_id'];
    final actionLabel = switch (newStatus) {
      'pending_for_delete' => 'Mark for Deletion',
      'deleted' => 'Permanently Delete',
      'active' => 'Restore Account',
      _ => 'Update Status',
    };
    final bodyText = switch (newStatus) {
      'pending_for_delete' =>
        'This will flag "${_localMember.fullNameExtended}" for deletion. An admin will need to confirm before the account is fully removed.',
      'deleted' =>
        'This will permanently delete "${_localMember.fullNameExtended}". Their records will be hidden from the app. This action cannot be undone easily.',
      'active' => 'This will restore "${_localMember.fullNameExtended}" to active status.',
      _ => 'Are you sure?',
    };
    final confirmColor = switch (newStatus) {
      'deleted' => _danger,
      'active' => _success,
      _ => _warning,
    };
    final confirmIcon = switch (newStatus) {
      'pending_for_delete' => Icons.hourglass_top_rounded,
      'deleted' => Icons.delete_forever_rounded,
      'active' => Icons.restore_rounded,
      _ => Icons.update_rounded,
    };

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        final isDark = ThemeManager.isDark(ctx);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ThemeManager.surfaceElevated(ctx),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ThemeManager.borderStrong(ctx)),
              boxShadow: isDark
                  ? null
                  : [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: confirmColor.withOpacity(isDark ? 0.15 : 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(confirmIcon, color: confirmColor, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  actionLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ThemeManager.primary(ctx),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  bodyText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.secondary(ctx), height: 1.5),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ThemeManager.secondary(ctx),
                          side: BorderSide(color: ThemeManager.border(ctx)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: Icon(confirmIcon, size: 15),
                        label: Text(actionLabel, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;
    setState(() => _isStatusUpdating = true);
    try {
      final response = await RequestHandler().handleRequest(
        'user/update-status/${_localMember.id}',
        method: 'POST',
        body: {'requester_ccc_id': requesterCccId, 'status': newStatus},
      );
      if (response['success'] == true) {
        setState(() => _localMember = _localMember.copyWith(status: newStatus));
        if (mounted) {
          AppSnackBar.success(context, switch (newStatus) {
            'pending_for_delete' => 'Member marked for deletion.',
            'deleted' => 'Member deleted.',
            'active' => 'Member restored.',
            _ => 'Status updated.',
          });
          if (newStatus == 'deleted') {
            Future.delayed(const Duration(seconds: 1), () {
              Navigator.pop(context);
              widget.onClose();
            });
          }
        }
      } else {
        if (mounted) AppSnackBar.error(context, response['message'] ?? 'Failed to update status.');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Network error: $e');
    } finally {
      if (mounted) setState(() => _isStatusUpdating = false);
    }
  }

  void _showAddScheduleDialog() => showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: AddScheduleDialog(detailStore: _detailStore, selectedDate: DateTime.now()),
    ),
  );
  void _showEditScheduleDialog(ScheduleRecord record, int originalIndex) => showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: EditScheduleDialog(record: record, originalIndex: originalIndex, detailStore: _detailStore),
    ),
  );
  void _showDeleteScheduleDialog(int originalIndex) => showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: DeleteScheduleDialog(
        onConfirm: () {
          _detailStore.deleteSchedule(originalIndex);
          Navigator.pop(context);
          AppSnackBar.success(context, 'Schedule record deleted');
        },
      ),
    ),
  );
  void _showEditMemberDialog() => showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: EditMemberDialog(
        member: _localMember,
        onConfirm: (member) async {
          MembersStore ms = MembersStore();
          await ms.loadFromLocal();
          await ms.editMember(member);
          setState(() => _localMember = member);
          if (mounted) {
            Navigator.pop(context);
            AppSnackBar.success(context, 'Edited member successfully.');
          }
        },
      ),
    ),
  );

  Widget _buildStaticSYBadge(BuildContext context, Member member) {
    final userSY = member.current_sy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceTint(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeManager.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, size: 12, color: ThemeManager.secondary(context)),
          const SizedBox(width: 5),
          Text(
            'AY $userSY-${userSY + 1}',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ThemeManager.secondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Member member, double size, {Color? borderColor}) {
    final hasImage = member.profileLink != null && member.profileLink!.isNotEmpty;
    final bool isSupervisorOrAdmin = member.role == 'supervisor' || member.isAdmin == true;
    final Color effectiveBorder =
        borderColor ?? (isSupervisorOrAdmin ? (member.isAdmin == true ? _violet : _success) : ThemeManager.brand);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: effectiveBorder.withOpacity(0.4), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                member.profileLink!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsCenter(member.initials, size * 0.35),
              )
            : _initialsCenter(member.initials, size * 0.35),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    final isSupervisor = _loginStore.user.value['role'] == 'supervisor';
    final isAdmin = _loginStore.user.value['isAdmin'] == true;
    final isSupervisorProfile = _localMember.role == 'supervisor';
    final isActiveSY =
        _loginStore.user.value['current_iteration'] == _loginStore.user.value['changeable_current_iteration'];
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final displayRecords = _getFilteredAndSortedRecords();

    return Scaffold(
      backgroundColor: ThemeManager.scaffold(context),
      appBar: _buildAppBar(isSupervisor, isSupervisorProfile, isLandscape, isActiveSY, isAdmin, isDark),
      body: _detailStore.isLoading && _detailStore.schedules.isEmpty
          ? Center(child: CircularProgressIndicator(color: ThemeManager.blue(context)))
          : isLandscape
          ? _buildPcLayout(isSupervisor, isAdmin, isSupervisorProfile, displayRecords, isActiveSY)
          : _buildMobileLayout(isSupervisor, isAdmin, isSupervisorProfile, displayRecords, isActiveSY),
    );
  }

  PreferredSizeWidget _buildAppBar(
    bool isSupervisor,
    bool isSupervisorProfile,
    bool isLandscape,
    bool isActiveSY,
    bool isAdmin,
    bool isDark,
  ) {
    return AppBar(
      backgroundColor: ThemeManager.surfaceElevated(context),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: ThemeManager.dividerColor(context)),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: ThemeManager.brand),
        onPressed: () {
          Navigator.pop(context);
          widget.onClose();
        },
      ),
      title: Text(
        _localMember.fullNameExtended,
        style: GoogleFonts.dmSans(color: ThemeManager.primary(context), fontSize: 17, fontWeight: FontWeight.w600),
      ),
      actions: [
        if (isSupervisor && !isSupervisorProfile && isActiveSY) ...[
          SizedBox(
            height: 34,
            child: OutlinedButton.icon(
              onPressed: _showAddScheduleDialog,
              icon: const Icon(Icons.add_rounded, size: 15),
              label: const Text('Add'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeManager.blue(context),
                side: BorderSide(color: ThemeManager.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        if (isSupervisor) ...[
          if (!isAdmin && _memberIsActive)
            _appBarStatusButton(
              label: 'Mark for Deletion',
              icon: Icons.person_remove_rounded,
              color: _warning,
              onTap: () => _updateMemberStatus('pending_for_delete'),
            ),

          if (isAdmin) ...[
            if (_memberIsActive)
              _appBarStatusButton(
                label: 'Mark for Deletion',
                icon: Icons.person_remove_rounded,
                color: _warning,
                onTap: () => _updateMemberStatus('pending_for_delete'),
              ),
            if (_memberIsPendingDelete) ...[
              _appBarStatusButton(
                label: 'Delete',
                icon: Icons.delete_forever_rounded,
                color: _danger,
                onTap: () => _updateMemberStatus('deleted'),
              ),
              const SizedBox(width: 6),
              _appBarStatusButton(
                label: 'Restore',
                icon: Icons.restore_rounded,
                color: _success,
                onTap: () => _updateMemberStatus('active'),
              ),
            ],
            if (_memberIsDeleted)
              _appBarStatusButton(
                label: 'Restore',
                icon: Icons.restore_rounded,
                color: _success,
                onTap: () => _updateMemberStatus('active'),
              ),
          ],

          if (_isStatusUpdating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: ThemeManager.blue(context)),
              ),
            ),
          const SizedBox(width: 8),
        ],

        if (!isSupervisorProfile)
          SizedBox(
            height: 34,
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ExportExcelDialog(cccId: _localMember.cccId),
              ),
              icon: const Icon(Icons.download_rounded, size: 15),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeManager.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _appBarStatusButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: _isStatusUpdating ? null : onTap,
        icon: Icon(icon, size: 14),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          backgroundColor: color.withOpacity(ThemeManager.isDark(context) ? 0.08 : 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildPcLayout(
    bool isSupervisor,
    bool isAdmin,
    bool isSupervisorProfile,
    List<ScheduleRecord> displayRecords,
    bool isActiveSY,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 300,
          child: Container(
            decoration: BoxDecoration(
              color: ThemeManager.surfaceElevatedDarker(context),
              border: Border(right: BorderSide(color: ThemeManager.dividerColor(context))),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: isSupervisorProfile
                  ? _buildSupervisorInfoPanel()
                  : _buildStudentInfoPanel(isSupervisor, isAdmin, isActiveSY),
            ),
          ),
        ),
        Expanded(
          child: isSupervisorProfile
              ? _buildSupervisorInfo()
              : Column(
                  children: [
                    _buildPcFilterBar(),
                    _buildRecordCount(displayRecords.length),
                    Expanded(child: _buildScheduleList(displayRecords, isSupervisor, isActiveSY)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    bool isSupervisor,
    bool isAdmin,
    bool isSupervisorProfile,
    List<ScheduleRecord> displayRecords,
    bool isActiveSY,
  ) {
    return Column(
      children: [
        _buildMemberInfoCard(isSupervisor, isAdmin),
        if (!isSupervisorProfile) ...[
          _buildSearchAndFilters(),
          _buildRecordCount(displayRecords.length),
          Expanded(child: _buildScheduleList(displayRecords, isSupervisor, isActiveSY)),
        ] else
          _buildSupervisorInfo(),
      ],
    );
  }

  // ── Info panels ────────────────────────────────────────────────────────────

  Widget _buildStudentInfoPanel(bool isSupervisor, bool isAdmin, bool isActiveSY) {
    final totalHours = _detailStore.totalCompletedHours;
    final targetHours = _localMember.targetHours ?? 0;
    final progress = targetHours > 0 ? (totalHours / targetHours).clamp(0.0, 1.0) : 0.0;
    final isDark = ThemeManager.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B1C3A), Color(0xFF1B3769)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: ThemeManager.border(context), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: _localMember.profileLink != null && _localMember.profileLink!.isNotEmpty
                      ? Image.network(
                          _localMember.profileLink!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initialsCenter(_localMember.initials, 22),
                        )
                      : _initialsCenter(_localMember.initials, 22),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _localMember.fullNameExtended,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ThemeManager.primary(context),
                ),
              ),
              const SizedBox(height: 12),
              _buildStaticSYBadge(context, _localMember),
              const SizedBox(height: 6),
              _roleBadge('STUDENT', ThemeManager.blue(context), isDark),
              if (_memberIsPendingDelete) ...[
                const SizedBox(height: 6),
                _roleBadge('PENDING DELETION', _warning, isDark, icon: Icons.hourglass_top_rounded),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),
        Divider(color: ThemeManager.dividerColor(context)),
        const SizedBox(height: 14),

        _pcInfoRow(Icons.badge_outlined, 'Office ID', _localMember.customId ?? 'N/A'),
        const SizedBox(height: 10),
        _pcInfoRow(Icons.email_outlined, 'Email', _localMember.email),
        if (_localMember.course != null) ...[
          const SizedBox(height: 10),
          _pcInfoRow(Icons.school_outlined, 'Course', _localMember.course!),
        ],

        const SizedBox(height: 16),
        Divider(color: ThemeManager.dividerColor(context)),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OJT Progress',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ThemeManager.bodyColor(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: progress >= 1.0
                    ? _success.withOpacity(isDark ? 0.15 : 0.08)
                    : ThemeManager.brand.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                progress >= 1.0 ? '100%' : '${(progress * 100).floor()}%',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: progress >= 1.0 ? _success : ThemeManager.blue(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: ThemeManager.surfaceTint(context),
            valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? _success : ThemeManager.blue(context)),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${totalHours.toStringAsFixed(1)}h done',
              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: ThemeManager.blue(context)),
            ),
            Text('${targetHours}h target', style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.muted(context))),
          ],
        ),

        const SizedBox(height: 16),
        Divider(color: ThemeManager.dividerColor(context)),
        const SizedBox(height: 14),

        if (isSupervisor && isActiveSY)
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton.icon(
              onPressed: _showEditMemberDialog,
              icon: const Icon(Icons.edit_rounded, size: 14),
              label: Text('Edit Member', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeManager.blue(context),
                side: BorderSide(color: ThemeManager.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSupervisorInfoPanel() {
    final isAdmin = _localMember.isAdmin;
    final isDark = ThemeManager.isDark(context);
    final Color color = isAdmin ? _violet : _success;
    final String badge = isAdmin ? 'ADMIN' : 'SUPERVISOR';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        _buildAvatar(_localMember, 72, borderColor: color),
        const SizedBox(height: 12),
        Text(
          _localMember.fullNameExtended,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: ThemeManager.primary(context)),
        ),
        const SizedBox(height: 6),
        _roleBadge(badge, color, isDark),
        const SizedBox(height: 20),
        Divider(color: ThemeManager.dividerColor(context)),
        const SizedBox(height: 14),
        _pcInfoRow(Icons.badge_outlined, 'Office ID', _localMember.customId ?? 'N/A'),
        const SizedBox(height: 10),
        _pcInfoRow(Icons.email_outlined, 'Email', _localMember.email),
        const SizedBox(height: 10),
        _pcInfoRow(Icons.calendar_today_outlined, 'Joined', DateFormat('MMM dd, yyyy').format(_localMember.createdAt)),
      ],
    );
  }

  Widget _roleBadge(String label, Color color, bool isDark, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.09),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 10, color: color), const SizedBox(width: 4)],
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.1),
          ),
        ],
      ),
    );
  }

  Widget _pcInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: ThemeManager.muted(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: ThemeManager.muted(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: ThemeManager.primary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _initialsCenter(String initials, double size) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(fontSize: size, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  // ── PC filter bar ──────────────────────────────────────────────────────────

  Widget _buildPcFilterBar() {
    final isFirstLoad = _detailStore.schedules.isEmpty && _detailStore.isLoading;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceElevated(context),
        border: Border(bottom: BorderSide(color: ThemeManager.dividerColor(context))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            height: 34,
            child: Container(
              decoration: BoxDecoration(
                color: ThemeManager.inputFillColor(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ThemeManager.inputBorderColor(context)),
              ),
              child: TextField(
                style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.primary(context)),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, color: ThemeManager.muted(context), size: 17),
                  hintText: 'Search by date…',
                  hintStyle: GoogleFonts.dmSans(color: ThemeManager.hint(context), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  isDense: true,
                ),
                onChanged: (val) => setState(() => searchQuery = val),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _pcFilterChip('All', selectedStatus == null, () => setState(() => selectedStatus = null)),
          const SizedBox(width: 4),
          _pcFilterChip('Completed', selectedStatus == 'Completed', () => setState(() => selectedStatus = 'Completed')),
          const SizedBox(width: 4),
          _pcFilterChip('Active', selectedStatus == 'Active', () => setState(() => selectedStatus = 'Active')),
          Container(
            width: 1,
            height: 20,
            color: ThemeManager.dividerColor(context),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          _pcSortDropdown(),
          const Spacer(),
          SizedBox(
            height: 34,
            width: 34,
            child: OutlinedButton(
              onPressed: _refreshData,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: ThemeManager.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _detailStore.isLoading && !isFirstLoad
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ThemeManager.blue(context)),
                    )
                  : Icon(Icons.refresh_rounded, size: 16, color: ThemeManager.secondary(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pcFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? ThemeManager.brand : ThemeManager.inputFillColor(context),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? ThemeManager.brand : ThemeManager.border(context)),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : ThemeManager.secondary(context),
          ),
        ),
      ),
    );
  }

  Widget _pcSortDropdown() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: ThemeManager.inputFillColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeManager.border(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedSort ?? 'Newest',
          isDense: true,
          dropdownColor: ThemeManager.surfaceElevated(context),
          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: ThemeManager.primary(context)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: ThemeManager.muted(context)),
          items: sortOptions
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: GoogleFonts.dmSans(color: ThemeManager.primary(context))),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => selectedSort = val),
        ),
      ),
    );
  }

  // ── Mobile info card ───────────────────────────────────────────────────────

  Widget _buildMemberInfoCard(bool isSupervisor, bool isAdmin) {
    final totalHours = _detailStore.totalCompletedHours;
    final targetHours = _localMember.targetHours ?? 0;
    final progress = targetHours > 0 ? (totalHours / targetHours).clamp(0.0, 1.0) : 0.0;
    final isDark = ThemeManager.isDark(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeManager.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _memberIsPendingDelete ? _warning.withOpacity(0.4) : ThemeManager.border(context),
          width: _memberIsPendingDelete ? 1.5 : 1,
        ),
        boxShadow: isDark ? null : [const BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          if (_memberIsPendingDelete) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _warning.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, size: 13, color: _warning),
                  const SizedBox(width: 6),
                  Text(
                    'This account is pending deletion',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: _warning),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B1C3A), Color(0xFF1B3769)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _localMember.profileLink != null && _localMember.profileLink!.isNotEmpty
                      ? Image.network(
                          _localMember.profileLink!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initialsCenter(_localMember.initials, 20),
                        )
                      : _initialsCenter(_localMember.initials, 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localMember.fullNameExtended,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ThemeManager.primary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStaticSYBadge(context, _localMember),
                        const SizedBox(width: 6),
                        _roleBadge(
                          _localMember.role.toUpperCase(),
                          _localMember.role == 'supervisor' ? _success : ThemeManager.brand,
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSupervisor) ...[_iconBtn(Icons.edit_rounded, _showEditMemberDialog), const SizedBox(width: 6)],
              _iconBtn(
                _isInfoExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                () => setState(() => _isInfoExpanded = !_isInfoExpanded),
              ),
            ],
          ),

          AnimatedCrossFade(
            firstChild: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeManager.inputFillColor(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ThemeManager.border(context)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.badge_outlined, 'Office ID', _localMember.customId ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.email_outlined, 'Email', _localMember.email),
                      if (_localMember.course != null && _localMember.role == 'student') ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.school_outlined, 'Course', _localMember.course!),
                      ],
                      if (_localMember.role != 'supervisor') ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.access_time_rounded, 'Target', '${_localMember.targetHours}h'),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.timeline_rounded, 'Completed', '${totalHours.toStringAsFixed(1)}h'),
                        if (targetHours > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: ThemeManager.secondary(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                progress >= 1.0 ? '100%' : '${(progress * 100).floor()}%',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: ThemeManager.primary(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: ThemeManager.surfaceTint(context),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress >= 1.0 ? _success : ThemeManager.brand,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isInfoExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return Container(
      height: 32,
      width: 32,
      decoration: BoxDecoration(
        color: ThemeManager.surfaceTint(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeManager.border(context)),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        color: ThemeManager.secondary(context),
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: ThemeManager.muted(context)),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context), fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.primary(context), fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ── Mobile search/filters ──────────────────────────────────────────────────

  Widget _buildSearchAndFilters() {
    final isFirstLoad = _detailStore.schedules.isEmpty && _detailStore.isLoading;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceElevated(context),
        boxShadow: ThemeManager.isDark(context)
            ? null
            : [const BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: ThemeManager.inputFillColor(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ThemeManager.inputBorderColor(context)),
                  ),
                  child: TextField(
                    style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.primary(context)),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, color: ThemeManager.muted(context), size: 18),
                      hintText: 'Search date',
                      hintStyle: GoogleFonts.dmSans(color: ThemeManager.hint(context), fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => searchQuery = val),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(color: ThemeManager.brand, borderRadius: BorderRadius.circular(8)),
                child: _detailStore.isLoading && !isFirstLoad
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                        onPressed: _refreshData,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded, color: ThemeManager.muted(context), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...statusOptions.map((status) {
                        final isSelected = (status == 'All' && selectedStatus == null) || status == selectedStatus;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(status),
                            selected: isSelected,
                            onSelected: (_) => setState(() => selectedStatus = status == 'All' ? null : status),
                            backgroundColor: ThemeManager.inputFillColor(context),
                            selectedColor: ThemeManager.brand,
                            checkmarkColor: Colors.white,
                            labelStyle: GoogleFonts.dmSans(
                              color: isSelected ? Colors.white : ThemeManager.secondary(context),
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            side: BorderSide(color: isSelected ? ThemeManager.brand : ThemeManager.border(context)),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          ),
                        );
                      }),
                      Container(
                        width: 1,
                        height: 20,
                        color: ThemeManager.dividerColor(context),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      ...sortOptions.map((sort) {
                        final isSelected = (selectedSort ?? 'Newest') == sort;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(sort),
                            selected: isSelected,
                            onSelected: (_) => setState(() => selectedSort = sort),
                            backgroundColor: ThemeManager.inputFillColor(context),
                            checkmarkColor: ThemeManager.inputFillColor(context),
                            selectedColor: ThemeManager.brand,
                            labelStyle: GoogleFonts.dmSans(
                              color: isSelected ? Colors.white : ThemeManager.secondary(context),
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            side: BorderSide(color: isSelected ? ThemeManager.brand : ThemeManager.border(context)),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCount(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$count record${count != 1 ? 's' : ''}',
          style: GoogleFonts.dmSans(color: ThemeManager.secondary(context), fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ── Schedule list ──────────────────────────────────────────────────────────

  Widget _buildScheduleList(List<ScheduleRecord> records, bool isSupervisor, bool isActiveSY) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeManager.brand.withOpacity(ThemeManager.isDark(context) ? 0.12 : 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_outlined, size: 40, color: ThemeManager.muted(context)),
            ),
            const SizedBox(height: 16),
            Text(
              'No records found',
              style: GoogleFonts.dmSans(
                color: ThemeManager.secondary(context),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your filters',
              style: GoogleFonts.dmSans(color: ThemeManager.muted(context), fontSize: 12),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.white,
      backgroundColor: ThemeManager.brand,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
        itemCount: records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final record = records[index];
          final originalIndex = _detailStore.schedules.indexOf(record);
          return _buildScheduleRecordCard(record, originalIndex, isSupervisor, isActiveSY);
        },
      ),
    );
  }

  Widget _buildScheduleRecordCard(ScheduleRecord record, int index, bool isSupervisor, bool isActiveSY) {
    final isDark = ThemeManager.isDark(context);
    final isCompleted = record.timeOut != null;
    final hours = isCompleted ? _detailStore.calculateHours(record.timeIn, record.timeOut!) : 0.0;
    final hasProofIn = record.proofIn != null && record.proofIn!.isNotEmpty;
    final hasProofOut = record.proofOut != null && record.proofOut!.isNotEmpty;
    final hasAnyProof = hasProofIn || hasProofOut;

    final statusColor = isCompleted
        ? (!record.isAcceptedWorkFromHome ? const Color(0xFFDC2626) : _success)
        : const Color(0xFFD97706);
    final statusIcon = isCompleted
        ? (!record.isAcceptedWorkFromHome ? Icons.close_rounded : Icons.check_circle_rounded)
        : Icons.pending_rounded;

    return Container(
      decoration: BoxDecoration(
        color: ThemeManager.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ThemeManager.border(context)),
        boxShadow: isDark ? null : [const BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEE, MMM dd, yyyy').format(record.date),
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ThemeManager.primary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.login_rounded, size: 12, color: ThemeManager.muted(context)),
                              const SizedBox(width: 4),
                              Text(
                                record.timeIn.format(context),
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: ThemeManager.secondary(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(Icons.logout_rounded, size: 12, color: ThemeManager.muted(context)),
                              const SizedBox(width: 4),
                              Text(
                                record.timeOut?.format(context) ?? 'Pending',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: ThemeManager.secondary(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isCompleted && record.isAcceptedWorkFromHome) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: _success.withOpacity(isDark ? 0.15 : 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: _success.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    '${hours.toStringAsFixed(2)}h',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _success,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSupervisor)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, color: ThemeManager.secondary(context), size: 18),
                        elevation: 4,
                        color: ThemeManager.surfaceElevated(context),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'ar')
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ARPage(record: record, cccId: widget.member.cccId, role: widget.member.role),
                              ),
                            );
                          else if (value == 'edit')
                            _showEditScheduleDialog(record, index);
                          else if (value == 'delete')
                            _showDeleteScheduleDialog(index);
                        },
                        itemBuilder: (_) => [
                          _popupItem('ar', Icons.folder_rounded, 'View AR', ThemeManager.brand),
                          if (isActiveSY) ...[
                            _popupItem('edit', Icons.edit_rounded, 'Edit', ThemeManager.brand),
                            _popupItem('delete', Icons.delete_outline_rounded, 'Delete', _danger),
                          ],
                        ],
                      ),
                  ],
                ),

                if (hasAnyProof) ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, color: ThemeManager.dividerColor(context)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.image_outlined, size: 12, color: ThemeManager.muted(context)),
                      const SizedBox(width: 6),
                      Text(
                        'Proof',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: ThemeManager.muted(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (hasProofIn)
                        _proofButton(
                          label: 'Time In',
                          icon: Icons.login_rounded,
                          color: ThemeManager.blue(context),
                          onTap: () => _showProofImage(context, record.proofIn!, 'Time In Proof', record.date),
                        ),
                      if (hasProofIn && hasProofOut) const SizedBox(width: 8),
                      if (hasProofOut)
                        _proofButton(
                          label: 'Time Out',
                          icon: Icons.logout_rounded,
                          color: _success,
                          onTap: () => _showProofImage(context, record.proofOut!, 'Time Out Proof', record.date),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showProofImage(BuildContext context, String imageSource, String title, DateTime date) async {
    Uint8List? imageBytes;
    final isUrl = imageSource.startsWith('http://') || imageSource.startsWith('https://');
    if (isUrl) {
      try {
        imageBytes = await DefaultCacheManager().getSingleFile(imageSource).then((f) => f.readAsBytes());
      } catch (_) {}
    } else {
      try {
        imageBytes = base64Decode(imageSource);
      } catch (_) {}
    }
    imageBytes ??= Uint8List(0);
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ProofImageViewer(imageBytes: imageBytes!, title: title, date: date),
      ),
    );
  }

  Widget _proofButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeManager.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _popupItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color == _danger ? color : ThemeManager.bodyColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorInfo() {
    final isDark = ThemeManager.isDark(context);
    final isAdmin = _localMember.isAdmin;
    final color = isAdmin ? _violet : _success;
    final title = isAdmin ? 'Admin Account' : 'Supervisor Account';
    final subtitle = isAdmin
        ? 'This user has full administrative access'
        : 'This user manages student schedules and records';

    return Expanded(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: ThemeManager.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ThemeManager.border(context)),
            boxShadow: isDark ? null : [const BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(_localMember, 72, borderColor: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ThemeManager.primary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.muted(context)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: ThemeManager.surfaceTint(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ThemeManager.border(context)),
                ),
                child: Text(
                  'Joined ${DateFormat('MMM dd, yyyy').format(_localMember.createdAt)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: ThemeManager.secondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
