# After-Task: Ayumi Beak And Binomial Ledger

## Scope

This task turned three loose follow-ups into issue-led slices after #568 merged:
Ayumi's beak convergence failure, the Julia q4 ML size-ladder failure, and the
missing plain Bernoulli/binomial response-family route.

## Evidence

- `drmTMB#555` now records the beak and Julia ladder evidence:
  <https://github.com/itchyshin/drmTMB/issues/555#issuecomment-4713176684>
- `drmTMB#569` tracks the first Bernoulli/binomial response-family slice.
- `drmTMB#570` tracks native optimizer/start rescue for the 10,440-tip beak
  sigma-phylo model.
- `DRM.jl#293` tracks the Julia q4 ML `-Inf` point-fit ladder.
- Local beak artifact:
  `/tmp/drmtmb-ayumi-evidence/beak-pruned-size-ladder-20260615-164203/beak-pruned-size-ladder.csv`
- Local Julia ladder artifact:
  `/tmp/drmtmb-ayumi-evidence/julia-point-ladder-drm-main-20260615-164757`

## Findings

The beak full-data univariate sigma-phylo model is not merely missing a profile
interval. It returns a starting-like basin under both default and careful
native-TMB optimizer budgets. The reduced no-phylo full-data model converges,
so the next R-side work should be deterministic starts or rescue selection for
the scale-side phylogenetic route.

The Julia q4 ladder is split: REML point fits return through 1000 tips, while ML
returns `-Inf` and nonconvergence from 250 tips onward. That belongs to the
DRM.jl engine lane before any larger ML interval run.

The package has `beta_binomial()` for overdispersed counted successes and uses
`family = binomial()` inside missing-predictor models, but it does not yet fit
plain Bernoulli/binomial responses. The docs now state that boundary directly.

## Files Updated

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/02-family-registry.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Next Slices

1. Implement `drmTMB#570`: a small reproducible beak fixture plus deterministic
   start/rescue ladder.
2. Implement `DRM.jl#293`: direct Julia q4 ML objective diagnostics at 100,
   250, and 500 tips.
3. Implement `drmTMB#569`: fixed-effect logit Bernoulli/binomial first, then
   ordinary random effects after simulation and documentation gates.
