# 248 — Structured zero-one-beta atom effects at q1: symbolic-alignment gate

**Status:** P0 symbolic gate. Written *before* implementation. Nothing in `src/` or `R/`
may be changed until this document is signed off, and the implementation plus its
oracle are both checked against §6.
**Scope:** `zero_one_beta()` = `model_type 15`, structured random effects on the two
atom dpars `zoi` and `coi`, at **q1 only**.
**Ground-truthed:** 2026-08-02 against `src/drmTMB.cpp`, `src/drm_numeric.h`,
`R/drmTMB.R`, `R/control.R`, `tests/testthat/test-zero-one-beta.R`. Line numbers drift;
re-grep before editing.
**Author:** Noether (math↔engine contract). **§2.4 table recomputed and corrected by the
orchestrator, 2026-08-02** — see the correction note in §2.4.

The bug this gate exists to prevent: the current structured dispatch in block 15 is a
**binary** test with a catch-all `else` (`src/drmTMB.cpp:3085-3089`). Adding an atom
endpoint without making that dispatch exhaustive produces a model that routes a `zoi`
structured effect onto `eta_mu`, converges cleanly, reports `conv = 0` and
`pdHess = TRUE`, and is the wrong model. See §3.3.

---

## 1. The likelihood, symbolically

### 1.1 Support and data

Response `y_i ∈ [0, 1]`, closed interval, enforced at `R/drmTMB.R:15911-15916`. At least
one strictly interior value `0 < y_i < 1` is required (`R/drmTMB.R:15917-15923`), because
the interior block is the only source of information on `mu` and `sigma` (§2).

Prior weights `w_i` are data (`weights`), applied multiplicatively to the observation
log-density only — never to the GMRF prior (§3.2).

Rows with `observed_y(i) == 0` contribute nothing (`src/drmTMB.cpp:3145`).

### 1.2 Linear predictors

```
eta_mu    = X_mu    beta_mu        src/drmTMB.cpp:3004
lambda    = X_sigma beta_sigma     src/drmTMB.cpp:3005   (lambda == log_sigma)
eta_zoi   = X_zi    beta_zoi       src/drmTMB.cpp:3006   (X_zi holds the zoi design)
eta_coi   = X_nu    beta_coi       src/drmTMB.cpp:3007   (X_nu holds the coi design)
```

The slot reuse is set on the R side at `R/drmTMB.R:19123-19124`:
`X_zi = spec$X$zoi`, `X_nu = spec$X$coi`. **This is storage aliasing only.** See §4.

Ordinary (i.i.d.) random effects are added to all four predictors before any transform,
in the standardized `sd * u`, `u ~ N(0, I)` form:

```
eta_mu(i)   += mu_re_value(i,j)   * exp(log_sd_mu(term))    * u_mu(idx)     :3013-3014
lambda(i)   += sigma_re_value(i,j)* exp(log_sd_sigma(term)) * u_sigma(idx)  :3031-3033
eta_zoi(i)  += zoi_re_value(i,j)  * exp(log_sd_zoi(term))   * u_zoi(idx)    :3050-3051
eta_coi(i)  += coi_re_value(i,j)  * exp(log_sd_coi(term))   * u_coi(idx)    :3068-3069
```
each with `-sum(dnorm(u, 0, 1, log))` added to the nll (`:3018, :3037, :3055, :3073`).

Structured effects are added next, in a **centered** form (§3.1) — different from the
above. Order matters: all contributions land before the transforms of §1.3.

### 1.3 Transforms

Let `sigmoid(x) = 1/(1 + exp(-x))`.

**Mean, with an epsilon compression** (`src/drmTMB.cpp:3107-3113`), `eps = 1e-12`:

```
mu_i = eps + (1 - 2 eps) * exp(drm_log_inv_logit(eta_mu_i))
```
`drm_log_inv_logit(x) = -logspace_add(0, -x)` (`src/drm_numeric.h:38-41`), i.e. exactly
`log sigmoid(x)`. Plain equivalent:
```
mu_i = eps + (1 - 2 eps) * sigmoid(eta_mu_i),   mu_i in [eps, 1 - eps]
```
**The fitted mean is the compressed value, not `sigmoid(eta_mu)`.** Any oracle must
apply the same compression (§5, and §7 finding F6).

**Scale, with a soft clamp** (`src/drmTMB.cpp:3114-3118`), applied to `lambda` *after*
every random and structured contribution:

```
lambda_i <- S(lambda_i; lo, hi, m)   if use_logsigma_clamp == 1
sigma_i   = exp(lambda_i)
```
with (`src/drmTMB.cpp:27-32`)
```
S(x) = hi + m*tanh((x - hi)/m)   if x > hi
     = lo - m*tanh((lo - x)/m)   if x < lo
     = x                          otherwise
```
**The clamp is ON by default**: `drm_control()` defaults `logsigma_clamp = c(-12, 12)`,
`logsigma_clamp_margin = 3` (`R/control.R:134-135`), and `R/drmTMB.R:493-503` sets
`use_logsigma_clamp <- 1L` for any non-`NULL` band. An oracle that omits `S` is testing
a different function (§7 finding F5).

**Atoms** (`src/drmTMB.cpp:3119-3120` for reporting; `3126-3129` for the likelihood):

