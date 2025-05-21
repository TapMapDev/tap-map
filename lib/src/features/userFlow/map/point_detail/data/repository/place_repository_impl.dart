import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_detail.dart';
import 'place_repository.dart';

class PlaceRepositoryImpl implements PlaceRepository {
  final http.Client _client;
  PlaceRepositoryImpl(this._client);

  @override
  Future<PlaceDetail> fetchPlaceDetail(String id) async {
    // TODO: заменить URL на реальный
    final uri = Uri.parse('https://api.example.com/places/$id');
    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    return PlaceDetail.fromJson(jsonDecode(resp.body));
  }
}
