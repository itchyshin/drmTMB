# 222 — The location–scale–scale model: `sd_phylo()` with a phylogenetic residual scale

Status: **design done; implementation ATTEMPTED and REVERTED, 2026-07-08 — it failed its own
recovery gate.** The capability remains rejected. See §"Attempt 1" at the foot of this document
before writing any code: the naive per-endpoint scaling rule is *not* sufficient, and the failure
mode is a clean fit with plausible numbers.

Requested by Ayumi Mizuno
([issue #3](https://github.com/Ayumi-495/LS_ecogeographical-rules/issues/3)); tracked as the
`reml_gate_sd_phylo_plus_sigma_phylo` row of
`docs/dev-log/dashboard/estimator-surface-conformance.tsv`.

## The model

Three linear predictors, two of which are scales — hence *location–scale–scale*.

```r
bf(y     ~ x + phylo(1 | id, tree = tree),   # location, phylogenetic
   sigma ~ 1 + phylo(1 | id, tree = tree),   # residual scale, phylogenetic
   sd_phylo(id) ~ climate)                   # the phylogenetic SD itself, a surface
```

For species `i` on a tree with tip correlation `C = Q⁻¹`:

```
(z₁, z₂) ~ N(0, R ⊗ C),      R = [[1, ρ], [ρ, 1]]
s_i      = exp(w_i' β_s)                      # sd_phylo(id) ~ climate
u_i      = s_i · z₁ᵢ                          # phylogenetic LOCATION effect, species-varying SD
v_i      =  τ  · z₂ᵢ                          # phylogenetic SCALE effect, scalar SD
μ_i      = x_i' β_μ + u_i
log σ_i  = w_i' β_σ + v_i
y_i      ~ N(μ_i, σ_i²)
```

Note `Var(u) = D C D` with `D = diag(s_i)`, `Var(v) = τ² C`, `Cov(u, v) = ρ D C τ`. The joint
covariance is not a Kronecker product, but the model *is* separable in the standardized field
`(z₁, z₂)`: put the SDs in the **linear predictor** and give `(z₁, z₂)` a unit-SD correlated GMRF
prior. TMB integrates `z`, so the marginal likelihood is identical and no Jacobian term is needed.

## Alignment table (build this BEFORE coding — `skills/symbolic-alignment`)

| Symbol | R syntax | TMB parameter / DATA | DGP draw | Recovery extractor |
|---|---|---|---|---|
| `β_μ` | `y ~ x` | `beta_mu` | `0.3 + 0.5·x` | `fixef:mu:x` |
| `z₁` | `phylo(1 \| id)` in `mu` | `u_phylo[0·n + node]` | `chol(C)' · rnorm` | `ranef()` |
| `β_s` | `sd_phylo(id) ~ climate` | `beta_sd_mu[sd_phylo_beta_offset + k]` | `−0.7 + 0.6·climate` | `fixef:sd_phylo(id):climate` |
| `s_i` | (derived) | `sd_phylo_group[sd_row]` | `exp(w_i'β_s)` | `obj$report()$sd_phylo_group` |
| `β_σ` | `sigma ~ 1` | `beta_sigma` | `−0.9` | `fixef:sigma:(Intercept)` |
| `z₂` | `phylo(1 \| id)` in `sigma` | `u_phylo[1·n + node]` | `chol(C)' · rnorm` | `ranef()` |
| `τ` | (implicit) | `exp(log_sd_phylo[1])` | `0.45` | `sd:sigma:phylo(1 \| id)` |
| `ρ` | (implicit; cross-dpar) | `tanh(eta_cor_phylo)` | `0.5` | `rho_phylo` |

Eight symbols, eight DGP draws, eight extractors. No row is empty — that is the contract.

## Why this was rejected, and what the rejection was protecting

`parse_sd_phylo_entry()` (`R/drmTMB.R:10545`) aborts when the phylo term has any non-`mu`
endpoint. **This was not a grammar ambiguity.** `sd_phylo()` is *defined* to target the location
effect; `target_endpoint` (`R/drmTMB.R:10630`) records which endpoint that is, and the parameter
map already frees the SD of every *other* endpoint:

```r
log_sd_map[unname(sd_phylo$target_endpoint)] <- NA_integer_   # R/drmTMB.R:15414
```

The obstacle was in C++. `src/drmTMB.cpp` scaled the field of **every** endpoint by the location
surface:

```cpp
for (int k = 0; k < q_phylo; ++k) {
  Type field_effect = u_phylo(k * n_phylo + phylo_mu_node_index(i));
  if (has_sd_phylo_model == 1) {
    field_effect *= sd_phylo_group(phylo_mu_sd_row(i));   // <- applied to k = sigma too
  }
```

With `q_phylo = 2` that forces `τ_i ≡ s_i`: the phylogenetic *scale* SD is silently pinned to the
phylogenetic *location* SD surface, `log_sd_phylo(1)` goes unidentified, and the fit converges to
plausible numbers. A wrong model, not a crash. Same failure class as the `eta_cor_sigma` near-miss
(`6b0ed817`) — and here there is no sentinel to segfault on.

Additionally, the correlated cross-dpar branch was gated on `has_sd_phylo_model == 0`, so a
direct-SD surface silently *disabled* the `μ`–`σ` phylogenetic correlation while leaving
`eta_cor_phylo` a free, unused parameter.

## The change

Introduce an **effective SD per endpoint**:

```
sd_eff(k) = 1        if has_sd_phylo_model && k == sd_phylo_target_endpoint
          = sd_phylo(k)   otherwise
```

Then, uniformly:

* **linear predictor** — scale only the target endpoint's field by `sd_phylo_group(g)`; every other
  endpoint's field carries its own SD through its prior;
* **diagonal density** — one formula, `2n·log sd_eff(k) − log|Q| + exp(−2 log sd_eff(k))·qᵏ`. For the
  target this reduces to the standardized form (`log 1 = 0`), so the existing behaviour is
  byte-identical when `q_phylo = 1`;
* **correlated (cross-dpar) density** — enable it when a direct-SD surface is present, using
  `sd_eff(0)`, `sd_eff(1)` in the 2×2 inverse and log-determinant.

New `DATA_INTEGER(sd_phylo_target_endpoint)` (0-based), fed from
`spec$random_scale$phylo$target_endpoint`.

## Scope of this slice

**Covers ✓** — univariate Gaussian; `q_phylo = 2` with endpoints `{mu, sigma}`; intercept-only phylo
terms; ML and REML; the `μ`–`σ` phylogenetic correlation estimated jointly with the SD surface.

**Does NOT cover ✗** — structured *slopes* under a direct-SD formula (already rejected separately at
`R/drmTMB.R:10553`); the `|p|`-coupled `corpair` phylo model combined with a direct-SD surface (the
parameter map's `corpair` branch precedes the `sd_phylo` branch and would leave the target's
`log_sd_phylo` free, double-counting the scale); bivariate `sd_phylo1`/`sd_phylo2` with a
residual-scale phylo endpoint; non-Gaussian families.

## Gating (non-negotiable — the silent-wrong-model rule)

No admission without a **known-truth recovery test** and a **null control**:

1. **Recovery** — simulate from the DGP above and recover `β_s`, `τ`, and `ρ` separately. If the C++
   still pinned `τ ≡ s_i`, `τ` would not recover.
2. **Null control** — with `τ = 0`, the fitted `sd:sigma:phylo` must collapse toward 0 while the
   `sd_phylo` surface still recovers.
3. **Byte-identity** — the `q_phylo = 1` path (no residual-scale phylo endpoint) must be unchanged.

A model that fits cleanly and returns plausible numbers is exactly the thing these tests exist to
catch.

---

## Attempt 1 (2026-07-08) — implemented, recovery FAILED, reverted

The change described above was implemented in full and reverted. It is recorded here so the next
attempt does not repeat it.

**What was built.** `DATA_INTEGER(sd_phylo_target_endpoint)`; `sd_phylo_eff(k)` (= 1 for the target,
`sd_phylo(k)` otherwise) used in the diagonal density, the correlated 2×2 inverse and its
log-determinant; the target-only scaling in the linear predictor; the cross-dpar branch enabled when
a direct-SD surface is present; the gate relaxed to `{mu, sigma}`. Also a genuine latent bug fix:
`gaussian_ls_map()` blanket-fixed the whole `log_sd_phylo` vector when a direct-SD model was present,
so with `q_phylo > 1` the map length (1) disagreed with the parameter length (2) and `MakeADFun()`
aborted. `biv_gaussian_map()` already had the general form.

**Result — the recovery ladder (60 tips × 8 obs/species, one seed):**

| arm | truth | estimated | verdict |
|---|---|---|---|
| (i) `q=1` + `sd_phylo`, τ = 0 (unchanged path) | `β_s = (−0.70, 0.60)` | `(−0.458, 0.574)` | baseline |
| (ii) `q=2` + `sd_phylo`, **τ = 0**, ρ = 0 (null control) | `β_s` as above; `τ = 0` | `(−0.449, 0.569)`; `τ = 0.036` | **PASS** |
| (iii) `q=2` + `sd_phylo`, **τ = 0.45**, ρ = 0 | `β_s = (−0.70, 0.60)`; `τ = 0.45`; `ρ = 0` | **`(0.827, −0.064)`**; `τ = 0.82`; **`ρ = −0.59`** | **FAIL** |

`conv = 0`, `pdHess = TRUE` throughout. The null control passes; the live case inverts the surface
intercept, annihilates the climate slope, nearly doubles `τ`, and invents `ρ = −0.59`. This is the
silent-wrong-model failure the gate was protecting against — the fit is clean and the numbers are
plausible.

**What was ruled out (evidence, not assumption).** The R-side wiring is correct:
`phylo_mu_dpars = (mu, sigma)` → `phylo_mu_dpar = (0, 1)`; `target_endpoint = 1` (1-based) →
`sd_phylo_target_endpoint = 0`; `map$log_sd_phylo = (NA, 2)`; `Q_phylo` is the 38×38 augmented
precision for 20 tips and `u_phylo` has length `2 × 38`; `phylo_mu_sd_row` is a bijection onto the
20 species rows; `phylo_mu_value ≡ 1`. The **pre-existing** correlated branch (same DGP, constant
`s`, no `sd_phylo`) recovers `ρ` with the right sign. So the defect lives in the *interaction* of
the per-group surface with the correlated cross-dpar block, not in the endpoint indexing.

**The next isolating test** (not yet run): fit arm (iii)'s DGP — species-varying `s`, `τ = 0.45` —
with the model **without** `sd_phylo()` (constant phylo SD). If `τ` and `ρ` recover there, the
correlated block is sound and the surface × correlation interaction is the culprit; if `τ` also
inflates, the augmented-field scaling is being double-counted.

**Hypotheses worth testing, in order.**

1. The marginal implied by "standardize the target field, scale it in the predictor" may not equal
   `D C D` once the *augmented* (node + tip) field is involved: the surface multiplies only at tip
   rows via `phylo_mu_sd_row(i)`, while the GMRF prior is over all 38 augmented nodes. Internal-node
   values remain unscaled, so the scaling is **not** a similarity transform of the field and the
   induced tip covariance is not `D C D`. **This is the leading suspect.** The `q_phylo = 1` path
   gets away with it only because a single global surface times a standardized field is still a
   valid reparameterisation of *that* likelihood; with two correlated fields the cross-covariance
   `Cov(u, v) = ρ · D C τ` requires the scaling to act on the same space the correlation does.
2. `sd_phylo_eff(0) = 1` forces the target's prior SD to 1 *in the correlated 2×2*, but
   `log_sd_phylo(0)` is still a mapped-but-present parameter; check nothing else reads `sd_phylo(0)`.
3. Starting values: `beta_sd_mu` starts far from truth once the correlated block is live.

**Gate status.** `parse_sd_phylo_entry()` still rejects. The conformance row
`reml_gate_sd_phylo_plus_sigma_phylo` stays `expected = error`. Nothing was promised to the user
beyond "it is on the implementation list".

**Reusable artifact.** `scratchpad/location_scale_scale_recovery.R` — arms A/B/C exactly as above.
Run it before and after any future attempt.
