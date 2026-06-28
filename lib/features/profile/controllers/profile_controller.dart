import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:image_picker/image_picker.dart';

import '../../../app/services/auth_service.dart';
import '../../../app/services/api_service.dart';
import '../../../data/models/user_model.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ApiService _api = Get.find<ApiService>();
  final ImagePicker _picker = ImagePicker();

  // Observable user data
  Rx<User?> get user => _authService.currentUser;

  final isLoading = false.obs;
  final isUploadingAvatar = false.obs;
  final isChangingPassword = false.obs;

  // Change password form
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final obscureCurrent = true.obs;
  final obscureNew = true.obs;
  final obscureConfirm = true.obs;
  final passwordError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    refreshProfile();
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Refresh profile from server
  Future<void> refreshProfile() async {
    isLoading.value = true;
    await _authService.fetchProfile();
    isLoading.value = false;
  }

  /// Pick and upload avatar image
  Future<void> pickAndUploadAvatar() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image == null) return;

    // Show crop/preview dialog
    final confirmed = await Get.dialog<bool>(
      _AvatarPreviewDialog(imagePath: image.path),
      barrierDismissible: false,
    );

    if (confirmed != true) return;

    isUploadingAvatar.value = true;
    try {
      final ext = image.path.split('.').last.toLowerCase();
      final mimeType = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';
      final response = await _api.multipartPatch(
        '/auth/me/avatar',
        files: [
          MultipartFile(
            field: 'file',
            path: image.path,
            mimeType: mimeType,
          ),
        ],
      );

      if (response.isSuccess) {
        await _authService.fetchProfile();
        user.refresh();
        Get.snackbar(
          'تم التحديث',
          'تم تغيير الصورة الشخصية بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      } else {
        Get.snackbar(
          'خطأ',
          response.errorMessage ?? 'فشل رفع الصورة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء رفع الصورة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  /// Change password
  Future<bool> changePassword() async {
    passwordError.value = '';

    final current = currentPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      passwordError.value = 'جميع الحقول مطلوبة';
      return false;
    }

    if (newPass.length < 6) {
      passwordError.value = 'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل';
      return false;
    }

    if (newPass != confirm) {
      passwordError.value = 'كلمة المرور الجديدة غير متطابقة';
      return false;
    }

    isChangingPassword.value = true;
    try {
      final response = await _api.patch('/auth/change-password', body: {
        'currentPassword': current,
        'newPassword': newPass,
      });

      if (response.isSuccess) {
        _clearPasswordFields();
        Get.snackbar(
          'تم التغيير',
          'تم تغيير كلمة المرور بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return true;
      } else {
        passwordError.value = response.errorMessage ?? 'فشل تغيير كلمة المرور';
        return false;
      }
    } catch (e) {
      passwordError.value = 'حدث خطأ غير متوقع';
      return false;
    } finally {
      isChangingPassword.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
  }

  void _clearPasswordFields() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    passwordError.value = '';
    obscureCurrent.value = true;
    obscureNew.value = true;
    obscureConfirm.value = true;
  }
}

/// Dialog to preview and confirm avatar before uploading
class _AvatarPreviewDialog extends StatelessWidget {
  final String imagePath;

  const _AvatarPreviewDialog({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'معاينة الصورة',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ClipOval(
              child: Image.file(
                File(imagePath),
                width: 180,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ستظهر الصورة بشكل دائري',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('حفظ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
