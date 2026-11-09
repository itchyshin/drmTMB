# Refusal-gap map, wave-8 rerun: native Julia DRModels at wave 8 vs the old base, against R drmTMB 0.8.1, 2026-11-08

Reader: whoever owns the R-Julia parity lane. Purpose: rerun the 3008-cell refusal fuzz of `../fuzz-gap-map/` on the wave-8 Julia tip (DRM.jl PR #1270) and on the old base, and say what flipped to fit, whether anything got worse, and what Julia still refuses that R fits. Nothing here edits R/, src/ or the parity matrix.

## Bottom line

- Wave 8 (`479bbf963`) fits **305** of 3008 cells; the old base (`fd5d6c0dc`) fits 286; the original map's Julia commit (`759e58e4f`) fit 254. R fits 427 in all three.
- **19 cells flipped from refusing (or timing out) to a fit that agrees with R within 1e-4** (largest gap 8e-10). Nothing got worse: 0 cells where Julia went from fit to not-fit, 0 agree-to-disagree, 0 refusal-to-crash, 0 new crash types.
- **Crashes: 0 on both tips** (R also 0). The 729 keyword `MethodError`s of the original map are already refusals at the old base, so that fix landed before wave 8. No `AssertionError`, `PosDefException` or any other uncaught exception type appears on either tip, and no refusal message matched the numeric-failure regex.
- **Julia behind (R fits, Julia does not): 145 cells on wave 8** (139 refusals, 5 non-converged, 1 timeout), down from 164 on the old base (157 refusals, 5 non-converged, 2 timeouts) and 196 in the original map. Largest remaining groups: Gaussian REML routes (15), Gaussian SD formulas on `indep`/`crossed` (12), Gaussian labelled `(.. | p | g)` on `ordinary`/`crossed` (10), Gaussian crossed/ordinary q = 3, 4 (8).
- **Log-likelihood disagreements: 54 of 282 both-fit cells** (old base 57 of 263). The 3 that closed are Gamma spatial q = 1: Julia's logLik rose by 0.07 and now equals R. The other 54 did not change by more than 1e-6.
- The wave-8 flips are all Beta and Tweedie structured routes, which is what the wave-8 branch set out to add.

## Method

Same grid, data, runners and classifier as `../fuzz-gap-map/` (unchanged copies of `cells*.tsv`, `data/`, `run_r.R`, `run_julia.jl`, `driver.py`, `classify.py`). Thresholds and flip rules were written in `PREREGISTRATION.md` and committed before any result was read.

| Item | Value |
| --- | --- |
| R reference | drmTMB 0.8.1 from the Totoro library `~/drm_campaign_20261108/Rlib` (the same library as the original map), `engine = "tmb"`. Rerun in full: every one of the 3008 cells gives the same outcome and logLik (to 1e-8) as the original R run. |
| Julia, wave 8 | DRM.jl `origin/claude/wave8-integration-20261108` at `479bbf963`, Julia 1.10.12 on Totoro, `Pkg.develop` of a `git archive` of that commit. |
| Julia, old base | DRM.jl `fd5d6c0dc`, same Julia and depot. |
| Compute | Totoro only. R 10 workers (about 1.5 min). Julia 20 workers per tip, both tips at once (40 cores total, one thread per process, `nice -n 10`, `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=1`). Julia wall time 14.9 min for both tips together. Estimate up front was 1 to 1.5 h; it took about 25 min including setup. No process of mine is left running on Totoro. |
| Agreement | both FITS and the absolute logLik difference is at most 1e-4 (pre-registered, from the original harness). |
| Outcome rules | unchanged: FITS, REFUSES (`cli_abort`, or Julia `ArgumentError`/`ErrorException`), ERRORS (any other exception or a dead process), NONCONVERGED, TIMEOUT (180 s R, 300 s Julia). |

`julia_behind_*` ranking is by the number of cells that share one Julia refusal message. It is an upper bound on what one fix unlocks; a lifted refusal does not guarantee a converged, correct fit.

## Outcome table (all 3008 cells)

| Class | Original map (`759e58e4f`) | Old base (`fd5d6c0dc`) | Wave 8 (`479bbf963`) |
| --- | --- | --- | --- |
| Julia fits and agrees with R (<= 1e-4) | 175 | 206 | **228** |
| Julia fits and disagrees (> 1e-4) | 56 | 57 | **54** |
| Julia refuses, R fits | 181 | 157 | **139** |
| Julia fits, R refuses | 23 | 23 | **23** |
| Both refuse | 1838 | 2558 | **2558** |
| Crash (uncaught error) | 729 (Julia) | 0 | **0** |
| Non-converged (R fits or both) | 4 | 5 | **5** |
| Timeout (inconclusive) | 2 | 2 | **1** |
| Total | 3008 | 3008 | 3008 |

The original map and the old base differ in Julia commit and in the keyword `MethodError` fix, so the left column is context, not part of the pre-registered comparison. Files: `compare/outcome_table.tsv`, `compare/julia_modes.tsv`, `compare/transitions.tsv` (old to wave 8), `compare/transitions_vs_original.tsv`.

## Diff, old base to wave 8

| Transition | Cells |
| --- | --- |
| Julia refuses (R fits) to fits and agrees | 18 |
| Timeout to fits and agrees | 1 |
| Disagrees to agrees | 3 |
| Everything else unchanged (class identical) | 2986 |
| Got worse (any pre-registered rule) | **0** |

### Flipped to fit (19, `compare/flipped_to_fit.tsv`)

All 19 agree with R at most 8e-10 apart.

| Family | Shape | Cells | Detail |
| --- | --- | --- | --- |
| Beta | animal q = 2 | 2 | `sd-one`, `sd-z` |
| Beta | relmat q = 1 | 2 | `sd-one`, `sd-z` |
| Beta | relmat q = 2 | 2 | `sd-one`, `sd-z` (the `sd-z` cell has R `is_converged() = FALSE`) |
| Beta | phylo q = 1, q = 2 | 4 | `sd-one`, `sd-z` |
| Beta | spatial q = 1 | 2 | `sd-one`, `sd-z` |
| Beta | spatial q = 2 | 2 | `sd-one` (R `is_converged() = FALSE`), `sd-z` |
| Tweedie | relmat q = 1 | 2 | `sd-none`; `sd-z` was a Julia timeout on the old base |
| Tweedie | phylo q = 1 | 3 | `sd-none`, `sd-one`, `sd-z` |

### Disagreements that closed (3)

`gamma|spatial|lab0|q1|sd-none|cm0|ML`, `sd-one`, `sd-z`. Julia's logLik moved from -406.265 to -406.195 (and -404.338 to -404.276), which equals R. The original README listed Gamma spatial q = 1 as an unexplained Julia-lower gap of 0.06 to 0.07; at wave 8 it is gone.

### Got worse: none

Rules, fixed in advance: Julia FITS to not-fit; both-fit agreeing to disagreeing; Julia refuses to crashes; a crash type that is new for that cell. `compare/got_worse.tsv` has only its header. Also no fitted cell changed logLik by more than 1e-6 except the three Gamma spatial cells above (all improvements).

### Crashes that remain: none

`compare/remaining_crashes_wave8.tsv` is empty. Both tips: 2697 (wave 8) and 2715 (old base) of Julia's non-fits are deliberate `ArgumentError` or `ErrorException` refusals; 5 non-converged; 1 timeout. The refusal text includes a new kind: the Student route now says it "does not accept the keyword" and was refused before fitting, which is what replaced the original map's `MethodError`.

Non-converged on wave 8 (5, R fits): `poisson|spatial|lab0|q1|sd-none`, `nb2|animal|lab0|q2|sd-z`, `gamma|phylo|lab0|q1|sd-z`, `binomial|ordinary|lab0|q3|sd-z`, `gamma|indep|lab0|q2|sd-none`. Timeout (300 s): `binomial|ordinary|lab0|q4|sd-z`. The same five were non-converged on the old base.

## Log-likelihood disagreements still open (54)

`maps/w8/loglik_disagreements.tsv`. Not re-analysed here; the pattern equals the original map's. By shape: binomial ordinary 10, binomial indep 4, Poisson ordinary 4, NB2 ordinary 4, Gamma/Beta/Student ordinary 3 each, Tweedie ordinary 3, Tweedie slope 3, and slope-only cells (Poisson 2, NB2 2, Gamma 2, Binomial 2, Beta 2, Student 2), binomial animal 2, binomial spatial 2, Gaussian spatial 1. 48 have no quality flag; 5 have R `is_converged() = FALSE`; 1 has non-finite Julia SEs. The original README attributed the plain `(1 | g)` ones to Julia's default adaptive Gauss-Hermite integrator against R's Laplace (confirmed on 6 cells with `marginal = :Laplace`), and left the Tweedie ordinary and slope cells (6 here) unexplained. I did not repeat the Laplace re-run, so none of those attributions is re-tested at wave 8. Largest gap 1.8.

## What Julia still refuses that R fits: ranked (145 cells, 44 signatures)

Per-cell list: `maps/w8/julia_behind_ranked.tsv`; groups: `maps/w8/julia_behind_groups.tsv`. By family, R fits / Julia fits / Julia behind: Gaussian 123/75/54, Poisson 59/48/19, NB2 56/42/19, Gamma 46/43/5, Binomial 60/38/22, Beta 34/26/9, LogNormal 19/10/9, Student 14/10/5, Tweedie 16/13/3.

Short reading of the ranking:

1. Gaussian is 54 of the 145 cells (REML on structured, crossed, slope and indep shapes; SD formulas on `indep`/`crossed` slopes; labelled correlated blocks; q = 3, 4).
2. Independent intercept-plus-slope terms `(1 | g) + (0 + x | g)` (`indep`) are the largest non-Gaussian shape: 39 of the 91 non-Gaussian cells, across Poisson 11, NB2 9, Binomial 7, Gamma, Beta, LogNormal and Tweedie 3 each, with and without an SD formula.
3. Correlated ordinary blocks 13, spatial 11 and crossed 6 non-Gaussian cells.
4. Slope-only `(0 + x1 | g)` with no SD formula: 7 cells (Poisson, NB2, Gamma, Binomial x2, Beta, Student).
5. Binomial structured shapes (`animal`, `relmat`, `spatial`): 8 cells; Binomial REML: 2.

| Rank | Cells | Mode | Families | Shapes | Julia message (normalised) | Example cell |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 15 | refuses | gaussian:15 | crossed:7, indep:3, animal:1, relmat:1, spatial:1, phylo:1, slope:1 | drm: method = :REML is not implemented for this model on the generic univariate Gaussian route (random slopes, a random effect on sigma, a structured  | `gaussian|crossed|lab0|q2|sd-none|cm0|REML` |
| 2 | 12 | refuses | gaussian:12 | indep:8, crossed:4 | drm: sd() supports random INTERCEPT terms only. | `gaussian|indep|lab0|q2|sd-first|cm0|ML` |
| 3 | 10 | refuses | gaussian:10 | ordinary:7, crossed:3 | unsupported random-effect term: `T` | `gaussian|crossed|lab1|q2|sd-none|cm0|ML` |
| 4 | 8 | refuses | gaussian:6, binomial:2 | ordinary:6, crossed:2 | DRModels.jl supports `T`, `T`, `T` | `gaussian|crossed|lab0|q3|sd-none|cm0|ML` |
| 5 | 6 | refuses | poisson:6 | indep:4, crossed:2 | Poisson random-effect SD regression requires exactly one SD target. | `poisson|indep|lab0|q2|sd-z|cm0|ML` |
| 6 | 6 | refuses | gaussian:6 | animal:2, relmat:2, spatial:2 | drm: Gaussian structured intercept SD regression supports maximum likelihood only. | `gaussian|animal|lab0|q1|sd-one|cm0|REML` |
| 7 | 5 | nonconverged | gamma:2, poisson:1, binomial:1, nb2:1 | indep:1, spatial:1, ordinary:1, phylo:1, animal:1 |  | `gamma|indep|lab0|q2|sd-none|cm0|ML` |
| 8 | 5 | refuses | beta:2, gaussian:2, binomial:1 | relmat:3, spatial:2 | drm: `T` is not implemented on the univariate routes; only the intercept form is admitted on this route | `beta|spatial|lab0|q2|sd-none|cm0|ML` |
| 9 | 4 | refuses | poisson:4 | indep:4 | Poisson `T` currently requires exactly one ordinary independent random effect. | `poisson|indep|lab0|q2|sd-first|cm0|ML` |
| 10 | 4 | refuses | nb2:4 | indep:4 | NegBinomialN `T` currently requires exactly one ordinary random intercept or one independent slope. | `nb2|indep|lab0|q2|sd-first|cm0|ML` |
| 11 | 4 | refuses | binomial:4 | indep:4 | Binomial SD regression requires one SD formula for each independent random-effect coefficient. | `binomial|indep|lab0|q2|sd-first|cm0|ML` |
| 12 | 4 | refuses | binomial:2, gaussian:1, beta:1 | animal:4 | drm: `T` is not implemented on the univariate routes; only the intercept form is generally available, and a slope-only or independent intercept-and-sl | `gaussian|animal|lab0|q2|sd-none|cm0|REML` |
| 13 | 4 | refuses | lognormal:4 | crossed:2, ordinary:2 | LogNormal SD regression currently requires one ordinary mean-effect `T` formula. | `lognormal|crossed|lab0|q1|sd-one|cm0|ML` |
| 14 | 3 | refuses | beta:3 | indep:3 | Beta() supports multiple random effects only as crossed/nested intercepts, e.g. `T` | `beta|indep|lab0|q2|sd-none|cm0|ML` |
| 15 | 3 | refuses | poisson:3 | indep:3 | Poisson() supports multiple random effects only as crossed/nested intercepts, e.g. `T` | `poisson|indep|lab0|q2|sd-none|cm0|ML` |
| 16 | 3 | refuses | binomial:3 | indep:3 | Binomial() supports multiple random effects only as crossed/nested intercepts, e.g. `T` | `binomial|indep|lab0|q2|sd-none|cm0|ML` |
| 17 | 3 | refuses | nb2:3 | indep:3 | NegBinomialN() supports multiple random effects only as crossed/nested intercepts, e.g. `T` | `nb2|indep|lab0|q2|sd-none|cm0|ML` |
| 18 | 3 | refuses | lognormal:3 | indep:3 | LogNormal() supports multiple random effects only as crossed/nested intercepts, e.g. `T` | `lognormal|indep|lab0|q2|sd-none|cm0|ML` |
| 19 | 3 | refuses | tweedie:3 | indep:3 | Tweedie() supports multiple random effects only as crossed/nested intercepts, e.g. `T` | `tweedie|indep|lab0|q2|sd-none|cm0|ML` |
| 20 | 3 | refuses | binomial:3 | spatial:1, relmat:1, animal:1 | Binomial() currently supports only phylo(N \| group) among structured markers | `binomial|spatial|lab0|q1|sd-none|cm0|ML` |
| 21 | 2 | refuses | nb2:1, beta:1 | spatial:2 | spatial(N \| g) for counts needs either a precomputed spatial covariance via `T`, or site `T` (a G×N coordinate matrix) for coordinate-based exponenti | `nb2|spatial|lab0|q1|sd-none|cm0|ML` |
| 22 | 2 | refuses | gamma:2 | indep:2 | Gamma `T` currently requires exactly one ordinary independent random effect. | `gamma|indep|lab0|q2|sd-first|cm0|ML` |
| 23 | 2 | refuses | student:2 | spatial:2 | drm: the Student route does not accept the keyword `T`. It was refused before any fitting, not run with the keyword ignored. `T`: `T` is read by a `T` | `student|spatial|lab0|q1|sd-none|cm0|ML` |
| 24 | 2 | refuses | lognormal:2 | ordinary:2 | LogNormal `T` supports `T` or one independent numeric `T` term; correlated blocks are not implemented on this route. | `lognormal|ordinary|lab0|q2|sd-first|cm0|ML` |
| 25 | 2 | refuses | nb2:2 | indep:2 | NegBinomialN random-effect SD regression requires exactly one `T` formula. | `nb2|indep|lab0|q3|sd-z|cm0|ML` |
| 26 | 2 | refuses | nb2:2 | ordinary:2 | NegBinomialN `T` supports `T` or one independent numeric slope `T`; correlated blocks are not implemented on this route. | `nb2|ordinary|lab0|q2|sd-first|cm0|ML` |
| 27 | 2 | refuses | nb2:2 | spatial:2 | NegBinomialN spatial SD regression supports only the slope-only `T` term with `T`. | `nb2|spatial|lab0|q1|sd-one|cm0|ML` |
| 28 | 2 | refuses | poisson:2 | ordinary:2 | Poisson `T` SD regression needs one SD formula for the intercept and one for the slope (`T` and `T`). | `poisson|ordinary|lab0|q2|sd-first|cm0|ML` |
| 29 | 2 | refuses | poisson:2 | spatial:2 | Poisson SD regression currently targets one ordinary mean random-effect coefficient. | `poisson|spatial|lab0|q1|sd-one|cm0|ML` |
| 30 | 2 | refuses | binomial:2 | slope:1, ordinary:1 | drm (Binomial): unknown `T`. Binomial is ML-only; for the integrator use `T` (the documented default integrator for this route), `T` (TMB-convention L | `binomial|slope|lab0|q1|sd-none|cm0|REML` |
| 31 | 2 | refuses | nb2:2 | phylo:2 | NegBinomialN `T` supports ordinary effects, an animal intercept with `T` or `T`, a relmat intercept with `T`, or a coordinate `T` slope with `T`; othe | `nb2|phylo|lab0|q1|sd-z|cm0|ML` |
| 32 | 2 | refuses | student:2 | crossed:2 | Student random-effect SD regression currently requires exactly one `T` formula. | `student|crossed|lab0|q1|sd-one|cm0|ML` |
| 33 | 2 | refuses | binomial:2 | relmat:2 | Binomial relmat SD regression currently requires exactly one `T` formula. | `binomial|relmat|lab0|q2|sd-one|cm0|ML` |
| 34 | 1 | refuses | binomial:1 | slope:1 | Binomial() supports `T` or `T` on the mean | `binomial|slope|lab0|q1|sd-none|cm0|ML` |
| 35 | 1 | refuses | gaussian:1 | crossed:1 | a correlated `T` block must be the only random-effect term | `gaussian|crossed|lab0|q2|sd-none|cm0|ML` |
| 36 | 1 | refuses | beta:1 | slope:1 | Beta() supports `T` or `T` on the mean, not `T` | `beta|slope|lab0|q1|sd-none|cm0|ML` |
| 37 | 1 | refuses | nb2:1 | slope:1 | NegBinomialN() supports (N\|g) or (N+x\|g) on the mean | `nb2|slope|lab0|q1|sd-none|cm0|ML` |
| 38 | 1 | refuses | poisson:1 | slope:1 | Poisson() supports `T` or `T` random effects on the mean | `poisson|slope|lab0|q1|sd-none|cm0|ML` |
| 39 | 1 | refuses | student:1 | slope:1 | Student() supports `T` or `T` random effects on the mean | `student|slope|lab0|q1|sd-none|cm0|ML` |
| 40 | 1 | refuses | gamma:1 | slope:1 | Gamma() supports `T` or `T` on the mean | `gamma|slope|lab0|q1|sd-none|cm0|ML` |
| 41 | 1 | refuses | beta:1 | phylo:1 | drm: `T` is not implemented on this route - only `T` (intercept) is here. The two-SD phylogenetic random intercept + slope `T` is implemented for the  | `beta|phylo|lab0|q2|sd-none|cm0|ML` |
| 42 | 1 | timeout | binomial:1 | ordinary:1 |  | `binomial|ordinary|lab0|q4|sd-z|cm0|ML` |
| 43 | 1 | refuses | gaussian:1 | ordinary:1 | drm: sd() submodels cannot be combined with a random effect on `T`. | `gaussian|ordinary|lab0|q1|sd-z|cm1|ML` |
| 44 | 1 | refuses | nb2:1 | phylo:1 | drm: `T` is not implemented on the univariate routes - only `T` (intercept) is, plus the one-slope `T` on the Gaussian mean (#N); slope-only `T` and m | `nb2|phylo|lab1|q2|sd-none|cm0|ML` |

## What this does not show

- Same limits as the original map: it maps what fits, and the only correctness check is logLik on both-fit cells. Estimates, SEs and intervals were not compared. One data set per family and shape, 400 rows, one seed; `FITS` means the optimiser reported convergence.
- Structured inputs are passed one way each (`coords` as a Dict, `A` with `ids`, `K`, `tree` as Newick). The original map found the matrix form of `coords` flipped 2 binomial spatial cells; I did not rerun that variant, so a few `spatial` refusals may be input-form artefacts. The Beta spatial flips here already use the Dict form.
- The Laplace re-run for the integrator disagreements was not repeated.
- I did not check which commit built the Totoro R library (same library as the original map; same outcomes in every cell).
- The wave-8 refusal groups are normalised messages; the ranking was not re-checked against the matrix.
- "Old base `fd5d6c0dc`" was run exactly as specified in the task; the original map used a different Julia commit, so the third column of the outcome table is context only.

## Files

| File | Content |
| --- | --- |
| `PREREGISTRATION.md` | thresholds and flip rules, committed before results |
| `compare/` | outcome table, Julia mode counts, transitions, flipped, got-worse (empty), remaining crashes (empty), newly both-fit, R stability |
| `maps/w8/`, `maps/old/` | full classifier output for each tip (`gap_map.tsv`, ranked behind list, disagreements, summaries) |
| `raw/r`, `raw/julia-w8`, `raw/julia-old` | verbatim runner output and driver logs |
| `compare.py`, `classify.py`, `driver.py`, `run_r.R`, `run_julia.jl`, `gen_cells.jl`, `cells*.tsv`, `data/` | harness |

## Reproduce

Cells file `cells_run.tsv` is `cells.tsv` followed by the data rows of `cells_indep.tsv` and `cells_slope.tsv`.

```sh
cd harness
R_LIBS=<lib with drmTMB 0.8.1> python3 driver.py r 10 180 cells_run.tsv out/r
FUZZ_JULIA_PROJECT=<env with DRModels developed at the commit> python3 driver.py julia 20 300 cells_run.tsv out/julia
python3 -I classify.py <dir with r/ and julia/> maps/<tip>
python3 -I compare.py ../fuzz-gap-map/gap_map.tsv maps/old/gap_map.tsv maps/w8/gap_map.tsv compare
```
