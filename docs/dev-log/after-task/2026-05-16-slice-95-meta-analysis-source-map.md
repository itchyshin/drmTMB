# After Task: Slice 95 Meta-Analysis Source-Map Polish

## Goal

Resume the example/tutorial lane after the `0.1.2` release gate by polishing
the meta-analysis tutorial with paper-grounded equations, exact syntax,
parameter definitions, biological interpretation, and unsupported-boundary
language.

## Implemented

- Kept meta-analysis as its own tutorial lane in `vignettes/meta-analysis.Rmd`.
- Added a source-grounding paragraph naming the local location-scale
  meta-analysis papers, Rodriguez et al. categorical-moderator paper, and the
  unifying weighted-regression note.
- Added a parameter dictionary for `yi`, `vi`, `V`, `mu`, `sigma`,
  `sd(study)`, and `weights = w`.
- Added a categorical heterogeneous-heterogeneity section with the matched
  equation, `drmTMB` interpretation, SD ratio, variance ratio, and biological
  restoration example.
- Expanded the future `meta_V()` note while keeping `meta_V()` explicitly
  unimplemented and separate from top-level likelihood weights.
- Updated `docs/design/08-meta-analysis.md`,
  `docs/design/37-worked-example-inventory.md`, `vignettes/source-map.Rmd`, and
  `ROADMAP.md` so source maps and roadmap status agree.

## Source Evidence Read

- `/Users/z3437171/Desktop/2604.00424v1.pdf`
- `/Users/z3437171/Desktop/Global Change Biology - 2025 - Nakagawa - Location‐Scale Meta‐Analysis and Meta‐Regression as a Tool to Capture Large‐Scale.pdf`
- `/Users/z3437171/Desktop/Brit J Math Statis - 2023 - Rodriguez - Heterogeneous heterogeneity by default Testing categorical moderators in.pdf`
- `/Users/z3437171/Dropbox/Github Local/unifying_model/R/unifying.html`

## Checks Run

- `air format ROADMAP.md docs/design/08-meta-analysis.md docs/design/37-worked-example-inventory.md vignettes/meta-analysis.Rmd vignettes/source-map.Rmd`:
  passed.
- `git diff --check`: passed.
- `Rscript -e 'pkgdown::build_site()'`: passed; rendered the edited
  `articles/meta-analysis.html`, `articles/source-map.html`, and `ROADMAP.html`.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."
- `Rscript -e 'devtools::test(filter = "meta")'`: passed with
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 57`.
- Source and rendered scans confirmed the categorical heterogeneity equations,
  future `meta_V()` boundary, and Slice 95 source anchors.
- `rg -n 'meta_V\\(' R tests || true`: returned no matches, confirming no
  implementation was added.
- PR #55 CI passed on macOS in 6m41s, Ubuntu in 7m38s, and Windows in 8m40s
  before merge.
- PR #55 was merged on 2026-05-16 as commit
  `78160d6c008426454ce7f608f76e9c55439e6650`.

## Standing Review Notes

- Ada: Slice 95 resumed examples only after Slice 94 was merged and local
  `main` was fast-forwarded.
- Noether: the tutorial now pairs each equation with the same public syntax:
  `meta_known_V(V = V)` for known covariance, `sigma ~ ...` for residual
  heterogeneity, and no `tau ~` grammar.
- Darwin: the restoration example now separates the biological claim about
  average biodiversity benefit from the claim about predictability across
  studies.
- Pat: the parameter dictionary gives first-time users a compact map before
  they read `summary(fit_meta)`.
- Rose: `meta_V()` remains future design only and is absent from `R/` and
  `tests/`.
- Grace: pkgdown and targeted meta tests pass on the edited branch.

## Known Limitations

No formula grammar, likelihood, TMB, extractor, or fitted-example API changed.
The future `meta_V()` umbrella and proportional sampling-variance route remain
not implemented and not CRAN-blocking.

## Next Actions

1. Move to Slice 96: a non-Gaussian count example source map, likely NB2 or
   zero-inflated NB2, using the local heteroscedasticity paper.
