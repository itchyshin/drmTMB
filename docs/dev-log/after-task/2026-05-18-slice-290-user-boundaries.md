# After Task: Slice 290 User-Facing Status Boundaries

## Goal

Make the public documentation use one concrete vocabulary for fitted, narrow,
opt-in, planned, and unsupported model surfaces.

## Implemented

The README, model-map article, package-level help topic, getting-started
article, source-map guidance, pkgdown reference sections, and large-fit control
documentation now share the same status words: stable, first slice, opt-in
control, planned or reserved, and unsupported or blocked. The wording tells a
reader when a surface is a routine fitted path, when it is fitted only inside a
narrow boundary, when it is a scalability or memory control, and when syntax is
roadmap-only or should not be used for analysis.

## Mathematical Contract

No likelihood, formula grammar, optimizer, extractor, simulation path, or
parameter transformation changed. This slice only clarifies documentation
status language for already fitted, planned, or unsupported surfaces.

## Files Changed

- `README.md`
- `R/control.R`
- `R/drmTMB-package.R`
- `_pkgdown.yml`
- `man/drmTMB-package.Rd`
- `man/drm_control.Rd`
- `vignettes/convergence.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/source-map.Rmd`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-222052-codex-checkpoint.md`

## Checks Run

```sh
air format README.md vignettes/model-map.Rmd vignettes/drmTMB.Rmd vignettes/source-map.Rmd R/drmTMB-package.R _pkgdown.yml NEWS.md ROADMAP.md
Rscript -e "devtools::document()"
Rscript -e "rmarkdown::render('vignettes/model-map.Rmd', quiet = TRUE)"
Rscript -e "rmarkdown::render('vignettes/drmTMB.Rmd', quiet = TRUE)"
Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', quiet = TRUE)"
rg -n 'Status word|status vocabulary|first-slice|first slice|Opt-in control|planned or reserved|unsupported or blocked|implemented first slice|implemented first slices|implemented \| "|experimental' README.md vignettes/model-map.Rmd vignettes/drmTMB.Rmd vignettes/source-map.Rmd R/drmTMB-package.R man/drmTMB-package.Rd _pkgdown.yml NEWS.md ROADMAP.md
git diff --check
air format R/control.R
Rscript -e "devtools::document()"
air format vignettes/convergence.Rmd
rg -n "implemented first slice|implemented first slices|experimental opt-in|experimental fits|experimental" README.md vignettes/*.Rmd R/*.R man/*.Rd _pkgdown.yml
Rscript -e "rmarkdown::render('vignettes/convergence.Rmd', quiet = TRUE)"
Rscript -e "pkgdown::check_pkgdown()"
Rscript tools/codex-checkpoint.R --goal "Slice 290 user-facing boundaries" --next "stage, commit, push, and open draft PR"
```

All checks passed. The final stale-wording scan intentionally returned no
matches.

## Tests Of The Tests

No model code or test files changed. The useful failure check for this
documentation slice is the stale-wording scan: it would fail the closeout if
reader-facing docs still used `implemented first slice`, `implemented first
slices`, `experimental opt-in`, `experimental fits`, or loose `experimental`
status language.

## Consistency Audit

The roadmap now marks Slice 290 done locally. NEWS records the public-docs
vocabulary update. The package help topic gives the compact definition, while
README and the model-map article put the terms beside the stable-core matrix.
The source-map article maps the reader-facing words back to the internal
validation-debt register, and pkgdown reference descriptions now signal that
some syntax is fitted while some remains planned.

## What Did Not Go Smoothly

The first pass left `experimental opt-in` in `drm_control()` and loose
`experimental fits` wording in the convergence article. The stale-wording scan
caught both, and the final docs use `opt-in control` consistently.

## Team Learning

Ada kept this as a wording and navigation slice, not a capability change. Pat
checked that a new user sees what can be fitted and what to avoid. Darwin
checked that applied readers get actionable boundaries rather than roadmap
shorthand. Fisher checked that no phrase implies validation beyond the current
evidence ledger. Grace confirmed roxygen, vignette rendering, pkgdown, and
whitespace checks. Rose checked for stale status terms. No spawned subagents
were used.

## Known Limitations

This slice does not add simulations, examples, tests, likelihoods, formula
grammar, or new fitted models. It also does not build the full pkgdown site;
`pkgdown::check_pkgdown()` and the touched article renders were the practical
docs checks for this narrow pass.

## Next Actions

Continue to Slice 291, the pre-simulation evidence-ledger gate, so Rose and
Fisher can check whether every advertised fitted feature has implementation,
tests, examples or docs, limitations, and simulation status before Phase 18
simulation design starts.
