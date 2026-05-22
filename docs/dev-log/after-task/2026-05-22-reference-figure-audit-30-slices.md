# After Task: Reference And Figure Audit 30-Slice Closeout

Date: 2026-05-22

## Task Goal

Finish the next function-reference and figure-gallery audit slices by improving
runnable examples, extractor discoverability, fast interval guidance, stale
structured-effect wording, and the two status-boundary figures that were still
on Florence's watchlist.

This was a documentation, reference, audit, and rendered-figure pass. It did
not change likelihoods, the TMB ABI, formula parsing, or fitted-model
behaviour.

## Team Roles

- Ada coordinated the slice and kept the scope to reference/documentation and
  figure QA.
- Boole checked formula examples and public marker wording.
- Emmy checked S3 extractor documentation and grouped reference coverage.
- Fisher checked interval and Hessian-diagnostic wording.
- Florence checked rendered figure readability and rejected clipped status
  labels.
- Pat checked that examples start from user-recognizable workflows.
- Grace ran roxygen, examples, full tests, pkgdown, and `R CMD check`.
- Rose updated audit ledgers and stale-wording checks.

No spawned subagents were running; these are standing review perspectives.

## Files Created Or Changed

- `R/check.R`
- `R/drmTMB.R`
- `R/formula-markers.R`
- `R/methods.R`
- `R/profile.R`
- `man/check_drm.Rd`
- `man/confint.drmTMB.Rd`
- `man/drmTMB.Rd`
- `man/fitted.drmTMB.Rd`
- `man/fixef.Rd`
- `man/model-fit-extractors.Rd`
- `man/profile_targets.Rd`
- `man/ranef.Rd`
- `man/rho12.Rd`
- `man/spatial.Rd`
- `man/weights.drmTMB.Rd`
- `vignettes/figure-gallery.Rmd`
- `vignettes/formula-grammar.Rmd`
- `tools/reference-audit.R`
- `docs/dev-log/audits/2026-05-21-function-reference-inventory.md`
- `docs/dev-log/figure-audits/2026-05-21-audit-kickoff/figure-audit.md`
- `docs/dev-log/figure-audits/2026-05-21-correlation-gallery-q2-refresh/figure-audit.md`
- `docs/dev-log/figure-audits/2026-05-22-status-matrix-reference-pass/figure-audit.md`
- `docs/dev-log/figure-audits/2026-05-22-status-matrix-reference-pass/emmeans-boundary-strip-1.png`
- `docs/dev-log/figure-audits/2026-05-22-status-matrix-reference-pass/correlation-layer-boundaries-1.png`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format R/check.R R/drmTMB.R R/formula-markers.R R/methods.R R/profile.R vignettes/figure-gallery.Rmd vignettes/formula-grammar.Rmd docs/dev-log/audits/2026-05-21-function-reference-inventory.md docs/dev-log/figure-audits/2026-05-21-audit-kickoff/figure-audit.md docs/dev-log/figure-audits/2026-05-21-correlation-gallery-q2-refresh/figure-audit.md docs/dev-log/figure-audits/2026-05-22-status-matrix-reference-pass/figure-audit.md tools/reference-audit.R
Rscript -e "devtools::document()"
Rscript tools/reference-audit.R
Rscript -e "pkgdown::build_reference()"
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('figure-gallery', new_process = FALSE, quiet = TRUE)"
rg -n 'Tile plot showing|bivariate spatial blocks remain planned|Fisher.s `z`|fitted q2 rows; spatial now also has a constant q4 block|fitted q2 row' R man vignettes docs/dev-log/figure-audits docs/dev-log/audits -S
git diff --check
Rscript -e "devtools::test(reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
Rscript -e "devtools::check()"
gh issue list --search "reference audit OR figure gallery OR visualization layer OR confidence intervals OR profile_targets" --limit 20
```

Outcomes:

- `Rscript tools/reference-audit.R` reported runnable examples for all topics
  except `drmTMB-package` and deprecated `gr()`.
- `git diff --check` passed.
- `devtools::test(reporter = "summary")` passed.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site()` completed.
- `devtools::check()` completed with 0 errors, 0 warnings, and 1 NOTE:
  `checking for future file timestamps ... unable to verify current time`.

## Consistency Audit

The stale-wording scan checked for old figure labels, old spatial q=2/q=4
wording, and Fisher-z phrasing that implied an unguarded transformation:

