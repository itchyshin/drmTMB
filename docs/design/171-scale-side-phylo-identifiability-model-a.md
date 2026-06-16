# Scale-Side Phylogenetic Identifiability and the "Model A" Recommendation

## Purpose

This note is the honest answer to a recurring question: why a bivariate q4
Gaussian location-scale **phylogenetic** model with a phylogenetic field on the
*scale* (`sigma1`, `sigma2`) is hard to fit on one-observation-per-tip data, and
what to do instead. The reader is the applied user (the beak/tarsus dataset) and
the next `drmTMB` contributor. The evidence comes from the Curie
(simulation/recovery) review role on pruned real data (n = 300-600 tips).

## The model and the failure

Ayumi's q4 model puts phylogenetic effects on all four endpoints:

```r
bf(
  mu1    = Tarsus_Length_z      ~ temp + prec + temp:prec + log_mass + phylo(1 | p | tree_tip, tree = tree),
  mu2    = Beak_Length_Culmen_z ~ temp + prec + temp:prec + log_mass + phylo(1 | p | tree_tip, tree = tree),
  sigma1 = ~ temp + prec + temp:prec + log_mass + phylo(1 | p | tree_tip, tree = tree),
  sigma2 = ~ temp + prec + temp:prec + log_mass + phylo(1 | p | tree_tip, tree = tree),
  rho12  = ~ 1
)
```

At every pruned size tested, this fails: `convergence = 1`
("false convergence (8)"), `pdHess = FALSE`, and the two **scale-side**
phylogenetic SDs are pinned at their lower start value (~0.05). The likelihood is
flat in the scale-phylo SD direction; the gradient with respect to
`log_sd_phylo` for the scale endpoints diverges, so the Hessian is indefinite.

## What it is NOT (ruled out by experiment)

- **Not a coupling problem.** The separable "Model D" (distinct labels
  `phylo(1 | pl | id)` on the mean side, `phylo(1 | ps | id)` on the scale side)
  fails the same way for the full four-covariate `sigma` specification -- the
  scale-side SD hits its boundary whether the 4x4 block is coupled or
  block-diagonal.
- **Not a correlation-start problem.** Seeding `theta_phylo` off-diagonal does
  not help. In the R/TMB implementation `theta_phylo = 0` already yields the
  *identity* correlation (`tmb_unstructured_corr_matrix(rep(0, 6)) = I_4`), so
  there is no removable 0/0 singularity to escape. (That singularity was specific
  to a different, Julia-side implementation.)
- **Not a warm-start problem.** Warm-starting the coupled model from a converged
  reduced fit finds a worse, still non-stationary point.

## Root cause

With (approximately) **one observation per tip** and a rich fixed-effect
predictor on `log(sigma)`, the data cannot identify a phylogenetic field on the
scale. A per-tip scale random effect estimated from a single residual is a
structural near-degeneracy. The tipping point in these tests is about **two
`sigma` covariates together with a scale-side phylo block**; the
`temp:prec` interaction on `sigma` consistently triggers it.

The univariate version of the same degeneracy (one response, phylo on `mu` and
`sigma`, full data) shows up not as an SD boundary but as a numerical *overflow*
of `log(sigma)`; that path is guarded separately by the soft-clamp in
`docs/design/170-sigma-phylo-conditioning-and-logsigma-clamp.md`. Both are the
same underlying weak identifiability of a scale-side phylogenetic field on
one-observation-per-tip data.

## Structural vs empirical correlation (important clarification)

`fit$corpars$phylo` is the **structural** phylogenetic correlation, computed from
`theta_phylo` via `tmb_unstructured_corr_matrix()` (and `eta_cor_phylo` for the
q=2 case). At the failed fits `theta_phylo = 0`, so the **structural phylogenetic
correlation is the identity (all zeros)** -- there is no structural boundary
correlation. A "phylogenetic correlation near +/-1" seen elsewhere is an
*empirical* correlation among the fitted random-effect predictions (BLUPs), which
is a different quantity. Do not read a large empirical random-effect correlation
at `theta = 0` as a structural identifiability boundary.

