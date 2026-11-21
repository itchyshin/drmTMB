# Adversarial data red team: native R drmTMB vs native Julia DRModels, SD-regression routes

Date: 2026-11-08. Reader: whoever decides what to fix next in the Julia SD-regression input checks or in
the R/Julia parity matrix. Nothing here edits a verdict or `tools/write-parity-matrix.R`.

## Bottom line

I built 30 awkward-but-legitimate datasets and ran them through 340 route x family cells on both engines
(R drmTMB 0.8.1 native, Julia DRModels 0.8.1 native; never `engine = "julia"`). Time-box 120 s per fit.

* **No hangs, no crashes.** The longest Julia fit took 34 s (it includes compile time), the longest R fit 20 s.
  This says nothing about datasets I did not try.
* **Julia's plain input checks held up against R's, with gaps in both directions.** Julia fits exactly duplicated
  relatives with a Gaussian response where R fails (finding 11), and accepts a label => coordinate `Dict` on
  most routes; R accepts a tree with tips that have no data rows where Julia refuses (finding 8), and refuses
  all-singleton groups where Julia fits (finding 12). The gaps are listed below, ranked.
* **Five cheap input-validation defects fixed** on branch `claude/red-team-20261108`
  (commit `d3f851857`, from `origin/claude/binomial-phylo-spatial-q2-20261108`), one test per fix in
  `test/test_red_team_inputs.jl`. Nothing else was changed.
* **Not fixed, reported:** a sentinel log-likelihood (`-1e18`) returned inside a fit object, missing-data
  handling that differs by family and route, a positional-`A` hazard, numerical fragility at 1e6 and 1e-6
  covariate scales, and a set of scope refusals where R fits.

## How to read the table

`table.md` (also `table.tsv`) has one row per cell, **after** the fixes. `table_before_fix.tsv` is the same grid
before the fixes (cell ids are identical; `changed_by_fix` in `table.tsv` lists the cells that moved).
`dataset_summary.md` is the one-screen version.

Status words. **fit**: returned a fit and `converged` is true. **fit-nonconv**: returned a fit, not converged.
**refuse**: a deliberate error (R `cli_abort` classes; Julia `ArgumentError`/`DimensionMismatch`).
**error**: any other Julia exception type. **hang**: killed at 120 s.

Log-likelihood comparison. Both engines return a marginal log-likelihood, but on the ordinary non-Gaussian
routes Julia's default is adaptive Gauss-Hermite quadrature and R's is the Laplace approximation, so the two
differ by 0.04 to 0.2 on the **baseline** (clean) data for Poisson, NB2, Gamma, Binomial ordinary `(1 | g)` and
for Binomial `(1 + x | g)`. `docs/src/capabilities.md` already says these are not comparable. So a cell is flagged
`LL-DISAGREE` only when |J - R| > 1e-4 **and** it is not within 0.05 of that route's own baseline gap.
`J higher` means the Julia optimum is better, `R higher` means the R optimum is better (same objective, so
higher is better); I did not decide which is "right" in the badly scaled cells.

Cell ids: `cNNN`. The cells for a dataset are in `cells.tsv`; datasets and routes in `gen.R`.

## Design

Base data: 24 groups x 8 rows (192 rows), `x ~ N(0,1)`, group-level SD predictors `z`, `z0`, `z1`, random effect
SD `exp(-0.6 + 0.4 z)`. Kernels: random ultrametric tree (24 tips, height 2), 6 x 4 coordinate grid, A = scaled
AR(1). One seed (20261108), generated once, same CSV/Newick/matrix files read by both engines.

Routes: ordinary `(1 | g)` with `sd(g) ~ z`; ordinary q2 `(1 + x | g)` with `sd(g, coef(intercept)) ~ z0`
and `sd(g, coef(x)) ~ z1`; `animal(1 | g)`; `phylo(1 | g)`; `spatial(1 | g)`, each with `sd(g, <level>) ~ z`.
Families: Gaussian, Poisson, NB2, Gamma, Bernoulli. Ordinary routes get all five families; structured routes get
Gaussian and Poisson, except the datasets aimed at one structure, which get all five. Inputs on the Julia side are
labelled: `A` with `ids = …`, coordinates as a label => coordinate `Dict`, tree as Newick with tip names.
Missing values are `missing` (Julia) and `NA` (R).

