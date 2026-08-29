import 'package:flutter/material.dart';
import 'package:view360directchat/view360directchat.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExampleApp());
}

/// Main entrypoint widget for the example application.
class ExampleApp extends StatelessWidget {
  /// Creates the [ExampleApp] widget.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'View360 Direct Chat Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D59E1)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

/// Home screen providing access to Chat and AI Voice Call features.
class HomeScreen extends StatefulWidget {
  /// Creates the [HomeScreen] widget.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _baseUrlController = TextEditingController(
    text: 'https://chat.view360.cx',
  );
  final _appIdController = TextEditingController(text: 'YOUR_APP_ID');
  final _nameController = TextEditingController(text: 'John Doe');
  final _emailController = TextEditingController(text: 'john.doe@example.com');
  final _phoneController = TextEditingController(text: '+1234567890');
  final _messageController = TextEditingController();

  final List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String log) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toIso8601String().substring(11, 19)}] $log');
    });
  }

  Future<void> _startChatSession() async {
    final baseUrl = _baseUrlController.text.trim();
    final appId = _appIdController.text.trim();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final message = _messageController.text.trim();

    if (baseUrl.isEmpty || appId.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Base URL, App ID, and Name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    _addLog('Creating chat session...');

    try {
      final chatService = ChatService(baseUrl: baseUrl, appId: appId);

      final response = await chatService.createChatSession(
        chatContent: message.isNotEmpty ? message : 'Hello from View360 Flutter Example!',
        customerName: name,
        customerEmail: email.isNotEmpty ? email : null,
        customerPhone: phone.isNotEmpty ? phone : null,
      );

      if (response.success) {
        if (response.isInQueue) {
          _addLog('Chat registered! Waiting in queue for an available agent.');
        } else {
          _addLog('Chat session created successfully!');
        }
      } else {
        _addLog('Error: ${response.message}');
      }
    } catch (e) {
      _addLog('Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openVoiceCall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => View360CallPage(
          config: const View360CallConfig(
            tokenUrl: 'https://ai.view360.cx/api/token',
            sdkId: 'DEMO_SDK_ID',
            apiKey: 'DEMO_API_KEY',
            livekitUrl: 'wss://livekit.view360.cx',
          ),
          userName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : 'John Doe',
          userPhone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : '+1234567890',
          userEmail: _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : 'john.doe@example.com',
          theme: const View360CallTheme(
            primaryColor: Color(0xFF5D59E1),
          ),
          strings: const View360CallStrings(
            agentName: 'View360 Voice Assistant',
          ),
          onCallStarted: () => _addLog('AI Voice Call connected'),
          onCallEnded: () => _addLog('AI Voice Call ended'),
          onRatingSubmitted: (rating, feedback) {
            _addLog('Rating submitted: $rating stars, feedback: $feedback');
          },
          onError: (error) => _addLog('Call error: $error'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _appIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View360 Direct Chat Example'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration & User Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Base URL',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _appIdController,
                      decoration: const InputDecoration(
                        labelText: 'App ID',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Email',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Phone',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Initial Message (optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _startChatSession,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chat),
                    label: const Text('Start Chat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openVoiceCall,
                    icon: const Icon(Icons.phone_in_talk),
                    label: const Text('AI Voice Call'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Activity Log',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs yet. Start a chat or call.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
