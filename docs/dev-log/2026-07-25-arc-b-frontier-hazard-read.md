# Arc B slice S5 — frontier static hazard read (`src/drmTMB.cpp`)

**Auditor.** Rose (systems auditor).
**Date.** 2026-07-25.
**Worktree.** `/private/tmp/drmtmb-arc-b`, branch `claude/arc-b-numerical-audit`,
off `origin/main` `95f323e1`. All `file:line` citations below are from this
worktree and are authoritative for this report.
**Scope.** Static read of the *frontier* branches only: the separable-covariance
Cholesky helper and its q=4 bivariate phylogenetic call site, the `sd()`-regression
and scale-side random-effect `exp()` sites, the count/positive-family
`mu = exp(eta_mu)` sites, epsilon-literal drift between the inline branches and the
extracted leaf `src/drm_response_kernels.h`, and `model_type == 97`.
**Method.** Source reading plus one mechanical check (`clang++ -fsyntax-only -Wall`
over the translation unit). No fits were run; no profiler was run. **No
performance or efficiency claim appears in this report.**

**Classification.** Every finding is placed in one of the six guard classes from
`docs/design/176-numerical-guard-simulation-audit.md`: *domain transform*,
*model-defining restriction*, *density-domain floor*, *tail log floor*,
*likelihood-altering scale guard*, *starting-value floor*. Doc 176's position
(lines 13-19) is that the first three of those and starting-value floors are
legitimate; likelihood-altering guards are diagnostic safeguards, not evidence of
identifiability. That standard is applied here, which is why several patterns the
brief flagged are closed below as non-findings rather than filed as defects.

**Labels.** `CONFIRMED` = mechanism traced end-to-end in the source.
`PLAUSIBLE` = reachable but not demonstrated statically. Fact, inference and
speculation are marked inline.

**Prior work not redone.** Issue #710 (2026-07-02 drmTMB<->DRM.jl twin static
review) found six numerical-guard defects; five are fixed and merged
(#710.1, .3, .4, .5, .6), and only #710.2 (sigma-slope start-value bias
correction) remains open. Nothing below re-files any of those six.

---

## Findings table

| # | Severity | Doc-176 class | Site | Label | Public API? |
|---|---|---|---|---|---|
| F1 | Medium | Likelihood-altering scale guard (degenerate) | `src/drmTMB.cpp:192` | CONFIRMED (mechanism) | Yes, via optimizer path |
| F2 | Medium | Likelihood-altering scale guard (undisclosed) | `src/drmTMB.cpp:190-195` vs `docs/design/176-...md:1101-1104` | CONFIRMED | Yes |
| F3 | Low | Likelihood-altering scale guard (margin) | `src/drmTMB.cpp:192` | CONFIRMED | Only at q > 8 |
| F4 | Medium | Likelihood-altering scale guard (applied inconsistently) | `src/drmTMB.cpp:2766-2771` vs `2888-2891` | CONFIRMED | Yes |
| F5 | Low-Medium | Domain transform, unguarded where its sibling is guarded | `src/drmTMB.cpp:831, 921, 2279, 2815, 4107` | PLAUSIBLE | Yes |
| F6 | Low | Domain transform (legitimate); overflow only | `src/drmTMB.cpp:2667, 2714, 3391, 3447` | PLAUSIBLE | Yes |
| F7 | Low | Not a guard — latent maintenance hazard | `src/drm_response_kernels.h:72-76` | CONFIRMED (latent) | No (today) |
| F8 | Low | Not a guard — stale citation cluster | `R/family-dpq.R:618, 817, 930, 1034` (+ others) | CONFIRMED | n/a |
| F9 | Informational | Not a guard — dead code | `src/drmTMB.cpp:1149 … 2172` (12 sites) | CONFIRMED | n/a |
| F10 | Informational | Not a guard — unreachable branch | `src/drmTMB.cpp:537` | CONFIRMED | No |

---

