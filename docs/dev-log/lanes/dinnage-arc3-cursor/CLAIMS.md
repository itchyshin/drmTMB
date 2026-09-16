# Dinnage Arc3 Cursor Coordinator Claims

Started: 2026-09-15 18:03 MDT

## Lane

- Lane name: `dinnage-arc3-cursor`
- Branch: `claude/lane-dinnage-arc3-cursor`
- Worktree: `/Users/z3437171/local-scratch/lanes/drmTMB-dinnage-arc3-cursor`
- Lease policy: no broad directory lease. The coordinator uses temporary file-level leases only.
- Coordinator-owned paths: `docs/dev-log/lanes/dinnage-arc3-cursor/LOOP/` and morning handoff/checkpoint files when actively editing them.

## Rehydration

- Required preflight was run first from the foreground checkout, then again from this worktree.
- The foreground checkout remains on `claude/d252-repeatability-notice-20260908` with unrelated dirty files and is protected.
- The coordinator worktree is clean and based on `238c1bedc`, the merge of PR #1366 containing the arc3 handover.
- `python3 ~/shinichi-brain/tools/route.py "/Users/z3437171/Dropbox/Github Local/drmTMB"` found no LOAD-FIRST manifest for this repo path.
- `gh issue list --label audit-dinnage --state open --limit 100` showed all 39 Dinnage audit issues still open.

## Coordinator Scope

The coordinator owns coordination records, status reconciliation, collision resolution, and the morning handoff. It does not own implementation files unless a specialist explicitly fails or returns a bounded patch for integration.

## Wave A Dispatch Board

- A1 docs PR: issues #1317, #1320, #1323, #1334, #1341, #1345, #1346, #1349, #1354, #1359. Owns roxygen, generated `man/`, `vignettes/capability-and-limits.Rmd`, `NEWS.md`, and its tests/check evidence.
- A2 check.R PR: issues #1338, #1343. Owns `R/check.R`, `R/profile.R`, `tests/testthat/test-dinnage-audit-wave4a.R`, `NEWS.md`, and focused check evidence. This must finish before any later B1 work.
- A3 misc code PR: issues #1324, #1325, #1326, #1344, #1348, #1350, #1357, #1358. Owns `src/`, `R/drmTMB.R`, `R/methods.R`, `R/phylo-utils.R`, `R/associate-pairs.R`, `R/aghq-coxreid.R`, related tests, and C17 recertification last via `tools/recertify-c17.py`.
- A4 record: DONE. Issue #1351 was closed at https://github.com/itchyshin/drmTMB/issues/1351#issuecomment-5689879524; the vault CRAN release-gate skill was updated by a separate agent and is being committed in the vault. No tag, release, or CI enforcement change.

## Held / Protected

