import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class BottomNavbar extends StatelessWidget {
  final StatefulNavigationShell shell;
  const BottomNavbar({super.key, required this.shell});



  void _onItemTapped(int index) {
    shell.goBranch(
      index,
      initialLocation: index == shell.currentIndex, // чтоб не перезагружался
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: shell.currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
              icon: SvgPicture.asset('assets/svg/afisha.svg'), label: 'Афиша'),
          BottomNavigationBarItem(
              icon: SvgPicture.asset('assets/svg/lookngplc.svg'),
              label: 'Найти место'),
          BottomNavigationBarItem(
              icon: SvgPicture.asset('assets/svg/map.svg'), label: 'Карта'),
          BottomNavigationBarItem(
              icon: SvgPicture.asset('assets/svg/chat1.svg'), label: 'Чат'),
          BottomNavigationBarItem(
              icon: SvgPicture.asset('assets/svg/Avatar.svg'),
              label: 'Профиль'),
        ],
      ),
    );
  }
}