## The Cholesky question (top-priority target)

`drm_separable_cov_logdet_quad` (`src/drmTMB.cpp:181-247`) hand-rolls a lower
Cholesky with `L(a,a) = sqrt(sum)` (line 207) and `L(a,b) = sum / L(b,b)`
(line 209), then divides by `L(a,a)` in both triangular solves (lines 228, 239).
There is no positive-definiteness test and no diagnostic. The only guard is the
ridge at line 192:

```cpp
Type ridge = Type(1e-12) * (trace_scale / Type(q));
```

Its only live call site is the bivariate phylogenetic q=4 location-scale-scale
block, `src/drmTMB.cpp:4359`. The other two (`:485`, `:526`) are the
`model_type == 93` and `94` probe codes.

### Verdict on "can a user reach a non-PD `S` and see a silent NaN?" — **No, not through the default public path.** This is a non-finding, and here is why, so it is not re-opened.

Two independent reasons, both traceable in the source:

1. **Both correlation builders return an exactly positive-semidefinite matrix.**
   The default is `qgt2_corr_parameterization = 0` (`R/drmTMB.R:17688-17689`,
   `getOption("drmTMB.internal.qgt2_corr_parameterization", 0L)`), which routes to
   `density::UNSTRUCTURED_CORR_t<Type>(theta).cov()` (`src/drmTMB.cpp:167-168`) —
   a Gram matrix of row-normalised vectors, hence PSD for every finite `theta`.
   The alternative builder `drm_partial_correlation_cholesky_corr`
   (`src/drmTMB.cpp:125-155`) is also PSD by construction: `remaining` is updated
   as `remaining *= 1 - partial*partial` with `partial = tanh(eta) in [-1, 1]`
   (lines 135-137), so `remaining >= 0` always and `sqrt(remaining)` at line 140
   never takes a negative argument. That builder's known hazard is the *gradient*
   at `|eta| ~ 20` (`d/dx sqrt(0)`), already recorded as an out-of-scope residual
   in doc 176 lines 1107-1117 — not a new finding, and it is an internal option,
   not a public control surface.
2. **The ridge dominates Cholesky round-off at the q this code runs at.** The
   standard backward-error bound for Cholesky is `||dS|| <= c_q * eps * ||S||`
   with `c_q = O(q^2)`; at q=4 that is roughly `4*5*1.1e-16 ~ 2e-15` relative,
   and the ridge is `1e-12` relative to `mean(diag(S))`. The ridge exceeds the
   round-off floor by about three orders of magnitude at q=4. (Fact: the bound is
   standard. Inference: the resulting margin. No numerical experiment was run.)

So the `sqrt` of a negative is not reachable from the default q=4 path. The ridge
form — scale-relative rather than absolute — is the right *form*, and doc 176's
rationale for it (lines 1096-1106) is sound. **The ridge nevertheless has three
real weaknesses, all of them about fidelity rather than about NaN.**

### F1 (CONFIRMED mechanism, PLAUSIBLE reachability) — the ridge is exactly zero at the one point where it is needed

`ridge = 1e-12 * trace_scale / q` is *multiplicative* in `trace(S)`. At the live
site, `sd_phylo = exp(log_sd_phylo)` (`src/drmTMB.cpp:4096`) and
`phylo_q4_covariance(a,b) = sd_phylo(a) * corr(a,b) * sd_phylo(b)`
(`src/drmTMB.cpp:4351-4352`). A diagonal entry is therefore
`exp(2 * log_sd_phylo(a))`, which underflows to exactly `0.0` in double once
`log_sd_phylo(a) < -372.5` (since `exp(-745)` is the underflow point). If all `q`
components underflow, `trace_scale == 0`, so `ridge == 0`, so `S` is the zero
matrix, so `L(0,0) = sqrt(0) = 0` (line 207), and the very next operation divides
by it (line 209 and again at 228/239) producing `Inf`/`NaN`, while `log_det`
becomes `-Inf` (line 217). The NLL is then `NaN`, not a clean `+Inf`.

