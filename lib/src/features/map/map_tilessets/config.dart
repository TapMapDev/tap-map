import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapConfig {
  MapConfig._();

  static const defaultMapStyle = 'mapbox://styles/mapbox/streets-v12';

  static String get accessToken => dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  // static const mapboxVectorSourceUrl = 'mapbox://map23travel.second';
  // static const mapboxVectorSourceId = 'map23travel.second';
  // static const mapboxVectorSourceLayerId = 'second';
}
