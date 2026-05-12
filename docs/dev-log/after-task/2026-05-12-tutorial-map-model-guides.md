# After Task: Tutorial Map And Model Guides

## Goal

Create a small documentation branch that makes the tutorial architecture
clearer without mixing with the active covariance branches. The implemented
claim is: the pkgdown site now separates orientation guides from worked
tutorials, the Getting Started page points readers to a new model-status map,
and the highest-traffic tutorial equations now use rendered biological-model
notation instead of plain text blocks.

## Implemented

Added `vignettes/model-map.Rmd` as "What can I fit today?", a guide for
implemented versus planned `drmTMB` model surfaces. It covers one-response
Gaussian location-scale models, random-effect scale distinctions, fixed-effect
non-Gaussian families, known sampling covariance, two-response Gaussian
`rho12`, the first labelled bivariate `mu1`/`mu2` random-intercept covariance
slice, and the narrow implemented `phylo()` path.

Shortened `vignettes/drmTMB.Rmd` so Getting Started keeps installation, the
first model, the learning path, and a compact current-surface table. Moved the
longer implemented-versus-planned discussion into the new guide.

Updated `_pkgdown.yml` so the navbar and article index now have four clearer
reader buckets: Getting Started, Model Guides, Tutorials, and Developer Notes.
Updated `docs/design/21-tutorial-style.md` to record the guide-versus-tutorial
rule for future contributors.

Normalized core symbolic model blocks in `location-scale`, `which-scale`,
`bivariate-coscale`, `phylogenetic-spatial`, and `robust-student`. The edited
equations now use rendered LaTeX with meaningful variable names such as
`\text{growth}_i`, `\text{temperature}_i`, `\text{activity}_i`, and
`\text{habitat}_j`; fenced text blocks remain only where they are explicitly
implementation cross-checks or code-like summaries.

Normalized the implemented-family contracts in `distribution-families`. The
family guide now uses rendered LaTeX for Gaussian, Student-t, lognormal,
Gamma, beta, Poisson, zero-inflated Poisson, NB2, zero-inflated NB2,
zero-truncated NB2, hurdle NB2, beta-binomial, and cumulative-logit equations.
The public R syntax blocks stayed as executable R examples.

Added a candidate worked-tutorial table to the tutorial-style design note.
The candidates are count abundance and extra zeros, positive counts after
conditional sampling, continuous proportions, successes out of trials, and
ordered severity scores.

After bounded Pat, Grace, Noether, and Rose review, tightened the branch before
publication: the structured-dependence article now has one stable short label,
the model map uses article links instead of quoted page names, Getting Started
defines compact table terms before sending readers onward, the implemented
`sd(group)` claim is narrowed to unlabelled Gaussian `mu` random-intercept SDs,
future phylogenetic location-scale correlations are labelled as future, and
rendered `rho12` subscripts now match the public API spelling.

## Mathematical Contract

No likelihood, formula grammar, or fitted model behavior changed. The guide
keeps the existing parameter vocabulary: `mu`, `sigma`, `sd(group)`,
`meta_known_V(V = V)`, `phylo()`, `spatial()`, and residual bivariate `rho12`.
It explicitly separates residual `rho12`, ordinary group-level correlations,
and future phylogenetic or spatial correlation layers. The new candidate
tutorial sketches are limited to implemented or documented family surfaces and
do not introduce new syntax.

## Files Changed

- `_pkgdown.yml`
- `docs/design/21-tutorial-style.md`
- `docs/dev-log/check-log.md`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/distribution-families.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/robust-student.Rmd`
- `vignettes/which-scale.Rmd`
- `docs/dev-log/after-task/2026-05-12-tutorial-map-model-guides.md`

## Checks Run

- `ruby -e 'require "yaml"; YAML.load_file("_pkgdown.yml"); puts "ok _pkgdown.yml"'`:
  passed.
- `air format _pkgdown.yml vignettes/drmTMB.Rmd vignettes/model-map.Rmd docs/design/21-tutorial-style.md`:
  completed.
- `air format vignettes/location-scale.Rmd vignettes/which-scale.Rmd vignettes/bivariate-coscale.Rmd vignettes/phylogenetic-spatial.Rmd vignettes/robust-student.Rmd docs/design/21-tutorial-style.md`:
  completed after equation-style edits.
- `Rscript -e "pkgdown::build_article('model-map')"`: passed and wrote
  `articles/model-map.html`; pkgdown emitted only local pre-existing-directory
  warnings from `pkgdown-site/deps`.
- `Rscript -e "pkgdown::build_article('drmTMB')"`: passed and wrote
  `articles/drmTMB.html`; pkgdown emitted only a local pre-existing-directory
  warning from `pkgdown-site/deps`.
- `Rscript -e "for (x in c('location-scale','which-scale','bivariate-coscale','phylogenetic-spatial','robust-student','drmTMB','model-map')) pkgdown::build_article(x)"`:
  passed for all listed articles.
- `Rscript -e "pkgdown::build_article('distribution-families')"`:
  passed and wrote `articles/distribution-families.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `air format _pkgdown.yml vignettes/drmTMB.Rmd vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`:
  completed after Pat's navigation review fixes.