Datasets (30). d00 clean control; d01a one singleton group; d01b all groups singletons; d02 identical responses in
one group; d03 a single-level group factor; d04 perfectly separated Bernoulli; d05 all-zero counts in one group;
d06a duplicated coordinates; d06b all coordinates identical; d07a zero-length internal branches (still
ultrametric); d07b zero-length terminal branches (identical tips); d07c/d07d trees that are not ultrametric;
d08a near-singular A (1e-9); d08b exactly singular A; d09 covariate constant within groups; d10 x scaled 1e6;
d11 x scaled 1e-6; d12 SD predictor scaled 1e6; d13 SD predictor scaled 1e-6; d14 three extreme outliers;
d15a six missing responses; d15b one whole group with missing responses; d16a one whole group with a missing SD
predictor; d16b one row with a missing SD predictor; d17 two extra kernel members (R: a factor with two unused
levels); d18 two groups absent from the kernel; d19 A with unsorted names, passed with `ids`; d20 SD predictor that
varies within a group; d21 as d19 but passed to Julia as a bare matrix (positional contract).

## Results at a glance (after fixes, 340 cells)

| | Julia fit | Julia fit-nonconv | Julia refuse | Julia error |
|---|---|---|---|---|
| R fit | 161 | 23 | 64 | 0 |
| R fit-nonconv | 1 | 0 | 1 | 0 |
| R refuse | 11 | 3 | 74 | 2 |

Before the fixes (338 cells; d07d was added afterwards) the "Julia error" column was 8: five Binomial cells
where R fits (four `MethodError` on `ids`, c015, c092, c103, c131, plus the c035 slope check) and three where R
refuses (c051, c146 slope check; c136 `MethodError`). The Binomial spatial `Dict` failure (c025, finding 3) was
seen in a pilot and then masked in the full run by a matrix fallback in my worker, recorded in that row's `msg`
column. Per-dataset counts are in `dataset_summary.md`.

## Findings, ranked

Fixed on the branch are marked **FIXED**. Everything else is reported only.

### 1. FIXED. `sd(g) ~ …` with a single-level group: Julia Gaussian fitted garbage (cell c074)
One group means no between-group variation. R refuses clearly ("at least two groups are needed"). Julia's Gaussian
ordinary route fitted it and returned boundary SD coefficients (+8.03 and -8.03 on the log scale) with only a
singular-Hessian warning; the other families failed later with "group-level design is rank deficient", which does
not name the cause (c075 to c089). Fix: `_require_sd_group_levels` in `_drm_entry_guard`, all families, names the
grouping variable and says what to check. Test: three families, one structured route, one negative control.

### 2. FIXED. Binomial structured SD routes did not accept `ids = …` (c015, c092, c103, c131, c136)
The unlabelled-`A` warning on every other family tells the user to pass `ids = …`; on Binomial that was
`MethodError: no method matching _drm_binomial_fit(...; ids)` (an unsupported-keyword dispatch error). Fix: `ids`
is accepted and labels `A` (animal) or `coords`; `ids` with `Ainv` is refused with a message. Test: permuted
labelled `A` gives the same log-likelihood as the first-seen-order matrix; the permuted matrix without `ids`
gives a different (wrong) model.

### 3. FIXED. Binomial `spatial(1 | g)` SD route refused a label => coordinate `Dict` (c025)
`ErrorException: needs coords as a 24-by-d matrix … got a Dict`, although the `Dict` form is documented for the
other families and works on the Binomial q2 route. Fix: the Binomial q1 spatial route resolves a `Dict` through the
same `_resolve_coords_labels`. Test: scrambled `Dict`, matrix with `ids`, and a missing site all behave.

### 4. FIXED. Binomial `(1 + x | g)` slope check was stricter than drmTMB (c035)
Julia refused when the slope predictor was constant in **any** group, so one singleton group among varying groups
was refused; drmTMB (`drm_validate_q2_slope_variation`) refuses only when it is constant in **every** group, and the
Julia comment said it "mirrors" that function. Now it matches (c035 fits; c051 and c146 are still refused). Test:
one singleton group fits; x constant in every group is refused. Not done: NB2 `(1 + x | g)` has no such check in
Julia, so c144 (x constant within groups) fits in Julia while R refuses; I did not add one because it turns a
fit into a refusal on a route I did not study.

### 5. FIXED (messages). Two refusals now say what to try
* Singular relatedness matrix (c133, c134 and friends): the Poisson animal route said "`relmat(1 | g)` covariance
  must be positive definite" for an `animal()` term; the shared helper said only "covariance matrix is not
  positive definite". Both now mention duplicated individuals and what to do.
