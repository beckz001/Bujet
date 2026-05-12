# Portfolio — remaining changes after Sprint 3 plan applied

Read of the updated `CS6005_ Portfolio_ZACHARY_BECK.pdf` (12 May 2026) against
the original `PORTFOLIO_SPRINT3_PLAN.md` and the module brief.

## What you've already done (verified)

- §2.1 Pause-before-purchase use case diagram redrawn with `Skip` + note ✅
- §2.2 Use case table for Pause & review updated with the Skip alternative ✅
- §2.3.5 S3.4 description rewritten properly (single-record NFR) ✅
- §2.3.6 Test cases T3.1 – T3.8 + T3.10 replacing the old Insights tests ✅
- §3.3 New Pause & Reflect sequence diagram added (great — keeps all 3 sprints covered) ✅
- §3.4 Detailed class descriptions: swapped `ReviewSpendingViewModel` for
  `PreSpendInterventionFlow` ✅
- Sprint 2 NFR count fixed: S2.3, S2.4, S2.5 are now all NFRs (meets the
  "min 3 NFRs per sprint" rubric) ✅

## What still needs changing

### 1. Class diagram (§3.2) — biggest open item

Current slide is still self-flagged *"still working on adding sprint 3 classes"*
and shows `ReviewSpendingViewModel` / `InsightService` / `InsightReport`, which
contradicts the rest of the Sprint 3 narrative.

**Three new diagrams are now in `portfolio_diagrams/`:**

| File | Slide title suggestion |
|---|---|
| `ClassDiagram_Sprint1_2.png` | 3.2 Class diagram — Sprints 1 & 2 |
| `ClassDiagram_Sprint3_ViewsAndFlow.png` | 3.2 Class diagram — Sprint 3 (Views + Flow) |
| `ClassDiagram_Sprint3_DomainAndData.png` | 3.2 Class diagram — Sprint 3 (Domain, Services, Repositories, Models) |

PlantUML source for each is alongside the PNGs in the same folder so you can
edit/re-render later.

**Action:** delete the current §3.2 slide content and the *"still working on…"*
title, drop these three images onto three consecutive slides.

### 2. Test case for S3.5 is missing (rubric risk)

T3.1 – T3.8 cover S3.1 – S3.4. T3.10 covers S3.6. **No test covers S3.5**
(on-device LLM / no data leaves device). Add `T3.9` from the original plan:

> **T3.9 — S3.5 On-device LLM narrative — no proposal data leaves the device.**
> 1) Put the simulator into Airplane mode (or block network at the OS level).
> 2) Run T3.1 end-to-end. 3) Inspect network traffic and the decision-view
> narrative paragraph.
> *Expected:* A non-empty LLM narrative renders. Zero outbound network traffic
> during evaluation. If the on-device model fails to load (e.g. older
> simulator), the app falls back to hard-coded copy with the same numerical
> budget impact — sheet still renders, no crash.

This closes the S3.1–S3.6 → test coverage map.

### 3. Architecture diagram (§3.1) — small Sprint 3 callout

The diagram is still framed entirely around Sprint 1's three-tier client/server
path. Sprint 3 doesn't touch the backend at all — that's actually an
architectural decision worth a single bullet in the right-hand prose:

> *Sprint 3 (Pause & Reflect) runs entirely on-device. The Foundation Models
> LLM, `UNUserNotificationCenter`, and JSON-persisted repositories all live on
> the iOS device — no proposal, amount, or category is ever transmitted. This
> satisfies S3.5 at the architecture level, not just at the implementation
> level.*

You don't need a second diagram; the bullet is enough.

### 4. Section 4 — Evidence of Implementation is empty

Slide currently has only the heading and *"4.1 Video recording of the working
system (max of 10 minutes long)"*. Add:

- Link / embed of the demo video.
- A short walk-through script (or screenshot stills) if you can't embed
  video in the PPTX — useful for marker context.

### 5. Section 5 — Reflection is empty

Slide currently just repeats the rubric prompts. The brief's §5 (5%) wants
three answers + references:

1. Lessons learned + what you'd improve next time.
2. AI tools used — pros/cons (e.g. Claude Code, GitHub Copilot, chatDyson).
3. Team formation — motivation for going individual, what went well, what to improve.

Plus references to anything you read beyond Canvas content, each with one
sentence on what you learned and how it shaped the project (Apple HIG,
Foundation Models docs, TrueLayer/Open Banking docs, anything on layered
architecture, etc.).

## Nice-to-haves (small, not required)

- **Add `PreSpendInterventionUseCase` to §3.4 as a 4th detailed class.** The
  brief requires "min 3 classes/person" and you have exactly 3. Adding the use
  case shows off the layering (Flow ≠ UseCase ≠ Repository), which directly
  evidences the *"well-argued choice of architectural style"* OOD rubric. The
  yellow-box description for it is already drafted in
  `PORTFOLIO_SPRINT3_PLAN.md` §8.2.

- **Top-level use case diagram** could optionally name the actor on the
  "Tap notification → reopen pre-filled sheet" arrow, but it's clear enough
  from the sub-diagram so this is cosmetic.

## Brief alignment recap (after applying the above)

| Brief item | Required | After fixes |
|---|---|---|
| §1.2 Similar systems / person | min 3 | 3 (Snoop, Emma, YNAB) ✅ |
| §2.2 Use case tables | min 3 | 3 ✅ |
| §2.3 Each sprint NFRs | min 3 | S1: 3, S2: 3, S3: 3 ✅ |
| §2.3 Each sprint shall → test coverage | (implicit) | Add T3.9 to close S3.5 ✅ |
| §3.1 Architecture diagram | 1 | 1 + Sprint 3 bullet ✅ |
| §3.2 Class diagram (abstract) | 1 | 3 new diagrams covering all sprints ✅ |
| §3.3 Message sequence diagrams | (no count) | 3 (Connect bank / Manual add / Pause & Reflect) ✅ |
| §3.4 Detailed class descriptions | min 3 | 3 (4 if you add UseCase) ✅ |
| §4 Implementation video | 1, ≤10 min | Pending |
| §5 Reflection | full coverage | Pending |
