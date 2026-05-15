# After Phase: Phase 11 Bivariate Correlation-Pair Foundation Closure

Date: 2026-05-15

## Goal

Close the local Phase 11 foundation for ordinary bivariate group-level
correlation pairs without claiming the full double-hierarchical endpoint. The
closed surface is Gaussian bivariate random-intercept covariance with
reader-facing `corpairs()` and `summary(fit)$covariance` rows that keep
group-level covariance separate from residual `rho12`.

## Implemented

- Matching labelled `(1 | p | id)` terms in `mu1` and `mu2` fit an ordinary
  bivariate mean-mean random-intercept covariance block.
- Matching labelled `(1 | p | id)` terms in `sigma1` and `sigma2` fit an
  ordinary bivariate scale-scale random-intercept covariance block on the
  `log(sigma)` random-effect scale.
- One same-response labelled pair, `mu1` with `sigma1` or `mu2` with
  `sigma2`, fits a mean-scale random-intercept covariance block.
- The ordinary all-four intercept-only q=4 pattern across `mu1`, `mu2`,
  `sigma1`, and `sigma2` fits one shared block and reports all six
  `corpairs()` rows.
- `corpairs()`, `profile_targets()`, `summary(fit)$covariance`, and
  `check_drm()` expose the fitted ordinary bivariate covariance rows while
  keeping residual `rho12` as a row-level residual correlation.
- Predictor-dependent q=2 `corpair()` regression is available for the ordinary
  `mu1`/`mu2` block and uses `newdata` for row-specific fitted correlations.

## Scope Boundary

This closure is not the full Phase 11 research programme. Bivariate random
slopes, coefficient-aware slope1-slope2 `corpair()` regression, full q=6 or q=8
double-hierarchical endpoint blocks, direct profile intervals for derived q=4
correlations, random effects in `rho12`, structured spatial covariance, and
non-phylogenetic species covariance remain planned until they have likelihood
code, recovery tests, diagnostics, user-facing examples, and their own
after-task evidence.

## Mathematical Contract

For the ordinary mean-mean block:

```text
u_j = [b_mu1,j, b_mu2,j]'
u_j ~ MVN(0, Sigma_group)
cor(b_mu1,j, b_mu2,j) = rho_group
```

For scale-scale and mean-scale blocks, the same covariance contract applies to
the fitted random-effect coefficients. Scale effects live on the
`log(sigma)` predictor, so a `sigma1`-`sigma2` covariance is a covariance among
persistent deviations in log residual scale, not a covariance among raw
residual variances.

Residual coscale remains separate:

```text
Omega_i[1, 2] = rho12_i sigma1_i sigma2_i
rho12_i = 0.99999999 * tanh(X_rho12[i, ] beta_rho12)
```

`corpairs()` therefore reports at least two different correlation layers when a
bivariate model contains both grouped covariance and residual correlation:
group-level rows for persistent individual differences and residual rows for
within-observation coupling.

## Standing Review Closure

- Ada: close the ordinary random-intercept foundation, not the full
  double-hierarchical endpoint.
- Boole: the supported syntax uses labelled `(1 | p | id)` terms; random-slope
  syntax in bivariate covariance blocks still errors clearly.
- Gauss: the fitted likelihood paths cover q=2 ordinary bivariate covariance
  blocks and the intercept-only q=4 block; derived q=4 intervals are not
  direct profile intervals.
- Noether: equations, R syntax, fitted random-effect scales, `corpairs()`
  labels, `profile_targets()`, and summary rows agree on the same covariance
  meanings.
- Darwin: the examples distinguish mean-mean, scale-scale, mean-scale, and
  residual `rho12` questions for applied ecology and evolution users.
- Fisher: tests include recovery-style checks, direct target inventories,
  malformed unsupported syntax, and diagnostics for weak or boundary
  covariance rows.
- Pat: a user can read `level`, `group`, `block`, `from_dpar`, `to_dpar`,
  `from_coef`, `to_coef`, class, and uncertainty status from `corpairs()`.
- Jason: structured phylogenetic and spatial covariance remain separate lanes;
  Phase 11 does not collapse them into residual `rho12`.
