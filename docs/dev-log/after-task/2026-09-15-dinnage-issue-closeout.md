# After-task: Dinnage audit issue close-out (2026-09-15)

## 1. Goal

Close the GitHub issues from Russell Dinnage's independent evaluation that `origin/main` already fixes, each with an evidence comment, and record a status comment on #1301. Docs-only lane: no code, tests, or NEWS changes.

## 2. Implemented

- Closed 16 issues on GitHub (list in section 7a), each with a comment citing the fixing commit sha(s) on `origin/main` and the crediting `NEWS.md` bullet, or for #1309 and #1312 the non-code reason.
- Posted a status comment on #1301 (see section 7a for the URL); the issue stays open for the D-252 vocabulary question.
- Appended "## Closed on GitHub (2026-09-15)" to the response map, with an updated counts table (FIXED 16, PRESENT 36, MOVED 1, UNCLEAR 1), and recorded the drafts, Rose's review, and the posted URLs in `docs/dev-log/issue-drafts/2026-09-15-dinnage-closeout/` (`EVIDENCE.tsv`, `TO-CLOSE.tsv`, `REVIEW.md`, `CLOSED.tsv`).

## 3a. Decisions and Rejected Alternatives

- #1312 (S3) closed as decided and documented (D-266), not a code fix (the roxygen diff `d44a495be` is documentation only); a plain-fix framing was rejected as an overclaim.
- #1309 (M3) closed on "does not reproduce after #1130, regression lock at n = 2000" (`61db027b0`), not a fixed-tolerance-bug claim. Rose deleted a sentence overstating the scanned range (lock n = 2000, report n = 1000); the absolute-tolerance design question stays open, deferred.
- #1352 (Mi-14) closed as pre-audit: fix `743191f8b` (2026-08-30) predates the issue filing but postdates the report's evidence pin (2026-08-29); Rose corrected the draft wording to say so precisely.
- Out of scope, not touched: the 5 stale open PRs, S6 bootstrap opt-in code, the Md-K decision, any message to Russell Dinnage.

## 4. Files Touched

New: `docs/dev-log/issue-drafts/2026-09-15-dinnage-closeout/` (`EVIDENCE.tsv`, `TO-CLOSE.tsv`, `REVIEW.md`, `CLOSED.tsv`, 17 per-issue draft `.md` files); this report. Edited: the response map at `docs/dev-log/audits/2026-09-13-dinnage-independent-evaluation-response.md` (section appended). No file under `R/`, `src/`, `tests/`, or `NEWS.md` was touched.

## 5. Checks Run

`check-shas.mjs` -> `ALL_ON_MAIN 17`; `check-drafts.mjs` -> `DRAFTS_OK 17`; `check-review.mjs` -> `REVIEW_CLEAN 17/17`; `check-closed.mjs` -> `CLOSED_SET_MATCH 16`; `check-open.mjs` -> `OPEN 39`. No `R CMD check`, `devtools::test()`, or CI run: nothing under `R/`, `src/`, or `tests/` changed.

## 6. Tests of the Tests

There are no code tests in this lane; there is no code. The gates in `.unlazy/dinnage-closeout/gates/leaf-closeout.md` are the checks. G3 (the closed-set match) is exercised against a known-positive by design: it compares the live GitHub closed-issue set for label `audit-dinnage` against `TO-CLOSE.tsv`, so a close that failed to post, or a wrong issue number in the list, makes the two sets differ and the check fails. A missing close is exactly the failure mode the comparison catches.

## 7a. Issue Ledger

Closed (16), label `audit-dinnage`: #1306 (C1), #1307 (M1), #1308 (M2), #1309 (M3), #1310 (M4), #1311 (S1), #1312 (S3), #1313 (S4), #1314 (S5), #1318 (Md-A), #1321 (Md-D), #1322 (Md-E), #1330 (Md-M), #1331 (Md-N), #1347 (Mi-9), #1352 (Mi-14).

Not closed, comment only: #1301 (S2), fix landed (`3192db3f6`, `1c44d2f12`, `19849f0dc`), stays open for the D-252 vocabulary question. Comment: https://github.com/itchyshin/drmTMB/issues/1301#issuecomment-5687875746

