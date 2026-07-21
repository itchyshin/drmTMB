# Part II personality and phylogenetic alignment

This note fixes the mathematical contract before the Part II tutorial is
rewritten. It changes documentation only; it does not change an estimand,
formula grammar, or likelihood.

## Repeated-measures personality model

For observation \(j\) from individual \(i\),

\[
\begin{aligned}
y_{ij} &\sim \operatorname{Normal}(\mu_{ij}, \sigma_{e,i}^2),\\
\mu_{ij} &= \beta_0 + \beta_1\operatorname{sex}_i + b_i,\\
b_i &\sim \operatorname{Normal}(0, \sigma_{b,i}^2),\\
\log(\sigma_{e,i}) &= \gamma_0 + \gamma_1\operatorname{sex}_i,\\
\log(\sigma_{b,i}) &= \alpha_0 + \alpha_1\operatorname{sex}_i.
\end{aligned}
\]

The equation uses female as the reference category:
\(\operatorname{sex}_i=0\) for female and
\(\operatorname{sex}_i=1\) for male.

Sex-specific repeatability is the derived quantity

\[
R_s = \frac{\sigma_{b,s}^2}{\sigma_{b,s}^2 + \sigma_{e,s}^2}.
\]

| Mathematical target | `drmTMB` formula | Simulated truth | Extractor | Tutorial interpretation |
|---|---|---|---|---|
| \(\beta_0,\beta_1\) | `score ~ sex + (1 | individual)` | sex-specific expected score | `predict(..., dpar = "mu")` | sex difference in mean personality score |
| \(\gamma_0,\gamma_1\) | `sigma ~ sex` | sex-specific within-individual SD | `predict(..., dpar = "sigma")` | sex difference in behavioural predictability |
| \(\alpha_0,\alpha_1\) | `sd(individual) ~ sex` | sex-specific between-individual SD | `predict(..., dpar = "sd(individual)")` | sex difference in personality differentiation |
| \(R_s\) | derived, not a fourth formula | ratio of between-individual variance to total variance | combine the two predicted SDs | sex-specific repeatability |

`sex` is an individual-level predictor and must therefore be constant within
each `individual` for the `sd(individual)` submodel.

## Short phylogenetic extension

The familiar constant-scale starting model is

\[
\begin{aligned}
y_i &= \mu_i + a_i + e_i,\\
\mu_i &= \beta_0 + \beta_1 T_i,\\
\mathbf a &\sim \operatorname{MVN}(\mathbf 0, \sigma_a^2 A),\\
e_i &\sim \operatorname{Normal}(0, \sigma_e^2).
\end{aligned}
\]

The location-scale-scale extension retains the same symbols and lets the two
SDs depend linearly on temperature:

\[
\log(\sigma_{e,i}) = \gamma_0 + \gamma_1 T_i,
\qquad
\log(\sigma_{a,i}) = \alpha_0 + \alpha_1 T_i.
\]

| Mathematical target | `drmTMB` formula | Tutorial scope | Extractor | Interpretation |
|---|---|---|---|---|
| \(\beta_0,\beta_1\) and \(a_i\) | `trait ~ temperature + phylo(1 | species, tree = tree)` | one linear predictor | `coef(..., "mu")` and `ranef()` | expected trait and phylogenetic location deviation |
| \(\gamma_0,\gamma_1\) | `sigma ~ temperature` | one linear predictor | `coef(..., "sigma")` | independent SD |
| \(\alpha_0,\alpha_1\) | `sd(species, level = "phylogenetic") ~ temperature` | one linear predictor | `coef(..., "sd_phylo(species)")` | SD of the phylogenetic location effect |

The scalar covariance \(\sigma_a^2 A\) describes the familiar constant-SD
starting point. Once \(\sigma_{a,i}\) varies by species, the model generalizes
that starting point; the tutorial does not introduce a matrix notation for the
heterogeneous covariance because it is unnecessary for the reader's first
model.
