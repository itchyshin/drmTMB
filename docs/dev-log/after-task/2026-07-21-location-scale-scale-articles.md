# After Task: Short Location-Scale and Location-Scale-Scale Articles

## 1. Goal

Replace the long single location-scale tutorial with two relatively short
articles: one for `mu` plus residual `sigma`, and one for `mu`, `sigma`, and a
grouped or phylogenetic random-effect `sd()` surface.

## 2. Implemented

The former 1,096-line article is now a 542-line Part 1. It retains the runnable
growth example and the interpretation of residual `sigma`, but removes long
side routes that are already documented elsewhere.

A new 364-line Part 2 introduces ordinary `sd(group) ~ predictors`, then the
phylogenetic form `sd(species, level = "phylogenetic") ~ predictors`. It
contains two runnable Gaussian fits, Ayumi-style syntax with the same climate
basis in all three submodels, and a derived phylogenetic variance proportion.

## 3. Mathematical Contract

Part 1 models the Gaussian response mean and residual log-SD:

\[
y_i \sim \operatorname{Normal}(\mu_i,\sigma_i^2),\qquad
\mu_i=X_{\mu,i}\beta,\qquad
\log\sigma_i=X_{\sigma,i}\gamma.
\]

Part 2 adds a predictor-dependent random-effect SD. For the phylogenetic case,

\[
\mathbf y \sim \operatorname{MVN}
\left(\boldsymbol\mu,D_a A D_a + D_e I D_e\right),
\]

where `sigma ~ ...` models the diagonal of \(D_e\) and
`sd(species, level = "phylogenetic") ~ ...` models the diagonal of \(D_a\).
The article does not equate family `sigma` with the latent phylogenetic SD.

## 3a. Decisions and Rejected Alternatives

The two articles remain a consecutive sequence rather than independent pages:
Part 1 establishes `mu` and residual `sigma`; Part 2 adds ordinary and
phylogenetic `sd()` surfaces. The new page teaches both grouped and
phylogenetic forms because they share the distinction between response scale
and latent random-effect scale.

Rejected alternative: do not keep the original one-row-per-species runnable
simulation. It rendered successfully but produced a collapsed phylogenetic SD
surface, so it was unsuitable as teaching evidence. The exact comparative
syntax remains in a non-evaluated block, while the runnable example uses
within-species replication.

Rejected alternative: do not add a Beta worked example here. The live model
map records only a narrow Beta q1 phylogenetic recovery slice, whereas this
tutorial teaches the broader Gaussian route. Mixing those evidence tiers would
make a short page longer and could overstate non-Gaussian support.

## 4. Files Touched

- `vignettes/location-scale.Rmd`: shortened and renamed Part 1.
- `vignettes/location-scale-scale.Rmd`: added Part 2.
- `_pkgdown.yml`: placed both parts consecutively in the navbar and article
  index.
- `vignettes/drmTMB.Rmd`: added the two-part route to the main learning path.
- `vignettes/count-nbinom2.Rmd`, `vignettes/figure-gallery.Rmd`,
  `vignettes/model-map.Rmd`, `vignettes/structural-dependence.Rmd`, and
  `vignettes/which-scale.Rmd`: synchronized the Part 1 link label.
- `docs/design/226-reader-learning-path.md`: placed the 35th vignette and
  updated the counts.
