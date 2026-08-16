# 257 — Non-Gaussian ordinary correlated `(1 + x | g)` (binomial wedge)

**Date:** 2026-08-16  
**Lane:** `cursor/ng-correlated-slope-impl` (Wave 1 code + ledger; no merge to `main`; no CRAN; no missing-data / MSPL). Design freeze originated on `cursor/ng-correlated-slope-design` (#1057).  
**Readers:** the next implementer after win-builder unlock, plus Fisher / Noether / Boole on the later code PR.  
**Inventory this note implements:** slice 1 of
[`docs/dev-log/research/2026-08-16-nongaussian-re-remaining-fruit.md`](../dev-log/research/2026-08-16-nongaussian-re-remaining-fruit.md).  
**Numbering:** 256 is reserved by the foreign MSPL-boundary lane (`256-mspl-boundary-penalty-derivation.md` on `claude/mspl-boundary-s0-s1`). This note is 257.

This is a design and symbolic-alignment contract. It does not admit a family, flip a gate, or
authorize compute. Quiesce still holds for shipped files.

## Purpose

Ordinary non-Gaussian random intercepts `(1 | g)` and independent slopes `(0 + x | g)` already
fit. The remaining ordinary gap is the **correlated** intercept–slope block `(1 + x | g)`.
Binomial already has an experimental complete-data ML point-fit path. Every other fitted
univariate non-Gaussian family still rejects that block with a “planned” message.

The first post-quiesce code slice should make the binomial experimental path an honest
`point_fit_recovery` cell, then open a family menu behind the same map. Coverage and
`supported` are later arcs.

## Claim ceiling

| Stage | Maximum claim | Not this stage |
| --- | --- | --- |
| This note | Design freeze only | No ledger move |
| First code slice (after quiesce) | `point_fit_recovery` for **one** complete-data binomial unlabelled `(1 + x \| g)` ML-Laplace cell | Intervals, coverage, REML, AGHQ, `supported` |
| Family menu | `point_fit_recovery` per admitted family, one cell at a time | Inheritance from binomial |
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
- Context fence: `drm_validate_binomial_q2_context()` rejects `REML = TRUE` and
  missing-response rows before TMB construction.
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

**Wave 2 (after Wave 1 has a ledger cell).** Ordinary Poisson and ordinary NB2
`mu` only (no `zi`). These families already fit independent RI + slope and
reject correlated blocks with an explicit “later gate” message. Their
structured labelled q2 cells stay separate.

**Wave 3 (one family per PR).** lognormal, Gamma, beta, skew_normal, tweedie,
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
`(1 + x | g)` on the same group.

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

1. Rebase this branch (or a fresh `cursor/ng-correlated-slope-impl`) on then-current `main`.
2. Implement Wave 1 only: ledger cell, grammar honesty if the experimental
   wording is now stale, and any parser/report gap the alignment table
   exposes. Touch `src/drmTMB.cpp` only if the existing binomial q2 carrier
   cannot report the three symbols above.
3. Run the Totoro smoke. Do not open Wave 2 in the same PR.
4. Do not merge until Fisher + Noether read the alignment table against the
   fitted object.

## Stop

No C++ in this change. No API. No family-gate flip. No MSPL. No missing-data.
No CRAN submission. No merge to `main` that ships code. The next safe *code*
action is Wave 1 after win-builder unlock, from this note, not from the
gllvmTMB probe.
