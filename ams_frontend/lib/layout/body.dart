import 'dart:convert';
import 'dart:io';
import 'package:ccc_ojt_schedule/components/logout.dart';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/screen/about.dart';
import 'package:ccc_ojt_schedule/screen/dashboard.dart';
import 'package:ccc_ojt_schedule/screen/location.dart';
import 'package:ccc_ojt_schedule/screen/logs.dart';
import 'package:ccc_ojt_schedule/screen/members.dart';
import 'package:ccc_ojt_schedule/screen/office.dart';
import 'package:ccc_ojt_schedule/screen/schedule.dart';
import 'package:ccc_ojt_schedule/screen/user.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ccc_ojt_schedule/components/web_download_stub.dart'
    if (dart.library.html) 'package:ccc_ojt_schedule/components/web_download.dart';
import 'package:path_provider/path_provider.dart';

import 'package:ccc_ojt_schedule/components/app_bar/app_bar_widgets.dart';
import 'package:ccc_ojt_schedule/components/app_bar/app_bar_rail_nav.dart';
import 'package:ccc_ojt_schedule/components/app_bar/app_bar_top_bar.dart';
import 'package:ccc_ojt_schedule/components/app_bar/app_bar_advance_sy_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CustomAppBar
// ─────────────────────────────────────────────────────────────────────────────
class CustomAppBar extends StatefulWidget {
  final Function onLogout;
  const CustomAppBar({super.key, required this.onLogout});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  int _currentIndex = 7;

  final LoginStore _loginStore = LoginStore();

  // ── Pages ──────────────────────────────────────────────────────
  final List<Widget> _pages = [
    // Add dashboard here
    SchedulePage(),
    MembersPage(),
    UserPage(),
    LogsPage(),
    LocationPage(),
    OfficePage(),
    AboutPage(),
    DashboardPage(),
  ];

  // ── Nav definitions ────────────────────────────────────────────
  static const _allNavItems = [
    AppNavItem(icon: Icons.schedule_outlined, activeIcon: Icons.schedule, label: 'Dashboard', index: 7),
    AppNavItem(icon: Icons.schedule_outlined, activeIcon: Icons.schedule, label: 'Schedule', index: 0),
    AppNavItem(icon: Icons.groups_outlined, activeIcon: Icons.groups, label: 'Members', index: 1),
    AppNavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Logs', index: 3),
    AppNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', index: 2),
    AppNavItem(icon: Icons.location_on_outlined, activeIcon: Icons.location_on, label: 'Location', index: 4),
    AppNavItem(icon: Icons.business_outlined, activeIcon: Icons.business, label: 'Office', index: 5),
    AppNavItem(icon: Icons.info_outline_rounded, activeIcon: Icons.info_rounded, label: 'About', index: 6),
  ];

  // ── Computed helpers ───────────────────────────────────────────

  bool get _isSupervisor => _loginStore.user.value['role'] == 'supervisor';
  bool get _isAdmin => _loginStore.user.value['isAdmin'] == true;
  bool get _canAdvanceSY => _isSupervisor || _isAdmin;

  List<AppNavItem> get _visibleNavItems => _allNavItems.where((item) {
    if (item.index == 0) return !_isSupervisor;
    if (item.index == 3) return _isSupervisor;
    if (item.index == 5) return _isSupervisor;
    return true;
  }).toList();

  int get _currentSY => _loginStore.user.value['current_sy'] ?? 2025;
  int get _currentIteration => _loginStore.user.value['current_iteration'] ?? 1;
  int get _activeSY => _currentSY + _currentIteration - 1;
  String get _activeSYLabel => '$_activeSY-${_activeSY + 1}';
  int get _changeableIteration => _loginStore.user.value['changeable_current_iteration'] ?? _currentIteration;
  int get _selectedSY => _currentSY + _changeableIteration - 1;
  String get _selectedSYLabel => '$_selectedSY-${_selectedSY + 1}';
  bool get _isViewingCurrentSY => _changeableIteration == _currentIteration;
  List<int> get _syIterations => List.generate(_currentIteration, (i) => i + 1);

