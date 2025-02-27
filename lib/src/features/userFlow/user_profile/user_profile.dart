import 'package:flutter/material.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/src/features/auth/authorization_repository.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          await getIt.get<AuthorizationRepositoryImpl>().logout();
          Navigator.pushReplacementNamed(context, '/authorization');
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.red,
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 21, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "log out",
                  // style: TextStylesManager.drawerErrorText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
