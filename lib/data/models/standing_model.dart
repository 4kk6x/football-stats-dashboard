import 'team_model.dart';

/// Represents a single row in the league standings table.
class Standing {
  final int position;
  final Team team;
  final int playedGames;
  final int won;
  final int draw;
  final int lost;
  final int points;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final String form; // e.g., "W,W,D,L,W"

  const Standing({
    required this.position,
    required this.team,
    required this.playedGames,
    required this.won,
    required this.draw,
    required this.lost,
    required this.points,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.form,
  });

  factory Standing.fromJson(Map<String, dynamic> json) {
    return Standing(
      position: json['position'] as int? ?? 0,
      team: Team.fromJson(json['team'] as Map<String, dynamic>? ?? {}),
      playedGames: json['playedGames'] as int? ?? 0,
      won: json['won'] as int? ?? 0,
      draw: json['draw'] as int? ?? 0,
      lost: json['lost'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      goalsFor: json['goalsFor'] as int? ?? 0,
      goalsAgainst: json['goalsAgainst'] as int? ?? 0,
      goalDifference: json['goalDifference'] as int? ?? 0,
      form: json['form'] as String? ?? '',
    );
  }

  @override
  String toString() => 'Standing(pos: $position, team: ${team.name}, pts: $points)';
}

/// Top-level wrapper that holds the competition metadata + the standings table.
class StandingsResponse {
  final String competitionName;
  final String competitionEmblem;
  final int currentMatchday;
  final int totalMatchdays;
  final String seasonLabel; // e.g. "2024/25"
  final List<Standing> standings;

  const StandingsResponse({
    required this.competitionName,
    required this.competitionEmblem,
    required this.currentMatchday,
    required this.totalMatchdays,
    required this.seasonLabel,
    required this.standings,
  });

  factory StandingsResponse.fromJson(Map<String, dynamic> json) {
    // The API returns standings as a list of tables (TOTAL, HOME, AWAY).
    // We only want the "TOTAL" table.
    final tables = json['standings'] as List<dynamic>? ?? [];
    final totalTable = tables.firstWhere(
      (t) => (t['type'] as String?) == 'TOTAL',
      orElse: () => tables.isNotEmpty ? tables.first : {'table': []},
    );

    final rawTable = totalTable['table'] as List<dynamic>? ?? [];
    final standingsList = rawTable
        .map((e) => Standing.fromJson(e as Map<String, dynamic>))
        .toList();

    final competition = json['competition'] as Map<String, dynamic>? ?? {};
    final season = json['season'] as Map<String, dynamic>? ?? {};

    // Build season label dynamically from API dates (e.g. "2024/25")
    final startDate = season['startDate'] as String? ?? '';
    final endDate = season['endDate'] as String? ?? '';
    String seasonLabel = '';
    if (startDate.length >= 4 && endDate.length >= 4) {
      final startYear = startDate.substring(0, 4);
      final endYearShort = endDate.substring(2, 4);
      seasonLabel = '$startYear/$endYearShort';
    }

    return StandingsResponse(
      competitionName: competition['name'] as String? ?? 'Unknown League',
      competitionEmblem: competition['emblem'] as String? ?? '',
      currentMatchday: season['currentMatchday'] as int? ?? 0,
      totalMatchdays: 38,
      seasonLabel: seasonLabel,
      standings: standingsList,
    );
  }
}
