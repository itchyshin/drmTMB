# After-task report: Julia q2/q3/q4 SD-regression feature work (2026-11-07)

## Task goal

Make DRModels.jl fit six shapes it used to refuse and that native drmTMB
already supports, then show R-versus-Julia numerical agreement for each. The
Julia work lives on `claude/q2-final-20261107` (draft PR on DRModels.jl, not
merged). This report belongs to evidence PR #1684 and changes no parity verdict.

## Files created or changed

Julia side (DRModels.jl, branch `claude/q2-final-20261107`):

- `src/poisson.jl`, `src/negbinomial.jl`: animal and relmat intercept-plus-slope
  with one SD per coefficient (Poisson, NB2), Laplace marginal likelihood.
- `src/gaussian_ranef.jl`, `src/bridge.jl`: Gaussian animal and relmat q2.
- `src/gaussian_ordinary_q34_sd.jl`: Gaussian ordinary q2, q3, q4, exact marginal.
- `src/gaussian_sigma_sd_laplace.jl`: joint mu+sigma and structured sigma with SD formulas.
- `src/gaussian_core.jl`, `src/inference.jl`: `predict`/`predict_parameters` flags and a
  marginal simulator, added after adversarial review found crashes.
- Tests: one file per route (animal q2, NB2 relmat, q3/q4, ordinary q2, sigma Laplace,
  `test_q2_sd_simulate.jl`).

drmTMB side (this PR): evidence under
`docs/dev-log/parity-crosswalk-evidence-20261107/`, `PLAN-julia-feature-work.md`,
`PROPOSED-verdict-flips.md` (proposal only; nothing applied).

## Checks run and exact outcomes

- Per-route Julia tests pass (Poisson animal 8/8, NB2 relmat 11/11, q3/q4 30, ordinary q2 22,
  sigma 35+36, simulate 78).
- R-versus-Julia agreement, one dataset per route, ML, at the optimum: coefficients and SDs
  agree to at most about 1.2e-7 R-SE units for the 6a sigma-slope case (the tightest), about
  2e-6 R-SE units across the wave 1 routes and wave 2 routes, and about 6e-6 for the wave 3
  labelled-ordinary routes; log-likelihood to at most 1e-9 on the wave 1 routes. Tables and
  scripts are in the evidence directory.
- Full Julia suite on the integration tip, four shards: see "Suite result" below.

## Suite result

Final tip `f4b30ee26`, four shards. Seven files failed; each failed identically on
origin/main: `test_binomial_animal_slope_iid_sd_regression`, `test_analytic_grad`,
`test_stored_loglik_at_optimum`, `test_lane_j4_predict_numerics`, `test_qgate_jet`,
`test_sentinel_mixed_family`, `test_q4_laplace` (the last needs `fit_q4_julia.jl`, absent
on main). No new failures. Draft PR: itchyshin/DRModels.jl#1261 (not merged). Later triage
(2026-11-08): `test_analytic_grad` and `test_qgate_jet` are excluded by CI's `_TEST_EXCLUDE`
(driver artefacts, not failures); `test_lane_j4_predict_numerics` had a real cumulative-model
bug, fixed in #1267; `test_stored_loglik_at_optimum` relaxes for a non-converged Binomial animal
q2 fit on Julia 1.10 (log-lik -263.18 against -243.95 on 1.12), an existing optimiser weakness
outside the parity PRs. The other three files have no new information.

## Consistency audit

- The R side supports every route, so Julia was the gap, not R. Native R was not edited.
- Syntax follows the project rules: `sigma`, `sd(...)` formulas, unlabelled q2 means two
  independent fields (rho fixed at 0).
- `predict` is population-level only; no conditional modes are stored.

## Tests of the tests

- Each route compares the fitted marginal likelihood with an independent dense
  Laplace or MvNormal oracle at the fitted theta.
- Adversarial review (4 dimensions, 3 skeptics) found real crashes in `predict`,
  `drm_bridge(newdata)`, `simulate` and bootstrap; each now has a test.

## What did not go smoothly

- The stress design `sigma ~ 1 + (1|site)` with 200 by 200 crossed groups, n = 2400,
  fails in both Julia and R (false convergence, infinite SEs). It is recorded as a failure,
  not as agreement. Cause is undiagnosed.
