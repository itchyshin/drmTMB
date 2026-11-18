# After Task: Bernoulli 97.5% Profile Range

## 1. Goal

Give native TMB profile intervals and curves enough default search range to attempt the requested confidence cutoff when the caller leaves `ytol` unspecified. The bounded test case is the frozen synthetic Bernoulli SD-regression seed that previously returned no 97.5% interval.

## 2. Implemented

`drm_profile_ytol_for_level()` now chooses a negative-log-likelihood range 0.5 above the one-parameter likelihood-ratio cutoff, subject to a minimum of 2. The direct TMB confidence-interval path and `profile()` use it only when `ytol` is absent. Explicit `ytol` values, including the `"fast"` profile shortcut's value of 2, remain in force.

The `confint()` help, `profile()` help, generated Rd pages, and development NEWS now describe the default and its explicit-control behavior. The regression test requests a 97.5% interval and checks finite endpoints, full-curve cutoff reach, and that an explicit `ytol = 2` remains in force for this fixture. The wider default range is a search heuristic, not a guarantee against optimizer, iteration, or other profile failures.

## 3a. Decisions and Rejected Alternatives

The fix changes the profile search range, not the likelihood-ratio cutoff or the interval method. A fixed `ytol = 3` would work for 97.5% but would overextend some lower-level profiles; choosing the range from `level` keeps the same rule across confidence levels. Explicit controls remain authoritative. The timing-only run was not promoted to recovery or calibration evidence. The initial source archive build stalled during its shared-tree copy; a later isolated `R CMD INSTALL` succeeded, but no full `R CMD check` was run.

## 3b. Mathematical Contract

For the one-parameter TMB profile, the requested confidence cutoff is `qchisq(level, df = 1) / 2` on the negative-log-likelihood scale. The default range target is `max(2, qchisq(level, df = 1) / 2 + 0.5)`. This adds 0.5 headroom beyond the requested cutoff; it does not guarantee endpoint bracketing. At level 0.975 this is `ytol = 3.011943`, above the cutoff 2.511943. The interval cutoff itself is unchanged. An explicitly supplied range remains the caller's choice and may still stop before the requested cutoff.

## 4. Files Touched

- `R/profile.R`
- `tests/testthat/test-binomial-sd-profile.R`
- `NEWS.md`
- `man/confint.drmTMB.Rd`
- `man/profile.drmTMB.Rd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-19-bernoulli-profile-range-0975.md`
- This report
- `docs/dev-log/after-task/2026-10-19-bernoulli-profile-range-0975.assessment.json`
- Synthetic Totoro timing and profile evidence under `docs/dev-log/general-sd-regression/evidence/calibration-20261017/profile-range-debug-0975-current-source-v2/`

## 5. Checks Run

- Before the source fix, the Bernoulli profile test at 97.5% failed its four endpoint assertions with `NA` bounds.
- After the fix, the focused Bernoulli test passed 19 expectations in 112.2 seconds, then passed 20 expectations in 111.9 seconds after adding an assertion for `profile.message == "nonfinite_interval"` on the explicit short-range fixture.
- `Rscript -e 'devtools::test(filter = "profile-targets")'` passed 1,034 expectations with 0 failures, 2 expected Julia-engine skips, and 6 deprecation warnings in 172.1 seconds.
- `Rscript -e 'devtools::document()'` completed and wrote `confint.drmTMB.Rd` and `profile.drmTMB.Rd`.
- The one-seed post-fix Totoro smoke used package 0.7.1 and TMB 1.9.25, with the patched `R/profile.R` SHA-256 `64e3d4465d8fa53bfec46f3ad71da3c8a41d4e13818a228b0afcf879688d3e3d`. The frozen seed returned interval [-1.078105, -0.2688165], status `profile`, fit convergence 0, and `pdHess = TRUE`. The curve's maximum deviance was 6.12987 against a 5.023886 cutoff. Fit, interval, and curve took 0.510, 8.607, and 8.571 seconds, respectively. The log and serialized result are retained beside the timing evidence.
- All 234 files copied from the pre-fix Totoro timing capsule matched a fresh remote SHA-256 manifest. That capsule records 45/45 completed timing-only fits but 0 valid 97.5% intervals; it makes no calibration claim.
- The post-fix timing-only capsule records 45/45 completed fits and 45/45 valid 97.5% intervals, with no profile failures, boundaries, warnings, or launch errors. Its source-registry digest is `674a924c2e86d134eecdbaf8f55883a0be14e3be15f334719c130d2dfcfefaf4`; the pinned worker hash matches the archived worker containing the overlay activation sequence, and the pinned `R/profile.R` hash matches the current source. The supervisor verifies registry integrity, each worker verifies source hashes, then evaluates and installs the three pinned profile functions before fitting and profiling. Independent read-only inference review confirmed this activation chain and found no material gap. The 16-worker supervisor run took 31.357 seconds; the conservative linear projection for 3,000 comparable fits is 2,090.5 seconds (34.8 minutes), excluding queue and setup. This is timing-only evidence, not recovery or calibration. See `general-sd-regression/evidence/calibration-20261017/profile-range-debug-0975-current-source-v2/source-activation-review.md`.
- `R CMD INSTALL --preclean` completed on Totoro into the isolated package library. A direct namespace readback from that installation reported drmTMB 0.7.1 and `drm_profile_ytol_for_level(0.975) = 3.011943`; this checked the installed helper, not a new model fit or package check.
- The raw pre-fix curve had a maximum negative-log-likelihood rise of 2.029. The same profile object returned finite 80% and 95% intervals but `NA` endpoints at 97.5%. TMB 1.9.25 documents its default `ytol = 2`, which explains the truncation.
- A full `R CMD build` attempt was interrupted after copying into its build directory stalled in the shared dirty worktree. That attempt did not produce package-check evidence.

