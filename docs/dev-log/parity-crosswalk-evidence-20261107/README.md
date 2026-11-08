# Parity crosswalk evidence, 2026-11-07: ZIP plain slope and Gamma structured SD

Reader: whoever owns the `unreconciled` rows in `tools/write-parity-matrix.R`.
Purpose: give route-specific evidence for 3 of the 22 unreconciled names, and
correct one test-to-row mapping. Nothing here flips a verdict.

Source pair: R drmTMB `1a23f2b00` (origin/main), Julia DRModels.jl `ba502d9d7`
(origin/main, package version 0.8.0), Julia 1.10.12, one thread, Apple silicon Mac.

## Results

| Row (exact name in the generator) | Evidence | Result |
| --- | --- | --- |
| Zero-inflated Poisson plain independent slope without `sd()` (native only) | R: `tests/testthat/test-zi-poisson-plain-slope.R`, log `r-zip-plain-slope.log`. Julia: `zip_probe.jl` on the same 480 rows (`zip_slope.csv`, from the R fixture seed 20261101), log `zip_probe.log` | R: 12 pass, 0 fail. Julia: plain `(0 + x | g)` with `zi ~ 1` REFUSES with "Poisson() random effects cannot be combined with `zi`/`hu` yet". Julia fits only with an `sd(g, coef(x)) ~ 1` formula (converged, logLik -698.62). So the Julia route for this row is NO, with a refusal. |
| Gamma slope-only phylo, spatial and relmat predictor-dependent SDs (native only) | `test_gamma_structured_slope_sd_regression.jl` | 11 + 7 + 8 pass (relmat, spatial, phylo; dense oracles) |
| Gamma ordinary + animal/phylo/spatial intercept predictor-dependent SDs (native only) | `test_gamma_phylo_sd_regression.jl` (29), `test_gamma_animal_sd_regression.jl` (15), `test_gamma_spatial_sd_regression.jl` (10) | all pass |

## Correction to the earlier scout

The scout proposed `test_gamma_relmat_sd_regression.jl` and
`test_gamma_spatial_sd_regression.jl` as slope-only evidence. They fit
`relmat(1 | g)` and `spatial(1 | g)`, which are intercept models. The slope-only
tests are in `test_gamma_structured_slope_sd_regression.jl`. Both intercept
tests pass (`gamma.log`) and support the intercept row, not the slope-only row.
`test_gamma_animal_slope_sd_regression.jl` (16 pass) is a Gamma animal
slope-only SD test, relevant to the Gamma animal rows.

## What this does not show

These are Julia-native tests and one R test on synthetic fixtures. They do not
show R-Julia numerical agreement for any row, and no bridge fit was run. The ZIP
refusal comes from one fixture and `nAGQ = 9`. A row flips only by editing the
hard-coded list in `tools/write-parity-matrix.R` and `test-parity-matrix.R` and
regenerating; I did not do that, because the generator Julia pin (`da8b3f87`) is
older than `ba502d9d7` and the release drafts #1683 and #1259 are open.

## Batch 2 (same source pair, three parallel one-thread shards)

All 11 Julia test files below pass (logs `b2a.log`, `b2b.log`, `b2c.log`).

| Test file | Fits | Pass | Supports row |
| --- | --- | --- | --- |
| `test_nb2_relmat_sd_regression.jl` | NB2 relmat location intercept, `sd ~ z` | 26 | NB2 relmat intercept SD (part of the NB2 relmat/spatial/phylo/relmat row) |
| `test_nb2_relmat_slope_sd_regression.jl` | NB2 relmat slope-only | 10 | NB2 relmat slope-only |
| `test_nb2_spatial_slope_sd_regression.jl` | NB2 coordinate spatial slope-only | 15 | NB2 spatial slope-only |
| `test_nb2_animal_slope_sd_regression.jl` | NB2 animal slope-only | 8 + 7 | NB2 animal slope-only |
| `test_poisson_relmat_slope_sd_regression.jl` | Poisson relmat slope | 28 | Poisson relmat slope-only |
| `test_poisson_animal_slope_sd_regression.jl` | Poisson animal slope | 25 | Poisson animal slope-only |
| `test_poisson_relmat_sd_regression.jl` | Poisson relmat intercept | 17 | Poisson relmat intercept |
| `test_gamma_sigma_sd_regression.jl` | Gamma `sigma` random intercept and slope | 9 (+ intercept and refusal sets) | sigma-side SD only |
| `test_negbinomial2_sigma_sd_regression.jl` | NB2 `sigma` random intercept and slope | 12 + 10 | sigma-side SD only |

Two cautions on what these do NOT cover:

- The row "NB2 and Gamma joint ordinary `mu` plus `sigma` intercepts, each with an
  SD formula" is NOT evidenced here. The Gamma and NB2 sigma tests put the random
  effect on `sigma` only (`y ~ 1 + x`, `sigma ~ 1 + (1 | group)`). No test in this
  batch has a random effect on both `mu` and `sigma`.
