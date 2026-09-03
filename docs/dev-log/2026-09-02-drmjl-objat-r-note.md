# DRM.jl `drm_bridge_objective_at` — replaces the five private names

Branch `feat/563-bridge-objective-at` (stacked on `feat/575-objective-at` @
`dc3ce190`), `src/bridge.jl` / `src/DRM.jl`. Exported, public.

## The call to make instead

Replace the `JuliaCall::julia_command(...)`-defined `drmTMB_reml_objective_at`
shim and its call in `drm_julia_reml_objective_at()`
(`R/julia-bridge.R`, ~line 2496) with a direct call to the new exported
Julia function:

```r
result <- JuliaCall::julia_call(
  "DRM.drm_bridge_objective_at",
  payload$formula,
  family_tag,
  as.list(payload$data),
  payload$tree,
  if (length(payload$options) == 0L) NULL else payload$options,
  Lambda = unname(Lambda),
  rho12 = as.numeric(rho12),
  beta = list(
    mu1    = as.numeric(beta$beta_mu1),
    mu2    = as.numeric(beta$beta_mu2),
    sigma1 = as.numeric(beta$beta_sigma1),
    sigma2 = as.numeric(beta$beta_sigma2)
  )
)
```

Julia signature: `drm_bridge_objective_at(formula, family, data, tree,
options = Dict(); beta, Lambda, rho12)` — `formula`/`family`/`data`/`tree`/
`options` are positional and are the SAME payload `drm_bridge` takes
(`payload$formula`, `family_tag`, `as.list(payload$data)`, `payload$tree`,
`payload$options`, unchanged from today's call); `beta`/`Lambda`/`rho12` are
keyword. `beta`'s field names are `mu1`/`mu2`/`sigma1`/`sigma2` (not
`beta_mu1`/... — those R-side names stay on the R side; strip the `beta_`
prefix when building the list passed to Julia). `tree` is still required
(errors if `NULL`/`nothing`); `options` is accepted for positional parity
with `drm_bridge` but is not otherwise read — this route is a diagnostic, not
a fit, so `method = "REML"` etc. inside `options` has no effect here.

This removes the dependency on `DRM._bridge_data`, `DRM._bridge_formula`,
`DRM._bivariate_q4_marker`, `DRM._design`, and `DRM._phylo_species_index`
(all private/qualified-name access) and on hand-writing
`drmTMB_reml_objective_at`'s Julia source via `julia_command`. The
`drm_julia_setup()` block that currently defines `drmTMB_reml_objective_at`
by string can be deleted entirely once this call is switched over.

## Return `Dict` keys

`DRM.drm_bridge_objective_at(...)` returns a Julia `Dict{String,Any}`
(JuliaCall marshals this to a named R list) with:

- `"objective"` — same value as `"reml_loglik"` (route-agnostic alias).
- `"reml_loglik"` — the normalised Patterson–Thompson restricted
  log-likelihood, the number to compare against `-logLik(fit_tmb)` /
  DRM.jl's own `fit_q4_reml(...).reml_loglik` (same convention as today).
- `"raw_reml_ll"` — pre-normalisation value (what the old shim also
  returned under this name).
- `"converged_inner"` — the inner conditional-Newton alternation's own
  convergence flag. **Name changed** from the old shim's `"converged"` — a
  barrier hit surfaces as `raw_reml_ll = reml_loglik = -Inf`,
  `converged_inner = FALSE`, same semantics as before, new key name.
- `"contract"` — the literal string `"bridge_objective_at_v1"`. Assert this
  equals that literal so a future incompatible return-shape change fails
  loudly on the R side instead of silently reading a stale field.

`drm_julia_reml_objective_at()`'s own R-facing return value (`list(
reml_loglik=, raw_reml_ll=, converged=)`) can stay unchanged — map
`converged = result$converged_inner` when adapting.

## Error messages R may see

All errors are Julia `ArgumentError`s (JuliaCall surfaces these as R errors
with the Julia message text):

- `tree` is `nothing`/`NULL`:
  `"drm_bridge_objective_at: \`tree\` is required for the bivariate q=4 phylogenetic REML objective-at diagnostic"`
- Non-bivariate formula (e.g. plain `mu`/univariate):
  `"drm_bridge_objective_at: only the bivariate q=4 phylogenetic REML route is supported (got a univariate formula)"`
- Bivariate formula without a shared `phylo(...)` term on all four axes
  (mu1/mu2/sigma1/sigma2), e.g. the bivariate q2 phylo route or an
  unstructured bivariate formula:
  `"drm_bridge_objective_at: only the bivariate q=4 phylogenetic REML route is supported (formula has no shared \`phylo(...)\` term on mu1, mu2, sigma1, and sigma2)"`
- `Lambda` not 4×4:
  `"drm_bridge_objective_at: \`Lambda\` must be a 4x4 symmetric numeric matrix (the phylo q4 among-axis covariance, axis order mu1, mu2, sigma1, sigma2); got size (r, c)"`
- `beta` missing a required field:
  `"drm_bridge_objective_at: \`beta\` is missing field \`mu1\`"` (etc. for
  mu2/sigma1/sigma2)
- `beta[field]` wrong length:
  `"drm_bridge_objective_at: \`beta[mu1]\` must have length K (the mu1 design width); got length L"`
- `beta` not a `Dict`/`NamedTuple`:
  `"drm_bridge_objective_at: \`beta\` must be a NamedTuple or Dict with mu1/mu2/sigma1/sigma2 fields"`

None of these were previously distinguishable from generic Julia errors
under the old `julia_command`-defined shim (which threw plain
`ArgumentError`s with different wording for `tree`/route-mismatch and no
shape checks on `Lambda`/`beta` at all — a wrong-length `beta` or non-4×4
`Lambda` would previously have failed deeper inside `reml_objective_at`/
`pack_phi` with a much less specific message, or silently misaligned).

## Verified evidence

`DRM.drm_bridge_objective_at` reproduces the #575 cross-engine receipt
numbers on the committed `biv-q4-phylo-reml` fixture:

- At TMB's fitted point: `-219.620688` (receipt), bridge returns
  `-219.6205..-219.6209` range, `isapprox(..., atol=2e-4)` — PASS.
- At Julia's own REML optimum: `-219.630326` (receipt), bridge returns
  within the same `2e-4` inner-alternation noise floor — PASS.
- Bridge result equals the private `reml_objective_at(prob, Q_cond, phi;
  beta0=...)` path at an identical point to `atol=1e-8` (same code path,
  same floating-point trace) — PASS.

Test: `test/test_bridge_objective_at.jl` (17 assertions, all green), wired
into `test/runtests.jl` immediately after `test_reml_objective_at.jl`.
Neighbours re-verified green: `test/test_reml_objective_at.jl` (5/5),
`test/test_bridge_formula_labels.jl` (819/819), `test/test_api_stability.jl`
(188/188, `"drm_bridge_objective_at"` added to the EXPERIMENTAL tier next to
`"drm_bridge"`/`"drm_bridge_inference"`).
