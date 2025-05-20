import 'dart:convert';
import 'package:flutter/material.dart';

class WorkingHoursFormatter {
  // Переводы дней недели
  static const Map<String, String> _dayTranslations = {
    'monday': 'Понедельник',
    'tuesday': 'Вторник',
    'wednesday': 'Среда',
    'thursday': 'Четверг',
    'friday': 'Пятница',
    'saturday': 'Суббота',
    'sunday': 'Воскресенье',
  };

  // Метод для парсинга строки JSON с расписанием
  static Map<String, Map<String, dynamic>> parseWorkingHours(String workingHoursJson) {
    try {
      final Map<String, dynamic> parsedData = jsonDecode(workingHoursJson);
      
      // Преобразуем в Map<String, Map<String, dynamic>>
      final Map<String, Map<String, dynamic>> result = {};
      
      parsedData.forEach((day, value) {
        if (value is Map) {
          result[day] = Map<String, dynamic>.from(value);
        }
      });
      
      return result;
    } catch (e) {
      // В случае ошибки возвращаем пустую карту
      return {};
    }
  }
  
  // Метод для получения форматированного времени работы
  static List<Widget> formatWorkingHours(String workingHoursJson) {
    final Map<String, Map<String, dynamic>> parsedData = parseWorkingHours(workingHoursJson);
    final List<Widget> result = [];
    
    if (parsedData.isEmpty) {
      return []; 
    }
    
    // Добавляем информацию по каждому дню
    _dayTranslations.forEach((englishDay, russianDay) {
      if (parsedData.containsKey(englishDay)) {
        final Map<String, dynamic> dayData = parsedData[englishDay]!;
        final bool isClosed = dayData['is_closed'] == true;
        final bool is24 = dayData['is_24'] == true;
        
        String timeInfo;
        Color timeColor = Color(0xFF2F2E2D);
        
        if (isClosed) {
          timeInfo = 'Закрыто';
          timeColor = Color(0xFFEB5757);
        } else if (is24) {
          timeInfo = 'Круглосуточно';
          timeColor = Color(0xFF27AE60);
        } else {
          final String openTime = dayData['open_times'] is List 
              ? dayData['open_times'][0] 
              : dayData['open_times'].toString();
          final String closeTime = dayData['close_times'] is List 
              ? dayData['close_times'][0] 
              : dayData['close_times'].toString();
          timeInfo = '$openTime - $closeTime';
        }
        
        // Проверка, является ли день текущим
        final DateTime now = DateTime.now();
        final bool isToday = _getDayIndex(englishDay) == now.weekday - 1;
        
        result.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  russianDay,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'SF Pro Display',
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    color: isToday ? Color(0xFF4A69FF) : Color(0xFF2F2E2D),
                  ),
                ),
                Text(
                  timeInfo,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'SF Pro Display',
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    color: timeColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
    
    return result;
  }
  
  // Вспомогательный метод для получения индекса дня (0 = понедельник, 6 = воскресенье)
  static int _getDayIndex(String englishDay) {
    final List<String> days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days.indexOf(englishDay);
  }
}
