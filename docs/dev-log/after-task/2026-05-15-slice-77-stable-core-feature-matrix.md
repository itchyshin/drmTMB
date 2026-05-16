# After Task: Slice 77 Stable-Core Feature Matrix

## Goal

Make the advertised `drmTMB` surface readable before fitting: stable fitted
surfaces, first slices, opt-in controls, rejected syntax, planned neighbours,
and interval/diagnostic status should be visible from the README and model-map
article without reading source code.

## Implemented

- Added a stable-core matrix to `README.md`.
- Added the same status contract to `vignettes/model-map.Rmd`, where users look
  for "What can I fit today?" guidance.
- Updated `ROADMAP.md` so Slice 77 is closed and Phase 6d uses stable,
  first-slice, opt-in, and planned/rejected wording instead of vague
  experimental wording.
- Updated `NEWS.md` to announce the matrix and its scope.
- Rebuilt `pkgdown-site/` so `index.html`, `articles/model-map.html`,
  `ROADMAP.html`, and `news/index.html` reflect the new reader-facing status
  language.

## Mathematical Contract

The matrix is a status surface, not a new likelihood surface. It separates:

- stable fitted surfaces with tests and user-facing documentation;
- first slices that fit inside deliberately narrow boundaries;
- opt-in controls that harden large-data or memory paths without claiming
  general scalability;
- planned or rejected neighbours that should not be treated as analysis syntax.

Interval wording is target-specific. Direct fixed-effect, SD, correlation,
row-specific `sigma`/`rho12`, and fitted q=2 `corpair()` targets are separated
from derived q=4 covariance summaries, which still report unavailable derived
intervals.

## Files Changed

- `README.md`
- `vignettes/model-map.Rmd`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/after-task/2026-05-15-slice-77-stable-core-feature-matrix.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format README.md vignettes/model-map.Rmd ROADMAP.md NEWS.md`:
  passed.
- `git diff --check`: passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/model-map.Rmd", output_file = tempfile(fileext = ".html"), quiet = FALSE)'`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `rg -n 'Stable-core matrix|First slice fitted|First slices fitted|Opt-in controls|Reserved or planned neighbours|feature matrix|stable-core feature matrix|derived_interval_unavailable|Profile support is target-specific' pkgdown-site/index.html pkgdown-site/articles/model-map.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  confirmed rendered site output.
- `rg -n 'stable-core versus experimental|stable or experimental|experimental feature matrix|Fitted narrow slice|blanket.*profile|all.*profile|every.*profile|spatial.*corpair.*Stable|phylogenetic slopes.*Stable|mesh/SPDE.*Stable|random effects in `rho12`.*Stable|bivariate random slopes.*Stable|mixed composed.*Stable|sigma\\*' README.md ROADMAP.md NEWS.md vignettes/model-map.Rmd pkgdown-site/index.html pkgdown-site/articles/model-map.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  found no Slice 77 stale-status contradiction. It returned valid historical
  profile wording and valid ordinary covariance row text.

## Tests Of The Tests

No new model code or testthat tests were added. This was a prose and status
inventory slice, so validation used source formatting, vignette rendering,
pkgdown build/check, rendered-site confirmation, and stale-claim scans.

## Consistency Audit

Pat can now answer "Can I fit this today?" from the README or model map. Noether
confirmed that `rho12`, `sigma`, q=2 direct `corpair()` targets, and q=4
derived rows are not collapsed into one interval claim. Grace confirmed the
rendered pkgdown pages carry the matrix. Rose confirmed that the new Phase 6d
language distinguishes stable surfaces, first slices, opt-in controls, and
planned or rejected neighbours.

## What Did Not Go Smoothly

- Ada initially reported progress without the standing team names, even after
  the user had asked for that working style. The correction is to keep Ada,
  Pat, Noether, Grace, Rose, and other named reviewers explicit in status
  updates and closure notes.
- The first `Rscript` render command failed because the default shell `PATH`
  did not include `/usr/local/bin`. Grace reran the validation with the project
  PATH used by recent checks.
- The first stale scan caught the matrix's own "blanket interval" wording, so
  Pat and Rose revised it to the clearer "not every summary row has an
  interval route" / "automatic intervals" language.

## Team Learning

- Ada: keep Slice 77 bounded to status documentation and do not turn it into
  the Slice 78 validation-debt register.
- Pat: the status table should privilege reader decisions over implementation
  taxonomy.
- Darwin: biological users need spatial, phylogenetic, residual `rho12`, and
  group-level covariance layers separated because they answer different
  ecological questions.
- Noether: q=4 rows are point-summary and derived-interval surfaces; they
  should not inherit q=2 direct profile wording.
- Grace: rendered pkgdown confirmation matters because both README and
  model-map are user-facing entry points.
- Rose: "experimental" is too vague for this project; the clearer vocabulary is
  stable, first slice, opt-in control, and reserved/rejected or design-only.
- Mill: the matrix should be readable as "what can I fit today?"
- Maxwell: profile and diagnostic statuses need target-level vocabulary, not a
  single package-wide profile claim.

## Known Limitations

- Slice 77 does not add new model behavior.
- The matrix does not yet link every row to simulation recovery, malformed-input
  tests, diagnostics, documentation, and check-log evidence. That is Slice 78.
- GitHub Actions remains the PR-side gate after push.

## Next Actions

- Start Slice 78 with a validation-debt register keyed to the same matrix rows.
- Keep the AGHQ sparse-binary Bernoulli point as a `gllvmTMB` post-CRAN methods
  candidate, not a `drmTMB` Slice 77 scope item.
