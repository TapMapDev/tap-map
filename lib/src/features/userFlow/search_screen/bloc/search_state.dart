part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Начальное состояние
class SearchInitial extends SearchState {}

// Состояние загрузки
class SearchLoading extends SearchState {}

// Состояние с загруженными данными
class SearchLoaded extends SearchState {
  final List<ScreenResponseModal> places;
  final bool isEndReached;
  final int offset;

  SearchLoaded({
    required this.places,
    this.isEndReached = false,
    this.offset = 0,
  });

  SearchLoaded copyWith({
    List<ScreenResponseModal>? places,
    bool? isEndReached,
    int? offset,
  }) {
    return SearchLoaded(
      places: places ?? this.places,
      isEndReached: isEndReached ?? this.isEndReached,
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [places, isEndReached, offset];
}

// Ошибка загрузки
class SearchError extends SearchState {
  final String message;

  SearchError(this.message);

  @override
  List<Object?> get props => [message];
}

// Состояние, когда место было лайкнуто
class PlaceLiked extends SearchState {
  final int placeId;

  PlaceLiked(this.placeId);

  @override
  List<Object?> get props => [placeId];
}

// Состояние, когда место было пропущено
class PlaceSkipped extends SearchState {
  final int placeId;

  PlaceSkipped(this.placeId);

  @override
  List<Object?> get props => [placeId];
}

// Состояние, когда больше нет мест для загрузки
class NoMorePlaces extends SearchState {}
