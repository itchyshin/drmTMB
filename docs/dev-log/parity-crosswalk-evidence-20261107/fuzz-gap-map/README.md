# Refusal-gap map: native R drmTMB 0.8.1 vs native Julia DRModels, 2026-11-08

Reader: whoever owns the Julia parity lane and the capability matrix. Purpose: replace hand-picked parity shapes with a
generated cross-product of the SD-regression grammar, run both engines on every cell, and show where Julia is behind,
where Julia fails with an uncaught error instead of a refusal, and where the two disagree on the log-likelihood.
Nothing here flips a verdict, edits the matrix, or touches `tools/write-parity-matrix.R`.

## Bottom line

- 3008 cells (9 families x 8 random-effect shapes x labelling x q x SD pattern x ML/REML, plus mu+sigma blocks). R drmTMB 0.8.1 fits 427 of them, Julia fits 254.
- Both fit: **231** cells. Of these **175 agree on logLik within 1e-4** (largest gap among agreeing cells 2.6e-06); **56 disagree**, listed below with the cause where I could establish one.
- **Julia behind (R fits, Julia does not): 196 cells** (181 refusals, 9 uncaught errors, 4 non-converged, 2 timeouts). They fall into 51 distinct Julia refusal signatures, ranked in `julia_behind_groups.tsv`.
- **Julia ahead (Julia fits, R refuses): 23 cells** (mostly Poisson/NB2 labelled q=2, Poisson REML, Gaussian REML with SD formulas).
- **Crashes: R none, Julia 729.** All 2581 R failures are deliberate `cli_abort` refusals. All 729 Julia errors are one mechanism, an uncaught `MethodError` when a keyword is passed to a family route that does not take it (`method = :REML` on LogNormal, Student and Tweedie; `tree`/`K`/`coords`/`A,ids` on routes without that structured provider). The same call without the keyword gives a readable refusal. Only 9 of the 729 crash cells are cells R fits.
- **Matrix cross-check:** the matrix file at the path given is a dirty working-tree draft 809 commits behind origin/main. Against that draft the map contradicts one sub-claim (unlabelled correlated q=2 blocks with a selected-slope SD formula for Beta, Gamma and Student-t are refused by R 0.8.1). Against origin/main's matrix the map shows the opposite error: it says binomial random effects are unavailable, and R 0.8.1 fits them. Details in the cross-check section.
- Two things worth acting on first: (1) the keyword `MethodError`s, which are cheap to turn into refusals; (2) the largest Julia-behind groups, which are mostly Beta/Gamma/NB2/Poisson slope or structured shapes that R fits.

## What was run

| Item | Value |
| --- | --- |
| R | drmTMB 0.8.1 (`DESCRIPTION` Version 0.8.1), Totoro library `~/drm_campaign_20261108/Rlib`. I did not verify which commit that library was built from. |
| Julia | DRModels 0.8.1 at `759e58e4f` (origin/claude/binomial-phylo-spatial-q2-20261108), Julia 1.10 on Totoro, 1.10.0 on the Mac. No Julia source was changed (branch `claude/fuzz-gap-map-20261108` exists locally with no commits). |
| Engines | Both native. R `engine = "tmb"`, Julia `drm()`. No `engine = "julia"`, no JuliaCall. Run as separate processes. |
| Data | One simulated data set per family x kind (54 files in `data/`), 40 groups x 10 rows (30 levels for the crossed second factor), `StableRNG` seeds in `gen_cells.jl`. Generation is deterministic: re-running it reproduced every data file byte for byte. |
| Compute | Totoro, 15 to 20 one-thread workers per engine, never more than 40 cores, `nice -n 10`. Main pass: R 26 s, Julia 12.6 min wall. Follow-up passes a few minutes each. Estimated up front at 30 to 60 min; it took about 25 min of wall time in total. No Totoro processes were left running. |

### The grid

| Axis | Levels |
| --- | --- |
| family | gaussian, poisson, nb2, gamma, binomial (logit, 0/1), beta, lognormal, student, tweedie (R `beta_family()`, `nbinom2()`, `Gamma(link = "log")`; Julia `Beta()`, `NegBinomial2()`, `Gamma()`) |
| random-effect shape (`kind`) | `ordinary` `(terms \| g)`; `animal(A)`; `relmat(K)`; `phylo` (random tree); `spatial` (coordinates); `crossed` `(terms \| g) + (1 \| g2)`; `indep` `(1 \| g) + (0 + x1 \| g) + ...`; `slope` `(0 + x1 \| g)` |
| q (coefficients in the block) | 1, 2, 3, 4 (`1 + x1 + x2 + x3`); `indep` q = 2..4; `slope` q = 1 |
| labelled | unlabelled `(.. \| g)` or labelled `(.. \| p \| g)`, for q >= 2 |
| SD formula pattern | `none` (no `sd()`), `one` (`~ 1` on every coefficient), `z` (`~ z` on every coefficient), `first` (`~ z` on the intercept only), `last` (`~ z` on the last coefficient only; q = 2 only). q = 1: none, one, z. q = 3, 4: none, z, first. |
| correlated mu+sigma | `(1 \| p \| g)` in both `mu` and `sigma` (q = 1 or 2, ordinary, families with a `sigma`, patterns none and z) |
| estimator | ML, REML (R `REML = TRUE`, Julia `method = :REML`) |

