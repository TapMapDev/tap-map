// Телефоны, сайт, соцсети
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

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
          Text('Контакты', style: AppTextStyles.h18),
          const SizedBox(height: 16),
          _line(Icons.phone, phone, () => _launch('tel:$phone')),
          const SizedBox(height: 12),
          _line(Icons.language, website, () => _launch(website.startsWith('http') ? website : 'https://$website')),
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
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(text, style: AppTextStyles.body16),
        ],
      ),
    );
  }

  Widget _social(MapEntry<String, VoidCallback> e) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: GestureDetector(
        onTap: e.value,
        child: CircleAvatar(
          radius: 21,
          backgroundColor: AppColors.primary20,
          child: Icon(_iconFor(e.key), color: AppColors.primary),
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'telegram': return Icons.send;
      case 'instagram': return Icons.camera_alt;
      default: return Icons.public;
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
