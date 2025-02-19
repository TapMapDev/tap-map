import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tap_map/src/features/map/major_map.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _MainScreenState();
}

class _MainScreenState extends State<BottomNavbar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MajorMap(), // Карта
    const SearchScreen(), // Поиск
    const FavoritesScreen(), // Избранное
    const ProfileScreen(), // Профиль
    const SettingsScreen(), // Настройки
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Показываем активный экран
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, // Цвет активной иконки
        unselectedItemColor: Colors.grey, // Цвет неактивных иконок
        type: BottomNavigationBarType.fixed, // Фиксированное расположение
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

// Заглушки для экранов
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Афиша'));
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Найти Место'));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Карта'));
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Профиль'));
  }
}