Fact: the mechanism. Inference: reachability. `log_sd_phylo` is a free
`PARAMETER_VECTOR` (`src/drmTMB.cpp:421`) with no bound and no clamp — note that
`drm_softclamp_log_sigma` protects only the *residual* `log_sigma`
(`src/drmTMB.cpp:690, 4399-4404`), never an RE log-SD. An unidentified variance
component drives its log-SD monotonically toward `-Inf`, which is a routine
optimizer behaviour; whether `nlminb` in practice steps past `-372` before it
stops is not demonstrated here. Speculation, flagged as such: it is more likely
in the frontier fixtures (bivariate phylo q4 location-scale-scale) than in
ordinary q2 fits, because those are where components are least identified.

Safeguard: make the ridge additive-floored rather than purely multiplicative, e.g.
`ridge = CppAD::CondExpGt(rel, abs_floor, rel, abs_floor)`. One line, no change to
well-posed behaviour.

### F2 (CONFIRMED) — the ridge is trace-relative, not diagonal-relative, so the doc's "no-op" claim is conditional and the condition is unstated

`src/drmTMB.cpp:180` says the ridge "is negligible for well-posed fits", and doc
176 lines 1101-1104 says it "is a no-op for well-posed fits (existing q4/q8
phylo, animal, relmat, and spatial tests pass unchanged)". Both statements are
true only when the `q` diagonal entries of `S` are on comparable scales. The ridge
added to *every* diagonal is `1e-12 * mean(diag(S))`, so for a component with
`sd(a)^2 << mean(diag(S))` the added mass is not negligible relative to that
component. The relative inflation of component `a` is
`1e-12 * mean(diag(S)) / sd(a)^2`.

This matters specifically at the live site, and it is a frontier-only problem:
the q=4 bivariate location-scale-scale phylogenetic block mixes **mu-side SDs in
response units** with **scale-side SDs in log units** in one covariance. A
response measured on an unscaled instrument scale (mass in grams, counts in
thousands) with `sd_mu ~ 1e4` and a log-SD field with `sd ~ 1e-2` gives
`mean(diag(S)) ~ 5e7` and `sd_sigma^2 = 1e-4`, i.e. a ridge of `5e-5` on a
variance of `1e-4` — a ~50% silent inflation of the scale-side variance
component, with no warning and no `REPORT`ed flag.

Doc-176 class: this is a **likelihood-altering scale guard**. Under doc 176's own
standard (lines 13-19) that is permitted as a diagnostic safeguard but requires
"an honest explanation of the guard and a diagnostic when it is active" (doc 176
lines 22-24). Neither exists: the helper `REPORT`s no PD or ridge-activity status,
so nothing on the R side can distinguish "the ridge was load-bearing" from
"well-posed". The evidence cited for the no-op claim (q4/q8 phylo, animal,
relmat, spatial tests passing) is evidence under scale homogeneity only; those
fixtures do not vary the cross-component scale ratio.

Safeguard: either make the ridge diagonal-relative
(`S(a,a) += 1e-12 * S(a,a)`), which removes the failure entirely and is a strict
improvement in fidelity, or keep the trace form and `REPORT` a ridge-to-min-diagonal
ratio that `check_drm()` can surface. Additionally, a test cell that sets the
mu-side and sigma-side phylo SDs three or more orders of magnitude apart would
convert this from static reasoning to measured evidence — no such cell exists
today.

### F3 (CONFIRMED, low) — the PD margin degrades as roughly `q^-3`

Ridge relative to `||S||` is at least `1e-12 / q`; the round-off floor grows as
`O(q^2) * eps`. The ratio therefore shrinks like `q^-3`: about `1e3` at q=4, about
`15` at q=8, and about `2` at q=16. `q_phylo = log_sd_phylo.size()`
(`src/drmTMB.cpp:4094`) is not bounded in the C++ and the design docs already
exercise q=8. This is adequate today and would not be adequate if `q` grows.
Speculation flagged: the exact crossover depends on the conditioning of `R`, which
was not measured.

