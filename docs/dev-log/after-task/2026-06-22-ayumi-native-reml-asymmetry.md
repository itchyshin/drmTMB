# After-Task: Ayumi Native REML Asymmetry A031-A040

## Goal

Bank the native REML wave of the Ayumi phylogenetic balance ledger without
overstating support. The aim was to distinguish exact-Gaussian mean-side native
REML from unsupported scale-side, matched `mu`/`sigma`, q2, and q4 native REML
cells.

## Changes

- Marked A031-A040 as banked in
  `docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`.
- Added `docs/design/199-native-reml-phylo-asymmetry-gap.md` with the current
  boundary, derivation gap, no-code estimator contract, and deferred decision
  for balanced native REML.
- Updated `docs/design/01-formula-grammar.md` so the structured-effect grammar
  says the fitted matching `mu`/`sigma` syntax is native ML, while native
  `REML = TRUE` is exact-Gaussian and mean-side-only for phylogenetic
  structured effects.
- Updated `docs/dev-log/known-limitations.md` so users see the same ML versus
  REML distinction before trying a scale-side or q4 phylogenetic REML model.

## Checks Run

```sh
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "reml-phylo-location", reporter = "summary")'
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "reml-bivariate", reporter = "summary")'
rg -n "balanced native REML|native balanced REML|balanced.*REML|scale-side.*REML|q4 AI-REML|AI-REML solves|10k sigma-phylo interval|10,440-tip sigma-phylo interval|native.*q4.*REML|non-Gaussian REML|engine_control" README.md ROADMAP.md NEWS.md docs vignettes R tests
git diff -U0 -- docs/design/199-native-reml-phylo-asymmetry-gap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv | rg -n "balanced native REML|native balanced REML|balanced.*REML|scale-side.*REML|q4 AI-REML|AI-REML solves|10k sigma-phylo interval|10,440-tip sigma-phylo interval|native.*q4.*REML|non-Gaussian REML|engine_control" || true
```

Result: the focused REML tests passed. The broad wording scan is noisy because
the repository keeps historical guard commands in check logs and after-task
reports. The diff-only scan found only new negative guard wording: scale-side,
matched `mu`/`sigma`, q2, and q4 phylogenetic REML requests reject early and
are not balanced native REML support.

## Boundary

A031-A040 do not implement a new estimator, do not promote scale-side or
matched native REML, do not promote q2/q4 native REML, do not change the
R-to-Julia bridge, do not claim interval coverage, and do not draft or post an
Ayumi reply.

## Next

Proceed to the Julia bridge wave A041-A050. Keep direct DRM.jl evidence,
native R/TMB evidence, and R-via-Julia bridge evidence separated row by row.
