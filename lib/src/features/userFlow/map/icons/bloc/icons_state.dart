part of 'icons_bloc.dart';

abstract class IconsState {}

class IconsInitial extends IconsState {}

class IconsLoading extends IconsState {}

class IconsSuccess extends IconsState {
  final List<IconsResponseModel> icons;
  final int styleId;

  IconsSuccess({required List<IconsResponseModel> icons, required this.styleId})
      : icons = List.unmodifiable(icons); // Неизменяемый список
}

class IconsError extends IconsState {
  final String message;
  IconsError({required this.message});
}