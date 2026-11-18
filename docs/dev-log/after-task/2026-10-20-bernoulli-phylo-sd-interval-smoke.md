# After Task: Bernoulli Phylogenetic SD Interval Smoke

## 1. Goal

Check that profile and parametric-bootstrap interval dispatch can target a predictor-dependent Bernoulli phylogenetic SD coefficient.

## 2. Implemented

No package code changed. A local 16-tip synthetic fit returned the intended SD-slope target. The profile interval was marked `clamp_limited`; a two-replicate parametric bootstrap completed both refits and returned an interval.

## 3. Mathematical Contract

The probe used `log(sd_g) = alpha_0 + alpha_1 z_g` to scale the existing phylogenetic covariance as `D K D`. It did not normalize the tree covariance or change the model.

## 3a. Decisions and Rejected Alternatives

The probe asserts the observed profile clamp instead of relaxing the endpoint rule or treating a missing interval as success. The two-refit bootstrap stays a dispatch smoke; expanding it into calibration would require a separately designed and approved campaign.

## 4. Files Touched

- This report.
- `docs/dev-log/check-log.md`.
- `docs/dev-log/check-log.d/2026-10-20-bernoulli-phylo-sd-interval-smoke.md`.
- `LOOP/lanes/general-sd-regression/checkpoint.md`.
- `tools/general-sd-regression/probes/bernoulli-phylo-interval-smoke.R`, a deterministic local probe.
- `tools/general-sd-regression/probes/bernoulli-phylo-high-info-profile.R`, a higher-information diagnostic probe.
- `tools/general-sd-regression/probes/bernoulli-phylo-profile-information-pair.R`, a paired within-tip replication diagnostic.
- `tools/general-sd-regression/probes/bernoulli-phylo-profile-group-count-pair.R`, a nested group-count diagnostic.

## 5. Checks Run

- `NOT_CRAN=true OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null Rscript --vanilla tools/general-sd-regression/probes/bernoulli-phylo-interval-smoke.R` exited 0. On the seeded 16-tip, 12-observation-per-tip synthetic fit, `profile_targets()` resolved `fixef:sd_phylo(species):z`. The profile call returned `NA` endpoints with `conf.status = "clamp_limited"` and `profile.boundary = TRUE`.
- `confint(..., method = "bootstrap", R = 2, seed = 20261020, parallel = "none", refit_control = drm_control(se = FALSE))` returned an interval with 2 successful refits and 0 failed refits.
- `OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null Rscript --vanilla tools/general-sd-regression/probes/bernoulli-phylo-high-info-profile.R` exited 0 in about 47 seconds after removing a redundant raw-profile call. The 60-tip, 100-observation-per-tip fit estimated the SD slope as 0.480 (truth 0.45); its 95% profile interval was `[0.319, 0.652]`, `conf.status = "profile"`, message `ok`, and `profile.boundary = FALSE`.
- `OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null Rscript --vanilla tools/general-sd-regression/probes/bernoulli-phylo-profile-information-pair.R` exited 0. With 16 tips and one seed, increasing from 12 to 100 observations per tip left both profiles `clamp_limited`; the estimated slope changed from 0.366 to 1.087 (truth 0.45). This indicates that within-tip replication alone does not guarantee a usable profile in a small-group realization.
- `OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null Rscript --vanilla tools/general-sd-regression/probes/bernoulli-phylo-profile-group-count-pair.R` exited 0 in about 1 minute. It held the 60-tip simulated data and 100 observations per tip fixed, comparing the first 16 tips with all 60. The pruned covariance differed from the matching full-matrix block by `2.22e-16`. Both profiles were finite and non-boundary; the 16-tip interval was `[0.157, 0.814]`, while the 60-tip interval was `[0.319, 0.652]`.
- No coverage, calibration, or scientific interval-performance claim follows from two refits.

## 6. Tests of the Tests

The low-information probe asserts one target, the expected profile clamp status and missing endpoints, and finite bootstrap endpoints with 2 successful and 0 failed refits. The group-count probe asserts exact preservation of the covariance block under tree pruning. The high-information and paired group-count probes confirm that their true slope falls inside finite profile intervals. A separate fixed-group, higher-replication seed still clamped, showing that sample information and the realized data both affect this outcome. These single-seed probes do not validate interval coverage.

## 7a. Issue Ledger

Read open issue [#59](https://github.com/itchyshin/drmTMB/issues/59), which tracks the package's staged simulation and reporting framework. This probe supplies one local diagnostic input to that broader work; it does not change the issue's scope or status, so no external comment was posted.

## 8. Consistency Audit

The fitted formula and covariance scaling match the documented structured-SD contract in `docs/design/18-random-effect-scale-models.md`. The profile status reports direct-SD clamp contact when an evaluated predictor leaves the configured log-SD band. No public example or capability claim changed. The NotebookLM methods query found no source that directly calibrates predictor-dependent latent-SD slopes; the source-audited boundary remains recorded in `docs/dev-log/general-sd-regression/research.md`.

## 9. What Did Not Go Smoothly

The profile interval hit the model's clamp boundary on this small synthetic data set. The first bootstrap call used the wrong `refit_control` type and was rejected before any refit; the corrected call used `drm_control(se = FALSE)` and completed.

## 10. Known Residuals

These are a handful of synthetic fits and two bootstrap refits. They do not establish interval calibration, a general group-count threshold, phylogenetic identifiability under other designs, or cross-engine uncertainty parity. The full general-SD programme and gates G0-G8 remain open.

## 11. Team Learning

Keep profile-boundary status visible in interval smoke tests, and pass a `drm_control()` object for bootstrap refit controls rather than a plain list when setting package-level controls.

## 12. Cross-Product Coverage

Only the R/TMB Bernoulli phylogenetic route was exercised. This smoke does NOT cover Julia fitting, cross-engine interval agreement, other random-effect types, other response families, recovery across seeds, or calibrated uncertainty.

## Next Actions

Use a predeclared, higher-information design to investigate the profile clamp result, then validate profile and bootstrap coverage on the approved compute route before advertising calibrated uncertainty for this capability.
