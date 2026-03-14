import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/services/storage_service.dart';
import '../../../core/constants/language_constants.dart';
import '../../../data/models/conversation_model.dart';

class TranslationHistoryPage extends StatefulWidget {
  const TranslationHistoryPage({super.key});

  @override
  State<TranslationHistoryPage> createState() => _TranslationHistoryPageState();
}

class _TranslationHistoryPageState extends State<TranslationHistoryPage> {
  final StorageService _storageService = StorageService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    await _storageService.init();
    final conversations = await _storageService.getAllConversations();
    setState(() {
      _conversations = conversations;
      _isLoading = false;
    });
  }

  Future<void> _deleteConversation(String id) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await Get.dialog<bool>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.trash, color: AppColors.error, size: 20),
              ),
              const Gap(10),
              Text('حذف المحادثة',
                  style: TextStyle(
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  )),
            ],
          ),
          content: Text('هل أنت متأكد من حذف هذه المحادثة؟',
              style: TextStyle(
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
              )),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Get.back(result: true),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text('حذف',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteConversation(id);
      await _loadHistory();
      Get.snackbar(
        'تم الحذف',
        'تم حذف المحادثة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _clearAll() async {
    if (_conversations.isEmpty) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await Get.dialog<bool>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.trash, color: AppColors.error, size: 20),
              ),
              const Gap(10),
              Text('حذف الكل',
                  style: TextStyle(
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  )),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف جميع المحادثات؟ لا يمكن التراجع عن هذا الإجراء.',
            style: TextStyle(
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Get.back(result: true),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text('حذف الكل',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _storageService.clearAllConversations();
      await _loadHistory();
      Get.snackbar(
        'تم الحذف',
        'تم حذف جميع المحادثات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          title: const Text(
            'سجل الترجمات',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(color: AppColors.primary),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_right_3),
            onPressed: () => Get.back(),
          ),
          actions: [
            if (_conversations.isNotEmpty)
              IconButton(
                icon: const Icon(Iconsax.trash, color: Colors.white),
                onPressed: _clearAll,
                tooltip: 'حذف الكل',
              ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: AppColors.primary,
                  size: 40,
                ),
              )
            : _conversations.isEmpty
                ? _buildEmptyState(isDark)
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _loadHistory,
                    child: AnimationLimiter(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _buildConversationCard(
                                  isDark,
                                  _conversations[index],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Iconsax.clock, size: 52, color: Colors.white),
          ),
          const Gap(20),
          Text(
            'لا توجد محادثات سابقة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const Gap(8),
          Text(
            'ابدأ الترجمة الصوتية لحفظ السجل هنا',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildConversationCard(bool isDark, Conversation conversation) {
    final dateFormat = DateFormat('yyyy/MM/dd - HH:mm', 'ar');
    final sourceLang =
        LanguageConstants.getLanguageNameArabic(conversation.sourceLanguage);
    final targetLang =
        LanguageConstants.getLanguageNameArabic(conversation.targetLanguage);
    final translationCount = conversation.translations.length;
    final preview = conversation.translations.isNotEmpty
        ? conversation.translations.first.originalText
        : '';
    final duration = conversation.durationSeconds != null
        ? '${(conversation.durationSeconds! ~/ 60)} دقيقة'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showConversationDetail(context, isDark, conversation),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$sourceLang → $targetLang',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _deleteConversation(conversation.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Iconsax.trash,
                            size: 18, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                Row(
                  children: [
                    Icon(Iconsax.clock, size: 14, color: AppColors.textLight),
                    const Gap(4),
                    Text(
                      dateFormat.format(conversation.startTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (duration != null) ...[
                      const Gap(12),
                      Icon(Iconsax.timer_1, size: 14, color: AppColors.textLight),
                      const Gap(4),
                      Text(
                        duration,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const Gap(12),
                    Icon(Iconsax.message_text, size: 14, color: AppColors.textLight),
                    const Gap(4),
                    Text(
                      '$translationCount جملة',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (preview.isNotEmpty) ...[
                  const Gap(10),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConversationDetail(
    BuildContext context,
    bool isDark,
    Conversation conversation,
  ) {
    final dateFormat = DateFormat('yyyy/MM/dd - HH:mm', 'ar');
    final sourceLang =
        LanguageConstants.getLanguageNameArabic(conversation.sourceLanguage);
    final targetLang =
        LanguageConstants.getLanguageNameArabic(conversation.targetLanguage);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.heroGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Iconsax.translate,
                              size: 20, color: Colors.white),
                        ),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$sourceLang → $targetLang',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textOnDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                dateFormat.format(conversation.startTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final buffer = StringBuffer();
                            for (var t in conversation.translations) {
                              buffer.writeln(t.originalText);
                              buffer.writeln(t.translatedText);
                              buffer.writeln('---');
                            }
                            Clipboard.setData(
                                ClipboardData(text: buffer.toString()));
                            Get.snackbar(
                              'تم النسخ',
                              'تم نسخ جميع الترجمات',
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 1),
                              margin: const EdgeInsets.all(16),
                              backgroundColor:
                                  AppColors.success.withValues(alpha: 0.9),
                              colorText: Colors.white,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Iconsax.copy,
                                color: AppColors.primary, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  Divider(
                    color: isDark ? AppColors.dividerDark : AppColors.divider,
                    height: 1,
                  ),
                  Expanded(
                    child: conversation.translations.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد ترجمات',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            itemCount: conversation.translations.length,
                            itemBuilder: (ctx, index) {
                              final t = conversation.translations[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.heroGradient,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(16),
                                          topLeft: Radius.circular(16),
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(4),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        t.originalText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const Gap(4),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.cardDark
                                            : AppColors.surfaceSunken,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(4),
                                          topLeft: Radius.circular(16),
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.cardBorderDark
                                              : AppColors.cardBorder,
                                        ),
                                      ),
                                      child: Text(
                                        t.translatedText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? AppColors.textOnDark
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
