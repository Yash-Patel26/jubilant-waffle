import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/ui/stick_cam_session.dart';
import 'package:gamer_flick/services/game/stick_cam_service.dart';
import 'package:gamer_flick/services/game/webrtc_service.dart';

class StickCamProvider extends ChangeNotifier {
  final StickCamService _service = StickCamService();
  WebRTCService? _webrtcService;
  WebRTCSignalingService? _signalingService;
  bool _isOfferer = false;

  StickCamSession? _session;
  final List<StickCamMessage> _messages = [];
  String? _error;
  bool _isMatching = false;
  bool _isTyping = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  List<String> _interests = [];
  String _mode = 'video'; // video, audio, text

  // WebRTC streams
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  String _connectionState = 'disconnected';
  Timer? _negotiationTimer;
  int _negotiationAttempts = 0;

  RealtimeChannel? _msgChannel;
  RealtimeChannel? _sessionChannel;
  Stream<bool>? _otherTypingStream;
  StreamSubscription<bool>? _otherTypingSub;

  StickCamSession? get session => _session;
  List<StickCamMessage> get messages => List.unmodifiable(_messages);
  bool get isMatching => _isMatching;
  String? get error => _error;
  bool get isTyping => _isTyping;
  bool get isMuted => _isMuted;
  bool get isVideoOff => _isVideoOff;
  List<String> get interests => List.unmodifiable(_interests);
  String get mode => _mode;

  // WebRTC getters
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  String get connectionState => _connectionState;

  Future<void> startMatching() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isMatching = true;
    _error = null;
    notifyListeners();

    try {
      // Initialize WebRTC if in video mode
      if (_mode == 'video') {
        await _initializeWebRTC();
      }

      // Try to find an existing matching session first
      final existing = await _service.findMatchingSession(
        user.id,
        _interests,
        _mode,
      );

      if (existing != null) {
        // Join as participant B
        await _service.connectUsers(existing.id, user.id);
        _session = StickCamSession(
          id: existing.id,
          aUserId: existing.aUserId,
          bUserId: user.id,
          status: 'connected',
          createdAt: existing.createdAt,
          endedAt: existing.endedAt,
          endReason: existing.endReason,
          interests: existing.interests,
          mode: existing.mode,
        );
      } else {
        // Create a new session and wait for a match
        _session = await _service.joinQueue(
          user.id,
          interests: _interests,
          mode: _mode,
        );
      }
      _subscribeRealtime();

      // If already connected, start signaling flow
      if (_session?.status == 'connected') {
        _onSessionConnected();
      }
    } catch (e) {
      _error = e.toString();
    }

