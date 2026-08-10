# MSPL Phase 3: binomial-logit symbolic alignment

## Status and decision

This document freezes the Phase 3 contract for maximum softly-penalized
likelihood (MSPL) in one native `drmTMB` route.  It is a design specification,
not evidence that the route is already implemented or inference-ready.

The only proposed public call is

```r
drmTMB(
  bf(cbind(successes, failures) ~ x + (1 | group)),
  family = binomial(link = "logit"), data = dat,
  estimator = "mspl"
)
```

`estimator = c("ml", "mspl")` is a scalar choice, defaulting to `"ml"`.
It is not a general tuning interface, a prior API, a new family, a link switch,
or an alias for `REML` or the existing phylogenetic `penalty` argument.  An
MSPL fit may record `fit$estimator = "MSPL"` internally; an ordinary fit
remains `"ML"` and an existing restricted fit remains `"REML"`.

The source method is Sterzinger and Kosmidis (2023), *Maximum softly-penalized
likelihood for mixed effects logistic regression*, **Statistics and
Computing** 33:53, [https://doi.org/10.1007/s11222-023-10217-3](https://doi.org/10.1007/s11222-023-10217-3).
In particular, its fixed-effect Jeffreys term is equation (4), its negative
Huber variance term is equation (5), and its common soft scaling is
`2 * sqrt(p / n)` (Section 7).  Phase 3 adopts those ingredients only in the
explicitly bounded setting below.

## Frozen eligible surface

An MSPL request is eligible exactly when all of the following hold.

1. `engine = "tmb"`, `REML = FALSE`, `penalty = NULL`, and
   `family = stats::binomial(link = "logit")`.
2. There is one `mu` formula and no other distributional formula; its fixed
   design `X` is finite and full column rank.
3. The response is complete and is either Bernoulli `0/1` or
   `cbind(successes, failures)` with positive integer trials.  Grouped counts
   are a derived representation of independent Bernoulli trials, not a second
   likelihood family.
4. A finite fixed `offset()` is allowed.  Likelihood `weights` must be finite
   non-negative integer **frequency** weights; after zero-frequency rows are
   omitted, every retained frequency is positive.  Pruning occurs before
   response, rank, random-block, and `n_eff` validation, so omitted rows
   contribute neither data nor information.  There is no `mi()` or non-default
   missing-data engine.  Complete-case row removal also occurs before `n_eff`
   is computed.
5. There is exactly one ordinary grouping factor in `mu`, with one of the
   Phase-3 blocks: q1 `(1 | group)` or q2 `(1 + x | group)`.  The q2 covariate
   is one finite numeric column and has a random-intercept partner.  The block
   has no label and no second random-effect term.

The following are explicit errors, rather than quiet fallbacks to ML:
`REML = TRUE`; a non-`NULL` phylogenetic penalty; `engine = "julia"`;
negative, fractional, non-finite, or otherwise non-frequency weights; `mi()`
or missing-response inclusion; q0 fixed-effect models; pure random slopes;
independent split q2 syntax `(1 | group) + (0 + x | group)`;
q3+; multiple grouping factors; labelled covariance blocks; structured,
phylogenetic, spatial, animal, relatedness, or `sd()` terms; bivariate models;
beta-binomial; zero-inflated or hurdle models; and every non-logit binomial
link.  At base `efb5af4f`, the binomial parser admits `offset()` in `mu`
(`R/drmTMB.R:6218`) and permits independent intercept/slope terms while
rejecting labelled correlation (`R/drmTMB.R:10154-10175`).  Phase 3 retains
the fixed-offset surface, narrows weights to integer frequencies, and changes
only the explicitly admitted covariance block; those base facts alone do not
prove the MSPL extension.

`zi`, `hu`, `zoi`, and `coi` are not MSPL endpoints.  In particular, this
document makes **no** claim that the fixed-effect Jeffreys argument, the
Huber variance argument, finiteness theorem, equivariance, Laplace behavior,
or any simulation conclusion transfers to `zi`/`hu` or to a zero-modified
family.  It also makes **no** claim for binomial `probit` or `cloglog` links.
The source paper explicitly leaves bounds for probit and complementary
log-log as future work; a generic statement that other links may be possible
is not a drmTMB implementation or validation claim.

## One-to-one alignment table

| Symbol and meaning | User/API term | TMB packing and objective term | DGP draw | Extracted estimate | Frozen truth |
| --- | --- | --- | --- | --- | --- |
| `y_ig` successes | `cbind(successes, failures)` or `y` | existing `y`; model type 18 | `rbinom(1, m_ig, pi_ig)` | `fit$model$y` | generated successes |
| `m_ig` trials | grouped response only | existing `trials` | fixed positive integers | `fit$model$trials` | generated trials |
| `f_i` frequency | positive integer `weights` | integer frequency multiplier | primary DGP uses `f_i = 1`; parity DGP duplicates whole rows | `fit$mspl$frequency` | retained frequency |
| `x_ig`, `X` fixed design | RHS fixed effects | existing `X_mu` | generated then fixed | `coef(fit, "mu")` | `beta` |
| `beta` fixed effects | `mu ~ ...` | `beta_mu` | fixed before response draws | `coef(fit, "mu")` | `beta` on the logit scale |
| `u_g` standard-normal latent effects | q1/q2 random block | `u_mu`, passed in TMB `random` | `z_g ~ N_q(0, I)` and `u_g = L z_g` | `random_effects$mu` is diagnostic only | realized `u_g` only for latent-recovery diagnostics |
| `L`, `Sigma = L L^T` | q1/q2 covariance block | `log_sd_mu` and new q2 correlation coordinate | stable map below | construct from DGP SDs and correlation | marginal SD(s) and correlation, not raw Cholesky entries |
| `o_i` fixed offset | `offset(o)` in `mu` | existing `offset_mu` | finite fixed value | `fit$model$offset$mu` | DGP offset |
| `eta_ig` | logit `mu` predictor | `offset_mu + X_mu beta_mu + Z u` | `o_i + x_ig^T beta + z_ig^T u_g` | `predict(fit, dpar = "mu", type = "link")` | DGP linear predictor |
| `pi_ig = expit(eta_ig)` | `family = binomial(link = "logit")` | stable logit leaf | `plogis(eta_ig)` | `predict(fit, dpar = "mu")` | DGP probability |
| `ell_L` Laplace marginal log likelihood | implicit TMB fit | TMB objective after `u_mu` is marginalized | not a draw | unpenalized value stored separately | ordinary ML/Laplace criterion |
| `P_f` fixed Jeffreys term | `estimator = "mspl"` | report and subtract from TMB NLL as below | deterministic from `X, o, f, m` | `fit$mspl$fixed_penalty` | formula below |
| `P_v` negative-Huber variance term | `estimator = "mspl"` | report and subtract from TMB NLL as below | deterministic from DGP covariance coordinates | `fit$mspl$variance_penalty` | formula below |
| `c_n` common softness scale | no user override | scalar data/diagnostic | deterministic from retained frequency-weighted trials and `p` | `fit$mspl$c_n` | `2 * sqrt(p / n_eff)` |

The live base already packs successes and trials for this route as TMB
`model_type = 18L` (`R/drmTMB.R:19606-19618`), maps `u_mu` into the Laplace
random block (`R/drmTMB.R:6370-6379`, `R/drmTMB.R:918-922`), and evaluates the
grouped logit-binomial leaf stably (`src/drmTMB.cpp:3291-3375`).  These are
the Phase-3 integration anchors, not copied implementation.

## Model, scaling, and objective

For retained row `i` in group `g(i)`, with q-dimensional random design
`z_i`, define

\[
y_i \mid u_{g(i)} \sim \operatorname{Binomial}(m_i,\pi_i),\qquad
\operatorname{logit}(\pi_i) = o_i+x_i^\top\beta + z_i^\top u_{g(i)},\qquad
u_g \sim N_q(0,\Sigma),\quad \Sigma=LL^\top.
\]

The primary source treats a Bernoulli response. For this derived grouped
representation, expanding row `i` into `m_i` Bernoulli observations sharing
`x_i`, `z_i`, `o_i`, and `u_g` gives the same parameter-dependent likelihood
kernel. The grouped form additionally contains the data-only constant
`log choose(m_i, y_i)`, so raw log-likelihood values differ by the sum of those
constants even though estimates, gradients, Hessians, and the MSPL penalty are
unchanged. An integer frequency `f_i` repeats the complete grouped likelihood
term `f_i` times. Accordingly, freeze

\[
n_{\mathrm{eff}}=\sum_{i\in\mathcal O}f_i m_i,\qquad
p=\operatorname{ncol}(X),\qquad
c_n=2\sqrt{p/n_{\mathrm{eff}}}.
\]

`n_eff` is neither the number of groups, the number of retained grouped rows,
nor a correlation-style heuristic.  It is the retained frequency-weighted
Bernoulli count.  The q1 unweighted Bernoulli case has `f_i = m_i = 1` and
reduces to the paper's `n`.  Grouping, finite fixed offsets, and integer
frequency replication are algebraic extensions of the logit likelihood; this
is not an asymptotic proof for arbitrary survey or fractional
pseudo-likelihoods.

At `beta = 0`, the grouped fixed-only information is

\[
W_0=\operatorname{diag}\{f_i m_i\pi_{0i}(1-\pi_{0i})\},\qquad
P_f(\beta)=\tfrac12\log\det\{X^\top W(\beta)X\},\qquad
W(\beta)=\operatorname{diag}\{f_i m_i\pi_i^{(f)}(1-\pi_i^{(f)})\},
\]

where `pi_i^(f) = expit(o_i + x_i^T beta)` has **no** random-effect
contribution, and `pi_0i = expit(o_i)`.  `P_f` is evaluated at the current
fixed effects; `W_0` is a stored initialization/diagnostic check, not a
substitute for `W(beta)`.
The implementation must fail before optimization if `X^T W_0 X` is not
positive definite (including a non-finite log determinant).

Let

\[
D(t)=\begin{cases}-t^2/2,&|t|\le1,\\-|t|+1/2,&|t|>1.\end{cases}
\]

be the **negative** Huber loss.  Thus `D(0)=0` and `D(t) <= 0`; the objective
must never silently reverse this sign or add the positive Huber loss.  With
the Cholesky coordinates specified next, `P_v` is the sum of `D()` over log
diagonal Cholesky entries and strict-lower entries.  The maximized criterion is

\[
\ell_{\mathrm{MSPL}}=\ell_L(\beta,\psi)+c_n\{P_f(\beta)+P_v(\psi)\}.
\]

Because TMB minimizes a negative log likelihood, the implementation target is
`nll_mspl = nll_laplace - c_n * (P_f + P_v)`.  The penalties depend only on
fixed TMB parameters and fixed data, not on `u_mu`; adding them inside the
template before TMB's Laplace fold is therefore algebraically the same as
adding them to the Laplace-marginal criterion.  They must not be applied to
the conditional mode, counted twice after `MakeADFun()`, or inserted by making
`beta_mu` a random variable.  Existing `MakeADFun(..., random =
spec$tmb_random_names)` is the relevant placement (`R/drmTMB.R:510-517`).

## Stable q1/q2 covariance and Huber coordinates

For q1, with `a1 = log(sd1)`, set `L = [exp(a1)]` and

\[
P_v=D(a_1).
\]

For q2, store marginal log SDs `a1`, `a2` and an unconstrained correlation
coordinate `z`.  Define `rho = tanh(z)` and `s = sech(z) > 0`, evaluated
without cancellation (for example `log_sech(z) = log(2) - |z| -
log1p(exp(-2*|z|))`).  The lower Cholesky factor is

\[
L=
\begin{pmatrix}
e^{a_1}&0\\
e^{a_2}\tanh(z)&e^{a_2}\operatorname{sech}(z)
\end{pmatrix}.
\]

Hence `Sigma[1,2] = rho * exp(a1 + a2)`: a positive raw `z` means a positive
intercept--slope covariance.  `sech(z)`, not `sqrt(1 - tanh(z)^2)`, is the
frozen numerical map.  The raw `z` is **not** a paper Huber coordinate.  To
match the paper's Cholesky penalty exactly, use

\[
P_v=D(a_1)+D\{a_2+\log\operatorname{sech}(z)\}
    +D\{e^{a_2}\tanh(z)\}.
\]

The three arguments are respectively `log(L11)`, `log(L22)`, and `L21`, with
the stated signs.  Penalizing `a2`, `z`, `rho`, or `atanh(rho)` instead is a
different estimator and is prohibited by this Phase-3 contract.  The existing
ML code's guarded transform `0.999999 * tanh(eta_cor_mu)` in other correlated
routes is not a substitute: the binomial base route does not yet expose q2
correlation, and the MSPL q2 implementation must use the map above.

## DGP and extraction contract

Every Phase-3 recovery fixture must generate the same objects it fits:

1. Choose full-rank `X`, one group factor, finite fixed `o_i`, positive integer
   `m_i`, fixed `beta`, and q1 or q2 marginal SD/correlation in the interior.
2. Build `L` with the q1/q2 map above; draw independent `z_g ~ N(0,I_q)` and
   set `u_g = L z_g`.
3. Form `eta_i = o_i + x_i^T beta + z_i^T u_{g(i)}` and draw
   `y_i ~ Binomial(m_i, plogis(eta_i))`.
4. Fit the matching `bf(cbind(y, m-y) ~ offset(o) + ...)` with
   `estimator = "mspl"`.  Primary recovery data use frequency one.
   Frequency-weight validation uses a clean literal row-duplication oracle,
   rather than treating repeated likelihood terms as a new response-generation
   mechanism.
5. Compare `coef(fit, "mu")` to `beta`, `fit$sdpars$mu` to marginal SD truth,
   and `fit$corpars$mu` to the q2 correlation truth.  The realized `u_g` may
   be compared only as an explicitly labelled latent-effect diagnostic, never
   as the variance-component truth.

`predict(..., type = "link")` must equal the fitted `offset + X beta + Z u`
expansion;
`predict(..., dpar = "mu")` must equal its logistic transform.  This mirrors
the current random-intercept test's identity at
`tests/testthat/test-arc2a-mu-random-intercept.R:23-26`.  The current binomial
simulator also uses the stored trials (`R/methods.R:3147-3161`), and the base
response parser makes `cbind(successes, failures)` explicit
(`R/drmTMB.R:16337-16430`).

## Required stored diagnostics

An MSPL fit must store a plainly named `fit$mspl` list and TMB reports with at
least: `active`; route/family/link; q; `p`; `n_row`; retained `frequency`;
`n_eff`; `c_n`; the
unpenalized Laplace NLL/log likelihood; `P_f`; `P_v`; their scaled sum; the
penalized NLL/objective; `logdet_XtW0X`; final `logdet_XtWX`; q1/q2 Cholesky
coordinates; q2 `rho`, `sech`, `log_sech`, `L11`, `L21`, and `L22`; all
eligibility flags; and a boolean that the fixed-information determinant was
finite and positive.  These values are diagnostics, not evidence of nominal
interval coverage or a universal non-boundary theorem.

The fit must store the independently evaluated unpenalized Laplace data log
likelihood in `fit$mspl`; the MSPL criterion is also retrieved from
`fit$mspl`, never disguised as ML likelihood.  The public `logLik()` method,
AIC, BIC, profile likelihood, `confint()`, Wald standard errors,
and `anova()` have no MSPL validity claim in Phase 3 and must either error with
an MSPL-specific message or be explicitly marked unsupported.  `sdreport()`
may be retained as an optimizer diagnostic but is not an MSPL uncertainty
endorsement.

> **Superseded in part — see "Phase 4 amendment" below.**  The Wald
> standard-error clause in the preceding paragraph is lifted for `vcov()` and
> `summary()` **only**.  Every other fence it names — `logLik()`, AIC, BIC,
> profile likelihood, `confint()`, and `anova()` — is re-asserted verbatim and
> remains in force.  The Phase 3 text is retained above as written rather than
> edited, so the original contract stays legible.

## Validation gate

The local experimental point-fit claim requires all of the following. These
gates do not authorize recovery, calibration, or release wording.

1. Pure deterministic tests of `D()`, its sign, q1/q2 `L L^T`, positive
   diagonal, rho sign, `sech` stability at large `|z|`, and the exact Huber
   coordinates above.
2. Grouped-and-frequency-versus-expanded Bernoulli equality for estimates,
   the parameter-dependent unpenalized likelihood after subtracting the known
   grouped combinatorial constant, `P_f`, `n_eff`, and `c_n`, including finite
   fixed offsets. Invalid counts, rank deficiency, non-integer/non-positive
   retained frequencies, and a representative cross-product matrix spanning
   missing engines, links, endpoint formulas, split/labelled/q>=3 blocks,
   multiple groups, and structured effects must fail loudly; zero-frequency
   rows must be shown absent before each validation.
3. A clean-room R reference, independent of the package penalty helper and TMB
   template expression, must verify q1/q2 fixed-vector penalty values and
   numerical gradients against the difference between penalized and
   unpenalized TMB objectives.
4. Independent Gauss-Hermite quadrature must stabilize and re-optimize the full
   q1/q2 exact-marginal MSPL analog, using directly coded Jeffreys and Huber
   equations. This is an approximation comparator: it must report, not hide,
   differences from the Laplace solution. A legally compatible external MSPL
   implementation may be added later but is not required for this clean-room
   local milestone.
5. Local deterministic q1 and q2 separation, mirrored-tail, quasi-separation,
   and near-boundary fixtures, retaining failures and reporting ML alongside
   MSPL. They require optimizer, Hessian/gradient, objective, and stored MSPL
   diagnostics. These are implementation tests, not population recovery or
   calibration evidence.

Passing these local gates earns only an *experimental, locally verified
binomial-logit MSPL point-estimation route*. A separate authorized Totoro or
DRAC campaign is required before any recovery, bias, RMSE, interval, coverage,
or calibrated-boundary claim. REML, `hu`/`zi`, probit/cloglog, structured or
multiple grouping effects, and a general GLMM separation detector remain out
of scope.

## Clean-room provenance boundary

The statistical method and equations are attributed to Sterzinger and
Kosmidis (2023).  drmTMB may implement an independently written translation of
the published equations after the validation contract is met.  Do not copy
their supplementary scripts, source implementation, function names, tests, or
comments into this package. Record the DOI, equation/section pointers, base
commit `efb5af4fea0204a8d0ce381685b259029d040637`, and independent local-oracle
provenance in the after-task receipt. A future landing PR must repeat this
provenance, but no PR is part of Phase 3.

At that base, the native binomial route is a logit grouped-binomial likelihood
with a latent-normal q1/independent-term implementation (`src/drmTMB.cpp:3291-3375`),
and its fixed-only runtime link is `logit` (`R/methods.R:5597-5614`).  Those
facts establish the landing interface only; they do not import MSPL code or
prove the new estimator.

## Phase 4 amendment — Wald standard errors

Owner decision, 2026-08-09: **MSPL ships standard errors in drmTMB 0.7.0,
claim-bounded.**  This section amends the Phase 3 clause above.  It is a
deliberate contract change, recorded as an amendment rather than applied as a
silent unlock, because the Phase 3 text explicitly required Wald standard
errors to error or be marked unsupported.

The estimand, the SPD gate, the failure behaviour, and the obligated tests are
specified in `251-mspl-wald-covariance-alignment.md`.  This section states only
what changes in the contract.

**Lifted.**  `vcov()` and `summary()$coefficients$std_error` may return values
for an MSPL fit.  The reported covariance is the inverse observed information
of the **unpenalized** Laplace log likelihood evaluated at the MSPL estimate.
The penalized Hessian remains an optimizer diagnostic and must never be the
reported covariance: it adds the penalty's curvature to the likelihood's, which
shrinks standard errors most in exactly the separated directions where the
penalty is carrying the fit.

**Re-asserted verbatim, still in force.**  `logLik()`, AIC, BIC, profile
likelihood, `confint()`, and `anova()` retain no MSPL validity claim and must
continue to error with an MSPL-specific message.  The stored unpenalized
objective must still never be exposed through `logLik()`.

**A standard error is a reported quantity; an interval is a coverage claim.**
The two are separated in code, not only in prose, which is why `vcov()` is
lifted while `confint()` is not.  Kosmidis and Firth establish that Wald
intervals in this setting fail to cover regardless of the nominal level, a
failure that persists even for profile penalized-likelihood intervals, and that
the mechanism is finiteness of the penalized estimator and its standard error
rather than separation as such.  A second, independent reason is recorded in
`251` section 3: the MSPL estimate maximises the penalized criterion, so the
unpenalized score is not zero at it and the textbook "evaluate at the maximum
likelihood estimate" justification does not transfer.

**Unchanged by this amendment.**  The admitted model surface of Phase 3, the
penalty form and its scaling, `sdreport()` remaining skipped, the validation
gate, the clean-room provenance boundary, and the requirement of a separately
authorized campaign before any recovery, bias, RMSE, interval, coverage, or
calibrated-boundary claim.  `probit`/`cloglog` also remain out of scope for
MSPL — see `252-binomial-link-generalisation.md` section 7 for why the
mixed-effects bounds do not exist.
