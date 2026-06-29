import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../data/models/user_model.dart';
import '../../features/missing_persons/services/pending_found_requests_service.dart';
import 'api_service.dart';

/// Service for authentication and token management
class AuthService extends GetxService {
  final ApiService _api = Get.find<ApiService>();
  // Match ApiService: first_unlock keeps the saved user readable at launch so
  // the session persists on iOS instead of dropping back to the login screen.
  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _userKey = 'current_user';

  final currentUser = Rx<User?>(null);
  bool get isLoggedIn => currentUser.value != null;

  /// Whether the current user may resolve a missing-person case directly
  /// (mark as found without approval). Only ADMIN and CENTER can; everyone
  /// else (VOLUNTEER, …) must send a request that ADMIN/CENTER approves.
  /// Role text is normalized (trim + uppercase) to match `roleDisplayArOf`.
  bool get canDirectlyResolveMissing {
    final role = (currentUser.value?.role ?? '').trim().toUpperCase();
    return role == 'ADMIN' || role == 'CENTER';
  }

  /// Initialize – restore saved user from secure storage
  Future<AuthService> init() async {
    try {
      final token = await _api.getToken();
      if (token != null) {
        final userJson = await _storage.read(key: _userKey);
        if (userJson != null) {
          currentUser.value =
              User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
          debugPrint('AuthService: Restored user ${currentUser.value?.userName}');
        }
      }
    } catch (e) {
      debugPrint('AuthService: Could not restore session: $e');
    }
    return this;
  }

  /// Login with username and password
  Future<ApiResponse> login(String userName, String password) async {
    final response = await _api.post('/auth/login', body: {
      'userName': userName,
      'password': password,
    });

    if (response.isSuccess && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);

      await _api.saveToken(token);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      currentUser.value = user;

      debugPrint('AuthService: Logged in as ${user.userName} (${user.role})');
    }
    return response;
  }

  /// Change the signed-in user's password.
  ///
  /// On success the API rotates the JWT and returns the updated user with
  /// `isTempPass: false`. We persist the new token and user so the
  /// temporary-password gate clears. Mirrors the web change-password flow.
  Future<ApiResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _api.patch('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });

    if (response.isSuccess) {
      final data = response.data;
      String? newToken;
      User? updated;
      if (data is Map<String, dynamic>) {
        newToken = data['access_token'] as String?;
        final userJson = data['user'];
        if (userJson is Map<String, dynamic>) {
          updated = User.fromJson(userJson);
        }
      }
      // Fall back to clearing the temp flag locally when the API doesn't
      // echo the user object back.
      updated ??= currentUser.value?.copyWith(isTempPass: false);

      if (newToken != null && newToken.isNotEmpty) {
        await _api.saveToken(newToken);
      }
      if (updated != null) {
        await _storage.write(key: _userKey, value: jsonEncode(updated.toJson()));
        currentUser.value = updated;
      }
    }
    return response;
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _api.deleteToken();
    await _storage.delete(key: _userKey);
    currentUser.value = null;
    if (Get.isRegistered<PendingFoundRequestsService>()) {
      Get.find<PendingFoundRequestsService>().reset();
    }
    Get.offAllNamed('/login');
    debugPrint('AuthService: Logged out');
  }

  /// Fetch fresh profile from server
  Future<ApiResponse> fetchProfile() async {
    final response = await _api.get('/auth/me');
    if (response.isSuccess && response.data != null) {
      debugPrint('AuthService: Profile Data: ${response.data}');
      final user = User.fromJson(response.data as Map<String, dynamic>);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      currentUser.value = user;
    }
    return response;
  }
}