```
zoi_i = sigmoid(eta_zoi_i)
coi_i = sigmoid(eta_coi_i)
```
The likelihood does **not** use those vectors. It uses the stable logs
```
log_zoi_i           = -logspace_add(0, -eta_zoi_i)   == log sigmoid(eta_zoi_i)
log_one_minus_zoi_i = -logspace_add(0,  eta_zoi_i)   == log(1 - sigmoid(eta_zoi_i))
log_coi_i           = -logspace_add(0, -eta_coi_i)   == log sigmoid(eta_coi_i)
log_one_minus_coi_i = -logspace_add(0,  eta_coi_i)   == log(1 - sigmoid(eta_coi_i))
```
There is no epsilon compression and none is needed: `logspace_add` returns a finite value
for every finite `eta`, so the log-atom terms never overflow. (The *reported* `zoi`/`coi`
at `3119-3120` can overflow; §7 finding F4.)

**Beta reparameterization** (`src/drmTMB.cpp:3124`, `3130-3144`), floor `c = 1e-8`:

```
phi_i   = exp(-2 * lambda_i)                 == 1 / sigma_i^2
alpha_i = max(mu_i * phi_i,       c)
beta_i  = max((1 - mu_i) * phi_i, c)
```
The `max` is `CppAD::CondExpLt`, i.e. exactly `pmax`. Note that flooring is applied to
each shape *independently*, so when a floor binds `alpha_i + beta_i != phi_i` and
`alpha_i/(alpha_i + beta_i) != mu_i` (§7 finding F3).

### 1.4 The three-branch mixture

With `b_i = 1{y_i in {0,1}}` (boundary indicator) and `t_i = 1{y_i = 1}` (one-inflation
indicator), the density is

```
f(y_i) =  zoi_i * (1 - coi_i)                      if y_i = 0
       =  zoi_i * coi_i                            if y_i = 1
       = (1 - zoi_i) * Beta(y_i; alpha_i, beta_i)  if 0 < y_i < 1
```

**Normalizing constant.** `zoi(1-coi) + zoi*coi + (1-zoi) * INT_0^1 Beta = zoi + (1-zoi) = 1`.
The mixture is exactly normalized **provided no shape floor binds**; when a floor binds the
Beta component is still a proper density (so total mass remains 1) but of a different
`(mu, phi)` than the one reported.

**As implemented** (`src/drmTMB.cpp:3145-3163`), the contribution to `nll` is
`-w_i * log f(y_i)` with

```
y_i <= 0 : log f = log_zoi_i + log_one_minus_coi_i                         :3146-3149
y_i >= 1 : log f = log_zoi_i + log_coi_i                                   :3150-3153
else     : log f = log_one_minus_zoi_i
                 + lgamma(alpha_i + beta_i) - lgamma(alpha_i) - lgamma(beta_i)
                 + (alpha_i - 1) * log(y_i)
                 + (beta_i  - 1) * log(1 - y_i)                            :3154-3161
```

Two notes on the branch test. It is `y <= 0` / `y >= 1`, not `y == 0` / `y == 1`; the two
coincide only because `prepare_zero_one_beta_response()` rejects out-of-range values
(`R/drmTMB.R:15911-15916`). And `asDouble(y(i))` is legitimate here because `y` is
`DATA_VECTOR`, so the branch carries no derivative.

The total negative log-likelihood is
```
nll = -SUM_i 1{observed_y_i = 1} * w_i * log f(y_i)
      + SUM_(iid RE blocks) -sum dnorm(u, 0, 1, log)
      + GMRF prior term  (§3.2)
```

---

## 2. The information structure

**This is the load-bearing section.** It determines what a q1 atom slice can and cannot
demonstrate, and it must be read before any simulation design is written.

### 2.1 The likelihood factorizes into three orthogonal blocks

Substituting the branch definitions into §1.4 and collecting terms:

```
l = SUM_i w_i [ b_i log zoi_i + (1 - b_i) log(1 - zoi_i) ]           (Z)  all n rows
  + SUM_i w_i b_i [ t_i log coi_i + (1 - t_i) log(1 - coi_i) ]       (C)  boundary rows only
  + SUM_i w_i (1 - b_i) log Beta(y_i; alpha_i, beta_i)               (B)  interior rows only
```

Block **(Z)** is exactly a weighted Bernoulli logistic likelihood for the *boundary
indicator* `b_i`, on all `n` rows.
Block **(C)** is exactly a weighted Bernoulli logistic likelihood for the *which-boundary*
indicator `t_i`, on the `n_B = SUM_i b_i` boundary rows only.
Block **(B)** is the beta likelihood on the `n - n_B` interior rows only.

Given the data, `(Z)`, `(C)` and `(B)` share no parameters. Hence
```
d^2 l / d beta_zoi d beta_coi  = 0
d^2 l / d beta_zoi d beta_mu   = d^2 l / d beta_zoi d beta_sigma = 0
d^2 l / d beta_coi d beta_mu   = d^2 l / d beta_coi d beta_sigma = 0
```
exactly, not approximately. **The observed Hessian is block-diagonal across
`(beta_zoi) | (beta_coi) | (beta_mu, beta_sigma)`.** A structured effect on one atom
cannot borrow information from any other dpar.

### 2.2 Why coi is absent from the interior density

The interior branch is `(1 - zoi_i) * Beta(y_i; alpha_i, beta_i)`. `coi` appears nowhere
in it: `alpha_i` and `beta_i` are functions of `mu_i` and `phi_i` only
(`src/drmTMB.cpp:3131-3132`), and the mixing weight is `1 - zoi_i`. Therefore

```
d/d eta_coi_i  log f(y_i) = 0   for every i with 0 < y_i < 1
```

This is a structural zero, not a small number. **coi is informed by exactly the boundary
rows, and by nothing else.** By contrast `zoi` appears in every branch — as `log zoi` on
the boundary and as `log(1 - zoi)` in the interior — so all `n` rows carry `zoi` information.

### 2.3 Expected information for a single intercept

For an intercept-only atom, with `zoi_i = zoi` and `coi_i = coi` constant:

