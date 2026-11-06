## 1. Goal

Implement and lightly validate predictor-dependent SDs for Bernoulli spatial random intercepts and slope-only effects in native R/TMB and direct Julia.

## 2. Implemented

Both engines now admit coordinate-based q=1 spatial Bernoulli random intercepts and slope-only terms with a matching group-level SD formula. The slope predictor loads the latent spatial field at each observation. The native package overview and generated help now describe the supported links and within-site predictor requirements.

For a site effect (b_g), the fitted coefficient SD is τ_g with `log(τ_g) = W_g α`; for a slope, the linear predictor contribution is `x_i b_g`. Existing spatial covariance conventions are preserved within each engine.

## 3a. Decisions and Rejected Alternatives

- Limited the new route to one q=1 coordinate-spatial field, with a matching SD target and no additional random effects. No new covariance structure was introduced.
- Kept each engine's existing spatial covariance convention. Native uses its median-distance range and `1e-6` jitter; Julia uses its mean-distance range and `1e-8` jitter. Cross-engine parity is therefore not claimed.
- Used a balanced, higher-information synthetic slope design after the initial smaller logit fixture failed its recovery assertions. The test threshold was retained.
- Assumptions without asking: this slice supports the slope-only `0 + x` term. Intercept-plus-slope covariance blocks need a separate q=2 extension.

## 4. Files Touched

Native drmTMB worktree:

- `R/drmTMB.R`
- `man/drmTMB.Rd`
- `tests/testthat/test-binomial-spatial-sd-regression.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-27-binomial-spatial-sd-slope.md`

Direct Julia worktree:

- `src/gaussian_ranef.jl`
- `src/binomial_sd_regression.jl`
- `src/inference.jl`
- `src/gaussian_core.jl`
- `test/test_binomial_spatial_sd_regression.jl`

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "binomial-spatial-sd-regression", stop_on_failure = TRUE)'`: **42/42 passed**, 19.0 seconds. This covers logit, probit, and cloglog fitting, recovery, predicted SDs, and simulator output validity.
- `JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. test/test_binomial_spatial_sd_regression.jl`: spatial intercept **21/21** and spatial slope **22/22** passed on Julia 1.10.0. The slope fixture includes a seeded marginal-simulation oracle with the observation-level `x` loading.
- `Rscript -e 'devtools::document()'`: completed and wrote `man/drmTMB.Rd`.
- The scoped status search covered README, roadmap, NEWS, known limitations, formula grammar, vignette grammar, and pkgdown navigation. README and likelihood-design wording are already being edited by the documentation-audit lane; those shared files were left untouched pending coordination.
- `gh issue list --repo itchyshin/drmTMB --state open --search 'Bernoulli spatial slope SD' --limit 20 --json number,title,url`: no matching open issue returned.

## 6. Tests of the Tests

The new Julia slope test first failed at parser admission, then exposed missing parser support in `predict()` and `predict_parameters()`. The native test first failed at the R validator before reaching TMB. Its first low-information design missed the logit recovery target; after balancing within-site slope values and increasing the number of sites and observations, the same recovery tolerance passed for all links. The Julia simulator oracle generates an independent spatial field and applies `x` at each observation.

## 7a. Issue Ledger

No matching open GitHub issue was found by the scoped search. Interval coverage and R-to-Julia bridge parity remain open programme work.

## 8. Consistency Audit

Native fitting, public SD prediction, and simulation were checked in the focused test. Julia fitting, public parameter prediction, and the marginal simulator were checked in its direct test. The formula selector remains `sd(group, level = "spatial") ~ predictors`; spatial SD predictors must be group-constant, and a slope predictor must vary within sites. No formula-grammar or covariance parameterization change was made.

The documentation-audit lane is editing `docs/src/families.md`, `README.md`, and `docs/design/03-likelihoods.md`. Its owner has been asked to reconcile the Bernoulli spatial capability wording before those shared guide files are changed. The R help now documents this narrow development route. The check-log entry was appended to record this milestone.

Status inventory search run:

```sh
rg -n -i "binomial.*spatial|spatial.*binomial|Bernoulli.*structured|predictor-dependent.*SD|random-effect SD" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

## 9. What Did Not Go Smoothly

The first native recovery fixture was too weak for the logit link, so the design was strengthened rather than loosening its acceptance bound. Exact-file lane preflight for shared documentation and check-log paths stalled during the live lane census; the documentation owner was contacted, and shared guide files remain untouched.

## 10. Known Residuals

There is no calibrated interval evidence. Direct Julia checks do not establish R-to-Julia bridge parity. The two spatial covariance builders use different range and jitter conventions, so point-estimate comparisons across engines would conflate model-scale differences. Mesh spatial fields, q>1 spatial blocks, mixed structured effects, and other response families are outside this slice. Julia user-facing guide wording is awaiting the active documentation-audit owner.

## 11. Team Learning

For spatial random slopes, build a synthetic design with deliberate within-site variation in the coefficient predictor and a full-rank site-level SD design. Validate the simulator with an independently generated latent field that multiplies the slope predictor at each observation. Keep kernel convention differences explicit when comparing engines.

Memory receipt: project AGENTS and after-task protocol were used; the routed LOAD-FIRST manifest lookup returned no manifest for this worktree.

Golden Set: not in scope for this implementation slice.

## 12. Cross-Product Coverage

Covers: native R/TMB and direct Julia; Bernoulli/Binomial logit, probit, and cloglog; one coordinate-spatial q=1 intercept or slope-only field; fitting, predicted SD output, and basic simulation checks.

Does NOT cover: R-to-Julia bridge parity, calibrated uncertainty or interval coverage, mesh fields, correlated spatial intercept-slope blocks, multiple structured effects, non-Bernoulli families, or a harmonized cross-engine spatial kernel.
