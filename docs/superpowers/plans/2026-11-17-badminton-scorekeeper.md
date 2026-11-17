# Badminton Scorekeeper Implementation Plan (Flutter)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Flutter phone app that scores a badminton match by one tap per rally and tells players who serves, from which court, who receives, when to change ends, when intervals start, and when it is game/match point.

**Architecture:** A pure Dart rules engine (`lib/engine/`, no Flutter imports) derives all match state by replaying an append-only event log (`PointEvent` / `StartGameEvent`) over a `MatchConfig`; undo = drop the last event. A thin Flutter UI renders the derived state and fires voice/haptic/wake-lock side effects. State persists via `shared_preferences`.

**Tech Stack:** Flutter 3.47 / Dart, `flutter_test`, `shared_preferences`, `flutter_tts`, `wakelock_plus`, built-in `HapticFeedback`. Phone app only (Android first, iOS where available).

**Spec:** `docs/superpowers/specs/2026-11-17-badminton-research.md` (researcher brief; there is no separate design doc). User decisions: the USER picks the ruleset at match setup (no fixed default); phone app via Flutter is enough (no watch).

## Global Constraints

- Rulesets, chosen by the user at setup: `bwf21` = win at 21, win by 2, cap 30 (at 29-all the 30th point wins), change ends in game 3 when a side first reaches 11, 60 s interval at 11, 120 s between games. `bwf15` = 15 / deuce at 14-all / cap 21 / change at 8 / 60 s interval at 8 / 120 s between games.
- Best of 3 games (`gamesToWin = 2`).
- Rally scoring: the rally winner scores; there is no second-server rule.
- Server serves from the RIGHT court when the serving side's score is even (including 0), LEFT when odd. The receiver stands in the same-named court (from their own side's view), i.e. diagonally opposite.
- Doubles: only the serving side swaps courts, and only when it wins a rally. When the receiving side wins, it becomes the serving side with no swap, and the player standing in the court matching its new score serves.
- The winner of a game serves first in the next game. Ends are swapped after every game, and in game 3 once, when a side first reaches `changeEndsAt`.
- Service-court/order errors keep the score (corrected by undo plus replay).
- Offline: no network, no accounts, no ads.
- Player ids are enum `PlayerId { a1, a2, b1, b2 }`; singles uses only `a1` and `b1`.
- Score call format is server's score first: `"7 – 5"`.

## Review Focus

1. Undo right after a game-winning point must restore the previous game's live state, and undo after a `StartGameEvent` must return to the between-games state.
2. 29-29 (bwf21) / 20-20 (bwf15): the next point wins; 20-20 in bwf21 must not end the game.
3. Reload/app kill mid-match resumes the same score, server and ends; corrupt stored JSON falls back to the setup screen, not a crash.
4. Taps after the match is finished are ignored; an accidental double-tap is recoverable via undo.
5. TTS, haptics or wake-lock unavailable must degrade silently, never throw.

---

### Task 1: Flutter project scaffold

**Files:**
- Create: Flutter project at repo root (`pubspec.yaml`, `lib/main.dart`, `analysis_options.yaml`, `android/`, `ios/`, `test/`), `.gitignore` (from Flutter)
- Modify: `NOTES.md`

**Interfaces:**
- Produces: `flutter test` and `flutter analyze` pass on a project named `badminton_score` (org `edu.csc4330`), platforms android and ios.

- [ ] **Step 1:** `flutter create --project-name badminton_score --org edu.csc4330 --platforms android,ios .` in the repo root; remove the template counter `test/widget_test.dart` and replace `lib/main.dart` with a `MaterialApp` whose home is a `Scaffold` with `Text('Badminton')`.
- [ ] **Step 2:** Write `test/smoke_test.dart` pumping `BadmintonApp` (class in `lib/main.dart`) and expecting `find.text('Badminton')`. Run `flutter test` — Expected: 1 passed.
- [ ] **Step 3:** `flutter analyze` — Expected: No issues found. Commit `chore: scaffold flutter project`.

---

### Task 2: Rulesets and game-level scoring

**Files:**
- Create: `lib/engine/types.dart`, `lib/engine/rulesets.dart`, `lib/engine/game.dart`
- Test: `test/engine/game_test.dart`

