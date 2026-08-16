# Overnight import batch 2 — interval-claim truth audit

Cells: mc-0223, mc-0236, mc-0238, mc-0240, mc-0244, mc-0326, mc-0342, mc-0358,
mc-0374, mc-0376, mc-0378. All 11 sit at `evidence_tier = interval_feasible`,
`location_checked = unchecked`, `tranche_id = legacy-census`,
`primary_evidence_class = legacy_model_evidence` (the 2026-07-11 `095409c02`
migration import; `evidence.tsv` / `transitions.tsv` show no run_id, command,
or replicates on any of the 11 rows).

Tier definition used throughout: `docs/design/255-interval-feasible-tier-contract.md`
Position 1 (shape) — "a named interval method runs to completion on this exact
cell and returns a well-formed interval — finite, ordered, unclamped." A
metadata flag that a profile mechanism is *available* (`profile_ready`) is not
the same claim as a computed interval whose endpoints were checked.

## Searches run for every cell (Question 1 — campaign)

- `docs/dev-log/simulation-artifacts/`: listed all ~230 dirs; grepped file
  contents for `gamma|lognormal|cumulative_logit|hurdle_nbinom2` and separately
  grepped directory names for `gamma`, `lognorm`, `hurdle`/`nbinom2`,
  `cumlogit`/`cumulative`/`ordinal`. Hits found: `2026-07-17-gamma-sigma-re-coverage`
  (mc-0242, gamma **sigma random-intercept** — a different cell, not fixed),
  `2026-07-24-biv-lognormal-rho12-*` (**bivariate** lognormal `rho12`, not our
  univariate mu/sigma-fixed or mu-RE cells), `2026-07-18-cumlogit-laplace-vs-aghq`
  and `2026-07-18-o3-cumlogit-slope-coverage` (mc-0227, cumulative_logit mu
  **random-slope** RE-SD — not mc-0223's fixed-mu route), `2026-06-26-count-slope-*-nbinom2-*`
  (plain `nbinom2` slope RE, not `hurdle_nbinom2`/`truncated_nbinom2` fixed
  effects). None of these five match any of our 11 (family, dpar, effect_type)
  routes.
- `docs/dev-log/dashboard/*.tsv`: grepped every tsv for the four family
  strings; hits in `parity-triage.tsv` (comparator-parity rows, not coverage,
  and for different cell_ids — mc-0225, mc-0248, mc-0251, mc-0380, mc-0386,
  mc-0388 — none of our 11), `structured-re-*` boards (q-series structured RE,
  rejected-cell rows for Gamma-relmat and ordinal-phylo, again different
  cell_ids). Directly grepped `cells.tsv` for each of the 11 cell_ids by exact
  tab-delimited match: only the single `legacy-census` row each, already known.
- `docs/dev-log/check-log.md` (94,041 lines): `grep -c <cell_id>` = 0 for all
  11 IDs. Grepped `gamma.*coverage`, `lognormal.*coverage`, `hurdle.*coverage`,
  `cumulative_logit.*coverage` — only hits are the bivariate-lognormal rho12
  campaign (line 743) and the emmeans "coverage" *test-suite-coverage* slice
  (line 53514, `test-emmeans-methods.R` — a testing-coverage phrase, not a
  statistical-coverage campaign; this is the same test cited for mc-0236).
- `docs/dev-log/after-task/`: `grep -rl <cell_id>` = 0 files for all 11 IDs.
- `git log --all --oneline -S"<cell_id>"` for every ID (full history, all
  refs). Hits are exclusively: (a) two bookkeeping commits from this same
  overnight audit's predecessor lane (`9ee8c9fc4` Wave-1 classification,
  `2d033a7d3` LOOP-kit census — see below), (b) unrelated `missing-data`
  formula-inventory commits that merely enumerate every cell_id in a table,
  (c) for mc-0223/0326/0342/0358 only: `7c62279e5` "assert finite ordered
  endpoints at the 14 label-only confint sites" (2026-08-15, see Q2 below).
  No campaign-shaped commit for any of the 11.
