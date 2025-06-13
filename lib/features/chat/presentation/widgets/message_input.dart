import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tap_map/features/chat/data/models/message_model.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String) onChanged;
  final MessageModel? editingMessage;
  final VoidCallback? onCancelEdit;
  final String hintText;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final Function(PlatformFile) onFileSelected;
  final Function(XFile) onImageSelected;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSend,
    required this.onFileSelected,
    required this.onImageSelected,
    this.editingMessage,
    this.onCancelEdit,
    this.hintText = 'Введите сообщение...',
    this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  Future<void> _showAttachmentMenu(BuildContext context) async {
    print('📎 Opening attachment menu');
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Фото из галереи'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Видео из галереи'),
                onTap: () => Navigator.pop(context, 'video'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Сделать фото'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    switch (result) {
      case 'gallery':
        print('📸 Opening gallery for photo selection');
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          print('📸 Photo selected from gallery: ${image.path}');
          onImageSelected(image);
        } else {
          print('❌ No photo selected from gallery');
        }
        break;
      case 'video':
        print('🎥 Opening gallery for video selection');
        final picker = ImagePicker();
        final video = await picker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          print('🎥 Video selected from gallery: ${video.path}');
          onImageSelected(video);
        } else {
          print('❌ No video selected from gallery');
        }
        break;
      case 'camera':
        print('📸 Opening camera');
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          print('📸 Photo taken with camera: ${image.path}');
          onImageSelected(image);
        } else {
          print('❌ No photo taken with camera');
        }
        break;
      case 'file':
        print('📄 Opening file picker');
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
        if (result != null && result.files.isNotEmpty) {
          print('📄 File selected: ${result.files.first.path}');
          onFileSelected(result.files.first);
        } else {
          print('❌ No file selected');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('MessageInput: Building with editingMessage: $editingMessage');
    final theme = Theme.of(context);
    final defaultBackgroundColor = theme.scaffoldBackgroundColor;
    final defaultTextColor = theme.textTheme.bodyLarge?.color;
    final defaultIconColor = theme.iconTheme.color;

    if (editingMessage != null) {
      print(
          'MessageInput: Building edit preview for message: ${editingMessage!.text}');
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (editingMessage != null) _buildEditPreview(context),
          _buildInputField(context),
        ],
      ),
    );
  }

  Widget _buildEditPreview(BuildContext context) {
    print('MessageInput: Building edit preview');
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          Icon(Icons.edit, color: iconColor ?? Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Редактирование сообщения',
                  style: TextStyle(
                    color: textColor ?? Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  editingMessage!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor ?? Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: iconColor),
            onPressed: () {
              print('MessageInput: Cancel edit button pressed');
              onCancelEdit?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.attach_file, color: iconColor),
          onPressed: () => _showAttachmentMenu(context),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: textColor?.withOpacity(0.5),
              ),
            ),
            style: TextStyle(color: textColor),
            onChanged: onChanged,
            onSubmitted: (_) => onSend(),
          ),
        ),
        IconButton(
          icon: Icon(Icons.send, color: iconColor),
          onPressed: onSend,
        ),
      ],
    );
  }
}
