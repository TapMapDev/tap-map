import 'package:flutter/material.dart';
import 'package:tap_map/core/common/styles.dart';

class CustomBackButton extends StatelessWidget {
  const CustomBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: StyleManager.blocColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.5, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_back,
                size: 20,
                color: Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                'Back',
                style: TextStylesManager.drawerText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