`indep` and `slope` were added in a second pass, after the first results showed that the matrix's "independent-slope" wording means these shapes and not `(1 + x | g)`. Cell counts: animal 450, crossed 450, indep 198, ordinary 506, phylo 450, relmat 450, slope 54, spatial 450.

### How an outcome is decided

| Outcome | Rule |
| --- | --- |
| FITS | the call returned, the log-likelihood is finite, and R `opt$convergence == 0` or Julia `fit.converged == true`. Quality flags (R `pdHess = FALSE` or `is_converged() = FALSE`; Julia non-finite SEs or a -1e18 sentinel) are recorded in `quality_flag` and do not change the outcome. |
| REFUSES | R: a `cli_abort()` condition (class `rlang_error`; all 2581 R failures are this). Julia: `ArgumentError` or `ErrorException` raised on purpose with model-support text (1771 `ArgumentError`, 248 bare `error()` calls). A numeric-failure regex was applied to both and matched nothing. |
| ERRORS (crash) | anything else: a non-`rlang` R error, any Julia exception other than the two above, or a process that died. The watchdog also catches hangs (TIMEOUT) and segfaults (process died); neither occurred as a crash. |
| NONCONVERGED | returned, but the convergence flag is false. |
| TIMEOUT | no result for 180 s (R) or 300 s (Julia). Reported as inconclusive, never as a gap. |

Cell classes: `both-fit`; `R-only` (R fits, Julia refuses); `Julia-only`; `both-refuse`; `crash-Julia` / `crash-R` (an uncaught error on that side, whatever the other side did); `nonconverged`; `inconclusive` (timeout). The "Julia behind" list is every cell where R fits and Julia does not fit, whatever the Julia failure mode.

## Results

| Class | Cells | Share |
| --- | --- | --- |
| both-fit | 231 | 8% |
| R-only | 181 | 6% |
| Julia-only | 23 | 1% |
| both-refuse | 1838 | 61% |
| crash-Julia | 729 | 24% |
| crash-R | 0 | 0% |
| nonconverged | 4 | 0% |
| inconclusive | 2 | 0% |
| total | 3008 | |

| Engine | FITS | REFUSES | ERRORS | NONCONVERGED | TIMEOUT |
| --- | --- | --- | --- | --- | --- |
| R drmTMB 0.8.1 | 427 | 2581 | 0 | 0 | 0 |
| Julia DRModels | 254 | 2019 | 729 | 4 | 2 |

Per family and shape: `breakdown_family_kind.tsv`. Per refusal message: `signatures_r.tsv`, `signatures_julia.tsv`.

## Crash cells (uncaught errors that are not refusals)

R: **none**. Julia: **729 cells, all `MethodError`**, three mechanisms:

| Family | Keyword that was passed | Cells | Example cell |
| --- | --- | --- | --- |
| binomial | `A,ids` | 25 | `binomial|animal|lab0|q1|sd-none|cm0|ML` |
| binomial | `method,A,ids` | 25 | `binomial|animal|lab0|q1|sd-none|cm0|REML` |
| lognormal | `A,ids` | 25 | `lognormal|animal|lab0|q1|sd-none|cm0|ML` |
| lognormal | `coords` | 25 | `lognormal|spatial|lab0|q1|sd-none|cm0|ML` |
| lognormal | `method` | 68 | `lognormal|ordinary|lab0|q1|sd-none|cm0|REML` |
| lognormal | `method,A,ids` | 25 | `lognormal|animal|lab0|q1|sd-none|cm0|REML` |
| lognormal | `method,K` | 25 | `lognormal|relmat|lab0|q1|sd-none|cm0|REML` |
| lognormal | `method,coords` | 25 | `lognormal|spatial|lab0|q1|sd-none|cm0|REML` |
| lognormal | `method,tree` | 25 | `lognormal|phylo|lab0|q1|sd-none|cm0|REML` |
| student | `A,ids` | 25 | `student|animal|lab0|q1|sd-none|cm0|ML` |
| student | `K` | 25 | `student|relmat|lab0|q1|sd-none|cm0|ML` |
| student | `coords` | 25 | `student|spatial|lab0|q1|sd-none|cm0|ML` |
| student | `method` | 68 | `student|ordinary|lab0|q1|sd-none|cm0|REML` |
| student | `method,A,ids` | 25 | `student|animal|lab0|q1|sd-none|cm0|REML` |
| student | `method,K` | 25 | `student|relmat|lab0|q1|sd-none|cm0|REML` |
| student | `method,coords` | 25 | `student|spatial|lab0|q1|sd-none|cm0|REML` |
| student | `method,tree` | 25 | `student|phylo|lab0|q1|sd-none|cm0|REML` |
| student | `tree` | 25 | `student|phylo|lab0|q1|sd-none|cm0|ML` |
| tweedie | `A,ids` | 25 | `tweedie|animal|lab0|q1|sd-none|cm0|ML` |
| tweedie | `method` | 68 | `tweedie|ordinary|lab0|q1|sd-none|cm0|REML` |
| tweedie | `method,A,ids` | 25 | `tweedie|animal|lab0|q1|sd-none|cm0|REML` |
| tweedie | `method,K` | 25 | `tweedie|relmat|lab0|q1|sd-none|cm0|REML` |
| tweedie | `method,coords` | 25 | `tweedie|spatial|lab0|q1|sd-none|cm0|REML` |
| tweedie | `method,tree` | 25 | `tweedie|phylo|lab0|q1|sd-none|cm0|REML` |

