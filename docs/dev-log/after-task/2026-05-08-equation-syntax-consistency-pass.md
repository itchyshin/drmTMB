# After Task: Equation-Syntax Documentation Consistency Pass

## Goal

Make the public documentation show the same model in three ways: the applied
question, the symbolic equation, and the supported R syntax.

## Implemented

- Added a compact applied framing question to `vignettes/drmTMB.Rmd`.
- Added equation-and-syntax pairings for:
  - Gaussian location-scale regression;
  - ordinary `mu` random intercepts;
  - residual-scale random intercepts in `sigma`;
  - group-level scale models via `sd(group)`;
  - intercept-only phylogenetic `mu` effects;
  - fixed-effect bivariate Gaussian `rho12`;
  - known sampling covariance via `meta_known_V(V = V)`.
- Added README equation context for bivariate residual covariance,
  meta-analysis known covariance, and phylogenetic location effects.
- Updated `docs/design/01-formula-grammar.md` so implemented bivariate
  Gaussian syntax is fixed-effect only, while bivariate random effects and
  `mvbind()` shorthand are clearly future work.
- Updated `ROADMAP.md` to describe implemented `sd(group)` support as one or
  more distinct unlabelled univariate Gaussian `mu` random-intercept targets.
- Updated `_pkgdown.yml` so the `phylo()` reference is no longer grouped under
  a purely planned heading.
- Clarified `vignettes/phylogenetic-spatial.Rmd` so phylogenetic `mu` is the
  implemented target and phylogenetic residual-scale terms remain planned.

## Mathematical Contract

The get-started documentation now states the implemented contracts directly.
For example, the basic Gaussian location-scale model is:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
```

The fitted phylogenetic location slice is:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + a_species[i]
log(sigma_i) = X_sigma[i, ] beta_sigma
a ~ MVN(0, sigma_phylo^2 A)
```

The bivariate Gaussian residual-correlation slice is:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
rho12_i = tanh(X_rho12[i, ] beta_rho12)
Omega_i[1, 2] = rho12_i sigma1_i sigma2_i
```

These equations match the currently supported R syntax and avoid showing
planned bivariate random effects or `mvbind()` shorthand as implemented.

## Files Changed

- `README.md`
- `_pkgdown.yml`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/dev-log/check-log.md`
- `vignettes/drmTMB.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

- `rg` stale-status scans for bivariate random-effect, `mvbind()`,
  intercept-only `phylo()`, `sd(group)`, old person-name shorthand, and
  biology-only wording.
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

## Tests Of The Tests

This was a documentation consistency task, so no new unit tests were added.
The safeguard was a two-reader review:

- Pat checked whether an applied user could see the model question and connect
  the syntax to equations.
- Rose checked cross-document status drift between README, vignettes, roadmap,
  formula grammar, likelihood notes, and known limitations.

The full package check also rebuilt vignettes and ran the test suite through
R CMD check.

## Consistency Audit

- `phylo(1 | species, tree = tree)` is now described consistently as
  implemented only for univariate Gaussian `mu`.
- `phylo(1 + x | species, tree = tree)`, phylogenetic `sigma`, spatial terms,
  bivariate random effects, and `mvbind()` shorthand are described as planned.
- `rho12` remains residual response-response correlation, not a group-level
  covariance label.
- `sigma` remains residual SD; `sd(group)` remains a group-level random-effect
  scale model.
- `meta_known_V(V = V)` remains known sampling covariance in Gaussian
  regression, not a separate meta-analysis family.
- The README now describes shape and zero inflation as design direction, while
  listing the currently implemented Gaussian and known-covariance paths.

## What Did Not Go Smoothly

- A first stale-wording `rg` command used double quotes around a pattern with
  backticks, so zsh attempted command substitution. The scan was rerun with
  single quotes.
- The rendered pkgdown search index includes old changelog and after-task text.
  Those are historical records and should not be mechanically rewritten unless
  they misdescribe current pages outside their historical context.

## Team Learning

- Pat's user-testing lens improved the first page: the documentation now starts
  with a real modelling question before moving into equations.
- Rose's systems-audit lens found the highest-risk drift: status labels for
  implemented versus planned syntax.
- Future documentation tasks should start from the likelihood note pattern:
  equation, matching R syntax, then interpretation.

## Known Limitations

- No new model code was added.
- Equation detail is now present in the overview, but the next pass should
  continue improving worked examples with real ecological, evolutionary, and
  environmental data stories.
- The bivariate double-hierarchical model remains planned and needs equations,
  simulations, and implementation before any public "implemented" wording.

## Next Actions

1. Add a small implemented-versus-planned status table to the formula-grammar
   vignette if users continue to confuse parsed syntax with fitted syntax.
2. Continue comparator and simulation work for the fitted phylogenetic
   location model.
3. Start the next modelling slice only after the current documentation commit
   is pushed and GitHub Actions are green.