### Probe-only, one line: `model_type == 94` (`src/drmTMB.cpp:499-534`)

That probe passes `re_cov_probe_covariance` — a `DATA` matrix — straight into the
helper (`src/drmTMB.cpp:526`). An *indefinite* input (as opposed to the
rank-deficient one doc 176 line 1105 reports testing) will take `sqrt` of a
negative and return a silent `NaN`. Probe-only, no R-side construction path, so
this is recorded for completeness rather than filed.

---

## F4 (CONFIRMED) — beta family: the mi() rows bypass the log-sigma clamp

In `model_type == 10` the missing-predictor 2-point sum calls the shared leaf at
`src/drmTMB.cpp:2766-2771`, passing `log_sigma(i)`. The soft clamp is applied to
`log_sigma` only afterwards, at `src/drmTMB.cpp:2888-2891`. The main density loop
(`:2896-2925`) therefore uses **clamped** `log_sigma`, while rows with a missing
predictor get their response density at **unclamped** `log_sigma`. One dataset,
two different scale guards.

This is a genuine drift, not a stylistic one, because the sibling branch does it
the other way: `model_type == 7` (nbinom2) clamps at `src/drmTMB.cpp:3606-3609`
*before* its leaf call at `:3633-3638`. Same construction, opposite order.

Reachability is real, not hypothetical. The clamp is **on by default** with band
`c(-12, 12)` (`R/control.R:134-135`). For the beta family the precision is
`phi = exp(-2 * log_sigma)` (`src/drmTMB.cpp:2897`), so `log_sigma = -12`
corresponds to `phi ~ 2.6e10`; a high-precision beta fit can push `log_sigma`
below the lower band edge, at which point the clamp becomes active for observed
rows and inactive for missing-predictor rows. At the extreme
(`log_sigma < -354`), `phi` overflows to `Inf` and `lgamma(Inf)` gives `NaN` —
which is precisely what the clamp exists to prevent (`src/drmTMB.cpp:18-24`).

Doc-176 class: **likelihood-altering scale guard, applied inconsistently within a
single likelihood**. Safeguard: move the clamp block above the `has_mi` block in
`model_type == 10`, matching `model_type == 7`; add a test that fits a beta model
with `mi()` and a `log_sigma` below the band and asserts the mi and non-mi rows
agree on `sigma`.

## F5 (PLAUSIBLE) — `sd()` regression: `exp()` of an unbounded linear predictor, unguarded

`sd_mu_group(g) = exp(eta_sd)` where `eta_sd = X_sd_mu %*% beta_sd_mu`, at
`src/drmTMB.cpp:831` (mu-side RE SD, Gaussian), `:921` (phylo SD, Gaussian),
`:2279` (Student-t), `:2815` (beta phylo SD), `:4107` (bivariate phylo SD). The
resulting SD multiplies the random effect and enters the linear predictor
(e.g. `src/drmTMB.cpp:845-846`, `4130-4137`). There is no clamp, no bound, no
`CondExp`.

Doc-176 class: `exp()` here is a **domain transform** and is legitimate in form —
an SD must be positive. The finding is not the `exp`, it is the **asymmetry in the
project's own protective reasoning**:

- residual `log_sigma`: soft-clamped, on by default (`src/drmTMB.cpp:690`, `R/control.R:134`);
- every correlation: bounded by `0.999999 * tanh` (`src/drmTMB.cpp:836, 4304, 4200`);
- a *regression-predicted* RE log-SD: nothing.

