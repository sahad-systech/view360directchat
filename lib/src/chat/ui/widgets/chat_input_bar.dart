import 'package:flutter/material.dart';

/// Floating pill-shaped text input bar for composing and sending chat messages.
class ChatInputBar extends StatefulWidget {
  /// Callback fired when the user submits a message.
  final void Function(String text)? onSend;

  /// Optional external controller for the text input.
  final TextEditingController? controller;

  /// Creates a [ChatInputBar] widget.
  const ChatInputBar({super.key, this.onSend, this.controller});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasNow = _controller.text.trim().isNotEmpty;
    if (hasNow != _hasText) {
      setState(() => _hasText = hasNow);
    }
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    _controller.clear();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSubmit(),
                  style: const TextStyle(
                    fontSize: 15.0,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 15.0,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 14.0,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    size: 22,
                    color: _hasText
                        ? const Color(0xFF4E37D3)
                        : const Color(0xFF9CA3AF),
                  ),
                  tooltip: 'Send',
                  onPressed: _hasText ? _handleSubmit : null,
                  splashRadius: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
