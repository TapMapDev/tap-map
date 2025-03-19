import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/src/features/userFlow/search_screen/bloc/search_bloc.dart';
import 'package:tap_map/src/features/userFlow/search_screen/search_repository.dart';
import 'package:tap_map/src/features/userFlow/search_screen/widgets/search_silver.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SearchBloc(getIt<SearchRepository>())..add(InitializeSearchEvent()),
      child: const _SearchPageContent(),
    );
  }
}

class _SearchPageContent extends StatefulWidget {
  const _SearchPageContent({super.key});

  @override
  State<_SearchPageContent> createState() => _SearchPageContentState();
}

class _SearchPageContentState extends State<_SearchPageContent>
    with AutomaticKeepAliveClientMixin {
  // Флаг для переключения режимов:
  // false -> показываем режим свайпа (SwipeModePage)
  // true  -> показываем детальный режим (DetailModePage)
  bool _showDetails = false;

  // Какая карточка сейчас «открыта»
  var _selectedPlace;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Необходимо для AutomaticKeepAliveClientMixin

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
        // Если _showDetails = true, показываем кнопку «Назад»,
        // чтобы вернуться к свайпам.
        leading: _showDetails
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showDetails = false;
                  });
                },
              )
            : null,
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
          if (state is SearchLoading && !state.hasCachedData) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SearchLoaded ||
              (state is SearchLoading && state.hasCachedData)) {
            final places = state is SearchLoaded
                ? state.places
                : (state as SearchLoading).cachedPlaces!;

            if (places.isEmpty) {
              return const Center(child: Text('Ничего не найдено'));
            }

            // Если _showDetails == false -> показываем режим свайпа
            if (!_showDetails) {
              return SwipeModePage(
                places: places,
                onPlaceSelected: (place) {
                  setState(() {
                    _selectedPlace = place;
                    _showDetails = true;
                  });
                },
              );
            } else {
              // Если _showDetails == true -> показываем детальный режим
              return DetailModePage(place: _selectedPlace);
            }
          } else {
            return const Center(child: Text('Начните поиск'));
          }
        },
      ),
    );
  }
}