The justification recorded for the `log_sigma` clamp (`src/drmTMB.cpp:20-24`,
doc 170) is that "a runaway per-observation scale — e.g. a per-group scale random
effect estimated from one observation per group — is therefore bounded and cannot
overflow the Gaussian density or break the inner Laplace solve". That argument
applies verbatim to `sd_mu_group(g) = exp(X_sd_mu %*% beta_sd_mu)` in a
sparsely-populated group, and it is not applied there. Inference, not
demonstration: no fit was run to show `eta_sd > 709`.

Scope note, verified: there is **no** sigma-side `sd()` regression —
`grep` for `X_sd_sigma` / `has_sd_sigma_model` / `sd_sigma_group` in
`src/drmTMB.cpp` returns nothing. `sd()` regression exists on the mu side and the
phylo side only. Scale-side RE SDs are plain parameters
(`sd_sigma_re = exp(log_sd_sigma)`, `src/drmTMB.cpp:862, 2307, 2550, 2649`),
which is an ordinary domain transform and a non-finding.

Safeguard: reuse `drm_softclamp_log_sigma` on `eta_sd` before the `exp`, gated by
the same `use_logsigma_clamp` switch, so one control governs every predicted
log-scale. That keeps the existing "exactly identity inside the band" property, so
well-posed fits are bit-unchanged.

## F6 (PLAUSIBLE, low) — `mu = exp(eta_mu)`: four live sites, not eight

The brief listed eight count/positive-family sites. Reading each, **only four feed
the likelihood**:

- `src/drmTMB.cpp:2667` (gamma) — `scale = mu(i) * variance_multiplier`, in the density;
- `:2714` (tweedie) — `dtweedie(y(i), mu(i), phi(i), nu(i), true)`;
- `:3391` (poisson) — `dpois(y(i), mu(i), true)`;
- `:3447` (zi_poisson) — `logspace_add(log_zi, log_one_minus_zi - mu(i))` and `dpois(y(i), mu(i), true)`.

The other four are **report-only or derived-quantity-only**, and are a non-finding:

- `:3605` (nbinom2), `:3845` (zi_nbinom2) — the density is
  `drm_nbinom2_log_density(y(i), eta_mu(i), log_sigma(i))`, taking the raw linear
  predictor; `mu` is only `REPORT`ed;
- `:3691` (truncated_nbinom2), `:3763` (hurdle_nbinom2) — `mu` enters only
  `positive_mean(i) = mu(i) / trunc_prob(i)` (`:3703`, `:3777`), which is
  `REPORT`ed (`:3715`, `:3800`) and not part of `nll`.

For the four live sites: doc-176 class is **domain transform** — a log link
defines the legal mean space, and under doc 176's standard that is legitimate and
needs no guard. The only residual is `exp` overflow for `eta_mu > 709` giving
`Inf` and then `NaN`, which is standard TMB behaviour that the optimizer handles
by backtracking. This is recorded so it is not re-opened, **not** filed as a
defect. It is worth noting only that the same asymmetry as F5 applies: the scale
side is hardened against runaway per-observation values and the mean side is not,
even though a mu-side RE in a count model with a log link has the identical
failure mode inside the inner Laplace solve.

---

## Epsilon-literal drift — mostly a clean bill, with one exception

Census over `src/drmTMB.cpp`, `src/drm_numeric.h`, `src/drm_count_kernels.h`,
`src/drm_response_kernels.h`:

- **`1e-300` (11 sites) — no drift.** Eight identical
  `CondExpGt(prior_norm, 1e-300, prior_norm, 1e-300)` MI prior-normaliser floors
  (`src/drmTMB.cpp:1438, 1584, 1765, 1851, 1956, 2032, 2120, 2214` — the #710.6
  fix), two additive `exp(2*log_sigma) + 1e-300` dispersion floors
  (`src/drm_count_kernels.h:33, 46`), and one `log(skew_cdf + 1e-300)` tail log
  floor (`src/drmTMB.cpp:2473`). Same constant, consistent role, two idioms
  (conditional vs additive) that are each appropriate to their site. Doc-176
  class: density-domain floor / tail log floor. **Non-finding.**
