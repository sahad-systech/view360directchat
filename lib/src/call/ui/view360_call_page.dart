import 'package:flutter/material.dart';
import '../config/call_config.dart';
import '../config/call_strings.dart';
import '../config/call_theme.dart';
import '../service/livekit_call_service.dart';
import 'widgets/connected_ui.dart';
import 'widgets/disconnected_ui.dart';
import 'widgets/ended_ui.dart';

/// A full-screen AI Voice Call widget powered by LiveKit WebRTC.
///
/// Handles audio calling, live speech transcripts, visualizer animation,
/// microphone/speaker toggling, and post-call feedback ratings.
class View360CallPage extends StatefulWidget {
  /// LiveKit connection configuration (endpoints and keys).
  final View360CallConfig config;

  /// User's full name.
  final String userName;

  /// User's phone number.
  final String userPhone;

  /// User's email address.
  final String userEmail;

  /// Optional UI theme colors customization.
  final View360CallTheme? theme;

  /// Optional UI localized text strings customization.
  final View360CallStrings? strings;

  /// Callback fired when call is successfully connected.
  final VoidCallback? onCallStarted;

  /// Callback fired when call is terminated.
  final VoidCallback? onCallEnded;

  /// Callback fired when user submits call rating and feedback.
  final void Function(int rating, String feedback)? onRatingSubmitted;

  /// Callback fired when an error occurs.
  final void Function(String error)? onError;

  /// Creates a [View360CallPage] widget.
  const View360CallPage({
    super.key,
    required this.config,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    this.theme,
    this.strings,
    this.onCallStarted,
    this.onCallEnded,
    this.onRatingSubmitted,
    this.onError,
  });


  @override
  State<View360CallPage> createState() => _View360CallPageState();
}

class _View360CallPageState extends State<View360CallPage> {
  late final LivekitCallService _service;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _service =
        LivekitCallService(
            config: widget.config,
            userName: widget.userName,
            userPhone: widget.userPhone,
            userEmail: widget.userEmail,
          )
          ..onCallStarted = widget.onCallStarted
          ..onCallEnded = widget.onCallEnded
          ..onRatingSubmitted = widget.onRatingSubmitted
          ..onError = widget.onError;
    _service.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    setState(() {});
    // Auto-scroll transcripts
    if (_service.status == CallStatus.connected &&
        _service.transcripts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
    // Show error snackbar
    if (_service.status == CallStatus.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_service.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _service.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? const View360CallTheme();
    final strings = widget.strings ?? const View360CallStrings();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? theme.darkBackground
          : theme.lightBackground,
      body: SafeArea(child: _buildBody(theme, strings, isDarkMode)),
    );
  }

  Widget _buildBody(
    View360CallTheme theme,
    View360CallStrings strings,
    bool isDarkMode,
  ) {
    switch (_service.status) {
      case CallStatus.initial:
        return DisconnectedUI(
          service: _service,
          theme: theme,
          strings: strings,
          isDarkMode: isDarkMode,
          isConnecting: false,
        );
      case CallStatus.loading:
        return DisconnectedUI(
          service: _service,
          theme: theme,
          strings: strings,
          isDarkMode: isDarkMode,
          isConnecting: true,
        );
      case CallStatus.connected:
        return ConnectedUI(
          service: _service,
          theme: theme,
          strings: strings,
          scrollController: _scrollController,
        );
      case CallStatus.ended:
        return EndedUI(
          service: _service,
          theme: theme,
          strings: strings,
          room: _service.currentRoom,
        );
      case CallStatus.error:
        return DisconnectedUI(
          service: _service,
          theme: theme,
          strings: strings,
          isDarkMode: isDarkMode,
          isConnecting: false,
        );
    }
  }
}