- HOLD: all Wave B and Wave C implementation until **A2 (#1369) and A3 (#1367) are merged by Shinichi** (independent of whether A1 merges first).
- DEFER / PROTECTED: Md-K/Julia, S6, A-5/A-6, Md-L, Eq-4, variance-ratio interval design, S3 option B, Gaussian latent `mi()` missing-row weighting, raw-predictor sigma-clamp consumers, and M3 sqrt(n) tolerance design.

## Live Status

Updated: 2026-09-16 ~06:25 MDT (board tip `origin/main` @ `a543c11a4`; **#1369 + #1367 MERGED**).

- **Merge agents: PAUSE** until parallel CI triage settles — **`main` `receipt-staleness` green**, **#1368 R-CMD-check green**, **#1370 R-CMD-check green**. Do not merge #1368 / #1370 / #1371 while red or in-flight.
- **A2 [#1369](https://github.com/itchyshin/drmTMB/pull/1369): MERGED** @ `2c15ae63e`. **A3 [#1367](https://github.com/itchyshin/drmTMB/pull/1367): MERGED** @ `e6ca0dc8e` (pre-merge CI all **SUCCESS**, run [35092861888](https://github.com/itchyshin/drmTMB/actions/runs/35092861888)). **Wave B implementation: UNLOCK pending `main` receipt green** — B1/B2 may spawn per [`LOOP/wave-b-brief.md`](LOOP/wave-b-brief.md) once receipt-staleness passes; **Wave A merge queue still HOLD**.
- **`main` CI:** `receipt-staleness` **FAILED** on #1367 merge push ([35095399310](https://github.com/itchyshin/drmTMB/actions/runs/35095399310)); **IN_PROGRESS** on coord tip ([35095465048](https://github.com/itchyshin/drmTMB/actions/runs/35095465048)). Fix lane owns receipt refresh; coordinator does not.
- Remaining queue (after triage): **#1368 → #1370 → #1371** (CI-green merge only).
- **A1 docs — PR [#1368](https://github.com/itchyshin/drmTMB/pull/1368)** (`cursor/dinnage-arc3-a1-docs-20260915`). **CI:** prior run [35093012041](https://github.com/itchyshin/drmTMB/actions/runs/35093012041) **FAILED** — capability-ledger validator (stale C17 receipt for `R/drmTMB.R`, not `R/methods.R`); **re-run IN_PROGRESS** [35095486957](https://github.com/itchyshin/drmTMB/actions/runs/35095486957). Merge state **UNSTABLE**. Fix lane owns C17 repoint on branch tip.
- **A4 record:** DONE (#1351).
- **D-263 audit markdown — PR [#1370](https://github.com/itchyshin/drmTMB/pull/1370)** (`cursor/dinnage-arc3-d263-audits-20260915`). Prior CI green @ `fd84f009f`; **fresh R-CMD-check IN_PROGRESS** [35095453122](https://github.com/itchyshin/drmTMB/actions/runs/35095453122) post-#1367 merge. **PAUSE merge** until settled green.
- **Wave B docs-only — PR [#1371](https://github.com/itchyshin/drmTMB/pull/1371)** (`cursor/docs-mdj-map-20260915`), head `d5055cf02`. Prior CI green [35053150085](https://github.com/itchyshin/drmTMB/actions/runs/35053150085) **stale vs current `main`**; merge state **CLEAN** but **PAUSE** until #1368/#1370 triage done. Does **not** unlock Wave B code PRs.

## Claim Reporting

The coordinator released the broad lease on `docs/dev-log/lanes/dinnage-arc3-cursor/` at 2026-09-15 18:04 MDT. Specialists should not request that directory as a whole.

Specialists have two safe reporting routes:

- Report claimed files to the coordinator, who will append them to this file under a temporary `CLAIMS.md` file-level lease.
- Or create a personal inbox note under `docs/dev-log/lanes/dinnage-arc3-cursor/claims-inbox/<specialist>.md` and lease only that exact file.

Recommended lease command shape:

```sh
LANE_ID='<specialist>:dinnage-arc3-<domain>' ~/shinichi-brain/tools/lane_lease.sh --claim drmTMB --paths '<exact-file-or-comma-separated-files>'
```

Gauss starting point:

```sh
LANE_ID='gauss:dinnage-arc3-A3' ~/shinichi-brain/tools/lane_lease.sh --claim drmTMB --paths 'src/,R/drmTMB.R,R/methods.R,R/phylo-utils.R,R/associate-pairs.R,R/aghq-coxreid.R,tests/testthat/test-numeric-kernel-oracle.R,tests/testthat/test-dinnage-audit-a3-misc.R'
```

## OWED Classification

OWED now means Wave A only. All of these were still open on GitHub during rehydration:

- Wave A1 docs: #1317, #1320, #1323, #1334, #1341, #1345, #1346, #1349, #1354, #1359.
- Wave A2 check/profile: #1338, #1343.
- Wave A3 misc code: #1324, #1325, #1326, #1344, #1348, #1350, #1357, #1358.
- Wave A4 record/vault item: DONE for #1351.

HELD after Wave A:

- Wave B1 check.R: #1319, #1327, #1333, #1337, #1342, #1356.
- Wave B2 surfaces: #1316, #1332, #1353, #1355, #1360.
- Wave C API: #1339, #1340.

PROTECTED / not coordinator-owned:

- Julia bridge public-status work #1328 and Julia bridge files, owned by active Codex Julia lanes.
- Deferred campaign/design items named in the handover: #1315, #1335, #1336, #1329, plus carried-over design/campaign questions.

## Integration Rules

- No `git add -A`.
- No push, merge to main, CRAN submission, tags, releases, or email.
- Do not edit foreign specialist files unless integrating an explicit returned result and holding the lease.
- Each implementation branch must run its own focused tests and C17 recertification when touching `R/methods.R` or `R/drmTMB.R`.
