// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';

// import '../models/message_model.dart';

// class ChatBubble extends StatefulWidget {
//   final MessageModel message;
//   final bool isMe;
//   final VoidCallback? onLongPress;
//   final List<MessageModel> messages;

//   const ChatBubble({
//     super.key,
//     required this.message,
//     required this.isMe,
//     this.onLongPress,
//     required this.messages,
//   });

//   @override
//   State<ChatBubble> createState() => _ChatBubbleState();
// }

// class _ChatBubbleState extends State<ChatBubble> {
//   VideoPlayerController? _videoController;

//   @override
//   void initState() {
//     super.initState();
//     _initializeVideo();
//   }

//   void _initializeVideo() {
//     final videoAttachment = widget.message.attachments.firstWhere(
//         (a) => a.isVideo,
//         orElse: () => Attachment(url: '', contentType: ''));
//     if (videoAttachment.url.isNotEmpty) {
//       _videoController = VideoPlayerController.network(videoAttachment.url)
//         ..initialize().then((_) {
//           if (mounted) setState(() {});
//         });
//     }
//   }

//   @override
//   void dispose() {
//     _videoController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onLongPress: widget.onLongPress,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//         child: Row(
//           mainAxisAlignment:
//               widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
//           children: [
//             if (!widget.isMe) _buildAvatar(),
//             const SizedBox(width: 8),
//             Flexible(
//               child: Column(
//                 crossAxisAlignment: widget.isMe
//                     ? CrossAxisAlignment.end
//                     : CrossAxisAlignment.start,
//                 children: [
//                   if (widget.message.forwardedFromUsername != null)
//                     _buildForwardedHeader(),
//                   if (widget.message.replyToId != null) _buildReplyPreview(),
//                   Container(
//                     constraints: BoxConstraints(
//                       maxWidth: MediaQuery.of(context).size.width * 0.7,
//                     ),
//                     decoration: BoxDecoration(
//                       color: widget.isMe
//                           ? Theme.of(context).primaryColor
//                           : Theme.of(context).cardColor,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         if (widget.message.attachments.isNotEmpty)
//                           _buildAttachments(),
//                         if (widget.message.text.isNotEmpty)
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(
//                               widget.message.text,
//                               style: TextStyle(
//                                 color: widget.isMe ? Colors.white : null,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   _buildMessageInfo(),
//                 ],
//               ),
//             ),
//             if (widget.isMe) _buildAvatar(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAttachments() {
//     return Column(
//       children: widget.message.attachments.map((attachment) {
//         if (attachment.isImage) {
//           return GestureDetector(
//             onTap: () => _showFullScreenImage(attachment.url),
//             child: ClipRRect(
//               borderRadius:
//                   const BorderRadius.vertical(top: Radius.circular(12)),
//               child: CachedNetworkImage(
//                 imageUrl: attachment.url,
//                 placeholder: (context, url) => const Center(
//                   child: CircularProgressIndicator(),
//                 ),
//                 errorWidget: (context, url, error) => const Icon(Icons.error),
//                 fit: BoxFit.cover,
//                 maxWidthDiskCache: 800,
//               ),
//             ),
//           );
//         } else if (attachment.isVideo) {
//           return _buildVideoPlayer();
//         }
//         return const SizedBox.shrink();
//       }).toList(),
//     );
//   }

//   Widget _buildVideoPlayer() {
//     if (_videoController?.value.isInitialized ?? false) {
//       return AspectRatio(
//         aspectRatio: _videoController!.value.aspectRatio,
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             VideoPlayer(_videoController!),
//             IconButton(
//               icon: Icon(
//                 _videoController!.value.isPlaying
//                     ? Icons.pause
//                     : Icons.play_arrow,
//                 color: Colors.white,
//                 size: 50,
//               ),
//               onPressed: () {
//                 setState(() {
//                   _videoController!.value.isPlaying
//                       ? _videoController!.pause()
//                       : _videoController!.play();
//                 });
//               },
//             ),
//           ],
//         ),
//       );
//     }
//     return const Center(child: CircularProgressIndicator());
//   }

//   void _showFullScreenImage(String imageUrl) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => Scaffold(
//           backgroundColor: Colors.black,
//           body: Stack(
//             children: [
//               Center(
//                 child: CachedNetworkImage(
//                   imageUrl: imageUrl,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//               Positioned(
//                 top: 40,
//                 right: 20,
//                 child: IconButton(
//                   icon: const Icon(Icons.close, color: Colors.white),
//                   onPressed: () => Navigator.of(context).pop(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAvatar() {
//     return CircleAvatar(
//       radius: 16,
//       backgroundColor: widget.isMe
//           ? Theme.of(context).primaryColor
//           : Theme.of(context).cardColor,
//       child: Text(
//         widget.message.senderUsername[0].toUpperCase(),
//         style: TextStyle(
//           color: widget.isMe ? Colors.white : null,
//         ),
//       ),
//     );
//   }

//   Widget _buildForwardedHeader() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 4.0),
//       child: Text(
//         'Пересланное сообщение от ${widget.message.forwardedFromUsername}',
//         style: TextStyle(
//           fontSize: 12,
//           color: Theme.of(context).textTheme.bodySmall?.color,
//         ),
//       ),
//     );
//   }

//   Widget _buildReplyPreview() {
//     final replyToMessage = widget.messages.firstWhere(
//       (m) => m.id == widget.message.replyToId,
//       orElse: () => MessageModel(
//         id: 0,
//         chatId: 0,
//         text: 'Сообщение не найдено',
//         senderUsername: 'Unknown',
//         createdAt: DateTime.now(),
//       ),
//     );
//     if (replyToMessage.id == 0) return const SizedBox.shrink();

//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.grey.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             replyToMessage.senderUsername,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//           Text(
//             replyToMessage.text,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessageInfo() {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           _formatTime(widget.message.createdAt),
//           style: TextStyle(
//             fontSize: 12,
//             color: Theme.of(context).textTheme.bodySmall?.color,
//           ),
//         ),
//         if (widget.message.editedAt != null) ...[
//           const SizedBox(width: 4),
//           Text(
//             '(ред.)',
//             style: TextStyle(
//               fontSize: 12,
//               color: Theme.of(context).textTheme.bodySmall?.color,
//             ),
//           ),
//         ],
//         if (widget.isMe) ...[
//           const SizedBox(width: 4),
//           Icon(
//             Icons.done_all,
//             size: 16,
//             color: widget.message.readBy.isNotEmpty
//                 ? Colors.blue
//                 : Theme.of(context).textTheme.bodySmall?.color,
//           ),
//         ],
//       ],
//     );
//   }

//   String _formatTime(DateTime time) {
//     return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
//   }
// }