- **`1e-8` beta shape floor (6 sites) — no drift.** `src/drmTMB.cpp:1362, 1478,
  1617, 2896, 2975` and `src/drm_response_kernels.h:58`. Identical value,
  identical `CondExpLt` idiom. Doc-176 class: density-domain floor.
  **Non-finding.**
- **`1e-12` (6 sites) — no numerical drift, but the literal is overloaded.** Five
  sites are the beta mean nudge `beta_mu_eps` / `beta_mi_eps`
  (`src/drmTMB.cpp:1350, 1466, 2882, 2959`, `src/drm_response_kernels.h:57`); one
  is the Cholesky ridge (`src/drmTMB.cpp:192`). These are semantically unrelated —
  a density-domain floor and a scale guard — sharing one literal. That is a
  terminology-drift risk for a future reader, not a defect today. Recorded as a
  naming observation.
- **The extracted leaf `src/drm_response_kernels.h` has NOT drifted from the
  inline branches.** Case 10 (`:56-70`) reproduces `src/drmTMB.cpp:2882-2925`
  constant-for-constant and expression-for-expression. Case 1 (`:27-31`) matches
  the mi()-branch form and the header itself already documents (`:29-31`) that it
  is deliberately not bit-identical to the vanilla no-mi `sigma*sigma` precompute.
  The one genuine inconsistency between leaf and branch is **F4 above, and it is
  an ordering problem, not an epsilon problem.**

### Non-finding, stated so it is not re-opened: the beta-binomial mi prior omits the mean nudge

`src/drmTMB.cpp:1611` uses `mi_mean(i) = 1.0 / (1.0 + exp(-mi_eta(i)))` with no
`beta_mi_eps` nudge, where the beta mi prior at `:1354-1356` uses
`exp(drm_log_inv_logit(...))` plus the nudge. This looks like drift and is not:
the beta-binomial log-density (`:1633-1644`) has no `log(y)` / `log(1-y)` term, so
a mean of exactly 0 or 1 is not a density-domain violation there, and the shared
`1e-8` shape floor (`:1617-1628`) already catches the resulting zero shape.
Defensible as written.

## F7 (CONFIRMED latent) — the leaf's `default:` returns zero log-density silently

`src/drm_response_kernels.h:72-76` ends the family switch with
`default: return Type(0.0);`. Every current call site is inside a matching
`model_type` branch — the mi() sites at `src/drmTMB.cpp:1151-2173` are all inside
`model_type == 1` (branch `:686-2335`), `:2766/2770` inside `model_type == 10`,
`:3131/3135` inside `18`, `:3372/3374` inside `6`, `:3633/3637` inside `7` — and
cases exist for 1, 6, 7, 10 and 18. So the `default:` is **unreachable today**;
that is fact, not inference.

The hazard is latent and it is a maintenance hazard: adding an mi() call site for
a family whose case is missing produces a **silently zero log-density
contribution** — a wrong answer with no error, no warning, and no `NaN` to trip
the optimizer. The header's own P3 note (`:73-75`) says the remaining families
"are added in P3", so this path is on the near-term roadmap. Safeguard: replace
the `default:` with `Rf_error` / `TMBad`-safe abort, or at minimum return a `NaN`
so the failure is loud.

## F8 (CONFIRMED) — the R-side dpq mirrors cite compiled-kernel line ranges that have rotted

`R/family-dpq.R` documents each R mirror by citing the exact `src/drmTMB.cpp`
lines it claims to match. Several anchors now point at the wrong family. Verified
by reading the cited line and the current branch map:

