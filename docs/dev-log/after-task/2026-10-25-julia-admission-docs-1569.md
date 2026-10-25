# After Task: Julia engine admission wording (#1569)

Reader: an applied user deciding whether `engine = "julia"` can fit
`skew_normal()`, `cumulative_logit()`, `biv_student()`, `biv_lognormal()`,
or plain `binomial()`.

## Goal

Make one statement of what the Julia bridge admits, consistent across
`?drmTMB`, the README engines section, the Julia engine guide, and the
four family pages. Close #1569 only.

## Implemented

`R/drmTMB.R` `@param engine` still lists `skew_normal()`,
`cumulative_logit()`, `biv_student()`, and `biv_lognormal()` on the
fixed-effect route. The wrapping now matches `man/drmTMB.Rd`. README and
`vignettes/julia-engine.Rmd` name the same families. The four family
constructors say they are admitted through `engine = "julia"`.
`cumulative_logit()` notes that the Julia route refuses a `disc`
formula. Formula-grammar and known-limitations now say Julia admits
fixed-effect binomial only.

## Mathematical Contract

No likelihood, link, or parameterisation change. The registry in
`R/julia-family-registry.R` remains the admission source.

## Files Changed

- `R/drmTMB.R`, `man/drmTMB.Rd`
- `R/family.R`, `man/skew_normal.Rd`, `man/cumulative_logit.Rd`,
  `man/biv_student.Rd`, `man/biv_lognormal.Rd`
- `README.md`, `vignettes/julia-engine.Rmd`
- `docs/design/01-formula-grammar.md`, `docs/dev-log/known-limitations.md`
- `tests/testthat/test-julia-admission-docs.R`
- `NEWS.md`
- C17 receipt and ledger TSV

## Checks Run

- `devtools::test(filter = "julia-admission-docs")`: 20 expectations, 0
  failures.
- Sibling filters `julia-admission|julia-family|julia-fe-only|reader-journeys`:
  pass, with live Julia fits skipped (no DRM.jl in this environment).
- Full `devtools::test()` on this branch: 3 fail, 0 error. Two fails were
  the env-skip census after the new README skip; regenerating
  `inst/extdata/env-skip-census.tsv` (2 to 3 build-premise skips) and
  re-running `env-skip-census|julia-admission-docs` is green. The third
  fail is `test-reml-phylo-location.R:172` (`fit$opt$convergence` 1 vs
  0) on a matched phylo mean-and-scale REML fit. That path is unchanged
  by this docs PR.
- `tools/check-reader-contracts.R`: OK.
- `tools/run-source-tree-tests.R --check`: 48 files agree.
- `python3 tools/recertify-c17.py --label 1569-docs --tolerance 1e-10`:
  worst `|change|` 3.231e-11.
- `python3 tools/capability_ledger.py --check-c14-receipt-equivalence`: OK.
- `python3 tools/capability_ledger.py --check`: OK.
- `roxygen2::roxygenise(".", roclets = "rd")`: intended Rd pages kept;
  `DESCRIPTION` RoxygenNote bump and wrap-only drift in
  `man/predict.drmTMB.Rd` and `man/convergence_status.Rd` reverted so
  this PR does not rewrite the #1568 quantile wording.

## Tests Of The Tests

The admission-doc tests fail if any of the four registry names leave
`man/drmTMB.Rd`, `vignettes/julia-engine.Rmd`, or `README.md`, and they
still reject the old "unsupported" sentences from #1569. They do not
call `drmTMB(..., engine = "julia")`.

## Consistency Audit

Recorded searches:

```sh
rg "skew_normal\\(\\) or another family|binomial structured effects or Julia bridge|and \`engine = \"julia\"\` remain unsupported" --glob '*.{Rmd,md,Rd,R}'
rg "engine = \"julia\"" README.md vignettes/julia-engine.Rmd man/drmTMB.Rd docs/design/01-formula-grammar.md docs/dev-log/known-limitations.md
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md NEWS.md docs/design/01-formula-grammar.md docs/dev-log/known-limitations.md vignettes/julia-engine.Rmd
```

The first pattern now hits only the admission-doc test. Inventory files
checked: README current engines section, NEWS documentation bullet,
known-limitations binomial paragraph, formula-grammar binomial row. No
`_pkgdown.yml` change.

## GitHub Issue Maintenance

This PR closes #1569. #1475 and #1320 stay open (owner decisions; not
closed here). #1568 was checked so `man/predict.drmTMB.Rd` was not
rewritten. PRs #1426 and #1529 were not edited.

## What Did Not Go Smoothly

PR #1603 already added the four names to `@param engine` and fixed the
vignette table. This pass closes the leftover README and family-page
gaps and locks them in tests. Generating the family list from the
registry at document time is still not done. The environment had no R
until r2u packages were installed.

## Team Learning

When a hashed file changes only in a roxygen comment, recertify C17 and
leave `source_fingerprint` alone if the model-15 anchors did not move.
Revert unrelated `document()` wrap drift, especially around open
wording issues.

## Known Limitations

The family list is still hand-maintained. Live `engine = "julia"` fits
were not rerun. The cheatsheet PDF and `predict(type = "mean")` are
outside this PR.

## Next Actions

Review this PR. Do not merge from this session. Leave #1475 and #1320
to their owner decisions.
