import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
// import 'package:flutter_background/flutter_background.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';

import '../config/call_config.dart';
import '../model/fetch_token_model.dart';
import '../model/transcript_model.dart';

/// Represents the lifecycle states of a LiveKit voice call.
enum CallStatus {
  /// Initial idle state before initiating a call.
  initial,

  /// Connecting state while fetching credentials and joining the room.
  loading,

  /// Active call connected state.
  connected,

  /// Terminated call state.
  ended,

  /// Encountered an error state.
  error,
}

/// Service managing LiveKit WebRTC audio connection, microphone/speaker controls,
/// live transcript streaming, and post-call feedback ratings.
class LivekitCallService extends ChangeNotifier {
  /// Call configuration containing endpoints and API keys.
  final View360CallConfig config;

  /// Full name of the user starting the call.
  final String userName;

  /// Contact phone number of the user.
  final String userPhone;

  /// Contact email address of the user.
  final String userEmail;

  /// Callback fired when the voice call successfully connects.
  VoidCallback? onCallStarted;

  /// Callback fired when the voice call ends.
  VoidCallback? onCallEnded;

  /// Callback fired when rating and feedback are submitted.
  void Function(int rating, String feedback)? onRatingSubmitted;

  /// Callback fired when an error occurs during call connection or execution.
  void Function(String error)? onError;

  CallStatus _status = CallStatus.initial;
  String _errorMessage = '';
  String _currentRoom = '';
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  double _audioLevel = 0.0;
  final List<TranscriptModel> _transcripts = [];

  Room? _room;
  Timer? _audioLevelTimer;

  /// Creates a [LivekitCallService] instance.
  LivekitCallService({
    required this.config,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
  });

  /// The current lifecycle status of the call.
  CallStatus get status => _status;

  /// The error message if [status] is [CallStatus.error].
  String get errorMessage => _errorMessage;

  /// The active LiveKit room identifier.
  String get currentRoom => _currentRoom;

  /// Whether the user microphone is currently muted.
  bool get isMuted => _isMuted;

  /// Whether audio is currently routed through the loudspeaker.
  bool get isSpeakerOn => _isSpeakerOn;

  /// Current audio volume level (0.0 to 1.0).
  double get audioLevel => _audioLevel;

  /// List of live transcript utterances exchanged during the call.
  List<TranscriptModel> get transcripts => List.unmodifiable(_transcripts);

  /// Connects to the LiveKit server and establishes an active audio call.
  Future<void> connect() async {
    _setStatus(CallStatus.loading);

    try {
      // 2. Fetch token
      final tokenModel = await _fetchToken();

      // 3. Create Room
      _room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          defaultAudioPublishOptions: AudioPublishOptions(dtx: true),
        ),
      );

      // 4. Listen to room events
      _room!.events.listen((event) {
        if (event is DataReceivedEvent) {
          _handleDataReceived(event);
        } else if (event is TranscriptionEvent) {
          _handleTranscriptionEvent(event);
        } else if (event is RoomDisconnectedEvent) {
          disconnect();
        }
      });

      // 5. Connect
      await _room!.connect(
        config.livekitUrl,
        tokenModel.token,
        connectOptions: const ConnectOptions(
          autoSubscribe: true,
          rtcConfiguration: RTCConfiguration(
            iceTransportPolicy: RTCIceTransportPolicy.all,
          ),
        ),
      );

      // 6. Enable mic
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      // 7. Android foreground service
      // if (Platform.isAndroid) {
      //   try {
      //     final androidConfig = FlutterBackgroundAndroidConfig(
      //       notificationTitle: config.notificationTitle,
      //       notificationText: config.notificationText,
      //       notificationImportance: AndroidNotificationImportance.normal,
      //       notificationIcon: const AndroidResource(
      //         name: 'launcher_icon',
      //         defType: 'mipmap',
      //       ),
      //     );
      //     final hasInit =
      //         await FlutterBackground.initialize(androidConfig: androidConfig);
      //     if (hasInit) await FlutterBackground.enableBackgroundExecution();
      //   } catch (e) {
      //     debugPrint('Foreground service error: $e');
      //   }
      // }

      // 8. Speaker
      try {
        await AudioManager.instance.setSpeakerOutputPreferred(true);
        await _room?.startAudio();
      } catch (_) {}

      _isMuted = false;
      _isSpeakerOn = true;
      _currentRoom = tokenModel.room;
      _transcripts.clear();
      _addTranscript('System: Connected to AI Agent. Ready to talk.', false);
      _startAudioMonitoring();

