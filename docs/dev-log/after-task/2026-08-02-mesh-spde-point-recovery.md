# After Task: Fixed-kappa mesh point recovery

## 1. Goal

Resolve issue #881 by testing the raw GMRF field-scale estimator for the exact
fixed-kappa univariate Gaussian `mu` mesh intercept before changing the spatial
article's inference display.

## 2. Implemented

The exact fixed-domain `n = 128` and `n = 256` designs now have authenticated
`point_fit_recovery` evidence. The runner freezes 50 independent attempts per
rung, fails closed on incomplete or suspect fits, records Monte Carlo
uncertainty, and preserves the earlier failed `n = 64` rung as the lower tested
boundary. `check_drm()` and the public status documents now state that exact
scope.

### Mathematical Contract

The fitted model is

\[
y = X\beta + A_{st}\omega + \epsilon, \quad
\omega \sim N\{0, s^2 Q(\kappa_0)^{-1}\}, \quad
\epsilon \sim N(0, \sigma^2 I).
\]

The recovered estimand is the raw covariance-scale multiplier `s`, not range
and not a uniform projected marginal SD. R syntax remains
`bf(y ~ spatial(1 | site, mesh = mesh), sigma ~ 1)`. The TMB field remains
`A_st %*% omega`; no C++ code changed in this recovery slice.

## 3a. Decisions and Rejected Alternatives

The accepted decision narrows promotion to the two exact tested designs and
retains `n = 64` as a failed boundary. Rejected alternatives were dropping the
failed seed, treating the failure as an optimizer-start problem, pooling V2
with V3, or reporting generic `n >= 128` recovery. Confidence bars were also
rejected because the recovery campaign did not calibrate intervals.

## 4. Files Touched

The slice adds the V3 helper, runner, contract tests, plan, adjudication, and
complete Totoro receipt. It updates `R/check.R`, its mesh regression test,
`README.md`, `ROADMAP.md`, `NEWS.md`, the formula-grammar design and vignette,
the spatial-models article, known limitations, the check log, and this report.
The dense `coords =` implementation was not edited.

## 5. Checks Run

- V3 helper contract: 22/22 expectations.
- All mesh filters after status synchronization: 87/87 expectations.
- Protected dense coordinate-spatial intercept/slope filters: 292/292
  expectations.
- Totoro V3: 100/100 usable; `PASS_POINT_RECOVERY_GATE`.
- `n = 128`: bias -0.0301, 95% MC interval [-0.0657, 0.0056], log-RMSE
  0.1444, upper MC bound 0.1799.
- `n = 256`: bias -0.0096, interval [-0.0375, 0.0182], log-RMSE 0.1009,
  upper bound 0.1173.
- `pkgdown::build_article("spatial-models", new_process = FALSE)`: completed;
  rendered HTML has the point-recovery wording and no emitted warning text.
- `git diff --check`: passed.

## 6. Tests of the Tests

The CRAN-safe helper tests reject duplicate or overlapping seeds, extra sample
size rungs, malformed replicate identifiers, missing/nonpositive estimates,
optimizer or Hessian failures, nonfinite objectives, excessive gradients,
warnings, incomplete denominators, and Monte Carlo intervals that overlap a
gate. Smoke mode can never promote. The existing independent dense marginal
likelihood comparator and off-optimum normalized GMRF density/gradient tests
remain green.

## 7a. Issue Ledger

Issue #881 was closed after the authenticated receipt and adjudication were
committed and pushed to PR #893. gllvmTMB issue #904 remains open for the
sibling package's separate SPDE field-scale evidence debt.

## 8. Consistency Audit

The status inventory covered `README.md`, `ROADMAP.md`, `NEWS.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
`vignettes/formula-grammar.Rmd`, `vignettes/spatial-models.Rmd`, and
`_pkgdown.yml`. The exact searches were:

```sh
rg -n -i "mesh|fixed[- ]kappa|field[- ]scale|local[- ]fit|point_fit_recovery|spatial_coords|make_mesh" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml vignettes/spatial-models.Rmd
rg -n "mesh.*local.fit|local.fit.*mesh|local-fit-only|recovery.*not claimed|recovery.*unclaimed" R tests README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/spatial-models.Rmd
```

Historical V2 and figure-audit notes remain unchanged because their blocked
verdicts were true when recorded; the V3 adjudication supersedes them.

## 9. What Did Not Go Smoothly

The first V3 smoke reused two proposed promotion seeds. Curie caught the defect
immediately after the Totoro launch. That process was stopped, its result was
declared inadmissible, all 100 proposed seeds were excluded, and the campaign
was rerun from a new clean commit with a wholly fresh ledger. The local preview
server also required unsandboxed port binding.

## 10. Known Residuals

The result is limited to the exact fixed-domain, uniform-location, fixed-mesh
recipe and signal settings at `n = 128` and `n = 256`. It does not erase the
`n = 64` failure or support a universal `n >= 128` threshold. Confidence
intervals, coverage, projected marginal-SD inference, range, other `kappa`
values, slopes, non-Gaussian or bivariate meshes, anisotropy, barriers,
replicated fields, and spatiotemporal fields remain unearned. PR #893 must
finish refreshed CI before merge.

## 11. Team Learning

Smoke, development, and promotion seed universes must be disjoint by
construction and tested before any result is viewed. A clean-source check is
not enough when a smoke run previews the promotion ledger.

## 12. Cross-Product Coverage

This arc covers the univariate Gaussian ML `mu` intercept with fixed `kappa`,
projected geographic input, the raw GMRF field-scale point estimator, public
extractor/diagnostic wording, and the exact V3 fixed-domain designs. It does NOT cover
REML, missing-response routes, non-Gaussian or bivariate families,
mesh slopes, other structured providers, range, projected marginal-SD
inference, intervals, coverage, prediction uncertainty, anisotropy, barriers,
replicated fields, or spatiotemporal fields. A separate interval-calibration
arc must earn the field-scale interval before the article draws a mesh
confidence interval. The coordinate-spatial SD and q2 correlation displays
also remain point-only under their existing evidence; cosmetic error bars are
not a substitute for calibration.
