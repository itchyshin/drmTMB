# C7 NB2 sigma phylo-interaction final local point-recovery receipt

This retained re-run is the C7 receipt tied to the current runner digest. It
fits exactly ordinary univariate `nbinom2()` with
`sigma ~ phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)`.
The full 8 x 8 phylogenetic pair grid has 18 observations per pair, four fixed
seeds, within-pair centred `x`, fixed-effect truths `(1.40, 0.30)`, fixed
log-sigma intercept `-0.20`, and latent interaction SD `0.60`.

`raw-attempts.tsv` retains all four structured-route fits. The independent
`iid-fit-control.tsv` fits a matching NB2 `sigma ~ (1 | pair)` model to an IID
pair-effect DGP; it passed its convergence, Hessian, boundary, and 40% SD
recovery gate. The structured route passed all four attempts under the stated
convergence, Hessian, boundary, fixed-effect, log-sigma-intercept, and SD gates.

This is point-fit recovery only. It supplies no profile calculation, interval,
coverage, calibration, or inference-ready result. The preceding sibling
directories retain the initial DGP-stage runner error and the first repaired
run; neither is overwritten.
