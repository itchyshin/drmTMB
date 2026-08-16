# Overnight import batch 3 — interval-truth audit

Lane: `/Users/z3437171/local-scratch/lanes/drmTMB-interval-truth-audit` @ branch
`claude/lane-overnight-0815`. Read-only audit; this file is the only write.

Cells audited: mc-0456, mc-0458, mc-0484, mc-0485, mc-0486, mc-0487, mc-0488,
mc-0508, mc-0509, mc-0510, mc-0531. All 11 rows come from
`docs/dev-log/dashboard/capability-ledger/cells.tsv` (identical text in
`evidence.tsv` under `ev-<cell>-legacy`), `evidence_tier = interval_feasible`,
`location_checked = unchecked`, `legacy_evidence_source` citing only source +
tests (2026-07-11 MR-T0 migration import, commit `095409c0`).

## Headline finding

**Today's commit `7c62279e5` ("test: assert finite ordered endpoints at the 14
label-only confint sites", author Shinichi, 2026-08-15 18:27:30, Co-Authored-By
Claude Opus 5) is itself load-bearing evidence for several of these cells** —
and for one cell (mc-0486) its own line-citation repair is misleading: the
extended range spans into an unrelated adjacent test, not the cited cell's own
confint call. Full detail below.

**A second undocumented campaign was found for the student-shape family**:
`docs/dev-log/simulation-artifacts/2026-06-19-student-nu-wald-calibration-diagnostic/`
runs 200 fits (100 reps × 2 cells) and reports real Wald coverage for `mu`,
`sigma`, **and** `nu` jointly — but it is referenced nowhere in the ledger for
mc-0484, mc-0485, or mc-0486. Verdict (A) for all three.

---

## mc-0456 — skew_normal, mu, fixed

**Q1 (campaign).** YES, already partially wired. `docs/dev-log/simulation-artifacts/2026-06-17-skew-normal-fixed-effect-pilot/`
(150 fits, 6 conditions × 25 reps) is *already cited* in
`evidence.tsv:499`/`cells.tsv` legacy_evidence_source. Its
`tables/skew-normal-fe-wald-coverage.csv` has `mu:(Intercept)` and `mu:x` rows
for all 6 conditions, e.g. `skew_normal_fixed_effect_001,"mu:(Intercept)",25,25,24,0.96,...`
through `skew_normal_fixed_effect_006,"mu:x",25,23,0.92,...` — every row has
`n_interval == n_replicate == 25` (all 25 Wald CIs per cell were finite/usable),
coverage range 0.88–1.00 at nominal 0.70. README (`.../README.md:74-78`)
explicitly disclaims this as *not* calibrated-interval or coverage-gate
evidence, but it does report real, finite, well-formed intervals.
Query: `grep -rl "mc-0456" docs/dev-log/**` (only scratchpad wave-classification
files + this ledger); `git log --all --oneline -S"mc-0456"` → only lane/import
commits, nothing new.

**Q2 (direct test).** The line range actually cited as "test-confirmed" for mu
(`tests/testthat/test-skew-normal-location-scale.R:282-357`) is the **nu**
block only (`test_that("skew-normal fixed-effect shape intervals are
visible"...)`, asserts `is.finite(ci$lower)`/`is.finite(ci$upper)` at lines
342-343 for `nu:x`, not mu). No test in the current suite calls
`confint(fit, parm="mu:...")` and asserts finiteness directly
(`grep -rln "skew_normal" tests/testthat/*.R | xargs grep -n "confint(fit"` →
only nu:x and unparametrized `confint(fit)` warning checks). The ledger's own
text is honest about this: "directly test-confirmed for the sibling nu dpar
... same code path applies to mu" is an **inference**, not a direct test.
`tests/testthat/test-phase18-skew-normal-fixed-effect.R:154-155` does assert
`is.finite(first$summary$estimate)` and `is.finite(first$summary$std.error)`
for all 6 parameters including `mu:(Intercept)`/`mu:x` — ingredients of a
Wald CI, not the CI itself.

