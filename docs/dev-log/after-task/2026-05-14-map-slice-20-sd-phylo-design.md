# After Task: Map Slice 20 sd_phylo Direct-SD Design

## Goal

Define the univariate Family B `sd_phylo(species) ~ x_species` contract before
implementation, keeping it separate from the fitted Family A q=4
location-scale covariance block.

## Implemented

This slice is design-only. It does not fit `sd_phylo()` yet. The repository now
states that `sd_phylo(species) ~ x_species` will model the SD of the
phylogenetic location random effect at observed species tips through a
non-centred tree parameterization.

## Mathematical Contract

The planned model uses a unit phylogenetic base effect:

```text
v_aug ~ MVN(0, A_aug)
tau_l = exp(W_l alpha_phylo)
a_l = tau_l v_tip,l
Cov(a_tip) = D_tip A_tip D_tip
```

The predictor matrix `W_l` has one row per observed tree tip and must be
constant within species after complete-case filtering. Internal nodes remain
part of the sparse augmented tree effect, but they do not receive user-facing
SD predictors. When this formula is present, it replaces the scalar
`log_sd_phylo` target for the univariate location `phylo()` effect; it is not a
second variance layer.

## Files Changed

- `docs/design/18-random-effect-scale-models.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/dev-log/known-limitations.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-14-map-slice-20-sd-phylo-design.md`

## Checks Run

- `air format docs/design/18-random-effect-scale-models.md docs/design/16-phylo-spatial-common-math.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/dev-log/known-limitations.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-14-map-slice-20-sd-phylo-design.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "package-skeleton|biv-gaussian|phylo-gaussian", reporter = "summary")'`:
  passed.
- `rg -n 'tip/internal-node contract is explicit and tested|tip/internal-node covariance contract is explicit and tested|tip/internal-node scaling rule and simulation evidence|contract is still missing|sd_phylo\(species\).*Implemented' README.md ROADMAP.md NEWS.md docs vignettes pkgdown-site/articles/phylogenetic-spatial.html`:
  no hits.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `git diff --check`: passed.

## Tests Of The Tests

No likelihood or parser behavior changed in this slice. Slice 21 should add a
pre-implementation failure or equivalence check for `sd_phylo(species) ~ 1`
against the current scalar-SD phylogenetic location likelihood before adding
predictor recovery tests.

## Consistency Audit

The wording now says the design contract exists but fitted support does not.
That distinction appears in formula grammar, likelihood notes, the
phylogenetic math document, random-effect scale design, the roadmap, NEWS, and
known limitations.

## What Did Not Go Smoothly

The main risk was the internal-node question. The chosen contract avoids
inventing ancestral covariates by scaling only observed tip contributions while
leaving the augmented tree precision as the unit base process.

## Team Learning

- Ada: keep design-only slices honest by changing status language without
  claiming implementation.
- Boole: syntax names can be planned while still rejected by the parser; the
  docs must say why.
- Gauss: the non-centred parameterization is the simplest route to
  `D_tip A_tip D_tip` without parameter-dependent sparse precision algebra.
- Noether: internal nodes are computational coordinates here, not biological
  units with their own SD predictors.
- Fisher: the intercept-only `sd_phylo() ~ 1` equivalence test is the first
  inferential guard for Slice 21.
- Darwin and Pat: examples should describe species-level predictors at tips,
  not vague ancestral habitat predictors.
- Grace: Slice 21 needs focused tests before any pkgdown claim.
- Rose: watch stale language that says the tip/internal-node contract is still
  missing.

## Known Limitations

`sd_phylo()`, `sd_phylo1()`, and `sd_phylo2()` still do not fit. Spatial
direct-SD syntax remains planned and will need its own field-level contract.

## Next Actions

1. Commit and push Slice 20.
2. Move to Slice 21 implementation of univariate
   `sd_phylo(species) ~ x_species`.
