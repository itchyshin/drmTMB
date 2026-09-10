# Plan versus actual — phylogenetic-temporal OU G10 timing and diagnostics pilot

## Planned

Run five deterministic seeds in each P1--P4 design, recording complete model-start and profile denominators, timing, memory, diagnostics, and profile availability. Use the result only to size the later calibration proposal.

## Actual

The successful checkpointed v2 run retained 20/20 datasets and selected fits, 40/40 configured starts, 60/60 fixed-mean profiles, and 20/20 diagnostic rows. Every fit converged with a positive-definite Hessian; every profile was finite and available. Fit work took 24.826 seconds and profile work 310.254 seconds; peak R allocation was 371.1 MB.

## Evidence

- `docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g10-pilot-v2/`
- `Rscript --vanilla tools/phylo-temporal-ou-gates.R G10`
- `docs/dev-log/after-task/2026-09-10-phylo-temporal-ou-g10-pilot.md`

## Variance

The measured 335.080 seconds was below the 10--15 minute estimate. A v1 preflight stopped after an optimizer-diagnostics bookkeeping defect, and an uncheckpointed v1 full invocation retained only its manifest before it was stopped as redundant. Both partial directories are preserved. The successful v2 source adds per-dataset checkpointing; it does not alter the model, seeds, P1--P4 design, or inference boundary.