**Verdict: (B) SHAPE-JUSTIFIED** — not via the cited "test-confirmed for nu,
same code path" claim (that's inference), but via the already-cited campaign
CSV, which computed and returned genuinely finite, ordered mu Wald intervals
for 150/150 replicates. Flag: the ledger's own "directly test-confirmed"
language for mu is not accurate; the real justification is the campaign, not
the nu test.

---

## mc-0458 — skew_normal, sigma, fixed

Same basis as mc-0456. `skew-normal-fe-wald-coverage.csv` sigma rows: e.g.
`skew_normal_fixed_effect_001,"sigma:(Intercept)",25,25,23,0.92` and
`"sigma:z",25,25,21,0.84` through condition 006 `"sigma:z",25,25,25,1.0`; all
`n_interval == 25` (finite/usable) every row, coverage 0.84–1.00 at nominal
0.70. Same campaign already cited in `evidence.tsv:501`. Same gap as mc-0456:
the cited "directly test-confirmed... same code path" (nu block,
`test-skew-normal-location-scale.R:282-357`) does not itself test sigma.
Query: same as mc-0456 (shared cell family/route); `git log --all -S"mc-0458"`
→ only lane/import commits.

**Verdict: (B) SHAPE-JUSTIFIED**, same caveat as mc-0456 (campaign, not the
cited nu test, does the work).

---

## mc-0486 — student, nu, fixed

**Q1 (campaign).** YES, NOT WIRED. `docs/dev-log/simulation-artifacts/2026-06-19-student-nu-wald-calibration-diagnostic/`
— 200 fits (2 cells × 100 reps), Wald-only. Its
`tables/student-nu-wald-diagnostics.csv` reports, per cell:
`student_shape_001 ("low_nu_boundary")`: `nu:(Intercept)` coverage 0.87
(MCSE 0.0336), `nu:w` coverage 0.90 (MCSE 0.030); `student_shape_002
("ordinary_nu")`: `nu:(Intercept)` coverage 0.89 (MCSE 0.0313), `nu:w`
coverage 0.89 (MCSE 0.0313). Not referenced anywhere in
`docs/dev-log/dashboard/capability-ledger/evidence.tsv` for mc-0486
(`grep -n "student-nu-wald-calibration" docs/dev-log/dashboard/capability-ledger/*` →
no hits). A softer supplementary campaign,
`docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-calibration-diagnostic/README.md:55-62`,
reports 50-refit bootstrap "rough coverage" for nu (0.50–0.68), explicitly not
calibration-grade — secondary, also unwired.
Query: `git log --all --oneline -S"mc-0486"` → surfaces
`7c62279e5 test: assert finite ordered endpoints at the 14 label-only confint sites`.

