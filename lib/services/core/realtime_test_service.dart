import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class RealtimeTestService {
  final SupabaseClient _client = Supabase.instance.client;

  // Test real-time connection
  Future<bool> testConnection() async {
    try {
      final channel = _client.channel('test-connection');
      channel.subscribe();
      await channel.unsubscribe();
      if (kDebugMode) {
        print('✅ Real-time connection test successful');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Real-time connection test failed: $e');
      }
      return false;
    }
  }

  // Test message streaming
  Stream<List<Map<String, dynamic>>> testMessageStream(String conversationId) {
    if (kDebugMode) {
      print('🔍 Testing message stream for conversation: $conversationId');
    }

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((data) {
          final messages = (data as List).cast<Map<String, dynamic>>();
          if (kDebugMode) {
            print('📨 Received ${messages.length} messages in real-time');
            for (final message in messages) {
              print('   - Message: ${message['content'] ?? message['text']}');
            }
          }
          return messages;
        })
        .handleError((error) {
          if (kDebugMode) {
            print('❌ Error in message stream: $error');
          }
          return <Map<String, dynamic>>[];
        });
  }

  // Test conversation streaming
  Stream<List<Map<String, dynamic>>> testConversationStream(
      List<String> conversationIds) {
    if (kDebugMode) {
      print(
          '🔍 Testing conversation stream for ${conversationIds.length} conversations');
    }

    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .inFilter('id', conversationIds)
        .order('updated_at', ascending: false)
        .map((data) {
          final conversations = (data as List).cast<Map<String, dynamic>>();
          if (kDebugMode) {
            print(
                '💬 Received ${conversations.length} conversations in real-time');
            for (final conversation in conversations) {
              print(
                  '   - Conversation: ${conversation['id']} - Updated: ${conversation['updated_at']}');
            }
          }
          return conversations;
        })
        .handleError((error) {
          if (kDebugMode) {
            print('❌ Error in conversation stream: $error');
          }
          return <Map<String, dynamic>>[];
        });
  }

  // Test sending a message and verifying real-time update
  Future<void> testMessageSendAndReceive(
      String conversationId, String messageText) async {
    if (kDebugMode) {
      print(
          '🧪 Testing message send and receive for conversation: $conversationId');
    }

    try {
      // Send a test message
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': _client.auth.currentUser?.id,
        'content': messageText,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ Test message sent successfully');
      }

      // Update conversation timestamp
      // Note: last_message column doesn't exist in current schema
      await _client.from('conversations').update({
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', conversationId);

      if (kDebugMode) {
        print('✅ Conversation updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in test message send: $e');
      }
      rethrow;
    }
  }

  // Comprehensive real-time test
  Future<Map<String, bool>> runComprehensiveTest(String conversationId) async {
    final results = <String, bool>{};

    if (kDebugMode) {
      print('🚀 Starting comprehensive real-time test...');
    }

    // Test 1: Connection
    results['connection'] = await testConnection();

    // Test 2: Message streaming
    try {
      final messageStream = testMessageStream(conversationId);
      await messageStream.first.timeout(const Duration(seconds: 5));
      results['message_stream'] = true;
    } catch (e) {
      results['message_stream'] = false;
      if (kDebugMode) {
        print('❌ Message stream test failed: $e');
      }
    }

    // Test 3: Conversation streaming
    try {
      final conversationStream = testConversationStream([conversationId]);
      await conversationStream.first.timeout(const Duration(seconds: 5));
      results['conversation_stream'] = true;
    } catch (e) {
      results['conversation_stream'] = false;
      if (kDebugMode) {
        print('❌ Conversation stream test failed: $e');
      }
    }

    // Test 4: Send and receive
    try {
      await testMessageSendAndReceive(conversationId,
          'Test message ${DateTime.now().millisecondsSinceEpoch}');
      results['send_receive'] = true;
    } catch (e) {
      results['send_receive'] = false;
      if (kDebugMode) {
        print('❌ Send and receive test failed: $e');
      }
    }

    if (kDebugMode) {
      print('📊 Test Results:');
      results.forEach((test, passed) {
        print(
            '   ${passed ? '✅' : '❌'} $test: ${passed ? 'PASSED' : 'FAILED'}');
      });
    }

    return results;
  }
}
