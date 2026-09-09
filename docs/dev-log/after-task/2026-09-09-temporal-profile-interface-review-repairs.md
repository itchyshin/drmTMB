# After Task: Temporal profile-interface review repairs

## 1. Goal

Complete the local OU profile-interface slice: allow profile likelihood intervals for Gaussian temporal AR1 and OU mean regression coefficients, while making all other temporal parameters explicitly unavailable and retaining an honest fitted-likelihood diagnostic.

## 2. Implemented

`confint(..., method = "profile")`, `summary(..., conf.int = TRUE, method = "profile")`, generic `profile()`, and `profile_targets()` now share one restriction for temporal fits: only fixed `mu` effects are profile-ready. This applies to AR1 and OU, with or without the same-ID ordinary random intercept. The profile entry points warn if the fitted full observed Hessian is not positive definite. `check_drm()` names the situation as an irregular fitted likelihood and says that finite endpoints are not calibration evidence.

## 3a. Decisions and Rejected Alternatives

For the admitted Gaussian temporal model, the mean effect is profiled while the ordinary-intercept SD, temporal-process SD, residual SD, AR1 persistence, and OU decay are reoptimized nuisance parameters. The independent dense oracle reoptimizes the marginal Gaussian covariance likelihood at three fixed mean-effect values. It confirms the public profile curve without using the TMB profile implementation. A non-positive-definite fitted full Hessian does not invalidate a finite profile endpoint, but it prevents a general coverage claim.

## 4. Files Touched

The profile-target restriction and warning live in `R/profile.R`; interval-status metadata is in `R/methods.R`; and the reader diagnostic is in `R/check.R`. Focused public-boundary and dense-oracle tests are in `tests/testthat/test-temporal-ou.R` and `tests/testthat/test-temporal-ou-dense-oracle.R`. Roxygen output, the temporal vignette, G7/G11/G12/G13/G16 ledger entries, and `tools/temporal-ou-gates.R` were synchronized.

## 5. Checks Run

`Rscript --vanilla -e 'devtools::document(quiet = TRUE); devtools::test(filter = "temporal-ou", reporter = "summary")'` passed. `Rscript --vanilla tools/temporal-ou-gates.R G7`, `G10`, and `G11` reverified the profile interface, reader text, and source-built vignette. `git diff --check` passed. `Rscript --vanilla tools/temporal-ou-gates.R G12` built `drmTMB_0.7.1.tar.gz`; its `R CMD check --no-manual` log ended `Status: OK` on macOS.

## 6. Tests of the Tests

The dense-oracle test compares three public profile locations with a separately optimized dense covariance likelihood. The public-boundary test rejects OU decay and rejects a temporal-SD label from a combined `(1 | id) + temporal(...)` fit through generic `profile()`. It also mutates the fitted Hessian flag and requires the public warning. The metadata test checks that `profile_targets()` marks the temporal SD unavailable.

## 8. Consistency Audit

I searched the status inventory with `rg -n -i 'temporal|ornstein|\\bOU\\b|temporal_mean_profile|temporal_nonmean_intervals_deferred' README.md NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md vignettes/formula-grammar.Rmd vignettes/temporal-random-effects.Rmd _pkgdown.yml` and separately with `rg -n 'Wald.*(qualified|unqualified)|profile.*(calibrat|mean)'` over the same source documents. The README, NEWS, grammar, likelihood design note, limitations, vignette, and pkgdown navigation agree: profile intervals are limited to temporal mean effects; coverage is uncalibrated; OU Wald intervals and non-mean intervals remain unavailable. This repository has no `docs/design/04-architecture.md` file.

## 7a. Issue Ledger

`gh issue list --state open --search 'OU temporal in:title,body' --limit 30` found open issue [#1302](https://github.com/itchyshin/drmTMB/issues/1302), which records the deferred phylogenetically correlated temporal OU series. No issue was opened, closed, or commented on because this repair completes the existing Gaussian temporal interface rather than the phylogenetic extension.

## 9. What Did Not Go Smoothly

Independent review found that generic `profile()` bypassed the temporal mean-only guard, and that it did not display the irregular-Hessian warning. The first attempted profile pilot also exceeded its announced 5–10 minute estimate without producing a completed artifact, so it was stopped under the project compute rule. No incomplete pilot output was retained as evidence.

## 11. Team Learning

Public convenience methods must share the target registry used by `confint()`. A per-fit Hessian warning must be emitted by both interval endpoints and profile-curve entry points, otherwise users can see different inference messages for the same model. The pilot runner needs a measured single-fixture preflight or durable progress records before the full profile campaign is attempted.

## 10. Known Residuals

This is not a coverage-calibrated interval method. The G16 profile pilot, G14 campaign authorization, and G15 retained campaign recheck are still open. AR1 and OU variance, persistence/decay, bootstrap, forecast, and `newdata` intervals remain unavailable. OU accepts positive continuous decay only and cannot represent alternating negative correlation.

Measure one representative profile fixture with durable timing/progress output, update the full 15-dataset G16 estimate, and obtain explicit authorization before any run expected to exceed 30 minutes. Then use the measured result to select the approved campaign target and resource limit. The later temporal-correlation roadmap remains separate from this OU goal.

## 12. Cross-Product Coverage

This repair covers native-TMB Gaussian temporal AR1 and OU fits with constant `sigma`, with or without one same-ID ordinary random intercept, through `confint()`, `summary()`, generic `profile()`, `profile_targets()`, `check_drm()`, and the temporal vignette. It does NOT cover `REML = TRUE`, non-Gaussian families, missing-response or weighted routes, newdata/forecast prediction, another random-effect grouping factor, a temporal slope, Julia-engine fits, phylogenetic temporal series, or any variance/persistence/decay interval. It also does NOT cover coverage calibration: G16--G15 remain pending retained profile-pilot and campaign evidence.
