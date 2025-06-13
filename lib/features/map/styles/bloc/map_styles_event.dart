part of 'map_styles_bloc.dart';

abstract class MapStyleEvent {}

class FetchMapStylesEvent extends MapStyleEvent {}

class UpdateMapStyleEvent extends MapStyleEvent {
  final int newStyleId;
  final String uriStyle;

  UpdateMapStyleEvent({required this.newStyleId, required this.uriStyle});
}

class ResetMapStyleEvent extends MapStyleEvent {}