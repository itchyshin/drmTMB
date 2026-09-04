# After Task: Tutorial Map And Model-Guide Equation Consistency

## Goal

Make the highest-traffic tutorials easier to navigate and make their main
symbolic models use LaTeX display math paired with fenced R syntax and direct
interpretation.

## Implemented

- Expanded the learning-path table in `vignettes/drmTMB.Rmd` into a
  question-first route map.
- Added an article-architecture section to `docs/design/21-tutorial-style.md`
  to keep model-class tutorials separate from larger biological case-study
  articles.
- Converted high-visibility plain-text model blocks to LaTeX display math in
  `vignettes/drmTMB.Rmd`, `vignettes/which-scale.Rmd`,
  `vignettes/bivariate-coscale.Rmd`, `vignettes/phylogenetic-spatial.Rmd`, and
  `docs/design/28-double-hierarchical-endpoint.md`.
- Converted the compact distribution-family model contracts in
  `vignettes/distribution-families.Rmd` from fenced text blocks to rendered
  LaTeX equations while preserving the matching R syntax blocks and
  family-specific limitations.
- Rebuilt the full pkgdown site after the distribution-family cleanup.
- Converted the introductory post-fit Gaussian model in
  `vignettes/model-workflow.Rmd` and the Student-t model contract in
  `vignettes/robust-student.Rmd` to rendered LaTeX equations.
- Converted remaining reader-facing model statements in
  `vignettes/location-scale.Rmd` to rendered LaTeX equations, including
  residual-scale random slopes, double-hierarchical `sd(id)` models, multiple
  random intercepts, simple random slopes, labelled mean-scale covariance, and
  the Gaussian meta-analysis equations.
- Converted model-statement and likelihood equations in
  `vignettes/adding-families.Rmd` to rendered LaTeX equations while leaving
  field, prediction, and file checklists as fenced text blocks.
- Re-reviewed `vignettes/bivariate-coscale.Rmd`; its main fixed-effect, worked
  example, and group-level model statements are already rendered equations, so
  the one remaining fenced text block stays as an explicitly labelled
  implementation cross-check.
- Left compact text-style blocks only where they are implementation
  cross-checks, checklists, or lower-priority later sections.

## Files Changed

- `vignettes/drmTMB.Rmd`
- `vignettes/which-scale.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/distribution-families.Rmd`
- `vignettes/model-workflow.Rmd`
- `vignettes/robust-student.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/adding-families.Rmd`
- `docs/design/21-tutorial-style.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format vignettes/drmTMB.Rmd vignettes/bivariate-coscale.Rmd vignettes/phylogenetic-spatial.Rmd vignettes/which-scale.Rmd docs/design/21-tutorial-style.md docs/design/28-double-hierarchical-endpoint.md`:
  passed.
- `rg -n "format|air|styler|lintr|prettier" .github .pre-commit-config.yaml .lintr .Rbuildignore DESCRIPTION 2>/dev/null`:
  found no separate formatting GitHub Actions workflow; formatting is currently
  a local `air format` convention.
- `find .github/workflows -maxdepth 1 -type f -print -exec sed -n '1,80p' {} \; 2>/dev/null`:
  confirmed the repo currently has `R-CMD-check` and `pkgdown` workflows, not a
  dedicated format workflow.
- `air format vignettes/distribution-families.Rmd`: passed.
- `rg -n '```text' vignettes/distribution-families.Rmd`: returned no matches.
- `Rscript -e "rmarkdown::render('vignettes/distribution-families.Rmd', output_format = 'html_document', output_dir = tempfile(), quiet = TRUE)"`:
  passed.
