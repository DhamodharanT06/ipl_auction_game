import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:ipl_auction_game/models/player_model.dart';

/// Fetches players from a published Google Sheet CSV export URL and
/// returns a list of `PlayerModel`.
///
/// Notes:
/// - Ensure the CSV is published/shared so the URL is accessible.
/// - Add these dependencies to `pubspec.yaml`:
///   http: ^0.13.0
///   csv: ^5.0.0
Future<List<PlayerModel>> fetchPlayersFromSheet(String csvUrl) async {
  final res = await http.get(Uri.parse(csvUrl));
  if (res.statusCode != 200) {
    throw Exception('Failed to fetch CSV (${res.statusCode})');
  }

  final converter = const CsvToListConverter(eol: '\n', shouldParseNumbers: false);
  final rows = converter.convert(res.body);
  if (rows.isEmpty) return [];

  final headers = rows.first.map((h) => h.toString().trim()).toList();
  final data = <PlayerModel>[];

  String _normalizeHeader(String h) => h.trim().toLowerCase().replaceAll(' ', '_');

  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.every((cell) => (cell == null || cell.toString().trim().isEmpty))) continue;

    final map = <String, dynamic>{};
    for (var j = 0; j < headers.length && j < row.length; j++) {
      final key = _normalizeHeader(headers[j].toString());
      final value = row[j];
      map[key] = value?.toString();
    }

    // Map normalized CSV keys to PlayerModel expected keys
    final playerMap = <String, dynamic>{
      'playerId': (map['player_id'] ?? map['playerid'] ?? map['id'])?.toString() ?? '',
      'name': (map['name'] ?? '')?.toString() ?? '',
      'role': (map['role'] ?? '')?.toString() ?? '',
      'avgScore': int.tryParse((map['avg_score'] ?? map['avgscore'] ?? '0').toString()) ?? 0,
      'isForeign': ((map['is_foreign'] ?? map['isforeign'] ?? 'false').toString().toLowerCase()) == 'true',
      'basePrice': int.tryParse((map['base_price'] ?? map['baseprice'] ?? '0').toString()) ?? 0,
      'imageUrl': (map['image_url'] ?? map['imageurl'])?.toString(),
      'country': (map['country'] ?? '')?.toString(),
    };

    data.add(PlayerModel.fromMap(playerMap));
  }

  return data;
}