- Merge conflicts in `src/bridge.jl` and `src/gaussian_ranef.jl` between parallel branches,
  resolved by hand.
- `test_q4_laplace.jl` ends the Julia process when `fit_q4_julia.jl` is missing, which
  killed one shard; its remaining files were rerun separately.

## Team learning and process improvements

Parallel worktrees per route worked; the integration merge was the costly step. Run the
shard driver with a per-file process guard next time.

## Design-doc updates

None yet. Verdict flips need a separate reviewed PR (see `PROPOSED-verdict-flips.md`).

## pkgdown/documentation updates

None.

## GitHub issue maintenance

None.

## Known limitations and next actions

- Single seed per route; this is agreement at the optimum, not calibration or coverage.
- No REML, labelled-rho forms, spatial or phylo q2, or conditional fields.
- Bridge R-coefficient names for two-target fits are hashed (`sdtarget_*`).
- Gaussian sigma-intercept stress failure above; dense engine capped at 600 latent
  coordinates; Gaussian q2 capped at 5000 rows.
- Plain `sigma ~ 1 + animal(1|id)` without an SD formula is still gap #963.
- Next: draft PR on DRModels.jl, then a separate reviewed drmTMB PR for verdict flips
  (only Gaussian ordinary q3/q4 flips outright), conditional on Julia landing and the pin moving.

## Wave 2 addendum (2026-11-08)

Julia side: draft PR itchyshin/DRModels.jl#1263, stacked on #1261, branch `claude/q2-wave2-merge-20261107`. It adds labelled correlated slopes with a free rho, phylogenetic and spatial q2, Gamma and NB2 two-field SD routes, joint mu+sigma SD Laplace for Gamma and NB2, and post-fit methods. Evidence folders `wave2-*` are under `docs/dev-log/parity-crosswalk-evidence-20261107/`.

Suite result on the merge tip: four shards. Seven files fail identically on origin/main. One extra failure, `test_skewnormal.jl`, was a test-isolation defect: two new test files used a bare `using Distributions`, which made `SkewNormal` ambiguous for later files in the same process. Fixed by importing only the needed names; the three files re-ran clean together. The whole suite was not re-run after that test-only change.

Not agreeing: Gamma crossed joint mu+sigma (different local maxima, 0.016 log-likelihood gap). Open: Poisson phylo slope-SD SE gap of 3e-3 relative; labelled phylo/spatial; mesh/SPDE; REML; NB2/Gamma structured sigma; multi-seed evidence. No parity verdict was changed; flips remain proposals in `PROPOSED-verdict-flips.md`.

## Waves 3 to 5 addendum (2026-11-08)

Reader: the reviewer of evidence PR #1684 and whoever writes the verdict PR. Per-row proposals, with numbers, are in `parity-crosswalk-evidence-20261107/PROPOSED-verdict-flips.md` (section "Waves 3 to 5"). This addendum records what was done and what went wrong. No parity verdict, `tools/write-parity-matrix.R` or test file was changed; nothing here is a claim of validated coverage.

### Julia side

- Wave 3: itchyshin/DRModels.jl PR #1264, tip `04581709d`. Labelled (correlated) phylo and spatial q2 with one SD formula per coefficient; labelled ordinary `(1 + x | p | g)` for Poisson and NB2.
- Waves 4 and 5: PR itchyshin/DRModels.jl#1266 (tip `e5ae24539`, includes the wave-5 optimiser fix and review fixes; branch `claude/wave4-merge-20261108`). PR #1263 is wave 2 (stacked on #1261), #1264 is wave 3 (stacked), #1267 is a small cumulative fix on main. The full suite on the final tip is being run on Totoro (Julia 1.10 and 1.12): result pending. Components: Gaussian structured q2 REML (`claude/gaussian-sd-reml-20261108`), NB2 structured sigma and Julia-only NB2/Gamma structured sigma with SD formula (`claude/nb2-gamma-structured-sigma-20261108`), conditional quantile residuals and `Ainv` for Gamma and Gaussian (`claude/postfit-cond-residuals-20261108`), the Gaussian ordinary line-search guard and the Poisson spatial second start (`claude/ordinary-robust-linesearch-20261108`, `346968b2b`). The Gamma crossed diagnosis branch has no commits: no source change was needed.

