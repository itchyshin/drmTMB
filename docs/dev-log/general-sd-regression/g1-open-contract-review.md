# G1 methods-contract review: what remains before wider latent-SD regression

Independent source/math review, 2026-10-17. This reads
[`research.md`](research.md), [`target-contract.md`](target-contract.md),
[`block-dimension-contract.md`](block-dimension-contract.md), and the
19,118-row [`required-universe.md`](required-universe.md). It changes no
model contract or admission gate. The research note is evidence triage, not
an identifiability theorem or calibration certificate. The required rows are
candidate obligations; all still have `direct_sd_claim=none`, and G0's
family/endpoint/provider classification remains open.

## Decisions already sufficient for a bounded build

The target is one latent coefficient axis, with its distributional parameter,
coefficient, group, block label, provider, and stable internal member identity.
The group design `W[g,]` predicts a positive latent amplitude
`tau_ga = exp(W[g,] alpha_a)`; the observation random-regression design
`Z[i,a]` acts later. For an admitted ordinary coefficient correlation
`R_g` with unit diagonal, the intended group covariance is

```
B_g = D_g R_g D_g,   D_g = diag(tau_g1, ..., tau_gq).
eta_i receives Z[i,a] b[g(i),a], not Z[i,a] tau_g on its own.
```

An unselected axis retains its existing constant SD. Positive diagonal
scaling preserves positive semidefiniteness and the existing correlation;
it does not establish identifiability or license a new covariance block.
The ordinary builder already separates latent term indices, group levels,
`re_sd_row0`, and SD coefficient/row indices (`R/drmTMB.R:15484-15612,
17384-17495`). The native q1/q2 path selects `sd_current` by `mu_re_sd_row`
before applying the random-regression value (`src/drmTMB.cpp:914-952`);
therefore a selected slope does **not** need a different response likelihood.
These facts support a narrow ordinary coefficient-specific slice, subject to
the tests below.

## Load-bearing decisions still open

1. **One amplitude per selected member, with no duplicate free scale.** For
   q2 and larger blocks, decide the exact native and Julia map for replacing
   a member's constant log-SD by `W alpha`. Freeing both a constant log-SD and
   the SD formula's intercept for the same member creates an exact scale
   redundancy. In native q>2 Gaussian blocks the current
   `VECSCALE(UNSTRUCTURED_CORR, sd_block).sqrt_cov_scale(z)` uses constant
   `log_sd_re_cov` values (`src/drmTMB.cpp:821-887`). A coefficient-specific
   extension must build `D_g` at each group, keep every existing correlation
   slot, and map/report the selected base SD only once. The q2 native path
   already has a correlation slot and, on admitted models, a predictor-varying
   correlation path (`src/drmTMB.cpp:4931-4973`); the target is
   `D_g R_g D_g`, not a new correlation regression. Julia's q2 and tagged q4
   layouts need their own explicit member/parameter map. The common target
   descriptor is necessary, but does not provide those engine maps by itself.

2. **Structured base covariance and normalization by actual provider/input.**
   Let `C` be the *current* covariance of the latent coefficient vector,
   including its K/Q, correlation, normalization, and projection rules.
   Then `Cov(b)=D C D` and marginal latent SD at axis/node `j` is
   `tau_j sqrt(C_jj)`. A raw multiplier is not generally that marginal SD.
   The provider audit must pin `C_jj` for tree phylogeny, pedigree versus
   animal A/Ainv, relmat K versus Q, coordinate spatial, temporal AR1/OU,
   two-tree interaction, and mesh separately. Do not normalize a non-unit
   diagonal away to make an extractor simpler. When a provider has an
   existing global multiplier, neutralize/map it exactly once for a selected
   axis and show that `W` slopes zero reproduces its old covariance at the
   same intercept. Current native structured q2 has distinct prior and
   observation-scaling branches (`src/drmTMB.cpp:1006-1111,5035-5180`):
   simply toggling `has_sd_phylo_model` together with predictor-varying
   correlation can bypass the intended scaling branch. A joint construction
   and a fixed-parameter covariance oracle are prerequisites for that cell.

3. **Projection has an observation index as well as a site/group index.** The
   mesh contract correctly chooses `D_obs A Q^-1 A' D_obs`, with one
   site-level multiplier shared across observations, even if their projection
   rows differ. This differs from `A D_node Q^-1 D_node A'`; its diagonal
   may differ within one site. The existing native field is a sparse GMRF
   projected by `A` (`src/drmTMB.cpp:1157-1173`). The implementation decision
   still needed is the exact sparse multiplication/derivative path and how
   stored/new-data prediction aligns `A` rows, site labels, `W` rows, and
   marginal-variance metadata. Dense `Q^-1` belongs only in a tiny independent
   oracle. Do not add a same-projection-row-per-site restriction or promise a
   single site intercept where the rows differ.

