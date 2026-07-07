/// Represents a single football team.
class Team {
  final int id;
  final String name;
  final String shortName;
  final String tla;      // Three-letter abbreviation (e.g., "MCI")
  final String crestUrl; // URL for the team's logo/crest PNG

  const Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.tla,
    required this.crestUrl,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      shortName: json['shortName'] as String? ?? json['name'] as String? ?? 'Unknown',
      tla: json['tla'] as String? ?? '???',
      crestUrl: json['crest'] as String? ?? '',
    );
  }

  @override
  String toString() => 'Team(id: $id, name: $name)';
}