**Interfaces:**
- Produces (`types.dart`):
  ```dart
  enum Side { a, b }            // extension: Side get other
  enum PlayerId { a1, a2, b1, b2 } // extension: Side get side; PlayerId get partner
  enum Court { right, left }
  enum Format { singles, doubles }
  class Ruleset { final String id, label; final int pointsToWin, cap, changeEndsAt, intervalAt, intervalSec, betweenGamesSec, gamesToWin; const Ruleset(...named required...); }
  ```
- Produces (`rulesets.dart`): `const Ruleset bwf21`, `const Ruleset bwf15`, `const List<Ruleset> allRulesets = [bwf21, bwf15]` (values from Global Constraints; `intervalSec` 60, `betweenGamesSec` 120, `gamesToWin` 2).
- Produces (`game.dart`): `bool isGameWon(int a, int b, Ruleset r)`; `bool wouldWinGame(int scoreFor, int scoreAgainst, Ruleset r)`.

- [ ] **Step 1: Write failing tests** in `game_test.dart` (bwf21 unless noted): `isGameWon(21,19)` true; `(21,20)` false; `(22,20)` true; `(20,20)` false; `(29,29)` false; `(30,29)` true; bwf15: `(15,13)` true, `(15,14)` false, `(16,14)` true, `(21,20)` true. `wouldWinGame(20,18)` true; `(20,20)` false; `(29,29)` true; bwf15 `(14,14)` false, `(14,13)` true.
- [ ] **Step 2:** `flutter test test/engine/game_test.dart` — Expected: FAIL (missing files).
- [ ] **Step 3:** Implement. `isGameWon`: `max == cap` or (`max >= pointsToWin` and `max - min >= 2`). `wouldWinGame` = `isGameWon(scoreFor + 1, scoreAgainst, r)`.
- [ ] **Step 4:** `flutter test` — Expected: all pass. Commit `feat(engine): rulesets and game scoring`.

---

### Task 3: Service and court-position engine

**Files:**
- Create: `lib/engine/service.dart`
- Test: `test/engine/service_test.dart`

**Interfaces:**
- Consumes: types from Task 2.
- Produces:
  ```dart
  class Rally { final Map<Side,int> scores; final PlayerId server, receiver; final Map<PlayerId,Court> positions; /* all on-court players */ }
  Rally startRally(Format f, PlayerId server, PlayerId receiver);       // 0-0
  Rally awardPoint(Rally r, Side winner, Format f);                     // pure
  ```
  `startRally` puts server on `right`, partner on `left`; receiver on `right`, partner on `left`.