- `Rscript -e "pkgdown::build_article('distribution-families', pkg = '.', lazy = FALSE, quiet = TRUE)"`:
  passed and wrote `pkgdown-site/articles/distribution-families.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed after the
  distribution-family cleanup.
- `air format vignettes/model-workflow.Rmd vignettes/robust-student.Rmd`:
  passed.
- `rg -n '```text' vignettes/model-workflow.Rmd vignettes/robust-student.Rmd`:
  returned no matches.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed after the
  post-fit and robust tutorial cleanup.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `air format vignettes/location-scale.Rmd`: passed.
- `rg -n '```text' vignettes/location-scale.Rmd vignettes/bivariate-coscale.Rmd`:
  found no `location-scale` matches and one intentional implementation
  cross-check block in `bivariate-coscale`.
- `rg -n '```text' vignettes/adding-families.Rmd vignettes/location-scale.Rmd vignettes/bivariate-coscale.Rmd`:
  found only the `adding-families` checklist blocks and one intentional
  implementation cross-check block in `bivariate-coscale`.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed after the
  longer-tutorial cleanup.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.
- Resume check after the crashed tutorial lane: `pkgdown::check_pkgdown()`
  passed with no problems found, and `git diff --check` passed.

## Consistency Audit

The main tutorial route map now points users by question: one-response
Gaussian scale, scale audit, response-family choice, bivariate residual
coupling, evidence synthesis, structured dependence, and post-fit workflow.
The tutorial-style design note now says biological case studies should split
from model-class tutorials only when they need their own data preparation,
figures, or multi-model narrative.

The distribution-family guide now uses the same teaching contract: a rendered
model statement, exact `drmTMB(...)` syntax, and prose saying what `sigma`,
`zi`, `hu`, `nu`, and `rho12` mean for the fitted family.

The post-fit workflow and robust Student-t tutorials now use the same
equation-plus-syntax pattern at their first model statement. The Student-t
tutorial still keeps the finite-variance `nu = 2 + exp(eta)` boundary visible
because it is part of the reader's interpretation of `check_drm()` output.

The longer location-scale tutorial now uses rendered equations for the
reader-facing Gaussian random-effect, double-hierarchical, and meta-analysis
model statements. The adding-families developer guide now uses rendered
equations for its model statements and likelihood equations, while retaining
checklist-like fenced text blocks where they function as implementation
inventories. The bivariate-coscale tutorial already had rendered equations for
its main teaching models; the remaining compact text block is intentionally
kept as an implementation cross-check.

## What Did Not Change

No package code changed in this pass. The family grammar, likelihood
parameterizations, and supported-versus-planned claims stayed within the
current tutorial scope. I rebuilt the full pkgdown site and ran
`pkgdown::check_pkgdown()`, but I did not run package tests because this slice
only changed tutorial prose and equations.

## What Did Not Go Smoothly

The first `pkgdown::build_article()` attempt used `preview = FALSE`, which this
installed pkgdown version does not accept. I reran the article build with the
local signature, `pkgdown::build_article('distribution-families', pkg = '.',
lazy = FALSE, quiet = TRUE)`, and that build passed.

Standalone `rmarkdown::render()` and targeted `pkgdown::build_article()`
attempts for `model-workflow` failed because the standalone environment loaded
an installed `drmTMB` without `predict_parameters()`. The full
`pkgdown::build_site(preview = FALSE)` path installs and renders from the
working tree, and that build passed after the tutorial edits.

## Team Learning

- Ada kept the change to navigation and equation consistency rather than a
  broad article reorganization.
- Pat and Darwin kept the route map organized by user question and biological
  task.
- Noether pushed model statements into LaTeX so equations, syntax, and prose
  line up.
- Rose kept the biological case-study split as a design rule rather than an
  immediate reshuffle.
- Grace checked local formatting, rendered the distribution-family article, and
  confirmed there is no separate formatting workflow in GitHub Actions.

## Known Limitations

- Some developer-note sections still use compact text-style equations,
  especially implementation cross-checks or checklist blocks in
  `testing-likelihoods` and `source-map`. `adding-families` retains checklist
  blocks, and `bivariate-coscale` retains one compact block that is explicitly
  labelled as an implementation cross-check.

## Next Actions

1. Continue normalizing developer-facing implementation notes where the text
   blocks are teaching equations rather than deliberate code-like cross-checks.
2. Add biological case-study pages only after the model-class tutorials are
   stable enough to support them.
3. Keep future model tutorials in the sequence: biological question, LaTeX
   model, R syntax, output, interpretation, diagnostics, and limitation.
