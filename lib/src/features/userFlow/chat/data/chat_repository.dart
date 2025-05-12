import 'package:dio/dio.dart';
import 'package:tap_map/core/network/dio_client.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  final DioClient _dioClient;

  ChatRepository({required DioClient dioClient}) : _dioClient = dioClient;

  Future<List<ChatModel>> fetchChats() async {
    try {
      final response = await _dioClient.get('/chat/list/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final chats = data.map((json) => ChatModel.fromJson(json)).toList();
        return chats;
      }
      throw Exception('Failed to fetch chats: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch chats: $e');
    }
  }

  Future<Map<String, dynamic>> fetchChatWithMessages(int chatId) async {
    try {
      final chatResponse = await _dioClient.get('/chat/$chatId/');
      final messagesResponse = await _dioClient.get('/chat/$chatId/messages/');

      if (chatResponse.statusCode == 200 &&
          messagesResponse.statusCode == 200) {
        final chat = ChatModel.fromJson(chatResponse.data);
        final List<dynamic> messagesData = messagesResponse.data;
        final messages =
            messagesData.map((json) => MessageModel.fromJson(json)).toList();

        return {
          'chat': chat,
          'messages': messages,
        };
      }
      throw Exception('Failed to fetch chat data: ${chatResponse.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch chat data: $e');
    }
  }

  Future<int> createChat(
      {required String type, required int participantId}) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        'participants_ids[]': participantId,
      });

      final response = await _dioClient.post(
        '/chat/create/',
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['chat_id'] as int;
      } else {
        throw Exception('Failed to create chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  Future<void> markChatAsRead(int chatId) async {
    try {
      final response = await _dioClient.post(
        '/chats/$chatId/mark_read/',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark chat as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to mark chat as read: $e');
    }
  }

  Future<List<MessageModel>> getChatHistory(int chatId) async {
    try {
      final response = await _dioClient.get('/chat/$chatId/messages/');
      if (response.statusCode == 200) {
        final List<dynamic> messagesData = response.data;
        final messages =
            messagesData.map((json) => MessageModel.fromJson(json)).toList();
        return messages;
      }
      throw Exception('Failed to fetch chat history: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMessage(int chatId, int messageId, String action) async {
    try {
      final response = await _dioClient.post(
        '/chat/$chatId/messages/$messageId/delete/',
        data: {
          'action': action,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> editMessage(int chatId, int messageId, String text) async {
    try {
      final response = await _dioClient.patch(
        '/chat/$chatId/messages/$messageId/edit/',
        data: {
          'text': text,
          'edited_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to edit message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }
}
