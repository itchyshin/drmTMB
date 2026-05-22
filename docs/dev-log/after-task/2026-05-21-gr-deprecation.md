# After Task: Deprecated Legacy gr() Marker

## Goal

Close the function-reference audit decision about `gr()` by deprecating it as
public syntax while keeping an exported compatibility placeholder.

## Implemented

- Added a base-R deprecation warning to direct `gr()` calls.
- Updated the `gr()` roxygen page to say that `relmat()` is the lower-level
  public known-relatedness route and that `animal()`, `phylo()`, and
  `spatial()` are the biological structured-effect routes.
- Renamed the pkgdown bucket from reserved marker internals to deprecated
  marker internals.
- Updated the formula grammar, speed note, common-math note, vision note,
  roadmap, NEWS, and function-reference audit so the project no longer leaves
  `gr()` as an undecided public marker.
- Added a direct warning test for `gr()` while preserving its no-op return
  value.

## Mathematical Contract

No model equation, likelihood, optimizer path, extractor, or TMB objective
changed. The structured-effect contract remains:

```text
eta_d = X_d beta_d + Z_d z
z ~ MVN(0, sigma_z^2 K)
```

The public source of `K` is still `animal()`, `phylo()`, `spatial()`, or the
lower-level `relmat()` route. `gr()` is only a deprecated compatibility marker.

## Files Changed

- `R/formula-markers.R`
- `tests/testthat/test-package-skeleton.R`
- `_pkgdown.yml`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/00-vision.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/audits/2026-05-21-function-reference-inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-gr-deprecation.md`
- `man/gr.Rd`

## Checks Run

```sh
air format R/formula-markers.R tests/testthat/test-package-skeleton.R _pkgdown.yml NEWS.md ROADMAP.md docs/design/00-vision.md docs/design/01-formula-grammar.md docs/design/09-phylogenetic-and-spatial-speed.md docs/design/16-phylo-spatial-common-math.md docs/dev-log/audits/2026-05-21-function-reference-inventory.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-gr-deprecation.md
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'package-skeleton|gaussian-location-scale|formula-grammar', reporter = 'summary')"
Rscript -e "pkgdown::build_reference()"
rg -n 'gr\(\)|deprecated|Deprecated marker internals|relmat\(\)' R/formula-markers.R man/gr.Rd _pkgdown.yml NEWS.md ROADMAP.md docs/design/00-vision.md docs/design/01-formula-grammar.md docs/design/09-phylogenetic-and-spatial-speed.md docs/design/16-phylo-spatial-common-math.md docs/dev-log/audits/2026-05-21-function-reference-inventory.md pkgdown-site/reference/gr.html pkgdown-site/reference/index.html -S
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
gh issue list --search "gr deprecated OR relmat gr OR reserved marker" --limit 20
```

## Tests Of The Tests

The focused package-skeleton test exercises direct evaluation of the marker and
checks that the warning is emitted without changing the placeholder return
value. The Gaussian/formula-focused tests guard the unsupported-formula
boundary where older `gr()` syntax can still appear in parser tests.

## Consistency Audit

The public route is now consistent across reference docs, pkgdown navigation,
the roadmap, and design notes: teach `relmat()` for known latent relatedness
matrices and keep `gr()` out of the main reader path.

## GitHub Issue Maintenance

Issue search found no matching open issue to close. This slice contributes to
the broader function-reference audit and public-surface cleanup.

## What Did Not Go Smoothly

The older design notes used three different states for `gr()`: reserved,
replacement candidate, and future decision. This slice converted that drift
into one explicit state.

## Known Limitations

`gr()` is still exported. Removal should be a separate compatibility decision
after release planning, not part of this deprecation slice.

## Next Actions

1. Continue the function/reference audit with `corpairs()` and
   `predict_parameters()` prose and examples.
2. Keep `relmat()` as the only public low-level known-relatedness teaching path.