- Not run: NB2 and Poisson phylo slope-only, ordinary + structured intercept
  tests, and all q2 rows. Those names stay unreconciled.

## Batch 3 and verified row mapping

Batch 3 (`b3a.log`, `b3b.log`, `b3c.log`) ran 12 more Julia test files, all passing. A read-only workflow then mapped every passing test to the exact row names by reading each test's family, kernel, intercept-versus-slope shape and SD formula. A second agent per cluster tried to refute each verdict. Full JSON: `row-mapping-verified.json`. 17 rows were mapped here; the ZIP, Julia bridge and `miss_control` rows are covered above or owned elsewhere.

Verdict count: COVERED 1, NOT_COVERED 13, PARTIAL 3.

| Verdict | Row | Missing |
| --- | --- | --- |
| NOT_COVERED | Binomial phylo and spatial q2 with coefficient-specific SDs (native only) | Both sub-shapes are missing a passing test. (a) Binomial phylo(1 + x | species) q2 with sd(species, phylogenetic, coef(intercept)) ~ ... and sd(species, phylogenetic, coef(x)) ~ ..., including the intercept-slope correlation. |
| NOT_COVERED | Gamma and NB2 same-group intercept + slope with `coef`-selected SDs (native only) | Missing Gamma ordinary (1 + x | g) / (1|g)+(0+x|g) with coef(intercept) and coef(x) SDs (no passing test). Missing NB2 ordinary same-group intercept + slope (the passing NB2 test refuses (1 + x | g) with sd(g) ~ z). |
| PARTIAL | Gamma animal correlated q2 (intercept + slope) with coefficient-specific SDs (native only) | The intercept-slope correlation is not covered for Gamma: no estimated correlation parameter and no oracle with a correlated field. Only the independent-fields sub-shape has a passing test. If the row's 'correlated' is only a label for (1 + x | g) syntax, this row would be COVERED. |
| NOT_COVERED | Gamma crossed (distinct groups) and ordinary + relmat intercept predictor-dependent SDs (native only) | Missing Gamma crossed ordinary (1|g)+(1|h) with SDs for both groups. Missing Gamma ordinary (1|g) + relmat(1|h) with SDs for both. Missing any Gamma ordinary-intercept SD test in the passed list. Gamma relmat-intercept alone is covered but is not this row's shape. |
| NOT_COVERED | NB2 and Gamma joint ordinary `mu` plus `sigma` intercepts, each with an SD formula (native only) | Missing joint NB2 mu (1|g) + sigma (1|group) with two SD formulas (the passing NB2 test refuses it). Missing the joint Gamma equivalent. Missing Gamma ordinary mu SD alone. |
| NOT_COVERED | Gaussian and NB2 phylo_interaction pair-level predictor-dependent SDs (Gaussian slope-only; NB2 intercept and slope-only) (native only) | Missing sub-shapes: Gaussian phylo_interaction slope-only with an SD formula; NB2 phylo_interaction intercept with an SD formula; NB2 phylo_interaction slope-only with an SD formula. The binomial tests do not transfer across families. |
| NOT_COVERED | Gaussian correlated q2, same-group, relmat/spatial, and mu + sigma joint predictor-dependent SDs (native only) | Missing sub-shapes: Gaussian correlated q2 (intercept+slope with a correlation parameter) with an SD formula per coefficient; same-group q2; relmat q2 and spatial q2; joint mu + sigma random effects with predictor-dependent SDs. |
| NOT_COVERED | Gaussian ordinary correlated q3 and q4 blocks with one SD formula per coefficient (native only) | Missing sub-shapes: Gaussian ordinary correlated q3 with one SD formula per coefficient; Gaussian ordinary correlated q4 with one SD formula per coefficient. |
| NOT_COVERED | Gaussian spatial q2 (unlabelled and labelled) with coefficient-specific SDs (native only) | Missing sub-shapes: Gaussian spatial(1 + x | g) unlabelled q2 with coefficient-specific SDs; Gaussian labelled spatial q2 (spatial(1 + x | p | g)) with coefficient-specific SDs. |
| NOT_COVERED | Gaussian structured `sigma` intercept (phylo, animal, relmat, spatial) with predictor-dependent SD (native only) | No sub-shape is tested: phylo, animal, relmat and spatial structured sigma intercepts with predictor-dependent SDs are all missing. If the row meant a mu-side structured intercept, it would be PARTIAL: animal, relmat and spatial are covered, and phylo is missing. |
| NOT_COVERED | Gaussian structured q2 (animal, relmat, phylo; unlabelled and labelled) with coefficient-specific SDs (native only) | Missing sub-shapes: animal q2 (unlabelled and labelled), relmat q2 (unlabelled and labelled) and phylo q2 labelled, each with coefficient-specific SD formulas. Unlabelled phylo q2 exists only with constant SDs and no SD formula, so it also lacks the SD formulas. |
| PARTIAL | NB2 relmat/spatial intercept, phylo/relmat slope-only, and ordinary + structured intercept predictor-dependent SDs (native only) | Missing sub-shapes. (a) NB2 spatial INTERCEPT with SD: no positive test, and a passing test asserts it is refused (test_nb2_spatial_slope_sd_regression.jl:86-88, `spatial(1 | g)` with `sd(g, spatial) ~ z` and coords throws ArgumentError, labelled 'intercept form' in the refusal comment). |
| NOT_COVERED | Poisson and NB2 labelled relmat q2 with coefficient-specific SDs (native only) | Missing sub-shapes: Poisson relmat(1 + x | g) with per-coefficient SDs; NB2 relmat(1 + x | g) with per-coefficient SDs; the labelled (tagged) variants of each. None has a passing test. |
| NOT_COVERED | Poisson and NB2 structured q2 (animal, relmat, phylo, spatial) with coefficient-specific SDs; NB2 labelled animal q2 (native only) | All sub-shapes missing: Poisson q2 for animal, relmat, phylo and spatial; NB2 q2 for animal, relmat, phylo and spatial; NB2 labelled animal q2. The phylo q2 shape is explicitly refused on Poisson/NB2 in passing tests (documented refusal), which conflicts with the row's claim. |
| COVERED | Poisson animal slope-only coefficient with predictor-dependent SD | none |
| PARTIAL | Poisson phylo/relmat slope-only, same-group/crossed, and ordinary + structured intercept predictor-dependent SDs (native only) | Missing sub-shapes. (a) Poisson phylo slope-only with SD: no positive test; test_phylo_slope_refusal.jl:55-63 shows Poisson `phylo(0 + x | species)` is refused as 'not implemented' (documented refusal, though that call has no sd() formula). |
| NOT_COVERED | Poisson phylo_interaction intercept and slope-only pair-level predictor-dependent SDs (native only) | Both sub-shapes missing: Poisson phylo_interaction intercept with pair-level SD, and Poisson phylo_interaction slope-only with pair-level SD. The only passing phylo_interaction SD tests are Binomial. |