- [ ] **Step 1: Write failing tests:**
  - Doubles `startRally(doubles,a1,b1)`: positions `{a1:right,a2:left,b1:right,b2:left}`, 0-0.
  - Then A wins: A 1-0, server `a1`, positions `a1:left, a2:right`, receiver `b2`; B positions unchanged.
  - Then B wins: 1-1, server `b2` (score 1 odd → left), receiver `a1` (A's left), no position changes.
  - Then B wins again (server wins): B 1-2, server `b2`, positions `b2:right, b1:left`, receiver `a2` (A's right).
  - Singles `startRally(singles,a1,b1)`: A wins → server `a1` on `left`, receiver `b1` on `left`; B wins → B 1, server `b1` on `left`, receiver `a1` on `left`; B wins → B 2, server `b1` on `right`, receiver `a1` on `right`.
  - Property loop (seeded `Random`, 200 sequences of up to 60 points, doubles): server's court == parity of its side's score (even → right); receiver is the opponent standing in the same court name; each side's two players are always on different courts.
- [ ] **Step 2:** `flutter test test/engine/service_test.dart` — Expected: FAIL.
- [ ] **Step 3:** Implement `awardPoint`: increment winner score; if the server's side won and doubles, swap that side's two players' courts; if the receiving side won, new server = that side's player whose court is `right` when the new score is even else `left`; receiver = the opposing player on the same court name. Singles: each player's court = right if own score even, else left.
- [ ] **Step 4:** `flutter test` — Expected: all pass. Commit `feat(engine): service and court positions`.

---

### Task 4: Match flow, ends, intervals, cues, replay

**Files:**
- Create: `lib/engine/match.dart`
- Test: `test/engine/match_test.dart`

**Interfaces:**
- Consumes: Tasks 2 and 3.
- Produces:
  ```dart
  class MatchConfig { final Format format; final Ruleset ruleset; final Map<PlayerId,String> names;
    final PlayerId firstServer, firstReceiver; final Side leftEndSide; }
  sealed class MatchEvent {}
  class PointEvent extends MatchEvent { final Side winner; }
  class StartGameEvent extends MatchEvent { final PlayerId server, receiver; }
  sealed class Cue {}   // GamePointCue(Side side), MatchPointCue(Side side), ChangeEndsCue(),
                        // IntervalCue(int seconds), GameWonCue(Side side), MatchWonCue(Side side)
  enum MatchStatus { playing, betweenGames, finished }
  class MatchState { final MatchStatus status; final int gameNumber /*1-based*/; final Rally rally;
    final List<Map<Side,int>> finishedGames; final Map<Side,int> gamesWon;
    final Side leftEndSide; final List<Cue> cues /*from the LAST event only*/; final Side? winner; }
  MatchState deriveMatch(MatchConfig c, List<MatchEvent> events);
  bool canAcceptEvent(MatchConfig c, List<MatchEvent> events, MatchEvent e);
  ({PlayerId server, PlayerId receiver}) defaultNextServe(MatchConfig c, MatchState s);
  ```
  Semantics: `PointEvent` only while `playing`; `StartGameEvent` only while `betweenGames`. A game-winning point ends the game (`GameWonCue`), status `betweenGames` (or `finished` + `MatchWonCue` when `gamesWon` reaches `gamesToWin`). `StartGameEvent` starts the next game with given server/receiver and swaps `leftEndSide`. `defaultNextServe` = previous game's winner side, serving with the player on that side who last served (singles: the only player), receiver = the opposing player who last received.
  Cues after a point (not emitted when the game just ended): `GamePointCue`/`MatchPointCue` for each side that would win with the next point (`MatchPointCue` when that also ends the match); `IntervalCue(ruleset.intervalSec)` the first time in a game any side reaches `intervalAt` (once per game); `ChangeEndsCue` in game 3 the first time a side reaches `changeEndsAt` (once; also flips `leftEndSide`).

- [ ] **Step 1: Write failing tests** with helper `play(config, winners)`:
  - A wins 21-0 in game 1: `betweenGames`, `gamesWon[a]==1`, cues contain `GameWonCue(a)`.
  - Leader reaching 11 in game 1 yields exactly one `IntervalCue(60)` over the whole game; point 12 yields none.
  - 20-19 for A: cues contain `GamePointCue(a)`; at 20-20 (bwf21) no game-point cue; at 29-29 both `GamePointCue(a)` and `GamePointCue(b)`.
  - A wins games 1 and 2: `finished`, `MatchWonCue(a)`, `winner == a`, `canAcceptEvent(PointEvent)` false.
  - Games 1-1, game 3: first side to 11 yields one `ChangeEndsCue` and flips `leftEndSide`; the other side reaching 11 later yields none; with bwf15 it triggers at 8.
  - `leftEndSide` flips on `StartGameEvent` for game 2.
  - A up 1-0 in games, A at 20-10 in game 2 → `MatchPointCue(a)`; B at 20-19 in game 2 → `GamePointCue(b)` not match point.
  - Undo: `deriveMatch(c, events.sublist(0, n-1))` across a game boundary — dropping the game-winning point returns to `playing` with prior scores; dropping `StartGameEvent` returns `betweenGames`.
  - `defaultNextServe` after A wins game 1 (doubles, a1 last served, b1 last received) → `(server: a1, receiver: b1)`.
  - `deriveMatch` skips events `canAcceptEvent` would reject (stale log cannot crash).
- [ ] **Step 2:** `flutter test test/engine/match_test.dart` — Expected: FAIL.
- [ ] **Step 3:** Implement `deriveMatch` as a left fold using `startRally`/`awardPoint`, tracking per-game `intervalFired` / `endsChanged`.
- [ ] **Step 4:** `flutter test && flutter analyze` — Expected: all pass, no issues. Commit `feat(engine): match flow, cues, undo by replay`.

---

> Tasks 5-8 below are the later phase (not part of the first execution). They were drafted for a web stack; when started, port to Flutter: `speech/haptics/wakelock/storage` become `flutter_tts`, `HapticFeedback`, `wakelock_plus`, `shared_preferences`; UI becomes widgets; Task 8 becomes Android/iOS device runs instead of PWA. The ruleset is chosen by the user in setup.

### Task 5: Announcements and platform wrappers

**Files:**
- Create: `src/announce.ts`, `src/platform/speech.ts`, `src/platform/haptics.ts`, `src/platform/wakelock.ts`, `src/platform/storage.ts`
- Test: `src/announce.test.ts`, `src/platform/storage.test.ts`

**Interfaces:**
- Consumes: `MatchState`, `MatchConfig`, `MatchEvent`, `Cue` from Task 4.
- Produces:
  ```ts
  export function scoreCall(state: MatchState, config: MatchConfig): string;
  export function cueText(cue: Cue, state: MatchState, config: MatchConfig): string;
  export function serveText(state: MatchState, config: MatchConfig): string; // e.g. "Ann serves from the left to Bob"
  export function speak(text: string): void;          // no-op if speechSynthesis missing
  export function vibrate(pattern: number | number[]): void; // no-op if unsupported
  export function keepAwake(on: boolean): Promise<void>;      // swallow errors/unsupported
  export interface Saved { config: MatchConfig; events: MatchEvent[]; }
  export function loadMatch(storage: Pick<Storage,'getItem'>): Saved | null; // null on missing/corrupt/shape-invalid
  export function saveMatch(storage: Pick<Storage,'setItem'>, s: Saved): void;
  export function clearMatch(storage: Pick<Storage,'removeItem'>): void;
  ```

- [ ] **Step 1: Write failing tests:** `scoreCall` at A=7, B=5 with A serving → `"7 – 5"`; B serving at the same score → `"5 – 7"`; at 0-0 → `"Love all"`; equal nonzero scores `n-n` → `"n all"`; `cueText` for `changeEnds` → `"Change ends"`, interval → `"Interval, 60 seconds"`, `matchPoint` → `"Match point, <name of side's player(s)>"`; `serveText` doubles names server, court and receiver. Storage: `loadMatch` returns `null` for `getItem` returning `null`, `"{not json"`, and `"{}"`; round-trips a saved value.
- [ ] **Step 2:** `npx vitest run src/announce.test.ts src/platform/storage.test.ts` — Expected: FAIL.
- [ ] **Step 3:** Implement. `speak` cancels any queued utterance before speaking; `keepAwake` requests `navigator.wakeLock.request('screen')` and releases on `false`, re-acquiring on `visibilitychange` when still wanted. Storage key `badminton.match.v1`.
- [ ] **Step 4:** `npm test` — Expected: all pass.
- [ ] **Step 5:** Commit `feat: announcements, storage, platform wrappers`.

---

### Task 6: Setup screen and app shell

**Files:**
- Create: `src/ui/setup.ts`, `src/ui/app.ts`, `src/style.css`
- Modify: `src/main.ts`, `index.html`

**Interfaces:**
- Consumes: `RULESETS`, `MatchConfig`, `loadMatch`, `saveMatch`, `clearMatch`.
- Produces: `renderSetup(root: HTMLElement, onStart: (c: MatchConfig) => void): void`; `mountApp(root: HTMLElement): void` which loads a saved match (resume) or shows setup, and exposes `store = { config, events, push(e), undo(), reset() }` used by Task 7, persisting after every change.

- [ ] **Step 1:** Setup form: singles/doubles toggle; player names (defaults "Player A1" …); ruleset select (default `BWF_21`, label notes that the 15-point system is the upcoming BWF format); "Who serves first" (player radio) and, for doubles, "who receives first"; "Team A starts on left end" toggle (a "coin toss" helper is out of scope). Start builds a `MatchConfig`.
- [ ] **Step 2:** `mountApp` with the in-memory store; `push(e)` only appends when `canAcceptEvent`; persists via `saveMatch(localStorage, …)`. A "New match" action calls `clearMatch` after a confirm dialog.
- [ ] **Step 3:** Verify manually: `npm run dev`, start a match, reload the page — the app resumes (placeholder scoreboard text showing the score from `deriveMatch` is enough here); corrupt the key in devtools (`localStorage.setItem('badminton.match.v1','x')`) and reload — setup screen shows, no console error.
- [ ] **Step 4:** `npm run build` — Expected: succeeds. Commit `feat(ui): setup screen and persisted store`.

---

### Task 7: Scoring screen

**Files:**
- Create: `src/ui/scoreboard.ts`, `src/ui/court.ts`
- Modify: `src/ui/app.ts`, `src/style.css`

**Interfaces:**
- Consumes: `deriveMatch`, `defaultNextServe`, cues, `scoreCall`, `cueText`, `serveText`, `speak`, `vibrate`, `keepAwake`, store from Task 6.
- Produces: `renderScoreboard(root, store): void` (re-renders on every store change); `renderCourt(rally, config, leftEndSide): SVGElement`.

- [ ] **Step 1:** Layout (portrait, glanceable at arm's length, ≥ 96 px score digits): two full-width tap zones (Team A on top, Team B on bottom, or left/right in landscape), each showing name(s), big score, and a serving badge on the serving side. Tap = `push({type:'point', winner})`. Tapping is ignored when status is not `playing`.
- [ ] **Step 2:** Court diagram (`renderCourt`): top-down doubles/singles court with the two ends oriented using `leftEndSide`; each on-court player's name in their `positions` court; the server highlighted and the receiver ringed; plus the `serveText` line ("Ann serves from the right to Bob") under the score.
- [ ] **Step 3:** Cue banner: for each cue from the last event show a banner ("Change ends", "Game point", "Match point", "Game to A", "Interval 60 s" with a countdown). When status is `between-games` show a 120 s countdown and a "Start next game" button which pushes `startGame` from `defaultNextServe` (editable server/receiver select for doubles). When `finished` show the final game scores and "New match".
- [ ] **Step 4:** Side effects after each accepted event: `speak(scoreCall + cue texts)` (toggle button "Voice" persisted in `localStorage`, default on), `vibrate(60)` per point and `[60,60,60]` for a cue, `keepAwake(true)` while a match is mounted.
- [ ] **Step 5:** Controls: a prominent "Undo" button (always visible; disabled with no events) calling `store.undo()`; a mute toggle; the layout must never put Undo within the point tap zones' hit area.
- [ ] **Step 6:** Manual check against Task 4 scenarios in the browser (dev server): play doubles to 11 in game 3 and confirm the Change-ends banner once; confirm undo across a game end; confirm taps do nothing at `finished`; open in a mobile viewport (Chrome devtools) and check nothing needs scrolling.
- [ ] **Step 7:** `npm run build` — Expected: succeeds. Commit `feat(ui): scoring screen with court, cues, voice, undo`.

---

### Task 8: PWA offline install

**Files:**
- Modify: `vite.config.ts`, `index.html`
- Create: `public/icon-192.png`, `public/icon-512.png` (simple generated shuttlecock/"B" mark)

**Interfaces:**
- Consumes: the app from Tasks 6–7.
- Produces: installable, fully offline PWA (`display: standalone`, portrait-agnostic orientation, theme colour matching the CSS).

- [ ] **Step 1:** Configure `VitePWA({ registerType: 'autoUpdate', manifest: { name: 'Badminton Scorekeeper', short_name: 'Shuttle', display: 'standalone', icons: [...] }, workbox: { globPatterns: ['**/*.{js,css,html,png,svg}'] } })`.
- [ ] **Step 2:** `npm run build && npm run preview`; in Chrome devtools Application tab confirm the manifest is valid, the service worker is activated, then tick Offline and reload — the app loads and a match is playable.
- [ ] **Step 3:** Record in `NOTES.md` the findings for iOS Safari (vibration unsupported, wake-lock and speech behaviour to test on device) — checked on a real phone if available, otherwise say "untested on device".
- [ ] **Step 4:** Commit `feat: installable offline PWA`.

---

## Out of scope (YAGNI, revisit later)

Match history/stats, watch app, Bluetooth clicker/volume-button scoring, spectator second-screen display, tournament brackets, retired/walkover recording, let counter, coin-toss helper, multi-language voice.

## Open questions for the user

- Which ruleset should be the default now — 21-point or the new 15-point? (The plan ships both, default 21.)
- Is a phone web app (PWA) enough, or is a smartwatch/Bluetooth remote a must-have? That decides whether we later wrap with Capacitor.