    _isMatching = false;
    notifyListeners();
  }

  Future<void> _initializeWebRTC() async {
    try {
      _webrtcService = WebRTCService(
        onRemoteStream: (stream) {
          _remoteStream = stream;
          notifyListeners();
        },
        onOffer: (offer) async {
          if (_session == null || _signalingService == null) return;
          await _signalingService!.sendSignalingMessage(
            sessionId: _session!.id,
            messageType: 'offer',
            messageData: {
              'sdp': offer.sdp,
              'type': offer.type,
            },
          );
        },
        onAnswer: (answer) async {
          if (_session == null || _signalingService == null) return;
          await _signalingService!.sendSignalingMessage(
            sessionId: _session!.id,
            messageType: 'answer',
            messageData: {
              'sdp': answer.sdp,
              'type': answer.type,
            },
          );
        },
        onIceCandidate: (candidate) async {
          if (_session == null || _signalingService == null) return;
          await _signalingService!.sendSignalingMessage(
            sessionId: _session!.id,
            messageType: 'ice-candidate',
            messageData: {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
          );
        },
        onConnectionStateChange: (state) {
          _connectionState = state;
          notifyListeners();
        },
        onError: (error) {
          _error = error;
          notifyListeners();
        },
      );

      await _webrtcService!.initialize();
      _localStream = _webrtcService!.localStream;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize video: $e';
      notifyListeners();
    }
  }

  void _subscribeRealtime() {
    if (_session == null) return;

    _msgChannel?.unsubscribe();
    _sessionChannel?.unsubscribe();

    _msgChannel = _service.subscribeMessages(_session!.id, (m) {
      _messages.add(m);
      notifyListeners();
    });

    _sessionChannel = _service.subscribeSession(_session!.id, (s) {
      final wasStatus = _session?.status;
      _session = s;
      notifyListeners();
      if (wasStatus != 'connected' && s.status == 'connected') {
        _onSessionConnected();
      }
    });

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      _otherTypingStream = _service.subscribeOtherTyping(_session!.id, uid);
      _otherTypingSub?.cancel();
      _otherTypingSub = _otherTypingStream!.listen((isOtherTyping) {
        _isTyping = isOtherTyping;
        notifyListeners();
      });
    }
  }

  void _onSessionConnected() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null || _session == null) return;
    _isOfferer = _session!.aUserId == uid;

    _signalingService?.dispose();
    _signalingService = WebRTCSignalingService();

    _signalingService!.joinSignalingRoom(
      _session!.id,
      currentUserId: uid,
      onOffer: (offer) async {
        // Remote offer received → set and answer
        await _webrtcService?.setRemoteDescription(offer);
        await _webrtcService!.createAnswer();
        // onAnswer callback will send via signaling
      },
      onAnswer: (answer) async {
        // Remote answer received → finalize
        await _webrtcService?.setRemoteDescription(answer);
      },
      onIceCandidate: (candidate) async {
        await _webrtcService?.addIceCandidate(candidate);
      },
    );

    // If we are the initiator, create and send the offer once joined
    if (_isOfferer) {
      // createOffer triggers onOffer which sends through signaling service
      _startNegotiation();
    }
  }

  void _startNegotiation() {
    _negotiationTimer?.cancel();
    _negotiationAttempts = 0;
    _attemptOfferWithBackoff();
  }

  void _attemptOfferWithBackoff() async {
    if (_negotiationAttempts > 4) return; // max 5 attempts
    _negotiationAttempts++;
    await _webrtcService?.createOffer();

    final backoffMs = 1000 * (1 << (_negotiationAttempts - 1));
    _negotiationTimer = Timer(Duration(milliseconds: backoffMs), () {
      // If still not connected, retry
      if (_connectionState != 'RTCPeerConnectionStateConnected' &&
          _connectionState != 'connected') {
        _attemptOfferWithBackoff();
      }
    });
  }

  Future<void> sendMessage(String text) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _session == null || text.trim().isEmpty) return;

    try {
      final m = await _service.sendMessage(
        sessionId: _session!.id,
        senderId: user.id,
        content: text.trim(),
      );
      _messages.add(m);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> leave({String reason = 'left'}) async {
    if (_session == null) return;

    try {
      await _service.leaveSession(_session!.id, reason);
    } finally {
      _negotiationTimer?.cancel();
      _msgChannel?.unsubscribe();
      _sessionChannel?.unsubscribe();
      await _otherTypingSub?.cancel();
      _msgChannel = null;
      _sessionChannel = null;
      _otherTypingStream = null;
      _otherTypingSub = null;
      _session = null;
      _messages.clear();
      _isMuted = false;
      _isVideoOff = false;
      notifyListeners();
    }
  }

  Future<void> next() async {
    await leave(reason: 'next');
    await startMatching();
  }

  Future<void> endCall() async {
    await leave(reason: 'ended');
  }

  Future<void> cancelMatching() async {
    if (_isMatching) {
      _isMatching = false;
      notifyListeners();
    }
    await leave(reason: 'cancelled');
  }

  void setInterests(List<String> values) {
    _interests = values;
    notifyListeners();
  }

  void setMode(String value) {
    _mode = value;
    notifyListeners();
  }

  void setTyping(bool value) {
    _isTyping = value;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null && _session != null) {
      _service.setTyping(_session!.id, uid, value);
    }
    notifyListeners();
  }

  void toggleMute(bool muted) {
    _isMuted = muted;
    _webrtcService?.toggleMute(muted);
    notifyListeners();
  }

  void toggleVideo(bool videoOff) {
    _isVideoOff = videoOff;
    _webrtcService?.toggleVideo(!videoOff);
    notifyListeners();
  }

  @override
  void dispose() {
    _msgChannel?.unsubscribe();
    _sessionChannel?.unsubscribe();
    _otherTypingSub?.cancel();
    _webrtcService?.dispose();
    _signalingService?.dispose();
    super.dispose();
  }
}