```
I_zoi = SUM_i w_i * zoi * (1 - zoi)
I_coi = SUM_i w_i * zoi * coi * (1 - coi)      [ = E over b_i of the Bernoulli info ]
```
The `coi` information carries the factor `zoi` that the `zoi` information does not.
**Effective sample size for coi is `n * zoi`.** With `zoi = 0.1`, a `coi` intercept has the
precision of a Bernoulli GLM on one tenth of the data. Any test designed for `zoi` and
reused for `coi` at the same `n` is under-powered by that factor.

### 2.4 Identifiability of a latent SD on each atom

Partition the rows into `m` groups (tips, sites, individuals) indexed by
`phylo_mu_node_index`. Let group `g` have `n_g` rows and `k_g` boundary rows, so
`k_g ~ Binomial(n_g, zoi)`.

**Uninformative groups (coi).** If `k_g = 0` the group contributes nothing to block (C).
Its latent value `u_g` is then informed only by the GMRF prior. Probability:
```
P(k_g = 0) = (1 - zoi)^{n_g}
```
For `zoi`, no group is ever uninformative: every row is a Bernoulli trial for block (Z).

**Complete separation (coi), per group.** Given `k_g = k >= 1`, block (C) in group `g` is
`Binomial(k, coi_g)`. The group is completely separated — the within-group MLE of
`eta_coi_g` is at `+/- infinity` — iff all `k` boundary rows fall on the same side:
```
P(separated | k_g = k) = coi^k + (1 - coi)^k
```
Note `P(separated | k = 1) = 1`: a group with a single boundary observation is *always*
separated. Marginalizing over `k_g ~ Binomial(n_g, zoi)` gives the closed form
```
P(no y = 1 in g) = (1 - zoi * coi)^{n_g}
P(no y = 0 in g) = (1 - zoi * (1 - coi))^{n_g}

P(g separated or uninformative) = (1 - zoi*coi)^{n_g}
                                + (1 - zoi*(1 - coi))^{n_g}
                                - (1 - zoi)^{n_g}
```
(the `k = 0` event is counted in both leading terms, so it is subtracted once).

**Complete separation (zoi), per group:** `P = zoi^{n_g} + (1 - zoi)^{n_g}`, negligible for
moderate `n_g` and `zoi` away from 0 and 1.

> **CORRECTION NOTE (orchestrator, 2026-08-02).** The closed forms above are correct and were
> re-derived independently. The *numeric table* in the first draft of this document was wrong
> in four of five rows, by up to two orders of magnitude, and every error ran in the
> optimistic direction. The draft's design rule — *"set `zoi >= 0.25` so that fewer than 1% of
> groups are separated or empty"* — is **false**: at `zoi = 0.25, coi = 0.5, n_g = 30` the true
> rate is **3.6%**, not 0.33%. The table below is recomputed from the closed forms. Do not
> reuse any figure from the superseded draft.

**Corrected table** — `P(group separated or uninformative)`, coi arm:

| `zoi` | `coi` | `n_g` | `P(k_g = 0)` | `P(sep or uninformative)`, coi | `P(sep)`, zoi |
|---|---|---|---|---|---|
| 0.10 | 0.50 | 10 | 0.3487 | **0.8488** | 0.3487 |
| 0.10 | 0.50 | 30 | 0.0424 | **0.3869** | 0.0424 |
| 0.25 | 0.50 | 30 | 1.79e-4 | **0.0362** | 1.79e-4 |
| 0.40 | 0.50 | 30 | 2.21e-7 | **0.0025** | 2.21e-7 |
| 0.10 | 0.20 | 30 | 0.0424 | **0.5851** | 0.0424 |

**Corrected design guidance.** Two separate facts matter, and the second is the one that
bites:

1. *At `coi = 0.5`* (the most favourable case), reaching <1% separated-or-uninformative at
   `n_g = 30` needs **`zoi >= 0.35`**, not 0.25. Equivalently, at `zoi = 0.25` you need
   **`n_g >= 40`**; at `zoi = 0.15`, `n_g >= 68`.
2. *Extreme `coi` is the binding constraint, and `zoi` cannot fix it.* Taking the worst case
   over `coi ∈ {0.1 … 0.9}` at `n_g = 30`, the rate is **46.8% at `zoi = 0.25`** and still
   **15.6% at `zoi = 0.60`**. Raising `zoi` has strongly diminishing returns because the
   `coi^k` term dominates once `coi` is far from 0.5. To get <1% at `coi = 0.2` you need
   `n_g >= 90` at `zoi = 0.25`, or `n_g >= 44` at `zoi = 0.50`.

So a recovery DGP for the `coi` cells must fix **both** a healthy boundary mass and a
`coi` near 0.5, or else raise `n_g` substantially. A DGP that only raises `zoi` while
leaving `coi` extreme will still separate a large fraction of groups.

**Consequence for this slice.** A GMRF prior means separation is not a hard failure — the
prior supplies the missing curvature, so the fit converges. It does mean the *data*
contribution to `log_sd` from a separated or empty group is zero, so `log_sd_phylo` for a
`coi` effect is estimated from far fewer effective units than the tip count suggests. This
is why the recovery gate must count separated groups directly rather than trusting an
aggregate `tau_hat`.

---

## 3. Carrier and routing specification

### 3.1 The carrier

Per observation `i`, the structured contribution is a scalar

```
v_i = phylo_mu_value(i, 0) * u(node_index_i),   node_index_i = phylo_mu_node_index(i)
```
exactly as at `src/drmTMB.cpp:3084`. For an unlabelled q1 intercept `phylo_mu_value(i,0) == 1`.