      _setStatus(CallStatus.connected);
      onCallStarted?.call();
    } catch (e) {
      await _cleanupAndroid();
      _setError(e.toString());
      onError?.call(e.toString());
    }
  }

  /// Disconnects from the current call and cleans up room resources.
  Future<void> disconnect() async {
    _audioLevelTimer?.cancel();
    await _cleanupAndroid();
    final room = _currentRoom;
    await _room?.disconnect();
    _room = null;
    _transcripts.clear();
    if (room.isNotEmpty) {
      _currentRoom = room;
      _setStatus(CallStatus.ended);
      onCallEnded?.call();
    } else {
      _setStatus(CallStatus.initial);
    }
  }

  /// Toggles the local microphone between muted and unmuted.
  Future<void> toggleMute() async {
    if (_room == null) return;
    _isMuted = !_isMuted;
    await _room!.localParticipant?.setMicrophoneEnabled(!_isMuted);
    notifyListeners();
  }

  /// Toggles the audio output between speaker and earpiece.
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(_isSpeakerOn);
    } catch (_) {}
    notifyListeners();
  }

  /// Submits post-call customer rating ([rating], 1-5) and text [feedback].
  Future<void> submitRating(int rating, String feedback) async {
    try {
      final url = Uri.parse(
        'https://ai.view360.cx/api/public/calls/$_currentRoom/rating',
      );
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rating': rating, 'feedback': feedback}),
      );
      onRatingSubmitted?.call(rating, feedback);
    } catch (e) {
      debugPrint('Rating submit error: $e');
    }
  }

  /// Resets the call state back to [CallStatus.initial].
  void reset() {
    _currentRoom = '';
    _errorMessage = '';
    _transcripts.clear();
    _setStatus(CallStatus.initial);
  }


  // ─── Private ──────────────────────────────────────────────────────────────

  Future<FetchTokenModel> _fetchToken() async {
    final uri = Uri.parse(
      '${config.tokenUrl}?mobileSdkId=${config.sdkId}'
      '&apiKey=${config.apiKey}'
      '&name=${Uri.encodeComponent(userName)}'
      '&phone=${Uri.encodeComponent(userPhone)}'
      '&email=${Uri.encodeComponent(userEmail)}',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return FetchTokenModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch token: ${response.statusCode}');
  }

  void _handleTranscriptionEvent(TranscriptionEvent event) {
    try {
      for (var segment in event.segments) {
        final isLocal =
            event.participant.identity == _room?.localParticipant?.identity;
        _updateOrAdd(id: segment.id, text: segment.text, isUser: isLocal);
      }
    } catch (_) {}
  }

  void _handleDataReceived(DataReceivedEvent event) {
    try {
      final data = utf8.decode(event.data);
      Map<String, dynamic> json;
      try {
        json = jsonDecode(data);
      } catch (_) {
        _addTranscript(data, false);
        return;
      }

      String? text;
      for (final field in [
        'text',
        'message',
        'transcript',
        'content',
        'payload',
        'msg',
        'speech',
        'utterance',
      ]) {
        if (json.containsKey(field) && json[field] is String) {
          text = json[field];
          break;
        }
      }
      if (text == null || text.isEmpty) return;

      bool isUser = false;
      if (event.participant != null) {
        isUser =
            event.participant?.identity == _room?.localParticipant?.identity;
      } else {
        final role = (json['role'] ?? json['participant_type'] ?? '')
            .toString()
            .toLowerCase();
        if (role == 'user' || role == 'customer') isUser = true;
      }

      final id =
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      _updateOrAdd(id: id, text: text, isUser: isUser);
    } catch (e) {
      debugPrint('Data packet error: $e');
    }
  }

  void _updateOrAdd({
    required String id,
    required String text,
    required bool isUser,
  }) {
    final idx = _transcripts.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _transcripts[idx] = TranscriptModel(
        id: id,
        text: text,
        isUser: isUser,
        timestamp: _transcripts[idx].timestamp,
      );
    } else {
      _transcripts.add(
        TranscriptModel(
          id: id,
          text: text,
          isUser: isUser,
          timestamp: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  void _addTranscript(String text, bool isUser) {
    _updateOrAdd(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: isUser,
    );
  }

  void _startAudioMonitoring() {
    _audioLevelTimer?.cancel();
    _audioLevelTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_room == null ||
          _room!.connectionState != ConnectionState.connected) {
        return;
      }
      _audioLevel = (DateTime.now().millisecond % 100) / 100.0;
      notifyListeners();
    });
  }

  void _setStatus(CallStatus s) {
    _status = s;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _status = CallStatus.error;
    notifyListeners();
  }

  Future<void> _cleanupAndroid() async {
    // if (Platform.isAndroid) {
    //   try {
    //     if (FlutterBackground.isBackgroundExecutionEnabled) {
    //       await FlutterBackground.disableBackgroundExecution();
    //     }
    //   } catch (_) {}
    // }
  }

  @override
  void dispose() {
    _audioLevelTimer?.cancel();
    _room?.disconnect();
    _cleanupAndroid();
    super.dispose();
  }
}
