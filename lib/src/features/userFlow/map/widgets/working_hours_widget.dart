import 'package:flutter/material.dart';
import 'working_hours_formatter.dart';

class WorkingHoursWidget extends StatelessWidget {
  final String workingHoursJson;
  
  const WorkingHoursWidget({
    Key? key,
    required this.workingHoursJson,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final workingHoursData = WorkingHoursFormatter.formatWorkingHours(workingHoursJson);
    final bool hasData = workingHoursData.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0x194A69FF),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 18,
                color: Color(0xFF4A69FF),
              ),
              SizedBox(width: 8),
              Text(
                'Часы работы',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2F2E2D),
                  fontFamily: 'SF Pro Display',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (hasData)
            ...workingHoursData
          else
            Text(
              'Информация о часах работы недоступна',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF828282),
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}
