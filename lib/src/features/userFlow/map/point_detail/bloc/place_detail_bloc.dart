import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repository/point_repository.dart';
import 'place_detail_event.dart';
import 'place_detail_state.dart';

class PlaceDetailBloc extends Bloc<PlaceDetailEvent, PlaceDetailState> {
  final PointRepository repo;

  PlaceDetailBloc(this.repo) : super(PlaceDetailInitial()) {
    on<FetchPlaceDetail>(_onFetch);
    on<SwitchPlaceDetailTab>(_onSwitchTab);
  }

  Future<void> _onFetch(
      FetchPlaceDetail e, Emitter<PlaceDetailState> emit) async {
    emit(PlaceDetailLoading());
    try {
      final detail = await repo.fetchPlaceDetail(e.placeId);
      emit(PlaceDetailLoaded(detail));
    } catch (err) {
      emit(PlaceDetailError(err.toString()));
    }
  }
  
  /// Обработчик переключения вкладок
  void _onSwitchTab(SwitchPlaceDetailTab event, Emitter<PlaceDetailState> emit) {
    final currentState = state;
    if (currentState is PlaceDetailLoaded) {
      emit(currentState.copyWith(selectedTab: event.tab));
    }
  }
}
