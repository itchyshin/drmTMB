# After Task: Namespaced Formula Markers

## Goal

Fix issue #504, where namespace-qualified marker calls such as
`drmTMB::phylo(...)` inside `bf()` formulas produced a cryptic length-3
condition error instead of being parsed like `phylo(...)`.

## Implemented

The formula parser now resolves the effective function name of ordinary and
namespace-qualified calls before comparing marker names. Existing marker
families such as `phylo()`, `meta_V()`, random-effect scale helpers, and
`corpair()` continue to use the same grammar; the parser just treats
`drmTMB::marker(...)` as the same marker call.

## Mathematical Contract

No likelihood, parameterization, or fitted-model mathematical contract changed.
This is a parser robustness fix before model construction.

## Files Changed

- `R/drmTMB.R` adds `drm_call_name()` and uses it in `meta_V()` detection and
  recursive formula call searches.
- `R/parse-formula.R` uses the same helper for structured markers,
  `corpair()` left-hand sides, and random-effect scale left-hand sides.
- `tests/testthat/test-phylo-gaussian.R` adds a regression fit for the reported
  bivariate `drmTMB::phylo()` formula pattern.
- `NEWS.md`, `docs/design/01-formula-grammar.md`, and
  `docs/dev-log/check-log.md` record the user-facing parser behavior.

## Checks Run

```sh
/Library/Frameworks/R.framework/Resources/bin/Rscript - <<'EOF'
devtools::load_all(quiet = TRUE)
# Reproduces issue #504 with drmTMB::phylo(...) in both bivariate location formulas.
# The command prints issue_504_reproducer_ok after fitting and preserving phylo SD names.
EOF
/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::test(filter = "phylo-gaussian")'
/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::test(filter = "meta-known-v|package-skeleton")'
air format R/drmTMB.R R/parse-formula.R tests/testthat/test-phylo-gaussian.R
```

Results:

- The pinned issue #504 reproducer now fits and prints
  `issue_504_reproducer_ok` with `mu1:phylo(1 | p | species)` and
  `mu2:phylo(1 | p | species)` in `fit$sdpars$mu`.
- `devtools::test(filter = "phylo-gaussian")` passed with 213 expectations, no
  failures, warnings, or skips.
- `devtools::test(filter = "meta-known-v|package-skeleton")` passed with 175
  expectations, no failures, warnings, or skips.

## Tests Of The Tests

Before the fix, the pinned reproducer failed with
`'length = 3' in coercion to 'logical(1)'`. The new regression test exercises a
full bivariate Gaussian phylogenetic fit with namespaced markers and checks that
the fitted structured SD names and block metadata match the unqualified route.

## Consistency Audit

The formula grammar note now says exported formula markers may be written either
unqualified after `library(drmTMB)` or namespace-qualified as
`drmTMB::marker(...)`. This is a parser normalization rule, not a broader
promise that arbitrary namespaced functions are model terms.

## GitHub Issue Maintenance

Issue #504 should be closed by the implementation PR after CI passes. Issue
#505 was separately verified as already fixed on current `main`, commented with
local evidence, and closed as completed.

## What Did Not Go Smoothly

The first regression assertion guessed that the internal display `label` stored
only `"p"`. The fitted object stores the display label as
`"phylo(1 | p | species)"` and the block as `"p"`, so the test now checks the
actual `block` and `type` fields.

## Team Learning

Formula parsers should avoid direct `as.character(expr[[1L]])` comparisons for
call heads. Namespaced calls, parenthesized calls, and marker aliases should go
through one call-name helper before matching.

## Known Limitations

This does not add support for new markers, arbitrary namespaced functions, or
unsupported structured-effect forms. It only makes existing exported marker
calls robust when namespace-qualified.

## Next Actions

After this PR lands, close #504 with the reproducer and focused-test evidence.
