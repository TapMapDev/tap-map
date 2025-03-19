import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/search_screen/bloc/search_bloc.dart';
import 'package:tcard/tcard.dart';

// 1. Виджет для "режима свайпа"
class SwipeModePage extends StatefulWidget {
  final List places;
  final Function(dynamic place) onPlaceSelected;

  const SwipeModePage({
    super.key,
    required this.places,
    required this.onPlaceSelected,
  });

  @override
  State<SwipeModePage> createState() => _SwipeModePageState();
}

class _SwipeModePageState extends State<SwipeModePage>
    with AutomaticKeepAliveClientMixin {
  late TCardController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = TCardController();

    // Получаем сохраненный индекс из BLoC, если он есть
    final searchState = context.read<SearchBloc>().state;
    if (searchState is SearchLoaded) {
      _currentIndex = searchState.currentIndex;

      // Если есть сохраненный индекс, переключаемся на него
      if (_currentIndex > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controller.reset(cards: _buildCards());
          // Перемещаемся к сохраненному индексу
          for (int i = 0; i < _currentIndex; i++) {
            _controller.forward();
          }
        });
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Необходимо для AutomaticKeepAliveClientMixin

    return Scaffold(
      body: Center(
        child: TCard(
          cards: _buildCards(),
          size: const Size(400, 580),
          controller: _controller,
          onForward: (index, info) {
            if (index < widget.places.length) {
              final currentPlace = widget.places[index];
              _currentIndex = index;

              // Обновляем состояние в BLoC
              context.read<SearchBloc>().add(UpdateSwipeState(
                    currentIndex: index,
                    viewedPlaceId: currentPlace.id,
                  ));

              if (info.direction == SwipDirection.Right) {
                context.read<SearchBloc>().add(LikePlace(
                      placeId: currentPlace.id,
                      objectType: currentPlace.objectType ?? 'point',
                    ));
              } else if (info.direction == SwipDirection.Left) {
                context.read<SearchBloc>().add(SkipPlace(
                      placeId: currentPlace.id,
                      objectType: currentPlace.objectType ?? 'point',
                    ));
              }
            }
          },
          onEnd: () {
            if (context.read<SearchBloc>().state is SearchLoaded) {
              final st = context.read<SearchBloc>().state as SearchLoaded;
              context
                  .read<SearchBloc>()
                  .add(LoadMorePlaces(offset: st.offset + 1));
            } else {
              context.read<SearchBloc>().add(LoadMorePlaces(offset: 1));
            }
          },
        ),
      ),
      floatingActionButton: Padding(
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

  List<Widget> _buildCards() {
    final List<Widget> cards = [];

    for (final place in widget.places) {
      cards.add(
        GestureDetector(
          onTap: () {
            // По тапу показываем детальную инфу о месте
            widget.onPlaceSelected(place);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[200],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Картинка
                place.images.isNotEmpty
                    ? Image.network(
                        place.images.first.image,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        'https://picsum.photos/500/800',
                        fit: BoxFit.cover,
                      ),
                // Подложка с названием
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          place.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return cards;
  }
}

// 2. Виджет для "режима детального просмотра"
class DetailModePage extends StatelessWidget {
  final dynamic place;

  const DetailModePage({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    if (place == null) {
      return const Center(child: Text('Нет данных для детализации'));
    }

    return CustomScrollView(
      slivers: [
        // SliverAppBar - верхняя панель (можно сделать "сворачиваемой")
        SliverAppBar(
          expandedHeight: 200.0,
          pinned: true,
          // floating: true,  // зависит от нужного поведения
          flexibleSpace: FlexibleSpaceBar(
            title: Text(place.name),
            background: place.images.isNotEmpty
                ? Image.network(
                    place.images.first.image,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    'https://picsum.photos/500/800',
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        // SliverToBoxAdapter - оборачиваем в Sliver наш обычный виджет
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Описание',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  place.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Информация',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Категория: ${place.category}'),
                if (place.distance.isNotEmpty)
                  Text('Расстояние: ${place.distance}'),
                if (place.timeInfo.isNotEmpty) Text('Время: ${place.timeInfo}'),
                if (place.openStatus.isNotEmpty)
                  Text('Статус: ${place.openStatus}'),
              ],
            ),
          ),
        ),

        // Показываем дополнительную информацию через tinderInfo
        if (place.tinderInfo.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  Text(
                    'Дополнительная информация',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),

        // SliverList для tinderInfo
        if (place.tinderInfo.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = place.tinderInfo[index];
                return ListTile(
                  title: Text(item.label),
                  subtitle: Text(item.value),
                );
              },
              childCount: place.tinderInfo.length,
            ),
          ),

        // Показываем данные из underCardData
        if (place.underCardData.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  Text(
                    'Детали',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),

        // SliverList для underCardData
        if (place.underCardData.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = place.underCardData[index];
                return ListTile(
                  title: Text(item.label),
                  subtitle: Text(item.value),
                );
              },
              childCount: place.underCardData.length,
            ),
          ),

        // Галерея изображений (если есть больше одного)
        if (place.images.length > 1)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Фотографии',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: place.images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              place.images[index].image,
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Добавляем отступ в конце
        const SliverToBoxAdapter(
          child: SizedBox(height: 30),
        ),
      ],
    );
  }
}
