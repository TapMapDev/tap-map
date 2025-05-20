import 'package:flutter/material.dart';

class ImageGalleryWidget extends StatefulWidget {
  final List<dynamic> images;
  final Function()? onBack;

  const ImageGalleryWidget({
    Key? key,
    required this.images,
    this.onBack,
  }) : super(key: key);

  @override
  State<ImageGalleryWidget> createState() => _ImageGalleryWidgetState();
}

class _ImageGalleryWidgetState extends State<ImageGalleryWidget> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      int page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 392,
      width: double.infinity,
      child: Stack(
        children: [
          // Изображения галереи
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final imageUrl = widget.images[index]['url'] ?? widget.images[index]['image'];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Изображение
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        _isLoading = false;
                        return child;
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[600],
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Градиент поверх изображения
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0.5, 0.4),
                          end: Alignment(0.5, 1.0),
                          colors: [
                            Colors.black.withOpacity(0),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Кнопка назад
          Positioned(
            left: 16,
            top: 49,
            child: GestureDetector(
              onTap: widget.onBack,
              child: Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(6),
                decoration: ShapeDecoration(
                  color: const Color(0x7F2F2E2D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          
          // Счетчик фотографий
          if (widget.images.length > 1)
            Positioned(
              right: 16,
              bottom: 48,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: ShapeDecoration(
                  color: const Color(0x7F2F2E2D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${widget.images.length}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.w600,
                        height: 1.38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Индикаторы страниц
          Positioned(
            left: 16,
            right: 16,
            bottom: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (index) {
                // Разделяем ширину индикаторов равномерно
                final double indicatorWidth = (MediaQuery.of(context).size.width - 32) / widget.images.length;
                final bool isActive = index == _currentPage;
                
                return Container(
                  width: indicatorWidth,
                  height: 4,
                  margin: EdgeInsets.symmetric(horizontal: 1),
                  decoration: ShapeDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (isActive)
                        Container(
                          width: indicatorWidth * 0.45, // Активный индикатор занимает 45% ширины
                          height: 4,
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          
          // Индикатор загрузки
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
