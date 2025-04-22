import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/icons/data/icons_repository.dart';
import 'package:tap_map/src/features/userFlow/map/icons/model/icons_response_modal.dart';

part 'icons_event.dart';
part 'icons_state.dart';

class IconsBloc extends Bloc<IconsEvent, IconsState> {
  final IconsRepository iconsRepository;

  IconsBloc(this.iconsRepository) : super(IconsInitial()) {
    on<FetchIconsEvent>(_onFetchIcons);
  }

  Future<void> _onFetchIcons(
      FetchIconsEvent event, Emitter<IconsState> emit) async {
    debugPrint(
        '🔄 IconsBloc: Начинаем загрузку иконок для стиля ${event.styleId}');
    emit(IconsLoading());
    try {
      final icons = await iconsRepository.fetchIcons(event.styleId);
      debugPrint('📦 IconsBloc: Получено ${icons.length} иконок');

      if (icons.isEmpty) {
        debugPrint(
            '⚠️ IconsBloc: Нет доступных иконок для стиля ${event.styleId}');
        emit(IconsError(message: "Нет доступных иконок для этого стиля"));
      } else {
        // ✅ Формируем Map: { "name" -> "text_color" }
        final Map<String, String> textColors = {
          for (var icon in icons) icon.name: icon.textColor
        };

        debugPrint(
            '📦 IconsBloc: Успешно загружены иконки: ${icons.map((e) => e.name).join(', ')}');
        emit(IconsSuccess(
            icons: icons, styleId: event.styleId, textColors: textColors));
      }
    } catch (e) {
      debugPrint('❌ IconsBloc: Ошибка загрузки иконок: $e');
      emit(IconsError(message: "Ошибка загрузки иконок"));
    }
  }
}
