import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tap_map/core/network/dio_client.dart';
import 'package:tap_map/src/features/userFlow/chat/data/local/chat_data_source.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart';

/// Реализация удаленного источника данных для чатов
class RemoteChatDataSource implements ChatDataSource {
  final DioClient _dioClient;
  final SharedPreferences _prefs;
  static const String _pinnedMessageKey = 'pinned_message_';
  ChatWebSocketService? _webSocketService;

  RemoteChatDataSource({
    required DioClient dioClient,
    required SharedPreferences prefs,
    ChatWebSocketService? webSocketService,
  })  : _dioClient = dioClient,
        _prefs = prefs,
        _webSocketService = webSocketService;

  @override
  Future<List<ChatModel>> getChats() async {
    try {
      final response = await _dioClient.get('/chat/list/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final chats = data.map((json) => ChatModel.fromJson(json)).toList();
        return chats;
      }
      throw Exception('Не удалось получить список чатов: ${response.statusCode}');
    } catch (e) {
      throw Exception('Не удалось получить список чатов: $e');
    }
  }

  @override
  Future<ChatModel?> getChatById(int chatId) async {
    try {
      final response = await _dioClient.get('/chat/$chatId/');

      if (response.statusCode == 200) {
        return ChatModel.fromJson(response.data);
      }
      throw Exception('Не удалось получить чат: ${response.statusCode}');
    } catch (e) {
      throw Exception('Не удалось получить чат: $e');
    }
  }

  @override
  Future<List<MessageModel>> getMessagesForChat(int chatId) async {
    try {
      final response = await _dioClient.get('/chat/$chatId/messages/');
      if (response.statusCode == 200) {
        final List<dynamic> messagesData = response.data;
        final messages = messagesData.map((json) => MessageModel.fromJson(json)).toList();
        return messages;
      }
      throw Exception('Не удалось получить сообщения чата: ${response.statusCode}');
    } catch (e) {
      throw Exception('Не удалось получить сообщения чата: $e');
    }
  }

