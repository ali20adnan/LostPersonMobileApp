import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/services/call_service.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/constants/api_constants.dart';

/// Full-screen 1:1 audio call UI. Reflects [CallService] state (ringing,
/// calling, connecting, active, ended) and exposes accept/reject/mute/hang-up.
class CallPage extends StatelessWidget {
  const CallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final call = Get.find<CallService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Own opaque immersive backdrop (navy) in BOTH light and dark themes.
      // This is what makes the white text/controls read correctly in light
      // mode, and — being opaque — it lets the route's fade-through cross-fade
      // a solid surface on hang-up instead of revealing the horizontally
      // sliding chat page underneath (the old "everything shifts left" bug).
      // Explicit full-screen size so the opaque backdrop ALWAYS fills the screen
      // — otherwise, in the ended/idle states the Column has no full-width child
      // and this Container would shrink-wrap to the avatar width, leaving half
      // the screen empty (the "call UI on the left half" bug). Filling also
      // forces full-width constraints down, so the content stays centered.
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.sacredGradient),
        child: SafeArea(
          child: Obx(() {
            final status = call.status.value;
            final peer = call.peer.value;
            final name = peer?.fullName ?? 'مكالمة';
            final avatarUrl = ApiConstants.resolveAvatarUrl(peer?.avatarUrl);
            final initial = name.isNotEmpty ? name[0] : '؟';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                // Avatar
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: avatarUrl == null ? AppColors.heroGradient : null,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 32,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: avatarUrl != null
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _initial(initial),
                        )
                      : _initial(initial),
                ),
                const SizedBox(height: 24),

                // Name
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Status / duration
                _StatusLine(call: call),

                const Spacer(flex: 3),

                // Controls
                _Controls(call: call, status: status),

                const Spacer(flex: 1),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _initial(String initial) => Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 44,
          ),
        ),
      );
}

class _StatusLine extends StatelessWidget {
  final CallService call;
  const _StatusLine({required this.call});

  static const _endLabels = {
    'rejected': 'تم رفض المكالمة',
    'canceled': 'أُلغيت المكالمة',
    'busy': 'المستخدم مشغول',
    'unavailable': 'المستخدم غير متصل',
    'ended': 'انتهت المكالمة',
    'failed': 'فشل الاتصال',
    'no-answer': 'لا يوجد رد',
    'mic-denied': 'تعذّر الوصول للميكروفون',
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = call.status.value;
      switch (status) {
        case CallStatus.active:
          return _CallDurationText(startedAt: call.startedAt.value);
        case CallStatus.calling:
          return _label('جارٍ الاتصال…');
        case CallStatus.ringing:
          return _label('مكالمة صوتية واردة…');
        case CallStatus.connecting:
          return _label('جارٍ الربط…');
        case CallStatus.ended:
          return _label(_endLabels[call.endReason.value] ?? 'انتهت المكالمة');
        case CallStatus.idle:
          return const SizedBox.shrink();
      }
    });
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      );
}

/// Ticks every second while the call is active.
class _CallDurationText extends StatefulWidget {
  final DateTime? startedAt;
  const _CallDurationText({required this.startedAt});

  @override
  State<_CallDurationText> createState() => _CallDurationTextState();
}

class _CallDurationTextState extends State<_CallDurationText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.startedAt;
    final elapsed = start == null ? Duration.zero : DateTime.now().difference(start);
    final m = elapsed.inMinutes;
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$m:$s',
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final CallService call;
  final CallStatus status;
  const _Controls({required this.call, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == CallStatus.ended || status == CallStatus.idle) {
      return const SizedBox(height: 72);
    }

    if (status == CallStatus.ringing) {
      // Incoming: reject + accept
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RoundButton(
            color: Colors.red.shade600,
            icon: PhosphorIcons.phoneSlash(PhosphorIconsStyle.fill),
            label: 'رفض',
            onTap: call.rejectCall,
          ),
          _RoundButton(
            color: Colors.green.shade600,
            icon: PhosphorIcons.phone(PhosphorIconsStyle.fill),
            label: 'قبول',
            onTap: call.acceptCall,
          ),
        ],
      );
    }

    // Calling / connecting / active: mute + speaker + hang up
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Obx(() {
          final muted = call.isMuted.value;
          return _RoundButton(
            color: muted ? Colors.amber.shade700 : Colors.white24,
            icon: muted
                ? PhosphorIcons.microphoneSlash(PhosphorIconsStyle.fill)
                : PhosphorIcons.microphone(PhosphorIconsStyle.fill),
            label: muted ? 'مكتوم' : 'كتم',
            onTap: status == CallStatus.active ? call.toggleMute : null,
          );
        }),
        // Speaker: filled/gold when audio is on the loudspeaker, neutral on
        // earpiece — the colour + icon signal where the sound is coming out.
        Obx(() {
          final on = call.isSpeakerOn.value;
          return _RoundButton(
            color: on ? AppColors.accentDark : Colors.white24,
            icon: on
                ? PhosphorIcons.speakerHigh(PhosphorIconsStyle.fill)
                : PhosphorIcons.speakerSimpleHigh(PhosphorIconsStyle.fill),
            label: 'مكبر الصوت',
            onTap: status == CallStatus.active ? call.toggleSpeaker : null,
          );
        }),
        _RoundButton(
          color: Colors.red.shade600,
          icon: PhosphorIcons.phoneSlash(PhosphorIconsStyle.fill),
          label: 'إنهاء',
          onTap: call.hangUp,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _RoundButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
