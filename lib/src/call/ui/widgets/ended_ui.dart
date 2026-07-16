import 'package:flutter/material.dart';
import '../../config/call_strings.dart';
import '../../config/call_theme.dart';
import '../../service/livekit_call_service.dart';

class EndedUI extends StatefulWidget {
  final LivekitCallService service;
  final View360CallTheme theme;
  final View360CallStrings strings;
  final String room;

  const EndedUI({
    super.key,
    required this.service,
    required this.theme,
    required this.strings,
    required this.room,
  });

  @override
  State<EndedUI> createState() => _EndedUIState();
}

class _EndedUIState extends State<EndedUI> {
  int _rating = 0;
  bool _isSubmitted = false;
  late final TextEditingController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final strings = widget.strings;

    if (_isSubmitted) {
      return _buildThankYou(theme, strings);
    }
    return _buildRating(theme, strings);
  }

  Widget _buildThankYou(View360CallTheme theme, View360CallStrings strings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 32),
                ),
                const SizedBox(height: 24),
                Text(strings.feedbackReceived,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF064E3B)),
                ),
                const SizedBox(height: 12),
                Text(strings.thankYouImprovement,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF166534)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: () => widget.service.reset(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(strings.startNewCall,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRating(View360CallTheme theme, View360CallStrings strings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Completed banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.callCompleted,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                      ),
                      const SizedBox(height: 4),
                      Text(strings.thankYouSummary,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF166534), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Star rating
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEDF2FF)),
            ),
            child: Column(
              children: [
                Text(strings.howWasExperience,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () => setState(() => _rating = index + 1),
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: index < _rating ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
                        size: 32,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Feedback text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: TextField(
              controller: _feedbackController,
              maxLines: null,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
              decoration: InputDecoration(
                hintText: strings.feedbackHint,
                hintStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Submit
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: _rating == 0 ? null : () async {
                await widget.service.submitRating(_rating, _feedbackController.text);
                setState(() => _isSubmitted = true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(strings.done,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Start new call
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: () => widget.service.reset(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(strings.startNewCall,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