- Curie: focused tests cover bivariate Gaussian fitting, `corpairs()`,
  covariance registry rows, profile targets, summary covariance output, and
  `check_drm()` diagnostics.
- Emmy: the labelled covariance registry and summary APIs are the stable
  reporting surface for later covariance expansions.
- Grace: local tests, pkgdown, and package check are the gate; GitHub Actions
  remains the PR-side gate.
- Rose: stale wording should not say that random slopes, q=4 direct intervals,
  `rho12` random effects, or spatial bivariate covariance are implemented.

## Files Changed In Gate Slice

- `ROADMAP.md`
- `R/drmTMB.R`
- `docs/design/04-random-effects.md`
- `docs/design/17-correlated-random-effect-blocks.md`
- `docs/design/34-validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-phase/2026-05-15-phase-11-bivariate-corpairs-foundation-closure.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format ROADMAP.md R/drmTMB.R docs/design/04-random-effects.md docs/design/17-correlated-random-effect-blocks.md docs/design/34-validation-debt-register.md docs/dev-log/check-log.md docs/dev-log/after-phase/2026-05-15-phase-11-bivariate-corpairs-foundation-closure.md`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "biv-gaussian|corpairs|profile-targets|summary|check-drm|covariance-block-registry", reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`
- `git diff --check`
- Source and rendered scans for Phase 11 closure wording and stale overclaims
  about random slopes, q=4 direct intervals, `rho12` random effects, and
  spatial bivariate covariance.

All tests and checks passed. `pkgdown::check_pkgdown()` found no problems.
`devtools::check()` passed with 0 errors, 0 warnings, and 0 notes in
2m 17s.

## Tests Of The Tests

The focused gate exercises positive fitted paths and unsupported syntax. The
bivariate Gaussian tests fit `mu1`/`mu2`, `sigma1`/`sigma2`, same-response
`mu`/`sigma`, combined `rho12`, and ordinary q=4 covariance blocks. The
`corpairs()` and summary tests verify that group-level covariance rows do not
reuse residual `rho12` labels. The profile-target tests mark q=2 targets as
direct and q=4 correlation targets as derived and not profile-ready. The
malformed-syntax tests reject bivariate random slopes and unsupported
cross-response mean-scale pairings.

## Consistency Audit

The ROADMAP now records the local Phase 11 foundation closure and keeps random
slopes, q=4 direct intervals, `rho12` random effects, and structured spatial
covariance planned. The validation-debt register points to this report and
continues to list the remaining debt. Source and rendered scans found no
current non-dev-log overclaim that the planned covariance extensions are
implemented. The stale scan returned only allowed planned-boundary statements:
README and rendered ROADMAP say bivariate random slopes remain planned,
`vignettes/distribution-families.Rmd` says richer covariance is planned,
`docs/design/01-formula-grammar.md` says `(1 + x1 | p | id)` should be
supported once bivariate random slopes are implemented, and
`docs/design/28-double-hierarchical-endpoint.md` says q4 derived intervals
remain planned.

## What Did Not Go Smoothly

The largest risk is name collision between correlation layers. Phase 11 has to
keep ordinary grouped covariance, phylogenetic covariance, spatial covariance,
mean-scale covariance, and residual `rho12` in separate namespaces even when
they all read biologically as "correlation".

## Known Limitations

- Only random-intercept bivariate covariance is locally closed.
- Scale covariance is on the `log(sigma)` random-effect scale.
- q=4 covariance rows are fitted point summaries with derived interval status;
  direct q=4 profile intervals remain planned.
- Bivariate random slopes and coefficient-aware slope-pair `corpair()`
  regression remain planned.
- Random effects in `rho12` remain blocked.
- Structured spatial covariance and non-phylogenetic species covariance remain
  planned.
- GitHub Actions remains the PR-side gate.

## Next Actions

1. Move to Phase 12 only with the ordinary, phylogenetic, spatial, and residual
   correlation layers kept separate.
2. Add bivariate random slopes only after a coefficient-aware `corpair()`
   contract has likelihood code and recovery evidence.
3. Keep q=4 derived interval work separate from point-estimate reporting.
