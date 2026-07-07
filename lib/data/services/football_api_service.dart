import 'package:dio/dio.dart';
import '../models/standing_model.dart';
import '../../core/constants/app_constants.dart';

/// Custom exception for Football API errors.
class FootballApiException implements Exception {
  final String message;
  final int? statusCode;

  const FootballApiException({required this.message, this.statusCode});

  @override
  String toString() => 'FootballApiException($statusCode): $message';
}

/// Singleton service for all network calls to football-data.org v4.
///
/// ## Smart Retry Strategy
///
/// Football seasons run August → May. During off-season (June–July), calling
/// the API without a season filter either returns an empty standings table or
/// a 4xx error for the upcoming season. This service handles it with a
/// **multi-season retry loop**:
///
/// 1. Try with NO season filter (API picks the "current" season).
/// 2. If that fails OR returns empty, try `?season=Y-1` (most recently completed).
/// 3. If that fails, try `?season=Y-2` as a final fallback.
/// 4. If all attempts fail, throw the last [FootballApiException].
class FootballApiService {
  late final Dio _dio;

  FootballApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeoutMs),
        headers: {
          'X-Auth-Token': AppConstants.apiKey,
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // ignore: avoid_print
          print('[API] → ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          // ignore: avoid_print
          print('[API] ← ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
        onError: (DioException err, handler) {
          // ignore: avoid_print
          print('[API] ✗ ${err.response?.statusCode} ${err.type} — ${err.message}');
          handler.next(err);
        },
      ),
    );
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Fetches standings for [leagueCode] with automatic season fallback.
  ///
  /// Tries progressively older seasons until valid data is found.
  /// Throws [FootballApiException] only when **all attempts** fail.
  Future<StandingsResponse> getStandings(String leagueCode) async {
    final now = DateTime.now();

    // Candidate season-start years to try (ordered newest → oldest).
    // We only include the current year if August has passed (new season started).
    final candidateSeasons = <int>[
      if (now.month >= 8) now.year,  // e.g. Sep 2026 → season 2026/27
      now.year - 1,                   // e.g. Jul 2026 → season 2025/26 ✓
      now.year - 2,                   // final safety net
    ];

    FootballApiException? lastError;

    // ── Step 1: try without season filter first ───────────────────────────
    try {
      final result = await _fetchAndParse(leagueCode);
      if (result.standings.isNotEmpty) {
        // ignore: avoid_print
        print('[API] ✅ Got ${result.standings.length} teams (default season)');
        return result;
      }
      // ignore: avoid_print
      print('[API] ⚠ Default season returned empty standings — starting fallback loop');
    } on FootballApiException catch (e) {
      lastError = e;
      // ignore: avoid_print
      print('[API] ⚠ Default season error (${e.statusCode}) — starting fallback loop');
    }

    // ── Step 2: iterate through candidate seasons ─────────────────────────
    for (final year in candidateSeasons) {
      try {
        // ignore: avoid_print
        print('[API] 🔄 Trying ?season=$year for $leagueCode');
        final result = await _fetchAndParse(leagueCode, seasonYear: year);
        if (result.standings.isNotEmpty) {
          // ignore: avoid_print
          print('[API] ✅ Got ${result.standings.length} teams for season $year');
          return result;
        }
        // ignore: avoid_print
        print('[API] ⚠ season=$year also returned empty — trying next');
      } on FootballApiException catch (e) {
        lastError = e;
        // ignore: avoid_print
        print('[API] ✗ season=$year failed: ${e.statusCode} ${e.message}');
        // Continue loop — don't give up yet
      }
    }

    // ── Step 3: all attempts exhausted ────────────────────────────────────
    throw lastError ??
        const FootballApiException(
          message: 'No standings data available for this competition.',
        );
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  /// Performs a single GET request and parses the response.
  /// [seasonYear] — if provided, appends `?season=<year>` to the request.
  Future<StandingsResponse> _fetchAndParse(
    String leagueCode, {
    int? seasonYear,
  }) async {
    try {
      final response = await _dio.get(
        '/competitions/$leagueCode/standings',
        queryParameters: seasonYear != null ? {'season': seasonYear} : null,
      );

      if (response.data == null) {
        throw const FootballApiException(
          message: 'Empty response body received from server.',
        );
      }

      return StandingsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw FootballApiException(
        statusCode: e.response?.statusCode,
        message: _parseDioError(e),
      );
    } catch (e) {
      if (e is FootballApiException) rethrow;
      throw FootballApiException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  String _parseDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please try again.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 400) return 'Bad request. Invalid parameters.';
        if (code == 401) return 'Unauthorized. Check your API key.';
        if (code == 403) {
          return 'Access denied. This competition may not be in your plan.';
        }
        if (code == 404) return 'Competition not found.';
        if (code == 429) return 'Rate limit exceeded. Please wait a moment.';
        if (code != null && code >= 500) return 'Server error ($code). Try later.';
        return 'Request failed (status $code).';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return e.message ?? 'An unknown network error occurred.';
    }
  }
}
