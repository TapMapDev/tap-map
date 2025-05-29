import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repository/point_repository.dart';
import 'point_detail_event.dart';
import 'point_detail_state.dart';

class PointDetailBloc extends Bloc<PointDetailEvent, PointDetailState> {
  final PointRepository repo;
  static const String _selectedTabKey = 'selected_point_detail_tab';

  PointDetailBloc(this.repo) : super(PointDetailInitial()) {
    on<FetchPointDetail>(_onFetch);
    on<SwitchPointDetailTab>(_onSwitchTab);
    
    // Восстанавливаем сохраненную вкладку при создании блока
    _restoreSelectedTab();
  }

  /// Восстанавливает сохраненную вкладку из SharedPreferences
  Future<void> _restoreSelectedTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTabIndex = prefs.getInt(_selectedTabKey);
      
      if (savedTabIndex != null && state is PointDetailLoaded) {
        final tab = PointDetailTab.values[savedTabIndex];
        add(SwitchPointDetailTab(tab));
      }
    } catch (e) {
      // Игнорируем ошибки при восстановлении таба
    }
  }

  /// Сохраняет выбранную вкладку в SharedPreferences
  Future<void> _saveSelectedTab(PointDetailTab tab) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_selectedTabKey, tab.index);
    } catch (e) {
      // Игнорируем ошибки при сохранении таба
    }
  }

  Future<void> _onFetch(
      FetchPointDetail e, Emitter<PointDetailState> emit) async {
    emit(PointDetailLoading());
    try {
      final detail = await repo.fetchPointDetail(e.pointId);
      
      // Восстанавливаем последнюю выбранную вкладку или используем обзор по умолчанию
      final prefs = await SharedPreferences.getInstance();
      final savedTabIndex = prefs.getInt(_selectedTabKey);
      final tab = savedTabIndex != null 
          ? PointDetailTab.values[savedTabIndex] 
          : PointDetailTab.overview;
          
      emit(PointDetailLoaded(detail, selectedTab: tab));
    } catch (err) {
      emit(PointDetailError(err.toString()));
    }
  }
  
  /// Обработчик переключения вкладок
  void _onSwitchTab(SwitchPointDetailTab event, Emitter<PointDetailState> emit) {
    final currentState = state;
    if (currentState is PointDetailLoaded) {
      emit(currentState.copyWith(selectedTab: event.tab));
      // Сохраняем выбранную вкладку
      _saveSelectedTab(event.tab);
    }
  }
}