Probe `probe_kwargs.jl` (log `probe_kwargs.log`) shows the user-visible difference. `drm(LogNormal(); method = :REML)`, `Student()`, `Tweedie()` raise a bare `MethodError`, while Gamma, NB2, Beta and Binomial raise `ArgumentError: unknown method = :REML ... ML-only`. LogNormal/animal with `A, ids` is a `MethodError`; the same call without `A` is `LogNormal() supports phylo/relmat structured markers on the mean (got animal)`. So the fix is to make the keyword-accepting signature uniform (or catch `MethodError` on the entry point), not to add a model.

The 9 crash cells where R fits (Julia is behind and also unfriendly): `binomial|animal|lab0|q1|sd-none|cm0|ML`; `binomial|animal|lab0|q1|sd-one|cm0|ML`; `binomial|animal|lab0|q1|sd-z|cm0|ML`, ... (binomial animal x7, student spatial x2; full list in `crash_cells.tsv`).

Other failure modes outside the crash class: one Julia route returns normally with a sentinel log-likelihood, `poisson|spatial|lab0|q1|sd-none` (`coords`-estimated range): `drm()` returns a fit with `loglikelihood = -1.0e18`, `converged = false` and a singular-Hessian warning (see `probe_spatial_coords.log`). It is recorded as NONCONVERGED. Beta and NB2 plain `spatial(1 | g)` with `coords = ...` raise an error whose text says `coords` is accepted; passing `K = <precomputed kernel>` fits (`probe_spatial_coords.jl`), so for those cells the gap is the `coords` route only.

## Julia behind: the work list, ranked

196 cells where R fits and Julia does not. They collapse into 51 Julia failure signatures. Ranking is by cells in the signature group, which is what a single fix can unlock at most (fixing a refusal does not guarantee a converged, correct fit). `julia_behind_ranked.tsv` and `julia_behind_ranked.md` list every cell with `unlocks` (group size) and `behind_neighbours` (cells that differ in exactly one grid coordinate and are also behind).

