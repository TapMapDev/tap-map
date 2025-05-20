import 'package:flutter/material.dart';

class ImageGalleryWidget extends StatefulWidget {
  final List<dynamic> images;
  final VoidCallback onBack;
  
  const ImageGalleryWidget({
    Key? key,
    required this.images,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ImageGalleryWidget> createState() => _ImageGalleryWidgetState();
}

class _ImageGalleryWidgetState extends State<ImageGalleryWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int page = _pageController.page?.round() ?? 0;
      if (_currentPage != page) {
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
          // Галерея изображений с обработкой ошибок
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final imageUrl = widget.images[index]['url'] ?? widget.images[index]['image'];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200], // Фон для случая ошибки загрузки
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Изображение с обработкой ошибок
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 48,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4A69FF),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                    // Градиент поверх изображения
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0.50, 0.41),
                          end: Alignment(0.50, 1.00),
                          colors: [
                            Colors.black.withOpacity(0), 
                            Colors.black
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
                  color: Color(0x7F2F2E2D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          
          // Счетчик фотографий
          Positioned(
            right: 16,
            bottom: 48,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: ShapeDecoration(
                color: Color(0x7F2F2E2D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Индикаторы страниц с учетом активной страницы
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length > 7 ? 7 : widget.images.length,
                (index) {
                  final bool isActive = index == _currentPage;
                  return Container(
                    width: isActive ? 20 : 8,
                    height: 4,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: ShapeDecoration(
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