```
u ~ N_m(0, sd_u^2 * Q^{-1}),    m = Q_phylo.rows()  (src/drmTMB.cpp:3082)
```
`Q = Q_phylo` and `log|Q| = log_det_Q_phylo` are supplied as **data**; the provider
(`phylo`, `animal`, `relmat`, `spatial`, `phylo_interaction`) determines them and nothing
else about this specification.

**Parameterization note — this differs from the ordinary RE blocks.** `u_phylo` is
*centered*: it carries the SD itself, and `sd_u = exp(log_sd_phylo(0))` appears only in the
prior. The ordinary blocks at `3013-3014`, `3050-3051`, `3068-3069` are *non-centered*:
`u ~ N(0, I)` and the SD multiplies in the predictor. Both are correct; they are not
interchangeable, and an oracle must use whichever the block it is testing uses.

### 3.2 The GMRF prior

```
nll += 0.5 * ( m * log(2*pi) + 2 * m * log_sd_phylo(0) - log_det_Q_phylo
             + exp(-2 * log_sd_phylo(0)) * u' Q u )
```
exactly as at `src/drmTMB.cpp:3092-3098`. **The prior is never weighted by `w_i`.**
This is the correct `-log N(u; 0, sd^2 Q^{-1})` because
`log det(sd^2 Q^{-1}) = 2 m log sd - log|Q|`.

### 3.3 The required dispatch — exhaustive, with an error on unknown codes

The contribution `v_i` must land on **exactly one** endpoint, before the transforms of §1.3:

| code | endpoint | statement | current site |
|---|---|---|---|
| 0 | `mu` | `eta_mu(i) += v_i` | `src/drmTMB.cpp:3088` |
| 1 | `sigma` | `log_sigma(i) += v_i` | `src/drmTMB.cpp:3086` |
| 5 | `zoi` | `eta_zoi(i) += v_i` | **new** |
| 6 | `coi` | `eta_coi(i) += v_i` | **new** |
| any other | — | **error** | **new** |

The required shape is a total function, not a defaulted test:

```
code = phylo_mu_dpar(0)
if      code == 0 : eta_mu(i)    += v_i
else if code == 1 : log_sigma(i) += v_i
else if code == 5 : eta_zoi(i)   += v_i
else if code == 6 : eta_coi(i)   += v_i
else              : ERROR("zero_one_beta: unsupported structured endpoint code")
```

**What goes wrong if the `else` catch-all at `src/drmTMB.cpp:3087-3089` is left in place.**
The current code is `if (phylo_mu_dpar(0) == 1) { log_sigma += } else { eta_mu += }`. It
does not test for `mu`; it tests for *not sigma*. The moment `phylo_mu_dpar_codes()` can
emit 5 or 6 (§4), a `phylo(1 | species)` term written in the `zoi` formula is added to
`eta_mu`. The consequences, in order of how hard they are to notice:

- The fit converges. No dimension mismatch, no `NaN`, no `MakeADFun` abort. `conv = 0`,
  `pdHess = TRUE`.
- `log_sd_phylo` is estimated — but as a *mean-side* phylogenetic SD, which the user reads
  as an atom-side SD.
- `beta_zoi` is estimated with no random effect, so its standard error is the
  no-random-effect one: too small, in a way that looks like a precise result.
- Because the blocks are exactly orthogonal (§2.1), there is no cross-term to make the
  misrouting visible in any diagnostic. Nothing in `check_drm()` can see it.
- **A recovery test would appear to fail on `log_sd_phylo`, and the natural diagnosis
  ("the atom SD is weakly identified — see §2.4") is exactly the wrong one and is
  independently true.** The two failure modes are confusable. This is why the exhaustive
  dispatch must land *before* any structured simulation is run.

The same latent defect exists in the other blocks (`src/drmTMB.cpp:2421-2423`,
`3605-3607`, `3962-3964`). Adding codes 5/6 to the shared vocabulary makes them reachable
there too. **Every `else` catch-all in a structured dispatch must become an explicit error
in the same change.** This is not scope creep; it is the cost of extending the vocabulary.

### 3.4 q1 guard in C++

Block 15 is written for `q = 1` only: no loop over `k`, `phylo_mu_value(i, 0)` at `3084`,
`u_phylo(phylo_mu_node_index(i))` with no `k * n_phylo` stride, `phylo_mu_dpar(0)` at
`3085`, `log_sd_phylo(0)` at `3096-3097`, quadratic form summed over `j < n_phylo` at
`3093`. Contrast `2413-2416`, `3599-3602`, `3956-3959`, which loop and stride. With `q = 2`
the second field would receive neither a likelihood contribution nor a prior — an
unpenalized free vector, and a wrong Laplace marginal. The only guard today is R-side
(`R/drmTMB.R:9807`). **The C++ must assert `log_sd_phylo.size() == 1` and
`u_phylo.size() == Q_phylo.rows()` in block 15**, or a future R-side relaxation silently
produces that free vector.

---

## 4. The code vocabulary

### 4.1 Current state

```r
# R/drmTMB.R:11370-11382
phylo_mu_dpar_codes <- function(phylo_mu) {
  family <- sub("[0-9]+$", "", phylo_mu_endpoint_dpars(phylo_mu))
  codes <- match(family, c("mu", "sigma", "nu", "zi", "hu")) - 1L
  ...
}
```
so `mu = 0`, `sigma = 1`, `nu = 2`, `zi = 3`, `hu = 4`. `zoi` and `coi` are absent and
would raise the internal-error abort at `R/drmTMB.R:11376-11380`. The codes travel to TMB
via `R/drmTMB.R:18360-18364` into `DATA_IVECTOR(phylo_mu_dpar)` (`src/drmTMB.cpp:385`).