| Rank | Cells | Julia mode | Families (cells) | Shapes (cells) | Julia message (normalised) | Example |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 16 | refuses | poisson:4, gaussian:4, beta:2, gamma:2, binomial:2, nb2:2 | spatial:8, relmat:8 | drm: `T` is not implemented on the univariate routes; only the intercept form is admitted on this route | `beta|spatial|lab0|q2|sd-none|cm0|ML` |
| 2 | 15 | refuses | gaussian:15 | crossed:7, indep:3, animal:1, relmat:1, spatial:1, phylo:1, slope:1 | drm: method = :REML is not implemented for this model on the generic univariate Gaussian route (random slopes, a random effect on ... | `gaussian|crossed|lab0|q2|sd-none|cm0|REML` |
| 3 | 12 | refuses | gaussian:12 | indep:8, crossed:4 | drm: sd() supports random INTERCEPT terms only. | `gaussian|indep|lab0|q2|sd-first|cm0|ML` |
| 4 | 10 | refuses | beta:10 | relmat:4, spatial:4, phylo:2 | Beta `T` accepts no `T`, `T`, or `T` input on this route. | `beta|phylo|lab0|q2|sd-one|cm0|ML` |
| 5 | 10 | refuses | gaussian:10 | ordinary:7, crossed:3 | unsupported random-effect term: `T` | `gaussian|crossed|lab1|q2|sd-none|cm0|ML` |
| 6 | 8 | refuses | gaussian:6, binomial:2 | ordinary:6, crossed:2 | DRModels.jl supports `T`, `T`, `T` | `gaussian|crossed|lab0|q3|sd-none|cm0|ML` |
| 7 | 7 | refuses | poisson:2, gaussian:2, beta:1, gamma:1, nb2:1 | animal:7 | drm: `T` is not implemented on the univariate routes; only the intercept form is generally available, and a slope-only or independ... | `beta|animal|lab0|q2|sd-none|cm0|ML` |
| 8 | 7 | crashes | binomial:7 | animal:7 | MethodError: no method matching keyword call _drm_binomial_fit with keywords (kw) | `binomial|animal|lab0|q1|sd-none|cm0|ML` |
| 9 | 6 | refuses | poisson:6 | indep:4, crossed:2 | Poisson random-effect SD regression requires exactly one SD target. | `poisson|indep|lab0|q2|sd-z|cm0|ML` |
| 10 | 6 | refuses | gamma:6 | phylo:4, spatial:2 | Gamma structured SD regression requires exactly one random-effect SD formula. | `gamma|phylo|lab0|q2|sd-z|cm0|ML` |
| 11 | 6 | refuses | gaussian:6 | animal:2, relmat:2, spatial:2 | drm: Gaussian structured intercept SD regression supports maximum likelihood only. | `gaussian|animal|lab0|q1|sd-one|cm0|REML` |
| 12 | 5 | refuses | beta:1, gamma:1, nb2:1, poisson:1, binomial:1 | phylo:5 | drm: `T` is not implemented on this route — only `T` (intercept) is here. The two-SD phylogenetic random intercept + slope `T` is ... | `beta|phylo|lab0|q2|sd-none|cm0|ML` |
| 13 | 4 | nonconverged | gamma:2, poisson:1, binomial:1 | indep:1, spatial:1, phylo:1, ordinary:1 |  | `gamma|indep|lab0|q2|sd-none|cm0|ML` |
| 14 | 4 | refuses | poisson:4 | indep:4 | Poisson `T` currently requires exactly one ordinary independent random effect. | `poisson|indep|lab0|q2|sd-first|cm0|ML` |
| 15 | 4 | refuses | nb2:4 | indep:4 | NegBinomialN `T` currently requires exactly one ordinary random intercept or one independent slope. | `nb2|indep|lab0|q2|sd-first|cm0|ML` |
| 16 | 4 | refuses | binomial:4 | indep:4 | Binomial SD regression requires one SD formula for each independent random-effect coefficient. | `binomial|indep|lab0|q2|sd-first|cm0|ML` |
| 17 | 4 | refuses | tweedie:4 | phylo:3, relmat:1 | Tweedie structured covariance inputs (`T`, `T`, `T`, `T`) are only used by supported structured SD routes; this formula has no ran... | `tweedie|phylo|lab0|q1|sd-z|cm0|ML` |
| 18 | 4 | refuses | lognormal:4 | crossed:2, ordinary:2 | LogNormal SD regression currently requires one ordinary mean-effect `T` formula. | `lognormal|crossed|lab0|q1|sd-one|cm0|ML` |
| 19 | 3 | refuses | poisson:3 | indep:3 | Poisson() supports multiple random effects only as crossed/nested intercepts, e.g. `T` | `poisson|indep|lab0|q2|sd-none|cm0|ML` |
| 20 | 3 | refuses | nb2:3 | indep:3 | NegBinomialN() supports multiple random effects only as crossed/nested intercepts, e.g. `T` | `nb2|indep|lab0|q2|sd-none|cm0|ML` |
| 21 | 3 | refuses | binomial:3 | indep:3 | Binomial() supports multiple random effects only as crossed/nested intercepts, e.g. `T` | `binomial|indep|lab0|q2|sd-none|cm0|ML` |
| 22 | 3 | refuses | beta:3 | indep:3 | Beta() supports multiple random effects only as crossed/nested intercepts, e.g. `T` | `beta|indep|lab0|q2|sd-none|cm0|ML` |
| 23 | 3 | refuses | lognormal:3 | indep:3 | LogNormal() supports multiple random effects only as crossed/nested intercepts, e.g. `T` | `lognormal|indep|lab0|q2|sd-none|cm0|ML` |
| 24 | 3 | refuses | tweedie:3 | indep:3 | Tweedie() supports multiple random effects only as crossed/nested intercepts, e.g. `T` | `tweedie|indep|lab0|q2|sd-none|cm0|ML` |
| 25 | 2 | refuses | beta:1, nb2:1 | spatial:2 | spatial(N \| g) for counts needs either a precomputed spatial covariance via `T`, or site `T` (a G×N coordinate matrix) for coordi... | `beta|spatial|lab0|q1|sd-none|cm0|ML` |
| 26 | 2 | refuses | binomial:2 | spatial:1, relmat:1 | Binomial() currently supports only phylo(N \| group) among structured markers | `binomial|spatial|lab0|q1|sd-none|cm0|ML` |
| 27 | 2 | refuses | beta:2 | phylo:2 | drm: random-effect `T` formulas are currently supported for Gaussian LSS models and narrow ordinary IID routes in Binomial, Poisso... | `beta|phylo|lab0|q1|sd-z|cm0|ML` |
| 28 | 2 | crashes | student:2 | spatial:2 | MethodError: no method matching keyword call _drm_student_fit with keywords (kw) | `student|spatial|lab0|q2|sd-none|cm0|ML` |
| 29 | 2 | refuses | beta:2 | animal:2 | Beta random-effect SD regression requires exactly one `T` formula. | `beta|animal|lab0|q2|sd-one|cm0|ML` |
| 30 | 2 | refuses | gamma:2 | indep:2 | Gamma `T` currently requires exactly one ordinary independent random effect. | `gamma|indep|lab0|q2|sd-first|cm0|ML` |
| 31 | 2 | refuses | lognormal:2 | ordinary:2 | LogNormal `T` supports `T` or one independent numeric `T` term; correlated blocks are not implemented on this route. | `lognormal|ordinary|lab0|q2|sd-first|cm0|ML` |
| 32 | 2 | refuses | nb2:2 | indep:2 | NegBinomialN random-effect SD regression requires exactly one `T` formula. | `nb2|indep|lab0|q3|sd-z|cm0|ML` |
| 33 | 2 | refuses | nb2:2 | phylo:2 | NegBinomialN `T` supports ordinary effects, an animal intercept with `T` or `T`, a relmat intercept with `T`, or a coordinate `T` ... | `nb2|phylo|lab0|q1|sd-z|cm0|ML` |
| 34 | 2 | refuses | nb2:2 | spatial:2 | NegBinomialN spatial SD regression supports only the slope-only `T` term with `T`. | `nb2|spatial|lab0|q1|sd-one|cm0|ML` |
| 35 | 2 | refuses | poisson:1, nb2:1 | phylo:2 | drm: `T` is not implemented on the univariate routes — only `T` (intercept) is, plus the one-slope `T` on the Gaussian mean (#N); ... | `poisson|phylo|lab1|q2|sd-none|cm0|ML` |
| 36 | 2 | refuses | poisson:2 | spatial:2 | Poisson SD regression currently targets one ordinary mean random-effect coefficient. | `poisson|spatial|lab0|q1|sd-one|cm0|ML` |
| 37 | 2 | refuses | binomial:2 | relmat:2 | Binomial relmat SD regression currently requires exactly one `T` formula. | `binomial|relmat|lab0|q2|sd-one|cm0|ML` |
| 38 | 2 | refuses | nb2:2 | ordinary:2 | NegBinomialN `T` supports `T` or one independent numeric slope `T`; correlated blocks are not implemented on this route. | `nb2|ordinary|lab0|q2|sd-first|cm0|ML` |
| 39 | 2 | refuses | poisson:2 | ordinary:2 | Poisson `T` SD regression needs one SD formula for the intercept and one for the slope (`T` and `T`). | `poisson|ordinary|lab0|q2|sd-first|cm0|ML` |
| 40 | 2 | refuses | binomial:2 | phylo:2 | Binomial `T` SD regression: the labelled correlated form `T` is not supported (native drmTMB N does not fit it for Binomial either... | `binomial|phylo|lab1|q2|sd-one|cm0|ML` |
| 41 | 2 | refuses | binomial:2 | slope:1, ordinary:1 | drm (Binomial): unknown `T`. Binomial is ML-only; for the integrator use `T` (the documented default integrator for this route), `... | `binomial|slope|lab0|q1|sd-none|cm0|REML` |
| 42 | 2 | refuses | student:2 | crossed:2 | Student random-effect SD regression currently requires exactly one `T` formula. | `student|crossed|lab0|q1|sd-one|cm0|ML` |
| 43 | 2 | timeout | tweedie:1, binomial:1 | relmat:1, ordinary:1 |  | `tweedie|relmat|lab0|q1|sd-z|cm0|ML` |
| 44 | 1 | refuses | gaussian:1 | crossed:1 | a correlated `T` block must be the only random-effect term | `gaussian|crossed|lab0|q2|sd-none|cm0|ML` |
| 45 | 1 | refuses | binomial:1 | slope:1 | Binomial() supports `T` or `T` on the mean | `binomial|slope|lab0|q1|sd-none|cm0|ML` |
| 46 | 1 | refuses | beta:1 | slope:1 | Beta() supports `T` or `T` on the mean, not `T` | `beta|slope|lab0|q1|sd-none|cm0|ML` |
| 47 | 1 | refuses | nb2:1 | slope:1 | NegBinomialN() supports (N\|g) or (N+x\|g) on the mean | `nb2|slope|lab0|q1|sd-none|cm0|ML` |
| 48 | 1 | refuses | poisson:1 | slope:1 | Poisson() supports `T` or `T` random effects on the mean | `poisson|slope|lab0|q1|sd-none|cm0|ML` |
| 49 | 1 | refuses | student:1 | slope:1 | Student() supports `T` or `T` random effects on the mean | `student|slope|lab0|q1|sd-none|cm0|ML` |
| 50 | 1 | refuses | gamma:1 | slope:1 | Gamma() supports `T` or `T` on the mean | `gamma|slope|lab0|q1|sd-none|cm0|ML` |
| 51 | 1 | refuses | gaussian:1 | ordinary:1 | drm: sd() submodels cannot be combined with a random effect on `T`. | `gaussian|ordinary|lab0|q1|sd-z|cm1|ML` |

`T` stands for a code term that was removed during normalisation. Rows with an empty message are non-converged or timed-out cells.

## Julia ahead (R refuses, Julia fits): 23 cells

`julia_only_cells.tsv`. Groups: Gaussian REML with an SD formula on ordinary and crossed intercepts; Poisson REML (Cox-Reid) for plain `(1 | g)`, animal, relmat, phylo; Poisson and NB2 labelled q=2 `(1 + x | p | g)` with SD formulas (and NB2 spatial labelled q=2); Gamma, Beta, Student plain unlabelled `(1 + x | g)` with no SD formula; NB2 and Gamma correlated mu+sigma intercept blocks.

## Log-likelihood disagreements: 56 of 231 both-fit cells exceed 1e-4

The other 175 agree: median |diff| 0.0e+00, maximum 2.6e-06. `loglik_disagreements.tsv` has every disagreeing cell, its sign and an `explanation` column.

| Cause | Cells | Evidence |
| --- | --- | --- |
| Julia default integrator is adaptive Gauss-Hermite (`marginal = :LA`, 5 nodes); R uses Laplace. Julia higher by 0.03 to 0.30 (binomial q>=2 up to 0.33) | 6 confirmed + 34 presumed | Re-running the 6 plain `(1 \| g)` cells with `marginal = :Laplace` reproduces R to <= 3e-9 (`raw/julia_laplace/`). The other 34 cells are SD-regression or q>=2 routes where Julia accepts `:LA` only (its own error text says so), so I could not re-run them with Laplace; they are presumed, not shown. In every `sd-none` / `sd-one` pair the gap is the same, which fits the integrator explanation. |
| R fit flagged unconverged (`is_converged()` or `pdHess` false), Julia sometimes also flagged | 6 | binomial `sd-z` cells on `indep`, `spatial` and `phylo` shapes. R's value is equal to its `sd-one` cell in the spatial case (the SD slope did not move); in the `phylo` cell R is higher and Julia's SEs are non-finite. Either engine can be the worse local optimum, differences are 0.6 to 1.7. These are not parity evidence either way. |
| Different model: Julia estimates the spatial range when there is no SD formula | 1 | `gaussian|spatial|lab0|q1|sd-none`: Julia has 7 parameters, R 6 (fixed-range kernel). With an SD formula both use the fixed kernel and agree to 1e-10. |
| Unexplained | 9 | Tweedie ordinary and slope-only, plain and SD formula (Julia lower than R by 0.03 to 0.08; `marginal` is not accepted on Tweedie, so no Laplace re-run) and Gamma spatial q=1 (Julia lower by 0.06 to 0.07). |

## Cross-check against `docs/design/168-r-julia-finish-capability-matrix.md`

**Which file.** The file at `/Users/z3437171/Dropbox/Github Local/drmTMB/docs/design/168-...md` is modified but uncommitted on branch `cursor/sweep-blocked-20261004` (DESCRIPTION Version 0.7.1, 809 commits behind origin/main `6fc0910ed`, which is 0.8.1). The SD-regression sentences (header note, the long Non-Gaussian row, the Bernoulli row) exist only in that dirty copy; origin/main's matrix still says Bernoulli/binomial random effects and structured effects "remain unavailable" and the Non-Gaussian row says only "Coefficient parity first". The related test `tests/testthat/test-gamma-correlated-q2-direct-sd.R` is untracked in that tree. I therefore compared the map (R 0.8.1) with both texts. WT = working-tree draft, MAIN = origin/main.

| Claim | Source | Text (shortened) | Cells | Cells as the claim expects | Verdict |
| --- | --- | --- | --- | --- | --- |
| A1 | WT | Header: native TMB fits Bernoulli ordinary independent-intercept SD regression (ordinary q=1, ~1 or ~z) | 2 | 2 | CONSISTENT |
| A2 | WT | Header: Bernoulli selected independent-slope SD regression (slope-only term (0 + x \| g), sd ~ z) | 1 | 1 | CONSISTENT |
| A3 | WT | Header: the separate Bernoulli animal q=2 SD route (animal(1 + x \| g), one SD formula per coefficient) | 1 | 1 | CONSISTENT |
| A4 | WT | Header: Poisson ordinary independent-intercept (q=1) and selected independent-slope (slope-only term) SD regression | 3 | 3 | CONSISTENT |
| A5 | WT | Header: NB2 ordinary independent-intercept (q=1) and selected independent-slope (slope-only term) SD regression | 3 | 3 | CONSISTENT |
| A6 | WT | Header: Gamma ordinary independent-intercept (q=1) and selected independent-slope (slope-only term) SD regression, sigma ~ 1 | 3 | 3 | CONSISTENT |
| A7 | WT | Non-Gaussian row: selected independent-slope slices (slope-only term, sd ~ z) for Beta, lognormal, Student-t | 3 | 3 | CONSISTENT |
| A7b | WT | Same rows, other reading of 'independent': intercept and slope as separate terms (1\|g)+(0+x\|g) with SD on the slope only (info: shows which families R 0.8.1 fits in this shape... | 7 | 7 | INFO (7 cells) |
| A8 | WT | Non-Gaussian row: selected slopes in unlabelled correlated q=2 blocks for Bernoulli, Beta, Poisson, NB2, Gamma, lognormal, Student-t (ordinary lab0 q=2, SD on one coefficient) | 14 | 8 | CONTRADICTED (6/14 cells do not fit in R) |
| A9 | WT | Non-Gaussian row: direct-SD intercept slices for Bernoulli, Beta, Poisson, NB2, Gamma, lognormal, Student-t (ordinary q=1, ~z) | 7 | 7 | CONSISTENT |
| B1 | MAIN | origin/main Bernoulli row: random effects and structured effects 'remain unavailable' for binomial (any binomial ML cell with a random effect that R fits contradicts it) | 164 | 106 | CONTRADICTED (58/164 cells fit in R although the matrix says they are not admitted) |
| B2 | MAIN | origin/main claim guard: 'Plain Bernoulli/binomial support means event-probability mu only ... not random-effect binomial' (same cells as B1) | 164 | 106 | CONTRADICTED (58/164 cells fit in R although the matrix says they are not admitted) |
| C1 | BOTH | Gaussian REML: mean-side phylo admitted (phylo q=1, no SD formula) | 1 | 1 | CONSISTENT |
| C2 | BOTH | Gaussian REML: direct-SD phylo (phylo q=1, sd ~ z) | 1 | 1 | CONSISTENT |
| C3 | BOTH | Gaussian REML: ordinary random effects admitted (ordinary q=1 and q=2 independent terms, no SD formula) | 3 | 3 | CONSISTENT |
| C4 | BOTH | Gaussian REML with direct ordinary SD regression: matrix lists 'ordinary sigma random effects' only; R itself refuses REML with direct ordinary sd() (expected NOT to fit) | 1 | 1 | CONSISTENT |
| N1 | BOTH | NOT COMPARABLE (bivariate wording): 'Q, animal(), slopes, q4+ ... do not inherit' the REML admission; the map is univariate. Univariate animal q=1 REML (no SD) outcome shown f... | 1 | 1 | INFO (1 cells) |
| N2 | BOTH | NOT COMPARABLE (bivariate wording): 'bivariate mu-sigma RE correlations still gated'. The map's univariate labelled mu+sigma intercept block (1\|p\|g) in both formulas, Gaussian... | 1 | 1 | INFO (1 cells) |
| J1 | WT | Matrix: 'Direct-SD Julia and R-bridge parity remain unestablished': both-fit cells with an SD formula (direct R vs Julia, not the bridge) | 172 | 172 | INFO (172 cells) |

Rows where the map contradicts the matrix:

1. **A8 (working-tree draft).** "selected slopes in unlabelled correlated q=2 blocks for ... Gamma, lognormal, and Student-t" and Beta: R 0.8.1 refuses `(1 + x1 | g)` with an SD formula for **Beta, Gamma and Student-t** (6 cells: gamma|ordinary|lab0|q2|sd-first|cm0|ML, gamma|ordinary|lab0|q2|sd-last|cm0|ML, beta|ordinary|lab0|q2|sd-first|cm0|ML, beta|ordinary|lab0|q2|sd-last|cm0|ML, student|ordinary|lab0|q2|sd-first|cm0|ML, student|ordinary|lab0|q2|sd-last|cm0|ML). Its message for Gamma: "Only independent Gamma mu random intercepts and slopes are implemented in this slice ... Gamma and labelled covariance blocks remain rejected." Bernoulli, Poisson, NB2 and lognormal are consistent. The most likely reading is version skew (the claim describes unreleased work in that tree), which I could not confirm without building that tree.
2. **B1/B2 (origin/main).** The Bernoulli row says random effects and structured effects remain unavailable, and the claim guard says plain binomial is `mu` only. R 0.8.1 fits 58 of the 164 binomial ML cells (ordinary, indep, slope, animal, relmat, phylo, spatial, crossed; examples in `matrix_crosscheck.tsv`). The matrix understates R here.
3. **Julia wording (working-tree draft).** "Direct-SD Julia and R-bridge parity remain unestablished." The map is direct Julia vs R, not the bridge, and is not a bridge claim. But in 172 cells with an SD formula both engines fit, and 129 of those agree within 1e-4 (the rest are the causes above). That is direct-API evidence the matrix does not mention.

Rows consistent with the map: A1 to A7, A9 (Bernoulli, Poisson, NB2, Gamma, Beta, lognormal, Student-t direct-SD intercept and selected independent-slope slices, and the Bernoulli animal q=2 route), and the Gaussian REML rows C1 to C4 (phylo mean-side and direct-SD admitted; ordinary random effects admitted; REML with direct ordinary `sd()` refused by R, as its own message says). Rows I could not compare: N1 and N2 use bivariate wording. For information, N1 (univariate Gaussian `animal(1 | g)` REML) fits in R and Julia refuses; N2 (univariate Gaussian labelled `(1 | p | g)` in `mu` and `sigma`, ML) fits in **both** engines and agrees to 1e-10, so the matrix line "bivariate mu-sigma RE correlations still gated" does not describe this univariate cell. The matrix text on structured-covariance rows is mostly about the bivariate and q4 targets, which this grid does not cover.

## What this does not show

- It is a map of what fits, not of whether the fits are right. The only correctness check is the log-likelihood comparison on cells both engines fit; estimates, standard errors and intervals were not compared.
- One data set per family x kind, tiny (400 rows), one seed. Many q = 3, 4 and structured fits sit near boundaries. `FITS` means the optimiser returned convergence 0, so 37 R fits and 3 Julia fits carry a quality flag (see `quality_flag`).
- "Unlocks" is an upper bound. A group of refused cells is not guaranteed to fit once its refusal is removed, and 6 cells behind are non-converged or timed out and say nothing about refusals.
- Julia refusals depend on how I pass structured inputs: `coords` as a `Dict` (a second pass with a G x 2 matrix flipped 2 binomial spatial cells to FITS; `raw/julia_matcoords/`), `A` with `ids`, `K` in first-appearance row order, `tree` as a Newick string. The Beta/NB2 spatial refusals persist with a matrix, but `K =` works there. Other keyword forms were not tried.
- Sigma-side shapes are out of scope: no `sigma` predictors, random effects on `sigma` except the correlated mu+sigma intercept block, no `nu` or `zi` formulas, no cumulative or beta-binomial families, no bivariate responses, no bridge (`engine = "julia"`).
- The dirty working-tree R code was not built or tested. Whether it fits the cells in contradiction row 1 is unknown.
- Numeric-failure classification is by message regex; none of the 5000 failures matched it, but a refusal whose text hides a numerical cause would be counted as a refusal.

## Files

| File | Content |
| --- | --- |
| `gap_map.tsv` | one row per cell: coordinates, class, per-engine outcome / logLik / convergence / seconds / first message line / normalised signature, quality flag |
| `julia_behind_groups.tsv`, `julia_behind_ranked.tsv`, `julia_behind_ranked.md` | work list, by refusal signature and by cell |
| `julia_only_cells.tsv`, `crash_cells.tsv`, `loglik_disagreements.tsv` | the three lists above |
| `matrix_crosscheck.tsv`, `breakdown_family_kind.tsv`, `julia_sd_fit_counts.tsv`, `signatures_*.tsv`, `summary.json` | derived tables |
| `cells.tsv`, `cells_indep.tsv`, `cells_slope.tsv`, `cells_all.tsv`, `data/` | the grid and its fixtures |
| `gen_cells.jl`, `run_r.R`, `run_julia.jl`, `driver.py`, `classify.py`, `make_readme.py`, `probe_*.jl` / `.log` | code |
| `raw/r`, `raw/julia`, `raw/julia_matcoords`, `raw/julia_laplace` | verbatim runner output (`S` and `R` lines) and driver logs |

## Reproduce

```sh
julia --project=<env with DRModels, StableRNGs, Distributions, DelimitedFiles> gen_cells.jl .          # cells*.tsv, data/
FUZZ_DATA=$PWD/data DRMTMB_LIB=<lib> python3 -I driver.py r 20 180 cells_all.tsv out_r
FUZZ_DATA=$PWD/data FUZZ_JULIA_PROJECT=<env> python3 -I driver.py julia 20 300 cells_all.tsv out_julia
python3 -I classify.py raw . && python3 -I make_readme.py
```
