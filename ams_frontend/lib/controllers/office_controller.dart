// office_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:ccc_ojt_schedule/components/office/restore_confirm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/main.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:ccc_ojt_schedule/store/member_store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ccc_ojt_schedule/components/web_download_stub.dart'
    if (dart.library.html) 'package:ccc_ojt_schedule/components/web_download.dart';
import 'package:path_provider/path_provider.dart';

class OfficeController extends ChangeNotifier {
  final LoginStore loginStore;
  final RequestHandler requestHandler = RequestHandler();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _allowWeekend = false;

  late TextEditingController officeNameCtrl;
  late TextEditingController officeAcronymCtrl;
  late TextEditingController timeInStartCtrl;
  late TextEditingController timeInStartWfhCtrl;
  late TextEditingController timeInEndCtrl;
  late TextEditingController timeOutCapCtrl;
  late TextEditingController officeVisionCtrl;
  late TextEditingController officeMissionCtrl;

  OfficeController({required this.loginStore}) {
    _initControllers();
  }

  // Getters for UI
  bool get isEditing => _isEditing;
  bool get isSaving => _isSaving;
  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  bool get allowWeekend => _allowWeekend;
  bool get isSupervisor => loginStore.user.value['role'] == 'supervisor' || loginStore.user.value['isAdmin'] == true;
  Map<String, dynamic> get user => loginStore.user.value;

  void _initControllers() {
    final u = user;
    officeNameCtrl = TextEditingController(text: u['office_name'] ?? '');
    officeAcronymCtrl = TextEditingController(text: u['office_acronym'] ?? '');
    timeInStartCtrl = TextEditingController(text: u['time_in_start'] ?? '06:30:00');
    timeInStartWfhCtrl = TextEditingController(text: u['time_in_start_wfh'] ?? '08:00:00');
    timeInEndCtrl = TextEditingController(text: u['time_in_end'] ?? '17:00:00');
    timeOutCapCtrl = TextEditingController(text: u['time_out_cap'] ?? '21:00:00');
    officeVisionCtrl = TextEditingController(text: u['office_vision'] ?? '');
    officeMissionCtrl = TextEditingController(text: u['office_mission'] ?? '');
    _allowWeekend = u['allow_weekend'] ?? false;
  }

  void startEdit() {
    _isEditing = true;
    notifyListeners();
  }

  void cancelEdit() {
    _initControllers(); // reset to original values
    _isEditing = false;
    notifyListeners();
  }

  void setAllowWeekend(bool value) {
    _allowWeekend = value;
    notifyListeners();
  }

  Future<void> saveChanges(BuildContext context) async {
    _isSaving = true;
    notifyListeners();
    try {
      final cccId = user['ccc_id'];
      final response = await requestHandler.handleRequest(
        'user/update-office',
        method: 'POST',
        body: {
          'ccc_id': cccId,
          'office_name': officeNameCtrl.text.trim(),
          'office_acronym': officeAcronymCtrl.text.trim(),
          'office_vision': officeVisionCtrl.text.trim(),
          'office_mission': officeMissionCtrl.text.trim(),
          'time_in_start': timeInStartCtrl.text.trim(),
          'time_in_start_wfh': timeInStartWfhCtrl.text.trim(),
          'time_in_end': timeInEndCtrl.text.trim(),
          'time_out_cap': timeOutCapCtrl.text.trim(),
          'allow_weekend': _allowWeekend,
        },
      );
      if (response['success'] == true) {
        final updated = Map<String, dynamic>.from(user);
        updated['office_name'] = officeNameCtrl.text.trim();
        updated['office_acronym'] = officeAcronymCtrl.text.trim();
        updated['office_vision'] = officeVisionCtrl.text.trim();
        updated['office_mission'] = officeMissionCtrl.text.trim();
        updated['time_in_start'] = timeInStartCtrl.text.trim();
        updated['time_in_start_wfh'] = timeInStartWfhCtrl.text.trim();
        updated['time_in_end'] = timeInEndCtrl.text.trim();
        updated['time_out_cap'] = timeOutCapCtrl.text.trim();
        updated['allow_weekend'] = _allowWeekend;
        loginStore.user.value = updated;
        loginStore.saveUser(updated, loginStore.rememberMe.value);
        _isEditing = false;
        notifyListeners();
        if (context.mounted) AppSnackBar.success(context, 'Office settings updated successfully.');
      } else {
        if (context.mounted) AppSnackBar.error(context, response['message'] ?? 'Failed to update office settings.');
      }
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, 'Network error: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> pickTime(BuildContext context, TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1B3769),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
      notifyListeners();
    }
  }

  Future<void> backupOffice(BuildContext context) async {
    _isBackingUp = true;
    notifyListeners();
    AppSnackBar.loading(context, 'Creating backup...', id: 'office-backup');
    try {
      final officeId = user['office_id'];
      final response = await requestHandler.handleRequest('backup/office/$officeId', method: 'GET');

      if (response['success'] != true) {
        AppSnackBar.hide(context, id: 'office-backup');
        AppSnackBar.error(context, response['message'] ?? 'Backup failed.');
        return;
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert(response['backup']);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'backup_${officeId}_$timestamp.json';

      final saved = await _saveFile(fileName, bytes);

      if (!context.mounted) return;
      AppSnackBar.hide(context, id: 'office-backup');

      if (saved) {
        AppSnackBar.success(context, 'Backup saved: $fileName');
      } else {
        AppSnackBar.info(context, 'Backup cancelled.');
      }
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.hide(context, id: 'office-backup');
      AppSnackBar.error(context, 'Backup error: $e');
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  Future<void> restoreOffice(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Backup File',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => RestoreConfirmDialog(fileName: result.files.first.name),
    );
    if (confirmed != true || !context.mounted) return;

    _isRestoring = true;
    notifyListeners();
    AppSnackBar.loading(context, 'Restoring office data...', id: 'office-restore');

    try {
      final jsonString = utf8.decode(result.files.first.bytes!);
      final backup = jsonDecode(jsonString);

      final response = await requestHandler.handleRequest('backup/restore', method: 'POST', body: {'backup': backup});

      if (!context.mounted) return;
      AppSnackBar.hide(context, id: 'office-restore');

      if (response['success'] == true) {
        MembersStore().clearAll();
        await loginStore.logout();
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginOrHomePage(isResetted: true, isLogout: false)), (route) => false);
        }
        
      } else {
        AppSnackBar.error(context, response['message'] ?? 'Restore failed.');
      }
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.hide(context, id: 'office-restore');
      AppSnackBar.error(context, 'Restore error: $e');
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<bool> _saveFile(String fileName, Uint8List bytes) async {
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
          dialogTitle: 'Save Backup',
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

  void disposeControllers() {
    officeNameCtrl.dispose();
    timeInStartCtrl.dispose();
    timeInStartWfhCtrl.dispose();
    timeInEndCtrl.dispose();
    timeOutCapCtrl.dispose();
    officeVisionCtrl.dispose();
    officeMissionCtrl.dispose();
  }
}
