import 'package:bloc/bloc.dart';
import 'package:tap_map/src/features/userFlow/map/styles/map_styles_repository.dart';
import 'package:tap_map/src/features/userFlow/map/styles/map_styles_responce_modal.dart';

part 'map_styles_event.dart';
part 'map_styles_state.dart';

class MapStyleBloc extends Bloc<MapStyleEvent, MapStyleState> {
  final MapStyleRepository repository;

  MapStyleBloc(this.repository) : super(MapStyleLoading()) {
    on<FetchMapStylesEvent>((event, emit) async {
      try {
        final styles = await repository.fetchMapStyles();
        emit(MapStyleSuccess(mapStyles: styles));
      } catch (e) {
        emit(MapStyleError(message: e.toString()));
      }
    });
    on<UpdateMapStyleEvent>((event, emit) async {
      emit(MapStyleUpdateSuccess(styleUri: event.uriStyle));
    });
    @override
    Future<void> close() {
      return super.close();
    }
  }
}
