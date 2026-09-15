# 275 — Repeatability scale (D-252/#1301) and residual-variance mechanism (S2/#1301-comment)

## 1. Purpose and reader

For the next contributor touching `summary()$derived`,
`heritability()`/`icc()`/`repeatability()`, or `drm_constant_residual_sigma()`,
and for Shinichi as decision-maker on the open question in section 5. Two
audit findings landed on the same code path but are different defects: issue
#1301 (a scale-*naming* audit against de Villemereuil, Schielzeth, Nakagawa &
Morrissey 2016, *Genetics* 204:1281-1294, "the paper") and Russell Dinnage's
S2 comment on #1301 (a residual-variance *aggregation* bug). This note answers
#1301's four checks with file:line evidence, derives Russell's mechanism, and
proposes a fix for the next slice without applying it here.

## 2. The two questions being reconciled

**#1301** asks which of the paper's three scales (Eq 3a-3c: latent `ℓ`,
expected data `η = g⁻¹(ℓ)`, observed data `z ~ D(η,θ)`) a reported
repeatability/heritability/ICC lives on, whether the docs say so, whether a
link/distribution variance is ever added and mislabelled "latent" (that is
the *liability* scale, Eq 24; p1287 says explicitly it "is not the same as
the latent scale"), and whether a latent value is ever refused where Eq 4 is
defined.

**Russell's S2 comment** asks whether the code computes the right residual
variance at all: `drm_constant_residual_sigma()` returns the *median*
residual sigma (`exp(beta0^sigma)`), not `E[sigma^2]^{1/2}`, whenever `sigma`
is not constant.

These are independent: #1301 is about which of three well-defined quantities
a number represents; Russell's is about whether the ingredient feeding all
three (the residual term) is arithmetically correct once a random effect on
`sigma` exists. Section 3 answers #1301; section 4 answers Russell; section 5
fixes Russell's defect and argues it need not wait for #1301's decision.

## 3. Answers to #1301's four checks for drmTMB

Both loci #1301 asks about — `summary()$derived`'s
`total_variance_share`/`phylo_total_variance_share` rows
(`drm_derived_summary_rows()`, `R/methods.R:4553-4622`) and
`heritability()`/`icc()`/`repeatability()` (`drm_variance_ratio()`,
`R/heritability.R:266-348`) — are gated to `object$model$model_type ==
"gaussian"` (`R/methods.R:4554`; `R/heritability.R:279-280`), which answers
all four checks at once.

**(i) Which scale, and do the docs say so?** For a Gaussian fit with an
identity-link mean, Eq 3b's `g` is the identity, so `ℓ = η`, and the Gaussian
observation mean is `η` itself: **latent = expected = observed** for the
response. `sigma^2` here fills the role of `V_O` (Eq 3a) directly — no
addition or subtraction is needed to reach Eq 4's shape. A separate, unrelated
log link operates on the `sigma` *parameter* itself (`drm_dpar_link(object,
"sigma") == "log"`, checked at `R/methods.R:4653`), purely as a positivity
transform for the working parameter — not the paper's mean-structure link,
and not a distinct scale for the reported ratio. It is, however, exactly why
a random effect can live on `log(sigma)` unnoticed (section 4).
**Gap**: neither `man/summary.drmTMB.Rd` (lines 60-70) nor `?heritability`/
`docs/design/259-heritability-icc-repeatability.md` states this
latent-equals-observed coincidence; both describe only the denominator
distinction (total vs focal). Section 7 drafts the missing sentence.

**(ii) Is a link/distribution variance added?** No. `drm_derived_summary_rows()`
computes `denominator <- total_re_var + residual_variance`
(`R/methods.R:4591`, `residual_variance <- sigma^2` at `R/methods.R:4577`);
`drm_variance_ratio()` builds `denom_positions` from the same `sdpars$mu` SDs
plus the `beta_sigma` residual position (`R/heritability.R:315-320`). Neither
adds `pi^2/3`, `1`, or `pi^2/6` (Eq 24's `V_L`) — both are Eq 4's shape with
`V_L = 0`, correct because `V_L` applies only to binomial/threshold families,
which the Gaussian-only gate excludes structurally.

**(iii) Is a latent value ever refused where Eq 4 is defined?** For
`heritability()`/`icc()`/`repeatability()`: refused loudly, `cli::cli_abort()`
at `R/heritability.R:279-280` ("requires a Gaussian model_type fit") — not
`NA`/`NaN`. For `summary()$derived`: refused quietly — a non-Gaussian fit
returns `empty_derived_summary_parameters()` (`R/methods.R:4554-4556`), an
empty data frame, also not `NaN` but a silent omission rather than a named
message. **This refusal is a FEATURE decision, not a naming bug**: drmTMB has
not implemented Eq 4/24/26-28 for non-Gaussian families, so it neither
computes nor mislabels a latent-scale value for them. What that feature would
need, from D-252 and the paper:

```
ℓ = μ + Xb + Z_a a + … + o        (3a)  latent;  o = overdispersion, var V_O
η = g⁻¹(ℓ)                        (3b)  expected-data scale
z ~ D(η, θ)                       (3c)  observed-data scale

h2_latent    = V_A,ℓ / (V_A,ℓ + V_RE + V_O)                                        (4)   every family, no link/distribution variance
h2_liability = V_A,ℓ / (V_A,ℓ + V_RE + V_O + V_L)                                  (24)  binomial/threshold only
lambda       = exp(mu + (V_A,ℓ + V_RE + V_O)/2)                                   (27)  Poisson-log, exact
h2_observed  = lambda*(exp(V_A,ℓ) - 1) / (lambda*[exp(V_A,ℓ+V_RE+V_O) - 1] + 1)   (28)  Poisson-log ICC/repeatability, exact
```

Eq 28 makes the `ln(1+1/lambda)` distribution-specific-variance approximation
(Nakagawa & Schielzeth 2010) unnecessary for Poisson-log repeatability: an
exact result already exists.

**(iv) Does any phylo-signal accessor share the same denominator?** Yes, the
same code path. `grep -n "drm_constant_residual_sigma"` over `R/` returns
exactly two call sites: `R/methods.R:4557` and `R/heritability.R:285`. No
separate "phylo_signal"/"lambda" accessor exists (`grep -n
"phylo_signal\|phylogenetic_signal"` over `R/` and `man/` finds only a
roxygen note at `R/heritability.R:25` and `man/heritability.Rd:98` recording
that `phylo_total_variance_share` and `heritability()` were both called
`phylogenetic_signal` before a 2026-09-03 rename, D-213). The
`phylo_total_variance_share` row is built with the identical `sigma <-
drm_constant_residual_sigma(object)` call used for the ordinary
`total_variance_share` row (shared before the per-row `lapply` at
`R/methods.R:4557`), and `heritability()`'s own roxygen (`R/heritability.R:9-11`)
names itself "the comparative-biology 'phylogenetic signal' definition." The
phylogenetic quantity inherits the S2 defect exactly as ordinary
repeatability does — same function, same bug.

## 4. Russell's S2 mechanism

`drm_constant_residual_sigma()` (`R/methods.R:4650-4668`) returns
`exp(unname(beta[[1L]]))` — `exp(b0)`, `b0` the fixed intercept on
`log(sigma)`. Its only guards (one `(Intercept)` coefficient, log link, no
known-variance override) do not detect an *additional* random intercept on
`log(sigma)`. When one exists with SD `omega` (`sigma(u) = exp(b0+u)`,
`u ~ N(0,omega^2)`), `exp(b0)` is sigma's **median**, not its RMS.

**Derivation.** For lognormal `exp(t*u)`, `E[exp(t*u)] = exp(t^2*omega^2/2)`.
With `t=2`:

```
E[sigma(u)^2] = exp(2*b0) * E[exp(2*u)] = exp(2*b0 + 2*omega^2)
```

so the correct residual SD is `sqrt(E[sigma^2]) = exp(b0 + omega^2)`, larger
than the median `exp(b0)` by `exp(omega^2)` on the SD scale (`exp(2*omega^2)`
on the variance scale), growing with `omega`.

**Checking Russell's numbers.** The issue text's proof that
`residual_sd == exp(beta0^sigma)` to `0.000e+00` max abs. difference matches
this derivation exactly — the mechanism is confirmed. The reported
*magnitudes* (+60.6% at `omega=0.8`, +8.51% at `omega=0.4`) are errors in the
final **ratio** `re_variance/(total_re_var+residual_variance)`, not in
`sigma^2` alone, so they also depend on `total_re_var`'s size relative to the
residual — not stated in the issue text. This note's pure sigma-moment bias,
`exp(2*omega^2)-1`, is **+260%** at `omega=0.8` and **+37.7%** at `omega=0.4`
— both larger than Russell's ratio-level figures, as expected, since mixing
in `total_re_var` always attenuates a ratio-level error. Write the
ratio-level error as `r_wrong/r_true - 1 = (k-1)*s2/(V+s2)` with
`k = exp(2*omega^2)`, `s2` the true residual variance, `V` the RE variance.
The factor `s2/(V+s2)` is common to both `omega` settings, so it **cancels
in the ratio of ratios**: the pure-variance-**excess** ratio is
`(e^1.28-1)/(e^0.32-1) = 6.885` (not `exp(1.28)/exp(0.32) = 2.612`), and
this prediction is **exact**, independent of the unknown `total_re_var`.
The ratio of Russell's two figures (`60.6/8.51 = 7.121`) matches it to
**3.4%**. Better still, inverting either figure recovers the missing
ingredient: `0.606/(e^1.28-1) = 0.2334` and `0.0851/(e^0.32-1) = 0.2257` —
two independent estimates of `s2/(V+s2)` agreeing to 3%, implying
`V ~ 3.3*s2`. **Conclusion: the mechanism matches exactly (verified); the
direction and growth with `omega` match (verified); the precise
60.6%/8.51% figures ARE independently re-derivable from the issue text
alone via this ratio-of-ratios argument — the mechanism is quantitatively
confirmed, not merely plausible.**

## 5. The proposed fix (for the next slice, not applied here)

Detect a random effect on `sigma` through the sources
`has_sigma_random_effects()` already reads (`R/methods.R:6182-6190`):
`object$random_effects$sigma$values` and `object$model$structured$phylo_mu$has`
restricted to `sigma` dpars. The corrected `drm_constant_residual_sigma()`:

- **No random effect on `sigma`** (current guarded case): `exp(b0)`,
  unchanged — must not regress.
- **One or more ordinary random intercepts on `sigma`** with working-scale
  SDs `omega_1,…,omega_k` (possibly crossed): `exp(b0 + sum_k(omega_k^2))`,
  the direct generalisation of section 4's derivation.
- **A phylogenetic random effect on `sigma` on drmTMB's default
  `correlation = TRUE` scale**: the **same** `exp(b0 + omega^2)` form, not
  `NA`. The tree correlation matrix governs only the *joint* law of the tip
  effects; a residual variance is a *per-observation marginal* moment, and
  with `u ~ N(0, omega^2 * C)`, `C_ii = 1` for every tip under
  `correlation = TRUE` — `drm_phylo_tip_covariance()` divides by
  `info$height` at `R/phylo-utils.R:251-253` and enforces ultrametricity for
  exactly that path via `require_ultrametric = correlation`
  (`R/phylo-utils.R:226, 273`; `R/phylo-utils.R:109-113` explains that the
  scalar height normalisation is what requires it; `R/julia-bridge.R:487`
  records the same convention). So `E[sigma_i^2] = exp(2*b0 + 2*omega^2)`
  identically across tips, and `C` cancels out entirely — the same
  derivation as the ordinary-random-intercept case above.
- **A phylogenetic random effect on `sigma` on the `correlation = FALSE`
  (raw branch-length, non-ultrametric) path**: `NA_real_` with a message
  naming why. There the diagonal of the structured matrix is the
  root-to-tip depth and varies by tip, so `E[sigma_i^2] = exp(2*b0 +
  2*omega^2*V_ii)` differs per observation and no single scalar residual
  exists.
- **A random slope on `sigma`**: `NA_real_` with a message naming why (the
  marginal variance depends on the covariate value, so the quantity is
  design-dependent and a scalar would be a fiction) — **never** the
  silently wrong `exp(b0)`, mirroring
  `drm_variance_ratio_reject_random_slopes()`'s pattern for `mu`. (A
  design-averaged value is computable and could be offered later, but only
  as a named, documented estimand.)

`drm_derived_summary_rows()` inherits the corrected value or the refusal
directly: `residual_variance <- sigma^2` at `R/methods.R:4577` consumes
`drm_constant_residual_sigma()`'s return value (called at `R/methods.R:4557`)
with no further change.

`drm_variance_ratio()` does **not** inherit it automatically and needs its
own change. It uses `drm_constant_residual_sigma()` (called at
`R/heritability.R:285`) only as a finiteness gate
(`R/heritability.R:285-291`) and then rebuilds the residual from
`beta_sigma` (`resid_position` at `R/heritability.R:306`, folded into
`denom_positions` at `R/heritability.R:318`) inside
`drm_variance_ratio_delta()` (`R/heritability.R:465-495`), which computes
`exp(2*theta[focal]) / sum(exp(2*theta[denom]))` directly from
`object$opt$par` — so the residual enters as `exp(2*beta_sigma)`, the median
squared, regardless of what the helper returns. The fix must therefore also
change `drm_variance_ratio_delta()`: (a) the residual entry of
`denom_positions` must resolve to the corrected `log`-residual-SD position,
not `beta_sigma` alone, whenever a detected random effect exists on `sigma`;
and (b) because the corrected residual `exp(2*b0 + 2*sum_k omega_k^2)` is a
function of the `omega_k`, the delta-method gradient must extend over the
`log_sd_sigma` positions and `cov_fixed` must be indexed accordingly — both
the point estimate and the delta-method SE change, or the fix understates
uncertainty in exactly the regime it exists for.

The refusal message must move with the return value at both call sites.
`drm_variance_ratio()`'s existing abort text at `R/heritability.R:287-290`
("This fit has a `sigma` predictor, a non-log link, or a known-dispersion
override...") is false under the `NA` branch — a random-slope-on-`sigma` or
`correlation = FALSE`-phylo-on-`sigma` fit is none of those — and must be
updated to name the actual reason. `drm_derived_summary_rows()` currently
converts a non-finite `sigma` into a **silent** empty frame
(`R/methods.R:4558-4560`) with no message at all — the weaker of the two
refusal styles per section 3(iii) — so an `NA_real_` **with a message**
needs a call site that can carry one; today's silent-frame branch cannot.

**This fix is scale-independent.** Section 3 established both loci are
Gaussian-only, where latent/expected/observed coincide; the fix changes only
which number feeds an already-correctly-scaled formula, never which scale it
reports. **The S2 fix — returning `E[sigma^2]^{1/2}` whenever a detected
random effect exists on `sigma`, or `NA` with a named reason otherwise — is
therefore orthogonal to, and does not have to wait on, the D-252
latent/liability/observed naming decision for non-Gaussian families, because
both current call sites never leave the Gaussian, identity-link case where
that three-way distinction does not arise.** This is the sentence for review
to rule on.

## 6. Twins and siblings

**DRM.jl** (`src/heritability.jl`, main, 366 lines). `_variance_component_indices()`
(lines 37-84) requires a single homoscedastic residual and structurally
forbids the trigger for S2: on the single-structured path, `length(rs) == 1`
or it errors — `"heritability/repeatability needs a homoscedastic residual
(sigma ~ 1); this fit has a σ predictor with $(length(rs)) coefficients"`
(lines 71-74). No path admits any predictor, random or fixed, on `sigma`
beyond one intercept, so DRM.jl never faces a median-vs-RMS choice — every
admitted residual is already a scalar `exp(theta)`. **DRM.jl lacks the S2 bug
because it refuses the fits that would trigger it, more strictly than
drmTMB's current guard** (which checks for one *fixed* `(Intercept)` but not
an *additional random effect*). Until section 5 lands, tightening drmTMB's
guard to match DRM.jl's stricter refusal is a smaller interim option.

**gllvmTMB #1276** (OPEN; confirmed via `gh issue view 1276 --repo
itchyshin/gllvmTMB`, title "Scale naming: what we call the latent scale is
the LIABILITY scale") is the same D-252 rename #1301 tracks here. D-252: "the
twins must land the same vocabulary in the same change" — section 7's
documentation change should reuse gllvmTMB's eventual
`latent`/`liability`/`observed` naming, and neither repo should ship its half
alone.

## 7. Documentation change needed (draft, not applied)

Add to `man/summary.drmTMB.Rd`'s "derived" paragraph, after the existing
total-vs-focal denominator sentence:

> Both `total_variance_share` and `phylo_total_variance_share` are computed
> only for Gaussian fits with an identity-link mean, where the latent,
> expected-data, and observed-data scales of de Villemereuil, Schielzeth,
> Nakagawa & Morrissey (2016, *Genetics* 204:1281-1294) coincide; there is no
> separate latent- or liability-scale value to distinguish.
> `drm_constant_residual_sigma()` requires a constant `sigma ~ 1` fit; see
> `docs/design/275-repeatability-scale-and-residual-variance.md` for what
> happens, and what is planned, when `sigma` instead carries a random effect.

A parallel sentence belongs in `?heritability`'s Details, next to the
existing "Fits must be Gaussian, have a constant residual scale..." paragraph
(`R/heritability.R:27-31`).

## 8. Not covered

- No non-Gaussian latent/liability/observed formulas are implemented here;
  section 3(iii) records what they need, not a build plan.
- Section 5's fix is proposed, not implemented; `R/methods.R`, `R/heritability.R`,
  and tests are out of scope (owned by other agents in this worktree).
- Section 6's interim guard-tightening option is not costed against section 5.
- gllvmTMB's repeatability code was not read; only its issue title and D-252.
- Russell's exact simulated `total_re_var`/DGP (outside this repository) is
  not reconstructed; section 4 marks that gap explicitly.

## 9. References

- de Villemereuil, P., Schielzeth, H., Nakagawa, S., & Morrissey, M. (2016).
  General methods for evolutionary quantitative genetic inference from
  generalized mixed models. *Genetics*, 204(3), 1281-1294.
- Nakagawa, S., & Schielzeth, H. (2010). Repeatability for Gaussian and
  non-Gaussian data. *Biological Reviews*, 85(4), 935-956 (source of the
  `ln(1+1/lambda)` approximation; unnecessary here, see section 3(iii)).
- Dinnager, R. (2026). Independent evaluation of drmTMB 0.7.0 at `945da24f`.
  https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md, §4, Appendix
  A row S2.
