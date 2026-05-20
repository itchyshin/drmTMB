# After Task: Slices 391-402 Mass-Beak PV2 Rerun And Bootstrap Prototype

Date: 2026-05-19

Branch: `codex/slices-363-full-ayumi-starts`

## Roles

Ada corrected the target and integrated the rerun evidence. Fisher checked the
collinearity, bootstrap, and Hessian interpretation. Noether checked the
pre-registration equations against the fitted formulas. Grace checked runtime,
parallel worker controls, and reproducibility. Rose flagged the earlier
lightness artifacts as a separate stress fixture rather than the Ayumi Issue #1
Mass + Beak model.

## What Changed

Ada added a corrected Mass + Beak PV2 rerun script and a developer-only
conditional parametric bootstrap prototype:

- `tools/ayumi-mass-beak-pv2-rerun.R`
- `tools/ayumi-parametric-bootstrap-prototype.R`

The scripts explicitly separate `Mass_z` as the first response from
`Mass_cov_z` as the fixed Beak allometry covariate. This split is invisible on
the observed data but essential for bootstrap refits.

## Evidence

The locphylo anchor rerun on all 6,196 species converged cleanly:

- `PV2_locphylo`: convergence 0, `pdHess TRUE`, logLik -4226.204, AIC
  8504.407;
- residual `rho12`: -0.789;
- phylogenetic `mu1`-`mu2` correlation: -0.841.

The prereg fallback still fails before optimization because current
phylogenetic q4 parsing requires the same label across `mu1`, `mu2`,
`sigma1`, and `sigma2`.

The full q4 model with `se = FALSE` took about 20 minutes and still reported:

- convergence code 1;
- skipped Hessian because `se = FALSE`;
- fixed-gradient warning with largest component `log_sd_phylo[2] = 123.1`;
- residual `rho12`: -0.984;
- maximum absolute q4 phylogenetic correlation: 0.998.

The four-replicate bootstrap smoke used four local workers. All four locphylo
refits converged with code 0 when `Mass_cov_z` was held fixed:

- elapsed wall time: 113.8 seconds;
- residual `rho12` range: -0.822 to -0.767;
- phylogenetic `mu1`-`mu2` range: -0.889 to -0.881;
- Beak-on-Mass coefficient range: 2.083 to 2.116.

These four replicates check mechanics only. They are not a final uncertainty
estimate.

## Validation Commands

```sh
DRMTMB_PV2_RUN_Q4=false Rscript tools/ayumi-mass-beak-pv2-rerun.R
DRMTMB_PV2_MODELS=PV2_main_q4 DRMTMB_PV2_SE=false DRMTMB_PV2_RERUN_OUT=docs/dev-log/ayumi-convergence/slices-391-402/mass-beak-pv2-q4-main Rscript tools/ayumi-mass-beak-pv2-rerun.R
DRMTMB_BOOT_R=4 DRMTMB_BOOT_CORES=4 DRMTMB_BOOT_BACKEND=multicore DRMTMB_BOOT_OUT=docs/dev-log/ayumi-convergence/slices-391-402/mass-beak-bootstrap-4core Rscript tools/ayumi-parametric-bootstrap-prototype.R
```

## Decisions

- Use `PV2_locphylo` as the trustworthy real-data anchor for Mass + Beak.
- Treat q4 PV2-main as diagnostic/failure-ledger material until restart,
  fallback, or bootstrap evidence shows a stable selected optimum.
- Build the phylogenetic block-diagonal q2 fallback before interpreting q4
  scale-scale or location-scale phylogenetic correlations for this dataset.
- Treat parallel bootstrap and profile CI as one repeated-refit infrastructure
  problem: bounded worker counts, deterministic seed streams, convergence
  ledgers, and no silent replicate dropping.

## Remaining Risks

The bootstrap prototype is local and developer-only. It uses conditional
simulation from the fitted model and does not yet implement a public interval
object, seed-stream table, profile sharing, or CRAN-safe backend selection.

The q4 selected optimum remains scientifically suspect despite its lower
objective, because residual and phylogenetic correlations land near the
boundary and the gradient remains large.
