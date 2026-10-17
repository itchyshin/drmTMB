# Random-effect SD target and covariance contract

Status: design contract for P1/P2; no new capability or inference claim. The
[finite universe](universe-contract.md) remains the admission denominator. This
document fixes the meaning of one `sd()` target before family-specific builders
or either engine implement it.

## One target, one latent axis

An `sd(group) ~ z` formula selects one **latent coefficient axis** of one
random-effect block. It does not select a response family, an observation-level
residual scale, a row of `X_mu`, or an arbitrary mesh vertex. The canonical
descriptor should be assembled from the existing block/member and structured
term metadata, then handed to both engine adapters:

| Descriptor field | Meaning and source |
| --- | --- |
| `target_id`, `block_id`, `member_id` | Stable identity within this fitted spec; registry `block_id0`/`member_id0` where present, otherwise a private equivalent for independent and structured terms. Never use the printed label as identity. |
| `group`, `level`, `provider`, `provider_instance` | Public group column; dependence level (`group`, `phylogenetic`, `spatial`, `animal`, `relmat`, temporal as admitted); actual primitive and object/term identity. `level` is a selector, not a substitute for provider identity. |
| `dpar`, `coef`, `block_label` | Existing endpoint, coefficient, and optional covariance-block label; keep `mu1` distinct from `mu2`, and an intercept distinct from a slope. |
| `axis_pos0`, `latent_pos0`, `obs_group_index0`, `group_levels` | Zero-based member position in the covariance block; latent parameter positions; observation-to-group indices; ordered group labels. Registry members already carry `coef_pos0`, `latent_index0` (the observation-to-group map), `group_levels`, and `design_value` (`R/drmTMB.R:16460–16488`). The global latent positions must be derived separately and validated against the actual parameter layout. |
| `Z_member`, `K_or_Q`, `A`, `normalization`, `scale_role`, `diagcov_mapping` | Observation random-regression design; the actual covariance or precision kernel, optional projection, current scale convention, whether the fitted SD is a raw kernel multiplier or marginal latent SD, and the mapping to the relevant covariance diagonal. These define *where* amplitude acts. Keep sparse matrices sparse. |
| `sd_row_index`, `sd_coef_index`, `engine_slot` | Separately: latent group/site to SD-design row, SD fixed coefficients `alpha`, and engine-specific latent/base-scale/correlation parameter positions and maps. The current ordinary builder already separates `row_index`, `coef_index`, and `re_sd_row0` (`R/drmTMB.R:17266–17410`). |

The registry's `members` and `pairs` (`R/drmTMB.R:16237–16488`) supply q>2
member identities and correlation edges. The q=1/2 ordinary and structured
paths need equivalent descriptors rather than pretending they appear in that
q>2 subset. A term with q>1 contributes one descriptor per coefficient axis;
the random-regression value `Z_member[i]` remains separate from the **group
predictor** `W[g,]` in `sd() ~ z`. Require `W` to be constant within each
retained latent group (or site) and align by label, never by first-row accident.
For a slope, its SD multiplies the latent slope coefficient *before* the
observation's slope design value is applied.

The resolver begins with all actual member descriptors for this spec, filters
by `group`, then by any supplied `level`, `dpar`, `coef`, and `block`; exactly one
candidate must remain. On zero or multiple candidates, report the candidate
tuples and a usable fully qualified `sd(group, dpar = ..., coef = ..., block =
..., level = ...)` example. An omitted `block` leaves labelled and unlabelled
candidates in play; a supplied `block` must match one label exactly. `sd1()`/`sd2()` and
`sd_phylo*()` are aliases resolved to the same descriptor, with existing
legacy naming retained for fitted objects. Two identical printed terms still
need distinct internal identities for fitting; if selectors cannot distinguish
two same-group, same-provider unlabelled instances, refuse the SD target,
list the candidates, and tell the user to add unique block labels. No new
identity syntax is required. The parser currently reserves these strings but
rejects explicit selectors and non-phylogenetic levels
(`R/parse-formula.R:554–710`); implementing this contract requires lifting
those *specific* gates and updating grammar/docs, without admitting a model
whose base effect is unsupported.

Keep four indices distinct: `axis_pos0` addresses a covariance member,
`latent_pos0` addresses random coefficients, `obs_group_index0` maps an
observation to its latent group, and `sd_row_index` addresses rows of `W`.
They are equal only by coincidence. `engine_slot` translates this
family-independent target to native TMB or Julia parameter names/maps and
report/prediction keys. Neither engine may infer a target from a printed
`sdpars` name after fitting. Prediction at known levels reuses the saved
factor coding and group order; an unknown level needs the established explicit
new-level policy, never a silently recycled SD row.

## Covariance and reported SD

