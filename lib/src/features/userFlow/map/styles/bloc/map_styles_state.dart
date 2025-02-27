part of 'map_styles_bloc.dart';

abstract class MapStyleState {}

class MapStyleLoading extends MapStyleState {}

class MapStyleError extends MapStyleState {
  final String message;
  MapStyleError({required this.message});
}

class MapStyleSuccess extends MapStyleState {
  final List<MapStyleResponceModel> mapStyles;

  MapStyleSuccess({required this.mapStyles});
}

class UserMapStyleSuccess extends MapStyleState {
  final MapStyleResponceModel userMapStyle;

  UserMapStyleSuccess({required this.userMapStyle});
}

class MapStyleUpdateSuccess extends MapStyleState {
  final int newStyleId;
  final String styleUri;

  MapStyleUpdateSuccess({required this.newStyleId, required this.styleUri});
  // @override
  // List<Object?> get props => [newStyleId, styleUri];
}
