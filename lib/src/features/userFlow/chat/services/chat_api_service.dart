import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

class ChatApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.tap-map.net';
  final SharedPrefsRepository _prefsRepository =
      GetIt.I<SharedPrefsRepository>();

  Future<List<MessageModel>> getChatHistory(int chatId) async {
    try {
      final token = await _prefsRepository.getAccessToken();
      if (token == null) {
        throw Exception('Access token not found');
      }

      final response = await _dio.get(
        '$_baseUrl/api/chat/$chatId/messages/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('Chat history response: ${response.data}');

      if (response.statusCode == 200) {
        // API возвращает массив сообщений напрямую
        final List<dynamic> messages =
            response.data is List ? response.data : [];
        return messages.map((json) {
          print('Processing message: $json');
          try {
            return MessageModel(
              id: json['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
              chatId: json['chat'] as int? ?? 0,
              text: json['text'] as String? ?? '',
              senderUsername: json['sender_username'] as String? ?? 'Unknown',
              createdAt: json['created_at'] != null
                  ? DateTime.parse(json['created_at'] as String)
                  : DateTime.now(),
              replyToId: json['reply_to_id'] as int?,
              forwardedFromId: json['forwarded_from_id'] as int?,
              attachments: (json['attachments'] as List<dynamic>?)
                      ?.map((e) => {
                            'url': e['url'] as String? ?? '',
                            'content_type': e['content_type'] as String? ?? '',
                          })
                      .toList() ??
                  [],
              status: MessageStatus.sent,
              type: MessageType.text,
            );
          } catch (e) {
            print('Error processing message: $e');
            print('Message data: $json');
            rethrow;
          }
        }).toList();
      } else {
        throw Exception('Failed to load chat history');
      }
    } catch (e) {
      print('Error loading chat history: $e');
      rethrow;
    }
  }
}