### 4.2 Recommendation: new codes, `zoi = 5`, `coi = 6`

```r
codes <- match(family, c("mu", "sigma", "nu", "zi", "hu", "zoi", "coi")) - 1L
```

**Why not alias `zoi -> 3` (`zi`) and `coi -> 2` (`nu`), given the design-matrix reuse?**
The `X_zi`/`X_nu` reuse (`R/drmTMB.R:19123-19124`) is a *storage* decision: ZOB borrows two
otherwise-idle matrix slots. It carries no semantic content. The parameters are distinct:
`zi` in `model_type 8` is the mixing weight of a degenerate-at-zero component of a **count**
distribution, while `zoi` is the probability that a **continuous proportion** lands on the
closed boundary `{0,1}`; `nu` in `model_type 3` is the Student-t degrees of freedom, while
`coi` is a conditional Bernoulli probability.

**Risks of aliasing, concretely.**

1. `phylo_mu_dpars()` returns *names*, which are printed. Aliasing makes `summary()`,
   `check_drm()` and the structured-effect extractors report `zi`/`nu` for a model the user
   wrote with `zoi`/`coi` (`R/methods.R:264`, `:285`, `:2753`; `R/check.R:3460`, `:3534`),
   violating the project rule that public dpar names are the API.
2. Code 3 already means "route to `eta_zi`" (`src/drmTMB.cpp:3603`) and code 2 "route to
   `eta_nu`" (`:2417`). If the dispatch is ever hoisted into a shared helper — the obvious
   refactor once four blocks need it — an aliased ZOB code would be resolved against the
   wrong endpoint, compile-legally.
3. Aliasing makes `zoi`-vs-`zi` indistinguishable in any cross-family audit of
   `phylo_mu_dpar`, so a future misrouting could not be detected by inspecting the data object.

**Cost of new codes, stated honestly.** Codes 5 and 6 become emittable, so every existing
`else` catch-all becomes reachable by a code it cannot interpret — which is precisely why
§3.3 requires all four dispatches to become exhaustive in the same change. The alternative,
aliasing to keep the catch-alls safe, buys safety by making the model wrong in a way that
prints correctly. That is strictly worse.

**Compatibility checks performed.** `sub("[0-9]+$", "", ...)` (`R/drmTMB.R:11374`) leaves
`"zoi"`/`"coi"` unchanged. `phylo_mu_response_codes()` (`:11388`) strips a leading
`mu|sigma`; both survive intact, `as.integer` yields `NA`, mapped to `0L` at `:11390` —
correct for a univariate family. `R/drmTMB.R:2282-2283` tests `all(codes == 1L)` for the
REML scale-side-only route, so codes 5/6 fall outside it and REML for atom endpoints must
be decided explicitly (open question, out of scope).

---

## 5. The oracle contract

An independent dense-R oracle must reproduce the *joint* negative log-likelihood at a given
`(theta, u)` — what TMB's `obj$env$f(par)` returns before Laplace integration — to `1e-8`.

**The oracle must be written from §1 and §3 of this document. It must not be
reverse-engineered from `src/drmTMB.cpp`.** If the oracle author transcribes the C++, a
shared derivation error (a wrong sign in the log-determinant, a missing `2*m*log_sd`, a
`coi` term leaking into the interior branch) reproduces identically on both sides and passes
a `1e-8` check while both are wrong. Agreement between two transcriptions of one source is
not evidence.

### 5.1 Structured `zoi` oracle

```
u        = par$u_phylo                       (length m)
Q, logdetQ from the provider, built densely in R
node_i   = observation node index (1-based; check against tmb_data$phylo_mu_node_index + 1)

eta_mu    = X_mu    %*% beta_mu
log_sigma = X_sigma %*% beta_sigma
eta_zoi   = X_zi    %*% beta_zoi + phylo_mu_value[, 1] * u[node]     <-- carrier here
eta_coi   = X_nu    %*% beta_coi

mu        = 1e-12 + (1 - 2e-12) * plogis(eta_mu)
if (use_logsigma_clamp == 1) log_sigma = S(log_sigma; band)
sigma     = exp(log_sigma)
phi       = 1 / sigma^2
alpha     = pmax(mu * phi,       1e-8)
beta      = pmax((1 - mu) * phi, 1e-8)
zoi       = plogis(eta_zoi);  coi = plogis(eta_coi)

logf[y == 0]        = log(zoi) + log1p(-coi)
logf[y == 1]        = log(zoi) + log(coi)
logf[0 < y & y < 1] = log1p(-zoi) + dbeta(y, alpha, beta, log = TRUE)

prior = 0.5 * ( m*log(2*pi) + 2*m*log_sd_phylo - logdetQ
              + exp(-2*log_sd_phylo) * as.numeric(t(u) %*% Q %*% u) )

nll = prior - sum(weights * logf)
```

### 5.2 Structured `coi` oracle

Identical, with the carrier moved:
```
eta_zoi = X_zi %*% beta_zoi
eta_coi = X_nu %*% beta_coi + phylo_mu_value[, 1] * u[node]          <-- carrier here
```

### 5.3 Mandatory oracle checks

1. **Node-index bijection.** `expect_equal(tmb_data$phylo_mu_node_index + 1L, unname(node))`,
   as at `tests/testthat/test-zero-one-beta.R:301`, `:313`, `:323`, `:332`, `:352`, `:367`,
   `:393`, `:405`, `:419`, `:431`. The only check that catches a permuted design.
2. **Apply the soft clamp conditionally**, following `zoib_zoi_random_intercept_nll`
   (`:467-469`), *not* the sigma-structured oracles at `:309-319`, `:321-328`, `:330-337`,
   `:402-410`, `:427-436`, which omit it (§7 finding F5).
