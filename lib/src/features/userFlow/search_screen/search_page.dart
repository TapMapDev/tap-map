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
        backgroundColor: Colors.pink.shade500,
        title: const Text(
          'Найди то самое место',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
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
              cards.add(
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[200], // Фоновый цвет для карточки
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Изображение с обработкой ошибок
                      place.images.isNotEmpty
                          ? Image.network(
                              place.images.first.image,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.pink.shade300),
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Ошибка загрузки изображения: $error');
                                return Image.network(
                                  'https://picsum.photos/500/800',
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, st) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : Image.network(
                              'https://picsum.photos/500/800', // Запасное изображение
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),

                      // Накладываем инфу о месте поверх картинки
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                place.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                place.description,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: TCard(
                cards: cards,
                size: const Size(400, 580),
                controller: _controller,
                onForward: (index, info) {
                  debugPrint('Свайп вперёд! Текущий индекс: $index');
                  debugPrint('Направление свайпа: ${info.direction}');

                  if (index < state.places.length) {
                    final currentPlace = state.places[index];

                    // Если свайп вправо - лайкаем место
                    if (info.direction == SwipDirection.Right) {
                      context.read<SearchBloc>().add(LikePlace(
                          placeId: currentPlace.id,
                          objectType: currentPlace.objectType ?? 'point'));
                    }
                    // Если свайп влево - пропускаем место
                    else if (info.direction == SwipDirection.Left) {
                      context.read<SearchBloc>().add(SkipPlace(
                          placeId: currentPlace.id,
                          objectType: currentPlace.objectType ?? 'point'));
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
      floatingActionButton: null,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 30, right: 30, bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: "dislike",
                backgroundColor: Colors.red.shade400,
                onPressed: () {
                  // Программный переход к следующей карточке (свайп влево)
                  _controller.forward(direction: SwipDirection.Left);
                },
                child: const Icon(Icons.thumb_down, color: Colors.white),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: "like",
                backgroundColor: Colors.green.shade400,
                onPressed: () {
                  // Программный переход к следующей карточке (свайп вправо)
                  _controller.forward(direction: SwipDirection.Right);
                },
                child: const Icon(Icons.thumb_up, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
