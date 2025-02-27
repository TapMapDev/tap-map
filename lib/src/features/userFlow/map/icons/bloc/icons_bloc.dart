import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tap_map/src/features/userFlow/map/icons/icons_repository.dart';
import 'package:tap_map/src/features/userFlow/map/icons/icons_responce_modal.dart';

part 'icons_event.dart';
part 'icons_state.dart';

class IconsBloc extends Bloc<IconsEvent, IconsState> {
  final IconsRepository iconsRepository;

  IconsBloc(this.iconsRepository) : super(IconsInitial()) {
    on<FetchIconsEvent>(_onFetchIcons);
  }

  Future<void> _onFetchIcons(
      FetchIconsEvent event, Emitter<IconsState> emit) async {
    emit(IconsLoading());
    try {
      final icons = await iconsRepository.fetchIcons(event.styleId);

      if (icons.isEmpty) {
        // Если API вернул пустой список
        emit(IconsError(message: "Нет доступных иконок для этого стиля"));
      } else {
        emit(IconsSuccess(icons: icons, styleId: event.styleId));
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки иконок: $e');
      emit(IconsError(message: "Ошибка загрузки иконок"));
    }
  }
}
