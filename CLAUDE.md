# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

This is a Flutter app (Dart SDK ^3.11.5). Firebase project: `carenepal-cf3ec`.

- Install dependencies: `flutter pub get`
- Run the app: `flutter run`
- Static analysis (uses `flutter_lints`): `flutter analyze`
- Run all tests: `flutter test`
- Run a single test file: `flutter test test/widget_test.dart`
- Deploy Firestore rules: `firebase deploy --only firestore:rules`

## Architecture

**Care-Nepal** connects customers with verified care providers (booking + in-app chat).

### Data flow and entry point

`main.dart` initializes Firebase and `GoogleSignIn` once at startup, then hands off to
`AuthGate` (`lib/screens/auth/auth_gate.dart`), which is the single router for the whole app:

1. No Firebase user signed in → `AuthScreen`.
2. Signed in, no `role` saved in Firestore yet → `RoleSelectionScreen`.
3. Signed in with `role == customer` → `UserDashboard`.
4. Signed in with `role == provider` → `ProviderDashboard`.

The role, once set, is immutable (enforced both client-side in `UserRepository.setRole` via a
transaction, and server-side in `firestore.rules`). There is no in-app way to change roles.

### Repository pattern (partial)

Firestore/Storage access for **data** goes through repositories in `lib/repositories/`, not
directly from widgets:

- `UserRepository` — role assignment, provider verification/profile submission, ID document
  upload to Storage, and the stream of *verified* provider profiles used for discovery.
- `BookingRepository` — booking creation (uses a deterministic doc id
  `{providerId}_{epochMillis}` to prevent double-booking the same provider/slot) and
  accept/decline/cancel streams.
- `ChatRepository` — conversation lookup/creation and message sending, batched so a message
  write and the conversation preview/unread-count update happen atomically.

**Exception:** authentication itself (email/password, phone/OTP, Google Sign-In, password
reset) is called directly against `FirebaseAuth.instance` / `GoogleSignIn.instance` from
`lib/screens/auth/auth_screen.dart` — there is no `AuthRepository`, despite a stale comment in
`UserRepository` implying one exists. Don't assume one when editing auth flows.

`lib/blocs/` and `lib/features/` exist but are currently empty — there is no state-management
layer beyond `StreamBuilder`/`FutureBuilder` and `StatefulWidget` local state.

### Firestore schema

- `users/{uid}` — `role` ('customer'|'provider', set once), and for providers:
  `verificationStatus` ('pending'|'verified') + `providerProfile` map (see
  `ProviderProfile.toMap()`). `verificationStatus` can only move pending→verified out-of-band
  (admin console / Cloud Function) — never from the client.
- `bookings/{providerId}_{epochMillis}` — `status` is one of
  `pending|accepted|declined|cancelled` (see `BookingStatus`). Only the assigned provider can
  move `pending → accepted|declined` per current rules; customer-initiated `cancelBooking` is
  implemented client-side but the rules only grant status updates to the provider — check
  `firestore.rules` before relying on cancel actually succeeding.
- `conversations/{id}` (+ `messages` subcollection) — `participantIds`/`participantNames`/
  `participantRoles`/`unreadCount` keyed by uid; writes are restricted to an explicit allow-list
  of fields (see rules) rather than wholesale document replacement.

When changing what a repository writes, update `firestore.rules` to match — the rules encode
field-level invariants (e.g. immutable role, immutable participant list) that the client relies
on implicitly.

### UI structure

- `lib/core/theme/` — `AppTheme`/`AppColors`/`AppTextTheme` define the single `MaterialApp`
  theme (fonts: Fraunces for display, WorkSans for body — see `pubspec.yaml`).
