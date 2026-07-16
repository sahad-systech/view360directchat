import 'package:flutter/material.dart';
import '../../config/call_strings.dart';
import '../../config/call_theme.dart';
import '../../service/livekit_call_service.dart';
import 'message_bubble.dart';

class ConnectedUI extends StatelessWidget {
  final LivekitCallService service;
  final View360CallTheme theme;
  final View360CallStrings strings;
  final ScrollController scrollController;

  const ConnectedUI({
    super.key,
    required this.service,
    required this.theme,
    required this.strings,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final transcripts = service.transcripts;
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.phone_in_talk_outlined,
                    color: theme.primaryColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.agentName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        strings.connectedLabel,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Transcripts
        Expanded(
          child: transcripts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.voice_chat_outlined,
                          size: 40, color: Colors.grey.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        strings.listeningLabel,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: transcripts.length - 1,
                  itemBuilder: (context, index) {
                    final t = transcripts[index + 1];
                    return MessageBubble(
                      text: t.text,
                      isUser: t.isUser,
                      theme: theme,
                      strings: strings,
                    );
                  },
                ),
        ),

        const Divider(height: 1),

        // Audio visualizer
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: _buildVisualizer(),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlButton(
                icon: service.isMuted
                    ? Icons.mic_off_outlined
                    : Icons.mic_none_outlined,
                onPressed: () => service.toggleMute(),
                color: theme.primaryColor.withValues(alpha: 0.15),
                iconColor: theme.primaryColor,
              ),
              const SizedBox(width: 24),
              _ControlButton(
                icon: Icons.phone_disabled,
                onPressed: () => service.disconnect(),
                color: Colors.red,
                iconColor: Colors.white,
                isLarge: true,
              ),
              const SizedBox(width: 24),
              _ControlButton(
                icon: service.isSpeakerOn
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
                onPressed: () => service.toggleSpeaker(),
                color: theme.primaryColor.withValues(alpha: 0.15),
                iconColor: theme.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualizer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final height =
            20.0 + (service.audioLevel * 30 * (index % 2 == 0 ? 0.5 : 1.0));
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final Color iconColor;
  final bool isLarge;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.iconColor,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isLarge ? 64.0 : 52.0;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Icon(icon, color: iconColor, size: isLarge ? 32 : 24),
      ),
    );
  }
}
