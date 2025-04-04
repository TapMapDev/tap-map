import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ProfileShareSection extends StatelessWidget {
  final String username;
  final String domain;

  const ProfileShareSection({
    super.key,
    required this.username,
    this.domain = 'api.tap-map.net',
  });

  @override
  Widget build(BuildContext context) {
    final profileUrl = 'https://$domain/api/users/link/@$username/';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ваш QR-код профиля',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            QrImageView(
              data: profileUrl,
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Share.share('Мой профиль: $profileUrl'),
              icon: const Icon(Icons.share),
              label: const Text('Поделиться ссылкой'),
            ),
          ],
        ),
      ),
    );
  }
}