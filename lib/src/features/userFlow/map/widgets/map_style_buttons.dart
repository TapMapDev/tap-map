import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/features/userFlow/map/styles/bloc/map_styles_bloc.dart';

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
    Future.delayed(const Duration(milliseconds: 300), () {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => const MapStyleDialog(),
        );
      }
    });
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapStyleBloc = context.read<MapStyleBloc>();

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
          buildWhen: (previous, current) => current is! MapStyleUpdateSuccess,
          builder: (context, state) {
            if (state is MapStyleLoading) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (state is MapStyleSuccess) {
              return Container(
                padding: const EdgeInsets.all(16),
                // height: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Стиль карты",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: GridView.builder(
                        itemCount: state.mapStyles.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (context, index) {
                          final style = state.mapStyles[index];
                          return GestureDetector(
                            onTap: () async {
                              /// Сохраняем ссылку на стиль
                              await getIt
                                  .get<SharedPrefsRepository>()
                                  .saveMapStyle(style.styleUrl!);

                              /// Сохраняем ID стиля
                              await getIt
                                  .get<SharedPrefsRepository>()
                                  .saveMapStyleId(style.id!);
                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                mapStyleBloc.add(ResetMapStyleEvent());
                              });

                              /// Запускаем ивент обновления стиля в BLoC
                              mapStyleBloc.add(UpdateMapStyleEvent(
                                newStyleId: style.id!,
                                uriStyle: style.styleUrl!,
                              ));

                              /// Закрываем окно
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      'assets/map_styles/${style.id}.jpg',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(style.name!,
                                    style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is MapStyleError) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text("Ошибка загрузки стилей")),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
