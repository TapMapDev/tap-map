import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/bloc/point_detail_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/bloc/point_detail_event.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/bloc/point_detail_state.dart';
import 'tab_navigation.dart';

/// Обертка для табов с интеграцией с PointDetailBloc
class TabNavigationBloc extends StatefulWidget {
  final int photoCount;
  final int reviewCount;

  const TabNavigationBloc({
    Key? key,
    required this.photoCount,
    required this.reviewCount,
  }) : super(key: key);

  @override
  State<TabNavigationBloc> createState() => _TabNavigationBlocState();
}

class _TabNavigationBlocState extends State<TabNavigationBloc>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Реагируем на изменения вкладок по тапу в TabBar
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      // Индекс в контроллере изменился - оповещаем Bloc
      final PointDetailTab tab;
      switch (_tabController.index) {
        case 0:
          tab = PointDetailTab.overview;
          break;
        case 1:
          tab = PointDetailTab.photos;
          break;
        case 2:
          tab = PointDetailTab.reviews;
          break;
        case 3:
          tab = PointDetailTab.menu;
          break;
        default:
          tab = PointDetailTab.overview;
      }
      
      context.read<PointDetailBloc>().add(SwitchPointDetailTab(tab));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Слушаем изменения состояния BLoC и синхронизируем контроллер табов
    return BlocListener<PointDetailBloc, PointDetailState>(
      listenWhen: (previous, current) {
        // Реагируем только когда меняется таб в состоянии PointDetailLoaded
        if (previous is PointDetailLoaded && current is PointDetailLoaded) {
          return previous.selectedTab != current.selectedTab;
        }
        return false;
      },
      listener: (context, state) {
        if (state is PointDetailLoaded) {
          // Состояние в блоке изменилось - синхронизируем контроллер
          final int index;
          switch (state.selectedTab) {
            case PointDetailTab.overview:
              index = 0;
              break;
            case PointDetailTab.photos:
              index = 1;
              break;
            case PointDetailTab.reviews:
              index = 2;
              break;
            case PointDetailTab.menu:
              index = 3;
              break;
            default:
              index = 0;
          }
          
          if (_tabController.index != index) {
            _tabController.animateTo(index);
          }
        }
      },
      child: DetailTabNavigation(
        controller: _tabController,
        photoCount: widget.photoCount,
        reviewCount: widget.reviewCount,
      ),
    );
  }
}
