P0/PX Report - Performance + Edge Cases

P0 - Critical Risks

| ID | Issue | Impact | Evidence (files) | Suggested Mitigation |
|---|---|---|---|---|
| P0-1 | DB change stream can be permanently closed | After close(), watchTodayMeals() will not emit and UI can stop updating | lib/data/services/database_service.dart | Implemented: table-scoped streams, controller reinit on access, close streams only when requested |
| P0-2 | Async flush in dispose() not awaited | Pending saves can be dropped on app exit or provider disposal | lib/presentation/providers/today_provider.dart, lib/presentation/providers/day_detail_provider.dart | Implemented: flushAndDispose() async path, screens trigger async flush before dispose, notify guarded after dispose |
| P0-3 | Image replacement deletes old file before DB save | Failed save can lose both old and new image | lib/presentation/providers/today_provider.dart, lib/presentation/providers/day_detail_provider.dart | Implemented: delete old image only after DB write succeeds |

PX - Important Improvements

| ID | Issue | Impact | Evidence (files) | Suggested Mitigation |
|---|---|---|---|---|
| PX-1 | Global DB change notifications trigger all listeners | Unnecessary re-queries; scales poorly as features grow | lib/data/repositories/meal_repository.dart, lib/data/services/database_service.dart | Implemented: table-scoped notifications and watchTable() |
| PX-2 | Metrics range fetch refetches cached dates on pagination | Wasted IO and extra map merges | lib/presentation/providers/meals_provider.dart | Implemented: track fetched dates and request only missing ranges |
| PX-3 | Image decode can spike memory | Risk of jank or OOM with large photos | lib/data/services/image_storage_service.dart | Implemented: preflight size check + decode via decoder with resize target |
| PX-4 | In-memory feed sort conflicts with paging order | Visual reordering or duplication across pages | lib/data/repositories/meal_repository.dart, lib/presentation/screens/meals_screen.dart | Implemented: preserve repository order in feed |
| PX-5 | Error handling gaps in IO paths | Exceptions can bubble and crash widgets | lib/presentation/providers/today_provider.dart, lib/presentation/providers/day_detail_provider.dart | Implemented: try/catch on delete/save paths with provider error |

Appendix - Coverage Gaps (Tests)

| Gap | Risk | Suggested Test |
|---|---|---|
| Image replacement failure | Lost images if DB write fails | Simulate save failure; ensure old image retained |
| Day rollover or time drift | Meals saved to wrong day | Unit test around midnight with DateTime control |
| Provider dispose saves | Lost description/metrics on exit | Test flushing pending saves before dispose |