3. **Apply the `beta_mu_eps` compression**, following `:303`/`:316`, not `:448` (finding F6).
4. **Provider log-determinant sign.** The prior uses `-log|Q|`; with `Q = solve(K)` that is
   `+log|K|` (`:335`, `:372-373`), with `Q = Ainv` it is `-log|Ainv|` (`:326`, `:357-359`).
   Getting this backwards shifts the nll by a constant a gradient check cannot detect — so
   **check the value, not only the gradient**.
5. **Endpoint-swap negative control.** Fit the `zoi` structured model, then evaluate the
   *`mu`-carrier* oracle at the same parameter vector. The two must **disagree**. If they
   agree, the dispatch is routing to `eta_mu` (§3.3) and every other test in the file is
   vacuous. This is the only direct test of the routing and it must be present.
6. **Central-difference gradient** at a non-optimal `par`, per `zoib_phylo_central_gradient`
   (`:339-347`), to catch a carrier sign error that a value check at a symmetric point misses.

---

## 6. Alignment table

| symbol | meaning | R-side name | TMB name | file:line |
|---|---|---|---|---|
| `y_i` | response in `[0,1]` | `spec$y` / `tmb_data$y` | `y(i)` | `R/drmTMB.R:15911`; `src/drmTMB.cpp:3146` |
| `w_i` | prior weight | `tmb_data$weights` | `weights(i)` | `src/drmTMB.cpp:3147,3151,3161` |
| `o_i` | observed-response flag | `tmb_data$observed_y` | `observed_y(i)` | `src/drmTMB.cpp:3145` |
| `eta_mu` | mean linear predictor | `X_mu %*% beta_mu` | `eta_mu` | `src/drmTMB.cpp:3004` |
| `lambda` | log residual scale | `X_sigma %*% beta_sigma` | `log_sigma` | `src/drmTMB.cpp:3005` |
| `eta_zoi` | boundary-inflation predictor | `X_zi %*% beta_zoi` | `eta_zoi` | `src/drmTMB.cpp:3006`; `R/drmTMB.R:19124` |
| `eta_coi` | conditional-one predictor | `X_nu %*% beta_coi` | `eta_coi` | `src/drmTMB.cpp:3007`; `R/drmTMB.R:19123` |
| `beta_zoi` | zoi coefficients | `par$beta_zoi` | `beta_zoi` | `src/drmTMB.cpp:431` |
| `beta_coi` | coi coefficients | `par$beta_coi` | `beta_coi` | `src/drmTMB.cpp:432` |
| `eps` | mean compression, `1e-12` | hard-coded in oracles | `beta_mu_eps` | `src/drmTMB.cpp:3108` |
| `mu_i` | compressed mean | `1e-12+(1-2e-12)*plogis(eta_mu)` | `mu(i)` | `src/drmTMB.cpp:3110-3112` |
| `S(.)` | log-sigma soft clamp | `softclamp_logsigma_drm` | `drm_softclamp_log_sigma` | `tests/testthat/test-zero-one-beta.R:50-57`; `src/drmTMB.cpp:27-32,3114-3117` |
| `(lo,hi,m)` | clamp band + margin | `control$logsigma_clamp`, `_margin` | `logsigma_clamp(0..2)` | `R/control.R:134-135`; `R/drmTMB.R:493-503` |
| `phi_i` | beta precision `= sigma^-2` | `1/sigma^2` | `phi(i)` | `src/drmTMB.cpp:3130` |
| `c` | shape floor, `1e-8` | `pmax(., 1e-8)` | `beta_shape_floor` | `tests/testthat/test-zero-one-beta.R:32-33`; `src/drmTMB.cpp:3124` |
| `alpha_i` | first beta shape | `shape1` | `alpha(i)` | `src/drmTMB.cpp:3131,3133-3138` |
| `beta_i` | second beta shape | `shape2` | `beta_shape(i)` | `src/drmTMB.cpp:3132,3139-3144` |
| `zoi_i` | boundary probability | `plogis(eta_zoi)` | `zoi(i)` (report) / `log_zoi` (llh) | `src/drmTMB.cpp:3119`, `3126-3127` |
| `coi_i` | P(y=1 given boundary) | `plogis(eta_coi)` | `coi(i)` (report) / `log_coi` (llh) | `src/drmTMB.cpp:3120`, `3128-3129` |
| `b_i` | boundary indicator | `y == 0 or y == 1` | `y(i) <= 0 or y(i) >= 1` | `src/drmTMB.cpp:3146,3150` |
| `t_i` | one-vs-zero indicator | `y == 1` | `y(i) >= 1` | `src/drmTMB.cpp:3150` |
| `u` | structured latent field (centered) | `par$u_phylo` | `u_phylo` | `src/drmTMB.cpp:3084` |
| `m` | field dimension | `nrow(Q)` | `n_phylo = Q_phylo.rows()` | `src/drmTMB.cpp:3082` |
| `Q` | provider precision | `precision$Q` | `Q_phylo` | `tests/testthat/test-zero-one-beta.R:291`; `src/drmTMB.cpp:3091` |
| `log|Q|` | log-determinant (data) | `precision$log_det` | `log_det_Q_phylo` | `tests/testthat/test-zero-one-beta.R:292`; `src/drmTMB.cpp:3096` |
| `sd_u` | structured SD | `exp(par$log_sd_phylo)` | `exp(log_sd_phylo(0))` | `src/drmTMB.cpp:3097,3103` |
| `x_i` | carrier value | `phylo_mu_value[, 1]` | `phylo_mu_value(i, 0)` | `src/drmTMB.cpp:3084` |
| `node_i` | 0-based node index | `phylo_mu_node_index + 1L` | `phylo_mu_node_index(i)` | `src/drmTMB.cpp:3084`; test `:301` |
| `code` | endpoint code | `phylo_mu_dpar_codes()` | `phylo_mu_dpar(0)` | `R/drmTMB.R:11370-11382`; `src/drmTMB.cpp:385,3085` |
| `u_zoi` | i.i.d. zoi RE (non-centered) | `par$u_zoi` | `u_zoi` | `src/drmTMB.cpp:455,3051` |
| `u_coi` | i.i.d. coi RE (non-centered) | `par$u_coi` | `u_coi` | `src/drmTMB.cpp:457,3069` |

