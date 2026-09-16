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

Updated: 2026-09-16 ~05:50 MDT (board tip `origin/main` @ `2c15ae63e`; **#1369 MERGED**; #1367 #1368 rebased post-#1369).

- **A2 [#1369](https://github.com/itchyshin/drmTMB/pull/1369): MERGED** on `main` @ `2c15ae63e` (2026-09-16). Wave B unlock **1/2**.
- Merge queue (Shinichi-authorized): **#1367 → #1368 → #1370 → #1371** after each is MERGEABLE/CLEAN with green CI. **Wave B implementation and Wave C: HOLD until A3 (#1367) on `main`.** Plan: [`LOOP/wave-b-brief.md`](LOOP/wave-b-brief.md).
- **A1 docs — PR [#1368](https://github.com/itchyshin/drmTMB/pull/1368)** (`cursor/dinnage-arc3-a1-docs-20260915`), head `2aad4c1b8` (rebased post-#1369) (`fix(ci): refresh Dinnage audit manifests` — capability-ledger manifest + `inst/extdata/env-skip-census.tsv` refresh; follows `c68620405` DHARMa **Suggests** + wave1 installed-doc path guards). All ten A1 issues addressed in-branch (docs, `man/`, vignette, `NEWS.md`, focused evidence). **#1344 cross-PR help cleared.** Independent D-263 **ACCEPT** (docs; unchanged). **CI:** all 6 R-CMD-check jobs **SUCCESS** on run [35046449684](https://github.com/itchyshin/drmTMB/actions/runs/35046449684) @ `822763660`; GitHub merge state **MERGEABLE / CLEAN**. **Shinichi merge only — agents must not merge.**
- **A3 misc code — PR [#1367](https://github.com/itchyshin/drmTMB/pull/1367)** (`cursor/dinnage-arc3-a3-misc-20260915`), head `684485d73` (rebased onto post-#1369 `main`; C17 recert `pr1367-a3-post-rebase`). D-263 **ACCEPT** unchanged. **Next:** green CI on rebased tip, then merge (B-unlock 2/2).
- **A4 record:** DONE (#1351).
- **D-263 audit markdown — MERGE-READY — PR [#1370](https://github.com/itchyshin/drmTMB/pull/1370)** (`cursor/dinnage-arc3-d263-audits-20260915`), head `fd84f009f` (rebased from `348ff67b6`). Lands `docs/dev-log/audits/2026-09-15-dinnage-arc3-a{1,2,3}-review.md` (sources: A1 `claude/pr1368-a1-rereview-20260915`, A2 `cursor/dinnage-arc3-a2-review-20260915` @ `b6714135d`, A3 `claude/pr1367-a3-rereview-20260915`). Independent light review **ACCEPT after rebase** ([comment](https://github.com/itchyshin/drmTMB/pull/1370#issuecomment-5691457958)). **CI:** all 6 checks **SUCCESS** on run [35060483133](https://github.com/itchyshin/drmTMB/actions/runs/35060483133) @ `fd84f009f`. **Live merge state @ 00:10 MDT: MERGEABLE / CLEAN**. **Shinichi merge only — agents must not merge.**
- **Wave B docs-only — MERGE-READY — PR [#1371](https://github.com/itchyshin/drmTMB/pull/1371)** (`cursor/docs-mdj-map-20260915`), head `d5055cf02`. Md-J design stub (`docs/design/276-…`) + Russell response map (`docs/dev-log/correspondence/2026-09-15-russell-dinnage-response-map.md`); **17 closed / 38 open** `audit-dinnage` after P1 fix. Independent D-263 light review **ACCEPT** (post-P1 re-check on tip). **CI:** all 6 checks **SUCCESS** on run [35053150085](https://github.com/itchyshin/drmTMB/actions/runs/35053150085) @ `d5055cf02`; **MERGEABLE / CLEAN**. Does **not** unlock Wave B implementation PRs. **Shinichi merge only — agents must not merge.**

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
