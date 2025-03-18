import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/src/features/userFlow/search_screen/bloc/search_bloc.dart';
import 'package:tap_map/src/features/userFlow/search_screen/search_repository.dart';
import 'package:tcard/tcard.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchBloc(getIt<SearchRepository>()),
      child: const _SearchPageContent(),
    );
  }
}

class _SearchPageContent extends StatefulWidget {
  const _SearchPageContent({super.key});

  @override
  State<_SearchPageContent> createState() => _SearchPageContentState();
}

class _SearchPageContentState extends State<_SearchPageContent> {
  final TCardController _controller = TCardController();

  @override
  void initState() {
    super.initState();
    // Инициируем загрузку одного места при создании виджета
    context.read<SearchBloc>().add(LoadPlaces(offset: 0, limit: 10));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Найди то самое место'),
      ),
      body: BlocConsumer<SearchBloc, SearchState>(
        listener: (context, state) {
          if (state is SearchError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is NoMorePlaces) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Больше мест не найдено')),
            );
          }
        },
        builder: (context, state) {
          if (state is SearchInitial || state is SearchLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SearchLoaded) {
            if (state.places.isEmpty) {
              return const Center(child: Text('Ничего не найдено'));
            }

            // Преобразуем все места в список карточек
            final List<Widget> cards = [];

            for (final place in state.places) {
              // Для каждого места используем первое изображение, если оно есть
              if (place.images.isNotEmpty) {
                cards.add(
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(place.images.first.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Накладываем инфу о месте поверх картинки
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${place.name}\n${place.description}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
            }

            return Center(
              child: TCard(
                cards: cards,
                size: const Size(380, 550),
                controller: _controller,
                onForward: (index, info) {
                  debugPrint('Свайп вперёд! Текущий индекс: $index');
                  debugPrint('Направление свайпа: ${info.direction}');

                  if (index < state.places.length) {
                    final currentPlace = state.places[index];

                    // Если свайп вправо - лайкаем место
                    if (info.direction == SwipDirection.Right) {
                      context
                          .read<SearchBloc>()
                          .add(LikePlace(placeId: currentPlace.id));
                    }
                    // Если свайп влево - пропускаем место
                    else if (info.direction == SwipDirection.Left) {
                      context
                          .read<SearchBloc>()
                          .add(SkipPlace(placeId: currentPlace.id));
                    }
                  }
                },
                onEnd: () {
                  debugPrint('Все карточки просмотрены!');
                  // Загружаем следующие места
                  context.read<SearchBloc>().add(
                        LoadMorePlaces(offset: state.offset + 1),
                      );
                },
              ),
            );
          } else {
            return const Center(child: Text('Начните поиск'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Программный переход к следующей карточке (свайп вправо)
          _controller.forward(direction: SwipDirection.Right);
        },
        child: const Icon(Icons.thumb_up),
      ),
    );
  }
}