**Q2 (direct test) — mismatch found.** Commit `7c62279e5` (2026-08-15,
message: "docs/design/255 found 14 cells whose entire interval evidence is a
test that calls confint() and asserts ci$parm, ci$tmb_parameter and the
conf.status method string ... but never that the endpoints are finite,
ordered, or present," listing mc-0486 among the 14 fixed cells) edited
`tests/testthat/test-profile-targets.R`. The diff (`git show 7c62279e5 --
tests/testthat/test-profile-targets.R`) adds
`expect_true(all(is.finite(ci$lower)))` / `is.finite(ci$upper)` /
`ci$lower < ci$upper` at lines 1434-1436 — but that insertion lands inside
`test_that("confint bootstrap refits bivariate phylogenetic q2 targets", ...)`
(opens line 1391), an **unrelated bivariate-phylogenetic-q2 bootstrap-plumbing
test**, not the student-nu test. The actual student-nu block,
`test_that("interval inventory covers Student-t fixed-effect shape targets", ...)`
(current lines 1439-1476), still only does:
```
ci <- stats::confint(fit, parm = "nu:x", level = 0.90)
...
expect_equal(ci$parm, "fixef:nu:x")
expect_equal(ci$method, "wald")
expect_equal(ci$conf.status, "wald")
expect_equal(ci$scale, "link")
```
— labels only, exactly the defect class the commit describes, **still
present** for this cell. The ledger's `cells.tsv` row for mc-0486 cites
`tests/testthat/test-profile-targets.R:1408-1448`, a range that was
mechanically extended (per the commit message: "the 5 audited cells whose
cited range ended before the insertion point had their ranges extended to
cover the new assertions") to *overlap* the neighbouring bootstrap test's new
finite/ordered assertions (lines 1434-1436) while only reaching partway into
the actual nu test (1439-1448, which ends mid-block, before line 1472's
label-only assertions). Reading `1408-1448` in isolation gives the false
impression that mc-0486 gained endpoint checks; it did not.
Confirmed via `tests/testthat/test-student-location-scale.R:67-161` (other
citation) too: no confint call there at all, point recovery only.

**Verdict: (A) CAMPAIGN EXISTS, NOT WIRED** —
`docs/dev-log/simulation-artifacts/2026-06-19-student-nu-wald-calibration-diagnostic/tables/student-nu-wald-diagnostics.csv`,
nu coverage 0.87–0.90 (100 reps/cell, MCSE ~0.03), 200 fits total. **Also flag**:
the ledger's citation-line repair from commit `7c62279e5` created a misleading
overlap for this cell — the endpoint assertions it added belong to a different
(bivariate-phylo-q2) test, not to mc-0486's own nu confint call, which remains
label-only.

---

## mc-0484 — student, mu, fixed

**Q1.** Same campaign as mc-0486, same csv, mu rows:
`student_shape_001 mu:(Intercept)` coverage 0.84 (MCSE 0.0367), `mu:x` 0.82
(MCSE 0.0384); `student_shape_002 mu:(Intercept)` 0.86 (MCSE 0.0347), `mu:x`
0.85 (MCSE 0.0357). Not referenced in evidence.tsv for mc-0484.

**Q2.** Cited evidence: `test-student-location-scale.R:67-92` (point recovery
only, no confint — verified by reading lines 67-89, no `confint`/`is.finite`
call) and `test-profile-targets.R:1408-1445` (same mismatched range discussed
under mc-0486 — none of it is a mu confint call; the block that opens at 1439
tests nu, not mu, and even that is label-only). No direct mu-confint-finite
assertion exists anywhere in the current suite for student mu
(`grep -rln "student()" tests/testthat/*.R | xargs grep -n "confint(fit.*mu"`
→ no hits).

**Verdict: (A) CAMPAIGN EXISTS, NOT WIRED** — same csv as mc-0486, mu coverage
0.82–0.86 (100 reps/cell).

---

## mc-0485 — student, sigma, fixed

**Q1.** Same campaign, sigma rows: `student_shape_001 sigma:(Intercept)`
coverage 0.85 (MCSE 0.0357), `sigma:z` 0.84 (MCSE 0.0367);
`student_shape_002 sigma:(Intercept)` 0.81 (MCSE 0.0392), `sigma:z` 0.81
(MCSE 0.0392). Not referenced in evidence.tsv for mc-0485.

**Q2.** Cited evidence `test-student-location-scale.R:67-92` and
`R/profile.R:1301-1330` — the latter is generic dispatch/mapping code, not a
test; no sigma-confint-finite assertion found in the test suite.

**Verdict: (A) CAMPAIGN EXISTS, NOT WIRED** — same csv, sigma coverage
0.81–0.85 (100 reps/cell).

---

## mc-0487 — student, mu, ordinary_re_intercept

**Q1.** No campaign found. `docs/dev-log/simulation-artifacts/` has no
`student`+`random`/`intercept`/`slope` directory
(`ls docs/dev-log/simulation-artifacts/ | grep -i student` → only the six
`student-nu-*` fixed-shape dirs above, none touch random effects).
`docs/dev-log/dashboard/*.tsv` hits for "student" are all *structured*
(spatial/phylo) rejection rows (`structured-re-q-series-support-cells.tsv:92,97`),
not the *ordinary* `(1 | id)` route mc-0487 needs. No hit in check-log.md or
interval-campaign-bindings for mc-0487. `git log --all -S"mc-0487"` → only
lane/import/missing-data commits, nothing new.

**Q2.** Cited: `tests/testthat/test-phase18-student-mu-random-intercept.R:42-83`.
Read in full: line 74-78 asserts
`sum(summary$wald_intervals$interval_scale == "formula_coefficient" & summary$wald_intervals$interval_status == "ok") == 10L`
— this *is* a genuine finiteness check (traced `interval_status` to
`inst/sim/R/sim_uncertainty.R:58-107`, `phase18_add_wald_intervals()`: `ok <-
is.finite(estimate_value) & is.finite(se_value) & se_value >= 0`, so
`interval_status=="ok"` mechanically implies finite, correctly-ordered
lower/upper) — **but it is scoped to `interval_scale=="formula_coefficient"`,
i.e. the fixed `mu`/`sigma`/`nu` rows only.** mc-0487's own target parameter,
the random-intercept SD `sd:mu:(1 | id)`, is carried in
`summary$profile_intervals` (public_sd scale), which the test only checks via
`expect_equal(nrow(summary$profile_intervals), 2L)` — a row-count, **no
`interval_status`/`is.finite` check on that column at all.** (The producing
function, `inst/sim/run/sim_summary_student_mu_random_intercept_smoke.R:74-115`,
does compute a real `interval_status` for these rows, but no test reads it.)
Corroborated in `tests/testthat/test-student-location-scale.R:128-132`: only
`sd_target$profile_ready` (a readiness flag, not a computed-interval check) is
asserted.

**Verdict: (C) NOT EVEN SHAPE** — the fixed-effect side is shape-checked, but
the cell's actual target (the random-intercept SD interval) has no endpoint
assertion in the current suite, and no campaign exists.

---

## mc-0488 — student, mu, ordinary_re_slope

**Q1.** No campaign. `docs/dev-log/simulation-artifacts/2026-07-12-arc2b-slope-recovery/README.md:1-4`
covers mu random-slope recovery for exactly 5 families (binomial,
cumulative_logit, skew_normal, tweedie, zero_one_beta) — **student is not
included**, and even for included families it is explicitly "`point_fit_recovery`,
not coverage" (line 28). No other slope-specific artifact directory or
dashboard row names student+slope. `git log --all -S"mc-0488"` → only
lane/import/missing-data commits.

**Q2.** Cited: `tests/testthat/test-nongaussian-mu-random-slopes.R:66-161`.
Read `expect_nongaussian_mu_slope_fit()` (lines 112-144) in full: point/BLUP
recovery checks (`cor(slope_effects, truth$slope) > 0.25`), and
`expect_equal(any(targets$parm == paste0("sd:mu:", slope_label)), TRUE)` —
only asserts the `sd:mu:(0+x|id)` **row exists** in `profile_targets()`, no
`confint()` call, no `is.finite`, no `profile_ready` check even (the ledger's
own notes admit this: "profile_ready not separately asserted for this row").

**Verdict: (C) NOT EVEN SHAPE** — no campaign, and the cited test never
computes or checks an interval for this cell's parameter.

---

## mc-0508 — truncated_nbinom2, mu, fixed

**Q1.** No dedicated campaign directory found for `truncated_nbinom2` fixed-mu
under simulation-artifacts (only unrelated `count-slope-*-nbinom2-*` micro-shards,
plain `nbinom2` not `truncated_nbinom2`). **Adjacent-axis finding**: a
missing-response G5 panel exists,
`docs/dev-log/simulation-artifacts/2026-08-11-g5-authenticated-panel/panel-cell-summary.csv`,
with `"truncated_nbinom2","fixef:mu:(Intercept)","1x",1200,1200,1,0.9392,0.0069`
(N=1200, 3 information rungs) — but there is **no** `ev-mr-truncated-nbinom2-g5`
row in `evidence.tsv` (only G2/G3 rejection-axis rows,
`evidence.tsv:726,763-764`), and every sibling `-g5` row explicitly states
"It does not claim anything about the model-surface capability ledger axis"
(e.g. `evidence.tsv:1048`) — this campaign is for the **missing-response**
governance axis (25% MCAR fits), a deliberately separate route from mc-0508's
complete-data model-surface cell. Not counted toward the verdict; flagged for
visibility only.

**Q2.** **Genuinely fixed today.** Commit `7c62279e5` edited
`tests/testthat/test-truncated-nbinom2-location-scale.R`. Current content
(lines 85-104, `test_that("drmTMB fits fixed-effect truncated nbinom2
models"...)`):
```r
ci <- confint(fit)
expect_equal(ci$parm, c("fixef:mu:(Intercept)", "fixef:mu:x",
                         "fixef:sigma:(Intercept)", "fixef:sigma:z"))
expect_equal(ci$tmb_parameter, c("beta_mu","beta_mu","beta_sigma","beta_sigma"))
expect_true(all(ci$conf.status == "wald"))
expect_true(all(is.finite(ci$lower)))
expect_true(all(is.finite(ci$upper)))
expect_true(all(ci$lower < ci$upper))
```
covers all four fixed-effect params including mc-0508's `mu:(Intercept)`/`mu:x`.

**Verdict: (B) SHAPE-JUSTIFIED** — added today by `7c62279e5`, verified live in
the file.

---

## mc-0509 — truncated_nbinom2, sigma, fixed

Same test block as mc-0508 (`test-truncated-nbinom2-location-scale.R:85-104`)
covers `sigma:(Intercept)`/`sigma:z` too. Same adjacent-axis G5 note applies:
`"truncated_nbinom2","fixef:sigma:(Intercept)","1x",1200,926,0.7717,0.9492,0.0072`
(missing-response axis, not wired, explicitly out-of-scope for model-surface
per the sibling G5 rows' own text).

**Verdict: (B) SHAPE-JUSTIFIED** — same commit `7c62279e5`, same file.

---

## mc-0510 — truncated_nbinom2, mu, ordinary_re_intercept

**Q1.** No committed campaign with real numbers. The after-task doc cited in
the ledger, `docs/dev-log/after-task/2026-05-27-truncated-nbinom2-mu-random-intercept-artifacts-slices-1389-1398.md:200-204`,
states "this is smoke/artifact evidence, not a formal coverage claim," and the
Phase-18 artifact lane it describes is an **opt-in GitHub Actions task** whose
per-replicate outputs are not committed (`find . -iname "*truncated*random*intercept*"`
→ only the design doc, two after-task docs, and the test files themselves; no
csv/tsv artifact directory). Adjacent-axis G5 panel again has a real number —
`"truncated_nbinom2","sd:mu:(1 | id)","1x",1200,498,0.415,0.9659,0.0081`
(only 41.5% of replicates were interval-usable at the 1x rung; NOT applicable
per the same missing-response-axis disclaimer) — flagged, not counted.
`git log --all -S"mc-0510"` → `36ec0bb8d feat(ledger): render location_checked
on the reader surfaces` (a rendering feature, not new interval evidence) plus
lane/import commits.

**Q2.** Cited: `test-truncated-nbinom2-location-scale.R:107-137` — read in
full, no `confint()` call at all in this block, only `check_drm()`. Cited
`test-phase18-truncated-nbinom2-mu-random-intercept.R:41-73` — read in full
(lines 41-122): asserts `nrow(summary$wald_intervals)==10`,
`nrow(summary$wald_coverage)==8`, `nrow(summary$profile_intervals)==2`, file
existence — all row-counts/structure, no `interval_status`/`is.finite` check
anywhere (unlike mc-0487's sibling student test, this one does not even check
`interval_status` on the fixed-effect rows). Cited
`inst/sim/fit/sim_summarise_truncated_nbinom2_mu_random_intercept.R:74-132` is
the producing code (confirmed it does compute real `interval_status` values
internally, same `phase18_add_wald_intervals` mechanism as mc-0487), but no
test reads/asserts that value for this cell.

**Verdict: (C) NOT EVEN SHAPE** — no campaign committed with numbers, and no
current test asserts finite/ordered endpoints for this cell's random-intercept
SD interval.

---

## mc-0531 — tweedie, mu, fixed

**Q1.** No `model_surface`-axis committed coverage campaign for tweedie fixed
mu (only unrelated `arc2b-slope-recovery`, a random-slope point-recovery study
for a *different* effect_type, and `dg3-power-arm*`, a power study, not
interval coverage). Adjacent-axis G5 panel again has real numbers —
`"tweedie","fixef:mu:(Intercept)","1x",1200,1200,1,0.9417,0.0068`,
`"fixef:mu:x","1x",1200,1200,1,0.9433,0.0067` (and 0.5x/2x rungs similar,
0.9375–0.9617) — flagged as adjacent (missing-response axis,
`ev-mr-tweedie-g5`, `evidence.tsv:1057`), not counted per its own scope
disclaimer.

**Q2.** Cited `tests/testthat/test-phase18-tweedie-fixed-effect.R:53-92`. Read
in full: `test_that("Phase 18 Tweedie smoke returns Wald artifacts", ...)`
(lines 56-92) asserts, unconditionally over all 5 parameters
(`mu:(Intercept)`, `mu:x`, `sigma:(Intercept)`, `sigma:z`, `nu:(Intercept)`):
`expect_true(all(summary$wald_intervals$interval_status == "ok"))` (line 83).
Traced `interval_status` to `inst/sim/run/sim_summary_tweedie_fixed_effect_smoke.R:44`
→ `phase18_add_wald_intervals()`, the same finiteness-derived status
mechanism confirmed under mc-0487/mc-0510 (`is.finite(estimate) &
is.finite(se) & se>=0`). This directly and currently covers mc-0531's own
target parameters (`mu:(Intercept)`, `mu:x`).

**Verdict: (B) SHAPE-JUSTIFIED** — pre-existing (not from today's commit),
genuinely finite/well-formed via `interval_status=="ok"` on both mu rows.

---

## Summary table

| Cell | Route | Verdict | 5-word reason |
| --- | --- | --- | --- |
| mc-0456 | skew_normal mu fixed | B | Pilot campaign returns finite mu CIs |
| mc-0458 | skew_normal sigma fixed | B | Pilot campaign returns finite sigma CIs |
| mc-0484 | student mu fixed | A | Wald-calibration campaign unwired, coverage 0.82-0.86 |
| mc-0485 | student sigma fixed | A | Wald-calibration campaign unwired, coverage 0.81-0.85 |
| mc-0486 | student nu fixed | A | Campaign unwired; citation-fix hit wrong test |
| mc-0487 | student mu RE-intercept | C | Random-SD interval never checked, only counted |
| mc-0488 | student mu RE-slope | C | Only row presence checked, no interval |
| mc-0508 | truncated_nbinom2 mu fixed | B | Today's commit added finite/ordered mu assertions |
| mc-0509 | truncated_nbinom2 sigma fixed | B | Today's commit added finite/ordered sigma assertions |
| mc-0510 | truncated_nbinom2 mu RE-intercept | C | Only row/file counts, no finiteness check |
| mc-0531 | tweedie mu fixed | B | Wald interval_status=="ok" asserted for mu |

## Recurring pattern worth surfacing (not a recommendation, an observation)

Three of the four (C) findings and one (A) finding above have the identical
shape: a phase18 "smoke" test asserts `interval_status=="ok"` (a real
finiteness check) for the **fixed-effect** rows only, while the cell's own
target parameter is a **random-effect SD** row (`profile_intervals`,
`public_sd` scale) that the same test checks only by row-count
(`nrow(...)==N`), never by status or finiteness — even though the producing
R code (`inst/sim/**/sim_summarise_*_random_intercept.R`) computes a genuine
`interval_status` for exactly that row. This affects mc-0487, mc-0510 in this
batch, and by the same file pattern likely other random-intercept/slope cells
outside this batch's 11.