NOT_COVERED means no PASSING test in this run has that exact shape. It does not mean the route is unimplemented, and it does not say native R lacks it. Several rows have refusal tests on the Julia side (for example Poisson and NB2 `phylo` slope-only and q2), which are documented NOs, not gaps in testing. The one COVERED row is Julia-native evidence only: the row name has no `(native only)` tag, so a bridge fit is still needed before it can count as R-Julia parity.

## Batch 4: can the cheapest NOT_COVERED rows be closed with new tests?

No. Seven shapes were tried on `ba502d9d7` (probe scripts and logs `b4-*`). Every one is a documented, deliberate Julia refusal, so a passing test cannot be written without first implementing the feature in DRModels.jl:

| Shape tried | Julia result |
| --- | --- |
| Poisson `animal(1 + x \| g)` with two coefficient SDs | `ArgumentError`: requires exactly one SD formula |
| NB2 `animal(1 + x \| g)` with two coefficient SDs | `ArgumentError`: requires exactly one `sd(group)` formula |
| Gaussian `animal(1 + x \| g)` with coefficient SDs | `ArgumentError`: only intercept form generally available |
| Gaussian `relmat(1 + x \| g)` with coefficient SDs | `ArgumentError`: only intercept form admitted |
| Gaussian ordinary `(1 + x \| g)` with coefficient SDs | `ArgumentError`: sd() supports random intercepts only |
| Gaussian `sigma ~ animal(1 \| g)` with SD formula | `ArgumentError`: sigma-side structured effect unsupported with sd() |
| Gaussian `(1 \| g)` on mu and sigma with SD formulas | `ArgumentError`: sd() cannot combine with a sigma random effect |

Consequence: the remaining NOT_COVERED rows are feature gaps, not test gaps. Closing them is Julia implementation work (separate repository, own review), and until then the honest parity verdict for these rows is "Julia refuses", not "agrees".

## Wave 2

Four further evidence folders sit in this directory. Each has its own README with the numbers; none changes a verdict. Conditional proposals that use them are in `PROPOSED-verdict-flips.md` (nothing applied).

- `wave2-labelled-rho/`: labelled (correlated) animal/relmat q2 with two coefficient SD formulas, Poisson, NB2 and Gaussian.
- `wave2-phylo-spatial-q2/`: phylo and coordinate-kernel spatial `(1 + x | g)` q2, Gaussian, Poisson and NB2.
- `wave2-gamma-nb2-ordinary/`: Gamma and NB2 two-field SD routes (crossed, ordinary + relmat/animal, independent and labelled q2).
- `wave2-joint-sigma/`: joint mean + sigma random effects, structured Gaussian sigma (phylo, spatial), the Gamma crossed disagreement, and stress case 6a.

Julia branch for all of it: `claude/q2-wave2-merge-20261107` (itchyshin/DRModels.jl, PR #1263, stacked on #1261). Single seed per case, ML only, agreement at the optimum only.