## 6. Tests of the Tests

The new 97.5% assertions were run against the old implementation first and failed with the expected nonfinite endpoints. The baseline failed the finite endpoint assertions as expected. After the fix, the fixture passed finite endpoint, full-curve cutoff, and explicit-control checks; the final rerun also verified the specific failure message for the deliberately short explicit range.

## 8. Consistency Audit

The documentation search was:

```sh
rg -n "ytol|97\.5%|profile range|profile cutoff" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/18-random-effect-scale-models.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

Only the new NEWS entry and an existing roadmap profile note matched. Formula grammar, family support, and pkgdown navigation do not change. The earlier Totoro report with a 98 to 127 minute projection used a different 95% worker/source, so it is not evidence for the corrected 97.5% route. The post-fix 45-row run is the successful-profile timing estimate; it is not calibration or coverage evidence.

The profile path reviewed here is native R/TMB. Julia profile behavior, random-effect SD recovery, interval coverage, and calibration remain outside this slice. Programme gates G2 and G5 remain open, and the release hold in D-93 is unchanged.

## 7a. Issue Ledger

Read-only GitHub search for `repo:itchyshin/drmTMB profile interval ytol` returned no open issues. No issue was created, commented on, or closed.

## 9. What Did Not Go Smoothly

The first 97.5% timing run completed every fit but returned no usable intervals because TMB's default profile range stopped below the required cutoff. An initial source archive build stalled while copying the shared dirty worktree. A later isolated `R CMD INSTALL` completed; no full `R CMD check` was run for this profile-range slice.

## 11. Team Learning

Choose a TMB profile range from the requested confidence cutoff, not from a fixed default that only happens to cover common levels. Preserve explicit range controls, and keep profile computation evidence separate from coverage evidence.

## 10. Known Residuals

The half-unit `ytol` headroom gives the profile room to reach the requested cutoff but does not ensure bracketing when other profile limits or optimizer failures intervene. The explicit `ytol = 2` assertion is fixture-specific because a TMB profile step can jump across a cutoff. The successful 45-row run estimates runtime only; it does not establish recovery, bias, or calibrated coverage. The earlier failed 45-row run is retained as failure evidence. An explicitly small `ytol` or the `"fast"` shortcut can still stop before a high-level cutoff. The Julia engine was not changed or tested live.

## 12. Cross-Product Coverage

This slice covers the native R/TMB `profile()` and direct `tmbprofile` confidence-interval routes. It does NOT cover Julia profile behavior, other-engine parity, random-effect SD recovery, interval coverage, or calibration. The source-pinned 45-row post-fix timing-only pre-run is complete and supports a preliminary 34.8-minute estimate for 3,000 comparable fits. The run does not establish recovery or calibrated uncertainty.

This closes only the native profile-range repair and its bounded runtime pre-run. It does not complete Bernoulli recovery or interval calibration, Julia parity, family breadth, or programme gates G0-G8. The next action is the first-look 3,000-fit recovery and coverage campaign, using the pinned source and keeping failed attempts in the denominator.
