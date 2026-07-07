import 'package:get/get.dart';
import '../../data/models/standing_model.dart';
import '../../data/services/football_api_service.dart';
import '../../core/constants/app_constants.dart';

/// GetX Controller managing all state for the Football Dashboard.
///
/// Responsibilities:
/// - Fetching standings via [FootballApiService]
/// - Exposing reactive state (loading, error, data)
/// - Computing derived stats for the summary cards
class FootballController extends GetxController {
  // ── Dependencies ───────────────────────────────────────────────────────────
  final FootballApiService _apiService = FootballApiService();

  // ── Observable State ───────────────────────────────────────────────────────

  /// Full sorted standings list (TOTAL table).
  final RxList<Standing> standings = <Standing>[].obs;

  /// Whether data is currently being fetched.
  final RxBool isLoading = true.obs;

  /// Non-null when the last fetch resulted in an error.
  final RxnString errorMessage = RxnString(null);

  /// Competition metadata surfaced to the UI.
  final Rx<StandingsResponse?> response = Rx<StandingsResponse?>(null);

  /// Currently selected league code (reactive — swappable later).
  final RxString selectedLeague = AppConstants.premierLeagueCode.obs;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    fetchStandings();
  }

  // ── Public Methods ─────────────────────────────────────────────────────────

  /// Fetches standings for [selectedLeague].
  /// Can be called again on pull-to-refresh.
  Future<void> fetchStandings() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.getStandings(selectedLeague.value);
      response.value = result;
      standings.assignAll(result.standings);
    } on FootballApiException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Something went wrong. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  /// Changes the active league and re-fetches data.
  Future<void> changeLeague(String leagueCode) async {
    if (selectedLeague.value == leagueCode) return;
    selectedLeague.value = leagueCode;
    standings.clear();
    response.value = null;
    await fetchStandings();
  }

  // ── Derived / Computed Getters ─────────────────────────────────────────────

  /// Top 4 teams (Champions League spots).
  List<Standing> get topFour =>
      standings.length >= 4 ? standings.sublist(0, 4) : standings.toList();

  /// The league leader (position 1).
  Standing? get leagueLeader =>
      standings.isNotEmpty ? standings.first : null;

  /// Total number of matches played across the entire league.
  int get totalMatchesPlayed {
    if (standings.isEmpty) return 0;
    // Each match is counted by two teams, so divide by 2.
    return standings.fold<int>(0, (sum, s) => sum + s.playedGames) ~/ 2;
  }

  /// Total goals scored across all matches.
  int get totalGoalsScored {
    return standings.fold<int>(0, (sum, s) => sum + s.goalsFor);
  }

  /// Average goals per match (rounded to 1 decimal).
  double get avgGoalsPerMatch {
    final matches = totalMatchesPlayed;
    if (matches == 0) return 0.0;
    return totalGoalsScored / matches;
  }

  /// Current matchday from the API response.
  int get currentMatchday => response.value?.currentMatchday ?? 0;

  /// Competition name from the API response.
  String get competitionName =>
      response.value?.competitionName ?? 'League Standings';

  /// Competition emblem URL.
  String get competitionEmblem => response.value?.competitionEmblem ?? '';

  /// Season label derived from API dates (e.g. "2024/25").
  String get seasonLabel => response.value?.seasonLabel ?? '';

  /// Whether there is data to display.
  bool get hasData => standings.isNotEmpty;

  /// Whether currently in an error state.
  bool get hasError => errorMessage.value != null;

  // ── Private Helpers ────────────────────────────────────────────────────────

  void _setLoading(bool value) => isLoading.value = value;

  void _setError(String message) => errorMessage.value = message;

  void _clearError() => errorMessage.value = null;
}