| `R/family-dpq.R` claim | Cited line actually contains | Actual branch |
|---|---|---|
| `:618` — "src/drmTMB.cpp:2886-2892, model_type == 14" | line 2886 is the beta mean nudge, inside `model_type == 10` | `model_type == 14` is `:3030-3088` |
| `:817` — "src/drmTMB.cpp:3184-3195, model_type == 6" | line 3184 is a `u_mu` prior loop inside `model_type == 13` | `model_type == 6` is `:3259-3403` |
| `:930` — "src/drmTMB.cpp:3463-3510, model_type == 11" | line 3463 is `REPORT(zi)` inside `model_type == 8` | `model_type == 11` is `:3670-3718` |
| `:1034` — "src/drmTMB.cpp:3598-3668, model_type == 9" | line 3598 is inside `model_type == 7` | `model_type == 9` is `:3805-3876` |

Others (`:485` for `model_type == 10`, `:416` for `4`) still resolve correctly, so
this is drift, not wholesale rot: the file was written when the anchors were true
and has not been re-anchored as the C++ grew. It is not a numerical defect, but it
matters more than a typo would, because these comments are the *audit trail* for
the claim that the R dpq functions reproduce the compiled kernel exactly. A reader
verifying that claim is sent to the wrong family. Safeguard: replace line-number
anchors with searchable markers (e.g. a `// [dpq-anchor: nbinom2]` comment in the
C++ that the R comment names), and add a `testthat` check that each named anchor
resolves to exactly one site — line numbers cannot be kept correct by discipline
alone.

## F9 (CONFIRMED) — the dead `sigma_i` count is **12, not 3**

The brief reported `warning: unused variable 'sigma_i'` at
`src/drmTMB.cpp:1995, 2079, 2172`. Measured, not inferred — a syntax-only compile
of the translation unit against the installed TMB/RcppEigen/R headers
(`clang++ -fsyntax-only -Wall`) emits **exactly 12** such warnings and **no other
warning of any kind**:

```
src/drmTMB.cpp:1149, 1232, 1312, 1397, 1535, 1666, 1728, 1810, 1914, 1995, 2079, 2172
```

`grep -n "sigma_i" src/drmTMB.cpp` returns those 12 declarations and **zero
reads**. So all 12 are dead; the three in the recon note are a subset. (Why the
recon captured only three is not established — plausibly a truncated build log.
Flagged as inference.)

### Determination requested by the brief: **harmless residue, and positive evidence *against* drift.**

At each of the 12 sites the dead local is immediately followed by a call to
`drm_response_log_density(model_type, y(i), mu_q, log_sigma(i), V_known(i), ...)`,
and that leaf's case 1 (`src/drm_response_kernels.h:27-31`) recomputes
`sqrt(V_known_val + exp(Type(2.0) * log_sigma_val))` from the same two arguments —
the identical expression, character for character. The dead variable is therefore
a *frozen copy of the pre-extraction inline computation*, and the fact that it
matches the leaf is direct evidence that the extraction preserved the formula.
It is an accidental regression oracle. It is **not** evidence that the leaf and
the inline branch disagree.

Nothing here is a correctness problem. The reporting is: a build that emits 12
warnings is a build whose warnings will stop being read. Safeguard: delete all 12
declarations in one change (they have no side effects — `sqrt` and `exp` on a TMB
`Type` do tape operations, so removal shrinks the tape but the tape's *value* is
unchanged since the results feed nothing), and keep the translation unit at zero
warnings so the next real one is visible.

## F10 (CONFIRMED, informational) — `model_type == 97` is dead code

`model_type == 97` enters the shared `95 || 96 || 97` probe setup at
`src/drmTMB.cpp:537` with no family body of its own, and `grep` across `R/` finds
no construction site for `97` (nor for `95`/`96`, which are also probe-only). It
is unreachable. One line, as requested; no investigation performed.

---

## What was deliberately closed as a non-finding

Recorded so a later session does not spend the same effort:

1. **`sqrt` of a negative in the Cholesky, reached from the public API.** Not
   reachable — both correlation builders are exactly PSD and the ridge dominates
   round-off at q<=8. Reasons above.
