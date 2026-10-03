# Plan versus actual: phylogenetic-temporal OU dense oracle

## Planned

Create a dense covariance oracle that distinguishes the additive stable
phylogeny plus independent OU model from the separable field and validates
objective derivatives and reductions.

## Actual

The independent helper uses `ape::vcv()` and direct dense Gaussian algebra.
It validates the objective, score, two finite-difference Hessians, four
reductions, and six predeclared mutations. The TMB provider itself was not
changed.

## Difference and decision

The oracle was strengthened twice after its own failures: the tree is passed
explicitly and the tree-misalignment mutation cannot be repaired by dimnames.
These changes increase independence and do not widen the model scope.
