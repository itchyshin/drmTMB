# After Task: GAMLSS Parameter Names

## Purpose

Record Rigby and Stasinopoulos (2005) as the foundational naming source for
future location-scale-shape families.

## Source Checked

Local PDF:

```text
dis_reg_models/Royal Stata Society Series C - 2005 - Rigby - Generalized additive models for location scale and shape.pdf
```

The source describes GAMLSS as a framework where all parameters of the
conditional distribution can have additive predictors, and it uses `mu`,
`sigma`, `nu`, and `tau` for location, scale, and up to two shape parameters.

## Changes Created

- Added `Rigby2005GAMLSS` to `REFERENCES.bib`.
- Added `docs/design/14-gamlss-parameter-names.md`.
- Updated `docs/design/02-family-registry.md` with the canonical dpar naming
  policy.
- Updated `docs/design/06-distribution-roadmap.md` so skew-normal uses `nu`
  rather than `skew`, and skew-t uses `nu` and `tau`.
- Updated `docs/design/11-reference-programme.md` to treat Rigby and
  Stasinopoulos (2005) as the foundational distributional-regression source.

## Design Decision

Use canonical GAMLSS-style names:

- `mu`;
- `sigma`;
- `nu`;
- `tau`.

For skew-normal-like families, `nu` should usually be the skewness/shape
parameter. Human-readable aliases such as `skew` or `df` may be added later,
but they should map to canonical names internally.

## Checks Run

Commands run:

- `pdftotext` on the local Rigby and Stasinopoulos PDF for source checking.
- `rg` consistency searches for `skew_normal`, `skew_t`, `skew`, `nu`, `tau`,
  `Rigby`, and `GAMLSS`.
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`

Results:

- The local PDF check confirmed the GAMLSS framing and the `mu`, `sigma`,
  `nu`, `tau` parameter convention.
- The consistency search exposed stale generic `shape`/`skew` wording in the
  formula grammar and beta-family roadmap; these were corrected.
- `devtools::test()`: 148 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