### Evidence folders added (drmTMB side, under `parity-crosswalk-evidence-20261107/`)

`multiseed` (7 routes x 10 seeds), `multiseed2` (12 routes x 10 seeds plus 10 refusal checks), `scale300` (9 routes x 300 seeds, 2,700 pairs, Totoro, 119 s wall against a 5 minute estimate), `wave3-labelled-phylo-spatial`, `wave3-labelled-ordinary`, `wave4-gamma-crossed-diagnosis`, `wave4-structured-sigma`, `wave4-reml`, `wave4-postfit`, `wave5-ordinary-robust`. Raw per-seed fits (about 130 MB) stay on Totoro and were not committed.

### Results in one place

- Where both fits are at an interior optimum, the two packages agree to optimiser tolerance: median differences 1e-10 to 4e-6 R-SE units over 300 seeds per route.
- Gamma crossed joint mu+sigma is outer bimodality: two optima 0.016 apart with a barrier of about 0.7; Julia's default start lands on the higher one (16 of 30 random Julia starts reach it, 5 of 30 R starts). Oracle value at Julia's estimate -832.50851620, at R's -832.52452715. Not an engine defect; no Julia change.
- Gaussian ordinary q2 line-search failure: 36 of 300 seeds (Julia 1.10.12) and 26 of 300 (1.12.7) before the fix; 0 of 1,200 after, agreeing with R to 9.8e-10 R-SE units. Fits that already worked are bit-identical.
- Poisson spatial q2 is the weakest route: of 300 seeds, 7 are beyond 1e-3 R-SE. Five are R stopping at a lower maximum, one (seed 147) is Julia stopping 1.02 lower (fixed by a second start; 299 of 300 datasets unchanged), one is boundary non-identification. The `multiseed` seed 9 slope-SD boundary is a flat direction, not a different maximum.
- Labelled spatial Gaussian seed 2 is at the rho = 0.999999 bound in both packages; a dense oracle gives the same likelihood at both estimates.
- REML (30 fits, six shapes native R accepts): coefficients within 9.3e-8, REML log-lik within 8.1e-10.
- Conditional quantile residuals now match what native R does for fitted rows (conditional on the Laplace modes): conditional mean 2.2e-7 relative, PIT bounds 8.2e-8, all count rows inside R's PIT interval.

### What did not go smoothly

