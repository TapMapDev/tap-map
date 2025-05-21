import 'package:tap_map/src/features/userFlow/map/point_detail/data/models/place_detail.dart';

abstract class PlaceDetailState {}

class PlaceDetailInitial extends PlaceDetailState {}

class PlaceDetailLoading extends PlaceDetailState {}

class PlaceDetailLoaded extends PlaceDetailState {
  final PlaceDetail detail;

  PlaceDetailLoaded(this.detail);
}

class PlaceDetailError extends PlaceDetailState {
  final String message;

  PlaceDetailError(this.message);
}
