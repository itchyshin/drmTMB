# After-task report: native stale-test group (batch 10)

Date: 2026-11-01. Base: bee7f6c4f (codex/general-sd-regression, PR #1663). Reproduced and verified on Totoro with OMP and OpenBLAS threads capped, no Julia and no sdmTMB installed.

## Scope

Eight failures from the Totoro R CMD check of 7309d3cd8, in six test files. Cause classes: (a) stale test pinning a refusal that this lane deliberately admitted, (b) real code bug, (c) environment only.

## Per-failure table

| test:line | cause class | evidence | fix |
|---|---|---|---|
| test-package-skeleton.R:97 | (a) stale refusal | b87566680 removed the parse-time check that `sd(id, dpar = "sigma")` is "reserved for location"; `parse_sd_lhs()` now records any `dpar` and the family builders accept only "mu" or "sigma" (R/drmTMB.R, "can target mu or sigma"). | Replaced the assertion with a positive one (`target_dpar` is "sigma", `explicit` is TRUE) and added a still-refused route of the same kind, `sd2(id, dpar = "sigma2")`, which keeps raising "does not accept explicit target". The existing `sd1(id, dpar = "mu1")` check stays. |
| test-package-skeleton.R:383 | (a) stale refusal | Same commit: `parse_phylo_interaction_bar_term()` lost its `is_intercept_one()` guard and now reuses `parse_structured_bar_term()`, so `phylo_interaction(1 + x \| plant:pollinator)` is admitted (checked on Totoro: no error). | Swapped to `1 + x + z \| plant:pollinator`, still refused with "currently reserves only intercept and one-slope structured terms"; regex is "intercept and one-slope". |
| test-count-structured-mu.R:1369 | (a) stale refusal | 8dcb17f81 added "spatial" to `slope_only_structured_mu_types` for NB2, so `nbinom2()` with `spatial(0 + x \| site)` now fits. Probed on Totoro: Gamma, Binomial, Student, lognormal, Tweedie and truncated NB2 all still refuse the same term; Gaussian fits (it is not a count family). | Swapped the NB2 refusal to Gamma with `spatial(0 + x \| site, coords)` on a strictly positive response (`nb2_spatial + 1`), expecting "intercept-only in this q=1 route" (whitespace-tolerant regex). The Poisson fit assertion above it is untouched. |
| test-meta-v-lss-api.R:12 | (a) stale message | b87566680 routed Gaussian direct SD through `drm_scalar_sd_mu_targets()` (R/random-effect-targets.R:271), whose message no longer names the group. The refusal itself is unchanged: `sd(study)` with no matching `(1 \| study)` still errors. | Regex now "No random-effect term matches the Gaussian `sd()` formula for `mu`". |
| test-mspl-estimator.R:685 | (a) stale message | b87566680 added `validate_binomial_mu_random_terms()`, which now rejects the labelled `(1 + x \| p \| group)` block first with "Binomial correlated random effects support one unlabelled block of size q >= 2 with an intercept". Still refused under MSPL. | Regex now `one\s+unlabelled\s+block\s+of\s+size` (whitespace-tolerant because cli wraps long lines). |
| test-env-skip-census.R:37 and :50 | (a) stale artefact, not environment | `inst/extdata/env-skip-census.tsv` predates about 290 new skip call sites (Beta, Binomial, NB2, Poisson SD regression files) and one changed count in test-julia-module-compat.R. The scanner (tests/testthat/helper-env-skip-census.R) is a static source parse, so the census does not depend on whether Julia is installed. | Regenerated with `Rscript tools/write-env-skip-census.R` (1555 call sites; 358 to 649 lines). The sibling gate-class test still passes (only engine-drm-jl and env-var-optin are permanent). |
| test-gaussian-batch5-sd-regression.R:460 (via :103) | (c) numeric platform sensitivity in the test's independent optimiser, not a package bug | `opt$convergence` 52 comes from the test's own `optim(method = "L-BFGS-B", factr = 10)`, not from drmTMB. Reproduced on Totoro: relmat gives code 52 ("ABNORMAL_TERMINATION_IN_LNSRCH") with one BLAS thread, phylo gives it with four, spatial passes; every run, including the failing ones, ends at the same value as the fit to 10 digits. `factr = 10` demands a relative reduction of 2e-15, which is below what the dense Cholesky objective resolves once threading changes rounding order. With `factr = 1e3` (2e-13) all three shapes return code 0 at 1 and 4 threads. | Changed the optimiser stopping rule from `factr = 10` to `factr = 1e3`. The fit versus oracle comparison keeps its 1e-5 relative tolerance, and the `expect_equal(opt$convergence, 0L)` assertion is retained. Same latent setting in test-gaussian-structured-direct-sd-providers.R:86 was changed in the same way (it passed on Totoro; changed for consistency, say so if you prefer it reverted). |

## Verification (Totoro, OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1, NOT_CRAN=true)

Counts are passed / failed / error / skipped, before then after.

- test-package-skeleton.R: 98/2/0/0 then 102/0/0/0
- test-meta-v-lss-api.R: 0/0/1/0 then 1/0/0/0
- test-env-skip-census.R: 4/2/0/0 then 5/0/0/0
- test-mspl-estimator.R: 154/0/0/0 after
- test-count-structured-mu.R: 533/0/0/0 after
- test-gaussian-batch5-sd-regression.R: 103/0/0/2 after, at 1 and at 4 threads (the two skips are existing skips, not new)
- test-gaussian-structured-direct-sd-providers.R: 60/0/0/0 after

No Julia-live test was needed for this group.

## Things to know

- Census staleness is order dependent. Other batches that add or remove skip call sites will make the regenerated TSV stale again, so regenerate it last, after every other patch is merged (`Rscript tools/write-env-skip-census.R`).
- On Totoro the system BLAS is openblas-openmp, so `OPENBLAS_NUM_THREADS=1` alone does not cap it; set `OMP_NUM_THREADS` too. Without it, the dense oracle fits in the batch5 file ran for over 30 minutes at very high CPU use (killed).
- No R source file was changed; every fix is in tests or the generated census.
- Not covered: the other 20 failures from the same check log belong to other groups.
