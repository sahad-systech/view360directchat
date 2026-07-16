import 'package:flutter/material.dart';
import '../../config/call_strings.dart';
import '../../config/call_theme.dart';
import '../../service/livekit_call_service.dart';

class DisconnectedUI extends StatelessWidget {
  final LivekitCallService service;
  final View360CallTheme theme;
  final View360CallStrings strings;
  final bool isDarkMode;
  final bool isConnecting;

  const DisconnectedUI({
    super.key,
    required this.service,
    required this.theme,
    required this.strings,
    required this.isDarkMode,
    required this.isConnecting,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isConnecting)
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    color: theme.primaryColor,
                    strokeWidth: 2,
                  ),
                ),
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mic_none_outlined,
                    size: 48, color: theme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            strings.haveAQuestion,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.aiSupportText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isConnecting ? null : () => service.connect(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: theme.primaryColor.withValues(alpha: 0.4),
              ),
              child: isConnecting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      strings.startVoiceChat,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
