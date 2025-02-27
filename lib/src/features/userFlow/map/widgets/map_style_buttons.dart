import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/features/userFlow/map/styles/bloc/map_styles_bloc.dart';

class MapStyleButtons extends StatelessWidget {
  const MapStyleButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final mapStyleBloc = context.read<MapStyleBloc>();

    return BlocBuilder<MapStyleBloc, MapStyleState>(
      buildWhen: (previous, current) => current is! MapStyleUpdateSuccess,
      builder: (context, state) {
        if (state is MapStyleLoading) {
          return const CircularProgressIndicator();
        } else if (state is MapStyleSuccess) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: state.mapStyles.map((style) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      /// Сохраняем ссылку на стиль
                      await getIt
                          .get<SharedPrefsRepository>()
                          .saveMapStyle(style.styleUrl!);

                      /// Сохраняем ID стиля
                      await getIt
                          .get<SharedPrefsRepository>()
                          .saveMapStyleId(style.id!);

                      /// Запускаем ивент обновления стиля в BLoC
                      mapStyleBloc.add(
                        UpdateMapStyleEvent(
                          newStyleId: style.id!,
                          uriStyle: style.styleUrl!,
                        ),
                      );
                    },
                    child: Text(style.name!),
                  ),
                );
              }).toList(),
            ),
          );
        } else if (state is MapStyleError) {
          return const Text("Ошибка загрузки стилей");
        }
        return const SizedBox.shrink();
      },
    );
  }
}
