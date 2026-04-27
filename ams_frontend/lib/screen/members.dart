// Author: JDM
// Updated on: 2026-03-22

import 'package:ccc_ojt_schedule/components/members/add_member.dart';
import 'package:ccc_ojt_schedule/components/members/add_supervisor.dart';
import 'package:ccc_ojt_schedule/components/members/member_detail.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:ccc_ojt_schedule/store/member_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<StatefulWidget> createState() => _Members();
}

class _Members extends State<MembersPage> {
  final MembersStore _membersStore = MembersStore();
  final LoginStore _loginStore = LoginStore();
  String searchQuery = '';
  String? selectedRole;
  String? selectedProgress;

  // Semantic colors — not mode-dependent
  static const _teal = Color(0xFF0F766E);
  static const _violet = Color(0xFF7C3AED);
  static const _success = Color(0xFF16A34A);
  static const _warning = Color(0xFFD97706);

  @override
  void initState() {
    super.initState();
    _membersStore.addListener(_onMembersUpdate);
    _loadMembers();
  }

  @override
  void dispose() {
    _membersStore.removeListener(_onMembersUpdate);
    super.dispose();
  }

  void _onMembersUpdate() => setState(() {});

  Future<void> _loadMembers() async {
    await _membersStore.loadFromLocal();
    final cccId = _loginStore.user.value['ccc_id'];
    final currentIteration = _loginStore.user.value['changeable_current_iteration'];
    if (cccId != null) await _membersStore.fetchMembers(cccId, currentIteration);
  }

