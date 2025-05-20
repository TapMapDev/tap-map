import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'working_hours_widget.dart';
import 'image_gallery_widget.dart';
import 'friends_visited_widget.dart';

class PointDetailsBottomSheet extends StatefulWidget {
  final Map<dynamic, dynamic> properties;
  final ScrollController scrollController;
  
  // Ключ для доступа к состоянию BottomSheet
  final GlobalKey<_PointDetailsBottomSheetState>? sheetKey;

  const PointDetailsBottomSheet({
    Key? key,
    required this.properties,
    required this.scrollController,
    this.sheetKey,
  }) : super(key: key ?? sheetKey);

  @override
  State<PointDetailsBottomSheet> createState() => _PointDetailsBottomSheetState();
  
  // Метод для обновления данных BottomSheet извне
  static void updateProperties(BuildContext context, Map<dynamic, dynamic> newProperties) {
    final state = context.findAncestorStateOfType<_PointDetailsBottomSheetState>();
    if (state != null) {
      state._updateProperties(newProperties);
    }
  }
}

class _PointDetailsBottomSheetState extends State<PointDetailsBottomSheet> 
    with SingleTickerProviderStateMixin {
  
  bool _isDragging = false;
  late AnimationController _animController;
  
  // Локальная копия свойств для обновления
  late Map<dynamic, dynamic> _properties;
  
  @override
  void initState() {
    super.initState();
    _properties = widget.properties;
    
    // Добавляем слушатель для отслеживания перетаскивания
    widget.scrollController.addListener(_onScrollChange);
    
    // Инициализируем контроллер анимации
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Запускаем анимацию
    _animController.forward();
  }
  
  // Новый метод для обновления свойств
  void _updateProperties(Map<dynamic, dynamic> newProperties) {
    setState(() {
      _properties = newProperties;
      
      // Воспроизводим короткую анимацию для индикации обновления
      _animController.reset();
      _animController.forward();
    });
  }
  
  void _onScrollChange() {
    if (!mounted) return;
    final isDragging = widget.scrollController.hasClients && 
        widget.scrollController.position.isScrollingNotifier.value;
    if (_isDragging != isDragging) {
      setState(() {
        _isDragging = isDragging;
      });
    }
  }
  
  @override
  void dispose() {
    widget.scrollController.removeListener(_onScrollChange);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Подготовка данных для галереи
    List<dynamic> images = [];
    if (_properties['images'] != null && _properties['images'] is List) {
      images = _properties['images'] as List;
    } else {
      // Если фотографий нет, добавим хотя бы одно заглушку
      images = [{'url': 'https://placehold.co/600x400/png'}];
    }
    
    // Данные о друзьях (заглушка если их нет)
    List<String> friendsAvatars = [];
    int friendsCount = 0;
    
    if (_properties['friends'] != null && _properties['friends'] is List) {
      List friendsList = _properties['friends'] as List;
      friendsCount = friendsList.length;
      
      for (var friend in friendsList) {
        if (friend['avatar'] != null) {
          friendsAvatars.add(friend['avatar']);
        }
      }
    }
    
    // Если нет данных о друзьях, используем заглушки для демонстрации
    if (friendsAvatars.isEmpty) {
      friendsCount = 12; // Примерное количество для демонстрации
      friendsAvatars = List.generate(5, (index) => 'https://placehold.co/46x46');
    }

    return FadeTransition(
      opacity: _animController,
      // Возвращаемся к DraggableScrollableSheet для обеспечения прокрутки
      child: DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        builder: (context, scrollController) {
          // Заменяем переданный контроллер на новый, чтобы лист можно было прокручивать
          widget.scrollController = scrollController;
          
          return Container(
            width: MediaQuery.of(context).size.width,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x00000000),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                )
              ],
            ),
            child: Stack(
              children: [
                // Галерея изображений
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  child: ImageGalleryWidget(
                    images: images,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
                
                // Основной контент
                Positioned(
                  left: 0,
                  top: 382, // по макету
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: ShapeDecoration(
                      color: const Color(0x194A69FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Color(0x21000000),
                          blurRadius: 6,
                          offset: Offset(0, 0),
                          spreadRadius: 0,
                        )
                      ],
                    ),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (OverscrollIndicatorNotification overscroll) {
                        overscroll.disallowIndicator();
                        return true;
                      },
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.only(top: 0, bottom: 24),
                        children: [
                          // Индикатор перетаскивания
                          Container(
                            height: 18,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                width: _isDragging ? 60 : 40,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: _isDragging ? Colors.grey[600] : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                          
                          // Заголовок
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              _properties['name']?.toString() ?? 'Информация о точке',
                              style: TextStyle(
                                fontSize: 24,
                                fontFamily: 'SF Pro Display',
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2F2E2D),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Базовая информация
                          if (_properties['subcategory'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildInfoRow('Категория', _properties['subcategory'].toString()),
                            ),
                          
                          if (_properties['address'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildInfoRow('Адрес', _properties['address'].toString()),
                            ),
                            
                          if (_properties['description'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildInfoRow('Описание', _properties['description'].toString()),
                            ),
                            
                          SizedBox(height: 16),
                          
                          // Блок "Были друзья"
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: FriendsVisitedWidget(
                              avatars: friendsAvatars,
                              friendsCount: friendsCount,
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Дополнительная информация
                          if (_properties['working_hours'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: WorkingHoursWidget(workingHoursJson: _properties['working_hours'].toString()),
                            ),
                            
                          if (_properties['phone'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: GestureDetector(
                                onTap: () => _launchUrl('tel:${_properties['phone']}'),
                                child: _buildInfoRow('Телефон', _properties['phone'].toString(), isClickable: true),
                              ),
                            ),
                            
                          if (_properties['website'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: GestureDetector(
                                onTap: () => _launchUrl(_properties['website'].toString()),
                                child: _buildInfoRow('Сайт', _properties['website'].toString(), isClickable: true),
                              ),
                            ),
                            
                          if (_properties['openStatus'] != null || _properties['open_status'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildInfoRow('Статус', (_properties['openStatus'] ?? _properties['open_status']).toString()),
                            ),
                            
                          if (_properties['distance'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildInfoRow('Расстояние', _properties['distance'].toString()),
                            ),
                            
                          if (_properties['rating'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildInfoRow('Рейтинг', _properties['rating'].toString()),
                            ),
                          
                          // Отображение изображений в ленте, если их более одного
                          if (images.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 16.0),
                              child: _buildImageGallery(images),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Метод для запуска URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Не удалось открыть URL: $url');
    }
  }
  
  // Метод для построения строки с информацией
  Widget _buildInfoRow(String label, String value, {bool isClickable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF828282),
              fontSize: 14,
              fontFamily: 'SF Pro Display',
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isClickable ? Color(0xFF4A69FF) : Color(0xFF2F2E2D),
                    fontSize: 16,
                    fontFamily: 'SF Pro Display',
                    fontWeight: isClickable ? FontWeight.w500 : FontWeight.w400,
                    height: 1.35,
                    decoration: isClickable ? TextDecoration.underline : null,
                    decorationColor: isClickable ? Color(0xFF4A69FF) : null,
                  ),
                ),
              ),
              if (isClickable)
                Icon(
                  label.toLowerCase() == 'телефон' ? Icons.call : Icons.open_in_new,
                  size: 18,
                  color: Color(0xFF4A69FF),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Обновленная галерея для внутреннего отображения
  Widget _buildImageGallery(List<dynamic> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Фотографии',
          style: TextStyle(
            color: Color(0xFF828282),
            fontSize: 14,
            fontFamily: 'SF Pro Text',
            fontWeight: FontWeight.w500,
            height: 1.29,
            letterSpacing: -0.08,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageUrl = images[index]['url'] ?? images[index]['image'];
              return Container(
                width: 120,
                margin: EdgeInsets.only(right: index < images.length - 1 ? 8 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
