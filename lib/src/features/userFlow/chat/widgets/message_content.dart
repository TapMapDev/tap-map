import 'package:flutter/material.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';
import 'package:tap_map/src/features/userFlow/chat/widgets/video_player_widget.dart';

class MessageContent extends StatelessWidget {
  final MessageModel message;

  const MessageContent({
    super.key,
    required this.message,
  });

  bool _isImageUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.startsWith('http') &&
        (lowerUrl.endsWith('.jpg') ||
            lowerUrl.endsWith('.jpeg') ||
            lowerUrl.endsWith('.png') ||
            lowerUrl.endsWith('.gif') ||
            lowerUrl.endsWith('.webp'));
  }

  bool _isVideoUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.startsWith('http') &&
        (lowerUrl.endsWith('.mp4') ||
            lowerUrl.endsWith('.mov') ||
            lowerUrl.endsWith('.avi') ||
            lowerUrl.endsWith('.webm'));
  }

  Widget _buildVideoPlayer(String url) {
    return VideoPlayerWidget(videoUrl: url);
  }

  Widget _buildAttachment(
      BuildContext context, Map<String, String> attachment) {
    final url = attachment['url'] ?? '';
    final contentType = attachment['content_type'] ?? '';

    // Проверяем тип контента
    final isImage = contentType.startsWith('image/') ||
        url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.png') ||
        url.toLowerCase().endsWith('.gif');

    final isVideo = contentType.startsWith('video/') ||
        url.toLowerCase().endsWith('.mp4') ||
        url.toLowerCase().endsWith('.mov') ||
        url.toLowerCase().endsWith('.avi') ||
        url.toLowerCase().endsWith('.webm');

    if (isImage) {
      return GestureDetector(
        onTap: () => _showFullScreenImage(context, url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            url,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error),
                ),
              );
            },
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (isVideo) {
      return _buildVideoPlayer(url);
    } else {
      return GestureDetector(
        onTap: () => _openFile(context, url),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.attach_file),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  url.split('/').last,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _openFile(BuildContext context, String url) {
    // TODO: Implement file opening functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening file: ${url.split('/').last}'),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error, color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Если есть вложения, показываем их
    if (message.attachments.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...message.attachments
              .map((attachment) => _buildAttachment(context, attachment)),
          if (message.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(message.text),
          ],
        ],
      );
    }

    // Если текст - это URL изображения или видео, показываем его
    if (_isImageUrl(message.text)) {
      return GestureDetector(
        onTap: () => _showFullScreenImage(context, message.text),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            message.text,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error),
                ),
              );
            },
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (_isVideoUrl(message.text)) {
      return _buildVideoPlayer(message.text);
    }

    // Иначе показываем обычный текст
    return Text(message.text);
  }
}
