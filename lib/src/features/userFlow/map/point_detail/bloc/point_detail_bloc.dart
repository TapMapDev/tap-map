import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repository/point_repository.dart';
import 'point_detail_event.dart';
import 'point_detail_state.dart';

class PointDetailBloc extends Bloc<PointDetailEvent, PointDetailState> {
  final PointRepository repo;

  PointDetailBloc(this.repo) : super(PointDetailInitial()) {
    on<FetchPointDetail>(_onFetch);
  }

  Future<void> _onFetch(
      FetchPointDetail e, Emitter<PointDetailState> emit) async {
    emit(PointDetailLoading());
    try {
      final detail = await repo.fetchPointDetail(e.pointId);
      emit(PointDetailLoaded(detail));
    } catch (err) {
      emit(PointDetailError(err.toString()));
    }
  }
}
