# After Task: Slice 78 Validation-Debt Register

## Goal

Back the Slice 77 stable-core matrix with an evidence ledger. Each advertised
surface should point to tests, diagnostics, interval status, docs, check-log
evidence, and explicit debt before the project expands it.

## Implemented

- Added `docs/design/34-validation-debt-register.md`.
- Defined register statuses: `covered`, `partial`, `opt-in`, and `blocked`.
- Added stable surface IDs, validation risk, and next gates for every Slice 77
  matrix row.
- Linked each advertised row to tests, diagnostics or interval routes, docs,
  check-log evidence, and remaining debt.
- Updated README, model-map, and source-map pointers to the register.
- Updated `ROADMAP.md` so Slice 78 is marked done.
- Updated `NEWS.md` with the new evidence/debt ledger.

## Mathematical Contract

The register is a traceability document, not a new model. It keeps direct
profile targets separate from derived covariance summaries, keeps residual
`rho12` separate from group-level, phylogenetic, and spatial correlations, and
keeps opt-in large-data controls separate from broad scalability claims.

## Files Changed

- `docs/design/34-validation-debt-register.md`
- `README.md`
- `vignettes/model-map.Rmd`
- `vignettes/source-map.Rmd`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/after-task/2026-05-15-slice-78-validation-debt-register.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format README.md vignettes/model-map.Rmd vignettes/source-map.Rmd ROADMAP.md NEWS.md docs/design/34-validation-debt-register.md`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/model-map.Rmd", output_file = tempfile(fileext = ".html"), quiet = FALSE); rmarkdown::render("vignettes/source-map.Rmd", output_file = tempfile(fileext = ".html"), quiet = FALSE)'`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `git diff --check`: passed.
- `rg -n '34-validation-debt-register|Validation-debt register|covered|partial|opt-in|blocked|D78-0|Slice 78' README.md vignettes/model-map.Rmd vignettes/source-map.Rmd ROADMAP.md NEWS.md docs/design/34-validation-debt-register.md`:
  confirmed source pointers and register rows.
- `rg -n '34-validation-debt-register|Validation-debt register|covered|partial|opt-in|blocked|D78-0|Slice 78|First slice' README.md vignettes/model-map.Rmd vignettes/source-map.Rmd ROADMAP.md NEWS.md docs/design/34-validation-debt-register.md pkgdown-site/index.html pkgdown-site/articles/model-map.html pkgdown-site/articles/source-map.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  confirmed rendered README, model-map, source-map, roadmap, and NEWS output.
- `rg -n 'Stable first slice|stable first slice|stable-versus-experimental|experimental feature matrix|spatial.*intercept-only.*implemented|q=4.*direct profile-ready|phylogenetic slopes.*fitted|spatial `corpair\\(\\)`.*fitted|random effects.*non-Gaussian.*implemented|profile intervals are supported' README.md ROADMAP.md NEWS.md vignettes/model-map.Rmd vignettes/source-map.Rmd docs/design/34-validation-debt-register.md`:
  found only valid guardrail wording in NEWS and model-map.

## Tests Of The Tests

No new likelihood or R method tests were added because Slice 78 is a traceability
slice. The validation test for this slice is that every stable-core matrix row
now has an evidence block and an explicit debt statement.

## Consistency Audit

- Ada: Slice 78 stayed scoped to evidence and debt rather than adding new
  behaviour.
- Noether: direct interval targets, derived q=4 summaries, residual `rho12`,
  ordinary latent correlations, phylogenetic correlations, and spatial fields
  remain separate.
- Grace: every covered or partial row names tests, diagnostics or interval
  routes, docs, and check-log evidence.
- Pat: the register answers "can I trust this for my analysis?" by naming the
  fitted boundary and next gate.
- Rose: stale scans found no new claim that spatial `corpair()`, phylogenetic
  slopes, non-Gaussian random effects, or broad profile support are fitted.

## What Did Not Go Smoothly

- The first register draft had good prose blocks but not enough stable IDs,
  validation risk labels, or check-log evidence. Maxwell pushed for a more
  auditable table, and the register now includes IDs, risk, and next gates.
- Mill flagged `Stable first slice` as confusing. The README and model-map now
  use `First slice` for random-effect scale models.

## Team Learning

- Ada: evidence registers should make the next gate visible, not merely list
  current files.
- Mill: applied readers need status words that do not blend stability with
  first-slice caution.
- Maxwell: maintainers need stable row IDs and a clear difference between
  direct, derived, `newdata`, and unavailable interval routes.
- Grace: check-log evidence belongs in the register because it is the durable
  handoff path across agents.
- Rose: status vocabulary should be scanned like code; vague terms such as
  "experimental" and blended terms such as "stable first slice" invite drift.

## Known Limitations

- Slice 78 does not add new tests or model behavior.
- Some check-log evidence is summarized by heading or source-map reference
  rather than exact line number because the check log is append-only and very
  large.
- GitHub Actions remains the PR-side gate after push.

## Next Actions

- Start Slice 79: failure-safe standard-error and `sdreport()` controls.
- Use the `D78-*` debt IDs when later slices close validation gaps.
