import 'dart:async';
import 'dart:math';

import 'package:ccc_ojt_schedule/components/export_excel.dart';
import 'package:ccc_ojt_schedule/components/schedule/add_record_sheet.dart';
import 'package:ccc_ojt_schedule/components/schedule/record_card.dart';
import 'package:ccc_ojt_schedule/components/schedule/schedule_record.dart';
import 'package:ccc_ojt_schedule/components/schedule/timeout_sheet.dart';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:ccc_ojt_schedule/store/schedule_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late String cccId;
  late double targetLatitude;
  late double targetLongitude;
  late String timeInStart;
  late String timeInStartWfh;
  late String timeInEnd;
  late String timeOutCap;
  late bool allowWeekend;

  StreamSubscription<Position>? _positionStream;
  String? selectedStatus;
  String? selectedSort;
  String searchQuery = '';

  Position? _position;
  LoginStore loginStore = LoginStore();

  final List<String> statusOptions = ['All', 'Done', 'Active'];
  final List<String> sortOptions = ['Newest', 'Oldest', 'Earliest In', 'Latest In'];

  static const _addLoadingId = 'add_record';
  static const _updateLoadingId = 'update_record';

  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) AppSnackBar.error(context, 'Location services are disabled.');
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) AppSnackBar.warning(context, 'Location permission denied.');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) AppSnackBar.error(context, 'Location permission permanently denied. Enable it in settings.');
      await Geolocator.openAppSettings();
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    final user = loginStore.user.value;
    cccId = user['ccc_id'];
    targetLatitude = (user['latitude'] as num?)?.toDouble() ?? 0.0;
    targetLongitude = (user['longitude'] as num?)?.toDouble() ?? 0.0;
    timeInStart = user['time_in_start'] ?? "06:30:00";
    timeInStartWfh = user['time_in_start_wfh'] ?? "08:00:00";
    timeInEnd = user['time_in_end'] ?? "17:00:00";
    timeOutCap = user['time_out_cap'] ?? "21:00:00";
    allowWeekend = user['allow_weekend'] ?? false;
    _initializeSchedules();
  }

  Future<void> _initializeSchedules() async {
    final scheduleStore = Provider.of<ScheduleStore>(context, listen: false);
    await scheduleStore.loadFromLocal();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasPermission = await _ensureLocationPermission();
      if (hasPermission) _getLocationStream();
      scheduleStore.fetchSchedules(cccId);
    });
  }

  Future<void> _refreshSchedules() async {
    final hasPermission = await _ensureLocationPermission();
    if (hasPermission) _getLocationStream();
    final scheduleStore = Provider.of<ScheduleStore>(context, listen: false);
    await scheduleStore.fetchSchedules(loginStore.user.value['ccc_id']);
  }

  bool isInOffice({double radiusInMeters = 20}) {
    if (_position == null) return false;
    return _calculateDistance(_position!.latitude, _position!.longitude, targetLatitude, targetLongitude) <=
        radiusInMeters;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a =
        (sin(dLat / 2) * sin(dLat / 2)) + cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _degToRad(double deg) => deg * (pi / 180);

  void _getLocationStream() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0),
    ).listen((p) => setState(() => _position = p));
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  DateTime _parseTimeToday(String time) {
    final parts = time.split(":");
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  bool _isWithinTimeInWindow(bool isOffice) {
    final now = DateTime.now();
    final start = _parseTimeToday(isOffice ? timeInStart : timeInStartWfh);
    final end = _parseTimeToday(timeInEnd);
    return now.isAfter(start) && now.isBefore(end);
  }

  TimeOfDay _applyTimeOutCapTOD(TimeOfDay timeOut) {
    final capDT = _parseTimeToday(timeOutCap);
    final outDT = _timeOfDayToDateTime(timeOut);
    final cappedDT = outDT.isAfter(capDT) ? capDT : outDT;
    return _dateTimeToTimeOfDay(cappedDT);
  }

  void _addNewRecord() {
    final scheduleStore = Provider.of<ScheduleStore>(context, listen: false);
    final now = DateTime.now();
    final bool isOffice = isInOffice();

    if (!allowWeekend && _isWeekend(now)) {
      AppSnackBar.warning(context, 'You cannot add records on weekends');
      return;
    }
    if (_hasRecordForDate(now, scheduleStore.schedules)) {
      AppSnackBar.warning(context, 'A record for today already exists');
      return;
    }
    if (!_isWithinTimeInWindow(isOffice)) {
      final start = isOffice ? timeInStart : timeInStartWfh;
      AppSnackBar.warning(context, 'Time-in allowed only between $start and $timeInEnd');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddRecordSheet(
        isInOffice: isOffice,
        onSave: (record) async {
          record.isInOffice = isOffice;
          AppSnackBar.loading(
            context,
            'Saving record… (Allowed: ${isOffice ? timeInStart : timeInStartWfh} - $timeInEnd)',
            id: _addLoadingId,
          );
          try {
            await scheduleStore.addSchedule(record);
            if (mounted) {
              AppSnackBar.hide(context, id: _addLoadingId);
              AppSnackBar.success(context, 'Record added (Time-in window enforced)');
            }
          } catch (_) {
            if (mounted) {
              AppSnackBar.hide(context, id: _addLoadingId);
              AppSnackBar.error(context, 'Failed to add record. Please try again.');
            }
          }
        },
      ),
    );
  }

  DateTime _timeOfDayToDateTime(TimeOfDay tod) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
  }

  TimeOfDay _dateTimeToTimeOfDay(DateTime dt) => TimeOfDay(hour: dt.hour, minute: dt.minute);

  void _addTimeOut(int index) {
    final scheduleStore = Provider.of<ScheduleStore>(context, listen: false);
    final displayRecords = _getFilteredAndSortedRecords(scheduleStore.schedules);
    final originalIndex = scheduleStore.schedules.indexOf(displayRecords[index]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TimeOutSheet(
        onSave: (timeOut, proofOut, proofImageFile) async {
          final record = scheduleStore.schedules[originalIndex];
          final capped = _applyTimeOutCapTOD(timeOut);
          final wasCapped = _timeOfDayToDateTime(timeOut).isAfter(_timeOfDayToDateTime(capped));
          record.timeOut = capped;
          record.proofOut = proofOut;
          record.proofOutFile = proofImageFile;
          AppSnackBar.loading(context, 'Recording time out… (Max allowed: $timeOutCap)', id: _updateLoadingId);
          try {
            await scheduleStore.updateSchedule(originalIndex, record);
            if (mounted) {
              AppSnackBar.hide(context, id: _updateLoadingId);
              if (wasCapped) {
                AppSnackBar.warning(context, 'Time-out capped to $timeOutCap (office policy)');
              } else {
                AppSnackBar.success(context, 'Time out recorded (Max allowed: $timeOutCap)');
              }
            }
          } catch (_) {
            if (mounted) {
              AppSnackBar.hide(context, id: _updateLoadingId);
              AppSnackBar.error(context, 'Failed to record time out. Please try again.');
            }
          }
        },
      ),
    );
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);
    return recordDate.isBefore(today);
  }

  List<ScheduleRecord> _getFilteredAndSortedRecords(List<ScheduleRecord> records) {
    List<ScheduleRecord> filtered = List.from(records);
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final dateStr = '${r.date.year}-${r.date.month}-${r.date.day}';
        return dateStr.contains(searchQuery.toLowerCase());
      }).toList();
    }
    switch (selectedStatus) {
      case 'Done':
        filtered = filtered.where((r) => r.timeOut != null || _isPastDate(r.date)).toList();
        break;
      case 'Active':
        filtered = filtered.where((r) => r.timeOut == null && !_isPastDate(r.date)).toList();
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

  bool _isWeekend(DateTime date) => date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  bool _hasRecordForDate(DateTime date, List<ScheduleRecord> records) =>
      records.any((r) => r.date.year == date.year && r.date.month == date.month && r.date.day == date.day);

  bool _canAddRecord(List<ScheduleRecord> records) {
    final now = DateTime.now();
    final isOffice = isInOffice();
    if (!allowWeekend && _isWeekend(now)) return false;
    if (_hasRecordForDate(now, records)) return false;
    if (!_isWithinTimeInWindow(isOffice)) return false;
    return true;
  }

  String _formatLastFetched(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final isDark = ThemeManager.isDark(context);
    final isActive =
        loginStore.user.value['user_sy'] ==
        loginStore.user.value['current_sy'] + loginStore.user.value['current_iteration'] - 1;

    return Consumer<ScheduleStore>(
      builder: (context, scheduleStore, child) {
        final displayRecords = _getFilteredAndSortedRecords(scheduleStore.schedules);
        final isFirstLoad = scheduleStore.schedules.isEmpty && scheduleStore.isLoading;

        return Scaffold(
          backgroundColor: ThemeManager.scaffold(context),
          floatingActionButton: (isLandscape || !isActive) ? null : _buildFAB(scheduleStore),
          body: Column(
            children: [
              isLandscape
                  ? _buildPcTopBar(context, scheduleStore, displayRecords, isActive, isDark)
                  : _buildMobileFilterBar(context, scheduleStore, isDark),
              _buildOfflineBanner(context, scheduleStore, isDark),
              if (!isLandscape) _buildRecordCountRow(context, displayRecords, isDark),
              Expanded(child: _buildRecordList(context, scheduleStore, displayRecords, isFirstLoad, isDark)),
            ],
          ),
        );
      },
    );
  }

  // ── PC Top Bar ─────────────────────────────────────────────────────────────

  Widget _buildPcTopBar(
    BuildContext context,
    ScheduleStore scheduleStore,
    List<ScheduleRecord> displayRecords,
    bool isActive,
    bool isDark,
  ) {
    final isFirstLoad = scheduleStore.schedules.isEmpty && scheduleStore.isLoading;
    final inOffice = isInOffice();

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

          // Status filters
          _pcFilterChip(context, 'All', selectedStatus == null, () => setState(() => selectedStatus = null), isDark),
          
          const SizedBox(width: 4),
          _pcFilterChip(
            context,
            'Active',
            selectedStatus == 'Active',
            () => setState(() => selectedStatus = 'Active'),
            isDark,
          ),
          const SizedBox(width: 4),
          _pcFilterChip(
            context,
            'Done',
            selectedStatus == 'Done',
            () => setState(() => selectedStatus = 'Done'),
            isDark,
          ),

          Container(
            width: 1,
            height: 20,
            color: ThemeManager.dividerColor(context),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),

          _pcSortDropdown(context, isDark),
          const Spacer(),

          // In/Out Office badge
          _buildLocationBadge(context, inOffice, isDark),
          const SizedBox(width: 10),

          // Refresh
          SizedBox(
            height: 34,
            width: 34,
            child: OutlinedButton(
              onPressed: _refreshSchedules,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: ThemeManager.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: scheduleStore.isLoading && !isFirstLoad
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ThemeManager.blue(context)),
                    )
                  : Icon(Icons.refresh_rounded, size: 16, color: ThemeManager.secondary(context)),
            ),
          ),

          // Add record
          if (isActive) ...[
            const SizedBox(width: 8),
            Consumer<ScheduleStore>(
              builder: (context, store, _) {
                final canAdd = _canAddRecord(store.schedules);
                return SizedBox(
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: canAdd ? _addNewRecord : null,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('Add Record', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B3769),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: ThemeManager.surfaceTint(context),
                      disabledForegroundColor: ThemeManager.muted(context),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(width: 8),

          // Export
          SizedBox(
            height: 34,
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ExportExcelDialog(cccId: cccId),
              ),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: Text('Export', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBadge(BuildContext context, bool inOffice, bool isDark) {
    final color = inOffice ? const Color(0xFF10B981) : ThemeManager.muted(context);
    final bg = inOffice ? const Color(0xFF10B981).withOpacity(isDark ? 0.12 : 0.09) : ThemeManager.surfaceTint(context);
    final border = inOffice ? const Color(0xFF10B981).withOpacity(0.3) : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            inOffice ? 'In Office' : 'Outside Office',
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _pcFilterChip(BuildContext context, String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B3769) : ThemeManager.inputFillColor(context),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFF1B3769) : ThemeManager.border(context)),
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

  Widget _pcSortDropdown(BuildContext context, bool isDark) {
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

  // ── Mobile Filter Bar ──────────────────────────────────────────────────────

  Widget _buildMobileFilterBar(BuildContext context, ScheduleStore scheduleStore, bool isDark) {
    final isFirstLoad = scheduleStore.schedules.isEmpty && scheduleStore.isLoading;
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
              Expanded(child: _buildSearchField(context, isDark)),
              const SizedBox(width: 8),
              _buildRefreshButton(context, scheduleStore, isFirstLoad, isDark),
            ],
          ),
          if (scheduleStore.lastFetched != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Last synced: ${_formatLastFetched(scheduleStore.lastFetched!)}',
                  style: GoogleFonts.dmSans(fontSize: 10, color: ThemeManager.muted(context)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          _buildChipFilters(context, isDark),
        ],
      ),
    );
  }

  Widget _buildFAB(ScheduleStore scheduleStore) {
    return Consumer<ScheduleStore>(
      builder: (context, store, _) {
        final canAdd = _canAddRecord(store.schedules);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'export_fab',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ExportExcelDialog(cccId: cccId),
              ),
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              mini: true,
              elevation: 2,
              child: const Icon(Icons.download_rounded, size: 20),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'add_record_fab',
              onPressed: canAdd ? _addNewRecord : null,
              backgroundColor: canAdd ? const Color(0xFF1B3769) : Colors.grey[400],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text('Add Record', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              elevation: 2,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField(BuildContext context, bool isDark) {
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
          hintText: 'Search by date',
          hintStyle: GoogleFonts.dmSans(color: ThemeManager.hint(context), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onChanged: (val) => setState(() => searchQuery = val),
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context, ScheduleStore scheduleStore, bool isFirstLoad, bool isDark) {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(color: const Color(0xFF1B3769), borderRadius: BorderRadius.circular(8)),
      child: scheduleStore.isLoading && !isFirstLoad
          ? const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            )
          : IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              color: Colors.white,
              padding: EdgeInsets.zero,
              onPressed: _refreshSchedules,
            ),
    );
  }

  Widget _buildChipFilters(BuildContext context, bool isDark) {
    final activeColor = isDark ? const Color(0xFF1B3769) : const Color(0xFF1B3769);

    return SizedBox(
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
                      selectedColor: activeColor,
                      checkmarkColor: Colors.white,
                      labelStyle: GoogleFonts.dmSans(
                        color: isSelected ? Colors.white : ThemeManager.secondary(context),
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      side: BorderSide(color: isSelected ? activeColor : ThemeManager.border(context)),
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
                      selectedColor: activeColor,
                      labelStyle: GoogleFonts.dmSans(
                        color: isSelected ? Colors.white : ThemeManager.secondary(context),
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      side: BorderSide(color: isSelected ? activeColor : ThemeManager.border(context)),
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
    );
  }

  // ── Banners & count row ────────────────────────────────────────────────────

  Widget _buildOfflineBanner(BuildContext context, ScheduleStore scheduleStore, bool isDark) {
    if (scheduleStore.error == null || scheduleStore.schedules.isNotEmpty) {
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

  Widget _buildRecordCountRow(BuildContext context, List<ScheduleRecord> displayRecords, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${displayRecords.length} record${displayRecords.length != 1 ? 's' : ''}',
          style: GoogleFonts.dmSans(color: ThemeManager.secondary(context), fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ── Record List ────────────────────────────────────────────────────────────

  Widget _buildRecordList(
    BuildContext context,
    ScheduleStore scheduleStore,
    List<ScheduleRecord> displayRecords,
    bool isFirstLoad,
    bool isDark,
  ) {
    if (isFirstLoad) {
      return Center(child: CircularProgressIndicator(color: ThemeManager.blue(context)));
    }
    if (displayRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3769).withOpacity(isDark ? 0.12 : 0.06),
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
      onRefresh: _refreshSchedules,
      color: Colors.white,
      backgroundColor: const Color(0xFF1B3769),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: displayRecords.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final record = displayRecords[index];
          return RecordItem(record: record, onAddTimeOut: () => _addTimeOut(index));
        },
      ),
    );
  }
}