  Key _pageKey = UniqueKey();
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = _isSupervisor ? 7 : 7;
  }

  // ── SY change ──────────────────────────────────────────────────

  void _onSYChanged(int iteration) {
    setState(() {
      _loginStore.user.value['changeable_current_iteration'] = iteration;
      _pageKey = UniqueKey();
    });
  }

  // ── File save helper ───────────────────────────────────────────

  Future<bool> _saveFile(Uint8List bytes, String fileName) async {
    try {
      if (kIsWeb) {
        await downloadWebFile(bytes, fileName);
        return true;
      } else if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        final file = File('${dir!.path}/$fileName');
        await file.writeAsBytes(bytes);
        return true;
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup Before Advancing',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes,
        );
        return result != null;
      }
    } catch (e) {
      debugPrint('_saveFile error: $e');
      return false;
    }
  }

  // ── Advance SY flow ────────────────────────────────────────────

  Future<void> _showAdvanceSYDialog(BuildContext context) async {
    for (int step = 1; step <= 3; step++) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => AdvanceSYDialog(
          step: step,
          activeSYLabel: _activeSYLabel,
          nextSYLabel: '${_activeSY + 1}-${_activeSY + 2}',
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    // Backup
    AppSnackBar.loading(context, 'Creating backup...', id: 'advance-backup');
    try {
      final officeId = _loginStore.user.value['office_id'] as String;
      final backupResponse = await RequestHandler().handleRequest('backup/office/$officeId', method: 'GET');

      if (!mounted) return;
      if (backupResponse['success'] != true) {
        AppSnackBar.hide(context, id: 'advance-backup');
        AppSnackBar.error(context, backupResponse['message'] ?? 'Backup failed.');
        return;
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupResponse['backup']);
      final bytes = utf8.encode(jsonString);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'pre_advance_backup_${officeId}_$timestamp.json';
      final saved = await _saveFile(Uint8List.fromList(bytes), fileName);

      if (!mounted) return;
      AppSnackBar.hide(context, id: 'advance-backup');

      if (!saved) {
        AppSnackBar.error(context, 'Backup not saved. Advance cancelled.');
        return;
      }
      AppSnackBar.success(context, 'Backup saved. Advancing...');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.hide(context, id: 'advance-backup');
      AppSnackBar.error(context, 'Backup error: $e');
      return;
    }

    // Advance
    setState(() => _isAdvancing = true);
    AppSnackBar.loading(context, 'Advancing school year...', id: 'advance-id');

    try {
      final cccId = _loginStore.user.value['ccc_id'];
      final response = await RequestHandler().handleRequest('user/advance-iteration/$cccId', method: 'POST', body: {});

      if (!mounted) return;

      if (response['success'] == true) {
        final newIteration = response['current_iteration'] as int;
        final newSY = response['current_sy'] as int;
        final newActiveSY = newSY + newIteration - 1;

        _loginStore.user.value = {
          ..._loginStore.user.value,
          'current_iteration': newIteration,
          'current_sy': newSY,
          'changeable_current_iteration': newIteration,
        };
        _loginStore.saveUser2(_loginStore.user.value);
        await _refreshUserProfile();

        setState(() {
          _pageKey = UniqueKey();
          _isAdvancing = false;
        });
        AppSnackBar.hide(context, id: 'advance-id');
        AppSnackBar.success(context, 'School Year advanced to SY $newActiveSY-${newActiveSY + 1}');
      } else {
        setState(() => _isAdvancing = false);
        AppSnackBar.hide(context, id: 'advance-id');
        AppSnackBar.error(context, response['message'] ?? 'Failed to advance school year');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAdvancing = false);
      AppSnackBar.hide(context, id: 'advance-id');
      AppSnackBar.error(context, 'Network error: $e');
    }
  }

  Future<void> _refreshUserProfile() async {
    try {
      final cccId = _loginStore.user.value['ccc_id'];
      final result = await RequestHandler().handleRequest('user/me/$cccId', method: 'GET');
      if (result['success'] == true) {
        final u = result['user'];
        await _loginStore.saveUser2({
          ..._loginStore.user.value,
          ...u,
          'changeable_current_iteration': u['current_iteration'],
        });
      }
    } catch (e) {
      debugPrint('Failed to refresh user profile: $e');
    }
  }

  // ── Logout dialog ──────────────────────────────────────────────

  Future<void> _showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: const LogoutDialog(),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return KeyedSubtree(
      key: _pageKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: isLandscape ? _buildPcLayout(context) : _buildMobileLayout(context),
      ),
    );
  }

  // ── PC layout ──────────────────────────────────────────────────

  Widget _buildPcLayout(BuildContext context) {
    final user = _loginStore.user.value;
    final navItems = _visibleNavItems;
    final pageLabel = navItems.firstWhere((i) => i.index == _currentIndex, orElse: () => navItems.first).label;

    return Row(
      children: [
        // Sidebar
        AppRailNav(
          items: navItems,
          currentIndex: _currentIndex,
          officeName: user['office_name'] ?? '',
          isSupervisorOrAdmin: _isSupervisor || _isAdmin,
          canAdvanceSY: _canAdvanceSY,
          isViewingCurrentSY: _isViewingCurrentSY,
          selectedSYLabel: _selectedSYLabel,
          syIterations: _syIterations,
          currentIteration: _currentIteration,
          changeableIteration: _changeableIteration,
          currentSY: _currentSY,
          userSY: user['user_sy'] ?? _currentSY,
          onItemTapped: (i) => setState(() => _currentIndex = i),
          onSYChanged: _onSYChanged,
          onAdvanceSY: () => _showAdvanceSYDialog(context),
          onLogout: () => _showLogoutDialog(context),
        ),

        // Main content area
        Expanded(
          child: Column(
            children: [
              AppTopBar(
                pageLabel: pageLabel,
                firstName: user['first_name'] ?? '',
                middleName: user['middle_name'] ?? '',
                lastName: user['last_name'] ?? '',
                suffixName: user['suffix_name'] ?? '',
                extensionName: user['extension_name'] ?? '',
                role: user['role'] ?? 'student',
                course: user['course'] ?? '',
                officeName: user['office_name'] ?? '',
                targetHours: user['target_hours']?.toString() ?? '0',
                profileLink: user['profile_link'],
                isSupervisor: _isSupervisor,
                canAdvanceSY: _canAdvanceSY,
                isAdvancing: _isAdvancing,
                isSupervisorOrAdmin: _isSupervisor || _isAdmin,
                isViewingCurrentSY: _isViewingCurrentSY,
                selectedSYLabel: _selectedSYLabel,
                syIterations: _syIterations,
                currentIteration: _currentIteration,
                changeableIteration: _changeableIteration,
                currentSY: _currentSY,
                userSY: user['user_sy'] ?? _currentSY,
                isAdmin: _isAdmin,
                onSYChanged: _onSYChanged,
                onAdvanceSY: () => _showAdvanceSYDialog(context),
              ),
              Expanded(child: _pages[_currentIndex]),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile layout ──────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    final navItems = _visibleNavItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppMobileBar(
        officeName: _loginStore.user.value['office_name'] ?? '',
        isSupervisorOrAdmin: _isSupervisor || _isAdmin,
        isSupervisor: _isSupervisor,
        canAdvanceSY: _canAdvanceSY,
        isViewingCurrentSY: _isViewingCurrentSY,
        selectedSYLabel: _selectedSYLabel,
        syIterations: _syIterations,
        currentIteration: _currentIteration,
        changeableIteration: _changeableIteration,
        currentSY: _currentSY,
        userSY: _loginStore.user.value['user_sy'] ?? _currentSY,
        onSYChanged: _onSYChanged,
        onAdvanceSY: () => _showAdvanceSYDialog(context),
        onLogout: () => _showLogoutDialog(context),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: AppBottomNav(
        items: navItems,
        currentIndex: _currentIndex,
        onItemTapped: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
