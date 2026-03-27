# Changelog

## 2.0.0 — 2026-03-27

Major expansion: from meal tracker to full health & wellness app.

### Sprint 1: Backend
- Body metrics model + storage + API
- Workouts model + storage + API (with Strava fields)
- Screen time model + storage + API (with per-app breakdown)
- Daily check-ins model + storage + API (mood, energy, focus, stress, sleep)
- Hydration tracking model + storage + API
- Updated `/stats` endpoint with new data
- Strava OAuth + sync infrastructure
- Build, test, deploy

### Sprint 2: Data Layer
- Dart models for all new entities (with sync support)
- SQLite tables (DB v7) with migrations
- Local repositories with CRUD + watch + sync queries
- Remote repositories (cache-first, pending sync)
- Syncing repositories (local-first, sync queue)
- RepositoryFactory updated with all new repos

### Sprint 3: UI
- Check-in screen (mood, energy, focus, stress, sleep quality sliders)
- Workouts screen (grouped list, add bottom sheet, swipe-to-delete)
- Body Metrics screen (weight tracking, add measurement)
- Screen Time screen (daily view, per-app breakdown)
- Settings screen (Strava connection, screen time toggle, sync status)
- Hydration widget (water glasses, quick add, recent entries)
- Enhanced Today screen with new metric sections
- 5-tab navigation (Today, Meals, Workouts, Calendar, Settings)
- Full EN + FR localization
- Strava auth service placeholder

### Sprint 3.5: Tests
- Model tests for all new entities (248 tests passing)
- Repository integration tests for all new local repos
- Mock repositories for all new models
- RepositoryFactory test coverage for all repos

### Known Issues
- Screen time requires Android native implementation (PER-41 to PER-44)
- Strava auth is placeholder (needs OAuth credentials)
- Sync status in Settings is hardcoded

---

## 1.3.1 — Previous
- Meal tracking with sync
- Day ratings
- Daily metrics (water, exercise)
- Calendar view
- Photo capture + gallery
