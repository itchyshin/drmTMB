# Q2 Source-Start Prototype For Ayumi Phylogenetic Species Effects

Date: 2026-05-19

Branch: `codex/slices-363-full-ayumi-starts`

## Scope

Ada built a developer-only prototype to test whether simpler fitted models can
provide useful starts for the hard bivariate Gaussian q2 phylogenetic
species-effect case. This is not a public `start_from`, `warm_start`,
`multi_start`, or regularization implementation.

The prototype compared:

- default current starts;
- default covariance starts with modest jitter;
- fixed/residual source starts;
- ordinary species q2 source starts;
- aggregate phylogenetic q2 source starts;
- aggregate phylogenetic q2 source starts with modest covariance jitter.

## Artifacts

The script is:

- `tools/ayumi-q2-start-prototype.R`

The run artifacts are:

- `docs/dev-log/ayumi-convergence/slices-373-382/q2-start-prototype-80species/`
- `docs/dev-log/ayumi-convergence/slices-373-382/q2-start-prototype-300species/`
- `docs/dev-log/ayumi-convergence/slices-373-382/q2-start-prototype-full/`

Each directory contains preflight, source summary, target summary, `check_drm()`
rows, `corpairs()` rows, and start-provenance rows.

## Evidence Summary

| Species subset | Row-capped rows | Jitter starts | Target starts fitted | Target convergence | Residual `rho12` signal |
| --- | ---: | ---: | ---: | --- | --- |
| 80 species | 395 | 2 | 8 | all false convergence | all at 1 |
| 300 species | 1,431 | 2 | 8 | all false convergence | default/source starts at 1; phylo-source starts at -1 |
| 6,196 species | 29,489 | 1 | 6 | all false convergence | all at 1 |

The source models give a useful separation:

- fixed/residual source fits converged on all three subsets, with residual
  `rho12` around 0.668, 0.770, and 0.801;
- aggregate phylogenetic q2 source fits converged on all three subsets, with
  residual `rho12` around 0.641, 0.552, and 0.682;
- ordinary row-capped species q2 source fits false-converged on all three
  subsets, with residual `rho12` at the boundary.

Copying source parameters into the row-capped phylogenetic q2 target did not
rescue the target. Starts and jitter changed objective values, gradients, and
the fitted phylogenetic mean-mean correlation, but the target fits remained at
boundary residual `rho12` with false convergence.

## Interpretation

The larger all-species run matters because it rules out a simple "only small
subset" explanation. More species made the aggregate phylogenetic q2 source
model feasible, but more species did not make the row-capped target
identifiable. The row-capped target still asks the model to separate residual
male-female coupling from a structured species-effect covariance layer, and the
current likelihood surface lets residual `rho12` absorb almost all of that
coupling.

The practical lesson is not that starts are useless. The lesson is narrower:
source starts and covariance jitter are diagnostic tools until one of them
lands on a converged, non-boundary solution with a defensible objective,
gradient, and Hessian. In this stress case they did not.

## Literature And Package Practice

The nearby mixed-model ecosystem treats this as an identifiability and
estimator question, not just an optimizer question:

- `lme4` documents near-`+/-1` correlations as a singular-boundary pattern and
  warns that Wald and profile inference can become unreliable near such
  boundaries:
  <https://lme4.github.io/lme4/reference/isSingular.html>.
- `lme4` convergence guidance recommends data/specification checks, scaling,
  restarting from the reported optimum or a perturbed optimum, and all-optimizer
  comparison:
  <https://lme4.github.io/lme4/reference/convergence.html>.
- `glmmTMB` troubleshooting treats false convergence through gradients,
  Hessian checks, alternate starts, and alternate optimizers:
  <https://glmmtmb.github.io/glmmTMB/articles/troubleshooting.html>.
- `glmmTMB` priors are explicitly maximum-a-posteriori or regularizing
  penalties, not ordinary ML starts:
  <https://glmmtmb.github.io/glmmTMB/articles/priors.html>.
- Chung et al. (2013) provide a penalized-likelihood precedent for weak
  variance components, but the estimator is penalized/MAP:
  <https://doi.org/10.1007/s11336-013-9328-2>.
- Simpson et al. (2017) provide a principled PC-prior framework for shrinking
  toward simpler base models:
  <https://doi.org/10.1214/16-STS576>.
- Lasso or graphical-lasso methods target sparse coefficient or high-dimensional
  covariance selection. That is not the right first tool for one residual
  `rho12` and one q2 phylogenetic mean-mean correlation.

## Decisions

- Do not expose public `start_from`, raw starts, raw TMB `map`, fallback
  optimizers, or stochastic multi-start as a q2 rescue yet.
- Treat deterministic restart-from-optimum and all-fit-style comparison tables
  as the safer next implementation direction.
- Keep residual `rho12`, ordinary species covariance, and phylogenetic
  covariance in separate diagnostics and `corpairs()` rows.
- If penalization is added later, label it as penalized/MAP likelihood, record
  prior or penalty scale, and require simulation and sensitivity evidence.
- Keep the Ayumi row-capped q2 case in the hard-identifiability regression
  suite, not in a tutorial-ready example.

## Next Work

1. Add a deterministic restart-from-optimum developer loop before stochastic
   multi-start.
2. Add an all-fit-style internal comparison table with objective, convergence,
   gradient, boundary status, and selected optimum.
3. Add a fixed-grid or profile-style diagnostic around residual `rho12` for the
   Ayumi q2 target.
4. Keep structured `mu`-`mu` phylogenetic, spatial, and future animal paths as
   the priority; do not expand standalone structured `sigma`-`sigma` models
   before those paths are stable.
