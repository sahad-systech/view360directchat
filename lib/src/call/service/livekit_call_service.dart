import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
// import 'package:flutter_background/flutter_background.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';

import '../config/call_config.dart';
import '../model/fetch_token_model.dart';
import '../model/transcript_model.dart';

enum CallStatus { initial, loading, connected, ended, error }

class LivekitCallService extends ChangeNotifier {
  final View360CallConfig config;
  final String userName;
  final String userPhone;
  final String userEmail;

  // Callbacks
  VoidCallback? onCallStarted;
  VoidCallback? onCallEnded;
  void Function(int rating, String feedback)? onRatingSubmitted;
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

  LivekitCallService({
    required this.config,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
  });

  // Getters
  CallStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get currentRoom => _currentRoom;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  double get audioLevel => _audioLevel;
  List<TranscriptModel> get transcripts => List.unmodifiable(_transcripts);

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
      //     log('Foreground service error: $e');
      //   }
      // }

      // 8. Speaker
      try {
        await Hardware.instance.setSpeakerphoneOn(true);
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

  Future<void> toggleMute() async {
    if (_room == null) return;
    _isMuted = !_isMuted;
    await _room!.localParticipant?.setMicrophoneEnabled(!_isMuted);
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    try {
      await Hardware.instance.setSpeakerphoneOn(_isSpeakerOn);
    } catch (_) {}
    notifyListeners();
  }

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
      log('Rating submit error: $e');
    }
  }

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
        'utterance'
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

      final id = json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      _updateOrAdd(id: id, text: text, isUser: isUser);
    } catch (e) {
      log('Data packet error: $e');
    }
  }

  void _updateOrAdd(
      {required String id, required String text, required bool isUser}) {
    final idx = _transcripts.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _transcripts[idx] = TranscriptModel(
        id: id,
        text: text,
        isUser: isUser,
        timestamp: _transcripts[idx].timestamp,
      );
    } else {
      _transcripts.add(TranscriptModel(
        id: id,
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
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