## Recommendation: "Model A" (phylogeny on the mean, fixed-effect scale)

```r
bf(
  mu1    = Tarsus_Length_z      ~ temp + prec + temp:prec + log_mass + phylo(1 | pl | tree_tip, tree = tree),
  mu2    = Beak_Length_Culmen_z ~ temp + prec + temp:prec + log_mass + phylo(1 | pl | tree_tip, tree = tree),
  sigma1 = ~ temp + prec + temp:prec + log_mass,
  sigma2 = ~ temp + prec + temp:prec + log_mass,
  rho12  = ~ 1
)
```

This converges to a positive-definite-Hessian optimum (`pdHess = TRUE`) and
recovers a strong mean-level phylogenetic signal. On large trees, pass
`control = drm_control(optimizer_preset = "robust")` so the optimizer does not
stop at the default iteration cap. The scale is still a full distributional
regression (four covariates), just without a phylogenetic random field.

### Real-data confirmation (full 10,440-tip beak + tarsus data)

Model A with the robust preset converges cleanly on the full data:
`convergence = 0`, `pdHess = TRUE`, `max|gradient| = 0.18`, `logLik = 10,358`,
mean-side phylo SDs about 0.34, and mean-mean phylo correlation about 0.21
(`check_drm()` is clean apart from the expected one-observation-per-tip
replication notes). The likelihood-ratio test of mean-level phylogenetic signal
against a no-phylo model is overwhelming: `LR = 36,572` on 3 df, `p ~ 0`. So
Model A is strongly the right model; the scale-side phylogenetic field is the
weakly identified part, and dropping it costs nothing identifiable.

If a phylogenetic signal in the *scale* is scientifically important to test, do
it as a likelihood-ratio test of Model A against a model that adds **one
scale-side phylo intercept per endpoint without the interaction term** (which
does converge), and only when replication is adequate (more than one observation
per tip, or a tree/data combination where the scale-side phylo SD is clearly
supported: `pdHess = TRUE` and the SD off its boundary).

## Reconciliation with across-tree results

The data owner reports that a separable model converges with `pdHess = TRUE` on
some clean full-size trees. That is consistent with this note: whether the
scale-side phylo SD is identifiable depends on the tree, the sample, and the
`sigma` specification, not on the block structure. The recommendation is to
prefer Model A unless the scale-side phylo SD is demonstrably well supported.

## The Julia (DRM.jl) parallel

The DRM.jl engine (the Julia acceleration path) hits the **same identifiability
boundary** on this model, with the opposite numerical sign. There it surfaces as
DRM.jl issue #293: maximum-likelihood fits return `logLik = -Inf` once the tree
exceeds about 100 tips, because the per-tip scale latents collapse toward
`sigma -> 0` (the per-leaf density is unbounded below), whereas drmTMB's unbounded
log link drives `sigma -> +Inf` (overflow). Both are the same statistical
pathology -- a per-tip scale random effect cannot be identified from one
observation per tip -- and the DRM.jl team had already proved and documented it
(their inner Laplace objective is unbounded below for large trees, and it worsens
as tips increase, which is why small subsets fit and large ones do not). The
cross-cutting answer is the same: **Model A** (phylogeny on the mean,
fixed-effect scale) or two-plus observations per tip. A `log(sigma)` clamp is a
wrong-sided band-aid on the Julia side, and the off-diagonal correlation start is
already in place there and unrelated. REML stays finite in DRM.jl only because it
profiles the scale fixed effects and carries a restricted-information barrier that
repels the boundary -- a symptomatic escape, not evidence the model is
identified.

## What drmTMB does to help

- A `check_drm()` note that fires when a fit with a scale-side phylogenetic field
  is unreliable (`pdHess = FALSE`), pointing the user to Model A or to supplying
  more observations per group (separate slice).
- The `log(sigma)` soft-clamp (doc 170) so the univariate full-data case returns
  a finite, assessable fit instead of overflowing.
- This note as the reference for the recommendation.
