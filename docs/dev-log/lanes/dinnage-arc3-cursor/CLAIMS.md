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

Updated: 2026-09-15 ~19:10 MDT (Cursor; A2 CI settled green).

- Base for Wave A branches: `238c1bedc` (= `origin/main` after PR #1366). **Three Wave A PRs open; agents must not merge.** Shinichi merges only after settled green CI + D-263 ACCEPT on each PR. **Wave B/C: HOLD until A2 (#1369) and A3 (#1367) are merged by Shinichi** (A1 may merge whenever its CI settles).
- **A1 docs — COMPLETE — PR [#1368](https://github.com/itchyshin/drmTMB/pull/1368)** (`cursor/dinnage-arc3-a1-docs-20260915`), head `d9f7f12eb` (C17 receipt refresh; follows `c10332534`). All ten A1 issues addressed in-branch (docs, `man/`, vignette, `NEWS.md`, focused evidence). **#1344 cross-PR help cleared.** Independent D-263 **ACCEPT** (docs). **Next:** **await settled green CI** (run in flight; not all-green yet) + Shinichi merge only.
- **A2 check/profile — MERGE-READY — PR [#1369](https://github.com/itchyshin/drmTMB/pull/1369)** (`cursor/dinnage-arc3-a2-check-20260915`), head `3805b8520` (C17 recert on branch). Scope: #1338, #1343; `R/check.R`, `R/profile.R`, wave4a tests, `NEWS.md`. Independent D-263 **ACCEPT** at `b6714135d` ([comment](https://github.com/itchyshin/drmTMB/pull/1369#issuecomment-5690203422)). **CI:** all 6 checks **SUCCESS** on run [35040873414](https://github.com/itchyshin/drmTMB/actions/runs/35040873414) @ `3805b8520`. **Shinichi merge only — agents must not merge.**
- **A3 misc code — PR [#1367](https://github.com/itchyshin/drmTMB/pull/1367)** (`cursor/dinnage-arc3-a3-misc-20260915`), head `6a5200f39` (CondExp + env-skip census refresh; follows `ab78327b8`). Code + `NEWS.md` on branch; C17 recert run last on branch. Independent D-263 **ACCEPT** unchanged ([comment](https://github.com/itchyshin/drmTMB/pull/1367#issuecomment-5690207752)). **Next:** **await settled green CI** (run in flight) + Shinichi merge only (no agent merge).
- **A4 record:** DONE (#1351).
- **D-263 review files:** owed per PR before merge; path `docs/dev-log/audits/2026-09-<dd>-dinnage-arc3-<a1|a2|a3>-review.md`.

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