- `air format vignettes/bivariate-coscale.Rmd vignettes/which-scale.Rmd vignettes/location-scale.Rmd vignettes/drmTMB.Rmd`:
  completed after Noether/Rose terminology fixes.
- `rg -n 'rho 12|In phylogenetic location-scale models|random-effect scale formulas for `mu`|Known sampling variance: `meta_known_V\\(V = vi\\)`|Structured dependence: implemented|Implemented phylogeny and planned space' vignettes _pkgdown.yml`:
  no matches after the reviewer cleanup.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed after the final
  navigation and terminology edits.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found after
  the final site build.
- `rg -n '```text|\\mathrm\\{Normal\\}|temperature_|growth_|x1_|x2_|yi_i' vignettes/location-scale.Rmd vignettes/which-scale.Rmd vignettes/robust-student.Rmd vignettes/bivariate-coscale.Rmd vignettes/phylogenetic-spatial.Rmd`:
  confirmed only intentional code-like or R-object leftovers remained.
- `rg -n '```text|temperature_i|treatment_i|habitat_i|trap_nights_i|survey_method_i|larger fitted sigma|^(<<<<<<<|=======|>>>>>>>)' vignettes/distribution-families.Rmd`:
  no matches.
- `rg -n '<<<<<<<|=======|>>>>>>>' docs/dev-log/check-log.md _pkgdown.yml vignettes/drmTMB.Rmd vignettes/model-map.Rmd docs/design/21-tutorial-style.md docs/dev-log/after-task/2026-05-12-tutorial-map-model-guides.md`:
  no conflict markers found.
- `rg -n "What can I fit today\\?|Model Guides|Guide Versus Tutorial Split|model-map|rho ~|meta_gaussian\\(|tau ~|meta_known_V\\([^V]" _pkgdown.yml vignettes docs/design README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md`:
  confirmed the new navigation/style strings and found only intentional
  guardrail references for unsupported meta-analysis and `rho` shortcut
  syntax.
- `git diff --check`: clean.

## Tests Of The Tests

No package tests were added because this task changed documentation and site
navigation only. The relevant executable checks were article rendering for the
new guide, edited Getting Started page, and touched tutorial pages; YAML
parsing for `_pkgdown.yml`; stale-text searches; and `pkgdown::check_pkgdown()`
for article-index consistency.

## Consistency Audit

The guide keeps the univariate and bivariate scope boundary from AGENTS.md:
models are one-response or two-response only, higher-dimensional multivariate
models remain `gllvmTMB` territory, and `rho12` is the canonical residual
bivariate correlation name. The stale-wording scan found existing design-note
guardrails for `meta_gaussian()`, `tau ~`, and `rho ~`; it did not find a new
user-facing shortcut or unsupported model claim introduced by this branch. The
candidate tutorial table and the family guide use `cbind(germinated,
not_germinated)` or `cbind(successes, failures)` for beta-binomial responses,
matching the current family guide rather than a planned successes/trials alias.
The reviewer pass also checked that spatial models remain labelled planned, that
future phylogenetic scale/correlation language does not imply implementation,
and that the untracked `vignettes/model-map.Rmd` must be staged with the
`_pkgdown.yml` navigation change.

## What Did Not Go Smoothly

PR #15 landed on `origin/main` while this branch was in progress. The rebase
was clean except for `docs/dev-log/check-log.md`, where both branches added a
new top entry. The conflict was resolved by keeping the new bivariate group
covariance bridge entry and the tutorial-map entry. Running two
`pkgdown::build_article()` calls in parallel was also noisier than necessary
because each call initialized the same local `pkgdown-site` asset cache. Both
builds passed, and the warnings were only about directories that already
existed. Future article checks should run sequentially when clean logs matter.

## Team Learning

Ada should keep this lane small: it is a navigation and orientation patch, not
a package-behaviour change. Pat's likely reader test is whether a new applied
user can tell which page answers "what can I fit?" versus "how do I run this
analysis?", and whether the first equation on a tutorial page now looks like a
biological model rather than implementation scratch text. Noether's check is
that rendered equations, R formulas, and parameter names still match. Rose's
audit point is to keep planned spatial and structured-covariance wording
visibly planned until implementation, recovery tests, `corpairs()` rows, and
examples exist.

## Known Limitations

This branch does not create the candidate future worked tutorials; it records
the plan and keeps the current branch to navigation plus equation-style
cleanup. It also does not convert developer design notes, which still use
fenced text equations for implementation contracts. It does not run
`devtools::test()` because no package code or roxygen documentation changed.

## Next Actions

1. Open the small docs PR and let the PR `R-CMD-check` restore the GitHub
   Actions rhythm.
2. After merge, confirm the `main` `R-CMD-check` and workflow-run `pkgdown`
   deploy so the public site reflects the branch.
3. Pick one candidate worked tutorial to develop next, probably count
   abundance and extra zeros or continuous proportions, depending on the next
   scientific story the project wants to tell.
4. Consider a later dedicated "correlation layers" guide only if the
   group-level, phylogenetic, spatial, and residual-correlation explanations
   outgrow the new model map.
