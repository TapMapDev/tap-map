import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/OLD_app_text_styles.dart';

class CustomElevatedButton extends StatelessWidget {
  final void Function() onPressed;
  final String text;

  const CustomElevatedButton(
      {super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 42,
      child: ElevatedButton(
        style:
            ElevatedButton.styleFrom(backgroundColor: StyleManager.mainColor),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStylesManager.standartMain
                    .copyWith(color: StyleManager.bgColor),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
