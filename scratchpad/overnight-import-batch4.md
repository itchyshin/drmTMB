# Overnight import batch 4 — interval-truth audit

Lane: `/Users/z3437171/local-scratch/lanes/drmTMB-interval-truth-audit`
(branch `claude/lane-overnight-0815`), read-only sweep, cells: mc-0533, mc-0535,
mc-0559, mc-0560, mc-0561, mc-0562, mc-0623, mc-0625, mc-0627, mc-0657, mc-0663.

All 11 cells: `evidence_tier=interval_feasible`, `location_checked=unchecked`,
`tranche_id=legacy-census`, `primary_evidence_id=ev-<cell>-legacy`. Confirmed
against `docs/dev-log/dashboard/capability-ledger/cells.tsv`.

Cross-check against the prior Wave-1 classification (commit `9ee8c9fc4`,
`scratchpad/uncovered-cohort-A.md` in that commit) puts all 11 cells in
**class (c) "legacy import, no run"** — i.e. Wave 1 also found no stronger
instrument for any of these 11. Query used:
`git show 9ee8c9fc4:scratchpad/uncovered-cohort-A.md | grep -E "mc-0533|mc-0535|mc-0559|mc-0560|mc-0561|mc-0562|mc-0623|mc-0625|mc-0627|mc-0657|mc-0663"`.

## Summary table

| cell | family/dpar | Q1 campaign | Q2 cited test today | Verdict |
| --- | --- | --- | --- | --- |
| mc-0533 | tweedie / sigma | none found | asserts shape (indirect proxy) | **B** |
| mc-0535 | tweedie / nu | none found | asserts shape (indirect proxy) | **B** |
| mc-0559 | zero_one_beta / mu | none found | labels/status only | **C** |
| mc-0560 | zero_one_beta / sigma | none found | labels/status only | **C** |
| mc-0561 | zero_one_beta / zoi | none found | labels/status only | **C** |
| mc-0562 | zero_one_beta / coi | none found | labels/status only | **C** |
| mc-0623 | zi_nbinom2 / mu | none found (mc-* not wired) | asserts finite+ordered directly | **B** |
| mc-0625 | zi_nbinom2 / sigma | none found (mc-* not wired) | asserts finite+ordered directly | **B** |
| mc-0627 | zi_nbinom2 / zi | none found (mc-* not wired) | asserts finite+ordered directly | **B** |
| mc-0657 | zi_poisson / mu | none found (mc-* not wired) | asserts finite+ordered directly | **B** |
| mc-0663 | zi_poisson / zi | none found (mc-* not wired) | asserts finite+ordered directly | **B** |

## Cross-cutting Q1 finding: an adjacent-axis campaign exists, but it is NOT this
route and is explicitly NOT wired to any mc-* cell