- Cross-check against the predecessor board: commit `9ee8c9fc4` (this same
  worktree, 2026-08-15, "Wave 1 classification") independently classified all
  11 of these exact cells as class **(c) legacy import, no run** in
  `scratchpad/uncovered-cohort-A.md:38-56` ("Primary ev-mc-0XXX-legacy:
  run_id/command/replicates blank"). That prior pass did not, however, check
  whether the *cited test* asserts endpoints (its own §"Answer to Question 2"
  is about `primary_command`, not test-file content) — that is genuinely new
  ground covered below.

**Verdict on Question 1 for all 11 cells: NO CAMPAIGN EXISTS.** No coverage
rate, no DGP-vs-retained-interval study, no run_id/command/replicates, in any
location searched, for any of the 11 (family × dpar × effect_type) routes.

## Question 2 — does the cited test assert well-formed endpoints today?

### mc-0223 — cumulative_logit / mu / fixed
Cited: `tests/testthat/test-cumulative-logit.R:46-76` (ledger's evidence.tsv
range) / notes cite `:46-77`.
Current file, read at content (`test-cumulative-logit.R:70-77`):
```
ci <- confint(fit)
expect_equal(ci$parm, "fixef:mu:x")
expect_equal(ci$tmb_parameter, "beta_mu")
expect_equal(ci$conf.status, "wald")
expect_true(is.finite(ci$lower))
expect_true(is.finite(ci$upper))
expect_true(ci$lower < ci$upper)
```
The last line (`ci$lower < ci$upper`) was added by commit `7c62279e5`
(2026-08-15, "assert finite ordered endpoints at the 14 label-only confint
sites") — commit message confirms cumulative-logit "already asserted
finiteness; it gained ordering only." **YES, asserts finite + ordered.**

### mc-0236 — gamma / mu / fixed
Cited: `tests/testthat/test-gamma-location-scale.R:46-70,121-236`;
`tests/testthat/test-comparators.R:848-873`; `tests/testthat/test-emmeans-methods.R:608-622`.
- `test-gamma-location-scale.R`: zero `confint` calls in the entire 400-line
  file (`grep -n confint` → no output). Lines 46-70 ("fits fixed-effect Gamma
  mean-CV models") only check point coefficients, `predict()`, `fitted()`.
  Lines 121-185 ("methods return mean and CV scales") check `predict`/
  `residuals`/`simulate`, no interval. Lines 187-236 not an interval test
  either (factor/edge-case predict checks).
- `test-comparators.R:847-873` ("Gamma mean model agrees with base glm"):
  point-coefficient comparison to `glm()` only; no `confint`, no interval.
- `test-emmeans-methods.R:590-622` (helper `expect_emmeans_mu_prediction_parity`,
  lines 20-46, invoked at 608-622): asserts point-prediction parity and
  `expect_true(all(is.finite(link$SE)))` — a finite-**SE** check on the
  `emmeans::summary()` link object, not a computed CI; no `lower`/`upper`,
  no ordering assertion anywhere.
**NO — none of the three cited files assert interval endpoints for this
route.**

Additional finding (uncited): `tests/testthat/test-phase18-positive-continuous-fixed-effect.R:42-73`
("Phase 18 positive-continuous smoke returns Wald artifacts") fits **exactly
this route** — `phase18_fit_positive_continuous_fe()` at
`inst/sim/run/sim_run_positive_continuous_fixed_effect_smoke.R:44-56` calls
`drmTMB(bf(y ~ x, sigma ~ z), family = stats::Gamma(link = "log"), data = data)`
for `family="gamma"`, i.e. the identical `mu`-fixed/`sigma`-fixed base/base
gamma route — over 8 rows (2 families × 4 coefficients) and asserts
`expect_true(all(summary$wald_intervals$interval_status == "ok"))`. By
construction (`inst/sim/R/sim_uncertainty.R:90-103`) `interval_status=="ok"`
requires finite estimate and finite, non-negative SE, from which `conf.low`/
`conf.high` are literally computed as `estimate ∓ z·se` — i.e. genuinely
finite, and ordered whenever `se>0` (not itself asserted as a separate `<`
check). This test is cited in the ledger for the **sibling lognormal cells**
mc-0374/mc-0376 but not for mc-0236/mc-0238, even though it exercises gamma
in the same run. This is evidence that exists in the repo but is not wired to
mc-0236's ledger row.

### mc-0238 — gamma / sigma / fixed
Cited: same three files, ledger notes add `:145-185`. Read lines 145-185
directly (`test-gamma-location-scale.R`): `predict`/`residuals`/`simulate`
checks only, still zero `confint` calls anywhere in the file. **NO.**
Same additional uncited finding as mc-0236 applies (the same 8-row
`wald_intervals` check covers gamma `sigma` coefficients too).

### mc-0240 — gamma / mu / ordinary_re_intercept
Cited: `R/drmTMB.R:4004-4006,7755-7777`; `tests/testthat/test-gamma-location-scale.R:72-119`.
Read `:72-119` ("Gamma mu supports ordinary random intercepts"): fits `(1|id)`,
checks `pdHess`, `sd` estimate vs truth, BLUP correlation, then:
```
targets <- profile_targets(fit)
sd_target <- targets[targets$parm == "sd:mu:(1 | id)", , drop = FALSE]
expect_equal(nrow(sd_target), 1L)
expect_equal(sd_target$tmb_parameter, "log_sd_mu")
expect_true(sd_target$profile_ready)
```
`profile_ready` is a metadata flag saying the profile mechanism is *available*
for this parameter — no `confint()`/`tmbprofile()` call, no numeric endpoint
is ever produced or checked in this test. **NO.**
Checked for an uncited alternative: `test-phase18-positive-continuous-mu-random-intercept.R:51-85`
(family=c("lognormal","gamma"), same DGP surface as mc-0378) — read in full;
it asserts row counts (`nrow(summary$wald_intervals)==10L`,
`nrow(summary$wald_coverage)==8L`, `nrow(summary$profile_intervals)==2L`) and
`all(summary$manifest$status == "ok")` (fit-convergence status,
`inst/sim/R/sim_runner.R:349-367` — unrelated to interval endpoints). Traced
`phase18_summarise_interval_coverage` (`inst/sim/R/sim_uncertainty.R:166-196`):
it groups and reports `n_interval`/`n_covered` even for groups whose
`usable_interval` count is zero — the row still appears in the output — so
the `nrow(...)==8L` / `==2L` equalities do **not** imply any interval was
finite; they are structural/shape counts on the data frame, not content
checks. This uncited test does **not** clear the bar either. No upgrade path
found.

### mc-0244 — gamma / mu / ordinary_re_slope
Cited: `R/drmTMB.R:4004-4006`; `tests/testthat/test-nongaussian-mu-random-slopes.R:20-59,79-85,111-140`.
`grep -n confint` on the whole file → no output. Read `:112-144`
(`expect_nongaussian_mu_slope_fit`, the shared assertion helper invoked across
the cited ranges): fits, checks `pdHess`, `sdpars`, slope-effect correlation
>0.25, `check_drm()` replication/design status, then:
```
targets <- profile_targets(fit)
expect_equal(any(targets$parm == paste0("sd:mu:", slope_label)), TRUE)
```
This is weaker than mc-0240's check — it only asserts a target **row exists**
in `profile_targets()`, not even the `profile_ready` flag, and again no
`confint()`/numeric endpoint anywhere in the cited range. **NO.**

### mc-0326 — hurdle_nbinom2 / mu / fixed
Cited: `tests/testthat/test-hurdle-nbinom2.R:34-92` (evidence.tsv) / `:34-95`
(cells.tsv notes, post-insertion). Read `:34-95` ("drmTMB fits fixed-effect
hurdle nbinom2 models"): single `confint(fit)` call at line 64 returns `ci`
covering all 8 coefficients across mu/sigma/hu in one data frame, then:
```
expect_true(all(ci$conf.status == "wald"))
expect_true(all(is.finite(ci$lower)))
expect_true(all(is.finite(ci$upper)))
expect_true(all(ci$lower < ci$upper))
```
The three `all(...)` finite/order lines were added by `7c62279e5` (confirmed
by `git show 7c62279e5 -- tests/testthat/test-hurdle-nbinom2.R`), one of its
7 sites (this file covers mc-0326/mc-0342/mc-0358 together, since it's one
`confint(fit)` call over all three dpars). **YES.**

### mc-0342 — hurdle_nbinom2 / sigma / fixed
Same test, same `ci` object, same `all()` assertions cover the two
`fixef:sigma:*` rows within the 8-row vector. **YES.**

### mc-0358 — hurdle_nbinom2 / hu / fixed
Same test, same `ci` object, same `all()` assertions cover the three
`fixef:hu:*` rows within the 8-row vector. **YES.**

### mc-0374 — lognormal / mu / fixed
Cited: `tests/testthat/test-lognormal-location-scale.R:46-69,177-215`;
`tests/testthat/test-phase18-positive-continuous-fixed-effect.R:42-73` with
`inst/sim/run/sim_run_positive_continuous_fixed_effect_smoke.R`.
`test-lognormal-location-scale.R` has zero `confint` calls (checked, no
output). The phase18 smoke (read in full, `:42-73`): `phase18_fit_positive_continuous_fe`
fits `drmTMB(bf(y ~ x, sigma ~ z), family = lognormal(), data = data)` for
`family="lognormal"`; `nrow(summary$wald_intervals)==8L`
(2 families × {mu:(Intercept), mu:x, sigma:(Intercept), sigma:z}), then
```
expect_true(all(summary$wald_intervals$interval_status == "ok"))
```
This is a genuine, all-rows assertion over real computed Wald endpoints
(`inst/sim/R/sim_uncertainty.R:90-103`: `interval_status=="ok"` requires and
implies finite `conf.low`/`conf.high`, computed as `estimate ∓ z·se`).
**YES** (finite, and ordered whenever `se>0`, which is the case for every
converged ML fit on continuous data — not separately re-asserted as a `<`
check the way the confint()-sites now are).

### mc-0376 — lognormal / sigma / fixed
Same phase18 smoke and same `all(...)` assertion; the row set includes
lognormal `sigma:(Intercept)` and `sigma:z`. **YES**, same basis as mc-0374.

### mc-0378 — lognormal / mu / ordinary_re_intercept
Cited: `tests/testthat/test-lognormal-location-scale.R:71-113` (`sd_id`
recovery, BLUP correlation, `profile_targets()` `profile_ready==TRUE`,
`check_drm()` replication `ok`) — same weak `profile_ready`-flag-only pattern
as mc-0240, no `confint()` call, no numeric endpoint. AND
`tests/testthat/test-phase18-positive-continuous-mu-random-intercept.R:51-85`
("Phase 18 positive-continuous mu random-intercept smoke returns artifacts"):
read in full; traced `phase18_summarise_positive_continuous_mu_ri_smoke`
(`inst/sim/run/sim_summary_positive_continuous_mu_random_intercept_smoke.R:1-92`)
and `phase18_positive_continuous_mu_ri_profile_intervals`
(same file, `:94-120`, `interval_status` from `is.finite(conf.low) &
is.finite(conf.high)` only — no ordering check even in the harness). The test
itself asserts only row counts (`wald_intervals`==10L, `wald_coverage`==8L,
`profile_intervals`==2L), the `interval_scale` set, and
`all(summary$manifest$status == "ok")` (fit-convergence, not interval
content) — it never reads `wald_intervals$interval_status` or
`profile_intervals$interval_status` directly, and (as traced under mc-0240)
the coverage-row counts do not imply any interval was finite, since
`phase18_summarise_interval_coverage` emits a row per group regardless of how
many of that group's intervals were usable. **NO — neither cited test
asserts endpoint validity for this route**, in contrast to the fixed-effect
sibling smoke used for mc-0374/mc-0376, which does.

## Verdict table

| cell_id | family/dpar/effect | campaign? | cited test asserts endpoints? | verdict |
|---|---|---|---|---|
| mc-0223 | cumulative_logit / mu / fixed | no | yes (`test-cumulative-logit.R:74-76`) | **B** |
| mc-0236 | gamma / mu / fixed | no | no | **C** |
| mc-0238 | gamma / sigma / fixed | no | no | **C** |
| mc-0240 | gamma / mu / ordinary_re_intercept | no | no (`profile_ready` flag only) | **C** |
| mc-0244 | gamma / mu / ordinary_re_slope | no | no (target-row-exists only) | **C** |
| mc-0326 | hurdle_nbinom2 / mu / fixed | no | yes (`test-hurdle-nbinom2.R:92-94`) | **B** |
| mc-0342 | hurdle_nbinom2 / sigma / fixed | no | yes (same block) | **B** |
| mc-0358 | hurdle_nbinom2 / hu / fixed | no | yes (same block) | **B** |
| mc-0374 | lognormal / mu / fixed | no | yes (`test-phase18-positive-continuous-fixed-effect.R:71`) | **B** |
| mc-0376 | lognormal / sigma / fixed | no | yes (same test) | **B** |
| mc-0378 | lognormal / mu / ordinary_re_intercept | no | no (row-count/manifest-status only) | **C** |

Note on mc-0236/mc-0238: strictly-cited evidence is (C), but the repository
contains uncited evidence (`test-phase18-positive-continuous-fixed-effect.R:71`)
that exercises the identical route and does clear the finite-endpoint bar —
recorded above as fact, not as a recommendation.
