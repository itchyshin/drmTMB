# After Task: Phylogenetic-Spatial Tutorial Teaching Upgrade

## Goal

Make the structured-dependence article teach the implemented
`phylo(1 | species, tree = tree)` path as a usable model, while keeping spatial
terms and richer phylogenetic structures clearly marked as planned.

## Implemented

- Rewrote `vignettes/phylogenetic-spatial.Rmd` around the implemented
  intercept-only univariate Gaussian phylogenetic location model.
- Added a worked thermal-tolerance example with body size, species, an
  ultrametric branch-length tree, fitted `summary()` output, residual SD,
  phylogenetic SD, and `check_drm()` output.
- Added LaTeX equations for the general structured-effect bridge and the
  implemented phylogenetic Gaussian location model.
- Added a practical checklist for common phylogenetic fitting failures:
  `phylo` class, matching species names and tree tip labels, branch lengths,
  ultrametricity, and currently supported syntax.
- Marked the spatial section as "planned, not implemented" before the code
  block.
- Updated `README.md` to distinguish `sigma_phylo` from residual `sigma`.
- Updated `ROADMAP.md` to clarify that future sparse known-covariance
  infrastructure is beyond the currently implemented phylogenetic A-inverse
  path.
- Added a `NEWS.md` bullet for the tutorial upgrade.

## Mathematical Contract

General structured-effect module:

```text
eta_d = X_d beta_d + Z_d z
z ~ MVN(0, sigma_z^2 K)
```

Implemented phylogenetic Gaussian location model:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = x_mu_i' beta_mu + a_species[i]
log(sigma_i) = x_sigma_i' beta_sigma
a ~ MVN(0, sigma_phylo^2 A)
```

The matching implemented syntax is:

```r
drmTMB(
  drm_formula(
    y ~ x1 + phylo(1 | species, tree = tree),
    sigma ~ x1
  ),
  family = gaussian(),
  data = dat
)
```

`sigma_phylo` is the among-species phylogenetic SD in the mean after fixed
effects. Residual `sigma` remains the within-observation residual SD.

## Files Changed

- `vignettes/phylogenetic-spatial.Rmd`
- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-09-phylogenetic-spatial-tutorial-teaching-upgrade.md`

## Checks Run

```sh
Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/phylogenetic-spatial.Rmd', output_dir = tempdir(), quiet = TRUE)"
Rscript -e "devtools::test(filter = 'phylo|check-drm')"
git diff --check
Rscript -e "devtools::test()"
Rscript -e "pkgdown::build_site()"
Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"
```

Results:

- phylogenetic-spatial vignette render: passed;
- targeted phylogenetic/check tests: 124 passed, 0 failed, 0 warnings, 0 skips;
- `git diff --check`: clean;
- full tests: 1215 passed, 0 failed, 0 warnings, 0 skips;
- pkgdown build: passed;
- pkgdown check: no problems found;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

The rendered tutorial exercises the implemented univariate Gaussian
phylogenetic `mu` path and prints the same diagnostic classes used in the
tests. The targeted phylogenetic tests also compare the fitted objective to an
independent dense marginal likelihood, combine phylogeny with known
meta-analytic covariance, check conditional predictions, check missing-row
handling, and verify planned-feature errors for phylogenetic slopes and
phylogenetic `sigma`.

## Consistency Audit

Searches run:

```sh
rg -n "spatial fields|spatial\\(1 \\| site|planned, not implemented|Hadfield and Nakagawa|A-inverse path internally|sigma_phylo|thermal tolerance|species names" vignettes/phylogenetic-spatial.Rmd README.md ROADMAP.md NEWS.md
rg -n "Structured dependence: implemented phylogeny|thermal tolerance|body size predicts|tree object has class|spatial likelihood is not implemented|setup code creates|sigma_phylo|Hadfield and Nakagawa|A-inverse path internally" pkgdown-site/articles/phylogenetic-spatial.html pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html
```

The generated site contains the new title, thermal-tolerance example,
tree/species checklist, spatial-not-implemented wording, and README
`sigma_phylo` distinction. No user-facing match remains for "Hadfield and
Nakagawa sparse augmented A-inverse path internally" in the vignette.

## What Did Not Go Smoothly

The first draft still called the toy tree generator a "hidden helper", which
felt too much like implementation machinery for an applied tutorial. The prose
now says the setup code creates a small ultrametric tree, while real analyses
usually supply a tree from a phylogenetic data workflow.

## Team Learning

- Socrates identified that an article with "roadmap" in the title can still
  contain implemented user-facing functionality and should therefore start
  with a concrete scientific question.
- Pat-style tutorial review should always ask whether the article tells users
  what to check next after unsupported or malformed structured-effect syntax.
- Rose should keep checking that planned spatial examples are labelled before,
  not after, code blocks.
- Ada should keep token and context use efficient: prefer targeted reads,
  concise status updates, and bounded agent tasks with clear value.

## Known Limitations

- The example uses simulated data and a toy tree.
- Spatial random effects are still planned, not implemented.
- Phylogenetic random slopes, phylogenetic `sigma`, and bivariate structured
  covariance blocks remain planned.
- The tutorial does not yet include a real phylogenetic comparative dataset or
  a plot of fitted species effects.

## Next Actions

1. Add a real phylogenetic comparative example once a small public dataset is
   selected.
2. Add an extractor or public helper for phylogenetic SD summaries so tutorials
   do not need to use `fit$sdpars$mu`.
3. Draft the spatial SPDE design note before exposing any spatial syntax as
   runnable tutorial code.
