- 2026-11-17: Wrote plan docs/superpowers/plans/2026-11-17-badminton-scorekeeper.md (8 tasks, PWA + pure TS rules engine) using researcher brief in docs/superpowers/specs/.
  Next: user picks execution method; no code yet. Gotcha: BWF 21-pt vs new 15-pt rules, so rulesets are selectable (default 21).
- 2026-11-17: Switched to Flutter. Tasks 1-4 done on branch feat/engine: scaffold + pure Dart engine in lib/engine (rulesets, service, match) with 22 passing tests; reviewed by opus reviewer, 1 fix applied.
  Next: Tasks 5-8 (TTS/haptics/storage, setup screen where USER picks ruleset, scoring screen, device run) — plan tasks 5-8 still describe the web stack, port them first. Gotcha: UI must let game winner pick next server and prevent same-side picks.
- 2026-11-17: Built UI on feat/ui: setup (user picks ruleset), scoreboard with top-down court showing who stands where, cues, undo, next-game/finished cards. 27 tests pass. No persistence/TTS/timers yet (kept plugin-free for xtool builds).
  Next: persistence, voice calls, interval countdown. Gotcha: push over HTTPS via gh credential helper (SSH key rejected); run on phone with `flutter-iphone` (trust profile on device first).
