// import 'dart:convert';

// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// bool isPointClosedNow(String? workingHours, DateTime date) {
//   if (workingHours == null || workingHours.isEmpty) return false;

//   Map<String, dynamic>? parsed;
//   try {
//     parsed = jsonDecode(workingHours);
//   } on FormatException catch (e) {
//     print('Ошибка парсинга: $e');
//     return false;
//   }

//   // Определяем текущий день недели (0-6 в JS, 1-7 в Dart)
//   int dayOfWeek = date.weekday;
//   String dayKey;
//   if (dayOfWeek == 7) {
//     dayKey = 'sunday';
//   } else {
//     dayKey = [
//       'monday',
//       'tuesday',
//       'wednesday',
//       'thursday',
//       'friday',
//       'saturday'
//     ][dayOfWeek - 1];
//   }

//   final schedule = parsed![dayKey];
//   if (schedule == null) return true;

//   if (schedule['is_closed'] == true) return true;
//   if (schedule['is_24'] == true) return false;

//   int nowMinutes = date.hour * 60 + date.minute;
//   List<String> openTimes = List<String>.from(schedule['open_times'] ?? []);
//   List<String> closeTimes = List<String>.from(schedule['close_times'] ?? []);

//   bool closed = true;

//   for (int i = 0; i < openTimes.length; i++) {
//     var open = openTimes[i].split(':');
//     var close = closeTimes[i].split(':');

//     int openMin = int.parse(open[0]) * 60 + int.parse(open[1]);
//     int closeMin = int.parse(close[0]) * 60 + int.parse(close[1]);

//     if (openMin < closeMin) {
//       if (nowMinutes >= openMin && nowMinutes < closeMin) {
//         closed = false;
//         break;
//       }
//     } else if (openMin > closeMin) {
//       if (nowMinutes >= openMin || nowMinutes < closeMin) {
//         closed = false;
//         break;
//       }
//     }
//   }

//   return closed;
// }

// Future<void> updateOpenCloseStates(MapboxMap? mapboxMapController) async {
//   try {
//     if (mapboxMapController == null) {
//       print("Mapbox controller is null");
//       return;
//     }

//     final now = DateTime.now();
//     print("Starting updateOpenCloseStates at $now");

//     // Получаем features с await
//     final List<QueriedSourceFeature?>? features = await mapboxMapController
//         .querySourceFeatures('places',
//             SourceQueryOptions(sourceLayerIds: ["mylayer"], filter: null))
//         .catchError((error) {
//       print("Error querying features: $error");
//       return null;
//     });

//     print("Features received: ${features?.length ?? 0} items");

//     if (features == null || features.isEmpty) {
//       print("No features found");
//       return;
//     }

//     for (var feature in features) {
//       try {
//         if (feature == null) continue;

//         final wh = feature.properties['working_hours'];
//         final isClosed = isPointClosedNow(wh, now);

//         if (feature.id != null) {
//           await mapboxMapController.setFeatureState(
//             'places',
//             'mylayer',
//             feature.id!,
//             jsonEncode({"closed": isClosed}),
//           );
//         }
//       } catch (e) {
//         print("Error processing feature: $e");
//       }
//     }
//   } catch (e) {
//     print("Global error in updateOpenCloseStates: $e");
//   }
// }