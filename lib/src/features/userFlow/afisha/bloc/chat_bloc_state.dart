part of 'chat_bloc_bloc.dart';

sealed class ChatBlocState extends Equatable {
  const ChatBlocState();
  
  @override
  List<Object> get props => [];
}

final class ChatBlocInitial extends ChatBlocState {}
