# Phase 6b Tutorial Source Map

Phase 6b turns the implemented model surfaces into a reader path. This source
map is for applied ecology, evolution, and environmental-science users who can
read a regression equation but need help translating `drmTMB` output into
biological claims.

This is a tutorial-planning note, not a new likelihood or syntax design. It
does not make structured slopes, q=4 derived profile intervals, or
predictor-dependent group-level correlations implemented.

## Reader Contract

Each tutorial slice should pair four things:

1. the biological question;
2. the symbolic model;
3. the exact `drmTMB` syntax and output columns;
4. the interpretation on the scale the reader wants to report.

For slope and variance-component material, the tutorial should say whether the
quantity is a fixed-effect mean slope, a residual-scale slope, a mean-model
random-slope SD, a residual-scale random-slope SD, a direct random-effect scale
model, a residual `rho12` correlation, or a group-level `corpairs()` row.

## Slope And Variance-Component Glossary

Use this glossary when polishing the Phase 6b tutorials.

| Quantity | Symbolic form | Implemented surface | Biological interpretation |
| --- | --- | --- | --- |
| Mean fixed-effect slope | `mu_i = beta_0 + beta_1 x_i` | `y ~ x` | Expected response changes by `beta_1` per one-unit increase in `x`, holding the other modelled terms fixed. |
| Residual-scale fixed-effect slope | `log(sigma_i) = gamma_0 + gamma_1 z_i` | `sigma ~ z` | Residual SD is multiplied by `exp(gamma_1)` per one-unit increase in `z`; residual variance is multiplied by `exp(2 gamma_1)` if the scientific summary is variance. |
| Mean random-intercept SD | `b_j = sd_mu_group u_j` | `y ~ x + (1 | group)` | Groups differ in expected response; `sd_mu_group` is the among-group SD in the mean model, not residual `sigma`. |
| Mean random-slope SD | `mu_ij = beta_0 + beta_1 x_ij + b_0j + b_1j x_ij` | ordinary Gaussian `mu` random slopes | Groups differ in their reaction-norm slopes. A larger slope SD means the biological effect of `x` varies more among groups. |
| Residual-scale random intercept | `log(sigma_ij) = X_sigma beta_sigma + a_j` | `sigma ~ z + (1 | group)` | Groups differ in residual unpredictability after the fixed residual-scale predictors are included. |
| Residual-scale random-slope SD | `log(sigma_ij) = X_sigma beta_sigma + a_1j w_ij` | independent Gaussian `sigma` random slopes | Groups differ in how residual unpredictability changes along `w`. |
| Random-effect scale model | `log(sd_mu_group,j) = alpha_0 + alpha_1 h_j` | `sd(group) ~ h` | A group-level predictor changes the among-group SD in expected response. Report `exp(alpha_1)` as an SD ratio or `exp(2 alpha_1)` as a variance ratio. |
| Residual correlation slope | `rho12_i = tanh(delta_0 + delta_1 x_i)` | `rho12 ~ x` | Residual coupling between two responses changes along `x` after both means and residual SDs are modelled. |
| Group-level correlation | `cor(b_1j, b_2j)` or `cor(b_0j, b_1j)` | fitted `corpairs()` rows when supported | Groups with higher latent values for one fitted component also tend to have higher or lower latent values for another fitted component. This is not residual `rho12`. |
| Structured variance component | `b ~ MVN(0, sd^2 A)` or spatial analogue | fitted `phylo()` intercept path plus coordinate-spatial intercept and one-slope `mu` paths | Species or sites share latent mean deviations according to tree or coordinate structure; the fitted spatial one-slope path lets the biological effect of one numeric covariate vary across sites without an intercept-slope correlation. |

The same coefficient can have different report scales. For example,
`gamma_1 = 0.3` in `sigma ~ z` means the residual SD ratio is `exp(0.3)`.
If the biological target is residual variance, the corresponding variance
ratio is `exp(0.6)`. Tutorials should name that conversion instead of silently
switching between SD, variance, and predictability.

## Tutorial Source Map

