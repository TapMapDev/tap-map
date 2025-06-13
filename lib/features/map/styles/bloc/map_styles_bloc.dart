import 'package:bloc/bloc.dart';
import 'package:tap_map/features/map/styles/data/map_styles_repository.dart';
import 'package:tap_map/features/map/styles/model/map_styles_responce_modal.dart';

part 'map_styles_event.dart';
part 'map_styles_state.dart';

class MapStyleBloc extends Bloc<MapStyleEvent, MapStyleState> {
  final MapStyleRepository repository;

  MapStyleBloc(this.repository) : super(MapStyleLoading()) {
    /// Загружаем список доступных стилей
    on<FetchMapStylesEvent>((event, emit) async {
      try {
        final styles = await repository.fetchMapStyles();
        emit(MapStyleSuccess(mapStyles: styles));
      } catch (e) {
        emit(MapStyleError(message: e.toString()));
      }
    });

    /// Обновляем стиль карты
    on<UpdateMapStyleEvent>((event, emit) async {
      emit(MapStyleUpdateSuccess(newStyleId: event.newStyleId, styleUri: event.uriStyle));

      /// Добавляем задержку перед сбросом состояния
      await Future.delayed(const Duration(milliseconds: 500));

      /// После обновления стиля отправляем `ResetMapStyleEvent`
      add(ResetMapStyleEvent());
    });

    /// Сбрасываем состояние после успешного обновления стиля
    on<ResetMapStyleEvent>((event, emit) {
      /// Проверяем, было ли состояние `MapStyleUpdateSuccess`
      if (state is MapStyleUpdateSuccess) {
        final successState = state as MapStyleUpdateSuccess;
        emit(MapStyleSuccess(
          selectedStyleId: successState.newStyleId,
          mapStyles: repository.getCachedMapStyles(), // ✅ Теперь кэшируем стили
        ));
      }
    });
  }

  @override
  Future<void> close() {
    return super.close();
  }
}