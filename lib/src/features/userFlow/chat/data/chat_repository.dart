import 'package:dio/dio.dart';
import 'package:tap_map/core/network/dio_client.dart';

import '../models/chat_model.dart';

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

  Future<ChatModel> fetchChatById(int chatId) async {
    try {
      final response = await _dioClient.get('/chats/$chatId/');

      if (response.statusCode == 200) {
        final chat = ChatModel.fromJson(response.data);
        return chat;
      }
      throw Exception('Failed to fetch chat: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch chat: $e');
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
}
