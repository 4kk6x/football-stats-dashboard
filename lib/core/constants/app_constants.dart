import 'secrets.dart';

/// Central configuration constants for the Football Stats Dashboard.
/// API key is loaded from [Secrets] — see secrets.example.dart for setup.
abstract class AppConstants {
  // ── API ──────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://api.football-data.org/v4';
  static const String apiKey = Secrets.footballApiKey;

  // ── League Codes ─────────────────────────────────────────────────────────
  static const String premierLeagueCode = 'PL';
  static const String laLigaCode = 'PD';
  static const String bundesligaCode = 'BL1';
  static const String serieACode = 'SA';
  static const String ligue1Code = 'FL1';

  // ── Network ──────────────────────────────────────────────────────────────
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;

  // ── Route Names ──────────────────────────────────────────────────────────
  static const String dashboardRoute = '/dashboard';
}