| Tutorial or guide | Current role | Slice need | Slope and variance-component obligation |
| --- | --- | --- | --- |
| `vignettes/drmTMB.Rmd` | Getting-started orientation | Slice 62 | Point readers from a biological question to the tutorial that explains the relevant slope or variance component. |
| `vignettes/model-map.Rmd` | Implemented-versus-planned guide | Slice 62 | Keep ordinary random slopes, residual-scale slopes, `sd(group)`, residual `rho12`, phylogenetic correlations, and spatial effects in separate rows. |
| `vignettes/location-scale.Rmd` | Gaussian location-scale tutorial | Slice 63 | Explain fixed mean slopes, fixed residual-scale slopes, ordinary mean random slopes, and why `sigma` is residual SD rather than among-group SD. |
| `vignettes/which-scale.Rmd` | Scale vocabulary guide | Slice 63 and Slice 67 | Become the main glossary for `sigma`, `sd(group)`, residual-scale random effects, random-slope SDs, likelihood weights, and known sampling variance. |
| `vignettes/bivariate-coscale.Rmd` | Residual `rho12` tutorial | Slice 64 | Interpret `mu1` and `mu2` slopes, `sigma1` and `sigma2` slopes, and `rho12` slopes as separate biological claims. Keep residual `rho12` distinct from group-level `corpairs()`. |
| `vignettes/meta-analysis.Rmd` | Known sampling covariance tutorial | Slice 65 | Explain mean moderator slopes, extra heterogeneity `sigma`, known sampling variance `V`, and when to report `sigma`, `sigma^2`, or total observation variance. |
| `vignettes/phylogenetic-spatial.Rmd` | Structural-dependence tutorial | Slice 66 and Slice 91 | Separate residual `rho12`, ordinary group-level correlations, phylogenetic covariance rows, coordinate-spatial `mu` diagnostics, the first independent spatial and phylogenetic slope SDs, and the planned phylogeny-plus-spatial endpoint. Keep mesh/SPDE, structured slope correlations, simultaneous `phylo()` plus `spatial()`, and structural `sigma` slopes planned unless implemented later. |
| `vignettes/model-workflow.Rmd` | Post-fit workflow | Slice 62 and Slice 68 | Teach readers to inspect `summary()`, `profile_targets()`, `conf.status`, `profile.boundary`, `profile.message`, `corpairs()`, and `check_drm()` before interpreting bounded SD or correlation targets. |
| `vignettes/source-map.Rmd` | Contributor source map | Slice 61 support | Keep R builders, TMB branches, tests, and docs aligned when a tutorial claims a model surface is implemented. |

## Biological Examples To Carry Forward

The Gaussian location-scale tutorial should keep a growth or performance
example where temperature affects both expected growth and residual
predictability:

\[
\begin{aligned}
\text{growth}_{ij}
  &\sim \operatorname{Normal}(\mu_{ij}, \sigma_{ij}^2),\\
\mu_{ij}
  &= \beta_0 + \beta_1 \text{temperature}_{ij}
     + b_{0j} + b_{1j}\text{temperature}_{ij},\\
\log(\sigma_{ij})
  &= \gamma_0 + \gamma_1 \text{temperature}_{ij}.
\end{aligned}
\]

Here `beta_1` is the average thermal response, `sd(b_1)` is the among-group
variation in thermal plasticity, and `gamma_1` is the residual-SD response to
temperature. Those are three different biological statements.

The random-effect scale tutorial should use a group-level predictor such as
habitat:

\[
\log(sd_{\mu,population,j})
  = \alpha_0 + \alpha_1 \text{habitat}_j.
\]

Here `alpha_1` says whether the among-population SD in expected growth differs
by habitat. It does not say that individual residual variation is larger; that
question belongs to `sigma ~ habitat` or a residual-scale random effect.

The bivariate tutorial should use paired traits or behaviours:

\[
\rho_{12i} = \tanh(\delta_0 + \delta_1 \text{disturbance}_i).
\]

Here `delta_1` says whether residual activity-boldness coupling changes with
disturbance after response-specific means and residual SDs are modelled. It is
not a species-level plasticity syndrome unless the fitted model has the
corresponding group-level slope covariance row.

For q=4 location-scale covariance examples, tutorials and planning notes must
name all four mean-scale pairs: `mu1`-`sigma1`, `mu1`-`sigma2`,
`mu2`-`sigma1`, and `mu2`-`sigma2`. The cross-trait pairs can be harder to
explain biologically, but they are part of the fitted q=4 covariance block and
should not disappear from examples.

## Implementation Notes For Later Slices

- Slice 61 records the source map and should not change fitted-model behavior.
- Slices 62-68 can edit tutorials, navigation, and examples using this map.
- Phase 6c and the structural-dependence phases should handle new random-slope
  implementation work. Ordinary fitted random slopes and the first
  coordinate-spatial, phylogenetic, animal-model, and `relmat()` one-slope
  paths can be interpreted, but multiple structured slopes, bivariate
  structured slopes, and slope correlations should stay planned.
- Any new user-facing syntax needs the formula grammar updated before it is
  treated as available.
- Any new likelihood parameterization needs the likelihood design note updated
  before it is treated as complete.
- Profile-likelihood interval claims must follow the Phase 6 status vocabulary:
  use profile intervals for direct profile-ready targets, and use explicit
  unavailable statuses for derived or weakly identified slope and covariance
  summaries.
