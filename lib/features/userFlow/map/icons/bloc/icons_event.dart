part of 'icons_bloc.dart';

abstract class IconsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchIconsEvent extends IconsEvent {
  final int styleId;
  FetchIconsEvent({required this.styleId});

  @override
  List<Object?> get props => [styleId];
}