- `lib/core/enum/` — Firestore-backed enums (`UserRole`, `ProviderVerificationStatus`) each
  pair a Dart enum with explicit `.value` / `fromValue` mapping to the Firestore string — follow
  this pattern (don't use `.name`/`EnumName.values.byName` directly) for anything persisted.
- `lib/screens/` — one subfolder per flow (`auth`, `role`, `dashboard`, `bookings`, `chat`,
  `profile`); `lib/widgets/` holds shared presentational widgets reused across those screens.

# Flutter Production Rules

Rules for building and maintaining a production-grade Flutter application.
Use this file as `CLAUDE.md`, `.cursorrules`, `AGENTS.md`, or a team engineering guideline.
Every rule is mandatory unless marked **(preferred)**.

---

## 0. Default Stack

| Concern | Choice |
|---|---|
| State management | `flutter_riverpod` + `riverpod_annotation` (code generation) |
| Navigation | `go_router` with typed routes (`go_router_builder`) |
| Models / unions | `freezed` + `json_serializable` |
| Networking | `dio` with interceptors |
| Local storage | `drift` (relational) / `shared_preferences` (flags only) / `flutter_secure_storage` (secrets) |
| Localization | `flutter_localizations` + `gen-l10n` (ARB files) |
| Testing | `flutter_test`, `mocktail`, `integration_test`, golden tests |
| Crash reporting | Firebase Crashlytics or Sentry |
| Lints | `very_good_analysis` or `flutter_lints` + strict mode |

Do not introduce a second state-management or networking library without an ADR (architecture decision record).

---

## 1. Project Structure — Feature-First, Layered

```
lib/
  main_development.dart
  main_staging.dart
  main_production.dart
  bootstrap.dart              # shared init: error handlers, DI overrides, runApp
  app/
    app.dart                  # MaterialApp.router
    router/                   # go_router config, typed routes, guards
    theme/                    # ThemeData, ThemeExtensions, tokens
  core/
    network/                  # dio client, interceptors, api exceptions
    error/                    # Failure types, error mapper
    storage/
    utils/                    # pure helpers only, no Flutter imports where possible
    widgets/                  # truly shared, design-system widgets
  features/
    auth/
      data/
        datasources/          # remote + local data sources
        dtos/                 # JSON models (freezed + json_serializable)
        repositories/         # repository implementations
      domain/
        entities/             # pure Dart, immutable
        repositories/         # abstract contracts
        usecases/             # (optional) only when logic spans repositories
      presentation/
        providers/            # Riverpod notifiers/controllers
        screens/
        widgets/
  l10n/
test/                         # mirrors lib/ exactly
integration_test/
```

Rules:
- A feature must never import another feature's `data/` or `presentation/` layer. Shared needs move to `core/` or are exposed via a domain contract.
- `domain/` contains **pure Dart**: no `package:flutter`, no `dio`, no JSON.
- DTOs never leak into the UI. Map DTO → Entity in the repository.
- One public widget per file. File names `snake_case.dart`, classes `PascalCase`.
- No barrel files that re-export entire layers (they hurt tree-shaking and cause cycles).

---

## 2. Dart Language Rules

- Sound null safety. Never use `!` unless the invariant is proven on the same line or documented. Prefer pattern matching / early returns.
- Prefer `final` everywhere; `var` only for genuinely mutated locals. No `dynamic` (enable `strict-raw-types`, `strict-inference`).
- Use **sealed classes** + exhaustive `switch` for states, failures, and results:

```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}
final class NetworkFailure extends Failure { const NetworkFailure(super.message); }
final class UnauthorizedFailure extends Failure { const UnauthorizedFailure() : super('Unauthorized'); }
final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

String describe(Failure f) => switch (f) {
  NetworkFailure() => 'Check your connection',
  UnauthorizedFailure() => 'Please sign in again',
  ServerFailure(:final statusCode) => 'Server error ($statusCode)',
};
```

- Use **records** for small multi-value returns instead of throwaway classes: `(int total, List<Item> items)`.
- Use **extension types** for strongly typed IDs: `extension type UserId(String value) {}` — never pass raw `String` IDs across layers.
- Immutable models only (`freezed` or `@immutable` + `copyWith`). Collections exposed as `List.unmodifiable` / freezed's immutable collections.
- `async` code: always `await` or explicitly `unawaited(...)`. Enable `unawaited_futures` and `discarded_futures` lints.
- Check `context.mounted` (or `ref.mounted` in notifiers) after every `await` before using `BuildContext` / state.

### analysis_options.yaml (baseline)

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_required_param: error
    missing_return: error
    unawaited_futures: error
    invalid_annotation_target: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "lib/l10n/generated/**"

linter:
  rules:
    public_member_api_docs: false
    discarded_futures: true
    avoid_print: true
    prefer_const_constructors: true
    use_build_context_synchronously: true
```

---

## 3. State Management (Riverpod)

- Use code generation (`@riverpod`) for all new providers. Default to `autoDispose` (the codegen default); use `@Riverpod(keepAlive: true)` only for app-lifetime services (auth session, dio client, database).
- **Widgets contain no business logic.** Widgets read state and call notifier methods; nothing else.
- `ref.watch` in `build`, `ref.read` in callbacks, `ref.listen` for side effects (snackbars, navigation). Never `ref.read` inside `build`.
- Narrow rebuilds with `select`:

```dart
final name = ref.watch(userProvider.select((u) => u.valueOrNull?.name));
```

- Async state is always `AsyncValue`; render all three cases. Never hand-roll `isLoading` booleans.

```dart
@riverpod
class OrdersController extends _$OrdersController {
  @override
  Future<List<Order>> build() => ref.watch(orderRepositoryProvider).fetchOrders();

  Future<void> refresh() async {
    state = const AsyncLoading<List<Order>>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(orderRepositoryProvider).fetchOrders(),
    );
  }
}

