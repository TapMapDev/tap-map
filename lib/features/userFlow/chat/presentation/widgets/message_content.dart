import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:tap_map/features/userFlow/chat/data/models/message_model.dart';
import 'package:tap_map/features/userFlow/chat/presentation/widgets/video_player_widget.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.clamp(0.0, 280.0);

        return Container(
          width: maxWidth,
          constraints: BoxConstraints(
            maxHeight: maxWidth * 1.5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: maxWidth,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: maxWidth,
                  child: VideoPlayerWidget(
                    videoUrl: url,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachment(
      BuildContext context, Map<String, String> attachment) {
    final url = attachment['url'] ?? '';
    final contentType = attachment['content_type'] ?? '';

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
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.clamp(0.0, 280.0);

          return GestureDetector(
            onTap: () => _showFullScreenImage(context, url),
            child: Container(
              width: maxWidth,
              constraints: BoxConstraints(
                maxHeight: maxWidth * 1.5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.error),
                      ),
                    );
                  },
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      );
    } else if (isVideo) {
      return _buildVideoPlayer(url);
    } else {
      return GestureDetector(
        onTap: () => _openFile(context, url),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
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
                  style: const TextStyle(fontSize: 14),
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
        builder: (context) => _FullScreenImageViewer(imageUrl: imageUrl),
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
          ...message.attachments.map((attachment) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildAttachment(context, attachment),
              )),
          if (message.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message.text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ],
      );
    }

    // Если текст - это URL изображения или видео, показываем его
    if (_isImageUrl(message.text)) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.clamp(0.0, 280.0);

          return GestureDetector(
            onTap: () => _showFullScreenImage(context, message.text),
            child: Container(
              width: maxWidth,
              constraints: BoxConstraints(
                maxHeight: maxWidth * 1.5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.text,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.error),
                      ),
                    );
                  },
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      );
    }

    if (_isVideoUrl(message.text)) {
      return _buildVideoPlayer(message.text);
    }

    // Иначе показываем обычный текст
    return Text(
      message.text,
      style: const TextStyle(fontSize: 16),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final double _scale = 1.0;
  Offset _offset = Offset.zero;
  bool _isDragging = false;

  void _handleScaleStart(ScaleStartDetails details) {
    _isDragging = true;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_isDragging) {
      setState(() {
        _offset += details.focalPointDelta;
      });
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _isDragging = false;
    // Если смещение вверх или вниз больше 100, закрываем экран
    if (_offset.dy.abs() > 100) {
      Navigator.of(context).pop();
    } else {
      // Возвращаем к исходному состоянию
      setState(() {
        _offset = Offset.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onScaleEnd: _handleScaleEnd,
        child: Stack(
          children: [
            // Затемненный фон
            Container(
              color: Colors.black
                  .withOpacity(1 - (_offset.dy.abs() / 500).clamp(0.0, 1.0)),
            ),
            // Изображение
            Transform.translate(
              offset: _offset,
              child: Center(
                child: PhotoView(
                  imageProvider: NetworkImage(widget.imageUrl),
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.transparent),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.0,
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.error, color: Colors.white),
                  ),
                ),
              ),
            ),
            // Кнопка закрытия
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
