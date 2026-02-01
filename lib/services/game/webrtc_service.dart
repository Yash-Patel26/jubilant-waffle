import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final Function(MediaStream)? onRemoteStream;
  final Function(RTCSessionDescription)? onOffer;
  final Function(RTCSessionDescription)? onAnswer;
  final Function(RTCIceCandidate)? onIceCandidate;
  final Function(String)? onConnectionStateChange;
  final Function(String)? onError;

  WebRTCService({
    this.onRemoteStream,
    this.onOffer,
    this.onAnswer,
    this.onIceCandidate,
    this.onConnectionStateChange,
    this.onError,
  });

  // STUN servers for NAT traversal
  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
    ],
  };

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final camera = await Permission.camera.request();
      final microphone = await Permission.microphone.request();

      if (camera.isGranted && microphone.isGranted) {
        return true;
      } else {
        onError?.call('Camera and microphone permissions are required');
        return false;
      }
    }
    return true;
  }

  Future<void> initialize() async {
    try {
      // Request permissions
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) return;

      // Create peer connection
      _peerConnection = await createPeerConnection(_iceServers, {
        'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
        'optional': [],
      });

      // Set up event handlers
      _peerConnection!.onIceCandidate = (candidate) {
        onIceCandidate?.call(candidate);
      };

      _peerConnection!.onConnectionState = (state) {
        onConnectionStateChange?.call(state.toString());
      };

      // Track-based API for remote media
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams.first;
          onRemoteStream?.call(_remoteStream!);
        }
      };

      // Get local media stream
      await _getLocalStream();
    } catch (e) {
      onError?.call('Failed to initialize WebRTC: $e');
    }
  }

  Future<void> _getLocalStream() async {
    try {
      final constraints = {
        'audio': true,
        'video': {
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '30',
          },
          'facingMode': 'user',
          'optional': [],
        },
      };

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);

      // Add local stream to peer connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    } catch (e) {
      onError?.call('Failed to get local stream: $e');
    }
  }

  Future<RTCSessionDescription> createOffer() async {
    try {
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });

      await _peerConnection!.setLocalDescription(offer);
      onOffer?.call(offer);
      return offer;
    } catch (e) {
      onError?.call('Failed to create offer: $e');
      rethrow;
    }
  }

  Future<RTCSessionDescription> createAnswer() async {
    try {
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });

      await _peerConnection!.setLocalDescription(answer);
      onAnswer?.call(answer);
      return answer;
    } catch (e) {
      onError?.call('Failed to create answer: $e');
      rethrow;
    }
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    try {
      await _peerConnection!.setRemoteDescription(description);
    } catch (e) {
      onError?.call('Failed to set remote description: $e');
    }
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    try {
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      onError?.call('Failed to add ICE candidate: $e');
    }
  }

  void toggleMute(bool muted) {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (final track in audioTracks) {
        track.enabled = !muted;
      }
    }
  }

  void toggleVideo(bool enabled) {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      for (final track in videoTracks) {
        track.enabled = enabled;
      }
    }
  }

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  RTCPeerConnection? get peerConnection => _peerConnection;

  Future<void> dispose() async {
    try {
      _localStream?.getTracks().forEach((track) => track.stop());
      _remoteStream?.getTracks().forEach((track) => track.stop());
      await _peerConnection?.close();
      await _peerConnection?.dispose();

      _localStream = null;
      _remoteStream = null;
      _peerConnection = null;
    } catch (e) {
      onError?.call('Error disposing WebRTC: $e');
    }
  }
}

// Signaling service for WebRTC
class WebRTCSignalingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _signalingChannel;

  Future<void> joinSignalingRoom(
    String sessionId, {
    required String currentUserId,
    required void Function(RTCSessionDescription offer) onOffer,
    required void Function(RTCSessionDescription answer) onAnswer,
    required void Function(RTCIceCandidate candidate) onIceCandidate,
  }) async {
    _signalingChannel = _supabase
        .channel('public:webrtc_signaling:session_id=eq.$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'webrtc_signaling',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            final messageType = data['message_type'] as String;
            final messageData = jsonDecode(data['message_data'] as String);

            // Ignore messages sent by self using sender_id column
            final senderIdColumn = data['sender_id'] as String?;
            if (senderIdColumn != null && senderIdColumn == currentUserId) {
              return;
            }

            if (messageType == 'offer') {
              onOffer(RTCSessionDescription(
                messageData['sdp'] as String,
                messageData['type'] as String,
              ));
            } else if (messageType == 'answer') {
              onAnswer(RTCSessionDescription(
                messageData['sdp'] as String,
                messageData['type'] as String,
              ));
            } else if (messageType == 'ice-candidate') {
              onIceCandidate(RTCIceCandidate(
                messageData['candidate'] as String,
                messageData['sdpMid'] as String?,
                messageData['sdpMLineIndex'] as int?,
              ));
            }
          },
        )
        .subscribe();
  }

  Future<void> sendSignalingMessage({
    required String sessionId,
    required String messageType,
    required Map<String, dynamic> messageData,
  }) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      await _supabase.from('webrtc_signaling').insert({
        'session_id': sessionId,
        'sender_id': uid,
        'message_type': messageType,
        'message_data': jsonEncode(messageData),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to send signaling message: $e');
    }
  }

  void dispose() {
    _signalingChannel?.unsubscribe();
  }
}
