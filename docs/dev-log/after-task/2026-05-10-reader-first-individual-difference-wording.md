# After Task: Reader-First Individual-Difference Wording

## Goal

Remove internal shorthand from active user-facing docs so readers see the model
class first: individual-difference location-scale models, double-hierarchical
covariance, predictability, plasticity, and malleability.

## Implemented

Replaced internal author shorthand in `README.md`, `ROADMAP.md`, the `0.1.0`
release checklist, the random-effect scale design note, and recent 2026-05-10
after-task reports. Formal paper references remain where they act as citations
rather than unexplained labels.

## Mathematical Contract

The public grammar remains `sigma`. When a paper-facing interpretation needs
residual variance, predictability, or malleability, examples should report the
derived quantity `sigma^2` beside `sigma`.

## Files Changed

- `README.md`
- `ROADMAP.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md`
- recent 2026-05-10 after-task reports

## Checks Run

- shorthand scans over `README.md`, `ROADMAP.md`, `NEWS.md`, active design
  docs, release checklists, 2026-05-10 after-task reports, vignettes, and
  `_pkgdown.yml`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- rendered-site shorthand scan over `pkgdown-site` excluding `search.json`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

## Tests Of The Tests

The scans cover the active public docs, design notes, release checklist, and the
newest after-task reports. They deliberately allow formal author citations such
as `O'Dea et al.` where a citation is clearer than a project nickname.

## Consistency Audit

The revised wording aligns with the landing-page purpose: readers should learn
what the model does before seeing author names or project shorthand.

## What Did Not Go Smoothly

The previous wording was convenient for internal planning but too opaque for a
new reader. That is exactly the kind of terminology drift Pat should catch
before release.

## Team Learning

Pat and Rose should treat roadmap prose as user-facing. Good release prose names
the analysis and the quantity, not the project team's nickname for a source.

## Known Limitations

Historical check-log command strings may still contain older search patterns.
Those are preserved as records of previous audits, not current public wording.

## Next Actions

When adding the real-data replication scripts, use descriptive file titles and
headings such as "individual-difference location-scale examples" and cite the
paper in prose or bibliography metadata.
