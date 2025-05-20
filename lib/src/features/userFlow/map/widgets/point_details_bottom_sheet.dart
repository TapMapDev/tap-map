import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'working_hours_widget.dart';

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
    return FadeTransition(
      opacity: _animController,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
            ),
          ],
        ),
        child: ListView(
          controller: widget.scrollController,
          padding: EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Индикатор перетаскивания
            Center(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(vertical: 12),
                width: _isDragging ? 60 : 40,
                height: 5,
                decoration: BoxDecoration(
                  color: _isDragging ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            
            // Заголовок
            Text(
              _properties['name']?.toString() ?? 'Информация о точке',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Базовая информация
            if (_properties['subcategory'] != null)
              _buildInfoRow('Категория', _properties['subcategory'].toString()),
            
            if (_properties['address'] != null)
              _buildInfoRow('Адрес', _properties['address'].toString()),
              
            if (_properties['description'] != null)
              _buildInfoRow('Описание', _properties['description'].toString()),
              
            // Дополнительная информация
            if (_properties['working_hours'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: WorkingHoursWidget(workingHoursJson: _properties['working_hours'].toString()),
              ),
              
            if (_properties['phone'] != null)
              GestureDetector(
                onTap: () => _launchUrl('tel:${_properties['phone']}'),
                child: _buildInfoRow('Телефон', _properties['phone'].toString(), isClickable: true),
              ),
              
            if (_properties['website'] != null)
              GestureDetector(
                onTap: () => _launchUrl(_properties['website'].toString()),
                child: _buildInfoRow('Сайт', _properties['website'].toString(), isClickable: true),
              ),
              
            if (_properties['openStatus'] != null || _properties['open_status'] != null)
              _buildInfoRow('Статус', (_properties['openStatus'] ?? _properties['open_status']).toString()),
              
            if (_properties['distance'] != null)
              _buildInfoRow('Расстояние', _properties['distance'].toString()),
              
            if (_properties['rating'] != null)
              _buildInfoRow('Рейтинг', _properties['rating'].toString()),
              
            if (_properties['images'] != null && _properties['images'] is List && (_properties['images'] as List).isNotEmpty)
              _buildImageGallery((_properties['images'] as List)),
              
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  // Метод для запуска URL
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
  
  // Вспомогательный метод для отображения строки информации
  Widget _buildInfoRow(String label, String value, {bool isClickable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          isClickable
              ? Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(fontSize: 16),
                ),
        ],
      ),
    );
  }
  
  // Вспомогательный метод для отображения галереи изображений
  Widget _buildImageGallery(List images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
          child: Text(
            'Фотографии',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageUrl = images[index]['url'] ?? images[index]['image'];
              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: 200,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200,
                        height: 150,
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 150,
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.error, color: Colors.grey[600]),
                        ),
                      );
                    },
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
