import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/store/logs_store.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> with TickerProviderStateMixin {
  LogType? selectedType;
  String searchQuery = '';
  String? selectedSort;

  final List<String> sortOptions = ['Newest', 'Oldest', 'Type A-Z', 'Type Z-A'];

  // Each log item gets its own animation controller, but we cap at 20 for perf
  final List<AnimationController> _itemControllers = [];
  int _lastRenderedCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeLogs();
  }

  Future<void> _initializeLogs() async {
    final store = Provider.of<LogsStore>(context, listen: false);
    await store.loadFromLocal();
    await store.fetchAllLogs();
  }

  Future<void> _refresh() async {
    _disposeItemControllers();
    setState(() => _lastRenderedCount = 0);
    final store = Provider.of<LogsStore>(context, listen: false);
    await store.fetchAllLogs();
  }

  void _disposeItemControllers() {
    for (final c in _itemControllers) {
      c.dispose();
    }
    _itemControllers.clear();
  }

  @override
  void dispose() {
    _disposeItemControllers();
    super.dispose();
  }

  void _ensureControllers(int count) {
    final needed = count.clamp(0, 20);
    if (_itemControllers.length == needed) return;
    _disposeItemControllers();
    for (int i = 0; i < needed; i++) {
      _itemControllers.add(AnimationController(vsync: this, duration: const Duration(milliseconds: 280)));
    }
    _lastRenderedCount = needed;
    _staggerItems(needed);
  }

  void _staggerItems(int count) async {
    for (int i = 0; i < count; i++) {
      await Future.delayed(Duration(milliseconds: 40 * i));
      if (mounted && i < _itemControllers.length) _itemControllers[i].forward();
    }
  }

  List<LogEntry> _filtered(List<LogEntry> logs) {
    var out = selectedType != null ? logs.where((l) => l.type == selectedType).toList() : [...logs];
    if (searchQuery.isNotEmpty) {
      out = out.where((l) => l.message.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    switch (selectedSort ?? 'Newest') {
      case 'Newest': out.sort((a, b) => b.timestamp.compareTo(a.timestamp)); break;
      case 'Oldest': out.sort((a, b) => a.timestamp.compareTo(b.timestamp)); break;
      case 'Type A-Z': out.sort((a, b) => a.type.toString().compareTo(b.type.toString())); break;
      case 'Type Z-A': out.sort((a, b) => b.type.toString().compareTo(a.type.toString())); break;
    }
    return out;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    return Consumer<LogsStore>(
      builder: (context, store, _) {
        final logs = _filtered(store.logs);
        final isFirstLoad = store.logs.isEmpty && store.isLoading;

        if (!isFirstLoad && logs.length != _lastRenderedCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _ensureControllers(logs.length);
          });
        }

        return Scaffold(
          backgroundColor: ThemeManager.scaffold(context),
          body: Column(
            children: [
              _buildFilterBar(store, isFirstLoad, isDark),
              _buildCountRow(logs, isDark),
              Expanded(
                child: isFirstLoad
                    ? Center(child: CircularProgressIndicator(color: ThemeManager.blue(context)))
                    : logs.isEmpty
                        ? _buildEmpty(isDark)
                        : RefreshIndicator(
                            onRefresh: _refresh,
                            color: Colors.white,
                            backgroundColor: const Color(0xFF1B3769),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                              itemCount: logs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (_, i) {
                                if (i < _itemControllers.length) {
                                  final ctrl = _itemControllers[i];
                                  final fade = CurvedAnimation(parent: ctrl, curve: Curves.easeOut);
                                  final slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                                      .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));
                                  return FadeTransition(
                                    opacity: fade,
                                    child: SlideTransition(position: slide, child: _logItem(logs[i], isDark)),
                                  );
                                }
                                return _logItem(logs[i], isDark);
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Filter Bar ────────────────────────────────────────────────────────────

  Widget _buildFilterBar(LogsStore store, bool isFirstLoad, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceElevated(context),
        boxShadow: isDark
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
                      prefixIcon: Icon(Icons.search_rounded, color: ThemeManager.muted(context), size: 17),
                      hintText: 'Search logs…',
                      hintStyle: GoogleFonts.dmSans(color: ThemeManager.hint(context), fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => searchQuery = v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(color: const Color(0xFF1B3769), borderRadius: BorderRadius.circular(8)),
                child: store.isLoading && !isFirstLoad
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                        onPressed: _refresh,
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
                      _chip('All', null == selectedType, () => setState(() => selectedType = null), isDark),
                      _chip('Time In', selectedType == LogType.timeIn, () => setState(() => selectedType = LogType.timeIn), isDark),
                      _chip('Time Out', selectedType == LogType.timeOut, () => setState(() => selectedType = LogType.timeOut), isDark),
                      _chip('Create', selectedType == LogType.create, () => setState(() => selectedType = LogType.create), isDark),
                      _chip('Update', selectedType == LogType.update, () => setState(() => selectedType = LogType.update), isDark),
                      _chip('Delete', selectedType == LogType.delete, () => setState(() => selectedType = LogType.delete), isDark),
                      _chip('Error', selectedType == LogType.error, () => setState(() => selectedType = LogType.error), isDark),
                      _chip('Info', selectedType == LogType.info, () => setState(() => selectedType = LogType.info), isDark),
                      Container(
                          width: 1, height: 20,
                          color: ThemeManager.dividerColor(context),
                          margin: const EdgeInsets.symmetric(horizontal: 6)),
                      ...sortOptions.map((s) {
                        final sel = (selectedSort ?? 'Newest') == s;
                        return _chip(s, sel, () => setState(() => selectedSort = s), isDark);
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

  Widget _chip(String label, bool selected, VoidCallback onTap, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: ThemeManager.inputFillColor(context),
        selectedColor: const Color(0xFF1B3769),
        checkmarkColor: Colors.white,
        labelStyle: GoogleFonts.dmSans(
          color: selected ? Colors.white : ThemeManager.secondary(context),
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(color: selected ? const Color(0xFF1B3769) : ThemeManager.border(context)),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      ),
    );
  }

  Widget _buildCountRow(List<LogEntry> logs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 3),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${logs.length} log${logs.length != 1 ? 's' : ''}',
          style: GoogleFonts.dmSans(color: ThemeManager.secondary(context), fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3769).withOpacity(isDark ? 0.12 : 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 38, color: ThemeManager.muted(context)),
          ),
          const SizedBox(height: 14),
          Text('No logs found',
              style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: ThemeManager.secondary(context))),
          const SizedBox(height: 4),
          Text('Try adjusting your filters',
              style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.muted(context))),
        ],
      ),
    );
  }

  // ── Log Item ──────────────────────────────────────────────────────────────

  static const Map<LogType, _LogStyle> _styles = {
    LogType.timeIn:  _LogStyle(Icons.login_rounded,         Color(0xFF10B981)),
    LogType.timeOut: _LogStyle(Icons.logout_rounded,         Color(0xFFFF4E0B)),
    LogType.create:  _LogStyle(Icons.add_circle_rounded,    Color(0xFF2563EB)),
    LogType.update:  _LogStyle(Icons.edit_rounded,           Color(0xFF7C3AED)),
    LogType.delete:  _LogStyle(Icons.delete_rounded,         Color(0xFFDC2626)),
    LogType.sync:    _LogStyle(Icons.sync_rounded,           Color(0xFF0891B2)),
    LogType.error:   _LogStyle(Icons.error_rounded,          Color(0xFFDC2626)),
    LogType.info:    _LogStyle(Icons.info_rounded,           Color(0xFF6B7280)),
  };

  Widget _logItem(LogEntry log, bool isDark) {
    final style = _styles[log.type] ?? const _LogStyle(Icons.info_rounded, Color(0xFF6B7280));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeManager.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ThemeManager.border(context)),
        boxShadow: isDark
            ? null
            : [const BoxShadow(color: Color(0x05000000), blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: style.color.withOpacity(isDark ? 0.12 : 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(style.icon, color: style.color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.message,
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w500, color: ThemeManager.primary(context))),
                const SizedBox(height: 3),
                Text(
                  DateFormat('MMM dd, yyyy  h:mm a').format(log.timestamp),
                  style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: style.color.withOpacity(isDark ? 0.1 : 0.07),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              log.type.toString().split('.').last,
              style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: style.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogStyle {
  final IconData icon;
  final Color color;
  const _LogStyle(this.icon, this.color);
}