4. **Identity and admission remain separate.** The existing ordinary
   resolver can identify unique labelled and slope axes; its 56 source
   assertions test ordering and pair integrity, not an admitted fit.
   Structured descriptors still need provider-instance identity and global
   latent positions distinct from observation-to-node/group indices.
   `group`, `level`, `dpar`, `coef`, and `block` selectors must resolve one
   member or list actual candidates. An unsupported endpoint or base route
   remains visible as `blocked_base_plumbing`, rather than disappearing from
   the 19,118-row denominator. The 6,750 canonical endpoint-subset rows are
   review candidates, not permission to invent dependence between arbitrary
   distributional parameters. Preserve one-response/two-response scope and
   the source-shaped q domains in `block-dimension-contract.md`. The current
   public parser still rejects explicit `dpar` other than `mu`, explicit
   selectors on `sd1()`/`sd2()`, and non-phylogenetic explicit `level`
   (`R/parse-formula.R:554-704`); its implicit ordinary level is `group`,
   but `level = "group"` is not a currently accepted public spelling. The
   contract needs one canonical spelling and alias rule before lifting those
   gates; internal resolver acceptance alone is insufficient.

5. **Identifiability is design-specific.** Full rank of `W` is necessary for
   its coefficients but does not prove estimability of latent amplitude from
   the response. A selected slope also needs informative variation in its
   within-group random-regression value `Z`; near-zero amplitude, sparse
   outcomes, collinear group predictors, and few groups can produce weak
   information. The research correction gives a specific probit/constant-SD
   confounding identity, `Phi(X beta / sqrt(1+tau^2))`, when all fixed
   coefficients are free. It does **not** exclude every singleton-group
   Bernoulli logit or heterogeneous-SD design. Existing all-singleton
   admission fences should be recorded as software fences until each exact
   family/design cell has a mathematical or recovery argument.

6. **Prediction and inference must name the estimand.** `W alpha`, `tau`,
   `tau sqrt(C_jj)`, and `Z[i,a] b[g(i),a]` are different outputs. Existing
   `sdpars` meanings, including the mesh raw GMRF multiplier, remain stable;
   the `predict_parameters()`/`VarCorr()` audit must precede a new public
   marginal-SD name. Uncertainty for `alpha`, a selected latent SD, an SD
   ratio, a provider-marginal SD, and a latent contribution also differs.
   Profile and parametric-bootstrap intervals need separate calibration,
   including failed fits and all-attempt denominators. The current native
   Bernoulli/logit scalar campaign is one fixed family/link/provider/q/design
   stratum and cannot validate Poisson, slopes, q2, structured kernels, Julia,
   or new interval routes. Laplace versus increasing-order quadrature is an
   approximation-sensitivity check where tractable, not forced equality of
   estimates.

## Finite next slice and GO boundary

**GO for a bounded native Poisson independent slope-only target**
`bf(y ~ x + (0 + x | id), sd(id, coef = "x") ~ w)` on complete data, with
group-constant `w`, within-group variation in numeric `x`, and no structured,
correlated, zero-inflated, missing-data, or cross-endpoint layer. Its contract
is `eta_gi = beta0 + beta1*x_gi + x_gi*tau_g*u_g`, `u_g~N(0,1)`,
`tau_g=exp(alpha0+a*w_g)`. The selected slope's old constant SD must be mapped
out; an unrelated constant intercept on a **different** group remains
unchanged. The independent scalar Poisson slope reference in
`tests/testthat/helper-poisson-slope-sd-reference.R` checks the exact
curvature `tau^-2 + sum_i x_i^2 exp(eta_i+x_i*b)` and adaptive integration
for fixed parameters. Before claiming the slice, require assembly/index
negatives, constant-SD equivalence, source-independent objective comparison,
stored/new-data SD predictions, marginal simulation/refit identity, and
recovery; calibrated intervals remain separately gated. This is not a GO
for q2 or for all Poisson provider rows.

**Next algebra gate after that q1 slope:** one ordinary correlated q2
intercept/slope block at fixed parameters. Test unequal group- and
coefficient-specific amplitudes against every entry of a hand-built
`D_g R_g D_g`, invert the member ordering, verify correlation preservation,
and show the base q2 fit is recovered when SD slopes are zero. Hold admission
until the native and Julia parameter maps each pass their own covariance
oracle. Structured providers then proceed one primitive/input and one block
shape at a time, with the non-unit-diagonal and mesh projection controls
above; a generic `D C D` proof alone is insufficient.
