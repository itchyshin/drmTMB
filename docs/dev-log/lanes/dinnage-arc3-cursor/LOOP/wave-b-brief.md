# Wave B dispatch brief (HOLD until A2 + A3 on main)

Status: **HOLD** as of **2026-09-16 ~05:50 MDT**. **#1369 MERGED** on `main` @ `2c15ae63e`. Unlock Wave B **code** only after **#1367** merges (A1 #1368 and audit **#1370** may merge in queue; B still waits on A3).

Do **not** start B implementation while A2/A3 are open. Agents must **not** merge any PR.

## Preconditions (verify before spawn)

```sh
gh pr view 1369 1367 --json number,state,mergedAt
git fetch origin main && git rev-parse origin/main
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/local-scratch/lanes/drmTMB-dinnage-arc3-cursor"
```

Base each B worktree on **`origin/main` after both merges**, not the dirty Dropbox foreground checkout.

## After unlock — parent dispatch (copy-paste)

Record merge SHAs, set Wave B **UNLOCKED** in `CLAIMS.md` + coordination board tip, then:

```sh
# B1 worktree (Gauss leads; Curie tests in same PR branch or paired review worktree)
~/shinichi-brain/tools/lane_launch.sh "/Users/z3437171/Dropbox/Github Local/drmTMB" dinnage-arc3-B1
cd "$(~/shinichi-brain/tools/lane_launch.sh --path dinnage-arc3-B1 2>/dev/null || echo /Users/z3437171/local-scratch/drmTMB-arc3-gauss)"
git fetch origin main && git checkout -B cursor/dinnage-arc3-b1-check-20260916 origin/main

# B2 after B1 PR opened (or parallel only if file lease clean — default sequential)
~/shinichi-brain/tools/lane_launch.sh "/Users/z3437171/Dropbox/Github Local/drmTMB" dinnage-arc3-B2
```

Spawn **two subagents** with the prompts below (fresh context each; D-263 reviewer is a third, later).

---

## B1 check.R PR (Gauss + Curie)

**Issues:** #1319 Md-B, #1356 UX-1, #1337 A-7, #1342 Mi-4, #1333 A-3, #1327 Md-J.

**Owns:** `R/check.R`, `R/profile.R` (Md-J / `conf.status`), `R/methods.R` only if convergence API requires it (C17 **last** if `R/methods.R` edits), `tests/testthat/test-dinnage-audit-wave4b1.R` (new, wave1 style), `NEWS.md`, design note only for Md-J g-question:

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

**Lease (before edit):**

```sh
LANE_ID='gauss:dinnage-arc3-B1' ~/shinichi-brain/tools/lane_lease.sh --claim drmTMB --paths 'R/check.R,R/profile.R,tests/testthat/test-dinnage-audit-wave4b1.R,NEWS.md,docs/design/276-phylo-bias-correction-denominator.md'
```

### Agent prompt — Gauss (`tmb_engineer`) B1

```
Full Repository Path: /Users/z3437171/local-scratch/lanes/drmTMB-dinnage-arc3-B1 (or lane_launch path)
Lane: dinnage-arc3-B1 · Wave B slice 1 · base = origin/main AFTER #1369+#1367 merged

Implement Dinnage audit Wave B1 in one PR branch. Issues: #1319 #1356 #1337 #1342 #1333 #1327.
Read docs/dev-log/lanes/dinnage-arc3-cursor/LOOP/wave-b-brief.md and CLAIMS.md on main.
Own only: R/check.R, R/profile.R, tests/testthat/test-dinnage-audit-wave4b1.R, NEWS.md,
docs/design/276-phylo-bias-correction-denominator.md (Md-J g-denominator question only).
If R/methods.R is required for convergence_status(), edit LAST and run tools/recertify-c17.py LAST.
Follow binding decision table in wave-b-brief (notes not warnings for B1 thresholds).
One commit per issue with message fix(check): … (Dinnage audit …, #NNNN).
Do not merge. Open PR when CI-ready; builder must not self-ACCEPT D-263.
Do not touch R/julia-bridge.R or foreign lanes.
```

