// Телефоны, сайт, соцсети
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ContactsSection extends StatelessWidget {
  final String phone;
  final String website;
  final Map<String, VoidCallback> socialButtons; // {'telegram': (){…}}

  const ContactsSection({
    Key? key,
    required this.phone,
    required this.website,
    this.socialButtons = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary20, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Контакты',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          _line(Icons.phone_outlined, phone, () => _launch('tel:$phone')),
          const SizedBox(height: 12),
          _line(Icons.language_outlined, website, () => _launch(website.startsWith('http') ? website : 'https://$website')),
          if (socialButtons.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: socialButtons.entries.map(_social).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.green),
          const SizedBox(width: 12),
          Text(
            text, 
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.dark,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _social(MapEntry<String, VoidCallback> e) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: e.value,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              _iconFor(e.key), 
              size: 20, 
              color: AppColors.dark,
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'telegram': return Icons.send_outlined;
      case 'instagram': return Icons.camera_alt_outlined;
      case 'vk': return Icons.public_outlined;
      default: return Icons.public_outlined;
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