```sh
rg -n 'Tile plot showing|bivariate spatial blocks remain planned|Fisher.s `z`|fitted q2 rows; spatial now also has a constant q4 block|fitted q2 row' R man vignettes docs/dev-log/figure-audits docs/dev-log/audits -S
```

The final scan returned no hits.

The rendered figure audit records PNG evidence for:

- `docs/dev-log/figure-audits/2026-05-22-status-matrix-reference-pass/emmeans-boundary-strip-1.png`
- `docs/dev-log/figure-audits/2026-05-22-status-matrix-reference-pass/correlation-layer-boundaries-1.png`

## Tests Of The Tests

The new `tools/reference-audit.R` script parses generated Rd files and reports
whether each topic has runnable examples. It is intentionally simple and
repeatable: it catches missing example blocks after `devtools::document()`,
but it does not execute every example by itself. Execution coverage came from
manual example smoke checks, full `devtools::test()`, `pkgdown::build_site()`,
and `devtools::check()` examples.

The `ranef()` example was adjusted after the first smoke test produced nearly
uninformative conditional modes. The final example uses a small but visible
grouped random-intercept signal so the extractor output is meaningful.

## What Did Not Go Smoothly

The first figure repair still clipped status labels in the correlation-layer
matrix. Florence's visual gate caught it from the rendered PNG, and the figure
was redesigned from an in-cell tile label to a marker-plus-side-label display.

The accessibility text also initially still described the redesigned panels as
tile plots. The final stale-wording scan caught that and the alt text was
updated before the full site build.

## Design And Documentation Updates

- `vcov.drmTMB` is now documented in `model-fit-extractors`.
- `drmTMB()`, `fixef()`, `ranef()`, `weights()`, `rho12()`, `fitted()`, and
  `vcov()` have more useful runnable examples.
- `confint()` and `profile_targets()` now make the fast interval path more
  visible: use default Wald intervals for routine fixed-effect work, then
  filter direct targets and start long profiles with
  `profile_precision = "fast"` when needed.
- `check_drm()` now frames Hessian and `sdreport()` warnings as inference or
  identifiability warnings, not automatic proof that point estimates are
  unusable.
- `spatial()` and the formula grammar now describe fitted q=2 and first-slice
  q=4 structured routes more accurately.
- The figure-gallery status-boundary panels now use lighter row displays with
  visible labels outside the markers.

## pkgdown Updates

`pkgdown::build_reference()` refreshed reference pages after roxygen changes.
`pkgdown::build_article("figure-gallery", new_process = FALSE)` refreshed the
two audited figures for direct PNG inspection. `pkgdown::build_site()` then
rebuilt the full site successfully.

## GitHub Issue Maintenance

The issue search found broader open ledgers:

- #58 visualization layer for fitted models and simulation outputs
- #255 replicate-level simulation artifacts for uncertainty displays
- #31 tutorials and user-facing learning path
- #147 animal and `relmat()` known-relatedness structured effects
- #265 public bootstrap intervals
- #128 random-effect slope capacity
- #33 remaining structured and bivariate random slopes
- #5 covariance blocks for individual-difference models
- #61 CRAN readiness and paper-preparation gate

No issue was closed because this pass improved documentation, reference pages,
and status figures without completing those broader feature ledgers.

## Team Learning

Rose's repeatable lesson is that figure fixes need rendered-image inspection,
not only source review. The next figure-heavy task should inspect PNG or HTML
outputs before calling a panel complete.

Florence and Fisher should treat the proposed "Confidence Eye" as a separate
visual-language design slice. The likely grammar is a pale confidence or
compatibility area, darker interval or outline strokes, and a white-filled
central estimate circle with a darker outline. The source of the interval must
be explicit so Wald, profile, bootstrap, simulation, and posterior-like displays
are not conflated.

## Known Limitations And Next Actions

- `confint(method = "bootstrap")` remains a public design/implementation task,
  not completed by this pass.
- The status-boundary figures are not estimate plots and do not provide
  interval evidence for richer q=4 or regression routes.
- The function-reference audit should continue across pages that have examples
  but still need stronger biological teaching examples.
- Figure refinement should continue under Florence's visual QA, with the
  Confidence Eye considered for estimate-and-interval figures rather than
  support-boundary matrices.
