part of 'icons_bloc.dart';

abstract class IconsState {}

class IconsInitial extends IconsState {}

class IconsLoading extends IconsState {}

class IconsSuccess extends IconsState {
  final List<IconsResponseModel> icons;
  final int styleId;
  final Map<String, String> textColors; // Новый параметр

  IconsSuccess(
      {required this.icons, required this.styleId, required this.textColors});

  @override
  List<Object?> get props => [icons, styleId, textColors];
}

class IconsError extends IconsState {
  final String message;
  IconsError({required this.message});
}
