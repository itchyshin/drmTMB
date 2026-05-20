# After Task: Slices 373-390 Q2 Starts And Regularization Boundary

## Goal

Test whether source-fit starts or covariance jitter rescue Ayumi's bivariate
Gaussian q2 phylogenetic species-effect stress case, then decide whether
larger data, lasso, penalization, or regularization should change the next
implementation slice.

## Implemented

- Added `tools/ayumi-q2-start-prototype.R`, a developer-only q2 start harness
  that does not expose a public start API.
- Ran the prototype on 80 species, 300 species, and all 6,196 species with
  row-capped target data.
- Added q2-start artifacts under
  `docs/dev-log/ayumi-convergence/slices-373-382/`.
- Added
  `docs/dev-log/ayumi-convergence/slices-373-382/2026-05-19-q2-start-prototype.md`
  with the evidence summary, literature reading, and decisions.
- Updated the optimizer/start/multi-start design note, pre-simulation readiness
  matrix, roadmap, NEWS, and convergence vignette so the package story matches
  the evidence.

## Mathematical Contract

The target model is still ordinary maximum likelihood for a bivariate Gaussian
fit with residual `rho12` and a q2 phylogenetic mean-mean covariance layer.
Source starts only change the initial fixed-parameter vector. They do not
change the likelihood or define a new estimator.

Penalized likelihood, weakly informative priors, PC priors, LKJ-style
correlation priors, and ridge penalties would change the estimator to
penalized/MAP. They may be useful later, but they must be named as such and
given simulation, sensitivity, interval, and documentation evidence before
becoming a public route.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/35-optimizer-start-map-multistart.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/after-task/2026-05-19-slices-373-390-q2-start-regularization.md`
- `docs/dev-log/ayumi-convergence/slices-373-382/2026-05-19-q2-start-prototype.md`
- `docs/dev-log/check-log.md`
- `tools/ayumi-q2-start-prototype.R`
- `vignettes/convergence.Rmd`
- q2 prototype artifact CSVs under
  `docs/dev-log/ayumi-convergence/slices-373-382/`

## Checks Run

```sh
DRMTMB_Q2_START_N_SPECIES=80 DRMTMB_Q2_START_N_JITTER=2 Rscript tools/ayumi-q2-start-prototype.R
DRMTMB_Q2_START_N_SPECIES=300 DRMTMB_Q2_START_N_JITTER=2 Rscript tools/ayumi-q2-start-prototype.R
DRMTMB_Q2_START_N_SPECIES=0 DRMTMB_Q2_START_N_JITTER=1 Rscript tools/ayumi-q2-start-prototype.R
Rscript -e "parse('tools/ayumi-q2-start-prototype.R'); parse('tools/ayumi-full-species-convergence.R')"
Rscript -e 'rmarkdown::render("vignettes/convergence.Rmd", output_dir = tempfile("convergence-render-"), quiet = FALSE)'
Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("convergence", new_process = FALSE, quiet = TRUE)'
Rscript -e 'pkgdown::check_pkgdown()'
git diff --check
```

Additional validation commands are recorded in the check log for this slice.

## Tests Of The Tests

The prototype would have supported a public-start follow-up only if at least
one source or jittered target landed on a converged, non-boundary solution with
defensible gradient and objective evidence. It did not. The negative result is
therefore the test: the artifacts prevent Ada from treating starts or jitter as
a rescue without stronger evidence.

## Consistency Audit

Ada kept the work developer-only and integrated the design boundary. Gauss and
Noether kept residual `rho12` separate from the latent phylogenetic mean-mean
correlation. Fisher read the result as identifiability evidence, not biological
inference. Jason and Russell checked the nearby package and statistical
literature. Grace kept the full all-species run reproducible and local. Pat
needed the convergence guide to explain that larger data only helps when it
adds the right replication. Rose checked that the docs do not describe
regularization, lasso, raw maps, or stochastic multi-start as implemented
solutions.

## What Did Not Go Smoothly

The first spawn attempt used an incompatible full-history fork option for
specialist roles, so Ada relaunched the literature and landscape tasks with
self-contained briefs. The full all-species prototype also took long enough
that the evidence had to be summarized from written artifacts rather than from
interactive console output alone.

## Known Limitations

- No public `start_from`, `start`, `warm_start`, `fixed`, fallback optimizer,
  or `multi_start` control was implemented.
- The full run used row-capped data, not all 1.6 million rows.
- The target runs used `se = FALSE`; Hessian positive-definiteness and Wald
  standard errors remain unavailable for the hard target fits.
- No penalized/MAP likelihood was implemented.
- No fixed-grid or profile diagnostic around residual `rho12` was run yet.

## Next Actions

1. Add a deterministic restart-from-optimum developer loop before stochastic
   multi-start.
2. Add an all-fit-style comparison table with objective, convergence, gradient,
   elapsed time, boundary status, and selected optimum.
3. Add a residual-`rho12` fixed-grid or profile-style diagnostic for the Ayumi
   q2 target.
4. Keep structured `mu`-`mu` phylogenetic, spatial, and future animal paths as
   the priority; do not expand standalone structured `sigma`-`sigma` models
   before those paths are stable.