  @override
  Future<int> createChat({required String type, required int participantId}) async {
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
        throw Exception('Не удалось создать чат: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Не удалось создать чат: $e');
    }
  }

  @override
  Future<void> markChatAsRead(int chatId) async {
    try {
      final response = await _dioClient.post(
        '/chats/$chatId/mark_read/',
      );

      if (response.statusCode != 200) {
        throw Exception('Не удалось отметить чат как прочитанный: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Не удалось отметить чат как прочитанный: $e');
    }
  }

  @override
  Future<void> deleteMessage(int chatId, int messageId, String action) async {
    try {
      final url = '/chat/$chatId/messages/$messageId/delete/';
      final data = {'action': action};
      final response = await _dioClient.post(
        url,
        data: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Не удалось удалить сообщение: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Не удалось удалить сообщение: $e');
    }
  }

  @override
  Future<MessageModel> editMessage(int chatId, int messageId, String text) async {
    try {
      final response = await _dioClient.patch(
        '/chat/$chatId/messages/$messageId/edit/',
        data: {
          'text': text,
          'edited_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        // Создаем модель сообщения из ответа API
        final Map<String, dynamic> data = response.data;
        return MessageModel.fromJson(data);
      } else {
        throw Exception('Не удалось отредактировать сообщение: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Не удалось отредактировать сообщение: $e');
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required int chatId,
    required String text,
    int? replyToId,
    int? forwardedFromId,
    List<Map<String, String>>? attachments,
  }) async {
    try {
      // Проверяем, инициализирован ли ChatWebSocketService
      if (_webSocketService == null) {
        throw Exception('ChatWebSocketService не инициализирован');
      }
      
      // Отправляем сообщение через WebSocket
      _webSocketService!.sendMessage(
        chatId: chatId,
        text: text,
        replyToId: replyToId,
        forwardedFromId: forwardedFromId,
        attachments: attachments,
      );

      // Получаем имя пользователя из SharedPreferences
      final String? username = _prefs.getString('username');
      if (username == null) {
        throw Exception('Имя пользователя не установлено');
      }

      // Создаем локальное представление сообщения с временным ID
      final temporaryId = DateTime.now().millisecondsSinceEpoch;
      final message = MessageModel(
        id: temporaryId,
        text: text,
        chatId: chatId,
        replyToId: replyToId,
        forwardedFromId: forwardedFromId,
        createdAt: DateTime.now(),
        senderUsername: username,
        isRead: false,
        type: _getMessageType(attachments),
        attachments: attachments ?? [],
      );
      
      return message;
    } catch (e) {
      throw Exception('Ошибка при отправке сообщения: $e');
    }
  }
  
  // Вспомогательный метод для определения типа сообщения на основе вложений
  MessageType _getMessageType(List<Map<String, String>>? attachments) {
    if (attachments == null || attachments.isEmpty) {
      return MessageType.text;
    }

    final contentType = attachments.first['content_type']?.toLowerCase() ?? '';
    if (contentType.startsWith('video/')) {
      return MessageType.video;
    } else if (contentType.startsWith('image/')) {
      return MessageType.image;
    } else {
      return MessageType.file;
    }
  }

  @override
  Future<void> pinMessage({
    required int chatId,
    required int messageId,
  }) async {
    try {
      final url = '/chat/$chatId/messages/$messageId/pin/';

      final response = await _dioClient.client.post(
        url,
        data: {},
        options: Options(
          headers: _dioClient.client.options.headers,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Сохраняем ID закрепленного сообщения локально
        await _prefs.setInt('$_pinnedMessageKey$chatId', messageId);
      } else {
        throw Exception('Не удалось закрепить сообщение: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при закреплении сообщения: $e');
    }
  }

  @override
  Future<void> unpinMessage({
    required int chatId,
    required int messageId,
  }) async {
    try {
      final url = '/chat/$chatId/messages/$messageId/unpin/';

      final response = await _dioClient.client.post(
        url,
        data: {},
        options: Options(
          headers: _dioClient.client.options.headers,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Удаляем ID закрепленного сообщения из локального хранилища
        await _prefs.remove('$_pinnedMessageKey$chatId');
      } else {
        throw Exception('Не удалось открепить сообщение: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при откреплении сообщения: $e');
    }
  }

  @override
  Future<int?> getPinnedMessageId(int chatId) async {
    return _prefs.getInt('$_pinnedMessageKey$chatId');
  }

  @override
  Future<String> uploadFile(String filePath) async {
    try {
      final file = await MultipartFile.fromFile(filePath);
      final formData = FormData.fromMap({'file': file});
      final response = await _dioClient.client.post(
        '/chat/upload_file/',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Ошибка при загрузке файла: ${response.statusCode}');
      }

      // Извлекаем URL из ответа сервера
      final attachments = response.data['attachments'] as List;
      if (attachments.isEmpty) {
        throw Exception('Нет URL файла в ответе');
      }

      final fileUrl = attachments[0]['url'] as String;
      return fileUrl;
    } catch (e) {
      throw Exception('Ошибка при загрузке файла: $e');
    }
  }

  // Методы для работы с кэшированием - в удаленном источнике не реализованы
  
  @override
  Future<List<MessageModel>> getCachedMessagesForChat(int chatId) async {
    // Возвращаем пустой список, так как удаленный источник не имеет кэша
    return [];
  }
  
  @override
  Future<void> cacheMessages(int chatId, List<MessageModel> messages) async {
    // Ничего не делаем, т.к. удаленный источник не кэширует
  }
  
  @override
  Future<void> cacheMessage(int chatId, MessageModel message) async {
    // Ничего не делаем, т.к. удаленный источник не кэширует
  }
  
  @override
  Future<void> cacheMediaFile(String url, String localPath, String contentType) async {
    // Ничего не делаем, т.к. удаленный источник не кэширует
  }
  
  @override
  Future<String?> getMediaFilePath(String url) async {
    // Удаленный источник не хранит локальные пути к файлам
    return null;
  }
  
  @override
  Stream<List<ChatModel>> watchChats() {
    // Удаленный источник не поддерживает наблюдение за данными
    throw UnimplementedError('Метод не реализован для удаленного источника');
  }
  
  @override
  Stream<List<MessageModel>> watchMessages(int chatId) {
    // Удаленный источник не поддерживает наблюдение за данными
    throw UnimplementedError('Метод не реализован для удаленного источника');
  }
}
