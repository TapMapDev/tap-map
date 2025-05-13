import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tap_map/core/network/dio_client.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  final DioClient _dioClient;
  final SharedPreferences _prefs;
  static const String _pinnedMessageKey = 'pinned_message_';

  ChatRepository({
    required DioClient dioClient,
    required SharedPreferences prefs,
  })  : _dioClient = dioClient,
        _prefs = prefs;

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
      print('📡 Fetching chat data for chatId: $chatId');
      final chatResponse = await _dioClient.get('/chat/$chatId/');
      print('📡 Chat response data: ${chatResponse.data}');

      final messagesResponse = await _dioClient.get('/chat/$chatId/messages/');
      print('📡 Messages response data: ${messagesResponse.data}');

      if (chatResponse.statusCode == 200 &&
          messagesResponse.statusCode == 200) {
        final chat = ChatModel.fromJson(chatResponse.data);
        print(
            '📱 Parsed chat model: chatId=${chat.chatId}, pinnedMessageId=${chat.pinnedMessageId}');

        final List<dynamic> messagesData = messagesResponse.data;
        final messages =
            messagesData.map((json) => MessageModel.fromJson(json)).toList();
        print('📱 Parsed ${messages.length} messages');

        return {
          'chat': chat,
          'messages': messages,
        };
      }
      throw Exception('Failed to fetch chat data: ${chatResponse.statusCode}');
    } catch (e) {
      print('❌ Error fetching chat data: $e');
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

  Future<void> pinMessage({
    required int chatId,
    required int messageId,
  }) async {
    try {
      print(
          '📌 Sending pin request for chatId: $chatId, messageId: $messageId');
      final response = await _dioClient.post(
        '/chat/$chatId/pin/',
        data: {
          'message_id': messageId,
        },
      );
      print('📌 Pin response status: ${response.statusCode}');
      print('📌 Pin response data: ${response.data}');

      if (response.statusCode == 200) {
        // Сохраняем ID закрепленного сообщения локально
        await _prefs.setInt('$_pinnedMessageKey$chatId', messageId);
      } else {
        throw Exception('Failed to pin message');
      }
    } catch (e) {
      print('❌ Pin message error details: $e');
      throw Exception('Error pinning message: $e');
    }
  }

  Future<void> unpinMessage({
    required int chatId,
    required int messageId,
  }) async {
    try {
      final response = await _dioClient.post(
        '/chat/$chatId/unpin/',
        data: {
          'message_id': messageId,
        },
      );
      print('📥 Unpin message response status: ${response.statusCode}');
      print('📥 Unpin message response data: ${response.data}');

      if (response.statusCode == 200) {
        // Удаляем ID закрепленного сообщения из локального хранилища
        await _prefs.remove('$_pinnedMessageKey$chatId');
      } else {
        throw Exception('Failed to unpin message');
      }
    } catch (e) {
      print('❌ Unpin message error details: $e');
      throw Exception('Error unpinning message: $e');
    }
  }

  Future<int?> getPinnedMessageId(int chatId) async {
    return _prefs.getInt('$_pinnedMessageKey$chatId');
  }

  Future<String> uploadFile(String filePath) async {
    try {
      print('📤 Starting file upload process');
      print('📤 File path: $filePath');

      final file = await MultipartFile.fromFile(filePath);
      print('📤 File size: ${file.length} bytes');

      final formData = FormData.fromMap({'file': file});
      print('📤 FormData created');

      print('📤 Sending request to server...');
      final response = await _dioClient.client.post(
        '/chat/upload_file/',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('📤 Upload file response status: ${response.statusCode}');
      print('📤 Upload file response data: ${response.data}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('❌ Upload failed with status: ${response.statusCode}');
        throw Exception('Ошибка при загрузке файла: ${response.statusCode}');
      }

      // Извлекаем URL из ответа сервера
      final attachments = response.data['attachments'] as List;
      if (attachments.isEmpty) {
        throw Exception('No file URL in response');
      }

      final fileUrl = attachments[0]['url'] as String;
      print('✅ File uploaded successfully. URL: $fileUrl');
      return fileUrl;
    } catch (e) {
      print('❌ Error uploading file: $e');
      if (e is DioException) {
        print('📤 Request URL: ${e.requestOptions.uri}');
        print('📤 Request method: ${e.requestOptions.method}');
        print('📤 Request headers: ${e.requestOptions.headers}');
        print('📤 Response status: ${e.response?.statusCode}');
        print('📤 Response data: ${e.response?.data}');
      }
      throw Exception('Ошибка при загрузке файла: $e');
    }
  }
}
