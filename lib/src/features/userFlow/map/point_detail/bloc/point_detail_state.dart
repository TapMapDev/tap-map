import 'package:tap_map/src/features/userFlow/map/point_detail/data/models/point_detail.dart';

abstract class PointDetailState {}

class PointDetailInitial extends PointDetailState {}

class PointDetailLoading extends PointDetailState {}

class PointDetailLoaded extends PointDetailState {
  final PointDetail detail;

  PointDetailLoaded(this.detail);
}

class PointDetailError extends PointDetailState {
  final String message;

  PointDetailError(this.message);
}
