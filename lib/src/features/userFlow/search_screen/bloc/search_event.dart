part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Загрузка мест
class LoadPlaces extends SearchEvent {
  final int offset;
  final int limit;

  LoadPlaces({
    required this.offset,
    required this.limit,
  });

  @override
  List<Object?> get props => [offset, limit];
}

// Лайк места
class LikePlace extends SearchEvent {
  final int placeId;

  LikePlace({required this.placeId});

  @override
  List<Object?> get props => [placeId];
}

// Пропуск места
class SkipPlace extends SearchEvent {
  final int placeId;

  SkipPlace({required this.placeId});

  @override
  List<Object?> get props => [placeId];
}

// Загрузка дополнительных мест
class LoadMorePlaces extends SearchEvent {
  final int offset;
  final int limit;

  LoadMorePlaces({
    required this.offset,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [offset, limit];
}

// Загрузка по категории
class LoadPlacesByCategory extends SearchEvent {
  final String category;
  final int offset;
  final int limit;

  LoadPlacesByCategory({
    required this.category,
    this.offset = 0,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [category, offset, limit];
}

// Сброс поиска
class ResetSearch extends SearchEvent {}
