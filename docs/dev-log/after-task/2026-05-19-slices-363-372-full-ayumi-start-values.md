# After-Task: Slices 363-372 Full Ayumi Starting-Value Read

Date: 2026-05-19

## Goal

Read starting-value guidance for the full Ayumi phylogenetic species-effect
convergence case, separate reduced-rank `rr()` advice from drmTMB's
two-response phylogenetic covariance needs, and run full-species evidence
rather than relying on the earlier 80-species stress subset.

## What Changed

- Added `tools/ayumi-full-species-convergence.R`, a reproducible local stress
  script for all 6,196 species.
- Added full-species artifacts under
  `docs/dev-log/ayumi-convergence/slices-363-372/full-species-live/`.
- Added the research and evidence note
  `docs/dev-log/ayumi-convergence/slices-363-372/2026-05-19-full-species-start-values.md`.

## Evidence

The script read 1,603,663 complete raw rows for 6,196 species and the
10,597-tip tree, then pruned the tree to 6,196 tips. The raw pruned tree was
not ultrametric. The forced tree was ultrametric, but `force.ultrametric()`
warned that this is a coercion method rather than a formal tree-smoothing
method.

Aggregate all-species models fitted quickly with `se = FALSE`:

- fixed/residual `rho12`: 0.21 seconds, optimizer convergence code 0;
- location-scale with modelled residual `rho12`: 1.04 seconds, code 0;
- q2 phylogenetic mean on forced tree: 26.30 seconds, code 0.

Row-capped all-species models used 29,489 rows and all 6,196 species. These
models ran but returned false convergence:

- ordinary species q2: 164.74 seconds, false convergence, residual `rho12`
  near 1, huge fixed-gradient diagnostic;
- q2 phylogenetic mean: 330.04 seconds, false convergence, residual `rho12`
  near 1, huge fixed-gradient diagnostic;
- q2 phylogeny plus ordinary species: 101.95 seconds, false convergence,
  residual `rho12` near 1, and diagnostics warning that phylogenetic and
  ordinary species covariance are not cleanly separated.

## Interpretation

Ada's conclusion is that the `rr()` start method in the glmmTMB/JSS article is
not the thing to port into drmTMB's phylogenetic species-effect lane. It is a
reduced-rank factor-loading initializer. The useful lesson is broader: staged
simpler fits, scale-aware variance-component starts, restarts from optima,
perturb-and-refit checks, and explicit multi-start provenance.

The full-species evidence says the aggregate q2 phylogenetic model is feasible
as an optimizer stress test, but row-level or row-capped phylogenetic
species-effect fits are not yet trustworthy with current starts. That is
exactly where a future `start_from` or `multi_start` contract should focus.

## Checks Run

```sh
Rscript tools/ayumi-full-species-convergence.R
```

Additional source and output checks:

```sh
git status --short --branch
sed -n '1,120p' docs/dev-log/ayumi-convergence/slices-363-372/full-species-live/fit-summary.csv
sed -n '1,160p' docs/dev-log/ayumi-convergence/slices-363-372/full-species-live/corpairs.csv
sed -n '1,220p' docs/dev-log/ayumi-convergence/slices-363-372/full-species-live/check-rows.csv
sed -n '1,80p' docs/dev-log/ayumi-convergence/slices-363-372/full-species-live/tree-preflight.csv
```

## Known Limitations

- These full-species runs used `se = FALSE`, so Hessian and Wald standard-error
  evidence remains unavailable.
- The row-capped data are all-species but not the full 1.6-million-row raw fit.
  They are a convergence stress compromise.
- No public `start`, `start_from`, `warm_start`, or `multi_start` path exists
  yet, so Ada did not claim starting values rescue the model.
- q4 phylogenetic location-scale remains in the hard-identifiability lane.

## Team Review

Ada separated reduced-rank starts from phylogenetic species-effect starts and
integrated the full-species script and artifacts. Gauss and Noether kept residual `rho12`,
ordinary species covariance, and phylogenetic covariance separate. Fisher read
the outputs as optimizer evidence, not biological inference. Grace kept the run
local and reproducible. Pat's reader-facing concern is that aggregate q2 and
row-level q2 look deceptively similar in formula but not in diagnostics. Rose
flags the repeated pattern: the package needs formal start provenance before
the examples can promise convergence recovery.

## Next Action

Design a narrow q2 Gaussian source-fit start prototype before revisiting the
full row-level phylogenetic species-effect model: fixed/residual source to q2 target, then
response-specific or ordinary species source to structured q2 target, with
every copied parameter recorded.
