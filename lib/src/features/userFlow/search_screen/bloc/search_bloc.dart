import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/search_screen/search_repository.dart';
import 'package:tap_map/src/features/userFlow/search_screen/search_response_modal.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository searchRepository;

  SearchBloc(this.searchRepository) : super(SearchInitial()) {
    on<LoadPlaces>(_onLoadPlaces);
    on<LoadMorePlaces>(_onLoadMorePlaces);
    on<LoadPlacesByCategory>(_onLoadPlacesByCategory);
    on<LikePlace>(_onLikePlace);
    on<SkipPlace>(_onSkipPlace);
    on<ResetSearch>(_onResetSearch);
  }

  Future<void> _onLoadPlaces(
      LoadPlaces event, Emitter<SearchState> emit) async {
    emit(SearchLoading());
    try {
      final places = await searchRepository.fetchPlace();

      emit(SearchLoaded(
        places: places,
        offset: event.offset,
        isEndReached: false,
      ));
    } catch (e) {
      emit(SearchError('Ошибка загрузки данных: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMorePlaces(
      LoadMorePlaces event, Emitter<SearchState> emit) async {
    if (state is! SearchLoaded) return;

    final currentState = state as SearchLoaded;
    if (currentState.isEndReached) return;

    try {
      final newPlaces = await searchRepository.fetchPlace();

      // Фильтруем новые места, исключая уже существующие
      final filteredNewPlaces = newPlaces
          .where((newPlace) =>
              !currentState.places.any((place) => place.id == newPlace.id))
          .toList();

      if (filteredNewPlaces.isEmpty) {
        emit(currentState.copyWith(isEndReached: true));
      } else {
        emit(currentState.copyWith(
          places: [...currentState.places, ...filteredNewPlaces],
          offset: event.offset,
          isEndReached: false,
        ));
      }
    } catch (e) {
      emit(SearchError(
          'Ошибка загрузки дополнительных данных: ${e.toString()}'));
      emit(currentState);
    }
  }

  Future<void> _onLoadPlacesByCategory(
      LoadPlacesByCategory event, Emitter<SearchState> emit) async {
    emit(SearchLoading());
    try {
      // На данный момент этот функционал может быть недоступен,
      // поэтому используем fetchPlace как запасной вариант
      final places = await searchRepository.fetchPlace();

      emit(SearchLoaded(
        places: places,
        offset: event.offset,
        isEndReached: false,
      ));
    } catch (e) {
      emit(SearchError('Ошибка загрузки данных по категории: ${e.toString()}'));
    }
  }

  Future<void> _onLikePlace(LikePlace event, Emitter<SearchState> emit) async {
    try {
      await searchRepository.likePlace(event.placeId);
      emit(PlaceLiked(event.placeId));

      // Восстанавливаем предыдущее состояние списка
      if (state is PlaceLiked && previousState is SearchLoaded) {
        emit(previousState as SearchLoaded);
      }
    } catch (e) {
      emit(SearchError('Ошибка при лайке места: ${e.toString()}'));

      // Восстанавливаем предыдущее состояние списка
      if (previousState is SearchLoaded) {
        emit(previousState as SearchLoaded);
      }
    }
  }

  Future<void> _onSkipPlace(SkipPlace event, Emitter<SearchState> emit) async {
    try {
      await searchRepository.skipPlace(event.placeId);
      emit(PlaceSkipped(event.placeId));

      // Восстанавливаем предыдущее состояние списка
      if (state is PlaceSkipped && previousState is SearchLoaded) {
        emit(previousState as SearchLoaded);
      }
    } catch (e) {
      emit(SearchError('Ошибка при пропуске места: ${e.toString()}'));

      // Восстанавливаем предыдущее состояние списка
      if (previousState is SearchLoaded) {
        emit(previousState as SearchLoaded);
      }
    }
  }

  void _onResetSearch(ResetSearch event, Emitter<SearchState> emit) {
    emit(SearchInitial());
  }

  // Сохраняем предыдущее состояние для восстановления после операций
  SearchState? previousState;

  @override
  void onChange(Change<SearchState> change) {
    super.onChange(change);
    previousState = change.currentState;
  }
}