2. **`mu = exp(eta_mu)` at nbinom2, zi_nbinom2, truncated_nbinom2,
   hurdle_nbinom2** (`:3605, 3691, 3763, 3845`). Report/derived-quantity only; the
   densities take `eta`. Four of the eight sites in the brief are not live.
3. **`mu = exp(eta_mu)` as a guard-class defect** at the four live sites. Under
   doc 176 a log link is a domain transform and is legitimate; only the overflow
   note stands, and that is ordinary TMB behaviour.
4. **`1e-300` and `1e-8` families.** No drift; consistent idioms; correct
   doc-176 classes.
5. **The extracted leaf's constants.** No drift from the inline branches; the
   header's byte-identity claim for the Gaussian case holds, with the one
   documented and deliberate exception it already states.
6. **Scale-side RE SDs as plain parameters** (`exp(log_sd_sigma)`). Ordinary
   domain transform.
7. **Beta-binomial mi prior omitting the mean nudge.** Justified by the absence of
   a `log(y)` term in that density.
8. **`drm_partial_correlation_cholesky_corr` gradient at `|eta| ~ 20`.** Already
   recorded in doc 176 lines 1107-1117; internal option only; not re-filed.

## Missing feedback loops

Three, in priority order:

1. **The Cholesky helper reports no state.** It has a guard that can silently
   change the likelihood (F1, F2) and nothing downstream can observe whether it
   fired. Everything else in this package that alters a likelihood — the
   `log_sigma` clamp, the correlation bounds — has at least a `REPORT` or a
   `check_drm()` surface. Adding a `REPORT`ed ridge-activity ratio closes the loop
   at near-zero cost.
2. **No fixture varies cross-component scale in the q=4 covariance.** The "no-op"
   evidence in doc 176 was collected under scale homogeneity, which is exactly the
   condition under which the claim is trivially true. One cell with a 1e3-1e6 SD
   ratio between the mu-side and sigma-side phylo blocks would settle F2
   empirically.
3. **Compiled-kernel line anchors in `R/` are unverified by any test.** F8 shows
   they rot. This is the same class of problem as a stale doc claim, and the same
   fix applies: make the claim machine-checkable or stop making it.

## Concrete next safeguards

1. Floor the ridge absolutely as well as relatively (`src/drmTMB.cpp:192`) — one
   line, removes F1.
2. Make the ridge diagonal-relative, or `REPORT` its activity — removes or
   surfaces F2. Update `src/drmTMB.cpp:180` and doc 176 lines 1101-1104 to state
   the scale-homogeneity condition either way.
3. Move the clamp above the `has_mi` block in `model_type == 10`
   (`src/drmTMB.cpp:2888` before `:2745`), matching `model_type == 7` — removes F4.
   Add the mi/non-mi `sigma` agreement test.
4. Replace `default: return Type(0.0);` in `src/drm_response_kernels.h:74` with a
   loud failure — removes F7 before P3 lands.
5. Delete all 12 dead `sigma_i` declarations and hold the translation unit at zero
   warnings — removes F9.
6. Re-anchor `R/family-dpq.R` to named markers and test that each resolves —
   removes F8 and prevents recurrence.
7. Add a q=4 phylo fixture with a large cross-component SD ratio, and a fixture
   that drives a phylo log-SD toward `-Inf`, so F1 and F2 have measured evidence
   rather than static reasoning.

## Limitations of this read

- No fits were run and no numerical experiment was performed. The round-off
  arguments in F1/F3 rest on the standard Cholesky backward-error bound, applied
  as inference.
- Reachability for F1, F5 and F6 is argued from the absence of bounds on the
  relevant parameters, not demonstrated by an optimizer trace.
- The only mechanically verified claim in this report is F9 (the warning count),
  plus every `file:line` citation, which were read directly.
- No performance or efficiency claim is made anywhere above; no profiler was run.
- Only the frontier branches named in the slice brief were read. The bivariate
  Gaussian core, the ordinal branch, the AGHQ path, and the spatial/SPDE code were
  not audited here.