**Parameter-scale audit.** All positive parameters are on an unconstrained log scale
(`log_sigma`, `log_sd_*`); all probabilities on an unconstrained logit scale (`eta_mu`,
`eta_zoi`, `eta_coi`). No correlation parameter exists in this slice. Nothing in block 15 is
bounded in the optimizer.

**Reparameterization audit.** Two transforms change the likelihood value and must be
mirrored in the oracle: the `beta_mu_eps` compression (relative `2e-12`), and the log-sigma
soft clamp (identity inside the band). Neither is a pure reparameterization. `phi = sigma^-2`
and `(mu, phi) -> (alpha, beta)` are exact bijections on the unfloored region. The shape
floor is *not* a reparameterization — see F3.

---

## 7. Findings — where the code and the mathematics disagree

Recorded, not fixed, per the scope fence. Each is a candidate for its own slice.

**F1 — the binary dispatch with a catch-all `else` (`src/drmTMB.cpp:3085-3089`).** Not a
code→endpoint function; a "not sigma" test. Must become exhaustive with an explicit error
before codes 5/6 exist. Same defect at `2421-2423`, `3605-3607`, `3962-3964`. Consequences
in §3.3. **Blocking for this slice.**

**F2 — block 15's structured code is q1-only with no C++ guard.** `3081-3106` versus the
looping form at `2413-2416`. With `q = 2` the second field receives neither likelihood nor
prior. Guarded only by `R/drmTMB.R:9807`. **Add the assertion now.**

**F3 — the shape floor substitutes a model rather than penalizing.** `3124`, `3133-3144`.
`alpha` and `beta` are floored independently, so when a floor binds `alpha + beta != phi` and
`alpha/(alpha+beta) != mu`: the reported `mu`/`sigma` (`REPORT` at `3165`, `3167`) do not
parameterize the density evaluated. Because `CondExpLt` returns a constant in the floored
region, `d(logf)/d(beta_mu) == 0` exactly — a flat plateau, not a barrier, on which the
optimizer can stop and report convergence. Pre-existing, shared with `model_type 10`.
Relevant here because atom effects shrink the interior sample.

**F4 — reported `zoi`/`coi` use the unstable form.** `3119-3120` computes `1/(1+exp(-eta))`
directly; for `eta < -709` this overflows and reports exactly `0`. The likelihood is safe
(`3126-3129`), and `mu` got the stable treatment (`3110` via `src/drm_numeric.h:38-41`), but
the atoms did not. Reporting-only — yet a reported `zoi = 0` is exactly what a diagnostic
would read as a degenerate fit.

**F5 — the sigma-structured oracles omit the soft clamp, which is on by default.**
`R/control.R:134` defaults the band to `c(-12,12)`, so `R/drmTMB.R:493-503` sets
`use_logsigma_clamp <- 1L`, and the engine clamps at `3114-3117` *after* the structured
contribution at `3086`. But `zoib_sigma_phylo_nll` (`:309-319`), `zoib_sigma_animal_nll`
(`:321-328`), `zoib_sigma_relmat_nll` (`:330-337`), `zoib_sigma_spatial_nll` (`:402-410`)
and `zoib_sigma_phylo_interaction_nll` (`:427-436`) never call `softclamp_logsigma_drm`.
They pass only because the test values sit inside the band. The atom oracles at `:456-475`
and `:477-496` do apply it. Two conventions in one file; the new atom oracle follows the
second.

**F6 — one oracle drops the mean compression.** `:448` uses `plogis(eta_mu)` while every
sibling includes the compression (`:303`, `:316`, `:325`, `:354`, `:369`, `:395`, `:407`,
`:421`, `:433`, `:466`, `:487`). The discrepancy is ~`2e-12` relative, so it passes a `1e-8`
check invisibly. It tests a function it does not claim to test.

**F7 — asymmetric boundary predicate.** Engine `y <= 0` / `y >= 1` (`:3146`, `:3150`);
oracle `y == 0` / `y == 1` (test `:35-37`). They coincide only because
`prepare_zero_one_beta_response()` rejects out-of-range values (`R/drmTMB.R:15911-15916`) —
an invariant in a different file. Fine today; record the dependency.

**F8 — open question, missing-predictor guard.** Five density blocks carry
`!(has_mi == 1 && mi_family != 0 && mi_observed(i) == 0)` (`2305`, `2984`, `3309`, `3586`,
`3889`); block 15 gates only on `observed_y(i) == 1` (`3145`). ZOB appears as an
*imputation* family at `1508-1509` and `R/drmTMB.R:18431-18432`, which would make the
omission correct. Whether a ZOB *response* model can co-occur with a non-zero `mi_family`
could not be determined from source. Flagged for `docs/design/149-missing-data-design.md`.

**F9 — (orchestrator) the first draft of §2.4's numeric table was wrong in four of five
rows**, up to two orders of magnitude, all optimistic, and its derived design rule was
false. The closed forms were correct. Lesson for this programme: a correct derivation
followed by hand-evaluated arithmetic is not a verified quantity — compute the table.

