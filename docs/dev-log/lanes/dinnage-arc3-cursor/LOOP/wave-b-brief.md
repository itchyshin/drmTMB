# Wave B dispatch brief (HOLD until A2 + A3 on main)

Status: **HOLD** as of 2026-09-15 21:00 MDT. Unlock only after Shinichi merges **#1369** and **#1367** (A1 #1368 may merge anytime; B still waits on A2+A3).

Do **not** start B implementation while A2/A3 are open. Agents must **not** merge any PR.

## Preconditions (verify before spawn)

```sh
gh pr view 1369 --json state,mergedAt
gh pr view 1367 --json state,mergedAt
git fetch origin main && git rev-parse origin/main
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/local-scratch/lanes/drmTMB-dinnage-arc3-cursor"
```

Base each B worktree on **`origin/main` after both merges**, not the dirty foreground checkout.

## B1 check.R PR (Gauss + Curie)

**Issues:** #1319 Md-B, #1356 UX-1, #1337 A-7, #1342 Mi-4, #1333 A-3, #1327 Md-J.

**Owns:** `R/check.R`, `R/profile.R` (Md-J / `conf.status`), `R/methods.R` if convergence API touches methods (C17 **last** if `R/methods.R` edits), `tests/testthat/test-dinnage-audit-wave4b*.R` (new, copy wave1 style), `NEWS.md`, design note only for Md-J g-question:

- `docs/design/276-phylo-bias-correction-denominator.md` (question + options, no answer)

**Binding decisions (handover G0):**

| Issue | Fix |
| --- | --- |
| #1319 | SE-inflation ratio reference = median over non-flagged subset |
| #1356 | `[.drm_check` keeps class; print shows "X of N checks shown" when subset |
| #1337 | New row: obs per estimated parameter; **note** (not warning) if below 10 |
| #1342 | New row: pairwise abs(r) > 0.99 among FE design columns; note only |
| #1333 | Keep `is_converged()` logical; add `convergence_status()` + `check_drm()` row; `multi_start` cannot clear degenerate |
| #1327 | Add `wald_bias_corrected` to `conf.status`; g-denominator → design 276 doc only |

Thresholds in B1 are **notes**, never warnings, until simulation says otherwise.

**Launch:**

```sh
~/shinichi-brain/tools/lane_launch.sh "/Users/z3437171/Dropbox/Github Local/drmTMB" dinnage-arc3-B1
LANE_ID='gauss:dinnage-arc3-B1' ~/shinichi-brain/tools/lane_lease.sh --claim drmTMB --paths 'R/check.R,R/profile.R,tests/testthat/test-dinnage-audit-wave4b1.R,NEWS.md'
```

## B2 surfaces PR (Gauss/Boole + Curie)

**Issues:** #1332 A-2, #1360 UX-5, #1353 Mi-15, #1355 Mi-bundle, #1316 S7.

**Owns:** `R/missing-data.R`, `R/parse-formula.R` (or formula entry points per grep), `R/methods.R` / confint helpers as needed, `R/control.R` (S7 docs), `tests/`, `NEWS.md`. C17 if `R/methods.R` or `R/drmTMB.R` touched.

**Binding decisions:**

| Issue | Fix |
| --- | --- |
| #1332 | `miss_control(predictor = "fail")` errors on NA predictors |
| #1360 | `bf()` / `drm_formula()` accept formula in a variable; literal-expression error otherwise |
| #1353 | Keep 13-column frame; add `as.matrix.drm_confint()` → 2-col matrix like `stats::confint()` |
| #1355 | Bundle items 2–7; backfill `{.i}` hint to all 17 unsupported-parameter branches |
| #1316 | Document joint sigma+zi local-optimum + `multi_start` in `?drm_control`; no default change |

**Launch:**

```sh
~/shinichi-brain/tools/lane_launch.sh "/Users/z3437171/Dropbox/Github Local/drmTMB" dinnage-arc3-B2
```

## Per-PR discipline (same as Wave A)

1. Red test → fix → green; one commit per finding: `fix(<area>): … (Dinnage audit <id>, #<issue>)`.
2. `NEWS.md` bullet with Russell credit line.
3. `NOT_CRAN=false R CMD check --as-cran --no-manual` on `git archive` export before push.
4. Independent D-263 review file: `docs/dev-log/audits/2026-09-<dd>-dinnage-arc3-b<1|2>-review.md` from a **fresh** reviewer context.
5. Open PR; tell Shinichi when MERGE-READY. **Agents do not merge.**

## Wave C

**HOLD** until Wave B lands. See handover § Wave C (#1339, #1340). Do not unlock from this brief.
