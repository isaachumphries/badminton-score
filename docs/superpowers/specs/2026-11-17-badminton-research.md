# Research: Badminton score-keeping assistant app

## Summary
Current BWF rules (21 pts, win by 2, cap 30, best of 3) are being replaced by a **3×15 system**: BWF news (Apr 2026) and Laws v6.0 "In Force 04/01/2027" use 15 pts, deuce at 14-all, cap 21, end change at 8, interval at 8. The app should make the ruleset configurable (21/30 and 15/21 presets). Service logic is unchanged between the two. Recommended stack: an offline-first PWA, or Capacitor-wrapped if watch/background audio is needed.

## Findings
1. **Scoring (new v6.0 text):** 15 pts to win; at 14-all first to a 2-point lead wins; the Swiss-hosted copy of the Laws says "at 20 all, the 21st point wins" (cap 21). Winner of a game serves first in the next game. Best of 3 unless otherwise arranged. **Sources:** [Laws v6.0 PDF (Swiss Badminton host)](https://www.swiss-badminton.ch/fileadmin/user_upload/reglemente/20260819_Laws_of_Badminton.pdf); [BWF news on 3x15](https://bwfbadminton.com/news-single/2026/04/26/key-changes-under-the-3x15-scoring-system) (seen only as a search snippet; fetch returned 403). **Support:** direct (PDF), snippet only for BWF news. **Confidence:** high for the 15 pts and 14-all rules, medium for the cap of 21.
2. **Old rules (21/30):** 21 pts, win by 2, at 29-all the 30th point wins; the interval is at 11 and the third-game end change at 11. **Sources:** [worldbadminton 2025 laws](https://worldbadminton.com/laws/rules_2025.htm), which shows 21 in its 7.2. I did not re-fetch the 29-all/30 text or the 11-point details. They are consistent with your brief and widely known, so treat them as background knowledge. **Confidence:** medium-high.
3. **Singles service:** server serves from the right court when the server's score is even (including 0), and from the left when it is odd. After winning a rally the server alternates courts. If the receiver wins, the receiver scores and becomes server. **Sources:** Laws v6.0 §10 (PDF above). **Support:** direct. **Confidence:** high.
4. **Doubles service:** the serving side serves from the right when its score is even, and from the left when odd. The receiver is the player diagonally opposite the server. Only the serving side swaps courts, and only when it wins a point as server (the same server serves again from the alternate court). The receiving side keeps its positions; the receiver's last-server stays in the same court. When the receiving side wins a rally it scores and becomes the serving side, with no court swap. Then the player standing in the court that matches the new serving side's score serves. **Sources:** Laws v6.0 §11 (PDF). **Support:** direct, with the last point being my inference from 11.1.6. **Confidence:** high.
5. **Doubles serving order and first server:** The nominal sequence is initial server → partner of initial receiver → partner of initial server → initial receiver → and so on. No one serves or receives out of turn or receives twice in a row. In practice the order is derived from position and score. The side that wins the next game chooses either player to serve first, and the losing side chooses either receiver. There is **no second-server rule** in rally scoring; each side has one "turn" that ends at the first lost rally. A service-court error (wrong court or out of turn) is corrected when the shuttle is not in play, and the **score stands**. **Sources:** Laws v6.0 §11–12 (PDF). **Support:** direct. **Confidence:** high.
6. **Toss:** the winner picks serve/receive or end, and the loser gets the other choice. **Sources:** Laws v6.0 §6. **Confidence:** high.
7. **Change of ends and intervals (new):** change after game 1, after game 2 if a game 3 is played, and in game 3 when a side first reaches **8**. A 60 s interval applies when the leading score reaches 8 in each game. A 120 s interval applies between games. **Sources:** Laws v6.0 §8, §16.2 (PDF). **Support:** direct. **Confidence:** high. Old rules used 11 for both the third-game change and the 60 s interval (background knowledge, medium-high confidence).
8. **Lets and faults:** a let (service before the receiver is ready, both faulted, shuttle stuck in the net after service return, a coach distraction, etc.) means the rally is not counted and the last server serves again from the same court. Faults award the rally to the opponent. **Sources:** Laws v6.0 §13–14 (PDF). **Confidence:** high.
9. **Edge cases:** Wrong-end or wrong-court mistakes are corrected as soon as they're discovered, with the score kept. The rules sources I read don't cover retirement or walkover scoring (that sits in the BWF Statutes/tournament regulations), so the app should record it as a manual "retired/walkover" result. A best-of-3 can be "otherwise arranged" (for example a single game), so support a configurable number of games.
10. **Existing apps (marketing claims, not independent reviews):**
   - Watch-focused apps: [Badminton – Keep Your Score!](https://apps.apple.com/gb/app/badminton-keep-your-score/id1592385071) offers watch tapping, voice announcement of scores, service and match points, and court position diagrams for singles/doubles.
   - [Badminton Score](https://applikhations.com/score-apps/badminton-score/) offers one tap per rally, a 30-point cap, service court, voice calls, undo, timeouts, match history, Apple Health and wrist gestures.
   - [MatchCaller](https://matchcaller.app/) offers Bluetooth remote/clicker scoring, a real announcer voice, no account and no signal needed, and Android watch support.
   - [Geilio](https://geilio.com/en/scoreboard/) offers one tap on the watch and a live iPhone display for spectators.
   **Confidence:** medium. These are vendor descriptions, not independent evidence.
11. **Recurring feature set (inference):** one-tap scoring, undo, service indicator and court side, voice calls, a big display for spectators, history, and a watch or remote. I did not find reliable user-complaint data (store reviews/Reddit) in this pass. Plausible pain points (my inference, unverified): wrong server tracking in doubles, no undo, ads, lost state on phone sleep, hard to see outdoors or from a distance, and rule-version mismatch (21 vs 15).
12. **Tech options:** the search results are generic: a PWA is enough for foreground, offline, one-codebase use. Native/React Native is for background work, deep hardware access, or iOS features Safari lacks. Sources: [Moiz](https://muhammadmoiz.dev/blog/progressive-web-apps-vs-native-app), [Pictorica](https://pictorica.dev/insights/mobile-mvp-development-guide), [KTH thesis](https://kth.diva-portal.org/smash/get/diva2:1653815/FULLTEXT01.pdf). **Confidence:** low-medium (blog quality; I did not verify per-API support).
   **Recommendation (inference):**
   - Build an offline-first PWA (service worker, localStorage/IndexedDB for state).
   - Use a pure rules engine in TypeScript with unit tests, and an event log so undo is just popping events.
   - Use the Web Speech API for announcements, the Screen Wake Lock API to keep the screen on, and `navigator.vibrate` for haptics. Check iOS Safari support, since Vibration API support is absent and wake lock/PWA audio behavior needs testing.
   - If a watch app, reliable haptics or background audio is a requirement, wrap with Capacitor, or write a native watch companion later. React Native is unnecessary for a single-screen scoring UI.

## Contradictions
- **Version conflict (important):** 21-point/30-cap rules vs 15-point/21-cap. The BWF news says 3×15 was approved. The Laws PDF is labelled "In Force: 04/01/2027". The date is ambiguous (April 1 vs 4 January), and I couldn't verify the current in-force date. Today is 2026-11-17, so the 21-pt rules are likely still in effect for now. Make the ruleset selectable.
- The Swiss-hosted v6.0 PDF says "at 20 all, the 21st point wins". Other snippets mention 14-all but I didn't see an official statement of the cap anywhere else. Verify against the BWF page.
- Third-game end change: 8 (new) vs 11 (old). Interval: 8 (new) vs 11 (old).

## Missing evidence
- The BWF news page was unreadable (403), so I'm relying on a hosted copy of the Laws.
- The exact effective date of 3×15 and whether leagues or club play adopt it at the same time.
- Retirement, walkover and tie-break details, plus a (2 vs 3 game) policy for non-BWF events.
- Real user reviews or complaints of scoring apps; iOS PWA API limits (vibrate, wake lock, speech); the Wear OS PWA story.

## Sources
- Kept: Laws of Badminton v6.0 PDF (https://www.swiss-badminton.ch/fileadmin/user_upload/reglemente/20260819_Laws_of_Badminton.pdf) — full text on service, doubles, lets, intervals.
- Kept: BWF 3×15 news (https://bwfbadminton.com/news-single/2026/04/26/key-changes-under-the-3x15-scoring-system) — snippet only.
- Kept: worldbadminton laws 2025 (https://worldbadminton.com/laws/rules_2025.htm) — old 21-pt version.
- Kept: app store pages: apps.apple.com, applikhations.com, matchcaller.app, geilio.com — feature sets.
- Kept (weak): Moiz, Pictorica, KTH — generic PWA/native trade-offs.
- Deprioritized: GitHub "ZAOOS" research README — a personal notes repo with unsupported figures.

## Next steps
- Confirm the 3×15 effective date and the cap via the BWF news page (browser) or the BWF Handbook.
- Skim App Store/Play reviews for the top 3 scoring apps for real complaints.
- Prototype the PWA wake lock, speech and vibration behavior on iOS Safari and Android Chrome.
