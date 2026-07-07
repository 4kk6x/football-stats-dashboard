/// 🔐 SECRETS — This file is git-ignored and must NEVER be committed.
///
/// Setup instructions for new contributors:
/// 1. Copy this file: `cp secrets.example.dart secrets.dart`
/// 2. Replace the placeholder below with your real API key from
///    https://www.football-data.org/client/register
///
/// ⚠️ Do NOT commit this file. It is listed in .gitignore.
abstract class Secrets {
  static const String footballApiKey = 'YOUR_API_KEY_HERE';
}
