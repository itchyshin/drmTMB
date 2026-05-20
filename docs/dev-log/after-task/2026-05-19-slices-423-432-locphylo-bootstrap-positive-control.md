# After-Task Report: Slices 423-432 Locphylo Bootstrap Positive Control

## Active Perspectives

Ada coordinated the contrast run and documentation. Fisher compared the clean
and fallback bootstrap diagnostics. Curie checked that the same prototype
produces a useful positive control, not just a failure ledger. Grace verified
the 10-core cap and elapsed-time evidence. Pat and Rose checked that the
reader-facing conclusion stays simple: use the clean model for examples and
keep the fallback diagnostic.

## Goal

Run the same 10-core bootstrap diagnostic on the clean Ayumi Mass + Beak
`PV2_locphylo` model so the fallback failure has a positive-control comparison.

## Implemented

- Ran `tools/ayumi-parametric-bootstrap-prototype.R` on the existing clean
  `PV2_locphylo` fit from slices 391-402.
- Recorded the comparison in the Ayumi convergence ledger.
- Updated roadmap and simulation-readiness docs so the clean location-only
  phylogenetic model is explicitly the demonstration path.

## Evidence

The clean bootstrap run used `B = 10`, `multicore`, and `cores = 10`. It
completed in 117.7 seconds. All ten refits returned convergence code 0 with
`relative convergence (4)`. Median max gradient was 0.043 and max gradient was
0.121.

By contrast, the block-diagonal fallback bootstrap had convergence code 1 in
all ten refits, median max gradient 37.45, max gradient 75.30, and scale-scale
phylogenetic correlation near `-1`.

## Checks Run

```sh
OMP_NUM_THREADS=1 DRMTMB_BOOT_MODEL=PV2_locphylo DRMTMB_BOOT_FIT_RDS=docs/dev-log/ayumi-convergence/slices-391-402/mass-beak-pv2-rerun/fits.rds DRMTMB_BOOT_OUT=docs/dev-log/ayumi-convergence/slices-423-432/mass-beak-locphylo-bootstrap-diagnostics DRMTMB_BOOT_R=10 DRMTMB_BOOT_CORES=10 DRMTMB_BOOT_BACKEND=multicore DRMTMB_BOOT_ITER_MAX=1000 DRMTMB_BOOT_EVAL_MAX=1000 Rscript tools/ayumi-parametric-bootstrap-prototype.R
```

## Tests Of The Tests

This is a positive-control check for the bootstrap prototype. It used the same
data preparation, simulation, worker cap, and summary extraction as the
fallback run. The clean model returned convergence 0 and small gradients,
showing that the prototype can distinguish a defensible refit pattern from the
fallback's boundary pattern.

## Known Limitations

`B = 10` is still a smoke diagnostic, not a final interval report. A serious
uncertainty run should increase `B`, keep the 10-core cap, and summarize
replicate-level convergence and gradients before reporting intervals.

## Next Actions

1. Use `PV2_locphylo` for the Ayumi Mass + Beak example.
2. Keep q4 fallback models in the diagnostic ledger.
3. If a public bootstrap interface is added later, include this contrast as the
   prototype for required diagnostics.
