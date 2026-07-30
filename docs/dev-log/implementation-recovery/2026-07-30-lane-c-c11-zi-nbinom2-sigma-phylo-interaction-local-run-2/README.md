# Lane C C11 local recovery receipt — BLOCK

## Exact target

`mc-0653`: ordinary ML zero-inflated NB2 with fixed `mu`, `zi ~ 1`, and
`sigma ~ phylo_interaction(1 | plant:pollinator, tree1 = plant_tree,
tree2 = pollinator_tree)`. The only new estimand is the natural-scale pair
field SD `tau = exp(log_sd_phylo)`.

## Provenance

The primary run used source `fc8ced12e20f8715321dfc004a056529338c0e33`, runner
MD5 `c9df94a755c1f4f1073dda70440e0a08`, and seeds 2026075301--2026075304.
Each DGP uses two fixed 8-tip ultrametric trees, an 8 x 8 pair grid, 18
observations per pair, centred within-pair `x`, `beta_mu = (1.40, 0.30)`,
log-sigma intercept `-0.20`, `tau = 0.60`, and structural-zero probability
`0.20`. The accepted draw and the minimum structural-zero/positive support are
retained in each raw row.

## Result

`structured-summary.tsv` passes all four structured attempts: convergence 0,
positive-definite Hessian, maximum gradient at most 0.01, no boundary flag,
mode correlation above 0.45, and every predeclared mean recovery threshold.

The required ZINB IID pair-random-intercept control is blocked in all four
attempts before optimization. Its exact formula, `sigma ~ (1 | pair), zi ~ 1`,
is still rejected as an unimplemented zero-inflated NB2 sigma ordinary-RE
route. Admitting that control would broaden C11 beyond its exact
phylo-interaction formula. Therefore the control gate is not waived and this
is a **BLOCK**, not point-fit evidence for `mc-0653`.

`run-1` remains retained as a provisional dirty-source diagnostic. Its seed
resampling could overlap across attempts and is not used in the decision;
`run-2` corrects that issue without changing the frozen target or thresholds.

## Claim boundary

The code route is admitted and unit/oracle-tested, but `mc-0653` remains
`not_implemented`. No interval, profile, bootstrap, coverage, inference, or
Mission Control/ledger claim follows from this receipt.
