import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/styles/bloc/map_styles_bloc.dart';

class MapStyleButtons extends StatelessWidget {
  const MapStyleButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final mapStyleBloc = BlocProvider.of<MapStyleBloc>(context);

    return BlocBuilder<MapStyleBloc, MapStyleState>(
      buildWhen: (previous, current) => current
          is! MapStyleUpdateSuccess, // Чтобы не пересоздавать кнопки при смене стиля
      builder: (context, state) {
        if (state is MapStyleLoading) {
          return const CircularProgressIndicator();
        } else if (state is MapStyleSuccess) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Чтобы не занимало весь экран
              children: state.mapStyles.map((style) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton(
                    onPressed: () {
                      mapStyleBloc.add(UpdateMapStyleEvent(
                        newStyleId: style.id!,
                        uriStyle: style.styleUrl!,
                      ));
                    },
                    child: Text(style.name!),
                  ),
                );
              }).toList(),
            ),
          );
        } else if (state is MapStyleError) {
          return const Text("Failed to load styles");
        }
        return const SizedBox.shrink();
      },
    );
  }
}