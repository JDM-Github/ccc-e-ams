import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ccc_ojt_schedule/components/web_download_excel_stub.dart' if (dart.library.html) 'package:ccc_ojt_schedule/components/web_download_excel.dart';

Future<String?> _saveExcelBytes(Uint8List bytes, String fileName) async {
  try {
    if (kIsWeb) {
      await saveExcelBytesWeb(bytes, fileName);
      return '';
    } else if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return null;
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } else if (Platform.isWindows) {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel File',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );
      return result;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }
  } catch (e) {
    debugPrint('_saveExcelBytes error: $e');
    return null;
  }
}

class ExportExcelDialog extends StatefulWidget {
  const ExportExcelDialog({super.key, required this.cccId});
  final String cccId;

  @override
  State<ExportExcelDialog> createState() => _ExportExcelDialogState();
}

class _ExportExcelDialogState extends State<ExportExcelDialog> {
  String _rangeMode = 'all';

  DateTime? _startDate;
  DateTime? _endDate;

  bool _isExporting = false;
  final store = LoginStore();

  String _fmt(DateTime? d) => d == null ? 'Select date' : DateFormat('MMM dd, yyyy').format(d);

  bool get _canExport => _rangeMode == 'all' || (_rangeMode == 'custom' && _startDate != null && _endDate != null);

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    if (!mounted) return; // ✅ safety

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
        if (_startDate != null && _startDate!.isAfter(picked)) {
          _startDate = null;
        }
      }
    });
  }

  Future<void> _export() async {
    if (!_canExport || _isExporting) return;

    setState(() => _isExporting = true);

    try {
      final body = {'ccc_id': widget.cccId};

      if (_rangeMode == 'custom') {
        body['startDate'] = DateFormat('yyyy-MM-dd').format(_startDate!);
        body['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
      }

      final handler = RequestHandler();
      final response = await handler.handleRequest('user/get-schedules-with-details', method: 'POST', body: body);

      if (response['success'] != true) {
        throw Exception(response['message']);
      }

      final data = response['data'] ?? [];

      if (data.isEmpty) {
        if (mounted) {
          AppSnackBar.info(context, 'No records found.');
        }
        return;
      }

      final bytes = await compute(_buildExcel, {
        'data': data,
        'ccc_id': widget.cccId,
        'full_name': response['full_name'] ?? '',
        'course': response['course'] ?? '',
        'range_mode': _rangeMode,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'store': store,
      });

      final fileName = 'OJT_Report_${widget.cccId}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      final savedPath = await _saveExcelBytes(bytes, fileName);

      if (mounted) {
        if (savedPath != null && savedPath.isNotEmpty) {
          AppSnackBar.success(context, 'Saved to: $savedPath');
          await OpenFile.open(savedPath);
        } else {
          AppSnackBar.success(context, 'Excel exported successfully');
        }

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Export failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        // ✅ FIX HERE
        color: Colors.transparent,
        child: Container(
          width: 440,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: ThemeManager.surfaceElevated(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ThemeManager.borderStrong(context)),
            boxShadow: ThemeManager.isDark(context)
                ? null
                : [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Divider(height: 1, color: ThemeManager.dividerColor(context)),
              _buildBody(),
              Divider(height: 1, color: ThemeManager.dividerColor(context)),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _icon(Icons.table_chart_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export to Excel',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ThemeManager.primary(context),
                  ),
                ),
                Text(
                  'Download OJT schedule records',
                  style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context)),
                ),
              ],
            ),
          ),
          _closeBtn(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('DATE RANGE'),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _rangeCard('All Records', 'all')),
              const SizedBox(width: 10),
              Expanded(child: _rangeCard('Custom Range', 'custom')),
            ],
          ),

          if (_rangeMode == 'custom') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _dateTile('Start Date', _startDate, true)),
                const SizedBox(width: 10),
                Expanded(child: _dateTile('End Date', _endDate, false)),
              ],
            ),
          ],

          const SizedBox(height: 20),
          _infoBanner(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isExporting ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeManager.secondary(context),
                side: BorderSide(color: ThemeManager.border(context)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (_isExporting || !_canExport) ? null : _export,
              icon: _isExporting
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded, size: 15),
              label: Text(
                _isExporting ? 'Exporting...' : 'Export Excel',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeManager.blue(context),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                disabledBackgroundColor: ThemeManager.border(context),
                disabledForegroundColor: ThemeManager.faint(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _icon(IconData icon) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: ThemeManager.blue(context).withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: 20, color: ThemeManager.blue(context)),
  );

  Widget _closeBtn() => GestureDetector(
    onTap: _isExporting ? null : () => Navigator.pop(context),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceTint(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeManager.border(context)),
      ),
      child: Icon(Icons.close_rounded, size: 16, color: ThemeManager.secondary(context)),
    ),
  );

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.dmSans(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: ThemeManager.muted(context),
      letterSpacing: 1.2,
    ),
  );

  Widget _rangeCard(String label, String value) {
    final selected = _rangeMode == value;

    return GestureDetector(
      onTap: _isExporting ? null : () => setState(() => _rangeMode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? ThemeManager.blue(context).withOpacity(0.08) : ThemeManager.inputFillColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? ThemeManager.blue(context) : ThemeManager.inputBorderColor(context)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? ThemeManager.blue(context) : ThemeManager.secondary(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateTile(String label, DateTime? date, bool isStart) {
    final hasDate = date != null;

    return InkWell(
      onTap: _isExporting ? null : () => _pickDate(isStart: isStart),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ThemeManager.inputFillColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ThemeManager.inputBorderColor(context)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: ThemeManager.blue(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context))),
                  const SizedBox(height: 2),
                  Text(
                    _fmt(date),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasDate ? ThemeManager.primary(context) : ThemeManager.faint(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBanner() {
    final invalid = _rangeMode == 'custom' && (_startDate == null || _endDate == null);

    final color = invalid ? Colors.amber : Colors.green;

    final text = _rangeMode == 'all'
        ? 'All records will be exported.'
        : invalid
        ? 'Select start and end date.'
        : 'Exporting from ${_fmt(_startDate)} to ${_fmt(_endDate)}';

    final isDark = ThemeManager.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.1) : color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? color.withOpacity(0.25) : color[200]!),
      ),
      child: Row(
        children: [
          Icon(
            invalid ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
            size: 15,
            color: isDark ? color[300] : color[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? color[300] : color[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


Uint8List _buildExcel(Map<String, dynamic> args) {
  final LoginStore store = args['store'];
  final List<dynamic> data = args['data'];
  final String cccId = args['ccc_id'] ?? '';
  final String fullName = args['full_name'] ?? '';
  final String course = args['course'] ?? '';
  final String rangeMode = args['range_mode'] ?? 'all';
  final DateTime? startDate =
      args['start_date'] != null ? DateTime.tryParse(args['start_date']) : null;
  final DateTime? endDate =
      args['end_date'] != null ? DateTime.tryParse(args['end_date']) : null;

  final excel = Excel.createExcel();
  final Sheet sheet = excel['OJT Schedule Report'];
  if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

  ExcelColor hex(String h) {
    h = h.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return ExcelColor.fromInt(int.parse(h, radix: 16));
  }

  CellStyle titleStyle = CellStyle(
    bold: true,
    fontSize: 16,
    fontColorHex: hex('#1B3769'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle subTitleStyle = CellStyle(
    bold: true,
    fontSize: 11,
    fontColorHex: hex('#1B3769'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle labelStyle = CellStyle(
    bold: true,
    fontSize: 10,
    fontColorHex: hex('#64748B'),
  );

  CellStyle valueStyle = CellStyle(
    fontSize: 10,
    fontColorHex: hex('#0F172A'),
  );

  CellStyle headerStyle = CellStyle(
    bold: true,
    fontSize: 10,
    backgroundColorHex: hex('#1B3769'),
    fontColorHex: hex('#FFFFFF'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle dataCenter = CellStyle(
    fontSize: 10,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle dataLeft = CellStyle(
    fontSize: 10,
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle completedStyle = CellStyle(
    fontSize: 10,
    fontColorHex: hex('#16A34A'),
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle pendingStyle = CellStyle(
    fontSize: 10,
    fontColorHex: hex('#F59E0B'),
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle notCountedStyle = CellStyle(
    fontSize: 10,
    fontColorHex: hex('#DC2626'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle totalLabelStyle = CellStyle(
    bold: true,
    fontSize: 11,
    fontColorHex: hex('#1B3769'),
    horizontalAlign: HorizontalAlign.Right,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle totalValueStyle = CellStyle(
    bold: true,
    fontSize: 11,
    fontColorHex: hex('#1B3769'),
    backgroundColorHex: hex('#EFF6FF'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  void setCell(Sheet s, int col, int row, CellValue value, CellStyle style) {
    final cell = s.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = value;
    cell.cellStyle = style;
  }

  int row = 0;
  sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row));
  setCell(sheet, 0, row, TextCellValue('OJT SCHEDULE REPORT'), titleStyle);
  row++;

  sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row));
  final rangeLabel = rangeMode == 'all'
      ? 'All Records'
      : '${DateFormat('MMM dd, yyyy').format(startDate!)} – ${DateFormat('MMM dd, yyyy').format(endDate!)}';
  setCell(sheet, 0, row, TextCellValue(rangeLabel), subTitleStyle);
  row += 2;
  final infoRows = [
    ['Student Name', fullName],
    ['CCC ID', cccId],
    ['Course', course],
    ['Generated By',"${store.user.value['first_name']} ${
      store.user.value['middle_name']} ${store.user.value['last_name']}",
    ],
    ['Generated On', DateFormat('MMMM dd, yyyy hh:mm a').format(DateTime.now())],
  ];

  for (final info in infoRows) {
    setCell(sheet, 0, row, TextCellValue(info[0]), labelStyle);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));
    setCell(sheet, 1, row, TextCellValue(info[1]), valueStyle);
    row++;
  }

  row += 2;

  final headers = [
    '#', 'Date', 'Day', 'Time In', 'Time Out', 'Hours', 'Type', 'Status', 'Summary', 'Activities',
  ];

  for (int i = 0; i < headers.length; i++) {
    setCell(sheet, i, row, TextCellValue(headers[i]), headerStyle);
  }
  row++;

  double calcHours(String? timeIn, String? timeOut, bool isAcceptedEarly) {
    if (timeIn == null || timeOut == null) return 0;
    int parseMinutes(String t) {
      final parts = t.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    int inMin = parseMinutes(timeIn);
    int outMin = parseMinutes(timeOut);

    if (!isAcceptedEarly && inMin < 8 * 60) inMin = 8 * 60;
    if (outMin <= inMin) return 0;

    int total = outMin - inMin;
    const lunchStart = 12 * 60;
    const lunchEnd = 13 * 60;
    if (outMin > lunchStart && inMin < lunchEnd) {
      final overlapStart = inMin > lunchStart ? inMin : lunchStart;
      final overlapEnd = outMin < lunchEnd ? outMin : lunchEnd;
      total -= (overlapEnd - overlapStart);
    }
    return total / 60.0;
  }

  String fmtTime(String? t) {
    if (t == null) return '--:--';
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }
  int recordNo = 1;
  double grandTotal = 0;

  for (final record in data) {
    final date = DateTime.tryParse(record['date'] ?? '') ?? DateTime.now();
    final isWfh = record['isWorkFromHome'] == true;
    final isAcceptedWfh = record['isAcceptedWorkFromHome'] == true;
    final isInOffice = !isWfh;
    final isAcceptedEarly = record['isAcceptedEarly'] == true;
    final timeIn = record['time_in'] as String?;
    String? timeOut = record['time_out'] as String?;

    final today = DateTime.now();
    final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
    if (isPast && timeOut == null) timeOut = '17:00:00';

    final bool counted = isInOffice || isAcceptedWfh;
    double hours = 0;
    String status;
    if (timeOut == null) {
      status = 'Pending';
    } else if (counted) {
      hours = calcHours(timeIn, timeOut, isAcceptedEarly);
      grandTotal += hours;
      status = 'Completed';
    } else {
      status = 'Not Counted';
    }

    final activities = (record['activities'] as List<dynamic>?)?.length ?? 0;
    final summary = record['summary_text'] as String? ?? '';

    setCell(sheet, 0, row, IntCellValue(recordNo), dataCenter);
    setCell(sheet, 1, row, TextCellValue(DateFormat('MM/dd/yyyy').format(date)), dataCenter);
    setCell(sheet, 2, row, TextCellValue(DateFormat('EEE').format(date)), dataCenter);
    setCell(sheet, 3, row, TextCellValue(fmtTime(timeIn)), dataCenter);
    setCell(sheet, 4, row, TextCellValue(fmtTime(timeOut)), dataCenter);
    setCell(sheet, 5, row, DoubleCellValue(double.parse(hours.toStringAsFixed(2))), dataCenter);
    setCell(sheet, 6, row, TextCellValue(isWfh ? 'Work From Home' : 'In Office'), dataCenter);

    final statusStyle = status == 'Completed'
        ? completedStyle
        : status == 'Pending'
            ? pendingStyle
            : notCountedStyle;
    setCell(sheet, 7, row, TextCellValue(status), statusStyle);

    setCell(sheet, 8, row, TextCellValue(summary.isNotEmpty ? summary : '—'), dataLeft);
    setCell(sheet, 9, row, TextCellValue(activities > 0 ? '$activities photo(s)' : '—'), dataCenter);

    row++;
    recordNo++;
  }

  row++;
  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
    CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
  );
  setCell(sheet, 0, row, TextCellValue('TOTAL HOURS'), totalLabelStyle);
  setCell(sheet, 5, row, DoubleCellValue(double.parse(grandTotal.toStringAsFixed(2))), totalValueStyle);
  final widths = [6.0, 14.0, 8.0, 12.0, 12.0, 10.0, 18.0, 14.0, 40.0, 14.0];
  for (int i = 0; i < widths.length; i++) {
    sheet.setColumnWidth(i, widths[i]);
  }

  final encoded = excel.save();
  if (encoded == null) throw Exception('Failed to encode Excel file.');
  return Uint8List.fromList(encoded);
}
