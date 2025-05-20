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
          // Галерея изображений
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final imageUrl = widget.images[index]['url'] ?? widget.images[index]['image'];
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
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
                child: Transform.rotate(
                  angle: 3.14, // 180 градусов в радианах
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 18,
                  ),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
                      height: 1.38,
                      letterSpacing: -0.43,
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
            bottom: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length > 7 ? 7 : widget.images.length,
                (index) {
                  if (index == 0) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        clipBehavior: Clip.antiAlias,
                        decoration: ShapeDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 22,
                                height: 4,
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      width: 49,
                      height: 4,
                      margin: EdgeInsets.only(left: 2),
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
