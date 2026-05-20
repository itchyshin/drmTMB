# After-Task Report: Slices 413-422 Fallback Profile And Bootstrap Diagnostics

## Active Perspectives

Ada coordinated the profile, bootstrap, simplification, and documentation
updates. Fisher interpreted the failed profile and bootstrap gradients. Gauss
and Noether kept the distinction between direct targets and successful
intervals explicit. Curie checked the bootstrap diagnostics. Grace kept worker
use capped at 10 cores and pushed for per-replicate failure rows. Rose audited
stale and overstrong wording about profile readiness and bootstrap uncertainty.

## Goal

Decide whether the implemented Ayumi Mass + Beak block-diagonal phylogenetic
fallback can support profile or bootstrap uncertainty, and test whether a
simpler scale formula improves the boundary behavior.

## Implemented

- Added `tools/ayumi-profile-fallback-correlations.R`, a developer-only profile
  diagnostic wrapper that records selected `profile_targets()`, `corpairs()`,
  `check_drm()`, profile summaries, and profile conditions.
- Extended `tools/ayumi-parametric-bootstrap-prototype.R` to record
  per-replicate optimizer message, objective, maximum absolute gradient, and
  largest gradient component.
- Hardened the bootstrap worker so future unexpected worker errors become
  replicate-level rows rather than collapsing the whole multicore run.
- Added `PV2_phylo_fallback_sigma_intercept` to the local Ayumi rerun and
  bootstrap scripts as a developer-only simplification check.
- Updated current docs to say that `profile_ready` means a direct profile can
  be attempted, not that an interval is guaranteed.

## Evidence

The bounded full-species profile for the fallback `mu1`-`mu2` phylogenetic
correlation took 511.6 seconds and failed to extract a 95% interval. The target
is direct, but this fitted model is not profile-proven.

The 10-core bootstrap diagnostic rerun completed all ten refits. All ten
returned `false convergence (8)`, median maximum gradient was 37.45, and the
scale-scale phylogenetic correlation stayed at about `-0.99999`.

The intercept-only scale fallback fit in 538.0 seconds but still returned
convergence 1 and `pdHess = FALSE`. AIC worsened to 8610.5, residual `rho12`
collapsed to nearly zero, and the scale-scale phylogenetic correlation remained
near `-1`.

## Checks Run

```sh
air format tools/ayumi-profile-fallback-correlations.R
air format tools/ayumi-parametric-bootstrap-prototype.R tools/ayumi-mass-beak-pv2-rerun.R
Rscript -e "invisible(parse(file = 'tools/ayumi-parametric-bootstrap-prototype.R')); cat('bootstrap parse ok\n')"
Rscript -e "invisible(parse(file = 'tools/ayumi-profile-fallback-correlations.R')); invisible(parse(file = 'tools/ayumi-parametric-bootstrap-prototype.R')); invisible(parse(file = 'tools/ayumi-mass-beak-pv2-rerun.R')); invisible(parse(file = 'tools/ayumi-q2-start-prototype.R')); invisible(parse(file = 'tools/ayumi-full-species-convergence.R')); cat('tool parse ok\n')"
git diff --check
Rscript -e "devtools::test(filter = '^phylo-gaussian$')"
Rscript -e "devtools::test(filter = '^profile-targets$')"
Rscript -e "devtools::test(filter = '^phylo-utils$')"
OMP_NUM_THREADS=1 DRMTMB_PROFILE_TARGETS=phylo_mean DRMTMB_PROFILE_YSTEP=1 DRMTMB_PROFILE_YTOL=0.5 DRMTMB_PROFILE_MAXIT=2 DRMTMB_PROFILE_RANGE_LOWER=-1.6 DRMTMB_PROFILE_RANGE_UPPER=-0.4 DRMTMB_PROFILE_OUT=docs/dev-log/ayumi-convergence/slices-413-422/mass-beak-pv2-block-fallback-profile-bounded Rscript tools/ayumi-profile-fallback-correlations.R
OMP_NUM_THREADS=1 DRMTMB_BOOT_MODEL=PV2_phylo_fallback DRMTMB_BOOT_FIT_RDS=docs/dev-log/ayumi-convergence/slices-403-412/mass-beak-pv2-block-fallback/fits.rds DRMTMB_BOOT_OUT=docs/dev-log/ayumi-convergence/slices-413-422/mass-beak-pv2-block-fallback-bootstrap-diagnostics DRMTMB_BOOT_R=10 DRMTMB_BOOT_CORES=10 DRMTMB_BOOT_BACKEND=multicore DRMTMB_BOOT_ITER_MAX=1000 DRMTMB_BOOT_EVAL_MAX=1000 Rscript tools/ayumi-parametric-bootstrap-prototype.R
OMP_NUM_THREADS=1 DRMTMB_PV2_MODELS=PV2_phylo_fallback_sigma_intercept DRMTMB_PV2_RUN_Q4=false DRMTMB_PV2_SE=true DRMTMB_PV2_ITER_MAX=2000 DRMTMB_PV2_EVAL_MAX=2000 DRMTMB_PV2_RERUN_OUT=docs/dev-log/ayumi-convergence/slices-413-422/mass-beak-pv2-block-fallback-sigma-intercept Rscript tools/ayumi-mass-beak-pv2-rerun.R
```

The focused tests passed with 178 `phylo-gaussian` assertions, 480
`profile-targets` assertions, and 79 `phylo-utils` assertions.

## Tests Of The Tests

The profile wrapper captured a real failure instead of silently returning empty
bounds. The bootstrap wrapper now exposes the same false-convergence status
that was previously easy to miss from the point summaries alone. The
simplification test was a negative control: if the boundary were mainly caused
by the scale climate predictors, removing them should have improved the scale
block. It did not.

## Consistency Audit

Rose searched current docs and found that the newest roadmap and readiness
matrix were already cautious about Ayumi fallback inference. Ada patched the
remaining overstrong wording:

- `docs/design/35-optimizer-start-map-multistart.md` now calls bootstrap a
  refit/audit path before it is an uncertainty path.
- `ROADMAP.md` and `docs/design/46-pre-simulation-readiness-matrix.md` record
  the failed bounded profile and the failed scale simplification.
- `docs/design/12-profile-likelihood-cis.md` and
  `vignettes/phylogenetic-spatial.Rmd` clarify that profile-ready does not
  guarantee a successful interval.

Historical reports that said the fallback was not implemented were left
unchanged because they were true when written and are superseded by the later
check-log entries.

## Known Limitations

No public bootstrap API was added. The profile and bootstrap scripts are
developer diagnostics. The Ayumi fallback still needs a defensible optimum
before bootstrap intervals or profile intervals should be reported as
scientific uncertainty.

## Next Actions

1. Keep `PV2_locphylo` as the clean all-species Mass + Beak example.
2. Treat the block-diagonal and full q4 fallback models as diagnostic stress
   cases until convergence and boundary behavior improve.
3. If the project wants the full prereg scale-phylo fallback to be inferential,
   open a separate design slice for explicit penalized/MAP covariance handling
   and simulation coverage.