  void _showAddStudentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddStudentSheet(onSuccess: _loadMembers),
    );
  }

  void _showAddSupervisorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSupervisorSheet(onSuccess: _loadMembers, addOfficeID: false),
    );
  }

  bool _isDeleted(Member member) => member.status == 'deleted';
  bool _isPendingDelete(Member member) => member.status == 'pending_for_delete';

  List<Member> _getFilteredMembers() {
    List<Member> filtered = List.from(_membersStore.members);
    if (_membersStore.supervisor != null) {
      filtered.insert(0, _membersStore.supervisor!);
    }
    filtered = filtered.where((m) => !_isDeleted(m)).toList();

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (m) =>
                m.fullName.toLowerCase().contains(q) ||
                m.cccId.toLowerCase().contains(q) ||
                m.email.toLowerCase().contains(q),
          )
          .toList();
    }

    if (selectedRole != null && selectedRole != 'All') {
      filtered = filtered.where((m) => m.role.toLowerCase() == selectedRole!.toLowerCase()).toList();
    }

    if (selectedProgress != null) {
      filtered = filtered.where((m) {
        if (m.role == 'supervisor') return true;
        if (selectedProgress == 'done') return m.isDone == true;
        if (selectedProgress == 'ongoing') return m.isDone != true;
        return true;
      }).toList();
    }

    filtered.sort((a, b) {
      int order(Member m) {
        if (m.isAdmin == true) return 0;
        if (m.role == 'supervisor') return 1;
        return 2;
      }
      return order(a).compareTo(order(b));
    });
    return filtered;
  }

  String _formatLastFetched(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _progressColor(double progress) {
    if (progress >= 1.0) return _success;
    if (progress >= 0.7) return const Color(0xFF2563EB);
    if (progress >= 0.4) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final isDark = ThemeManager.isDark(context);
    final displayMembers = _getFilteredMembers();
    final isFirstLoad = _membersStore.members.isEmpty && _membersStore.isLoading;
    final isUserSupervisor = _loginStore.user.value['role'] == 'supervisor';
    final isUserAdmin = _loginStore.user.value['isAdmin'] == true;
    final activeSY =
        _loginStore.user.value['current_iteration'] == _loginStore.user.value['changeable_current_iteration'];
    final myStatus = _loginStore.user.value['status'] as String?;
    final bool myIsPendingDelete = myStatus == 'pending_for_delete';

    return Scaffold(
      backgroundColor: ThemeManager.scaffold(context),
      floatingActionButton: isLandscape
          ? null
          : isUserSupervisor
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (activeSY) ...[
                  FloatingActionButton.extended(
                    heroTag: 'addSupervisor',
                    onPressed: _showAddSupervisorSheet,
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.admin_panel_settings_rounded),
                    label: const Text(''),
                    elevation: 2,
                  ),
                  const SizedBox(height: 10),
                ],
                if (activeSY)
                  FloatingActionButton.extended(
                    heroTag: 'addMember',
                    onPressed: _showAddStudentSheet,
                    backgroundColor: ThemeManager.brand,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text(''),
                    elevation: 2,
                  ),
              ],
            )
          : null,
      body: Column(
        children: [
          isLandscape
              ? _buildPcTopBar(isFirstLoad, isUserSupervisor, isUserAdmin, activeSY, isDark)
              : _buildMobileFilterBar(isFirstLoad, isUserSupervisor, isDark),
          if (myIsPendingDelete) _buildMyStatusBanner(context),
          _buildOfflineBanner(context, isDark),
          if (!isLandscape) _buildMemberCountRow(context, displayMembers),
          Expanded(child: _buildMemberList(context, displayMembers, isFirstLoad, isDark)),
        ],
      ),
    );
  }

  // ── Status banner ──────────────────────────────────────────────────────────

  Widget _buildMyStatusBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your account is pending deletion. Contact your administrator if this is a mistake.',
              style: GoogleFonts.dmSans(color: _warning, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── PC toolbar ─────────────────────────────────────────────────────────────

  Widget _buildPcTopBar(bool isFirstLoad, bool isUserSupervisor, bool isUserAdmin, bool activeSY, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceElevated(context),
        border: Border(bottom: BorderSide(color: ThemeManager.dividerColor(context))),
      ),
      child: Row(
        children: [
          // Search
          SizedBox(
            width: 220,
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
                  hintText: 'Search members…',
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

          _pcFilterChip(context, 'All', selectedRole == null, () => setState(() => selectedRole = null)),
          const SizedBox(width: 4),
          _pcFilterChip(
            context,
            'Supervisor',
            selectedRole == 'Supervisor',
            () => setState(() => selectedRole = 'Supervisor'),
          ),
          const SizedBox(width: 4),
          _pcFilterChip(context, 'Student', selectedRole == 'Student', () => setState(() => selectedRole = 'Student')),

          Container(
            width: 1,
            height: 20,
            color: ThemeManager.dividerColor(context),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),

          const Spacer(),

          if (_membersStore.lastFetched != null)
            Text(
              'Synced ${_formatLastFetched(_membersStore.lastFetched!)}',
              style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context)),
            ),
          const SizedBox(width: 10),

          // Refresh
          SizedBox(
            height: 34,
            width: 34,
            child: OutlinedButton(
              onPressed: _loadMembers,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: ThemeManager.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _membersStore.isLoading && !isFirstLoad
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ThemeManager.blue(context)),
                    )
                  : Icon(Icons.refresh_rounded, size: 16, color: ThemeManager.secondary(context)),
            ),
          ),

          if (activeSY && isUserSupervisor) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 34,
              child: ElevatedButton.icon(
                onPressed: _showAddSupervisorSheet,
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 16),
                label: Text('Add Supervisor', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 34,
              child: ElevatedButton.icon(
                onPressed: _showAddStudentSheet,
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: Text('Add Member', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeManager.brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pcFilterChip(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
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

  // ── Mobile filter bar ──────────────────────────────────────────────────────

  Widget _buildMobileFilterBar(bool isFirstLoad, bool isUserSupervisor, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceElevated(context),
        boxShadow: isDark ? null : [const BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchField(context)),
              const SizedBox(width: 8),
              _buildRefreshButton(context, isFirstLoad),
            ],
          ),
          if (_membersStore.lastFetched != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Last synced: ${_formatLastFetched(_membersStore.lastFetched!)}',
                  style: GoogleFonts.dmSans(fontSize: 10, color: ThemeManager.muted(context)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          _buildChipRow(context, [
            _ChipData('All', selectedRole == null, () => setState(() => selectedRole = null)),
            if (!isUserSupervisor)
              _ChipData('Supervisor', selectedRole == 'Supervisor', () => setState(() => selectedRole = 'Supervisor')),
            _ChipData('Student', selectedRole == 'Student', () => setState(() => selectedRole = 'Student')),
          ]),
          const SizedBox(height: 6),
          _buildChipRow(context, [
            _ChipData('All Progress', selectedProgress == null, () => setState(() => selectedProgress = null)),
            _ChipData(
              'Completed',
              selectedProgress == 'done',
              () => setState(() => selectedProgress = 'done'),
              color: _success,
              icon: Icons.check_circle_rounded,
            ),
            _ChipData(
              'In Progress',
              selectedProgress == 'ongoing',
              () => setState(() => selectedProgress = 'ongoing'),
              color: _warning,
              icon: Icons.timelapse_rounded,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildChipRow(BuildContext context, List<_ChipData> chips) {
    return SizedBox(
      height: 28,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: chips.map((chip) {
          final activeColor = chip.color ?? ThemeManager.brand;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: chip.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: chip.isSelected ? activeColor : ThemeManager.inputFillColor(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: chip.isSelected ? activeColor : ThemeManager.border(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chip.icon != null) ...[
                      Icon(
                        chip.icon,
                        size: 10,
                        color: chip.isSelected ? Colors.white : ThemeManager.secondary(context),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      chip.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: chip.isSelected ? Colors.white : ThemeManager.secondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
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
          hintText: 'Search members',
          hintStyle: GoogleFonts.dmSans(color: ThemeManager.hint(context), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onChanged: (val) => setState(() => searchQuery = val),
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context, bool isFirstLoad) {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(color: ThemeManager.brand, borderRadius: BorderRadius.circular(8)),
      child: _membersStore.isLoading && !isFirstLoad
          ? const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            )
          : IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              color: Colors.white,
              padding: EdgeInsets.zero,
              onPressed: _loadMembers,
            ),
    );
  }

  // ── Banners & count ────────────────────────────────────────────────────────

  Widget _buildOfflineBanner(BuildContext context, bool isDark) {
    if (_membersStore.error == null || _membersStore.members.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.orange.withOpacity(0.08) : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.orange.withOpacity(0.25) : Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.orange[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline mode — showing cached data',
              style: GoogleFonts.dmSans(color: Colors.orange[700], fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCountRow(BuildContext context, List<Member> displayMembers) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${displayMembers.length} member${displayMembers.length != 1 ? 's' : ''}',
          style: GoogleFonts.dmSans(color: ThemeManager.secondary(context), fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ── Member list ────────────────────────────────────────────────────────────

  Widget _buildMemberList(BuildContext context, List<Member> displayMembers, bool isFirstLoad, bool isDark) {
    if (isFirstLoad) {
      return Center(child: CircularProgressIndicator(color: ThemeManager.blue(context)));
    }
    if (displayMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeManager.brand.withOpacity(isDark ? 0.12 : 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_outlined, size: 40, color: ThemeManager.muted(context)),
            ),
            const SizedBox(height: 16),
            Text(
              'No members found',
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
      onRefresh: _loadMembers,
      color: Colors.white,
      backgroundColor: ThemeManager.brand,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: displayMembers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildMemberCard(context, displayMembers[index], isDark),
      ),
    );
  }

  // ── Member card ────────────────────────────────────────────────────────────

  Widget _buildMemberCard(BuildContext context, Member member, bool isDark) {
    final isSupervisor = member.role == 'supervisor';
    final isAdmin = member.isAdmin == true;
    final isStudent = !isSupervisor;
    final pendingDelete = _isPendingDelete(member);
    final bool isDone = member.isDone ?? false;
    final double progress = member.progress ?? 0.0;
    final Color progressColor = _progressColor(progress);

    final Color accentColor = pendingDelete
        ? _warning
        : isAdmin
        ? _violet
        : isSupervisor
        ? ThemeManager.brand
        : isDone
        ? _success
        : _teal;

    final String roleLabel = pendingDelete
        ? 'Pending Delete'
        : isAdmin
        ? 'Admin'
        : isSupervisor
        ? 'Supervisor'
        : isDone
        ? 'Completed'
        : 'Student';

    final IconData roleIcon = pendingDelete
        ? Icons.hourglass_top_rounded
        : isAdmin
        ? Icons.shield_rounded
        : isSupervisor
        ? Icons.manage_accounts_rounded
        : isDone
        ? Icons.check_circle_rounded
        : Icons.school_outlined;

    final cardBorderColor = pendingDelete
        ? _warning.withOpacity(0.4)
        : (isAdmin || isSupervisor || isDone)
        ? accentColor.withOpacity(0.22)
        : ThemeManager.border(context);

    return Container(
      decoration: BoxDecoration(
        color: ThemeManager.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorderColor),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MemberDetailScreen(
                member: member,
                onClose: () async => _membersStore.fetchMembers(
                  _loginStore.user.value['ccc_id'],
                  _loginStore.user.value['changeable_current_iteration'],
                ),
              ),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent stripe
                Container(width: 4, color: accentColor),

                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Main row ──────────────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar
                            _buildMemberAvatar(member, accentColor),
                            const SizedBox(width: 12),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name + role badge
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          member.fullNameExtended,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: ThemeManager.primary(context),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildRoleBadge(context, roleLabel, roleIcon, accentColor),
                                    ],
                                  ),
                                  const SizedBox(height: 5),

                                  // ID + schedules row
                                  Row(
                                    children: [
                                      Icon(Icons.badge_outlined, size: 11, color: ThemeManager.muted(context)),
                                      const SizedBox(width: 3),
                                      Text(
                                        member.customId ?? member.cccId,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.muted(context),
                                        ),
                                      ),
                                      if (isStudent && member.totalSchedules != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 3,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: ThemeManager.faint(context),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 11,
                                          color: ThemeManager.muted(context),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${member.totalSchedules} days',
                                          style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context)),
                                        ),
                                      ],
                                    ],
                                  ),

                                  // Course (students only)
                                  if (isStudent && member.course != null) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(Icons.school_outlined, size: 11, color: ThemeManager.muted(context)),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            member.course!,
                                            style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, color: ThemeManager.faint(context), size: 18),
                          ],
                        ),

                        // ── Progress section (students only) ──────────────
                        if (isStudent) ...[
                          const SizedBox(height: 10),
                          Divider(height: 1, color: ThemeManager.dividerColor(context)),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                isDone ? Icons.check_circle_rounded : Icons.timelapse_rounded,
                                size: 12,
                                color: progressColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 5,
                                    backgroundColor: ThemeManager.surfaceTint(context),
                                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                member.progressLabel,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: progressColor,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '· ${member.hoursLabel}',
                                style: GoogleFonts.dmSans(fontSize: 10, color: ThemeManager.muted(context)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberAvatar(Member member, Color accentColor) {
    final initials = member.initials;
    final profileLink = member.profileLink;
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withOpacity(0.22), width: 1.5),
      ),
      child: profileLink != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                profileLink,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold, color: accentColor),
              ),
            ),
    );
  }

  Widget _buildRoleBadge(BuildContext context, String label, IconData icon, Color color) {
    final isDark = ThemeManager.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

class _ChipData {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;
  const _ChipData(this.label, this.isSelected, this.onTap, {this.color, this.icon});
}
