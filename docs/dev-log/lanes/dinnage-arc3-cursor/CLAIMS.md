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

- HOLD: all Wave B and Wave C implementation until Wave A coordination says otherwise.
- DEFER / PROTECTED: Md-K/Julia, S6, A-5/A-6, Md-L, Eq-4, variance-ratio interval design, S3 option B, Gaussian latent `mi()` missing-row weighting, raw-predictor sigma-clamp consumers, and M3 sqrt(n) tolerance design.

## Live Status

Updated: 2026-09-15 18:15 MDT (Ada integration poll).

- Base for all Wave A branches: `238c1bedc` (= `origin/main` after PR #1366). **A1 has two local commits; A2/A3 remain at base; zero Wave A PRs; none of the cursor specialist branches pushed to origin.**
- A1 docs worktree: `/Users/z3437171/local-scratch/lanes/drmTMB-a1-docs`, branch `cursor/dinnage-arc3-a1-docs-20260915`. **Local commits:** `5399733b9` (A-4 / #1334), `43502894b` (Md-F / #1323). **Uncommitted WIP:** `NEWS.md`, `R/family.R`. Still owed: eight other A1 issues, `man/`, `vignettes/capability-and-limits.Rmd`, per-finding tests N/A for docs PR but `R CMD check` evidence missing.
- A2 check worktree: `/Users/z3437171/local-scratch/lanes/drmTMB-a2-check`, branch `cursor/dinnage-arc3-a2-check-20260915`. **Uncommitted WIP:** `R/check.R` (A-8 / #1338 dropped-groups note). Still owed: `R/profile.R` (Mi-5 / #1343), `tests/testthat/test-dinnage-audit-wave4a.R`, `NEWS.md`, focused check evidence. **Lease:** A1 released `R/profile.R` at 18:15 MDT; A2 may claim it for Mi-5.
- A3 misc worktree: `/Users/z3437171/local-scratch/lanes/drmTMB-a3-misc`, branch `cursor/dinnage-arc3-a3-misc-20260915`. **Uncommitted WIP:** `src/drmTMB.cpp`, `src/drm_response_kernels.h` (Md-H / #1325 beta_binomial nudge); untracked `tests/testthat/test-dinnage-audit-a3-curie.R` (Claude Curie lease). Still owed: six other A3 issues, `R/methods.R` (+ C17 recert last), other R files, `test-numeric-kernel-oracle.R`, lease expects `test-dinnage-audit-a3-misc.R`.
- A4 record: DONE (#1351).
- **D-263 review files:** none yet; when each PR opens, fresh reviewer writes `docs/dev-log/audits/2026-09-<dd>-dinnage-arc3-<a1|a2|a3>-review.md` (builder must not self-ACCEPT).

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
