# 257 — Non-Gaussian ordinary correlated `(1 + x | g)` (binomial wedge)

**Date:** 2026-08-16  
**Lane:** stacked `cursor/ng-correlated-slope-impl` (#1059, Wave 1), then
`cursor/ng-correlated-slope-wave2` (#1060, Wave 2), then
`cursor/ng-correlated-slope-nb2` (#1065, Wave 2.5), then
`cursor/ng-correlated-slope-wave3-lognormal` (Wave 3). No merge to `main`; no CRAN;
no missing-data / MSPL. Design freeze originated on
`cursor/ng-correlated-slope-design` (#1057).  
**Readers:** the next implementer after win-builder unlock, plus Fisher / Noether / Boole on later family PRs.  
**Inventory this note implements:** slices 1–2 plus the ordinary-NB2 count
follow-on and the first continuous-family Wave 3 cell of
[`docs/dev-log/research/2026-08-16-nongaussian-re-remaining-fruit.md`](../dev-log/research/2026-08-16-nongaussian-re-remaining-fruit.md).  
**Numbering:** 256 is reserved by the foreign MSPL-boundary lane (`256-mspl-boundary-penalty-derivation.md` on `claude/mspl-boundary-s0-s1`). This note is 257.

Wave 1 (`mc-0717`, binomial logit), Wave 2 (`mc-0718`, ordinary Poisson log),
Wave 2.5 (`mc-0719`, ordinary NB2 log-mean), and Wave 3 (`mc-0720`, ordinary
lognormal log-location) are the live `point_fit_recovery` contract on this
stack. The Wave 0 sentence that this note "does not admit a family" is stale.
Quiesce still holds: none of these waves merge to `main` until unlock.
Coverage and `supported` remain later arcs.

## Purpose

Ordinary non-Gaussian random intercepts `(1 | g)` and independent slopes `(0 + x | g)` already
fit. The remaining ordinary gap was the **correlated** intercept–slope block `(1 + x | g)`.
Wave 1 made the binomial experimental path an honest `point_fit_recovery` cell
(`mc-0717`). Wave 2 admitted ordinary Poisson behind the design-17 map
(`mc-0718`). Wave 2.5 admitted ordinary NB2 behind the same design-17 map
and the same report symbols (`mc-0719`). Other fitted univariate
non-Gaussian families still reject that block with a “planned” message.
Coverage and `supported` are later arcs.

## Claim ceiling

| Stage | Maximum claim | Not this stage |
| --- | --- | --- |
| This stacked note | Live Wave 1+2+2.5+3 contract: `mc-0717`, `mc-0718`, `mc-0719`, and `mc-0720` at `point_fit_recovery` | Intervals, coverage, REML, AGHQ, `supported`, merge to `main` |
| Wave 1 (binomial, #1059) | `point_fit_recovery` for **one** complete-data binomial unlabelled `(1 + x \| g)` ML-Laplace cell | Intervals, coverage, REML, AGHQ, `supported` |
| Wave 2 (Poisson, #1060) | `point_fit_recovery` for **one** complete-data ordinary Poisson unlabelled `(1 + x \| g)` ML-Laplace cell | Inheritance from binomial, intervals |
| Wave 2.5 (NB2, #1065) | `point_fit_recovery` for **one** complete-data ordinary `nbinom2()` unlabelled `(1 + x \| g)` ML-Laplace cell | Independent-slope `mc-0402`, ZI/truncated, intervals |
| Wave 3 (lognormal) | `point_fit_recovery` for **one** complete-data ordinary `lognormal()` unlabelled `(1 + x \| g)` ML-Laplace cell | Independent-slope `mc-0380`, Gamma neighbour, intervals |
| Later family menu | `point_fit_recovery` per admitted family, one cell at a time | Inheritance from binomial, Poisson, NB2, or lognormal |
| Later, separate owner goal | `interval_feasible` then fenced `inference_ready_with_caveats` | Never `supported` in the first arc |

Do not reuse `mc-0061`. That cell is the **independent** binomial `mu` slope
(`y ~ x + (0 + x | g)`), already `inference_ready_with_caveats` on a frozen M/{32,64} domain.
A correlated block is a different estimand (two SDs plus `rho_re`).

## What is already true on `origin/main`

Gaussian ordinary correlated blocks are the mature surface in
[`17-correlated-random-effect-blocks.md`](17-correlated-random-effect-blocks.md).

Binomial unlabelled `(1 + x | id)` is an **experimental point-fit** route:

- Parser: `validate_binomial_mu_random_terms()` admits exactly one unlabelled
  `correlated_slope` term and rejects labels, extra terms, and multi-slope bars.
- Context fence: `drm_validate_binomial_q2_context()` rejects `REML = TRUE`,
  missing-response rows, and a slope predictor that is constant within every
  group before TMB construction.
- Tests: `tests/testthat/test-binomial-correlated-re-mspl-prereq.R` (Cholesky
  positive-definiteness, parser, AD vs finite-difference gradient, fresh-draw map,
  one-seed ML recovery with absolute SD/ρ gates of 0.30).
- Grammar: `docs/design/01-formula-grammar.md` already lists
  `cbind(successes, failures) ~ x1 + (1 + x1 | id)` as an experimental q=2 point-fit
  slice. That row also mentions experimental `estimator = "mspl"`. **This arc does
  not expand MSPL.**

Other families reject ordinary correlated `mu` blocks in their
`validate_*_mu_random_terms()` helpers (Poisson / NB2 / Gamma / lognormal /
skew_normal / tweedie / beta / zero_one_beta / cumulative_logit / Student-t /
beta_binomial). Count families may already have **structured labelled** q2
point-fit cells; those are a different surface and stay out of this note.

Mission Control `do_not_repeat` already bars opening a non-Gaussian correlated q2
route from the 2026-07-21 gllvmTMB probe without a predeclared iid control, an
external or dense marginal oracle, an information ladder, and a treatment of
retained gradient exceptions.

## Symbolic alignment

Location here is the linear predictor on the family’s link scale. Scale (`sigma`)
and residual correlation (`rho12`) are not in this block. The group-level
correlation is `rho_re`, never `rho12`.

```text
y_ij | p_ij ~ Binomial(n_ij, p_ij)          # wedge family
logit(p_ij) = X_ij β + b_0j + x_ij b_1j
(b_0j, b_1j)' ~ MVN(0, Σ_g)

Σ_g = [ sd0^2 ,           rho_re sd0 sd1 ]
      [ rho_re sd0 sd1 ,  sd1^2          ]
```

R syntax for the wedge (complete data, ML, unlabelled):

```r
drmTMB(
  bf(cbind(success, failure) ~ x + (1 + x | id)),
  family = binomial(),
  data = dat
)
```

Independent control on the same DGP (already certified as a different cell):

```r
bf(cbind(success, failure) ~ x + (1 | id) + (0 + x | id))
```

| Symbol | Keyword / covstruct | DGP draw | Recovery extractor | Truth in the existing binomial fixture |
| --- | --- | --- | --- | --- |
| `β_0`, `β_x` | fixed `~ x` | `plogis(-0.25 + 0.70 x + …)` | `fixef()` | not a recovery gate in the first slice |
| `b_0j` | `(1 + x \| id)` intercept | `sd0 * z0` | `ranef()` / `random_effects$mu` | latent only |
| `b_1j` | `(1 + x \| id)` slope | `sd1 * (ρ z0 + √(1-ρ²) z1)` | same | latent only |
| `sd0` | `sdpars$mu["(1 + x \| id):(Intercept)"]` | 0.65 | `sdpars$mu` | 0.65 |
| `sd1` | `sdpars$mu["(1 + x \| id):x"]` | 0.42 | `sdpars$mu` | 0.42 |
| `rho_re` | `corpars$mu["cor((Intercept),x \| id)"]` | 0.45 | `tanh(eta_cor_mu)` | 0.45 |
| `n_ij` | `cbind(success, failure)` | `Poisson(16)+8` | trials = success + failure | not estimated |

The existing binomial tests use `n_group = 56`, `n_each = 14`, seed `20260811`
for the recovery assertion. Keep that fixture as the local regression; the
campaign DGP may enlarge `n_group` but must keep the same six recovered symbols.

### Cholesky map — reuse the binomial experimental path

Design 17 writes the Gaussian block as `b = diag(sd) L u` with
`ρ = 0.999999 tanh(η)` and `L = [[1, 0], [ρ, √(1-ρ²)]]`.

The compiled binomial experimental path uses the numerically stable **log-sech**
factorization already tested at `η ∈ {-40, 40}`:

```text
ρ = tanh(η)
log sech(η) = log 2 − |η| − log1p(exp(−2|η|))
L = [ exp(θ0) ,  0
      exp(θ1) ρ , exp(θ1 + log sech(η)) ]
```

At finite `η`, `sech(η) = √(1 − tanh²(η))`, so the two maps describe the same
`Σ_g`. The first code slice must **keep the binomial log-sech map**
(`eta_cor_mu`, `rho_mu_re`, `logsech_mu_re` in `obj$report()`;
`transform_mu_random_effects(..., binomial_q2 = TRUE)`). Do not “simplify”
binomial back to design 17’s `√(1-ρ²)` form. A later family may share this
carrier; if it cannot, write a new alignment row before flipping that family’s
gate.

## Grammar

| Form | This arc | Why |
| --- | --- | --- |
| `y ~ x + (1 + x \| g)`, `family = binomial()`, complete data, `REML = FALSE` | **In** (wedge) | Already experimental; cbind encoding is the tested contract |
| Bernoulli `y01 ~ x + (1 + x \| g)` | Sibling only after the cbind cell recovers | Same validator; not the first ledger row |
| `(1 \| g) + (0 + x \| g)` | Control, not the claim | Already implemented |
| `(1 + x \| p \| g)` labelled | **Out** | Parser already rejects |
| `(1 + x + z \| g)` multi-slope | **Out** | Parser already rejects |
| `(1 \| g) + (1 + x \| g)` mixed | **Out** | Same-group intercept plus correlated block is rejected |
| `phylo()` / `spatial()` / `animal()` / `relmat()` | **Out** | Structured q2 is a different surface |
| `sigma ~ (1 + x \| g)` on a non-Gaussian family | **Out** | Separate fruit (slice 3) |
| `estimator = "mspl"` | Untouched | Foreign / parked MSPL lane |
| `missing = miss_control(response = "include")` | **Out** | `drm_validate_binomial_q2_context()` already aborts |

When a family is still out, the error should keep telling the user to use
`(1 | g) + (0 + x | g)` or the exact binomial cbind block. Do not promise a
date.

## Families in / out

**Wave 0 (now, docs only).** No gate changes.

**Wave 1 (first code slice after quiesce).** Binomial logit, complete data,
unlabelled ordinary `(1 + x | g)`, ML-Laplace. Probit / cloglog inherit the
parser only if the same `validate_binomial_mu_random_terms()` path already
admits them; they do **not** inherit the recovery cell.

**Wave 2 (this stack, `cursor/ng-correlated-slope-wave2` on Wave 1).** Ordinary
Poisson `mu` only (no `zi`). The compiled Poisson branch already
carried the design-17 map (`ρ = 0.999999 tanh(η)` and
`u_cond = ρ u_pair + √(1-ρ²) u`). Wave 2 admits one complete-data unlabelled
`(1 + x | g)` block at `point_fit_recovery` as `mc-0718`. Labelled,
mixed, REML, and missing-response stay rejected. Structured labelled q2 cells
stay separate.

**Wave 2.5 (this stack, `cursor/ng-correlated-slope-nb2` on Wave 2).** Ordinary
NB2 `mu` only (no `zi`, no truncated). Compiled `model_type == 7` already
matched Poisson `model_type == 6` (`eta_cor_mu`, `rho_mu_re`; no
`logsech_mu_re`). Wave 2.5 admits one complete-data unlabelled
`(1 + x | g)` block at `point_fit_recovery` as `mc-0719`. This is not
`mc-0402` and not `mc-0718`. Zero-inflated or truncated NB2, labelled,
mixed, REML, and missing-response stay rejected.

**Wave 3 (this stack, `cursor/ng-correlated-slope-wave3-lognormal`).** Ordinary
lognormal `mu` only (not Gamma). Compiled `model_type == 4` now carries the
same design-17 ordinary-RE map as Poisson (`eta_cor_mu`, `rho_mu_re`; no
`logsech_mu_re`). Wave 3 admits one complete-data unlabelled
`(1 + x | g)` block at `point_fit_recovery` as `mc-0720`. Gamma, labelled,
mixed, REML, and missing-response stay rejected.

**Later Wave 3 menu.** Gamma, beta, skew_normal, tweedie,
zero_one_beta, cumulative_logit — each already has independent `mu` slopes.
Each needs its own alignment row if the report symbols differ.

**Out of this arc.** Student-t (only a narrow spatial intercept gate), hurdle /
zero-inflated counts, beta_binomial, bivariate non-Gaussian, labelled ordinary
blocks, structured ordinary correlated, scale-side NG correlated, public O3,
REML, missing-response, MSPL, Julia.

## REML / AGHQ fences

Keep these closed until a later owner goal names them.

- **O2 binomial Cox–Reid / joint-Laplace REML** is diagnostic-only for exactly
  one ordinary unlabelled `mu` intercept **or** one independent slope
  (`mc-0060` / `mc-0062`). Correlated q2 already aborts in
  `drm_validate_binomial_q2_context()`. Do not relax that abort in Wave 1.
- **O3 nested AGHQ + Cox–Reid** (`R/aghq-coxreid.R`, design 224) remains
  package-private. Public `mc-0227` stays ML-Laplace `point_fit_recovery`.
  Correlated binomial does not inherit O3.
- Design 224’s small-cluster lesson still applies: Laplace RE-SD bias is
  expected. Wave 1 recovery gates must be wide enough for that bias, or the
  DGP must put enough observations in each group. The existing local fixture
  uses `n_each = 14`; the information ladder below is what decides whether
  that is enough for a ledger cell.

## Test plan (ADEMP)

**Aim.** Recover `sd0`, `sd1`, and `rho_re` for one binomial correlated block
under ML-Laplace, and keep every rejected neighbour rejected.

**Data-generating process.** Reuse the symbols in
`test-binomial-correlated-re-mspl-prereq.R` (`mspl_q2_data()`): logit mean
`-0.25 + 0.70 x`, `sd0 = 0.65`, `sd1 = 0.42`, `rho_re = 0.45`, Poisson-plus-8
trials, `x ~ Normal(0,1)` **varying within group**. A slope with no
within-group variation in `x` is unidentified; that is a rejection test, not a
recovery cell.

**Estimand.** The three variance-component parameters above. Fixed effects are
nuisance. Do not profile them in Wave 1.

**Methods.** drmTMB ML-Laplace on `(1 + x | g)`. Predeclared comparators on the
same seeds: (i) drmTMB independent `(1 | g) + (0 + x | g)`; (ii) `glmmTMB` or
`lme4::glmer` with the same correlated formula. One of (ii) is the external
oracle. A dense marginal-likelihood oracle is acceptable if the external fit
is unavailable, but it must be named before the smoke runs.

**Performance gates (Wave 1, local + Totoro smoke).** Convergence 0; finite
`sdpars` / `corpars`; `pdHess` recorded but not a hard kill (weak-ID is
possible at low `n_each`). Absolute recovery gates start at the existing
0.30 SD / 0.30 ρ local test; the campaign may tighten them only after the
n-ladder is seen. Retain gradient exceptions in the denominator and classify
them; do not drop them quietly (MC fence).

**Rejection matrix (must stay red).** labelled block; multi-slope; REML;
missing response; one other NG family still in Wave 3; `(1 | g)` plus
`(1 + x | g)` on the same group; a slope predictor that is constant
within every group (unidentified `sd1` / `rho_re`).

## Compute gate

Ask “Totoro or DRAC?” before any recovery run (D-50). Never GitHub Actions.

1. **Local** focused tests already in tree. No new C++ in this PR.
2. **Totoro smoke** after quiesce and after the Wave 1 code PR exists:
   ~30 fits, the local fixture plus `n_each ∈ {4, 8, 14}`, disjoint seeds,
   iid control + one external oracle. STOP if recovery or exception handling
   is not honest.
3. **DRAC / Fir certification** only after that smoke, a frozen ADEMP sheet,
   and an explicit owner approval. Suggested first campaign: N≈200–400, not
   1,200, because the claim is `point_fit_recovery` not coverage.
4. Coverage / profile campaigns are a later goal. They do not start from this
   note.

## Reopen after quiesce

Quiesce still blocks shipped-file merges to `main` until the 0.7.0
platform matrix (including win-builder) is complete. Docs under `docs/` may
land earlier if a reviewer wants the contract on `main`; that is optional and
is not a ship.

When quiesce lifts:

1. Merge `#1059` (Wave 1 / `mc-0717`) to then-current `main`, then `#1060`
   (Wave 2 / `mc-0718`), then the Wave 2.5 NB2 PR (`mc-0719`), which is
   stacked on the Wave 2 branch.
2. Do not reopen Wave 0. The live contract is already Wave 1+2+2.5 at
   `point_fit_recovery`.
3. A later family PR (Wave 3 continuous families) starts from this stacked
   note, one cell at a time. Do not inherit binomial log-sech onto Poisson
   or NB2.
4. Do not merge until Fisher + Noether have read each new family's alignment
   table against a fitted object. Wave 1 already has that merge-path PASS.

## Stop

Wave 1, Wave 2, Wave 2.5, and Wave 3 lognormal are implemented on this stack.
Wave 3 required the first C++ change on the design-17 path for
`model_type == 4`. No MSPL. No missing-data. No CRAN submission. No merge to
`main` until quiesce lifts. The next safe *code* action after unlock is
merge Waves 1→2→2.5→3 in order, or open the next continuous-family Wave 3
cell from this note, not from the gllvmTMB probe.

## Wave 2 Poisson alignment (implemented on this stack)

Location is the log-mean. Group-level correlation is `rho_re`, never residual
`rho12`. Poisson reuses the compiled design-17 ordinary-RE carrier already in
`model_type == 6`; it does **not** inherit the binomial log-sech map.

```text
y_ij | λ_ij ~ Poisson(λ_ij)
log(λ_ij) = X_ij β + b_0j + x_ij b_1j
(b_0j, b_1j)' ~ MVN(0, Σ_g)

Σ_g = [ sd0^2 ,           rho_re sd0 sd1 ]
      [ rho_re sd0 sd1 ,  sd1^2          ]
ρ = 0.999999 tanh(η)
u_cond,slope = ρ u_intercept + √(1-ρ²) u_slope
```

```r
drmTMB(
  bf(count ~ x + (1 + x | id)),
  family = poisson(),
  data = dat
)
```

| Symbol | Extractor | Truth in `poisson_q2_data()` |
| --- | --- | --- |
| `sd0` | `sdpars$mu["(1 + x \| id):(Intercept)"]` | 0.65 |
| `sd1` | `sdpars$mu["(1 + x \| id):x"]` | 0.42 |
| `rho_re` | `corpars$mu["cor((Intercept),x \| id)"]` = `0.999999 tanh(eta_cor_mu)` | 0.45 |

`obj$report()` carries `eta_cor_mu` and `rho_mu_re`. It does **not** carry
`logsech_mu_re`. Do not rewrite Poisson onto the binomial log-sech factorisation
in this wave.

## Wave 2.5 NB2 alignment (implemented on this stack)

Location is the log-mean. Overdispersion `sigma` is a fixed-effect intercept
(`size = 1 / sigma^2`). Group-level correlation is `rho_re`, never residual
`rho12`. Ordinary NB2 reuses the compiled design-17 ordinary-RE carrier
already in `model_type == 7`; report symbols match Poisson exactly. The
alignment gate therefore flipped. This is not `mc-0402` and not `mc-0718`.

```text
y_ij | μ_ij ~ NB2(μ_ij, σ)
log(μ_ij) = X_ij β + b_0j + x_ij b_1j
(b_0j, b_1j)' ~ MVN(0, Σ_g)

Σ_g = [ sd0^2 ,           rho_re sd0 sd1 ]
      [ rho_re sd0 sd1 ,  sd1^2          ]
ρ = 0.999999 tanh(η)
u_cond,slope = ρ u_intercept + √(1-ρ²) u_slope
```

```r
drmTMB(
  bf(count ~ x + (1 + x | id), sigma ~ 1),
  family = nbinom2(),
  data = dat
)
```

| Symbol | Extractor | Truth in `nbinom2_q2_data()` |
| --- | --- | --- |
| `sd0` | `sdpars$mu["(1 + x \| id):(Intercept)"]` | 0.65 |
| `sd1` | `sdpars$mu["(1 + x \| id):x"]` | 0.42 |
| `rho_re` | `corpars$mu["cor((Intercept),x \| id)"]` = `0.999999 tanh(eta_cor_mu)` | 0.45 |

`obj$report()` carries `eta_cor_mu` and `rho_mu_re`. It does **not** carry
`logsech_mu_re`. Do not rewrite NB2 onto the binomial log-sech factorisation
in this wave.

## Wave 3 lognormal alignment (implemented on this stack)

Location is the log-response mean (`log(y) ~ Normal(mu, sigma^2)`). Residual
`sigma` is a fixed-effect intercept on the log-scale. Group-level correlation
is `rho_re`, never residual `rho12`. Ordinary lognormal now reuses the
compiled design-17 ordinary-RE carrier in `model_type == 4`; report symbols
match Poisson/NB2 exactly. This is not `mc-0380` and not `mc-0719`. Gamma
stays rejected by the shared positive-continuous validator.

```text
y_ij | mu_ij, sigma ~ Lognormal(mu_ij, sigma)
mu_ij = X_ij β + b_0j + x_ij b_1j
(b_0j, b_1j)' ~ MVN(0, Σ_g)

Σ_g = [ sd0^2 ,           rho_re sd0 sd1 ]
      [ rho_re sd0 sd1 ,  sd1^2          ]
ρ = 0.999999 tanh(η)
u_cond,slope = ρ u_intercept + √(1-ρ²) u_slope
```

```r
drmTMB(
  bf(y ~ x + (1 + x | id), sigma ~ 1),
  family = lognormal(),
  data = dat
)
```

| Symbol | Extractor | Truth in `lognormal_q2_data()` |
| --- | --- | --- |
| `sd0` | `sdpars$mu["(1 + x \| id):(Intercept)"]` | 0.65 |
| `sd1` | `sdpars$mu["(1 + x \| id):x"]` | 0.42 |
| `rho_re` | `corpars$mu["cor((Intercept),x \| id)"]` = `0.999999 tanh(eta_cor_mu)` | 0.45 |

`obj$report()` carries `eta_cor_mu` and `rho_mu_re`. It does **not** carry
`logsech_mu_re`. Do not rewrite lognormal onto the binomial log-sech
factorisation in this wave. Later Wave 3 families remain one cell at a time.