38 `audit-dinnage` issues remain open past this close (#1351 closed later the same day as A4 record).

## 8. Consistency Audit

Rose reviewed all 17 drafts against the shas, NEWS text, existing issue comments, and the no-em-dash house style. Verdict: 14 ACCEPT, 3 CHANGE-APPLIED (#1309, #1312, #1352; see section 3a). No draft claims a fix beyond what `EVIDENCE.tsv` and `NEWS.md` support. The overclaim class caught in those three, a non-code decision stated as a fix, was checked across all 17 drafts, not only the two known non-code closes, and none of the other 15 had it.

## 9. What Did Not Go Smoothly

- The first Sonnet drafting agent died on an expired OAuth token (API 401) before writing anything, and was re-dispatched; no partial output existed to reconcile.
- The Haiku recon agent that wrote `EVIDENCE.tsv` mis-recorded `news_wave` as "none" for M3 (#1309), because the NEWS bullet begins "Finding M3", not "finding M3", and its match was case-sensitive. The writer agent found the correct NEWS wave independently while drafting the comment, so the closing comment is not affected. `EVIDENCE.tsv` still shows "none" for M3's `news_wave` column; this is a gap in that one file, not in the posted comment.

- The ledger's G5 first ran the after-task validator as a gate CHECK. The validator re-verifies the ledger itself, so G5 saw its own pending state and the not-yet-mergeable G7 and failed on every run. The validator's source says a gate CHECK must never call it. G5 now runs it with `CHECK_AFTER_TASK_ACTIVE=1` (structure only); the full validator, ledger included, is the standalone check after the merge.

## 10. Known Residuals

- Gates G5 to G7 in `.unlazy/dinnage-closeout/gates/leaf-closeout.md` were pending at write time: G5 (this report passing the hub validator), G6 (the response map's Counts table showing FIXED = 16, satisfied by section 2 above), and G7 (the docs-only PR merged into main). G5 and G7 are checked after this report is written and the PR is opened.
- `EVIDENCE.tsv`'s `news_wave` column reads "none" for M3 (#1309) instead of the correct wave; see section 9.
- Deferred, not attempted here: a third audit arc for M3's sqrt(n) design question; the 36 open Moderates/Minors/UX issues; S6 bootstrap opt-in code; the Md-K decision; the #1301 vocabulary question; any message to Russell Dinnage; the five stale PRs (#1033, #1110, #1111, #1191, #1304).

## 11. Team Learning

A NEWS-bullet text match used for automated evidence lookup should be case-insensitive, or should match on a stable identifier (the issue ID or sha) rather than the literal casing of a heading word like "Finding". The mismatch here was caught at the drafting step rather than at the recon step, a weaker safety net than catching it at the source.

## 12. Cross-Product Coverage

This lane closed GitHub issues and updated the response-map document; it does NOT cover: the 38 still-open `audit-dinnage` issues (Moderates, Minors, UX items, and Mi-13, moved); the M3 sqrt(n) tolerance design question, which stays open under #1309 despite the issue being closed; the S6 bootstrap opt-in implementation; the Md-K public-status decision; the #1301 D-252 vocabulary question; any outreach to Russell Dinnage; the five stale open PRs (#1033, #1110, #1111, #1191, #1304); and any code, test, or `NEWS.md` change, none of which this lane touched. It also does NOT cover re-verifying the underlying fixes: that verification was done in the earlier wave 1 to 3 audit-response arcs and is only cited here, not repeated.

## Addendum (2026-09-15, after the merge of PR #1364)

The G5 route described in section 9 did not hold either: an approval binds the exact ledger path
and environment, and the validator's own re-verify run refused the gate that called it. G5 is now a
plain Node structure check (twelve headings in order, the "does NOT cover" marker, no em dash), and
the hub validator runs standalone after the merge: structure check passed, acceptance ledger
1 file, every gate satisfied, 8 of 8 met. Lesson: never make the validator a gate CHECK; the
validator already re-verifies the ledger.
