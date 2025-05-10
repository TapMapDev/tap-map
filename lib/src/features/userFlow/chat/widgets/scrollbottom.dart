import 'package:flutter/material.dart';

class ScrollToBottomButton extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onPressed;

  const ScrollToBottomButton({
    super.key,
    required this.scrollController,
    required this.onPressed,
  });

  @override
  State<ScrollToBottomButton> createState() => _ScrollToBottomButtonState();
}

class _ScrollToBottomButtonState extends State<ScrollToBottomButton> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (!widget.scrollController.hasClients) return;
    final shouldShow = widget.scrollController.offset > 200;
    if (_isVisible != shouldShow) {
      setState(() => _isVisible = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();
    return Positioned(
      right: 16,
      bottom: 80,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: widget.onPressed,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.arrow_downward, color: Colors.white),
      ),
    );
  }
}
