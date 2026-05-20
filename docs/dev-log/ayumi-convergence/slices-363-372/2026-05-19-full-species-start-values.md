# Full-Species Ayumi Starting-Value Read

Date: 2026-05-19

Branch: `codex/slices-363-full-ayumi-starts`

## Scope Correction

Ada is treating the McGillycuddy, Popovic, Bolker, and Warton
reduced-rank paper as background only. The `rr()` residual-initialization
method belongs to reduced-rank factor-analytic models, which is the gllvm and
glmmTMB lane. `drmTMB` is fitting one-response and two-response distributional
regression, so the useful starting-value question here is not "can we borrow
the `rr()` residual factor trick?" It is:

- can simpler fitted models provide scale-aware starts for fixed effects,
  residual `rho12`, residual `sigma`, and variance components;
- can staged covariance releases prevent q2 and q4 structured models from
  starting in a poor part of the likelihood surface;
- can multi-start refits show whether the final likelihood is stable or a local
  optimum;
- can `check_drm()` record enough provenance to keep inference tied to the
  selected final optimum.

## Sources Read

- McGillycuddy, Popovic, Bolker, and Warton:
  [Parsimoniously Fitting Large Multivariate Random Effects in glmmTMB](https://arxiv.org/abs/2411.04411).
  The paper is about high-dimensional multivariate random effects represented
  through lower-rank latent variables. Its `start_method = list(method = "res")`
  idea initializes fixed effects, latent variables, and factor loadings from a
  GLM-residual reduced-rank step. That does not directly transfer to the
  current `drmTMB` phylogenetic species-effect path because we are not
  estimating a factor-loading matrix.
- glmmTMB covariance documentation:
  [Covariance structures with glmmTMB](https://glmmtmb.github.io/glmmTMB/articles/covstruct.html).
  The public `start_method` is explicitly attached to reduced-rank `rr(...)`
  covariance structures. The transferable part is not the residual-factor
  algorithm; it is the warning that complex random-effect likelihoods can be
  multimodal and should be checked by repeated starts.
- glmmTMB model documentation:
  [Fit Models with TMB](https://glmmtmb.github.io/glmmTMB/reference/glmmTMB.html).
  glmmTMB exposes `start` by internal parameter classes such as fixed effects,
  random-effect modes, random-effect covariance parameters, and family shape
  parameters. `drmTMB` has intentionally not exposed this yet.
- glmmTMB control documentation:
  [glmmTMBControl](https://glmmtmb.github.io/glmmTMB/reference/glmmTMBControl.html).
  Optimizer controls and reduced-rank start controls are separate. Increasing
  iterations is not the same thing as a warm start or a multi-start diagnostic.
- lme4 convergence documentation:
  [Assessing Convergence for Fitted Models](https://lme4.github.io/lme4/reference/convergence.html).
  The mixed-model convergence workflow includes scaling predictors, changing
  optimizer tolerances, restarting from the reported optimum or a small
  perturbation, and comparing optimizers with `allFit()`.
- ASReml multivariate animal example:
  [Multivariate animal genetics data - Sheep](https://www.hpc.iastate.edu/sites/default/files/uploads/ASREML/htmlhelp/asreml/xsheep.htm).
  This is pedigree-animal-model literature, not the Ayumi model. The only
  transferable lesson is to start complex multivariate covariance models from
  simpler univariate analyses, which provide diagonal variance starts and
  reveal which variance components are estimable.
- ASReml convergence guidance:
  [ASReml user guide structural specification](https://www.animalgenome.org/bioinfo/resources/manuals/ASReml3/UserGuideStructural.pdf).
  The practical checks are starting-value order, magnitude, and scale; simpler
  models as a source of initial values; possible temporary fixed parameters;
  and whether the covariance structure itself is too ambitious for the data.
- BLUPF90 AIREML tutorial:
  [Variance component estimation](https://masuday.github.io/blupf90_tutorial/vc_aireml.html).
  AI-REML uses supplied variance-component starts. EM-REML is slower but more
  stable and can provide a starting point for AI-style updates. The transferable
  idea for `drmTMB` is an explicit staged optimizer or start-source contract,
  not an implicit hidden change.

## Current drmTMB State

`drmTMB` currently has internal default starts, but no public start,
warm-start, fixed-parameter map, fallback optimizer, or multi-start interface.
`drm_control()` reserves the relevant names so they cannot be silently passed
through to `nlminb()` before the contract exists.

For phylogenetic Gaussian starts, the current internal default is simple:

- latent phylogenetic effects start at zero;
- phylogenetic SDs start near one quarter of the response scale;
- covariance or correlation parameters start at zero.

That is a reasonable default for ordinary fits, but it is not enough to claim
we have a phylogenetic species-effect starting-value strategy for hard q2 or q4
cases.

## Full-Species Evidence

Ada added `tools/ayumi-full-species-convergence.R` and ran it against
`DRMTMB_TEST_DIR/data_raw/data_6196spp.csv` and
`DRMTMB_TEST_DIR/data_raw/tre_10597spp.nex`.

Artifacts:

- `docs/dev-log/ayumi-convergence/slices-363-372/full-species-live/tree-preflight.csv`
- `docs/dev-log/ayumi-convergence/slices-363-372/full-species-live/fit-summary.csv`
- `docs/dev-log/ayumi-convergence/slices-363-372/full-species-live/check-rows.csv`
- `docs/dev-log/ayumi-convergence/slices-363-372/full-species-live/corpairs.csv`
- `docs/dev-log/ayumi-convergence/slices-363-372/full-species-live/profile-targets.csv`
- `docs/dev-log/ayumi-convergence/slices-363-372/full-species-live/fit-conditions.csv`

Preflight:

- raw complete data: 1,603,663 rows, 6,196 species;
- aggregate data: 6,196 rows, 6,196 species;
- row-capped data: 29,489 rows, 6,196 species, up to 5 rows per species;
- pruned raw tree: 6,196 tips, not ultrametric;
- forced tree: ultrametric, but `phytools::force.ultrametric()` warned that it
  is only a coercion method, not a formal rate-smoothing method.

Fit signals with `se = FALSE`:

| Scenario | Rows | Species | Status | Optimizer message | Elapsed seconds | Main signal |
| --- | ---: | ---: | --- | --- | ---: | --- |
| aggregate fixed/residual `rho12` | 6,196 | 6,196 | fit | relative convergence | 0.21 | residual `rho12` around 0.787 |
| aggregate location-scale plus modelled `rho12` | 6,196 | 6,196 | fit | relative convergence | 1.04 | modelled residual `rho12` range around 0.764 to 0.823 |
| aggregate q2 phylo mean, raw tree | 6,196 | 6,196 | error | raw tree not ultrametric | 0.85 | preflight catches tree problem |
| aggregate q2 phylo mean, forced tree | 6,196 | 6,196 | fit | relative convergence | 26.30 | residual `rho12` around 0.682; phylo mean-mean correlation around 0.829 |
| row-capped ordinary species q2 | 29,489 | 6,196 | fit | false convergence | 164.74 | residual `rho12` hit boundary; huge gradient |
| row-capped q2 phylo mean | 29,489 | 6,196 | fit | false convergence | 330.04 | residual `rho12` hit boundary; huge gradient |
| row-capped phylo plus ordinary species q2 | 29,489 | 6,196 | fit | false convergence | 101.95 | residual `rho12` hit boundary; phylo and ordinary species covariance not cleanly separated |

The aggregate all-species q2 phylogenetic model is not the same diagnostic as
the row-level or row-capped phylogenetic species-effect model. The aggregate
fit can converge quickly because it has one row per species. Once repeated
rows are present and ordinary or phylogenetic species effects compete with
residual `rho12`, the current default starts and optimizer path do not produce
a trustworthy optimum.

Because these runs used `se = FALSE`, they test the optimizer path and
diagnostic rows, not Wald standard errors or Hessian positive-definiteness.
They are convergence stress evidence, not final inferential evidence.

## Practical Conclusion

The `rr()` residual start trick is not the right thing to port directly. The
right drmTMB starting-value work is a source-fit and multi-start contract for
ordinary and structured two-response models:

1. fit fixed/residual `rho12` models first;
2. copy compatible fixed effects, residual `sigma`, and residual `rho12` to the
   richer target model on the correct internal scale;
3. initialize variance components from simpler ordinary, univariate, or
   response-specific models rather than a universal `0.25 * sd(y)`;
4. release covariance parameters in stages: diagonal or response-specific
   starts, then q2 mean-mean, then q4 only after diagnostics pass;
5. add jittered multi-start refits for covariance and correlation parameters,
   record every attempt, and select only by a documented objective and
   convergence rule;
6. keep residual `rho12`, ordinary species covariance, and phylogenetic
   covariance separate in diagnostics and `corpairs()`.

## Next Work

- Implement no public phylogenetic species-effect start claim until `start_from` or
  `multi_start` can record copied targets, skipped targets, optimizer result,
  and selected optimum provenance.
- Add a narrow developer-only prototype first for q2 Gaussian bivariate fits:
  fixed/residual source fit to q2 target, then ordinary species or phylogenetic
  q2 source to richer q2 target.
- Treat the row-capped all-species false-convergence runs as the regression
  target for that prototype.
- Keep q4 phylogenetic location-scale on the hard-identifiability lane until
  q2 warm-start and multi-start diagnostics work.