---

## 8. Scope fence

**IN.** `model_type 15` only · q1 only, one unlabelled structured intercept · exactly one
structured provider per fit (`R/drmTMB.R:5499-5501`, `:5533-5535`) · exactly one structured
endpoint per fit, extending `:5537-5539` and `:5546-5551` · providers `phylo`, `animal`,
`relmat`, `spatial`, `phylo_interaction`, which differ only in `(Q, log|Q|, node_index)` ·
a dense-R oracle per endpoint agreeing to `1e-8` on value *and* central-difference gradient,
plus the §5.3 endpoint-swap negative control.

**OUT — each requires its own gate.** Simultaneous structured `zoi` **and** `coi` in one
fit · `q >= 2`, correlated or labelled blocks, cross-dpar covariance · structured *slopes*
on an atom · combining a structured atom effect with an i.i.d. atom RE · missing responses
with a structured atom effect (already refused for i.i.d. atom REs at `R/drmTMB.R:5448-5457`)
· REML for an atom endpoint (`:2282-2296` admits only `all(codes == 1L)`) · profiles,
intervals, bootstrap, coverage · **any inference claim**.

§2.4 shows the atom SDs are informed by a fraction `zoi` of the data with a per-group
separation probability given in closed form. This slice establishes *that the engine
computes the model this document specifies*. It establishes nothing about whether
`log_sd_phylo` on an atom is recoverable, and no artifact from it may be described as
recovery evidence.

---

## 9. Sign-off

| reviewer | lens | verdict |
|---|---|---|
| Noether | math ↔ syntax ↔ engine | **drafted**; blocking items F1, F2 must be resolved in the implementation slice |
| Orchestrator | §2.4 arithmetic | **corrected** — see the correction note and F9 |
| Fisher | information / recovery target | **pending** — owns §2.4 and the simulation design |
| Rose | completeness | **pending** |

## 10. Implementation status (Gauss, 2026-08-02)

§3.3, §3.4, and §4 implemented as specified, plus the R-side extraction and
guards of §8's IN scope.

- **§3.3 exhaustive dispatch.** `src/drmTMB.cpp` model_type 15 now dispatches
  `phylo_mu_dpar(0)` over an exhaustive `0/1/5/6` set with `error(...)` on any
  other code (F1 resolved for block 15). The three sibling catch-alls named
  in §3.3 (model_type 3 at the student `mu`/`sigma`/`nu` dispatch, model_type
  8 at the `zi_poisson` `mu`/`zi` dispatch, model_type 12 at the
  `hurdle_nbinom2` `mu`/`hu` dispatch) were each tightened to their own
  currently-reachable code set plus an explicit `error(...)`, verified against
  the R-side spec builders that only ever emit their currently-supported
  codes for those model types — a pure tightening, not a routing change, for
  every existing family.
- **§3.4 q1 guard.** Block 15 now asserts `log_sd_phylo.size() == 1` and
  `u_phylo.size() == Q_phylo.rows()` via `error(...)` before the carrier loop.
- **§4 vocabulary.** `phylo_mu_dpar_codes()` (`R/drmTMB.R`) appends
  `"zoi"`/`"coi"` as new codes 5/6, not aliases, exactly as recommended.
- **R-side extraction and guards.** `drm_build_zero_one_beta_spec` now
  extracts structured markers from `zoi_entry`/`coi_entry` via the same
  shared extractor helpers used for `mu_entry`/`sigma_entry`
  (`extract_gaussian_mu_phylo_term`, `extract_gaussian_mu_known_term`,
  `extract_gaussian_mu_spatial_term`, `extract_gaussian_mu_phylo_interaction_term`),
  tagging `$dpars <- "zoi"`/`"coi"`. The mutual-exclusion guard now requires
  exactly one structured provider across `mu`/`sigma`/`zoi`/`coi` (extending
  the pre-existing `mu` XOR `sigma` guard) and refuses combining a structured
  atom effect with any ordinary random effect on any of the four dpars.
  Simultaneous structured `zoi` and `coi` is refused by the same check.
- **Oracle and routing verification.** `tests/testthat/test-zero-one-beta.R`
  gained `zoib_zoi_phylo_nll`/`zoib_coi_phylo_nll` (§5.1/§5.2 oracles, with
  the soft clamp applied per F5 and the `beta_mu_eps` compression per F6) and
  two new gate tests, `"admits only the exact phylo q1 zoi gate"` and
  `"...coi gate"`, each with the §5.3 mandatory checks: node-index bijection,
  conditional clamp, mean compression, value + central-difference-gradient
  agreement to the documented tolerances, and the §5.3 item 5 endpoint-swap
  negative control (the mu-carrier oracle evaluated at the fitted zoi/coi
  parameters must disagree with the actual objective — confirmed disagreeing
  by ~1.9 nll units on an independent smoke fit, not merely in the unit test).
- **Profile fence.** `R/profile.R` already carried
  `point_fit_only_zero_one_beta_phylo_zoi_q1` /
  `..._phylo_coi_q1` notes pre-dating this slice (forward-compatible
  groundwork); the generic non-phylo-provider fallback was extended to also
  produce a `{provider}_{zoi,coi}_q1` note instead of a dpar-blind
  `{provider}_q1` note, satisfying the profile-fence requirement across all
  five providers, not only `phylo`.
- **Not implemented / deferred, per scope**: labelled/slope/q>=2 atom
  structured effects, cross-dpar covariance, and any profile/interval/
  coverage claim remain refused exactly as §8 requires. No `DATA_*`/
  `PARAMETER_*` block was added; the shared `u_phylo`/`Q_phylo`/
  `log_sd_phylo` carrier is reused unchanged.
