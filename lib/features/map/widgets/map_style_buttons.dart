import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/features/map/styles/bloc/map_styles_bloc.dart';

class MapStyleButton extends StatelessWidget {
  const MapStyleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showStyleSelectionDialog(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.map,
          color: Colors.grey,
          size: 20,
        ),
      ),
    );  
  }

  void _showStyleSelectionDialog(BuildContext context) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => const MapStyleDialog(),
      );
    }
  }
}

class StyleImages {
  static final List<String> paths = [
    'assets/jpeg/cyberpunk.jpeg',
    'assets/jpeg/standart.jpeg',
    'assets/jpeg/sputnik.jpeg',
    'assets/jpeg/GTA5.jpeg',
    'assets/jpeg/fallout.jpeg',
    'assets/jpeg/rd2.jpeg',
  ];

  static Future<void> preloadImages(BuildContext context) async {
    for (final path in paths) {
      precacheImage(AssetImage(path), context);
    }
  }
}

class MapStyleDialog extends StatefulWidget {
  const MapStyleDialog({super.key});

  @override
  State<MapStyleDialog> createState() => _MapStyleDialogState();
}

class _MapStyleDialogState extends State<MapStyleDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _imagesPreloaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

    @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preloadImages();   
  }


  Future<void> _preloadImages() async {
    if (!_imagesPreloaded) {
      await StyleImages.preloadImages(context);
      if (mounted) {
        setState(() {
          _imagesPreloaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        insetPadding: const EdgeInsets.only(
          top: 40,
          left: 10,
          right: 10,
          bottom: 200,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.topCenter,
        child: BlocBuilder<MapStyleBloc, MapStyleState>(
          buildWhen: (previous, current) =>
              current is MapStyleLoading ||
              current is MapStyleSuccess ||
              current is MapStyleError,
          builder: (context, state) {
            if (state is MapStyleLoading) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (state is MapStyleSuccess) {
              return _buildStyleGrid(context, state);
            } else if (state is MapStyleError) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('Ошибка загрузки стилей')),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildStyleGrid(BuildContext context, MapStyleSuccess state) {
    final mapStyleBloc = context.read<MapStyleBloc>();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Стиль карты',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              itemCount: state.mapStyles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, index) {
                final style = state.mapStyles[index];
                final imagePath = index < StyleImages.paths.length
                    ? StyleImages.paths[index]
                    : StyleImages.paths[0];

                return GestureDetector(
                  onTap: () {
                    _selectMapStyle(
                        context, mapStyleBloc, style.id!, style.styleUrl!);
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            cacheWidth: 200,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        style.name ?? '',
                        style: const TextStyle(fontSize: 14),
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectMapStyle(BuildContext context, MapStyleBloc mapStyleBloc,
      int styleId, String styleUrl) {
    mapStyleBloc.add(UpdateMapStyleEvent(
      newStyleId: styleId,
      uriStyle: styleUrl,
    ));

    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
