import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/audio_visualizer.dart';
import '../../../core/widgets/connection_status_indicator.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/record_button.dart';
import '../controllers/translator_controller.dart';
import '../widgets/message_bubble.dart';

class TranslatorPage extends GetView<TranslatorController> {
  const TranslatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('مترجم الحرم الفوري'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Connection status
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: ConnectionStatusIndicator(
                  status: controller.connectionStatus.value,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Language selector with swap button
            _buildLanguageSelector(theme),

            const SizedBox(height: 24),

            // Chat messages display
            Expanded(
              child: Column(
                children: [
                  // Messages list
                  Expanded(
                    child: Obx(
                      () => controller.messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'ابدأ الحديث لرؤية الترجمة',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: controller.messages.length,
                              itemBuilder: (context, index) {
                                // Reverse index to show latest at bottom
                                final messageIndex = controller.messages.length - 1 - index;
                                final message = controller.messages[messageIndex];

                                return Column(
                                  children: [
                                    // Original message (right side)
                                    if (message.originalText.trim().isNotEmpty)
                                      MessageBubble(
                                        text: message.originalText,
                                        isOriginal: true,
                                        timestamp: message.timestamp,
                                      ),
                                    // Translation message (left side)
                                    if (message.translatedText.trim().isNotEmpty)
                                      MessageBubble(
                                        text: message.translatedText,
                                        isOriginal: false,
                                        timestamp: message.timestamp,
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ),

                  // Audio visualizer
                  Obx(
                    () => controller.isRecording.value
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: AudioVisualizer(
                              amplitude: controller.audioLevel.value,
                            ),
                          )
                        : const SizedBox(height: 8),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Record button
            Obx(
              () => RecordButton(
                isRecording: controller.isRecording.value,
                isLoading: controller.isInitializing.value,
                onPressed: controller.toggleRecording,
                size: 80,
              ),
            ),

            const SizedBox(height: 16),

            // Recording hint
            Obx(
              () => Text(
                controller.isRecording.value
                    ? 'اضغط للتوقف'
                    : 'اضغط للبدء',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),

      // Floating action buttons
      floatingActionButton: _buildFloatingActions(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildLanguageSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Source language
          Flexible(
            child: Obx(
              () => LanguageSelector(
                language: controller.sourceLanguage.value,
                onTap: controller.goToLanguageSelection,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Swap button
          InkWell(
            onTap: controller.swapLanguages,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.swap_horiz,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Target language
          Flexible(
            child: Obx(
              () => LanguageSelector(
                language: controller.targetLanguage.value,
                onTap: controller.goToLanguageSelection,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speak translation button
          if (controller.currentTranslation.value.isNotEmpty)
            FloatingActionButton(
              heroTag: 'speak',
              onPressed: controller.speakTranslation,
              child: const Icon(Icons.volume_up),
            ),

          const SizedBox(height: 12),

          // History button
          FloatingActionButton(
            heroTag: 'history',
            onPressed: controller.goToHistory,
            child: const Icon(Icons.history),
          ),

          const SizedBox(height: 12),

          // Settings button
          FloatingActionButton(
            heroTag: 'settings',
            onPressed: controller.goToSettings,
            child: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}