Let `W_g alpha_a` be the log amplitude for axis `a` at group `g`, with
`tau_ga = exp(W_g alpha_a) > 0`. For an ordinary q-axis block, let `R` be its
existing positive-definite coefficient correlation matrix. At each group,
`B_g = D_g R D_g`, `D_g = diag(tau_g1,...,tau_gq)`. Existing correlation
parameters and predictor-varying q=2 correlation, where admitted, keep their
current interpretation; this contract adds no correlation regression. The
reported latent coefficient SD is `tau_ga` when `diag(R)=1`. A fixed-effects
formula on the response endpoint is not the SD formula, and a Bernoulli
response has no Gaussian residual `sigma` to reuse.

For a structured kernel `K` spanning groups and (possibly) coefficient axes,
the rule is `Cov(b) = D C D`, where `C` is the provider's *existing* base
covariance, including its current normalization and correlation block; `D`
contains the selected group-axis amplitudes and constant amplitudes for
unselected axes. In a separable case `C = K tensor R`; no separability is
assumed for an existing nonseparable provider. The marginal latent SD is
`sqrt(diag(D C D)) = tau_j sqrt(C_jj)`. It equals `tau_j` only if the
relevant base diagonal is one. The descriptor records `scale_role` and the
diagonal mapping so future inference cannot confuse a raw multiplier with
the marginal SD. Any public marginal-SD output waits for the P6 audit of
`predict_parameters()` and `VarCorr()` conventions. Setting all SD predictor
slopes to zero must reproduce the same base
model covariance and its normalization at the same intercept amplitude.

## Mesh: scale after projection

The current mesh source aligns sparse projection rows to retained model-row
IDs, sets `Q = kappa^4 c0 + 2 kappa^2 g1 + g2`, and validates `A` rows sum to
one (`R/drmTMB.R:14605–14656`). The TMB model currently has a raw node field
`u ~ N(0, sigma_raw^2 Q^-1)` and adds `A u` to `mu`
(`src/drmTMB.cpp:1157–1173`). `make_mesh()` constructs `A` from the supplied
observation locations (`R/mesh.R:96–130`). Its current `sdpars` entry is
explicitly the raw GMRF scale, not a constant projected marginal SD
(`R/drmTMB.R:22658–22668`). Existing mesh admission is a fixed-kappa Gaussian
`mu` intercept with `sigma ~ 1` and local-fit evidence, so the covariance
contract here does not promote its recovery or new-family support.

For `spatial(1 | site, mesh = mesh)` and fixed site covariates in
`sd(site) ~ z`, choose **site-level scaling of the projected field**. Let
`A_obs` be the retained observation-by-node projection, `g(i)` the site of
observation `i`, and `D_obs[i,i] = tau_{g(i)}`. Then the observation-level
latent covariance is

```
V_obs = D_obs A_obs Q^-1 A_obs' D_obs.
```

If every site has one projection row `A_site`, this reduces to
`V_site = D_site A_site Q^-1 A_site' D_site`, followed by the ordinary
site-to-observation incidence map. The site covariate must be constant among
retained observations of that site. Different `A_obs` rows within one site
remain admissible: the model is then a projected observation field with one
site-level multiplier, **not** a single shared site random intercept. The
current builder aligns model rows to projection rows but does not enforce
within-site equality, consistent with this interpretation. The descriptor
must retain observation/projection-row identity for its marginal-variance
mapping. No additional within-site projection constraint should be imposed
solely because an SD formula is present.

A two-row counterexample makes the distinction concrete. With `Q = I`,
`A_obs = rbind(c(1, 0), c(0.5, 0.5))`, one shared site, and `tau_site = 2`,
the two projected effects have variances 4 and 2 and covariance 2. They
cannot be represented by one site random-intercept value, yet the same
site-level SD predictor multiplies both rows coherently. The existing source
permits these distinct aligned `A` rows (`R/drmTMB.R:14605–14656`);
imposing a new equality check would break constant-SD equivalence.

Do not move `D` to the nodes. In general
`D_site A_site Q^-1 A_site' D_site` differs from
`A_site D_node Q^-1 D_node A_site'`; a site covariate need not exist at mesh
vertices, and projection and multiplication do not commute. Preserve sparse
`A` and `Q`; computing or storing dense `Q^-1` is only a tiny-test oracle.
For example, with the preceding `A`, `Q = I`, and two different observation
multipliers 2 and 3, `D_obs A A' D_obs` has off-diagonal 3, whereas choosing
node multipliers 2 and 3 gives `A D_node^2 A'` off-diagonal 2.
The raw intercept `tau = sigma_raw` preserves the current mesh amplitude:
`sigma_raw^2 A Q^-1 A'`. At observation/projection row `i`, the marginal
projected SD is `tau_{g(i)} sqrt((A_obs Q^-1 A_obs')_ii)`; it may differ
within a site. Existing `sdpars` continues to mean the raw kernel multiplier.
The descriptor's `diagcov_mapping` records the marginal transformation, with
no new public extractor until the P6 API audit. Do not renormalize `Q` or `A`
merely to make `tau` a marginal SD; that would change the existing baseline.

