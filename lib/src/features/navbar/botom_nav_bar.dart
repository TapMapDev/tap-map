import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_bloc/chat_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_bloc/chat_event.dart';

class BottomNavbar extends StatelessWidget {
  final StatefulNavigationShell shell;
  const BottomNavbar({super.key, required this.shell});

  void _onItemTapped(BuildContext context, int index) {
    // Индекс 3 - это вкладка "Чат"
    final bool wasOnChatTab = shell.currentIndex == 3;
    final bool goingToChatTab = index == 3;
    
    // Если переходим на вкладку чатов - подключаемся к WebSocket
    if (goingToChatTab && !wasOnChatTab) {
      print('🔥 BottomNavbar: Переход на вкладку чатов, подключаемся к WebSocket');
      context.read<ChatBloc>().add(const ConnectToChatEvent());
    }
    // Если уходим с вкладки чатов - отключаемся от WebSocket
    else if (wasOnChatTab && !goingToChatTab) {
      print('🔥 BottomNavbar: Уход с вкладки чатов, отключаемся от WebSocket');
      context.read<ChatBloc>().add(const DisconnectFromChatEvent());
    }

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
        onTap: (index) => _onItemTapped(context, index),
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