`docs/dev-log/simulation-artifacts/2026-08-11-g5-authenticated-panel/panel-cell-summary.csv`
(added by commit `946ae7383`, "promote(missing-response): seven routes G3 -> G5
on the authenticated campaign") reports real empirical Wald/profile coverage
for `fixef:mu`, `fixef:sigma`, `fixef:nu`, `fixef:zi`, `fixef:zoi`, `fixef:coi`
across all four families in this batch (tweedie, zero_one_beta, zi_nbinom2,
zi_poisson), at 1200 attempts/cell, coverage ~0.93-0.965. **This is the
`missing_response` axis (25% MCAR on the response, ML, profile-likelihood
CIs), not the plain fixed-effect `model_surface` route our 11 cells claim.**
The commit message states explicitly: "exactly seven rows changed tier, zero
mc-*/as-* rows touched" — confirming this campaign is bound to `mr-*` cell ids
(`docs/dev-log/dashboard/parity-triage.tsv` shows `mr-zi-poisson`,
`mr-zi-nbinom2`, `mr-zero-one-beta`, `mr-tweedie`, all `blocked_no_comparator`,
axis `response_missingness`/`route_contract` — a different row family from our
`mc-*` cells). Of the four families, only `zero_one_beta` and `zi_poisson` were
actually promoted (`gaussian, biv_gaussian, gamma, beta_binomial, binomial,
zero_one_beta, zi_poisson`); `tweedie` and `zi_nbinom2` explicitly **stayed at
G3** ("their campaign failures are interval AVAILABILITY, not calibration").
Given the different axis and non-identical route (missingness added), this is
recorded as informative-but-not-applicable, not as verdict (A) evidence for
any of the 11 cells.

Queries run:
- `grep -ril "tweedie" docs/dev-log/simulation-artifacts/` and same for
  `zero.one.beta`, `zi.nbinom2`, `zi.poisson` (most hits are noise —
  `SOURCE-MANIFEST.sha256` files list every repo path, or slope/RE-SD arcs:
  `2026-07-12-arc2b-slope-recovery` (mu random SLOPE, not fixed),
  `2026-07-12-dg3-power-arm(-gated)` (goodness-of-fit type-I/power, not CI
  coverage), `2026-07-19-arc4c-mu-slope-coverage` (mu random SLOPE).
- `git log --all --oneline -S"<cell_id>"` for each of the 11 cells (see per-cell
  sections).
- `grep -rl "<family>" docs/dev-log/dashboard/*.tsv | xargs grep -l "coverage"`
  → only `parity-triage.tsv` hits, all for different cell ids
  (`mc-0538`/`mc-0567` random-intercept SD cells and `mr-*` response-missingness
  cells), explicitly "No CI/coverage or bias claim" for `mc-0538`.
- `grep -l "<family>" docs/dev-log/interval-campaign-bindings/*.tsv` → only
  `mc-0538`/`mc-0567` (`sd:mu:(1|id)` random-intercept targets), not our cells.
- `docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot/README.md`
  and `2026-08-04-d117-10group-profile-gate/VERDICT.md` and
  `2026-06-18-support-floor-diagnostic/README.md` — all real fixed-effect
  interval work, but for `binomial/poisson/beta/nbinom2` (pilot) or explicitly
  disclaiming zero-one-beta coverage ("does not promote ... interval
  coverage"; D-117 "This measured the A1 scalar Gaussian corner only ... NOT
  discharged for Prong B (count, zero-one-beta)").
- `grep -n "mc-05[3-6][0-9]\|mc-062[3-7]\|mc-065[7-9]\|mc-066[0-3]" docs/dev-log/check-log.md`
  → no hits for any of the 11 cell ids.

## Per-cell detail

### mc-0533 — tweedie / sigma / fixed

- **Q1.** No coverage campaign for tweedie fixed-effect intervals. Only
  infrastructure exists: `inst/sim/fit/sim_summarise_tweedie_fixed_effect.R`,
  `inst/sim/run/sim_{run,write,summary}_tweedie_fixed_effect*.R`, and 5
  after-task notes (`docs/dev-log/after-task/2026-05-28-phase18-tweedie-*`)
  documenting the infra build, not a run at scale. `find . -iname
  "*tweedie-fixed-effect*"` returns only source/test files, no
  `simulation-artifacts/` results table. `git log --all --oneline
  -S"mc-0533"` returns only Wave-1/lane-audit commits, missing-response
  formula-inventory commits, and Arc-4a/4c coverage commits (mu-SLOPE, a
  different effect_type) — no campaign commit.
- **Q2.** Cited: `tests/testthat/test-tweedie-location-scale.R:27-56` and
  `tests/testthat/test-phase18-tweedie-fixed-effect.R:53-92`.
  - `test-tweedie-location-scale.R:27-56` (current, unchanged content) is
    point-recovery only: `expect_lt(max(abs(coef(fit, "sigma") -
    sim$beta_sigma)), 0.15)` (line 45) and `expect_identical(fit$uncertainty$status,
    "ok")` (line 42, sdreport success, not a CI). **No `confint()` call in this
    range.**
  - `test-phase18-tweedie-fixed-effect.R:53-92` (current lines 56-97 for the
    same `test_that` block — 3-line drift, same content): non-vacuous
    (`expect_equal(nrow(summary$wald_intervals), 5L)`, line 75) and asserts
    `expect_true(all(summary$wald_intervals$interval_status == "ok"))` (line
    83), with `sigma:(Intercept)`/`sigma:z` among the 5 named rows (lines
    89-90). `interval_status` is set by `phase18_add_wald_intervals()`
    (`inst/sim/R/sim_uncertainty.R:58-110`): `ok <- is.finite(estimate) &
    is.finite(se) & se >= 0`, then `lower/upper <- estimate -+ z*se`. This
    algebraically guarantees finite `lower`/`upper` and `lower <= upper`
    whenever `interval_status == "ok"`, but it is an indirect proxy through a
    smoke-test summary object, not a literal `expect_true(is.finite(ci$lower))`
    on the package's own `confint(fit)` output, and it only guarantees
    non-strict ordering (`lower <= upper`, equal only if `se == 0`, which does
    not occur with continuous covariates but is not itself asserted).
- **Verdict: (B) SHAPE-JUSTIFIED**, with the above caveat that the shape
  guarantee is algebraic/indirect rather than a direct `is.finite`/`<`
  assertion on `confint()`'s own columns.

### mc-0535 — tweedie / nu / fixed

- **Q1.** Same as mc-0533 — no campaign found; same negative-query set.
  `git log --all --oneline -S"mc-0535"` additionally turns up
  `a9c8849e5`/`aa237a288` (0.6 dev-arc handover docs) — read, not relevant
  (submission-parking notes, no tweedie-nu coverage content).
- **Q2.** Cited: `tests/testthat/test-phase18-tweedie-fixed-effect.R:83-90`.
  Current block (same `test_that`, lines 56-97): line 83 is exactly
  `expect_true(all(summary$wald_intervals$interval_status == "ok"))`, and the
  `nu:(Intercept)` row is asserted present at line 91 (1 line past the cited
  end but the same `test_that`/same `wald_intervals` object). Same algebraic
  proxy and same caveat as mc-0533.
- **Verdict: (B) SHAPE-JUSTIFIED**, same caveat as mc-0533.

### mc-0559 — zero_one_beta / mu / fixed

- **Q1.** No coverage campaign. `find . -iname "*zero-one-beta-fixed-effect*"`
  returns only infra (`inst/sim/{fit,dgp,run}/*zero_one_beta_fixed_effect*`,
  `tests/testthat/test-phase18-zero-one-beta-fixed-effect.R`, 2 after-task
  notes describing the infra build) — no results table under
  `simulation-artifacts/`. `git log --all --oneline -S"mc-0559"` returns only
  Wave-1/lane-audit and missing-response-formula-inventory commits, plus
  Arc-4a/4c (mu-slope, different effect_type) — no campaign commit.
- **Q2.** Ledger cites `tests/testthat/test-zero-one-beta.R:48-107`. **That
  range no longer contains a test** — it is now DGP/helper functions
  (`new_zero_one_beta_data()` lines 1-28, `dzoibeta_drm()` lines 30-48,
  `softclamp_logsigma_drm()` lines 50-57, phylo/animal/relmat/spatial data
  generators lines 59-135+). `grep -n "^test_that"
  tests/testthat/test-zero-one-beta.R` shows the first `test_that` in the
  file is at line 547 (a phylo gate test), nowhere near the cited range.
  The genuine base fixed-effect recovery test is found by content search
  (`grep -n "new_zero_one_beta_data("`) at **lines 1794-1853**
  (`test_that("drmTMB fits fixed-effect zero-one beta models", ...)`): it
  builds `ci <- confint(fit)` (line 1825), asserts `ci$parm` and
  `ci$tmb_parameter` labels for all four dpars (mu/sigma/zoi/coi, lines
  1826-1851), then only `expect_true(all(ci$conf.status == "wald"))` (line
  1852). **No `is.finite(ci$lower/upper))` or `ci$lower < ci$upper` assertion
  anywhere in this test_that block.** This is exactly the "label-only
  confint site" defect class the 2026-08-15 commit `7c62279e5` fixed at 7
  other sites — this site was not one of the 14 cells that commit touched.
  - Note (not part of the verdict): an *uncited* sibling test,
    `tests/testthat/test-phase18-zero-one-beta-fixed-effect.R:40-77`, does
    assert the same algebraic `interval_status == "ok"` proxy described for
    tweedie above, non-vacuously (`nrow(summary$wald_intervals) == 8L`,
    covering mu/sigma/zoi/coi in one summary), but it is a single `n=420`
    smoke realization, not wired into this ledger row's citation, and not a
    coverage campaign.
- **Verdict: (C) NOT EVEN SHAPE** — per the ledger's own citation site, once
  corrected for line drift. No campaign, and the actual test at that site
  asserts labels/status only.

### mc-0560 / mc-0561 / mc-0562 — zero_one_beta / sigma, zoi, coi / fixed

- **Q1.** Identical negative result and identical query set to mc-0559 (same
  family route). `git log --all --oneline -S"mc-0560"` / `-S"mc-0561"` /
  `-S"mc-0562"` each additionally show `36ec0bb8d` ("render location_checked
  on the reader surfaces" — ledger-column plumbing, not evidence) beside the
  same Wave-1/lane-audit/missing-response/Arc-4a-4c set. No campaign commit
  for any of the three.
- **Q2.** All three cells cite the exact same
  `tests/testthat/test-zero-one-beta.R:48-107` range as mc-0559, which is the
  same drifted citation pointing at data-generator code. The real test block
  is the same one found for mc-0559 (lines 1794-1853): `ci$parm` includes
  `fixef:sigma:(Intercept)`/`fixef:sigma:z` (mc-0560),
  `fixef:zoi:(Intercept)`/`fixef:zoi:w` (mc-0561), and
  `fixef:coi:(Intercept)`/`fixef:coi:v` (mc-0562) — all asserted for label
  only (`ci$conf.status == "wald"` at line 1852), with no endpoint check.
- **Verdict (all three): (C) NOT EVEN SHAPE** — same basis as mc-0559.

### mc-0623 — zi_nbinom2 / mu / fixed

- **Q1.** No campaign wired to this cell id. `git log --all --oneline
  -S"mc-0623"` shows `7c62279e5` ("test: assert finite ordered endpoints at
  the 14 label-only confint sites", 2026-08-15) — the endpoint-assertion
  commit referenced in the task brief — plus the usual
  Wave-1/lane-audit/missing-response/Arc-4a commits. The only *empirical
  coverage* artifact touching `zi_nbinom2` at all is the cross-axis
  `2026-08-11-g5-authenticated-panel` file described above (missing-response,
  not wired to `mc-*`, and `zi_nbinom2` explicitly stayed at G3 there, not
  promoted).
- **Q2.** Cited: `tests/testthat/test-zi-nbinom2.R:31-100`. Current content
  (read lines 31-104): the `test_that` block builds `ci <- confint(fit)` at
  line 73, asserts `ci$parm`/`ci$tmb_parameter` labels (lines 74-99), then
  `expect_true(all(ci$conf.status == "wald"))` (line 100 — matching the
  cited end-line), **followed immediately by**
  `expect_true(all(is.finite(ci$lower)))` (line 101),
  `expect_true(all(is.finite(ci$upper)))` (line 102), and
  `expect_true(all(ci$lower < ci$upper))` (line 103) — three lines the
  ledger's numeric citation (ending at 100) does not literally span, even
  though they are the immediate next statements in the same `test_that`
  block that closes at line 104. Commit `7c62279e5`'s message claims ranges
  were extended for "the 5 audited cells whose cited range ended before the
  insertion point" — this cell's citation was evidently not among those 5,
  so the citation is stale by 3-4 lines but the same test genuinely contains
  the assertions.
- **Verdict: (B) SHAPE-JUSTIFIED**, with the citation-drift caveat above
  (same test_that block, assertions 1-3 lines past the cited numeric range).

### mc-0625 — zi_nbinom2 / sigma / fixed; mc-0627 — zi_nbinom2 / zi / fixed

- **Q1.** Same as mc-0623 (`git log --all --oneline -S"mc-0625"` /
  `-S"mc-0627"` return the identical commit set including `7c62279e5`). No
  campaign wired to either cell id.
- **Q2.** Both cite `tests/testthat/test-zi-nbinom2.R:31-100` — the same
  `test_that` block as mc-0623. `ci$parm` includes
  `fixef:sigma:(Intercept)`/`fixef:sigma:z` (mc-0625) and
  `fixef:zi:(Intercept)`/`fixef:zi:w`/`fixef:zi:habitatopen` (mc-0627), both
  covered by the same lines 101-103 finite/ordered assertions (all `ci$lower`
  and `ci$upper` are checked with `all()` across every row, not per-dpar).
- **Verdict (both): (B) SHAPE-JUSTIFIED**, same citation-drift caveat as
  mc-0623.

### mc-0657 — zi_poisson / mu / fixed; mc-0663 — zi_poisson / zi / fixed

- **Q1.** `git log --all --oneline -S"mc-0657"` and `-S"mc-0663"` both return
  the same set as the zi_nbinom2 cells (`36ec0bb8d`, `7c62279e5`,
  Wave-1/lane-audit, missing-response formula-inventory, Arc-4a). No campaign
  wired to either cell id. `zi_poisson` *was* one of the seven routes
  promoted in the missing-response `g5-authenticated-panel` (2026-08-11), but
  that is the 25%-MCAR `mr-zi-poisson` route_contract cell, not `mc-0657`/
  `mc-0663` — the commit explicitly states "zero mc-*/as-* rows touched."
- **Q2.** Cited: `tests/testthat/test-zi-poisson.R:18-74`. Current content
  (read lines 18-74): `ci <- confint(fit)` at line 54, `ci$parm`/
  `ci$tmb_parameter` labels (lines 55-69), `ci$conf.status == "wald"` (line
  70), `expect_true(all(is.finite(ci$lower)))` (line 71),
  `expect_true(all(is.finite(ci$upper)))` (line 72), and
  `expect_true(all(ci$lower < ci$upper))` (line 73), with the `test_that`
  closing brace at line 74 — the cited range fully and exactly contains the
  finite/ordered assertions this time (no drift). `ci$parm` includes
  `fixef:mu:(Intercept)`/`fixef:mu:x`/`fixef:mu:habitatopen` (mc-0657) and
  `fixef:zi:(Intercept)`/`fixef:zi:z`/`fixef:zi:habitatopen` (mc-0663), both
  covered by the same `all()` assertions.
- **Verdict (both): (B) SHAPE-JUSTIFIED** — cleanest case in the batch, no
  citation drift.