## Independent checks before P2 promotion

1. **Resolver and indexing:** construct two intercepts with the same group
   but different dpars, a labelled q=2 intercept/slope block, and a q>2 block.
   Exact selectors resolve one member and preserve its group levels, member
   order, latent positions, SD-design rows, and engine slots. Ambiguous bare
   `sd(group)` fails with listed candidates; bad selectors and duplicate indistinguishable
   terms fail before fitting. A slope's `Z` and the group's `W` stay separate.
2. **Ordinary covariance:** use a fixed q=2/4 valid `R` and unequal `tau`.
   Compare every diagonal and off-diagonal of `D_g R D_g` to an independent
   dense calculation, including a cross-dpar member. Confirm correlations are
   unchanged by positive scaling and zero SD slopes reproduce the base fit.
3. **Structured covariance:** on a tiny non-unit-diagonal `K`, compare
   `D C D` to a hand-constructed matrix; verify the descriptor's marginal-SD
   mapping gives `tau_j sqrt(C_jj)`, not `tau_j`. Permute named groups and jointly permute
   `K`, `W`, and incidence indices; likelihood/covariance must be invariant.
4. **Mesh projection:** with small positive-definite `Q` and nontrivial
   two-node interpolation rows, compare sparse-model covariance with dense
   `D_obs A Q^-1 A' D_obs`; check off-diagonals, not only diagonal values.
   Contrast a deliberately unequal `D_node` oracle to prove it is not the
   implemented model. Permute observation rows jointly in data and `A`, and
   repeat sites to check alignment and site covariate constancy. Constant
   `tau` must equal the current scalar mesh covariance, including its raw
   projected marginal variance. Two observations at the same site with
   different projection rows must remain admissible with one shared `tau_site`
   and generally different diagonal variances; equal rows recover a common
   site latent effect. Check both cases.
5. **Engine and family mapping:** serialize the descriptor and independently
   compare predicted log amplitudes, covariance entries, and group labels from
   native TMB and Julia at fixed parameters for each admitted mechanism.
   Family-specific likelihoods may differ, but target identity and Gaussian
   latent covariance cannot. Run negative controls where a response endpoint
   does not exist or its base random effect is not yet admitted.

These are mathematical and mapping tests, not recovery or interval calibration.
The latter remain mechanism-specific gates; low-information Bernoulli groups
cannot be rejected by a blanket `n_g = 1` rule without analyzing that exact
design and link.

## Load-bearing decisions before implementation

- Preserve multi-row-per-site mesh models. Document a single shared site
  random intercept only when projection rows agree; otherwise state the
  projected-field/site-multiplier interpretation in P2 user guidance.
- Audit `predict_parameters()` and `VarCorr()` in P6 before naming any new
  marginal-SD extractor; keep current mesh `sdpars` as the raw multiplier.
- Freeze provider/block identity when two same-group structured terms coexist.
  `level` alone is insufficient; `block` can select a labelled block. Refuse
  indistinguishable unlabelled instances and advise unique block labels.
- Inventory both engine adapters' real parameter/map slots and admitted base
  effects per frozen universe row. A common descriptor does not by itself
  create an unsupported family/endpoint/provider route.

## Ordinary resolver prototype receipt (2026-10-17)

The isolated internal module `R/random-effect-targets.R` now constructs one
ordinary member descriptor per parsed random-effect coefficient and resolves
`group`/`dpar`/`coef`/`block` selectors without changing model admission. Its
tests use the actual univariate and mixed-endpoint bivariate builders; a
simple `sd(group)` resolves any unique member, including a unique slope or
labelled member, while the existing fitting gates remain in force. Global
latent positions, observation-to-group indices, coefficient order, and q=2
pair metadata are checked separately.

The final hardening RED had four expected failures: pair indices redirected
to an equal-level axis with the wrong group or block, and incompatible current
or paired correlation IDs. After validating paired group/block identity and
the existing correlation-slot rules, this exact source-only command passed
56 assertions:

```
DRMTMB_SOURCE_ASSEMBLY=1 Rscript tools/general-sd-regression/run-source-tests.R tests/testthat/test-random-effect-targets.R
```

This is an identity/mapping receipt only. It does not exercise a fit, compiled
likelihood, admission on any new family or effect, or statistical calibration.
The next bounded integration candidate is to compare the resolver's selected
member with the current q=1 ordinary SD target at a builder point where both
parsed terms and the built random-effect structure are available (for example,
after `build_random_mu_structure()` and before `build_sd_mu_structure()` in
`R/drmTMB.R:4460–4475`). Keep the existing family and intercept/label fences,
and test identity parity before replacing any old parser path. Bivariate
integration needs its combined-registry call separately; neither integration
step is implemented by this prototype.
