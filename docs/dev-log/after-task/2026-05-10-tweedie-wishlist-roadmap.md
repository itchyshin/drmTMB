# After Task: Tweedie Wishlist Roadmap

## Goal

Capture Tweedie models as a future `drmTMB` wish-list item for real eco-evo
datasets with exact zeros and positive continuous values.

## Implemented

- Added `tweedie()` to the Phase 7 roadmap as a future non-negative
  semicontinuous family.
- Added `tweedie()` to the distribution roadmap for biomass, cover, CPUE-like
  indices, and abundance-index responses.
- Added a family-registry note that future Tweedie work must fix the public
  `sigma` scale before comparator tests are written.

## Mathematical Contract

No implemented family changed. The future design target is a Tweedie variance
contract of the form

```text
Var[y] = phi * mu^nu, 1 < nu < 2
```

but the design deliberately leaves one decision open: whether public `sigma`
should represent `phi`, `sqrt(phi)`, or another stable scale. That decision
must be made before implementation.

## Files Changed

- `ROADMAP.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/02-family-registry.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-tweedie-wishlist-roadmap.md`

## Checks Run

- Web source check: glmmTMB official family documentation currently lists
  `tweedie(link = "log")`, describes `V = phi * mu^power`, and restricts the
  power parameter to `1 < power < 2`.
- Web source check: glmmTMB `family_params()` documentation names Tweedie as a
  family with an additional family-specific parameter.
- `air format ROADMAP.md docs/design/06-distribution-roadmap.md docs/design/02-family-registry.md`:
  passed.
- `rg -n "tweedie|Tweedie|phi \\* mu\\^nu|1 < nu < 2|sigma.*phi" ROADMAP.md docs/design/06-distribution-roadmap.md docs/design/02-family-registry.md`:
  passed and found the roadmap, family-registry, and distribution-roadmap
  entries.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `rg -n "tweedie|Tweedie|semi-continuous|semicontinuous" ROADMAP.md docs/design/06-distribution-roadmap.md docs/design/02-family-registry.md pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`:
  passed and confirmed the generated roadmap page includes the Tweedie
  wishlist entry.
- `git diff --check`: passed.

## Tests Of The Tests

This is roadmap/design work only, so no model tests were added. The useful
check is whether the design keeps implementation decisions explicit rather than
pretending the `sigma` scale is already settled.

## Consistency Audit

The roadmap keeps Tweedie after the current Gamma, lognormal, count, and scale
contracts. That prevents a new family from bypassing the family-link helper,
simulation, comparator, and scale-reporting requirements.

## What Did Not Go Smoothly

The tempting wording is to say "`sigma` is Tweedie dispersion" immediately.
That would be premature. The note now records the decision point instead.

## Team Learning

Darwin's lens matters here: Tweedie is not abstract feature creep, it maps to
real ecological measurements. Noether and Fisher should own the scale
convention and comparator checks before any TMB likelihood work starts.

## Known Limitations

No Tweedie likelihood, simulation, extractor, or comparator test exists yet.

## Next Actions

- Decide the public `sigma` to Tweedie-dispersion mapping.
- Add a design note with density, simulation, starting values, and comparator
  equations before implementation.
