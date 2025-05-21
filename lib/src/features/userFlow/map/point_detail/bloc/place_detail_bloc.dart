import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repository/place_repository.dart';
import 'place_detail_event.dart';
import 'place_detail_state.dart';

class PlaceDetailBloc extends Bloc<PlaceDetailEvent, PlaceDetailState> {
  final PlaceRepository repo;

  PlaceDetailBloc(this.repo) : super(PlaceDetailInitial()) {
    on<FetchPlaceDetail>(_onFetch);
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
}