* Tree with tips that have no data rows (c086, c307, c308): the message used the internal name "phylo LSS full
  input" and gave no remedy. It now says to prune the tree. This is a message fix only; see finding 8.

### 6. Sentinel log-likelihood inside a fit object (c114, c136; Binomial spatial and animal)
`loglikelihood(fit)` returns exactly `-1.0e18` with `converged = false`; the only visible text is a warning that the
variance estimate hit the "failed-fit sentinel". A user who reads `loglikelihood` or an AIC computed from it gets a
finite, hugely negative number. R returns a fit (c114) or a clear failure (c136). Suggest `-Inf`/`NaN` or an error.
c158 (Gaussian q2, x scaled 1e6) is the mirror image: `fit-nonconv` with a log-likelihood of +3.6e76.

### 7. Positional `A` (d21, c335, c336)
Passing a permuted `A` as a bare matrix gives a converged fit with the wrong model: log-likelihood 7.7 (Gaussian)
and 3.0 (Poisson) below R's. The only protection is the unlabelled-`A` warning, which is emitted once per session
(`maxlog = 1` in `_resolve_relatedness_labels`); the second call in a session is silent. With `ids = …` (d19, c317,
c318) Julia agrees with R to 1e-10. Suggest making the warning per call, or documenting positional order in the
`drm` docstring next to `A`.

### 8. Julia phylo requires every tree tip to appear in the data; R does not (c086, c307, c308)
A tree larger than the data (the usual case) is refused in Julia and fits in R. Not changed: pruning is a feature,
not a validation fix. Related: a non-ultrametric tree with positive branches (d07d, c339, c340) fits in Julia on the
raw branch-length scale (Poisson also warns) and is refused by R. Zero-length branches (d07a, d07b) are refused by
both; Julia names the edge by node numbers ("edge 27 -> 25"), not by tip names, and gives no remedy.

