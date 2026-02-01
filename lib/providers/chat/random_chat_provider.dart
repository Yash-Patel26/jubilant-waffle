import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/chat/random_chat.dart';
import 'package:gamer_flick/services/chat/random_chat_service.dart';

class RandomChatProvider extends ChangeNotifier {
  final RandomChatService _service = RandomChatService();

  RandomSession? _session;
  final List<RandomMessage> _messages = [];
  String? _error;
  bool _isMatching = false;
  bool _isTyping = false;
  bool _connectedBannerShown = false;
  List<String> _interests = [];
  String _mode = 'text';
  String? _question;

  RealtimeChannel? _msgChannel;
  RealtimeChannel? _sessionChannel;
  Stream<bool>? _otherTypingStream;
  StreamSubscription<bool>? _otherTypingSub;

  RandomSession? get session => _session;
  List<RandomMessage> get messages => List.unmodifiable(_messages);
  bool get isMatching => _isMatching;
  String? get error => _error;
  bool get isTyping => _isTyping;
  List<String> get interests => List.unmodifiable(_interests);
  String get mode => _mode;
  String? get question => _question;

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
      _session = await _service.joinQueue(
        user.id,
        interests: _interests,
        mode: _mode,
        question: _question,
      );
      _subscribeRealtime();
    } catch (e) {
      _error = e.toString();
    }
    _isMatching = false;
    notifyListeners();
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
      _session = s;
      if (s.status == 'connected' && !_connectedBannerShown) {
        _connectedBannerShown = true;
      }
      notifyListeners();
    });

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      _otherTypingStream = _service.subscribeOtherTyping(_session!.id, uid);
      _otherTypingSub?.cancel();
      _otherTypingSub = _otherTypingStream!.listen((isOtherTyping) {
        // Reuse _isTyping to display stranger typing banner
        _isTyping = isOtherTyping;
        notifyListeners();
      });
    }
  }

  Future<void> send(String text) async {
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
      _msgChannel?.unsubscribe();
      _sessionChannel?.unsubscribe();
      await _otherTypingSub?.cancel();
      _msgChannel = null;
      _sessionChannel = null;
      _otherTypingStream = null;
      _otherTypingSub = null;
      _session = null;
      _messages.clear();
      _connectedBannerShown = false;
      notifyListeners();
    }
  }

  Future<void> next() async {
    await leave(reason: 'next');
    await startMatching();
  }

  void setInterests(List<String> values) {
    _interests = values;
    notifyListeners();
  }

  void setMode(String value) {
    _mode = value;
    notifyListeners();
  }

  void setQuestion(String? value) {
    _question = (value == null || value.trim().isEmpty) ? null : value.trim();
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
}
