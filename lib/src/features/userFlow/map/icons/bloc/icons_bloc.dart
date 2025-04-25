import 'package:equatable/equatable.dart';
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
    emit(IconsLoading());
    try {
      final icons = await iconsRepository.fetchIcons(event.styleId);
      if (icons.isEmpty) {
        emit(IconsError(message: 'Нет доступных иконок для этого стиля'));
      } else {
        final Map<String, String> textColors = {
          for (var icon in icons) icon.name: icon.textColor
        };
        emit(IconsSuccess(
            icons: icons, styleId: event.styleId, textColors: textColors));
      }
    } catch (e) {
      emit(IconsError(message: 'Ошибка загрузки иконок'));
    }
  }
}
