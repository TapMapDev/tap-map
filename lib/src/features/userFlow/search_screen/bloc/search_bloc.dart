import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/search_screen/data/search_repository.dart';
import 'package:tap_map/src/features/userFlow/search_screen/model/search_response_modal.dart';

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
    on<InitializeSearchEvent>(_onInitializeSearch);
    on<UpdateSwipeState>(_onUpdateSwipeState);
  }

  // Обработчик обновления состояния свайпера
  void _onUpdateSwipeState(UpdateSwipeState event, Emitter<SearchState> emit) {
    if (state is! SearchLoaded) return;

    final currentState = state as SearchLoaded;
    List<int> updatedViewedPlaces = List.from(currentState.viewedPlaces);

    // Добавляем ID просмотренного места, если оно есть
    if (event.viewedPlaceId != null &&
        !updatedViewedPlaces.contains(event.viewedPlaceId)) {
      updatedViewedPlaces.add(event.viewedPlaceId!);
    }

    emit(currentState.copyWith(
      currentIndex: event.currentIndex,
      viewedPlaces: updatedViewedPlaces,
    ));
  }

  Future<void> _onInitializeSearch(
      InitializeSearchEvent event, Emitter<SearchState> emit) async {
    List<ScreenResponseModal>? cachedPlaces =
        await searchRepository.getCachedPlaces();

    if (cachedPlaces != null && cachedPlaces.isNotEmpty) {
      emit(SearchLoading(cachedPlaces: cachedPlaces, hasCachedData: true));
    } else {
      emit(SearchLoading());
    }

    try {
      final places = await searchRepository.fetchPlace();
      await searchRepository.cachePlaces(places);

      // Сохраняем текущий индекс и просмотренные места, если они были
      int currentIndex = 0;
      List<int> viewedPlaces = [];

      if (previousState is SearchLoaded) {
        final prevLoadedState = previousState as SearchLoaded;
        currentIndex = prevLoadedState.currentIndex;
        viewedPlaces = prevLoadedState.viewedPlaces;
      }

      emit(SearchLoaded(
        places: places,
        offset: 0,
        isEndReached: false,
        currentIndex: currentIndex,
        viewedPlaces: viewedPlaces,
      ));
    } catch (e) {
      if (cachedPlaces != null && cachedPlaces.isNotEmpty) {
        int currentIndex = 0;
        List<int> viewedPlaces = [];

        if (previousState is SearchLoaded) {
          final prevLoadedState = previousState as SearchLoaded;
          currentIndex = prevLoadedState.currentIndex;
          viewedPlaces = prevLoadedState.viewedPlaces;
        }

        emit(SearchLoaded(
          places: cachedPlaces,
          offset: 0,
          isEndReached: true,
          currentIndex: currentIndex,
          viewedPlaces: viewedPlaces,
        ));
      } else {
        emit(SearchError('Ошибка загрузки данных: ${e.toString()}'));
      }
    }
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
      await searchRepository.likePlace(event.placeId,
          objectType: event.objectType);
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
      await searchRepository.skipPlace(event.placeId,
          objectType: event.objectType);
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
