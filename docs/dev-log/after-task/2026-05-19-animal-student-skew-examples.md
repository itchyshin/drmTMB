# After Task: Animal, Student-t, and skew-normal examples

## Goal

Clarify three reader-facing example paths without changing model-fitting code:
planned animal-model syntax, fitted Student-t location-scale-shape regression,
and planned skew-normal residual asymmetry.

## Implemented

The documentation now separates fitted and planned status more explicitly.
`animal()` is shown as planned grammar only, paired with a runnable ordinary
Gaussian `(1 | individual)` sensitivity fallback. `student()` remains the
fitted robust continuous route, with `nu` described as tail shape. `skew_normal()`
is shown only as planned syntax, with guidance to use Gaussian and Student-t
sensitivity fits until the skew-normal likelihood, diagnostics, profile targets,
and recovery tests exist.

## Mathematical Contract

The touched docs define location as `mu`, scale as `sigma`, shape as
family-specific parameters such as Student-t `nu`, and coscale as residual
correlation such as bivariate `rho12`. Animal, phylogenetic, spatial, and
ordinary group-level correlations are kept separate from residual coscale.

## Files Changed

- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/dev-log/check-log.md`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/robust-student.Rmd`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd vignettes/robust-student.Rmd docs/design/02-family-registry.md docs/design/03-likelihoods.md`:
  passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/robust-student.Rmd", output_dir = tempfile("robust-student-render-"), quiet = FALSE)'`:
  passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/model-map.Rmd", output_dir = tempfile("model-map-render-"), quiet = FALSE)'`:
  passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/phylogenetic-spatial.Rmd", output_dir = tempfile("phylo-spatial-render-"), quiet = FALSE)'`:
  passed.
- `rg -n "skew_normal\\(\\)|skew-normal|animal\\(|student\\(|coscale|rho12|not fitted yet|planned only|fitted fallback" vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd vignettes/robust-student.Rmd docs/design/02-family-registry.md docs/design/03-likelihoods.md`:
  confirmed the intended fitted/planned wording in the touched docs.
- `git diff --check -- vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd vignettes/robust-student.Rmd docs/design/02-family-registry.md docs/design/03-likelihoods.md`:
  passed.
- `git diff -U0 -- vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd vignettes/robust-student.Rmd docs/design/02-family-registry.md docs/design/03-likelihoods.md | LC_ALL=C rg -n '^\\+.*[^\\x00-\\x7F]' || true`:
  returned no added non-ASCII text.

## Consistency Audit

The source scan covered the three requested surfaces and the terminology
guardrails: `animal()`, `student()`, `skew_normal()`, location, scale, shape,
coscale, and residual `rho12`. The touched docs now give readers a next step
when syntax is unsupported: ordinary grouped Gaussian sensitivity fits for
planned `animal()` models, and Gaussian plus fitted Student-t sensitivity fits
for planned skew-normal residual asymmetry.

## Tests Of The Tests

No tests were added because this task did not change package behavior. The
render checks exercise the new runnable ordinary-random-effect fallback in
`vignettes/phylogenetic-spatial.Rmd` and the existing fitted Student-t example
in `vignettes/robust-student.Rmd`.

## What Did Not Go Smoothly

The docs subtask ran while a separate interval-evidence slice was also active
on the same branch. This report covers only the animal, Student-t, and
skew-normal example edits; the simulation files are documented in the later
slices 333-342 after-task report.

## Team Learning And Process Improvements

Ada kept the scope to documentation/example files. Pat and Darwin pushed the
animal-model example toward a concrete biological question and an honest
fallback. Fisher kept planned syntax out of fitted claims. Grace kept the
validation to formatting, vignette renders, and source scans because no code or
tests changed. Rose checked that coscale wording and planned/fitted boundaries
are explicit in the touched docs.

## Design-Doc Updates

`docs/design/02-family-registry.md` and `docs/design/03-likelihoods.md` now
state that skew-normal examples are planned-only and that the fitted fallback is
Gaussian plus Student-t sensitivity, not a skewness analysis.

## Pkgdown And Documentation Updates

The touched vignettes rendered successfully from source. A full
`pkgdown::build_site()` was not run because this was a narrow docs-only slice
and the targeted render checks covered the changed pages.

## Known Limitations And Next Actions

This slice does not implement fitted `animal()` or `skew_normal()` support.
Those features still need likelihoods, extractors, diagnostics, profile targets,
simulation recovery, and reference documentation before examples can become
runnable analysis syntax.