### 9. Missing data is handled differently by family and route
R drops incomplete rows everywhere. Julia, for a missing **response** (d15a, d15b): Gaussian ordinary and Gaussian
phylo drop the rows (with a warning, same `nobs` as R); Gaussian q2, animal and spatial refuse ("requires observed
responses; remove incomplete rows before fitting"); every Poisson, NB2, Gamma and Binomial SD route refuses
(24 cells refuse in all: Poisson 9, Gaussian 5, NB2 4, Binomial 4, Gamma 2). For a missing **SD predictor** (d16a,
d16b): Gaussian ordinary and q2 drop the rows with a warning (the structured Gaussian routes drop them for one
row, and refuse when a whole group disappears from the kernel's group set); the non-Gaussian routes refuse with a
clear message naming the row (about 18 cells). All of these messages are clear and say what to do, so this is a
consistency gap, not a silent error. R is also inconsistent: spatial refuses a group whose responses are
all missing (c261) and coords with extra rows (c309), where animal and phylo fit.

### 10. Numerical fragility at 1e6 and 1e-6 scales (d10 to d13)
x scaled 1e6 (d10): Julia fit-nonconv in 4 of 16 cells and non-finite SEs in 5; R has non-finite SEs in 9 (14 of 16 when the SD
predictor is scaled 1e6, d12). c159 (Poisson q2):
Julia says converged with a log-likelihood 250 above R's non-converged fit; I could not verify which is right.
SD predictor scaled 1e-6 (d13): all 14 comparable cells disagree, **Julia higher in all 14** (by 0.25 to 36), so R
stops at a worse point there; Julia converged in every one. SD predictor scaled 1e6 (d12): Julia fit-nonconv in 6
cells. x scaled 1e-6 (d11): 10 disagreements, Julia higher in 8. None of this is flagged to the user in a way that
says "rescale your covariate".

### 11. Near-singular and exactly singular A, duplicated coordinates (d06a, d08a, d08b)
* d08a (A near singular at 1e-9): Julia Poisson, NB2 and Binomial are fit-nonconv with log-likelihoods 4.6 to 7.9
  (Poisson, NB2) and 0.7 (Binomial) below R's fit (c128 to c131); Gaussian and Gamma agree with R to 1e-7.
* d08b (exactly singular A): Julia Gaussian fits (c132), which is correct because the residual variance keeps the
  total covariance positive definite; R fails with "failed in all `nlminb()` optimizer preset attempts", which does
  not name the cause. Julia Poisson, NB2 and Gamma refuse; Binomial returns the sentinel (finding 6).
* d06a (three duplicated coordinate pairs): Julia Gamma is fit-nonconv, 0.14 below R (c113); Binomial sentinel (c114).

### 12. Julia fits an unidentified model when every group is a singleton (d01b)
R refuses every ordinary and q2 cell ("only singleton groups"). Julia fits 8 of them, Gaussian included, where the
random-effect SD and the residual SD are not separately identified (c042: converged, finite SEs, a "Hessian is
numerically singular" warning). For counts an all-singleton group is an observation-level random effect and is
legitimate, so I did not add a refusal. A Gaussian-only refusal is the clear case; left for the owner.

### 13. Scope refusals where R fits (65 cells, 41 of them the missing-data refusals of finding 9)
The other 24: Poisson `spatial(1 | g)` with `sd()` (14 cells; "currently targets one ordinary mean random-effect
coefficient", which does not say that spatial is the cause), NB2 phylo and spatial q1, and the tree-tip and
row-dropping refusals. These are known coverage gaps rather than input defects; the Poisson wording is the one
worth improving.

### 14. Small things
* Binomial `(1 + x | g)` refusals (c051, c146) are an `ErrorException`, not an `ArgumentError`, though the text is
  clear. Left alone: `error(...)` is the Binomial convention and tests expect `ErrorException`.
* `sd()` predictor that varies within a group (d20): every cell refused by both engines with clear messages. Good.
* Groups absent from the kernel (d18) and `A` with unsorted names plus `ids` (d19): both engines behave, clear
  messages, agreement 1e-10 on d19.
* Separated Bernoulli (d04): both engines fit with log-likelihood about 0 and absurd coefficients. Julia returns
  non-finite SEs in all five cells (with a Hessian warning); R's are finite in four of five. Neither says "separation".
* Julia warning texts use internal names ("sparse-Laplace vcov", "phylo LSS").

## What I could not verify

* Which optimum is right in the badly scaled cells (finding 10); I only know which log-likelihood is higher.
* Anything about R-side or Julia-side behaviour outside these 340 cells, other datasets, other seeds, REML, or
  non-default controls. One seed per dataset; no truth-recovery or coverage claim.
* Julia has no factor type, so "factor with an unused level" is covered on the R side only; on the Julia side d17 is
  the kernel-superset version (extra tips, rows or coordinates).
* Julia timings before the first fit of each family include compile time (warm-up covered the Gaussian family only);
  per-fit times are indicative.
* Regression testing is partial. Of 592 Julia test files I ran 84 (the ones most likely to touch the changed code:
  Binomial, Gaussian, Gamma, Poisson, NB2, labelled and guard tests); 80 passed. The four failures:
  `test_binomial_animal_slope_iid_sd_regression.jl` fails identically on the unmodified branch in my environment
  (its own dense oracle reports "did not converge"; unrelated to this work, cause not investigated); the other three
  (`test_labelled_ordinary_q2_sd`, `test_labelled_rho_q2_sd`, `test_gaussian_structured_q2_reml`) pass when run on
  their own and fail only inside my one-process runner (a once-per-session warning consumed by an earlier file).
  The full suite was not run, and not on Julia 1 (only 1.10.12).
* The Julia environment is my scratch one (`Pkg.develop` on the branch, packages resolved fresh), not the
  repository `Manifest.toml`.

## Compute

Estimated before starting at under 1 h (R about 0.3 s per cell, Julia a few seconds); measured 5 to 10 min per full
grid, run three times. All on the Mac Studio within the caps (at most 2 Julia processes, 1 thread each, `nice -n 10`);
Totoro was not needed.

## Files

* `table.md`, `table.tsv`, `table_before_fix.tsv`, `dataset_summary.md`: results.
* `raw/`: `R_all.tsv`, `J_after.tsv`, `J_before_a.tsv`, `J_before_b.tsv`, `J_before_rerun1.tsv` (one line per cell:
  id, engine, status, exception class, converged, log-likelihood, nobs, seconds, finite-SE flag, coefficients,
  warnings, message).
* `gen.R` (seeded generator, writes the datasets and `cells.tsv`), `cells.tsv`, `cells.tgz` (the exact datasets used).
* `r_worker.R`, `j_worker.jl`, `drive.py` (120 s watchdog, restarts after a kill), `analyse.py`.
* `julia-branch.patch`: the diff of `claude/red-team-20261108` against its base.

Reproduce: `Rscript gen.R`, then `python3 drive.py R out/R_all.tsv 1 340` and `python3 drive.py J out/J_a.tsv 1 340`
(edit the library paths at the top of the workers), then `python3 analyse.py out`.
