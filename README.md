# ⚽ Football Stats Dashboard

A **professional portfolio MVP** built with Flutter — a sleek, dark-mode sports dashboard that displays live football league standings powered by the [football-data.org](https://www.football-data.org/) API.

---

## 📱 Screenshots

> _Live standings, stats cards, and league selector — all in a premium dark UI._

---

## ✨ Features

- 🏆 **Multi-league support** — Premier League, La Liga, Bundesliga, Serie A, Ligue 1
- 📊 **Season stats dashboard** — League leader, total goals, matchday, avg goals/match
- 📋 **Full standings table** — Rank, crest, name, P / W / D / L / Pts with zone color-coding
- 🎨 **Zone indicators** — Champions League 🔵, Europa League 🟠, Conference League 🟢, Relegation 🔴
- ✨ **Shimmer skeleton** loading — premium feel while data fetches
- 🔄 **Pull-to-refresh** — always up to date
- 🤖 **Smart season fallback** — auto-detects off-season and fetches last completed season
- ❌ **Graceful error states** — friendly messages with retry button

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | GetX |
| Networking | Dio |
| Image Caching | cached_network_image |
| Loading UX | Shimmer |
| Typography | Google Fonts (Rajdhani + Inter) |
| API | football-data.org v4 |

---

## 🏗️ Project Architecture

```
lib/
├── core/
│   ├── constants/       # App config, API base URL, secrets (gitignored)
│   └── theme/           # Dark theme, color palette, gradients
├── data/
│   ├── models/          # Standing, Team, StandingsResponse
│   └── services/        # FootballApiService (Dio + smart retry)
├── modules/
│   └── dashboard/       # Controller, Binding, Screen (feature module)
└── routes/              # AppPages, AppRoutes
```

**Architecture pattern:** Feature-module with GetX MVC — each feature owns its screen, controller, and binding.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.8.1`
- A free API key from [football-data.org](https://www.football-data.org/client/register)

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/football.git
cd football

# 2. Create your secrets file
cp lib/core/constants/secrets.example.dart lib/core/constants/secrets.dart

# 3. Add your API key to secrets.dart
#    Open the file and replace 'YOUR_API_KEY_HERE' with your real key

# 4. Install dependencies
flutter pub get

# 5. Run the app
flutter run
```

> ⚠️ **Note:** `secrets.dart` is git-ignored and must be created locally. Never commit your API key.

---

## 📦 Supported Leagues

| Flag | League | Code |
|---|---|---|
| 🏴󠁧󠁢󠁥󠁮󠁧󠁿 | Premier League | `PL` |
| 🇪🇸 | La Liga | `PD` |
| 🇩🇪 | Bundesliga | `BL1` |
| 🇮🇹 | Serie A | `SA` |
| 🇫🇷 | Ligue 1 | `FL1` |

---

## 📄 License

MIT License — feel free to use this for your own portfolio.

---

<p align="center">Built with ❤️ using Flutter & GetX</p>
