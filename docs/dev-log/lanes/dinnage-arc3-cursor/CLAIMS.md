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

- ~~HOLD Wave B~~ **UNLOCKED 2026-09-16:** A2 (#1369) @ `2c15ae63e` and A3 (#1367) @ `e6ca0dc8e` on `main`. Wave C implementation still HOLD until Wave B lands.
- ~~HOLD docs-only pushes to `main`~~ **LIFTED 2026-09-16 ~07:44 MDT** after [#1374](https://github.com/itchyshin/drmTMB/pull/1374) @ `f7b40b75a` (`receipt-staleness` run `35103746783` **green**). Main had re-staled after Wave A tail merges; [#1372](https://github.com/itchyshin/drmTMB/pull/1372) @ `dd937ac3` was the earlier fix. Coord/docs **push to `main` OK**. **B1 / any `R/` merge:** regenerate `docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json` LAST on the branch (or land a receipt follow-up immediately after merge — do not leave `main` red).
- DEFER / PROTECTED: Md-K/Julia, S6, A-5/A-6, Md-L, Eq-4, variance-ratio interval design, S3 option B, Gaussian latent `mi()` missing-row weighting, raw-predictor sigma-clamp consumers, and M3 sqrt(n) tolerance design.

## Live Status

Updated: 2026-09-16 ~10:43 MDT (**B2 #1375 @ `05c28c1bb`** — `R/bf.R` name-restore for skeleton regression; prior D-263 **ACCEPT stale**; await fresh D-263 + green CI).

- **`main` tip:** `44b0e3b67` (coord); tip-identity last **green** @ `e169d7a76` (run `35111843393`). Docs-only coord pushes OK; no receipt PR unless `R/` on `main` moves.
- **Receipt gate:** post-#1373 `receipt-staleness` **green** (run `35111843393` @ `f822a34da`). Prior [#1374](https://github.com/itchyshin/drmTMB/pull/1374) @ `f7b40b75a` (run `35103746783`). **B2 `R/` merge:** tip-identity receipt regen **LAST** on branch (or receipt follow-up immediately after merge).
- **Wave A — all MERGED:** A2 [#1369](https://github.com/itchyshin/drmTMB/pull/1369) @ `2c15ae63e`; A3 [#1367](https://github.com/itchyshin/drmTMB/pull/1367) @ `e6ca0dc8e`; A1 [#1368](https://github.com/itchyshin/drmTMB/pull/1368) @ `f8745242`; D-263 audits [#1370](https://github.com/itchyshin/drmTMB/pull/1370) @ `3dcd7ab1`; Md-J map [#1371](https://github.com/itchyshin/drmTMB/pull/1371) @ `6580d74b1`.
- **Wave B1 — PR [#1373](https://github.com/itchyshin/drmTMB/pull/1373) MERGED** @ `f822a34da` (2026-09-16; Shinichi/Grace). Gauss lease `gauss:dinnage-arc3-B1` should **release** when idle.
- **Wave B2 — PR [#1375](https://github.com/itchyshin/drmTMB/pull/1375) OPEN** @ `05c28c1bb` (`cursor/dinnage-arc3-b2-surfaces-20260916`). **`R/bf.R` name-restore** on tip (skeleton `drm_formula` regression; prior CI RED @ `296a1f763` **stale**). Local **47/47** reported. **D-263:** prior **ACCEPT stale** (incl. @ `296a1f763`); **awaiting fresh D-263 + settled green CI** (run [`35123724324`](https://github.com/itchyshin/drmTMB/actions/runs/35123724324) @ `05c28c1bb` **in flight**). **P0:** C17 inert re-cert on earlier tip (`mc-0568` / C17+C14 @ `c493fc0bb`). **Not MERGE-READY** — agents **do not merge #1375** until fresh D-263 and CI green; tip-identity receipt **LAST** on `R/` before merge. Prefer **Composer** / Grace watchers. Active lease: `gauss:dinnage-arc3-B2` (release when idle).
- **A4 record:** DONE (#1351).
- **Wave B docs-only [#1371](https://github.com/itchyshin/drmTMB/pull/1371): MERGED** — does not gate B1/B2 implementation.
- **Jason / landscape:** [`LOOP/drm-jl-followups.md`](LOOP/drm-jl-followups.md) on `main` (checkpoint cross-link); do not open DRM.jl issues from this Cursor slice.

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
- Coordinator may **push coordination docs** to `main` (board, CLAIMS, checkpoint, check-log). Implementation branches: no merge to `main`, CRAN submission, tags, releases, or email unless Shinichi or a Grace watcher authorizes.
- Do not edit foreign specialist files unless integrating an explicit returned result and holding the lease.
- Each implementation branch must run its own focused tests and C17 recertification when touching `R/methods.R` or `R/drmTMB.R`. Any `R/` merge must keep `receipt-staleness` green (regenerate tip-identity receipt LAST).