- Julia's first Gaussian REML carried `beta_mu` as a free coordinate and stopped 5.13 log-lik units below R's optimum on relmat seed 4. The objective was right and the optimiser was not; profiling `beta_mu` by GLS fixed it. A multi-start was tried first and did not help.
- The requested multi-seed route "labelled-rho Poisson ordinary" did not exist in Julia at the time; `multiseed` substituted the structured labelled Poisson route and says so.
- The Gaussian ordinary failure was reproducible only by seed and platform; the failing set changes with Julia version and BLAS, so a fixed seed list is not a regression test. The Julia regression test uses a toy objective that reproduces the failure mode plus two campaign datasets.
- Julia 1.12.6 on the Mac: `test_binomial_animal_q2_sd.jl`, `test_phylo_spatial_q2_sd.jl` and `test_labelled_phylo_spatial_q2_sd.jl` failed with identical numbers on the unfixed source. Triage showed they were not simply pre-existing: the two new files failed because their fixtures used `MersenneTwister` streams that differ between Julia 1.10 and 1.12 (datasets differ; verified by swapping datasets), plus one real latent bug (`scales[:cond_failed] = 1.0` into a `Dict{Symbol,Vector{Float64}}` threw `MethodError`). Both are fixed on the wave-4 branch (#1266) with version-independent committed fixtures (`test/fixtures/q2_stable`). `test_binomial_animal_q2_sd.jl` fails on 1.12 on origin/main too (main has the file). The wave-3 rows depend on the suite result, which is pending.
- Gaussian relmat seed 1 under ML: Julia is higher by 3.57 log-lik (REML on the same data agrees to 1e-10). Same bimodality kind as Gamma crossed; not diagnosed.

### What R cannot check (oracle-only, not "agrees with R")

Labelled ordinary Poisson and NB2 (R refuses the labelled form; the evidence compares with R's unlabelled fit of the same model), labelled spatial NB2, SD formulas on labelled phylo (Poisson), every structured sigma term with an SD formula, and every Gamma structured sigma term. Gamma ordinary correlated is refused by both. REML is compared only on shapes R accepts; ordinary q2/q3/q4 and joint mu+sigma `sd()` REML are refused by both. Structured-sigma REML is not implemented in Julia although R fits it.

### Consistency audit

- R was not edited. One R documentation discrepancy was found: the header of `R/adequacy.R` and the `newdata` paragraph of `fitted_distribution()` say residuals are population-level, but for fitted rows they are conditional on the modes. Follow-up for a docs lane.
- The labelled relmat multi-seed evidence runs through `animal(..., A)`; animal and relmat share the raw matrix, so the relmat path is not separately exercised by seeds.
- Wald coverage in `scale300` is informational only (0.84 to 0.99); the Poisson spatial row may reflect generator-kernel mismatch.

### Known limitations and next actions

- Julia side: PR #1266 is open; its full-suite result on Julia 1.10 and 1.12 (Totoro) is pending. The three failing test files were triaged (see above). Decide whether to give NB2 spatial and the other structured routes the same second-start check as Poisson spatial.
- Matrix side (separate reviewed PR): add capability-status rows for labelled ordinary Poisson/NB2 and NB2 structured sigma before recording them; apply the row proposals only after the Julia pin moves.
- Still not shown: mesh/SPDE spatial, structured-sigma REML, bridge parity for any wave 3 to 5 route, coverage or recovery, offsets for NB2, Julia-side multistart on Poisson spatial beyond the one probe.

### Corrections of 2026-11-08 (after an independent audit; no verdict changed)

- Labelled-ordinary counts: 15 fits have a log-lik gap above 1e-6 (14 `lord_nb2`, 12 of them with both fits converged, plus 1 `lord_poisson`, seed 41), and 22 of 600 fits have R rho at or above 0.99999 (20 NB2, 2 Poisson). Earlier text said 13 plus 1 and 15 of 600.
- The R-SE-unit flag missed 25 seeds whose absolute coefficient difference exceeds 1e-3 (boundary signature, log-lik gap below 1e-6, not diagnosed); `scale300/aggregate_from_csv.R` now flags them. 50 Julia SEs are `Inf` and 3 R SEs are `NA`; SE agreement is not established for those seeds.
- Row proposals were tightened (row 2 conditional on the wave-5 fix merging plus a q3/q4 campaign; rows 12, 13 and 15 held at PARTIAL; row 20 Poisson via `animal()` only; the new labelled-ordinary row reads "Julia-only syntax; matches R's unlabelled equivalent"), and the claim text is `agreement-at-optimum (native Julia vs native R, ML)`, not "covered". See the Revision section of `PROPOSED-verdict-flips.md`.
- Gamma crossed: log-lik gap 0.016 (2 x gap = 0.03); sd(id) slope differs 1.9 SE; R lands on the lower optimum in 25 of 30 random starts. The earlier wording "statistically indistinguishable" was too strong.
- Comparison scripts: `multiseed2/compare2.R` now checks the Julia block labels against R's names (all 120 fits pass); `wave4-reml/compare.R` no longer claims a name check (Julia files carry no names) and `compare.out` now prints log-lik differences and convergence columns.

## Waves 6 to 9 and adversarial checks addendum (2026-11-08)

Reader: whoever reviews PR #1684 or writes the later verdict PR. This lane edited only the two write-ups (this file and `parity-crosswalk-evidence-20261107/PROPOSED-verdict-flips.md`) and `docs/dev-log/check-log.md`. No `R/`, `src/`, `NAMESPACE`, parity matrix, verdict file or test was changed. All numbers were copied from the named folder's README or result file; I re-ran no R or Julia fit.

### Julia side

DRModels.jl draft PR #1268, head `claude/wave6-rtfix-20261108`, stacked on #1266 (base `claude/wave4-merge-20261108`). Draft, not merged by us. Its description reports the full suite on Totoro (Julia 1.10.12 and 1.12.7) with no failure introduced by the stack after the merge fixes, four 1.12 files failing as on `origin/main`, and the last test-only commit checked on its own files only. That is the PR's statement, not something I verified.

### Evidence folders added (under `parity-crosswalk-evidence-20261107/`)

- `wave6-binomial-phylo-spatial/`: Binomial phylo and spatial coefficient-SD q2, 22 datasets, max abs log-lik difference 8.1e-07 (phylo) and 5.3e-07 (spatial), no flags. A first run with the default finite-difference step had Julia SEs up to 9.4% (phylo) and 19.2% (spatial) below R's on 3 spatial datasets; fixed by a step of 3e-3 on this route.
- `wave7-weak-optimum/`: three weak-optimum cases and a restart fix (NB2 phylo seed 55 gap 1.09e-3 to 2.0e-11; rebuilt Binomial weak-probe family 2 of 80 datasets below R before, 0 after; Binomial animal q2 fixture `converged` false to true). Julia 1.10.12 only.
- `wave8-binomial-labelled-phylo/`: labelled Binomial `phylo(1 + x | p | g)`, 10 seeds, log-lik difference at most 8.3e-07 in absolute value, SE ratio 1.0000 to 1.0002.
- `wave9-gap-close/`: bare structured `(1 + x | g)` and Gamma phylo/spatial with SD formulas; 121 paired fits, 106 unflagged (max abs log-lik difference 1.4e-08), 15 flagged and classified; regression fuzz of 492 cells, 0 regressions, 27 refusals turned into fits.
- `fuzz-gap-map/`: 3008 cells; R fits 427, Julia 254; both fit 231 (175 agree within 1e-4, 56 disagree); Julia behind 196 cells in 51 refusal signatures; 729 Julia `MethodError` crashes from one keyword mechanism, none in R.
- `metamorphic/`: 511 Julia-internal invariance cells over 35 routes, 0 FAIL (402 pass, 79 NA, 28 expected, 1 refused, 1 weak).
- `red-team/`: 30 datasets, 340 cells, no hangs or crashes, five input-validation defects fixed on the Julia branch.

### What did not go smoothly

- Wave 7: the original Binomial weak-probe dataset was overwritten, so case (b) was checked on a rebuilt family that reproduces the failure signature, not the numbers. The new regression test file has no test for (b).
- Wave 9: 15 of 121 fits were flagged. Nine are Binomial phylo boundary fits, two Poisson labelled phylo boundary fits, one Gamma spatial boundary fit, and three are different local maxima of the same objective (Gamma phylo sd-z seed 2; spatial sd-z seeds 9 and 10). The last group is not closed.
- Metamorphic: the zero FAIL is not a clean pre-registered pass; tolerances for sim-refit, fixtures and seeds were changed after seeing results (the README lists each change).

### Honest gaps (the earlier list stands; these are added)

1. Restarts cost 7 to 10 times more on collapsed-slope-SD fits (#1268 description). Wave 7 measured +14% on 500 NB2 fits on Totoro and about 3x on the 80-dataset Binomial weak-probe family.
2. The Binomial inner-solve noise-floor change moves some coefficients, up to 0.28. That figure came from the task brief; I did not find it in a folder README. Wave 7 says 4 of 80 weak-probe datasets moved by more than 4e-7 in log-lik and that no SEs were compared after the change.
3. REML still refuses on every new route (wave 9 section 7; #1268 description).
4. A permuted bare `A` without `ids` gave a converged wrong fit in the red-team run (log-lik 7.7 below R for Gaussian, 3.0 for Poisson). #1268 says the warning is now per call; the red-team grid was run before that and was not repeated.
5. Gamma coordinate-SD (`sd-z`) phylo and spatial sits at a different local maximum from R in 3 of 22 seeds; Julia is the lower fit in two of them. No multi-start was added.
6. Boundary fits: non-finite Julia SEs in 6 of 11 Binomial phylo seeds and 7 parameters in one Poisson labelled phylo seed; SD coordinates not comparable there.
7. Tweedie log-lik differs from R by 0.03 to 0.08 (Laplace vs adaptive Gauss-Hermite); cross-engine AIC is invalid for it.
8. Julia 1.12 was not run for the wave 7 restart work, and the metamorphic and red-team runs used Julia 1.10 only. No bridge path was exercised in waves 6 to 9.

### Known limitations and next actions

- Verdict flips remain PROPOSED, conditional on the #1268 stack landing in DRModels.jl main and the pin moving; no row proposal changed in this lane.
- The verdict-PR author must map Binomial phylo/spatial q2, labelled Binomial phylo, bare structured q2 and Gamma phylo/spatial (sd-one only) to matrix rows, and add the capability-status rows first.
- Source for the "7 to 10 times" and "0.28" figures should be added to the folders or removed.


## Waves 7 and 8 addendum: DRModels.jl draft PR #1270 (2026-11-08, later)

Reader: whoever reviews PR #1684 or writes the later verdict PR. This lane edited only this file, `parity-crosswalk-evidence-20261107/PROPOSED-verdict-flips.md` and a new `check-log.d` file. No `R/`, `src/`, `NAMESPACE` or parity matrix was changed. All numbers come from the #1270 description and four files on its branch (the spatial-kernel audit, the Tweedie structured-SD note, the structured-sigma REML design doc and `docs/src/capabilities.md`). I re-ran no fit and did not check out the branch.

### Julia side

DRModels.jl draft PR #1270, head `claude/wave8-integration-20261108` (tip `479bbf963`), stacked on #1268 (`claude/wave6-rtfix-20261108`). Full suite on Totoro with the shard driver (602 files): Julia 1.10.12 all pass; Julia 1.12.7 fails only the five files that also fail on `origin/main` and #1268 (baselines rerun on the previous tip, not this one). This is the PR's statement, not something I verified.

### What landed

- Beta structured SD, 7 shapes: log-likelihood within 2e-6 on 7 datasets, coefficients within 2.2e-7 on 6 non-boundary datasets. Reference drmTMB 0.8.0, not 0.8.1; 16 groups; Julia 1.10 only; no bootstrap or profile check.
- Tweedie phylo and relmat intercepts: 9 of 10 fits agree to about 1e-7. The tenth (phylo, SD covariate) is R at a stationary point 2.7 nats worse than Julia's. No cross-engine log-likelihood or AIC. The PR says Laplace versus Gauss-Hermite; the branch note says both engines use Laplace on these structured routes. The two disagree and I did not resolve it.
- Gaussian structured-sigma REML: 5 datasets, 61 of 61 checks; max log-likelihood difference 2.7e-12 (design doc).
- Gamma spatial q=1 native kernel: maximum difference from R 2.1e-2 (0.17 R-SE units) to 7e-8.
- Bivariate q=2 and q=4 native kernel: q=2 agrees (7e-7 to 1.6e-5 absolute in the audit). q=4 misses the audit's 1e-3 absolute bound on all three datasets; with the new `q4_f_reltol = 1e-12` the PR reports 1e-4 agreement in log-likelihood, and says the default stops up to about 1e-3 short.
- Failed-fit NaN bridge (Julia side), NB2 `B > A` crash fix, guarded `cholesky` calls, Gamma sd-z alternative starts (2 of 3 known lower-mode seeds fixed, about 6.4x per fit). Censored routes not added (drmTMB has no censored likelihood, issue 1455).

### What did not go smoothly

- The R side of the failed-fit bridge is not done. `R/julia-bridge.R` near `new_drmTMB_julia` needs a change in a separate drmTMB PR.
- The Tweedie phylo sd-z fit failed its pre-registered thresholds (reported, not dropped); the note also left open whether the non-finite R SEs on sd-none fits are R's reporting or its own extraction.
- The audit's q=4 datasets missed the pre-registered bound; its own test uses a looser 1e-2 absolute bound and says so.

### Honest gaps added

1. Beta checked against 0.8.0 only; Julia 1.10 only; small datasets.
2. q=4 default tolerance stops up to about 1e-3 short; `bootstrap_q4_phylo.jl` does not forward `q4_f_reltol`.
3. Gamma sd-z: single-field `sd(g, phylo/spatial) ~ z` and NB2 two-field were not changed or tested; B2 seed 2 is Julia higher, R lower.
4. Binomial q=1 spatial still uses the old mean-distance kernel; the Julia 1.12 probit failure is seed luck per the audit.
5. The BLUP NaN path is unit-tested on the helper only. Older Gamma coordinate-spatial results shift (log SD up to about 0.02). REML still refuses on the other new routes.

### Known limitations and next actions

- Verdict flips remain PROPOSED, conditional on #1270 and its stack landing and the pin moving. The evidence supports agreement-at-optimum wording for Beta structured SD, Tweedie phylo/relmat (not phylo sd-z), Gaussian structured-sigma REML, the Gamma spatial q=1 kernel and bivariate q=2. It does not support q=4 at default settings, Gamma sd-z, failed-fit handling through the bridge or any censored shape. Details in `PROPOSED-verdict-flips.md`, section "Waves 7 and 8".
- Next: a separate drmTMB PR for the R-side failed-fit fields; resolve the Tweedie integrator wording; decide whether to repeat the Beta check against 0.8.1 and on Julia 1.12.

## Waves 8 and 9 addendum: gap map, 54 disagreements, DRModels.jl #1271 (2026-11-09)

Reader: whoever reviews PR #1684 or writes the later verdict PR. This lane edited only this file, `parity-crosswalk-evidence-20261107/PROPOSED-verdict-flips.md` and a new `check-log.d` file. No `R/`, `src/`, `NAMESPACE`, parity matrix, verdict file or test was changed, and no verdict flipped. I re-ran no R or Julia fit; numbers are copied from the files named below.

### Julia side

All DRAFT and unmerged (state read from GitHub 2026-11-09): DRModels.jl #1261, #1263, #1264, #1266, #1267, #1268, #1270 (waves 1 to 8) and #1271 (wave 9: Gaussian REML routes, Gaussian SD-gap shapes, classification of the 54 disagreements; head `claude/wave9-integration-20261109`, tip `f6417475b`, stacked on #1270). #1271 states: full suite on the exact tip, Julia 1.10.12 clean, Julia 1.12.7 only the five known failing files. That is the PR's statement, not verified here. A wave-10 PR (Binomial independent sd-z restarts, stacked on #1271) is in preparation.

### Results

- Wave-8 gap map (drmTMB branch `origin/claude/gap-map-wave8-20261108`, tip `6a7c37c0f`, not merged; cited from its README and `maps/w8/summary.json`), 3008 cells: 228 agree within 1e-4, 54 fit in both with log-likelihoods that disagree, 139 Julia refuses while R fits (145 Julia-behind with 5 non-converged and 1 timeout), 23 R refuses while Julia fits, 2558 both refuse, 0 crashes. R fits 427 cells and Julia 305. 19 cells moved from refusal to agreement between the old base and wave 8; none got worse.
- The 54 disagreements (DRModels.jl `docs/dev-log/2026-11-09-wave8-disagreements.md`): 47 integrator (R Laplace against Julia adaptive Gauss-Hermite), 3 model (deliberate), 4 optimum (2 with R lower, 2 with Julia lower), 0 Julia likelihood defects, 0 constant offsets. Cross-engine log-likelihood and AIC are therefore not comparable on ordinary routes. Structured Tweedie routes use Laplace in both engines per the earlier branch note, so cross-engine log-likelihood is valid there only at the optimum estimates.

### Honest gaps

- Julia-behind: the wave-8 count is 145; wave 9 closed some of them and I did not re-measure on the #1271 tip.
- Censored routes cannot be compared: drmTMB has no censored likelihood (issue 1455).
- Bivariate q=4 default tolerance stops about 1e-3 short (agreement to 1e-4 needs `q4_f_reltol = 1e-12`).
- Binomial q=1 spatial stays on the old mean-distance kernel.
- Two binomial independent-slope cells leave Julia at a lower optimum with no supported restart; wave 10 is meant to address this.
- Wave-9 REML agreement is one small dataset per route, no bootstrap or profile intervals; Julia 1.10.12 only for the map and the classification. Class assignment for cell 9 and cells 11, 19, 53 rests on weaker evidence (see the classification note).

### What did not go smoothly

The classification note's Tweedie statement (R Laplace against Julia exact quadrature) covers ordinary routes only. The earlier structured-route note says both engines use Laplace. I kept both statements and did not reconcile them for the structured routes.

### Known limitations and next actions

Verdict flips remain PROPOSED (see the section "Waves 8 and 9" in `PROPOSED-verdict-flips.md`) and happen only in a separate reviewed drmTMB PR after the Julia stack lands and the pin moves. Next: merge or pin-cite the gap-map branch, re-measure the grid on #1271, then on the wave-10 PR.

