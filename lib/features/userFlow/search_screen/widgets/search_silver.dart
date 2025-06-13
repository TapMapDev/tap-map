import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/features/userFlow/search_screen/bloc/search_bloc.dart';
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
  bool _showDetails = false;
  bool _isSwiping = false;

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
      body: SizedBox.expand(
        child: _showDetails
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _showDetails = false;
                  });
                },
                child: DetailModePage(
                  place: widget.places[_currentIndex],
                  onImageTap: () => setState(() {
                    _showDetails = false;
                  }),
                ),
              )
            : TCard(
                cards: _buildCards(),
                controller: _controller,
                onForward: (index, info) {
                  if (index < widget.places.length) {
                    final currentPlace = widget.places[index];
                    _currentIndex = index;

                    setState(() {
                      _isSwiping = true;
                    });

                    // Сбрасываем флаг свайпа после анимации
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        setState(() {
                          _isSwiping = false;
                        });
                      }
                    });

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
        padding: const EdgeInsets.only(
          left: 30,
          right: 30,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
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
                backgroundColor: Colors.grey,
                onPressed: () {
                  _controller.back();
                },
                child: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
            ),
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
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.grey.shade400,
                onPressed: () {
                  _controller.forward(direction: SwipDirection.Right);
                },
                child: const Icon(Icons.share, color: Colors.white),
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[200],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Карусель изображений
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showDetails = true;
                  });
                },
                child: ImageCarousel(
                  images: place.images,
                  isCardSwiping: _isSwiping,
                ),
              ),

              // Кнопка-иконка поверх изображения (например, для деталей)
              Positioned(
                // top: 16,
                right: 16,
                bottom: 16,
                child: GestureDetector(
                  onTap: () {
                    widget.onPlaceSelected(place);
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),
              ),

              // Подложка с названием и описанием
              Positioned(
                left: 16,
                bottom: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${place.distance}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${place.timeInfo}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${place.openStatus}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                top: 35,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    '${place.category}',
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return cards;
  }
}

// Виджет карусели изображений
class ImageCarousel extends StatefulWidget {
  final List images;
  final int maxImages;
  final bool isCardSwiping;

  const ImageCarousel({
    super.key,
    required this.images,
    this.maxImages = 6,
    required this.isCardSwiping,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List get _limitedImages {
    return widget.images.take(widget.maxImages).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void nextPage() {
    if (_currentPage < widget.images.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Image.network(
        'https://picsum.photos/500/800',
        fit: BoxFit.cover,
      );
    }

    if (_limitedImages.length == 1) {
      // Если только одно изображение, показываем его напрямую
      return Image.network(
        _limitedImages[0].image,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            'https://picsum.photos/500/800',
            fit: BoxFit.cover,
          );
        },
      );
    }

    return IgnorePointer(
      ignoring: widget.isCardSwiping,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: widget.isCardSwiping
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: _limitedImages.length,
            onPageChanged: (index) {
              if (!widget.isCardSwiping) {
                setState(() {
                  _currentPage = index;
                });
              }
            },
            itemBuilder: (context, index) {
              return Image.network(
                _limitedImages[index].image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    'https://picsum.photos/500/800',
                    fit: BoxFit.cover,
                  );
                },
              );
            },
          ),

          // Индикатор количества фотографий
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentPage + 1}/${_limitedImages.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Кнопка влево
          if (_currentPage > 0)
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: previousPage,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),

          // Кнопка вправо
          if (_currentPage < _limitedImages.length - 1)
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: nextPage,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),

          // Полоски-индикаторы как в Tinder
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              children: List.generate(_limitedImages.length, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Виджет для "режима детального просмотра"
class DetailModePage extends StatelessWidget {
  final dynamic place;
  final VoidCallback onImageTap;

  const DetailModePage({
    super.key,
    required this.place,
    required this.onImageTap,
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
            background: GestureDetector(
              onTap: onImageTap,
              child: place.images.isNotEmpty
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
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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
