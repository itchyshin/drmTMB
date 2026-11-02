# After Task: Bernoulli animal slope SD regression (partial)

## 1. Goal

Add a native Bernoulli animal-model location slope whose SD depends on a fixed
group-level predictor, and check recovery and public outputs on independently
generated synthetic data. This is one row of the broader predictor-dependent SD goal.

## 2. Implemented

In this worktree, the binomial builder admits one unlabelled q1 animal slope-only coefficient
with or without its matching `sd(id, level = "animal")` formula. The direct-SD
route requires complete responses, no ordinary random-effect terms, and no
second structured SD target. The existing animal covariance matrix and its
scaling are preserved. The change reuses the existing structured TMB field; no
C++ code changed.

## 3. Mathematical Contract

For the animal slope coefficient, let `u ~ N(0, A)`, `D = diag(tau_g)`, and
`log(tau_g) = z_g * alpha`. The contribution to the logit linear predictor is
`x_ig * b_g`, where `b = D u`, so `Cov(b) = D A D`. Each retained `z` value
must be constant within its animal ID. For non-unit `A` diagonals, `tau_g` is
the multiplier on the supplied kernel; the marginal coefficient SD is
`tau_g * sqrt(A_gg)`.

## 3a. Decisions and Rejected Alternatives

The implementation reuses the existing structured-field TMB likelihood and
limits this slice to one unlabelled q1 animal coefficient. No C++ covariance
change was needed. Other providers, larger animal blocks, and combined
ordinary random effects remain outside this route.

## 4. Files Touched

- `R/drmTMB.R`: narrow binomial animal-slope admission.
- `tests/testthat/test-binomial-animal-slope-sd-regression.R`: seeded recovery,
  named group-SD predictions, profile-target identity, simulation, save/reload,
  constant-SD equivalence, and rejection of mixed coefficients and ordinary
  random effects.
- `docs/design/18-random-effect-scale-models.md` and
  `docs/design/59-structural-slope-and-non-gaussian-map.md`: record the exact
  route and its evidence boundary.
- `.unlazy/general-sd-regression/GATES.md`: add the tested row as partial G3
  evidence. The programme gate remains open.
- `docs/dev-log/check-log.md` and
  `docs/dev-log/check-log.d/2026-10-21-binomial-animal-slope-sd.md`: record the
  exact focused-test results.

## 5. Checks Run

- Before the admission change, the new public-API test failed at the existing
  intercept-only validator, as expected.
- `Rscript -e 'devtools::test(filter = "binomial-animal-slope-sd-regression")'`:
  16 passed, 0 failed, 0 warnings, 0 skipped; 34.6 seconds.
- `Rscript -e 'devtools::test(filter = "binomial-animal-(slope-)?sd-regression")'`:
  28 passed, 0 failed, 0 warnings, 0 skipped; 48.6 seconds. This includes the
  existing Bernoulli animal-intercept test.
- The project after-task checker accepted the report structure, then exited
  with unmet programme gates, as expected for this partial slice. G0–G8 and
  several child gates remain open.
- The constant-SD slope fit and the base animal-slope fit both converged; their
  log likelihoods agreed within `2e-5`.
- The point-recovery test used 240 groups, 32 observations per group, and a
  reversed, named positive-definite `A` matrix. It recovered the nonzero
  log-SD slope within `0.18` of its generating value. This is one fixed-seed
  recovery result; interval calibration remains untested.

## 6. Tests of the Tests

The new test first failed on the intended public call because the builder
rejected structured slopes. A first low-information fixture then fit but
recovered the SD slope poorly, so it was replaced with a higher-information
design. The final test also checks that group-SD prediction names match the
supplied matrix labels, that prediction equals the fitted `exp(W alpha)`
surface, that within-animal variation in `z` is rejected, and that ordinary
random effects cannot be added to this structured slope.

## 7a. Issue Ledger

No issue was updated. The open issue map has not yet been checked for a matching
general-SD or Bernoulli structured-slope issue, so issue maintenance remains
pending before this slice can be closed.

## 8. Consistency Audit

The equation, formula, and TMB interpretation agree for the one-coefficient
animal slope. The test uses the same named, reversed matrix ordering in the
generating model and fitted model and checks prediction labels. The design pages
now state the exact supported row and the absence of Julia and interval
calibration evidence.

The `R/drmTMB.R` file also has an active ZIP-slope lane lease. This slice's
validator change and the ZIP builder change occupy separate regions, and the
combined focused tests passed, but the source-owner handoff and post-handoff
diff review are still required before integration is considered settled. The
formula-grammar page, shared vignette, NEWS, and known-limitations page are
currently leased to the ZIP lane, so this report does not claim those surfaces
are synchronized. README status, the internal roadmap, pkgdown, and the main
check log remain to be audited after the shared-file leases clear.

## 9. What Did Not Go Smoothly

The first recovery design did not identify the SD slope well enough for the
planned tolerance. The check exposed that weakness before a recovery claim was
made. The lane-preflight and lease registry were slow, and the first lease
attempt could not write outside the workspace; the documentation lease was
later recorded successfully. A concurrent lease on `R/drmTMB.R` remains active.

## 10. Known Residuals

This evidence covers one native TMB q1 animal slope with supplied `A`, one
fixed seed, and complete responses. It does not establish calibration,
Julia parity, pedigree or `Ainv` support under this SD formula, other
structured providers, blocks, missing-response handling, or other response
families. The broader programme remains incomplete.

## 11. Team Learning

For Bernoulli random-slope recovery, group count alone is not enough. The test
needs informative within-group predictor variation and a generating SD
contrast large enough to be visible through the binary likelihood. The first
weak fixture is not evidence for recovery and should not be advertised.

## 12. Cross-Product Coverage

This slice covered one complete-data native R/TMB Bernoulli animal slope with
supplied `A`, including point recovery and public SD outputs. It ran locally.
It does NOT cover Julia fitting or the R-to-Julia bridge, other animal matrix
inputs, other structured providers, missing responses, larger blocks, other
families, interval calibration, or Totoro/DRAC runs. The formula-grammar page,
shared vignette, NEWS, and known-limitations page remain with the active ZIP
lane, and the full family, effect, endpoint, and backend matrix remains open.

## Next Actions

1. Reconcile the validator change with the active ZIP builder owner, review the
   exact combined diff, and rerun both focused test files after that handoff.
2. When their leases clear, update the formula-grammar page, shared vignette,
   NEWS, and limitations page, then audit README, roadmap, pkgdown, and the main
   check log for stale support claims.
3. Continue the required family/provider/backend matrix. This slice does not
   close G3, G4, G6, or the overall goal.
