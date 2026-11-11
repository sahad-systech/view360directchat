// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'view360_chat_view.dart';

/// Full-screen chat page widget displaying the View360 direct chat interface.
///
/// Wraps [View360ChatView] in a [Scaffold] with appropriate status bar and navigation
/// handling. Can be pushed directly onto the navigator stack.
class View360ChatPage extends StatelessWidget {
  /// Creates a [View360ChatPage] widget.
  final String userName;
  final String userEmail;
  final String? userNumber;
  const View360ChatPage({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFD),
      body: SafeArea(
        top: false,
        child: View360ChatView(
          userEmail: userEmail,
          userName: userName,
          userNumber: userNumber,
        ),
      ),
    );
  }
}
