import 'package:flutter/material.dart';

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
              
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  // Вспомогательный метод для отображения строки информации
  Widget _buildInfoRow(String label, String value) {
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
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
