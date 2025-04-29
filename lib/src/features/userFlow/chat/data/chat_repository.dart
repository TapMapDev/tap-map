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