- `docs/dev-log/check-log.md` and this report: recorded the evidence.

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'pkgdown::build_article("location-scale-scale", quiet = FALSE, new_process = FALSE)'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'pkgdown::check_pkgdown()'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'pkgdown::build_site(new_process = FALSE)'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'for (x in c("drmTMB", "count-nbinom2", "model-map", "structural-dependence", "which-scale", "location-scale", "location-scale-scale")) pkgdown::build_article(x, quiet = TRUE, new_process = FALSE)'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'pkgdown::build_article("figure-gallery", quiet = TRUE, new_process = FALSE)'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'pkgdown::build_home(); pkgdown::check_pkgdown()'
rg -n "\\[When variance carries signal\\]\\(location-scale\\.html\\)|>When variance carries signal</a>|\\\"When variance carries signal\\\"" vignettes pkgdown-site/articles --glob '*.Rmd' --glob '*.html' --glob '*.md'
git diff --check
rg -n '[[:blank:]]+$' vignettes/location-scale-scale.Rmd
gh issue list --repo itchyshin/drmTMB --state open --search 'location scale in:title,body' --limit 20
gh issue list --repo itchyshin/drmTMB --state open --search 'sd tutorial in:title,body' --limit 20
```

The configuration check and full site build passed. The final stale-title and
trailing-whitespace searches returned no matches.

## 6. Tests of the Tests

No package tests changed because this is a documentation-only slice. The
runnable chunks are nevertheless substantive checks: they fit an ordinary
grouped location-scale-scale model and a phylogenetic one, then exercise
`coef()` and `predict()` for both `sigma` and direct phylogenetic `sd()`.

The first one-row-per-species simulation rendered without an error but
collapsed the fitted phylogenetic log-SD intercept to `-11.909` and reversed
its slope to `-0.314`. Inspecting rendered numerical output therefore caught a
scientifically misleading example that a build-success check alone would have
missed. The replacement uses repeated observations and recovers the intended
opposing scale directions.

## 7a. Issue Ledger

Open-issue searches for `location scale` and `sd tutorial` found related
implementation arcs but no exact documentation issue, so no issue was opened
or modified. This branch is stacked on open PR #810, `docs: correct pre-CRAN
capability claims`. That parent advanced by one README-only commit during the
task. This branch was rebased onto that commit; there is no file overlap, and
the post-rebase home build and pkgdown check passed.

## 8. Consistency Audit

The equations, R syntax, and interpretation use one stable distinction:
`sigma` is the independent response-scale SD, whereas `sd(group)` is the SD of
a location random effect. The generic phylogenetic formula spelling is used in
model calls; the internal `sd_phylo(species)` extractor label is explained
once. Navigation, article index, starting-page learning path, and all current
cross-links use the Part 1/Part 2 titles.

No likelihood, parser, C++, formula grammar, model-map status, `NEWS.md`, or
`ROADMAP.md` capability statement changed.

## 9. What Did Not Go Smoothly

The first phylogenetic example was statistically weak despite a successful
render. Replacing it with a repeated-observation design made the two scale
surfaces identifiable enough for a short build-time example. The full site
build also took several minutes, but completed without warnings or errors.

The project-local `after-task-audit` skill still shows an older unnumbered
report template. The repository validator correctly rejected that first draft;
this report now follows the enforced numbered schema.

## 10. Known Residuals

Part 2 teaches the Gaussian route. It does not imply broad non-Gaussian support,
random effects on the right-hand side of `sd()`, generic spatial/animal/relmat
direct-SD surfaces, or a model that combines direct phylogenetic `sd()` with an
additional phylogenetic random effect inside `sigma`. A one-row-per-species fit
also needs stronger data and diagnostics than the compact repeated-observation
example.

## 11. Team Learning

A rendered statistical tutorial is not validated until its displayed estimates
have been read. For future model tutorials, the documentation checklist should
record both build success and whether the fitted output demonstrates the stated
scientific contrast.

The current after-task skill template should be synchronized with the validator
so future reports fail less late.

## 12. Cross-Product Coverage

Covers: univariate Gaussian `mu` plus residual `sigma`; ordinary unlabelled
location random-intercept `sd(group)` surfaces; and one univariate
phylogenetic location `sd(species, level = "phylogenetic")` surface. Both
ordinary and phylogenetic examples run during pkgdown builds, and the latter
exercises direct-SD prediction and a derived variance proportion.

Does NOT cover: Beta or other non-Gaussian families beyond links to the live
model map; bivariate endpoints; labelled or slope SD targets; random RHS terms
inside `sd()`; direct spatial, animal, or `relmat()` SD surfaces; structured
effects inside family `sigma`; REML; interval calibration; or posterior-tree
pooling.

## 13. Next Actions

This branch is synchronized with the current PR #810 head. Once that parent is
merged, rebase this commit onto `main` and open the focused docs PR. A later,
separate article can explain how family `sigma` maps to dispersion across
Gaussian, Beta, count, and other families; that broader family guide is not
part of this split.