// UI
ref.watch(ordersControllerProvider).when(
  data: (orders) => OrdersList(orders: orders),
  loading: () => const OrdersSkeleton(),
  error: (e, st) => ErrorView(failure: e, onRetry: notifier.refresh),
);
```

- Keep previous data during refresh (`copyWithPrevious` / `skipLoadingOnRefresh`) — never flash a full-screen spinner on pull-to-refresh.
- Dependency injection goes through providers only. No service locators, no global singletons, no static mutable state.
- Cancel in-flight work on dispose: `ref.onDispose(cancelToken.cancel)`.
- Family providers take a single immutable, `==`-comparable parameter (record or freezed class).

---

## 4. Navigation (go_router)

- Single `GoRouter` instance exposed through a provider; it listens to auth state via `refreshListenable`.
- Use typed routes (`go_router_builder`) — no string paths scattered in widgets.
- Auth/onboarding guards live in the router's `redirect`, never in screens.
- Use `StatefulShellRoute.indexedStack` for bottom-navigation tabs so each tab keeps its stack.
- Every screen must be reachable by deep link with only its path parameters; never require objects passed via `extra` for correctness (`extra` is lost on deep links and web refresh).
- Configure Android App Links and iOS Universal Links; test them in CI with `adb`/`xcrun simctl openurl`.

---

## 5. Data Layer & Networking

- One configured `Dio` instance. Interceptors, in order: auth token → token refresh (with request queueing to avoid refresh stampedes) → retry with exponential backoff (idempotent methods only) → logging (debug builds only, redact headers/body secrets).
- Timeouts are explicit: connect, send, receive.
- Data sources throw; repositories **catch and convert** to a typed result. The UI never sees `DioException`.

```dart
sealed class Result<T> { const Result(); }
final class Ok<T> extends Result<T> { const Ok(this.value); final T value; }
final class Err<T> extends Result<T> { const Err(this.failure); final Failure failure; }
```

  (or return `Future<T>` and throw typed `Failure`s that `AsyncValue.guard` captures — pick one convention per project and apply it everywhere.)
- Parse large JSON payloads off the main isolate: `await Isolate.run(() => parseOrders(body))`.
- Pagination: cursor-based where the API allows; implement as a notifier holding pages + `hasMore`, triggered near the list end, with de-duplication of concurrent page loads.
- Offline-first features: local DB is the source of truth, UI watches DB streams, network sync writes into DB. Queue mutations while offline and replay with idempotency keys.
- Cache policy is explicit per endpoint (no-cache / stale-while-revalidate / TTL).

---

## 6. Error Handling & Observability

`bootstrap.dart` must install all three global handlers:

```dart
Future<void> bootstrap(Future<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashReporter.recordFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    crashReporter.recordError(error, stack, fatal: true);
    return true;
  };

  ErrorWidget.builder = (details) => const ProductionErrorWidget(); // no red screen in release

  runApp(ProviderScope(observers: [AppProviderObserver()], child: await builder()));
}
```

- No `print`. Use a logger with levels; strip verbose logs in release.
- Never swallow exceptions (`catch (_) {}` is forbidden). Either handle, map, or rethrow with context.
- Every user-facing error has a human message and a recovery action (retry, sign in, contact support).
- Attach non-PII context to crash reports: app version, flavor, route, user ID hash.
- Track key funnels and performance traces (app start, screen load, API latency).

---

## 7. Performance

Build & rebuild:
- `const` constructors everywhere possible.
- Split large `build` methods into **widget classes**, not helper methods returning widgets (helper methods defeat element reuse and `const`).
- Push state down: the widget that changes should be the smallest subtree possible.
- Pass `child` to `AnimatedBuilder` / `ValueListenableBuilder` / `Consumer` for static subtrees.

Lists & layout:
- Always `ListView.builder` / `SliverList.builder` for unbounded or long lists. Never `Column` + `map` for large data.
- Provide `itemExtent` or `prototypeItem` when item height is fixed.
- Use slivers (`CustomScrollView`) for mixed scrolling layouts instead of nested scroll views with `shrinkWrap: true`.
- Avoid `IntrinsicHeight` / `IntrinsicWidth` in lists.

Painting:
- Wrap frequently-repainting regions (animations, video, charts) in `RepaintBoundary`.
- Don't animate `Opacity`; use `FadeTransition` / `AnimatedOpacity`. Avoid unnecessary `saveLayer` (clips with anti-alias, `ShaderMask`, `BackdropFilter` over large areas).

Images:
- Decode at display size: `cacheWidth` / `cacheHeight` or `ResizeImage`.
- Network images via a caching package with placeholders and error builders; `precacheImage` for above-the-fold hero images.
- Prefer SVG/vector or WebP; never ship oversized PNGs.

Work off the UI thread:
- Anything > ~8 ms (JSON parsing, crypto, image processing, sorting large lists) runs in `Isolate.run` / `compute`.

Startup:
- Defer non-critical init (analytics, remote config fetch) until after first frame.
- Use deferred imports (`deferred as`) for rarely used, heavy features on web.

Measurement:
- Profile only in `--profile` mode on a real low-end device. Target 60/120 fps, no jank frames in DevTools timeline.
- Track app size with `flutter build apk --analyze-size`; budget it in CI.

---

## 8. UI, Theming & Design System

- Material 3 with `ColorScheme.fromSeed` or a hand-built scheme; light **and** dark themes required.
- Custom tokens (spacing, radii, brand colors, semantic colors like `success`) via `ThemeExtension`. No hard-coded colors, font sizes, or magic paddings in feature code.

```dart
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({this.xs = 4, this.sm = 8, this.md = 16, this.lg = 24, this.xl = 32});
  final double xs, sm, md, lg, xl;
  @override
  AppSpacing copyWith({double? xs, double? sm, double? md, double? lg, double? xl}) =>
      AppSpacing(xs: xs ?? this.xs, sm: sm ?? this.sm, md: md ?? this.md, lg: lg ?? this.lg, xl: xl ?? this.xl);
  @override
  AppSpacing lerp(AppSpacing? other, double t) => this;
}
extension ThemeX on BuildContext {
  AppSpacing get spacing => Theme.of(this).extension<AppSpacing>()!;
}
```

- Responsive: breakpoints defined once (compact < 600, medium < 840, expanded ≥ 840). Use `LayoutBuilder` / `MediaQuery.sizeOf(context)` (not `MediaQuery.of`, which rebuilds on every change).
- Respect safe areas, keyboard insets, and foldables.
- Shared widgets live in `core/widgets` and are documented with a Widgetbook **(preferred)**.

### Accessibility
- Every tappable target ≥ 48×48 dp.
- Icons-only buttons have `tooltip` / `Semantics(label:)`.
- Layout must survive text scale 2.0 without overflow — test it.
- Color contrast meets WCAG AA. Never convey state by color alone.
- Run `meetsGuideline(androidTapTargetGuideline)` etc. in widget tests.

---

## 9. Localization

- All user-visible strings come from ARB files via `gen-l10n`. No string literals in widgets.
- Use ICU plurals/selects; never concatenate translated fragments.
- Format dates, numbers, and currency with `intl` using the active locale.
- Support RTL: use `EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end`.

---

## 10. Security

- No secrets in source. Build-time config via `--dart-define-from-file=env/<flavor>.json` (files git-ignored). Remember anything shipped in the binary is extractable — real secrets stay on the server.
- Tokens stored only in `flutter_secure_storage`. Never in `shared_preferences` or logs.
- Release builds: `--obfuscate --split-debug-info=build/symbols/<version>`; upload symbols to the crash reporter.
- HTTPS only; certificate pinning for high-risk apps (finance, health).
- Validate and sanitize all deep-link parameters.
- Mask sensitive screens from screenshots/app switcher where required (`FLAG_SECURE` on Android, blur overlay on iOS).
- Keep dependencies updated; run `dart pub outdated` and a vulnerability scan in CI.

---

## 11. Environments & Flavors

- Three flavors minimum: `development`, `staging`, `production`, each with its own entry point, bundle ID / application ID, app name, icon, and Firebase project.
- Flavor-specific config is injected via a provider (`appConfigProvider`), overridden in `bootstrap`.
- Feature flags via remote config with safe local defaults; kill-switch for risky features.
- Force-update / minimum-version check on startup.

---

## 12. Testing

Coverage target: **≥ 80% for `domain/` and `data/`, ≥ 60% overall**, enforced in CI.

| Layer | Test type | Tools |
|---|---|---|
| Entities, use cases, mappers | Unit | `test` |
| Repositories | Unit with mocked data sources | `mocktail` |
| Notifiers/controllers | Unit with `ProviderContainer` + overrides | `riverpod` |
| Widgets/screens | Widget tests with provider overrides | `flutter_test` |
| Design-system components | Golden tests (light, dark, large text) | `alchemist` / built-in goldens |
| Critical flows (login, checkout) | Integration tests on device/emulator | `integration_test`, `patrol` **(preferred)** |

```dart
test('loads orders', () async {
  final repo = MockOrderRepository();
  when(() => repo.fetchOrders()).thenAnswer((_) async => [fakeOrder]);

  final container = ProviderContainer(
    overrides: [orderRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);

  await expectLater(container.read(ordersControllerProvider.future), completion([fakeOrder]));
});
```

- Every bug fix ships with a regression test.
- No real network or real time in tests: inject a `Clock` and HTTP adapters.
- Tests are deterministic — no `Future.delayed` for synchronization; use `pumpAndSettle` / `fakeAsync`.

---

## 13. Code Generation

- Generated files (`*.g.dart`, `*.freezed.dart`) are **not** committed **(preferred)**, or are committed and verified in CI — pick one and enforce it.
- Run: `dart run build_runner build --delete-conflicting-outputs`.
- Configure `build.yaml` to scope generators to relevant directories to keep builds fast.

---

## 14. CI/CD

Every pull request must pass, in order:
1. `dart format --set-exit-if-changed .`
2. `flutter analyze` (zero warnings, zero infos in new code)
3. `dart run build_runner build --delete-conflicting-outputs`
4. `flutter test --coverage` + coverage threshold check
5. Golden tests
6. Build all flavors (`apk`/`appbundle`, `ipa --no-codesign` on PR)

Release pipeline:
- Semantic versioning; build number auto-incremented by CI.
- Fastlane or Codemagic for signing and store upload; signing keys only in CI secrets.
- Staged rollouts (Play Console % rollout, App Store phased release) with crash-free-rate gates (≥ 99.5% users).
- Changelog generated from conventional commits.

---

## 15. Git & Review

- Conventional commits (`feat:`, `fix:`, `refactor:`, `test:`, `chore:`).
- Small PRs (< 400 lines of non-generated diff). Screenshots/video for UI changes.
- No commented-out code, no `TODO` without a ticket reference.

### Review checklist
- [ ] Layer boundaries respected (no DTO in UI, no Flutter in domain)
- [ ] All async states (loading / error / empty / data) handled
- [ ] `context.mounted` checked after awaits
- [ ] No hard-coded strings, colors, or sizes
- [ ] Rebuild scope minimal (`const`, `select`, extracted widgets)
- [ ] Lists are lazy; images sized
- [ ] Errors mapped to `Failure` and shown with a recovery action
- [ ] Accessibility: semantics, tap targets, text scaling
- [ ] Tests added/updated
- [ ] No secrets, no PII in logs

---

## 16. Hard "Never" List

- Never put business logic, API calls, or navigation decisions inside `build`.
- Never use `setState` in feature screens for business state (local ephemeral UI state such as an expansion toggle is fine).
- Never use `BuildContext` across an async gap without a `mounted` check.
- Never catch `Exception` and ignore it.
- Never block the UI isolate with heavy synchronous work.
- Never use `shrinkWrap: true` on long lists or nest scrollables of the same axis without slivers.
- Never ship debug logging, test endpoints, or `debugPrint` of tokens in release.
- Never add a dependency without checking maintenance status, license, platform support, and size impact.