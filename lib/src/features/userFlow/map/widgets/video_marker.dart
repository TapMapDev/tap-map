// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';

// class VideoMarker extends StatefulWidget {
//   final String videoUrl;
//   final double size;

//   const VideoMarker({
//     super.key,
//     required this.videoUrl,
//     required this.size,
//   });

//   @override
//   State<VideoMarker> createState() => _VideoMarkerState();
// }

// class _VideoMarkerState extends State<VideoMarker> {
//   VideoPlayerController? _controller;
//   bool _isInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeVideo();
//   }

//   Future<void> _initializeVideo() async {
//     try {
//       _controller = VideoPlayerController.network(widget.videoUrl);
//       await _controller!.initialize();
//       _controller!.setLooping(true);
//       _controller!.setVolume(0.0);
//       _controller!.play();

//       if (mounted) {
//         setState(() {
//           _isInitialized = true;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error initializing video: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isInitialized || _controller == null) {
//       return SizedBox(
//         width: widget.size,
//         height: widget.size,
//         child: const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     return SizedBox(
//       width: widget.size,
//       height: widget.size,
//       child: FittedBox(
//         fit: BoxFit.cover,
//         child: SizedBox(
//           width: _controller!.value.size.width,
//           height: _controller!.value.size.height,
//           child: VideoPlayer(_controller!),
//         ),
//       ),
//     );
//   }
// }
