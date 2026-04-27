import 'dart:convert';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/store/member_store.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginStore {
  static final LoginStore _instance = LoginStore._internal();
  factory LoginStore() => _instance;
  LoginStore._internal();

  ValueNotifier<Map<String, dynamic>> user = ValueNotifier({});
  ValueNotifier<Map<String, dynamic>> superAdmin = ValueNotifier({});
  ValueNotifier<bool> rememberMe = ValueNotifier(false);
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  static const String _keyUser = 'logged_in_user';
  static const String _keyRememberMe = 'remember_me';
  static const String _keySuperAdmin = 'logged_in_super_admin';

  Future<void> saveUser(Map<String, dynamic> userData, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    user.value = userData;
    this.rememberMe.value = rememberMe;
    await prefs.setString(_keyUser, jsonEncode(userData));
    await prefs.setBool(_keyRememberMe, rememberMe);
  }

  Future<void> saveUser2(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    user.value = userData;
    await prefs.setString(_keyUser, jsonEncode(userData));
  }

  Future<bool> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final savedSuperAdmin = prefs.getString(_keySuperAdmin);
    if (savedSuperAdmin != null) {
      superAdmin.value = jsonDecode(savedSuperAdmin);
      return true;
    }

    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    if (!rememberMe) return false;

    final loadedUser = prefs.getString(_keyUser);
    if (loadedUser != null) {
      user.value = jsonDecode(loadedUser);
      return true;
    }
    return false;
  }

  Future<void> editUser(Member updatedMember) async {
    try {
      user.value['first_name'] = updatedMember.firstName;
      user.value['middle_name'] = updatedMember.middleName;
      user.value['last_name'] = updatedMember.lastName;
      user.value['suffix_name'] = updatedMember.suffixName;
      user.value['extension_name'] = updatedMember.extensionName;
      user.value['email'] = updatedMember.email;
      user.value['course'] = updatedMember.course;

      final requestHandler = RequestHandler();
      final body = updatedMember.toJson();
      final response = await requestHandler.handleRequest(
        'user/update-user/${updatedMember.cccId}',
        method: 'POST',
        body: body,
      );
      if (response['success'] != true) {
        debugPrint('Failed to sync member update: ${response['message']}');
      } else {
        await saveUser(user.value, rememberMe.value);
      }
    } catch (e) {
      debugPrint('Error editing member: $e');
    }
  }

  Future<dynamic> login(String cccIdOrEmail, String password, bool rememberMe) async {
    isLoading.value = true;

    try {
      final requestHandler = RequestHandler();
      final response = await requestHandler.handleRequest(
        'user/login',
        method: 'POST',
        body: {'identifier': cccIdOrEmail.trim(), 'password': password},
      );

      if (response['success'] == true) {
        if (response['is_super_admin'] == true) {
          final sa = response['super_admin'];
          superAdmin.value = {'id': sa['id'], 'username': sa['username'], 'email': sa['email']};
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keySuperAdmin, jsonEncode(superAdmin.value));
          isLoading.value = false;
          return response;
        }

        final user = response['user'];
        final userData = {
          'ccc_id': user['ccc_id'],
          'email': user['email'],
          'first_name': user['first_name'],
          'middle_name': user['middle_name'],
          'last_name': user['last_name'],
          'suffix_name': user['suffix_name'],
          'extension_name': user['extension_name'],
          'role': user['role'],
          'isAdmin': user['isAdmin'] ?? false,
          'profile_link': user['profile_link'],
          'course': user['course'],
          'target_hours': user['target_hours'],
          'office_id': user['office_id'],
          'office_name': user['office_name'],
          'latitude': user['latitude'],
          'longitude': user['longitude'],
          'altitude': user['altitude'],
          'custom_id': user['custom_id'],
          'status': user['status'],
          'user_sy': user['user_sy'],
          'current_sy': user['current_sy'],
          'current_iteration': user['current_iteration'],
          'changeable_current_iteration': user['current_iteration'],
          'time_in_start': user['time_in_start'],
          'time_in_start_wfh': user['time_in_start_wfh'],
          'time_in_end': user['time_in_end'],
          'time_out_cap': user['time_out_cap'],
          'allow_weekend': user['allow_weekend'],
          'loginTime': DateTime.now().toIso8601String(),
        };
        print('User logged in: $userData');
        await saveUser(userData, rememberMe);
        isLoading.value = false;
        return response;
      }

      isLoading.value = false;
      return response;
    } catch (e) {
      isLoading.value = false;
      return {'success': false, 'message': 'An error occurred during login.'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keySuperAdmin);
    user.value = {};
    superAdmin.value = {};
  }

  bool isLoggedIn() => user.value.isNotEmpty && user.value.containsKey('ccc_id');
  bool isSuperAdminLoggedIn() => superAdmin.value.isNotEmpty;
}
