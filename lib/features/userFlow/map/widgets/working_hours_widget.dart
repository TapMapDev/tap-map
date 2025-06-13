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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Часы работы',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          ...WorkingHoursFormatter.formatWorkingHours(workingHoursJson),
        ],
      ),
    );
  }
}
