# After Task: Slice 5 Guarded q=3 Registry Scaffold

## Goal

Let the labelled covariance block registry describe a three-member grouped
block internally, while keeping parser, TMB export, and likelihood gates closed
for `q > 2` covariance blocks.

## Implemented

`append_covariance_registry_block()` now builds pair rows through
`covariance_registry_pair_rows()`, which enumerates all
`q * (q - 1) / 2` member pairs in stable order. Current fitted two-member
blocks still produce the same single pair row, and q=3 scaffold registries can
now carry three members and three pair rows while setting `implemented = FALSE`.

`labelled_covariance_block_tmb_data()` still rejects any block whose size is not
two. The new q=3 scaffold is therefore a registry design and test surface only;
it is not passed to C++, does not allocate new TMB parameters, and does not fit
a larger covariance likelihood.

## Mathematical Contract

The scaffold records the combinatorics of a future block:

```text
q = 3
number of reportable pairs = q * (q - 1) / 2 = 3
pairs = (1, 2), (1, 3), (2, 3)
```

It does not choose a covariance parameterization. The next likelihood slice
still needs one positive-definite `q > 2` representation, such as
`UNSTRUCTURED_CORR_t` plus scaled standard deviations or a Cholesky-equivalent
fallback.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-covariance-block-registry.R`
- `tests/testthat/test-biv-gaussian.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-5-guarded-q3-registry-scaffold.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-covariance-block-registry.R tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed with 24 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|gaussian-random-intercepts|covariance-block-registry")'`: passed with 837 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry|corpairs|check-drm|profile-targets|biv-gaussian|gaussian-random-intercepts")'`: passed with 1196 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Tests Of The Tests

The new internal registry test constructs a synthetic q=3 block with
`mu1`, `mu2`, and `sigma1` members. It checks one block, three members, three
pairs, zero-based contiguous member and pair ids, stable pair order, pair
classes, shared group and block labels, finite design values, and
`implemented = FALSE`.

A second test sends that q=3 registry to
`labelled_covariance_block_tmb_data()` and expects the internal q > 2 export
guard. The bivariate public guard test also confirms that a user-facing
three-member shared-label route errors before fitting.

## Consistency Audit

`ROADMAP.md`, `docs/design/30-labelled-covariance-block-assembler.md`, and
`docs/design/28-double-hierarchical-endpoint.md` now say that q=3 support is an
internal registry scaffold only. They still state that larger shared labels
need simulation recovery and a positive-definite q > 2 likelihood before
exposure.

I checked status wording with:

```sh
rg -n 'q > 2|three-member|larger shared labels|full shared block|positive-definite' ROADMAP.md docs/design docs/dev-log/after-task/2026-05-13-slice-5-guarded-q3-registry-scaffold.md
rg -n 'rho13|rho23|mvbind\\(y1, y2, y3\\)|implemented.*q > 2|implemented.*three-member' README.md ROADMAP.md docs vignettes R tests
```

The remaining hits are the intentional three-response `mvbind()` rejection
test, the design note saying q > 2 TMB export still aborts, and this report's
own scan command.

No roxygen, exported help topic, vignette example, NEWS bullet, or pkgdown
navigation changed because this is an internal scaffold with no new user-facing
model.

## What Did Not Go Smoothly

The original registry already stored `n_pairs = choose(n_members, 2)` but only
materialized pair rows for `n_members == 2`. That was easy to miss because all
fitted models are still q=2. The new pure helper makes this invariant testable
without touching the likelihood.

## Team Learning

For architectural covariance work, a useful slice can be internal and
non-fitting if it removes ambiguity from the next mathematical step. This one
turns "three-member block" into a concrete registry shape before Gauss has to
choose the positive-definite parameterization.

## Known Limitations

No q > 2 covariance likelihood is implemented. The registry scaffold cannot be
created through supported user syntax, cannot be exported to TMB, does not
appear in `corpairs()` or `profile_targets()` for fitted models, and does not
provide simulation recovery evidence.

## Next Actions

1. Prototype the positive-definite q > 2 parameterization in C++.
2. Add simulation recovery for the first three-member likelihood once the
   parameterization exists.
3. Keep larger bivariate random slopes and the full shared
   `mu1`/`mu2`/`sigma1`/`sigma2` label pattern closed until that recovery is
   persuasive.
