# After Task: Phase 5b Slice 47 Gaussian Aggregation Design

## Goal

Define the first sufficient-statistic aggregation contract for repeated
Gaussian rows before changing R builders or TMB likelihood code.

## Implemented

- Added `docs/design/31-gaussian-aggregation-sufficient-statistics.md`.
- Updated `docs/design/23-large-data-memory.md` to distinguish sparse matrix
  pressure from repeated-row likelihood pressure.
- Updated `ROADMAP.md` so Phase 5b marks the aggregation contract as recorded
  while fitted aggregation remains planned.
- Updated `vignettes/large-data.Rmd` so readers know aggregation is planned,
  not implemented.
- Updated `docs/dev-log/known-limitations.md` with the first aggregation scope
  and rejected neighbouring paths.
- Rebuilt the local pkgdown site and confirmed the rendered roadmap and
  large-data article contain the intended wording.

## Mathematical Contract

For rows in a Gaussian aggregation cell `g`, the first target requires matching
`mu` and `sigma` design states after row filtering:

```text
y_i | mu_g, sigma_g ~ Normal(mu_g, sigma_g^2)
```

The full row contribution can then be rewritten as:

```text
-0.5 n_g log(2 pi)
- n_g log(sigma_g)
-0.5 (sum_y2_g - 2 mu_g sum_y_g + n_g mu_g^2) / sigma_g^2
```

with `n_g`, `sum_y_g`, and `sum_y2_g` replacing the individual `y_i` rows for
likelihood evaluation. The fitted model should not change.

## Files Changed

- `docs/design/31-gaussian-aggregation-sufficient-statistics.md`
- `docs/design/23-large-data-memory.md`
- `ROADMAP.md`
- `vignettes/large-data.Rmd`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- Formatted touched files with `air format`.
- Ran stale-wording scans for aggregation claims and candidate
  `aggregate_gaussian` wording.
- Ran `git diff --check`.
- Built the large-data article with `pkgdown::build_article("large-data",
  new_process = FALSE)`.
- Built the local pkgdown site with `pkgdown::build_site()`.
- Ran `pkgdown::check_pkgdown()` with no problems found.
- Confirmed rendered `pkgdown-site/ROADMAP.html` and
  `pkgdown-site/articles/large-data.html` contain the new Slice 47 wording.

## Tests Of The Tests

No R unit tests were added because this slice does not change package
behaviour. The next implementation slice must add likelihood-comparison tests
before any aggregation fit is claimed.

## Consistency Audit

The roadmap, design note, large-data article, and known limitations all say
the same thing: Gaussian aggregation is designed but not implemented. The first
planned path is opt-in, univariate Gaussian, and fixed-effect only.

## What Did Not Go Smoothly

The candidate control name `aggregate_gaussian` is useful because it is clear,
but it may be too narrow if later code wants a general `aggregation =` control.
Slice 48 should make that API decision before adding a user-facing argument.

## Team Learning

- Ada should keep Phase 5b split into separate scaling problems rather than
  bundling sparse matrices, aggregation, and phylogenetic precision together.
- Boole should decide the public control name before implementation.
- Gauss should implement the aggregated branch only after an independent fixed
  parameter likelihood comparator exists.
- Noether should keep the aggregation key tied to model matrices and offsets,
  not raw data-frame columns.
- Curie should require full-row versus aggregated parity tests for
  coefficients, `sigma`, `logLik()`, `AIC`, and post-fit methods.
- Fisher should reject benchmark claims until the aggregation branch has
  likelihood-equivalence evidence.
- Pat should keep the user-facing explanation focused on "same model, fewer
  likelihood cells."
- Grace should make pkgdown and stale-wording scans part of every design slice
  that changes public guidance.
- Rose should watch for accidental claims that `aggregate_gaussian` already
  exists.

## Known Limitations

- `aggregate_gaussian` is a reserved candidate name, not an implemented
  control.
- There is no aggregation-key builder, TMB aggregation branch, fitted-object
  expansion-map policy, or benchmark evidence yet.

## Next Actions

Slice 48 should implement the internal aggregation-key builder and an
independent likelihood-comparison helper, then decide the public control name
before exposing fitted aggregation.