### Agent prompt — Curie (`simulation_tester`) B1

```
Full Repository Path: same B1 worktree as Gauss (coordinate file ownership via lane lease)
Lane: dinnage-arc3-B1 · simulation tests for Wave B1 check rows

Add/extend tests/testthat/test-dinnage-audit-wave4b1.R covering #1319 #1356 #1337 #1342 #1333 #1327
acceptance from wave-b-brief (red-first where behavior is new). Match style of test-dinnage-audit-wave4a*.R.
Do not change R/check.R without Gauss lease overlap — pair commits on shared branch.
No merge. Flag MERGE-READY only after devtools::test() narrow + export check receipt.
```

---

## B2 surfaces PR (Gauss/Boole + Curie)

**Issues:** #1332 A-2, #1360 UX-5, #1353 Mi-15, #1355 Mi-bundle, #1316 S7.

**Owns:** `R/missing-data.R`, `R/parse-formula.R` (or formula entry points per grep), `R/methods.R` / confint helpers as needed, `R/control.R` (S7 docs), `tests/testthat/test-dinnage-audit-wave4b2.R`, `NEWS.md`. C17 if `R/methods.R` or `R/drmTMB.R` touched.

**Binding decisions:**

| Issue | Fix |
| --- | --- |
| #1332 | `miss_control(predictor = "fail")` errors on NA predictors |
| #1360 | `bf()` / `drm_formula()` accept formula in a variable; literal-expression error otherwise |
| #1353 | Keep 13-column frame; add `as.matrix.drm_confint()` → 2-col matrix like `stats::confint()` |
| #1355 | Bundle items 2–7; backfill `{.i}` hint to all 17 unsupported-parameter branches |
| #1316 | Document joint sigma+zi local-optimum + `multi_start` in `?drm_control`; no default change |

**Lease:**

```sh
LANE_ID='gauss:dinnage-arc3-B2' ~/shinichi-brain/tools/lane_lease.sh --claim drmTMB --paths 'R/missing-data.R,R/parse-formula.R,R/control.R,tests/testthat/test-dinnage-audit-wave4b2.R,NEWS.md'
```

### Agent prompt — Gauss + Boole B2

```
Full Repository Path: B2 worktree from lane_launch dinnage-arc3-B2 · base = origin/main after B1 base (or latest main)
Implement Wave B2: #1332 #1360 #1353 #1355 #1316 per docs/dev-log/lanes/dinnage-arc3-cursor/LOOP/wave-b-brief.md.
Own: R/missing-data.R, R/parse-formula.R, R/control.R, confint/matrix helpers in R/methods.R if needed (C17 LAST).
Boole: verify bf()/drm_formula() UX matches handover G0 for #1360.
One commit per issue; NEWS bullets credit Russell. No merge. Independent D-263 review before MERGE-READY.
```

### Agent prompt — Curie B2

```
Full Repository Path: B2 worktree · tests/testthat/test-dinnage-audit-wave4b2.R
Simulation/regression tests for #1332 #1360 #1353 #1355; #1316 may be docs-only with a lightweight expectation test if any.
Red-first; wave1 test style. Coordinate with Gauss on shared branch. No merge.
```

---

## Per-PR discipline (same as Wave A)

1. Red test → fix → green; one commit per finding: `fix(<area>): … (Dinnage audit <id>, #<issue>)`.
2. `NEWS.md` bullet with Russell credit line.
3. `NOT_CRAN=false R CMD check --as-cran --no-manual` on `git archive` export before push.
4. Independent D-263 review file: `docs/dev-log/audits/2026-09-<dd>-dinnage-arc3-b<1|2>-review.md` from a **fresh** reviewer context.
5. Open PR; tell Shinichi when MERGE-READY. **Agents do not merge.**

## Wave C

**HOLD** until Wave B lands. See handover § Wave C (#1339, #1340). Do not unlock from this brief.
