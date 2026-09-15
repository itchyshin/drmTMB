# Fisher review: Dinnage audit, second arc

Date: 2026-09-14 · Reviewer: Fisher (inference reviewer, review-only; no file
changed except this one) · Worktree:
`/Users/z3437171/local-scratch/lanes/drmTMB-audit-dinnage-wave1`, branch
`claude/audit-dinnage-wave1-20260913` at `46b9b19ec`.

## Purpose, for Shinichi

Three documents came out of today's arc, and none of them changes a number yet.
That is the right order. This review asks of each one the only question that
matters at the document stage: **if a contributor built the next slice from this
page alone, would they build the right thing?** For two of the three the answer
is yes with corrections. For the third — design note 275 — there is one sentence
that would send the next builder to fix half a bug and believe they had fixed all
of it, and that is the finding to read first.

Ordered by how hard each finding pushes on an inference claim:

1. **275 §5's call-site claim is false for one of its two call sites.**
   `drm_variance_ratio()` does not consume the value `drm_constant_residual_sigma()`
   returns — it uses it only as a finiteness gate and then recomputes the residual
   from `beta_sigma` directly. Fixing the helper alone leaves
   `heritability()`/`icc()`/`repeatability()` reporting exactly the same wrong
   ratio Russell measured, with the guard now passing. (Verified by reading both
   functions in full.)
2. **274 §4's mechanism does not explain the number §2 says it explains.** The
   algebra predicts a factor of 1 for the quantity issue #1315 actually defines,
   and a factor of 2 for a different quantity. As written the note claims a
   mechanism match it has not got.
3. **274 §7's time estimate drops a factor of three**, which is a D-139 honesty
   problem, not a rounding one.
4. Two arithmetic slips (275 §4's `9.53`, 274 §7's MCSE `0.014`) that each
   reverse or weaken the check they were offered as evidence for.
5. The S3 help page is correct on every point it was asked to be correct on; its
   two problems are a stale `.Rd` and one un-updated neighbouring sentence.

---

## Part A — code (M1, M2, S2b)

*Reviewer: Fisher, fresh context, read-only except this file. Worktree
`/Users/z3437171/local-scratch/lanes/drmTMB-audit-dinnage-wave1`. Nothing was
recompiled; the `.so` in the worktree is the post-M1 kernel, so every runtime
figure below is measured on the FIXED code unless stated. Line numbers for
`src/drmTMB.cpp` are the file as of `fc461aae4`; for `R/methods.R` as of
`0526baa2f` (unchanged at `HEAD`, checked with `git log 0526baa2f..HEAD -- R/methods.R`).*

### M1 (fc461aae4)

VERDICT: ACCEPT-WITH-CHANGES — all eleven blocks carry the weight in the right
place and the new objective-identity assertion is the right invariant and
genuinely red, but one test arm is credited with catching a bug it demonstrably
did not catch, and the two "recorded neighbours" are described less accurately
than the evidence in this worktree supports.

#### Mechanism

I read all eleven post-fix blocks against the Bernoulli template at
`src/drmTMB.cpp:1272-1313` (prior `:1289`, mixture `:1304`), one by one, not by
pattern-matching the first. For each of `mi_family` 2, 3, 4, 10, 12, 5, 8, 11, 6,
7, 9 the three required properties hold:

| `mi_family` | observed-row prior | per-node `log_y` | closing `nll` |
|---|---|---|---|
| 2 ordinal | `:1364` `weights(i) *` | `:1387` unweighted | `:1395` `weights(i) *` |
| 3 categorical | `:1460` | `:1471` | `:1479` |
| 4 beta | `:1545` | `:1560` | `:1567` |
| 10 zero-one-beta | `:1679` | `:1702` | `:1709` |
| 12 beta-binomial | `:1815` | `:1837` | `:1844` |
| 5 poisson | `:1892` | `:1903` | `:1910` |
| 8 nbinom2 | `:1974` | `:1989` | `:1996` |
| 11 trunc. nbinom2 | `:2081` | `:2097` | `:2104` |
| 6 lognormal | `:2172` | `:2182` | `:2198` |
| 7 gamma | `:2265` | `:2279` | `:2286` |
| 9 tweedie | `:2360` | `:2376` | `:2383` |

Evidence, not inference: I confirmed the eleven closing lines with a targeted
grep of the post-fix file and then read each block's body; there is no residual
`weights(i) * drm_response_log_density(` anywhere in `src/drmTMB.cpp`.

Three structural checks the brief asked for, all clean:

* **Third branch.** Nine of the eleven blocks have a third arm for
  `observed_y(i) == 0` *and* `mi_observed(i) == 0` (`:1580, :1722, :1857, :1923,
  :2009, :2117, :2212, :2299, :2396`). None of them touches `nll` at all — they
  only build a prior-mean plug-in for `mi_x_full` / `mu`. That is consistent
  with the template, where the same case collapses to
  `weights(i) * logspace_add(log_p1, log_p0) = w * log 1 = 0`. Weighting is
  vacuous there, so nothing is missing. `mi_family` 2 and 3 have no third arm
  because their `else` branch already covers it with `log_y = 0` and a
  normalised state prior, giving `log_denom = 0`.
* **Lognormal (`mi_family == 6`).** The comment at `:2183-2191` claims the
  Gauss-Hermite nodes already carry the prior, so no `+ log_density` belongs in
  the sum. This is **true and I checked the generator, not just the comment**:
  `drm_lognormal_mi_quadrature()` (`R/missing-data.R:3307-3321`) returns
  `nodes = sqrt(2) * hermite_nodes` and `weights = hermite_weights / sqrt(pi)`,
  i.e. probabilists' abscissae with weights summing to 1, and `:2178` forms
  `x_q = exp(mi_eta(i) + sigma * z_q)`. So `log(w_q) + log f(y | x_q)` is the
  correct `log E_x[f(y|x)]`. The block's own third arm (`:2213-2221`) uses
  `prior_norm = sum(mi_quad_weights)` with no density factor, which is the same
  statement made a second way.
* **No double counting.** The main Gaussian response loop skips exactly the
  mixture rows: `src/drmTMB.cpp:2455-2462`,
  `observed_y(i) == 1 && !(has_mi == 1 && mi_family != 0 && mi_observed(i) == 0)`,
  and weights that loop by `weights(i)`. So a weighted row contributes `w` once.

**What the template does not cover, and whether a weighted fit now gets it
wrong.** The per-block by-products — `posterior = exp(log_terms(q) - log_denom)`,
`conditional_mean`, `expected_mu`, `mi_state_probability`, and the `REPORT`ed
`mi_x_full` — are now formed from *unweighted* leaves, so the weight no longer
tempers the imputation posterior. That is correct and is the same by-product the
wave-1 review credited to the Bernoulli fix. I found nothing in the eleven blocks
that a weighted fit now gets wrong. Two adjacent things are wrong for other
reasons and are covered under "Contract" below.

#### Negative control

`tests/testthat/test-dinnage-audit-m1-families.R` is a real negative control and
a better one than wave 1's. The load-bearing assertion is
`fit_w2$obj$fn(p) == 2 * fit_w1$obj$fn(p)` at `1e-10`, evaluated at two parameter
points (`:38-44`).

*Is it the right invariant?* Yes, and it is strictly stronger than the coefficient
comparison it accompanies. For a fixed-effect model the weighted log-likelihood
is `sum_i w_i * l_i(theta)` identically in `theta`, so with `w == 2` the identity
holds at *every* parameter value, not only at an optimum; any weight that
multiplies part of a row (a leaf inside a mixture, an unweighted prior) breaks it
by a parameter-dependent margin rather than by optimiser noise. Two caveats worth
recording rather than fixing: (i) the identity is only true because these eleven
fixtures have **no random effects** — RE density terms are correctly unweighted,
so the same assertion would fail by construction on an RE model, and the helper
must never be reused there without that caveat; (ii) `run_mi_weight_invariance()`
now asserts `opt$convergence == 0L` on all three fits (`:20, :23, :26`), which
closes the wave-1 review's objection that invariance was being asserted at a
possibly non-optimal point.

The red proof `<scratchpad>/m1-red-final.txt` shows 43 failures with the correct
signature — `2*obj_w1` vs `obj_w2` off by tens of nats per family (ordinal 159.2
vs 105.6; beta-binomial 18.3 vs -157.0) and the `mi()` coefficients moving in the
5th-6th decimal against a `1e-6` tolerance. These would not pass on old code for
the wrong reason: the quantity compared is the objective itself, not a fitted
summary. `<scratchpad>/m1-green.txt` shows 77 = 11 x 7 passing assertions and
`<scratchpad>/m1-regress.txt` shows the whole missing-predictor suite green, so
`weights = 1` (the default) is unchanged, as it must be since `w * x` at `w = 1`
is exact.

**Does Tweedie's loosened duplication arm hide anything? It hides that it is not
a test.** Read the red-run progress line in `m1-red-final.txt`:
`...tuv.` for the Tweedie block — three dots (the convergence checks), three
failures (the two identity checks and `coef_w1 == coef_w2`), then a **dot**. The
fourth assertion, `coef_dup == coef_w2` at `dup_tolerance = 1e-2`, **passed on the
broken kernel**. Every other family shows `...ABCD` (four failures). So the test
comment at `:302-304`, "the duplication arm only guards the gross pre-fix bias",
is false as written: on the measured evidence it guarded nothing. The two identity
checks are the entire Tweedie negative control, and they are sufficient — but the
comment must say so.

I re-verified the two numbers that justify the loosening rather than taking them
on trust, by re-running `<scratchpad>/tweedie-probe2.R` against the current `.so`
(no recompile):

```
[with NA]  2*obj_w1: -63.7888192911  obj_w2: -63.7888192911  obj_dup: -65.1243435553
[20 NA] diff: -1.33552
```

So on the fixed kernel the M1 identity holds for Tweedie to twelve digits, and
the duplication gap is 1.336 nats over 20 missing rows — the figure NEWS and the
test comment quote. And the stated mechanism is exact, not approximate:

```
var(n rows) : 0.6587214291   var(2n rows): 0.6533659703
n_obs 62 -> 2(n-1)/(2n-1) = 0.9918699 ; observed ratio = 0.9918699
```

`stats::var()`'s `n - 1` divisor is the whole of it (`R/missing-data.R:3570`),
feeding `sigma` into `drm_tweedie_mi_quadrature()`'s
`upper = max(observed, mu + 8*sqrt(variance), 1)` (`R/missing-data.R:3665-3670`)
and hence every node and weight at `:3683-3684`. **The finding is real.**

#### Contract

For a user: any fit combining non-`NULL` `weights` with a non-Bernoulli
`impute_model()` changes — `logLik`, AIC, every estimate — in the direction of
correctness, and `weights = c` now means row duplication. `weights = 1` /
`weights = NULL` is bit-identical. Nothing else moves.

The NEWS wave-3 M1 bullet (working-tree `NEWS.md`, uncommitted) is accurate on the
fix itself and creditably names its two neighbours. Three corrections:

1. **The `mi_family == 0` description is narrower than the defect.** NEWS says the
   Gaussian latent route breaks invariance "through an unweighted covariate-model
   density inside a Laplace-integrated latent". The loop at `src/drmTMB.cpp:1215-1217`
   runs over **every** row, observed or missing, and carries no `weights(i)`. For
   the observed rows there is no latent and no Laplace: the fix there *is* one
   line, exactly as in the Bernoulli template at `:1289`. Only the missing rows
   raise the Laplace question. Saying "not a one-line change" of the whole route
   reads as "no cheap partial fix exists", which the source contradicts.
2. **A third site is unrecorded.** `has_mi2` (`src/drmTMB.cpp:1245-1270`, prior at
   `:1257`) — the second imputed covariate, Gaussian-only — has the identical
   unweighted prior and is mentioned in neither the commit message nor NEWS. So
   does the second `mi_family == 0` block at `:4417-4442` (prior `:4429`).
3. **The Tweedie item is filed as a tolerance nuisance; it is a likelihood
   -validity finding.** The support is sized **once, from start values**
   (`R/missing-data.R:3568-3583`: `beta` from `lm.fit`, `phi` from a moment
   estimate, then `quad_nodes` frozen into the TMB data). If the optimiser walks
   `sigma_tweedie_mi` well above its start value, the fixed upper limit truncates
   `int p(x) f(y|x) dx` silently, with no renormalisation of `p` over the
   retained support and no diagnostic. That is a bias in the objective, not a
   rounding difference, and it is invisible to every test in the suite.

#### Concrete change

1. **REQUIRED.** Fix the Tweedie test comment,
   `tests/testthat/test-dinnage-audit-m1-families.R:294-305`. Replace "the
   duplication arm only guards the gross pre-fix bias" with the measured truth:
   at `1e-2` that arm **passes on the pre-fix kernel** (`m1-red-final.txt`,
   progress line `...tuv.`), so the two objective-identity checks are the entire
   negative control for this family. A comment that credits an arm with a catch
   it did not make is the kind of thing that survives into a claim.
2. **REQUIRED.** Correct the NEWS `mi_family == 0` sentence to separate the two
   cases: the covariate-model density is unweighted **for observed rows as well**,
   where the repair is the same one-line change as the template; only the missing
   rows, whose `x_miss` is a Laplace-integrated latent, are genuinely hard. Add
   `has_mi2` (`src/drmTMB.cpp:1257`) and the second `mi_family == 0` block
   (`:4429`) to the recorded list.
3. **REQUIRED.** Re-file the Tweedie quadrature item as a likelihood finding, not
   only a duplication-tolerance one, naming the start-value-frozen support
   (`R/missing-data.R:3578-3583`, `3656-3689`) and the silent truncation risk.
   A `cli_warn()` when the fitted `sigma_tweedie_mi` exceeds the value the support
   was sized from would make it detectable; that is a separate slice, but the
   *record* should say what is at risk.
4. **OPTIONAL.** Add one row-varying-weight arm (e.g. `w = rep(c(1, 2), length.out = n)`
   compared against the correspondingly expanded data frame) to at least one
   family. A constant weight cannot detect a row-misaligned `weights(i)` index;
   the eleven loops run over `mi_x.size()` while `weights` is indexed by response
   row, and that alignment is currently only implied by `src/drmTMB.cpp:1218`.
5. **OPTIONAL.** Record, in the same place as the other neighbours, that
   `sigma_i` is computed and never used inside every one of the eleven quadrature
   loops (e.g. `:1559`, `:2181`) — dead since `drm_response_log_density()` takes
   `log_sigma` and `V_known` separately. Cosmetic, but it is eleven copies.

---

### M2 (0526baa2f)

VERDICT: ACCEPT-WITH-CHANGES — the helper is correct and placed correctly at the
two paths it touches, and the headline defect (a 297-nat gap between `logLik()`
and a hand-recomputed likelihood under `sigma(fit)`) is genuinely repaired; but
the "third path cannot fire" rationale is true of the *gate* and false of the
*defect*, and the commit introduces a new inference inconsistency in
`predict_parameters()` where the point estimate now falls outside its own
confidence interval.

#### Mechanism

`drm_clamped_sigma_eta()` (`R/methods.R:6045-6054`) gates on
`dpar %in% c("sigma", "sigma1", "sigma2")` and
`object$model$model_type %in% drm_clamped_scale_families()`, then applies
`drm_softclamp_log_sd(eta, object$model$tmb_data)`. I checked that this R helper
is the same map the kernel applies, not a lookalike: `R/drmTMB.R:23038-23060`
implements `hi + margin*tanh((x-hi)/margin)` above and
`lo - margin*tanh((lo-x)/margin)` below, reading `use_logsigma_clamp` and the
three-element `logsigma_clamp` band from `tmb_data`; `src/drmTMB.cpp:27-32`
(`drm_softclamp_log_sigma_one`) is the same two expressions with the same band.
Evidence, not inference.

**Both call sites verified.**

* `predict.drmTMB()`, `R/methods.R:2942`. Placement is right: it sits after every
  random-effect contribution (`:2888-2940`) and before `type == "link"` returns or
  `drm_inverse_link()` fires, which mirrors the kernel, where
  `drm_softclamp_log_sigma(log_sigma, ...)` is applied to the assembled predictor
  immediately before `sigma = exp(log_sigma)` (`src/drmTMB.cpp:2436-2440`).
* `drm_marginal_predict()`, `R/methods.R:6737`, likewise after the fresh RE draw
  and before the link.

**The delegation claims hold.** `sigma.drmTMB()` (`R/methods.R:4100-4115`) returns
`predict(object, dpar = "sigma")` for all thirteen univariate families and
`predict(dpar = "sigma1"/"sigma2")` for the three bivariate ones;
`observation_sigma()` (`:5760-5765`) and `observation_covariance()` (`:5767`) call
`predict(dpar = "sigma")`; `drm_fitted_response()` uses `predict.drmTMB(dpar = "sigma")`
for the truncated/hurdle NB2 means (`:6010-6019`). Outside `R/methods.R` every
consumer I could find goes through `predict()` too (`R/associate-pairs.R:141-194,
1269`); nothing reads a raw `report$sigma`.

#### Explicit question: does M2 cover `simulate()`'s marginal path?

**Yes.** `simulate.drmTMB()` (`R/methods.R:3029`) branches on `marginal <- is.null(re.form)`
(`:3037`). The marginal branch calls `drm_marginal_predict(object, "sigma", re_draws)`
— e.g. `R/methods.R:3075, 3141, 3163, 3400, 3424, 3452, 3490, 3524, 3533` and the
bivariate `sigma1`/`sigma2` at `:3568-3569, 3618-3619` — and that function clamps at
`R/methods.R:6737`. The conditional branch (`re.form = NA`) calls
`predict(object, dpar = "sigma")` (e.g. `:3081`) and is clamped at `R/methods.R:2942`.
Both paths are covered.

#### Negative control

`<scratchpad>/m2-red.txt` is a genuine red proof for four of the five test blocks:
`ll_hand` -572.3 vs `logLik` -275.1, `max(sigma())` 98.2 vs 3.7, band violations
on both arms, Pearson SD out of range, `simulate()` draw SD out of range.

**The fifth block is vacuous, and the red proof says so.** The progress line is
`1234567...` — seven failures, then **three dots**: every assertion in
`test-dinnage-audit-m2.R:108-129` ("the clamp fix is a no-op when the clamp band
is not binding") passed on the broken code. It has to: `sigma.drmTMB()` delegates
to `predict(dpar = "sigma")` (`R/methods.R:4100-4115`), so
`expect_equal(sigma(fit), exp(predict(fit, dpar = "sigma", type = "link")))`
compares a value with itself through the same code path, clamped or not. The only
non-tautological line in that block is `expect_equal(..$use_logsigma_clamp, 1L)`.
The test's *name* is a claim about behaviour it does not test.

Coverage is `gaussian`-only. `drm_clamped_scale_families()` names fourteen model
types (`R/drmTMB.R:3521-3540`), including three bivariate ones whose `sigma1`/`sigma2`
dpars the helper is written for; none is exercised. I cannot close that gap
without fitting, so: **UNVERIFIED** for the other thirteen.

#### Contract — and the two places it is now wrong

**(a) `predict_random_scale_dpar()` is not dead, and the "cannot fire" reasoning
is the wrong test.** The commit message says this third path "only ever sees
`sd(...)` dpars and cannot fire". The first half is true — `is_random_scale_dpar()`
(`R/methods.R:6274-6287`) admits only `random_scale$mu$dpars` /
`random_scale$phylo$dpars`, which are named `sd(id)`, `sd1(id)`, `sd2(id)`,
`sd_phylo(species)` (`R/drmTMB.R:4625` `startsWith(dpars, "sd(")`;
`R/julia-bridge.R:2217` `^sd(_phylo)?\([^()]+\)$`), never `sigma`. So
`drm_clamped_sigma_eta()` indeed never fires there. But the conclusion drawn from
that — that the path needs nothing — is false. The kernel **does** clamp the
direct-SD predictor: `src/drmTMB.cpp:2482-2485`,
`sd_mu_group(g) = drm_exp_sd_logscale_guarded(drm_softclamp_log_sd(eta_sd, use_logsigma_clamp, logsigma_clamp), ...)`,
and the R-side fit summary agrees (`sd_mu_group_values()`, `R/drmTMB.R:3062-3067`,
applies the same clamp). `predict_random_scale_dpar()` recomputes
`exp(X %*% coef)` with no clamp at all (`R/methods.R:6322-6326`).

Measured in this worktree on the current `.so` (no recompile), using the package's
own `new_gaussian_re_scale_data()` fixture with a deliberately narrow band:

```
bf(y ~ x + (1|id), sigma ~ z, sd(id) ~ w), logsigma_clamp = c(-0.2, 0.2), margin = 0.05
range predict(fit, dpar = "sd(id)") : 0.0308  3.5534
range fit$sdpars[["sd(id)"]]        : 0.7788  1.2840   (= exp(lo-margin), exp(hi+margin))
max |predict - sdpars|              : 2.269
```

That is the **same** M2 defect — a public accessor reporting a scale the
likelihood did not use — at a factor of ~25, on a documented call exercised by
`tests/testthat/test-gaussian-random-effect-scale.R:10` and
`tests/testthat/test-control.R:301`. M2 fixed two of three paths and retired the
third on a premise that is true but not the relevant one.

**(b) `predict_parameters()` now returns an estimate outside its own interval.**
`R/predict-parameters.R:129` takes the point estimate from
`predict(object, newdata = , dpar = , type = )` — now clamped — while the Wald
interval is built at `:288-292` from `basis$eta`, the **raw** linear predictor,
and the response-scale delta method at `:299-303` differentiates the inverse link
at the same raw `eta`. Before this commit both were the raw predictor and were
consistent. Measured, same fixture as the M2 test file, `conf.int = TRUE`:

```
row  estimate    std.error   conf.low    conf.high   conf.status
1   -1.29999999  0.30508393  -4.2976333  -3.10172628  wald
5    1.29999999  0.29822746   3.0440672   4.21309735  wald
```

Rows 1 and 5 have a point estimate that lies entirely outside its own 95%
interval. An interval that does not contain its own estimate is not a reporting
blemish; it is a broken inference object, and it is new as of this commit.

**(c) Two smaller consequences worth stating rather than fixing here.**
`predict(newdata = , dpar = "sigma")` is now saturated for extrapolation — at
`x = -2.5` in the fixture above the raw predictor is `-3.700` and `predict()`
returns `-1.300`, the band edge. That is defensible (it is what the model
evaluates) but it is not in the new help text, which speaks only about the fitted
rows. And `emm_basis.drmTMB()` (`R/emmeans-preflight.R:41`) hands `emmeans` a
`bhat` + `X` pair, so any `emmeans(fit, dpar = "sigma")` necessarily reports the
*unclamped* link and now disagrees with `predict(type = "link")`. That is
inherent to a linear-basis interface; it should be said once, not discovered.

**(d) A cross-finding with M1, recorded not fixed.** In `model_type == 1` the
soft clamp is applied at `src/drmTMB.cpp:2436-2439`, *after* the eleven `mi()`
quadrature blocks, so those blocks pass the **raw** `log_sigma(i)` into
`drm_response_log_density()` (`:1560`, `:2182`, ...). Every other model type I
checked clamps first: `model_type == 3` clamps at `:2614` before its `mi()` block
at `:2617`; likewise `:2869`/`:2874` (4), `:3020`/`:3023` (5), `:3150`/`:3156`
(10), `:3577`/`:3580` (14). So for a Gaussian fit where the clamp binds *and* a
covariate is imputed, the objective uses two different scales for different rows,
and M2's promise that the accessors report "the scale the likelihood used" is
false for the mixture rows. The clamp is on by default
(`test-dinnage-audit-m2.R:120` asserts `use_logsigma_clamp == 1L` on a plain fit),
so this is reachable, though it needs the clamp to actually bind.

The NEWS wave-3 M2 bullet is honest about the part it covers, and the "honest,
not correct" caveat is the right framing and is repeated in both help pages
(`man/sigma.drmTMB.Rd`, `man/predict.drmTMB.Rd`). It is **not** honest about
scope: it says the fix covers "every family in `drm_clamped_scale_families()`" —
true of the code, untested beyond `gaussian` — and it does not mention that
`predict(dpar = "sd(id)")` still reports an unclamped scale.

#### Concrete change

1. **REQUIRED.** Repair the `predict_parameters()` inconsistency before this is
   described as fixed anywhere user-facing. Either clamp `basis$eta` before
   `R/predict-parameters.R:288-292` and `:299-303` (accepting that the Wald
   interval around a saturated predictor is then degenerate and should be flagged,
   e.g. `conf.status = "clamped"`), or leave the interval alone and mark the row
   `interval_source = "not_available"` when the clamp bent that row's predictor.
   Silently returning an estimate outside its own CI is the worst of the three.
2. **REQUIRED.** Retract the "cannot fire" line and either fix
   `predict_random_scale_dpar()` (`R/methods.R:6322-6326`) by routing `eta`
   through `drm_softclamp_log_sd(eta, object$model$tmb_data)` before `exp()`, so
   it agrees with `sd_mu_group_values()` (`R/drmTMB.R:3062-3067`) and the kernel
   (`src/drmTMB.cpp:2482-2485`), or record it explicitly as an unfixed third path
   with the measured 25x figure. Do not leave the commit message's claim standing
   as written — it will be read as "all three paths are clean".
3. **REQUIRED.** Rename or repair `test-dinnage-audit-m2.R:108-129`. As written
   the block's only real assertion is `use_logsigma_clamp == 1L`; the other two
   compare `sigma()` with `exp(predict(type = "link"))`, which is the same code
   path. To test the stated no-op, compare against
   `exp(as.vector(model.matrix(~x, d) %*% coef(fit)$sigma))` (the raw predictor,
   computed independently, exactly as `m2_raw_sigma_eta()` already does at `:45-49`)
   and assert `is.null(drm_logsigma_clamp_active(fit$report, fit$model$tmb_data))`.
4. **OPTIONAL.** Add one bivariate case (`biv_gaussian`, `sigma1`/`sigma2`) and one
   non-Gaussian scale family (`nbinom2` or `beta`, where "sigma" is a dispersion)
   to the M2 file. The helper's family gate is currently exercised on exactly one
   of its fourteen entries.
5. **OPTIONAL.** Add one sentence to `?predict.drmTMB` saying the clamp also
   applies to `newdata` predictions, so an extrapolated `sigma` saturates at the
   band edge rather than following the fitted slope, and one to the same page
   noting that `emmeans` reports the unclamped link by construction.
6. **OPTIONAL, cross-lane.** Record finding (d) — `model_type == 1` clamping after
   its `mi()` blocks while every other model type clamps before — as its own
   issue. It is a one-line move of `src/drmTMB.cpp:2436-2439` above `:1175`, but
   it changes the objective for a reachable combination and therefore needs its
   own red proof, which needs a recompile.

---

### S2b (3192db3f6)

VERDICT: ACCEPT-WITH-CHANGES — the algebra is right, the estimand is genuinely
repaired (500-rep bias +0.0016 against a pre-fix estimand error of 0.169), and the
delta gradient is exact to 1.7e-11; but the refusal branch makes a measurably false
claim about `spatial(coords=)`, the phylogenetic case the man pages and NEWS now
promise produces **no number at either user-facing locus**, and two summary rows now
report two different residual scales under indistinguishable names.

*Reviewer: Fisher, fresh context, read-only except this file. Worktree
`/Users/z3437171/local-scratch/lanes/drmTMB-audit-dinnage-wave1`. Reviewed commit
`3192db3f6` only; the concurrent lane's uncommitted edits to
`R/predict-parameters.R`, `R/methods.R` (~6255-6330) and
`tests/testthat/test-dinnage-audit-m2.R` were ignored. Line numbers are
`git show 3192db3f6:<path>`. Nothing was recompiled. Every number below was
measured in this worktree unless marked UNVERIFIED.*

#### Mechanism

**The closed form is correct; I re-derived it rather than checking it off.** With
`log sigma_i = b0 + sum_k u_ik`, `u_ik ~ N(0, omega_k^2)` independent,
`2*sum_k u_ik ~ N(0, 4*sum_k omega_k^2)`, so
`E[sigma_i^2] = exp(2*b0) * E[exp(2*sum u)] = exp(2*b0) * exp(4*sum omega_k^2 / 2)
= exp(2*b0 + 2*sum_k omega_k^2)`, and `sqrt(E[sigma^2]) = exp(b0 + sum_k omega_k^2)`.
`R/methods.R:4725-4729` returns exactly that. The `omega_k` are read from
`object$sdpars$sigma`, which `split_tmb_sdpars()` fills with `exp(par$log_sd_sigma)`
(`R/drmTMB.R:22303-22309`) and then **appends** the `sigma`-endpoint phylogenetic SDs
to (`R/drmTMB.R:22386-22395`) — so both families of `omega_k` really are in the
vector, and their order does not matter to a sum of squares.

**The clamp is applied consistently within this path, and that is worth stating
because the neighbouring helper differs.** `sd_mu_group_values()` pushes its `eta`
through `drm_softclamp_log_sd()` and `drm_exp_sd_logscale_guarded()`
(`R/drmTMB.R:23062-23067`); the `sigma` branch of `split_tmb_sdpars()` does neither,
it is a bare `exp()`. The delta-method value function
`exp(2*t[[1]] + 2*sum(exp(2*t[-1])))` (`R/heritability.R:349`) is the bare `exp()` of
the same raw working parameters. **Estimate and gradient therefore agree; verified
numerically** — `drm_constant_residual_sigma(fit)` and the `resid_group$value` at
`theta_hat` agree to machine precision on fixture A, and
`drm_sigma_residual_extra_positions()` returned position 4, whose `theta` exponentiates
to `0.05417465` = `sdpars$sigma` exactly on the phylo fixture. *Caveat, not currently
recorded anywhere:* the likelihood evaluates `exp(softclamp(eta))`
(`src/drmTMB.cpp:781, 922`), so `exp(2*b0 + 2*sum omega^2)` is the moment of the
**unclamped** lognormal and is exact only while the clamp is inactive. On a
clamp-active fit it is an over-estimate of the residual variance the kernel actually
used. This is the same honest-but-not-correct situation NEWS already describes for
M2; it deserves one sentence rather than silence.

**Correlated mu-sigma blocks are handled, and are handled correctly for a reason the
commit does not state.** `bf(y ~ 1 + (1 | p | id), sigma ~ 1 + (1 | p | id))` is a
supported route (`tests/testthat/test-reml-ordinary-sigma.R:55-66`). Measured on a
fitted example: `has_sigma_random_effects()` is `TRUE`, `has_covariance_block_random_effects()`
is `FALSE`, `sdpars$sigma` holds the single `omega`, and corrected/reported = 1.000.
It is correct because the cross-`dpar` correlation `rho(u_mu, u_sigma)` **cancels**:
`Var(y) = E[Var(y|u)] + Var(E[y|u]) = E[sigma^2] + Var(u_mu)`, in which `rho` does
not appear, and the ratio's gradient with respect to `eta_cor_*` is exactly zero — so
omitting that position from `cov_sub` (`R/heritability.R:600`) is right, not an
oversight. **This deserves a fixture**; today it is load-bearing and untested.

**The refusal branch is where the mechanism breaks.** `drm_sigma_random_effect_omega2_sum()`
does **not** confirm `C_ii = 1`; it infers it from a type string,
`!identical(structured_mu_type(phylo_mu), "phylo")` (`R/methods.R:4771-4777`), and its own
comment concedes this ("only `phylo()`'s ultrametric default is verified here"). The
2026-09-14 ruling it cites said the opposite in terms: *"the refusal should be
conditioned on the **diagonal of the structured matrix**, not on the word
'phylogenetic'."* The consequence is measurable, not hypothetical. On
`bf(y ~ x + (1 | g), sigma ~ spatial(1 | site, coords = coords))` — a supported route
(`tests/testthat/test-wald-small-sample-default.R:163-170`,
`tests/testthat/test-profile-targets.R:1275`) — I inverted the fit's own precision
matrix (`fit$model$structured$phylo_mu$precision$precision`, 25x25) and found
**`diag(Sigma)` in `[1.000001, 1.000001]`**. The diagonal *is* unit; the closed form
applies verbatim; the package instead returns `NA` and tells the user *"whose
correlation matrix is not known to have a unit diagonal"*. That sentence is false for
this fit, and D-252 names this precise failure mode: *"Never return NaN for a quantity
that is defined — a refusal is a claim, and this one was false."* It is also a
capability regression: before `3192db3f6` this fit produced a `derived` row (wrong,
median-based); it now produces none, where it could produce the right one.

In the *other* direction the assumption currently holds, by construction rather than by
check: `phylo(term, tree)` exposes no `correlation` argument
(`R/formula-markers.R:196`), and `grep "correlation = FALSE" R/*.R` returns nothing, so
the `correlation = FALSE` branch of `drm_phylo_covariance()` is unreachable from the
formula grammar today and every `phylo()` matrix really is unit-diagonal. Refusing
`animal()`/`relmat()` is right on the merits (a pedigree `A` has diagonal `1 + F`, a
user-supplied `K` is arbitrary). A three-line diagonal check would get all four cases
right and would stop being a guess.

**Two routes I checked and found genuinely safe, so that a later change does not
reintroduce S2 quietly.** (1) `covariance_registry_member_sd_key()` maps a `sigma`-family
member of a `q > 2` covariance block into `sdpars$sigma` (`R/methods.R:1831-1839`), and
`has_sigma_random_effects()` (`R/methods.R:6352-6360`) cannot see that slot — but a
`q > 2` block needs three or more `dpar`s and both call sites are Gaussian-gated
(two `dpar`s), so it is unreachable. If a `nbinom2`/`zero_one_beta` route is ever
admitted to these accessors, S2 returns silently. (2) `sigma ~ spatial(1 | site,
mesh = mesh)` lives in the separate `mesh_spatial_mu` slot that
`has_sigma_random_effects()` also cannot see — but it is rejected at fit time
(`tests/testthat/test-mesh-contract.R:24-27`), so it is unreachable too.

**The delta method itself is correct and well-conditioned.** On fixture A I formed the
analytic gradient of `r = e^{2a}/(e^{2a} + e^{2b + 2e^{2c}})` by hand and contracted it
with `cov.fixed`: **package SE 0.08359478, analytic SE 0.08359478, relative difference
1.7e-11**. The step `h = 1e-5` (`R/heritability.R:583`) sits at the optimum of the
truncation/rounding trade-off for this function — sweeping
`h in {1e-3 … 1e-8}` gives max gradient error `1.4e-7, 1.4e-9, 1.7e-11, 3.3e-11,
5.2e-10, 3.6e-9`. The `exp(2t)` at `t = log(omega)` near zero is not a hazard: `t` is
merely order `-3` there and the derivative is bounded. `focal_index <- match(focal,
denom_idx)` (`R/heritability.R:356`) is right in both branches (`heritability`:
`match(focal, seq_along(sd_values)) == focal`; `icc`/`repeatability`:
`match(focal, focal) == 1`), and `cov_sub` is indexed by the same `opt$par` positions
the estimate used, with `drm_variance_ratio_check_cov_alignment()` asserting the
dimnames agree.

**But the interval is not nominal, and the commit message reads as though it is.**
500 replicates of fixture A's design (40 groups x 10, `sd_mu = 0.7`, `b0_sigma = -0.3`,
`omega = 0.6`, true marginal share `0.30294`), all 500 converged with `pdHess`:

| | random intercept on sigma | `sigma ~ 1` control |
|---|---|---|
| bias of the estimate | **+0.0016** (MC se 0.0037) | -0.0125 |
| mean delta SE / empirical SD | 0.942 | 0.941 |
| 95% Wald coverage | **0.910** (MC se 0.013) | 0.928 (MC se 0.011) |

Read this two ways, because it says two different things. **Estimation: the fix works.**
The corrected estimator is unbiased for the marginal share, where the pre-fix estimand
was `0.4717` against a truth of `0.3029` — coverage of *that* quantity by the corrected
interval is 0.436, which is the size of the defect Russell found. **Inference: the
interval was already ~2-4 points short of nominal before this commit and still is.**
The `sigma ~ 1` control is untouched code, so the shortfall is a pre-existing property
of a Wald interval on a bounded, skewed ratio, **not** something `3192db3f6` introduced
(0.928 vs 0.910 differ by 0.018 +/- 0.018 — I cannot separate them at this n). The
commit is therefore not to blame; but NEWS's *"the delta-method standard error of the
accessors carries the extra dependence on each `omega_k`"* is a *derivative* claim that
a reader will hear as a *calibration* claim. It is true and I verified it; say what it
does not buy.

#### Negative control

**Partly legitimate, and weaker than the commit message implies.**
`red_proof_setup.R:149-151` patches three functions —
`drm_constant_residual_sigma`, `drm_variance_ratio`, `drm_variance_ratio_delta` — and
**not** `drm_derived_summary_rows`, which also changed in this commit. Three separate
problems follow.

1. **Red failure 5 is an artefact, not a bug proof.** It is
   `Error ... unused arguments (denom_groups = ..., focal_index = ...)`
   (`<scratchpad>/s2-red.txt:37-38`) — the test calls the *new* helper signature
   directly, so under the old body it errors on arity. That arm demonstrates that a
   signature changed, which was never in doubt; it does not demonstrate the old
   estimate was wrong.
2. **The red run never reached the phylogenetic fixture.** testthat stopped at its
   ten-failure cap — *"Maximum number of 10 failures reached, some test results may be
   missing"* (`<scratchpad>/s2-red.txt` tail) — and fixture C begins around
   `test-dinnage-audit-s2.R:150`. **There is no red evidence for the phylo arm at all.**
3. The arms that *are* clean are genuinely clean and fail for the right reason: the
   marginal-vs-median gap (failures 1-4, e.g. `0.76` vs `1.01`) and the random-slope
   arm returning `nrow(derived) == 1` where 0 is required (failure 10).

**Green re-run, mine, this worktree:** `testthat::test_file("tests/testthat/test-dinnage-audit-s2.R")`
→ `[ FAIL 0 | WARN 1 | SKIP 0 | PASS 24 ]`. The one warning is the optimizer-preset
escalation on the phylo fixture, not an assertion.

**One fixture is built to be able to disable itself.** Fixture C's
`skip_if(elapsed > 60, ...)` is evaluated *after* the fit, so on a slower machine the
test reports SKIP and every assertion about the phylogenetic case silently vanishes.
Given that the same fixture has no red proof, the phylogenetic claim currently rests on
a single assertion that is allowed to not run.

#### Contract

**What the phylogenetic user actually gets is nothing, at both loci.** This is the most
serious contract defect and it is measured, not inferred. On
`bf(y ~ 1 + phylo(1 | species, tree = tree), sigma ~ 1 + phylo(1 | species, tree = tree))`
(fixture C's own model, converged):

- `summary(fit)$derived` → **0 rows**.
- `repeatability(fit)` / `icc(fit)` / `heritability(fit)` → **abort**:
  *"could not locate the working-scale parameter position for one or more structured
  components"*, raised at `R/heritability.R:312` before the new code is reached.

The cause is naming, and it is the same cause twice. Once a `sigma` endpoint exists,
`split_tmb_sdpars()` switches to per-`dpar` labels, so the mu component is called
`"mu:phylo(1 | species)"`. `drm_variance_ratio_positions()`'s structured regex is
`"^(phylo|animal|relmat|spatial|phylo_interaction)\\("` (`R/heritability.R:453`), which
does not match a `mu:` prefix, so the term is routed to the (empty) `log_sd_mu` pool
and yields `NA`. And `derived_summary_random_effect_kind()` returns `NULL` for the same
label — measured: `"phylo(1 | species)" -> phylo_total_variance_share`,
`"mu:phylo(1 | species)" -> NULL`. Meanwhile `man/heritability.Rd` and
`man/summary.drmTMB.Rd` now both state that this configuration is supported, and NEWS
says *"including a phylogenetic random intercept on `sigma` under the default
unit-diagonal correlation"*. **The internal helper is correct; no user-facing path
surfaces it.** Fixture C tests only `drmTMB:::drm_constant_residual_sigma()`, which is
exactly why the gap survived.

**Two residual scales now ship in one `summary()` object under names that do not
distinguish them.** Measured on fixture A:

```
summary(fit)$parameters       sigma            estimate 0.7599138   scale "response"
summary(fit)$derived          residual_sd      estimate 1.014436    scale "response"
```

Both are labelled `response`; one is the median `exp(b0)`, the other the RMS
`exp(b0 + sum omega^2)`; they differ by a third and nothing in the object or either
help page says why. `man/summary.drmTMB.Rd` documents the change to
`residual_variance` and never mentions `residual_sd`, nor the `sigma` parameter row it
now disagrees with. D-252's own diagnosis applies: *"One field name was carrying two
different quantities, which is the bigger defect."*

**`residual_variance.message` is written and never read.** `grep` across `R/` and
`tests/` finds exactly one occurrence, the assignment at `R/methods.R:4599`. I
confirmed the user-visible consequence: for the random-slope fixture,
`attr(summary(f2)$derived, "residual_variance.message")` is present, and
`any(grepl("random slope on sigma", capture.output(print(summary(f2)))))` is **FALSE**.
The convention it says it follows — `std_error.message` (`R/methods.R:4537`) — has no
consumer either. So the commit-message claim *"attaches `residual_variance.message`
instead of a silent empty frame"* is literally true and operationally empty: the frame
is still silent to anyone who does not read attributes. The `heritability()` abort text
*is* surfaced and is good — it names the defect precisely and I checked all four
branches of `drm_residual_sigma_na_reason_text()` render.

**One thing the man pages get right and should keep:** the Gaussian/identity gating
paragraph added to `man/summary.drmTMB.Rd` is accurate and correctly forecloses the
three-scale question, consistent with the earlier ruling on 275 §5.

#### Scope

- **Only two callers divide by it.** `grep drm_constant_residual_sigma` over `R/`
  returns `R/heritability.R:296` and `R/methods.R:4591` and nothing else; both are
  changed in this commit. No third consumer is left on the median.
- **`exp(unname(beta[[1L]]))` survives at `R/profile.R:1585` and `R/julia-bridge.R:5567`,
  and should.** Those build the *direct parameter* target row for `sigma`, where
  `exp(b0)` is the right answer for the coefficient. They are the source of the
  0.7599-vs-1.0144 collision above — the fix is naming, not arithmetic.
- **`spatial_mu_residual_scale()` (`R/check.R:3418-3430`) reports `mean(sigma(object))`,
  a third quantity again** (`0.8085` on fixture A, against median `0.7599` and RMS
  `1.0144`). It feeds a diagnostic, not an inference, so this is a note rather than a
  finding — but three residual scales now circulate in one package and only one of them
  is documented.
- **DRM.jl parity needs no new fence, but one row is now stale.**
  `docs/design/parity-matrix.md:90` already records the variance-ratio accessors as
  `unsupported` on the bridge, measured not assumed, and DRM.jl's `src/heritability.jl`
  has no random-effect-on-sigma route to reach this case. But the same row asserts the
  native side is *"point-fit-recovery ... delta-method Wald interval with a small-N
  sanity check, no coverage study"*, and both halves have moved: the **estimand changed**
  for any fit with a random intercept on `sigma`, and there **is** a coverage study now
  (this review, 500 reps, 0.910 / 0.928). The `sigma ~ 1` fixture the parity receipt was
  measured on (`h2 = 0.647012871707612`) is unaffected — the commit's test (d) asserts
  bit-identity and I re-confirmed it — so no re-measurement is owed, only a wording
  update. UNVERIFIED: I did not run DRM.jl.

#### Concrete change

1. **REQUIRED — stop making a false claim about `spatial(coords=)`.** Either (a)
   condition the refusal on the measured diagonal of the structured matrix, as the
   2026-09-14 ruling specified, or (b) if the check is deferred, change the message and
   both help pages to say the diagonal *was not checked* rather than that it *is not
   unit*. Option (a) is preferable and is the D-252-compliant answer: measured
   `diag(Sigma) = 1.000001` for `sigma ~ spatial(1 | site, coords = coords)`, so the
   closed form applies and the package is refusing a defined quantity. Option (b) is
   acceptable only as an explicit, dated deferral.
2. **REQUIRED — withdraw or fix the phylogenetic support claim.** `summary()$derived`
   returns 0 rows and `heritability()`/`icc()`/`repeatability()` abort for
   `phylo()`-on-mu + `phylo()`-on-`sigma`; the `mu:`-prefixed label defeats
   `R/heritability.R:453`'s regex and `derived_summary_random_effect_kind()`. Either
   teach both to strip a `^(mu|sigma):` prefix, or delete the phylogenetic sentence from
   `man/heritability.Rd`, `man/summary.drmTMB.Rd` and the NEWS bullet and record the gap.
   Do not leave a help page promising a number the package cannot produce.
3. **REQUIRED — extend fixture C to a user-facing assertion, and remove its
   self-disabling skip.** As written it asserts only on the internal helper, which is
   why item 2 went unnoticed; and `skip_if(elapsed > 60)` after the fit lets the only
   phylogenetic evidence evaporate on a slow machine. Assert on `summary()$derived` (or
   the documented refusal) and budget the fixture instead of skipping on it.
4. **REQUIRED — name the two residual scales.** `summary()$parameters["sigma"]` is
   `0.7599138` and `summary()$derived$residual_sd` is `1.014436` on the same fit, both
   marked `scale = "response"`. Document in `man/summary.drmTMB.Rd` that `residual_sd`
   is `sqrt(E[sigma^2])` and the `sigma` parameter row is the conditional/median scale,
   and say they coincide only when `sigma` has no random effect.
5. **REQUIRED — either surface `residual_variance.message` or drop the claim that it
   replaces silence.** It has no reader anywhere in the package (nor does the
   `std_error.message` convention it cites), and
   `print(summary(fit))` does not show it — measured FALSE. Printing one line in
   `print.summary.drmTMB()` when the attribute is set is the small change; otherwise
   amend the commit-message/help-page wording.
6. **REQUIRED — separate the estimation claim from the inference claim in NEWS.** Add
   that the delta interval remains a Wald interval whose measured coverage on this
   design is 0.910 (random intercept on `sigma`) and 0.928 (`sigma ~ 1` control), 500
   replicates each, so the SE change corrects *which* quantity is being bracketed and
   does **not** make the bracket nominal. Credit that the shortfall predates this
   commit.
7. OPTIONAL — add a `(1 | p | id)` fixture. The correlated mu-sigma route is supported,
   is exercised by users, and is correct here only because `rho` cancels out of both the
   marginal variance and the gradient. That reasoning is currently in no test and in no
   comment.
8. OPTIONAL — record the clamp caveat: `exp(2*b0 + 2*sum omega^2)` is the moment of the
   unclamped lognormal, so on a clamp-active fit it over-states the residual variance
   the kernel used (`src/drmTMB.cpp:781, 922`). One sentence beside the M2 wording.
9. OPTIONAL — record the two unreachable-today S2 routes as guarded assumptions so a
   later widening does not reintroduce the bug in silence: the `q > 2` covariance-block
   `sigma` key (`R/methods.R:1831-1839`), invisible to `has_sigma_random_effects()` but
   unreachable while both call sites are Gaussian-gated; and `mesh_spatial_mu` on
   `sigma`, likewise invisible but rejected at fit time
   (`tests/testthat/test-mesh-contract.R:24-27`).
10. OPTIONAL — update `docs/design/parity-matrix.md:90`: the native estimand moved for
    random-intercept-on-`sigma` fits, and "no coverage study" is no longer true. The
    bridge fence itself stands; DRM.jl requires `sigma ~ 1` and cannot reach this case.

---

### M2 follow-up (2a5b0665e)

VERDICT: REJECT — the `sd(group)` half (item 5) and the de-tautologised control
(item 6) are correct and should be kept, but the `predict_parameters()` half
(item 4) fixed a visible inconsistency by creating an invisible inference error:
measured against an unclamped truth, the new interval's coverage of the true
`sigma` at clamp-saturated rows falls from 0.93-0.97 (the pre-repair raw-eta
interval) to **0.000 at median width 0.0000**, and it ships with no flag.

#### Mechanism

**The clamp map and the containment claim check out.** `drm_softclamp_log_sd()`
(`R/drmTMB.R:23038-23060`) is `hi + m*tanh((x-hi)/m)` above the band, `lo -
m*tanh((lo-x)/m)` below, identity inside; it is continuous, `C^1` (derivative 1
at each knot) and strictly increasing, so the commit's stated invariant
`clamp(eta - z*se) <= clamp(eta) <= clamp(eta + z*se)` holds exactly. Re-derived,
and confirmed empirically: containment now holds for all 200 rows on the
clamp-active fixture where 100 rows are clamp-bent.

**But containment was the wrong thing to optimise.** The right question is what
the returned interval is an interval *for*. The package itself answers it:
`NEWS.md:2982` states the band is "a numerical guard only and does not change
identifiability", and the fit-time warning (`R/drmTMB.R:3610`) tells the
user that near the clamp "estimates and standard errors are unreliable". The
estimand is therefore `sigma`, not `c(sigma)`. I measured both candidate
intervals against an honest DGP — true `sigma(x) = exp(1.6x)` **unclamped**, the
band `c(-1, 1)` margin `0.3` set as a guard, 100 replicates, n = 200,
`scratchpad/fisher-cov3.R`:

| x | true sigma | cov: SHIPPED clamped CI | cov: pre-repair raw-eta CI | median width (raw) |
|---|---|---|---|---|
| -2.5 | 0.018 | **0.00** | 0.939 | 0.027 |
| -1.5 | 0.091 | **0.00** | 0.929 | 0.083 |
| 0.0 | 1.000 | 0.97 | 0.970 | 0.283 |
| 1.5 | 11.02 | **0.00** | 0.949 | 14.93 |
| 2.5 | 54.60 | **0.00** | 0.949 | 145.7 |

At the four clamp-bent rows the shipped interval is a zero-width point sitting on
the saturation asymptote `exp(1.3) = 3.669` while the truth is 0.018 / 0.091 /
11.0 / 54.6. The pre-repair raw interval covered at nominal rate *because it was
honestly enormous* (width 146 on a truth of 54.6) — that width is the correct
report of "this row carries almost no information about the scale". The new
interval reports the opposite. I also ran the mirror study with the truth
generated *through* the clamp (`scratchpad/fisher-coverage.R`, the fixture's own
DGP): there the shipped interval reads 0.960-0.967 coverage at width 0.0000. That
number is an artifact of a simulator that puts the truth exactly on the
asymptote, and should not be cited as validation. So: a user should get the RAW
interval with a clamp flag, or no interval at all — not this.

**Delta method: the repair is half-applied, and the half it skipped is the one
that matters.** The reported quantity is `q = g(c(eta))`, so `d q/d eta =
g'(c(eta)) * c'(eta)`, where `c'(eta) = sech^2((eta-hi)/m)` in the upper tail.
`R/predict-parameters.R:309-314` evaluates `g'` at the clamped eta (correct) but
then multiplies by the RAW `se_link` and never by `c'` — so the raw-scale SE is
pushed straight through a saturating map. Measured on the fixture
(`scratchpad/fisher-m2f-probe.R`): `c'(eta)` ranges `1.6e-10` to `1`; on the
worst row the reported link `std.error` is `0.374` against a delta-correct
`6.2e-11`, and on the response scale the reported SE overstates the
delta-correct SE by up to **6.1e9x**. The table is therefore internally
contradictory: the same row carries `conf.high - conf.low = 3.3e-9` and
`2 * z * std.error = 1.47`. Anyone who rebuilds a ribbon from `std.error` (the
ordinary broom-style use of this table) gets a different answer from
`conf.low`/`conf.high` in the same data frame. For a "Wald interval of the
reported quantity", the delta SE must carry `c'`; since that SE then collapses
to ~0, the honest conclusion is that no Wald interval should be reported on a
saturated row at all.

**Latent crash, introduced here.** `drm_softclamp_log_sd()` errors on `NA` input
whenever the assigned branch has length > 1 (`Error: NAs are not allowed in
subscripted assignments`; reproduced: `drm_softclamp_log_sd(c(0, NA, 2), band
c(-1,1,0.3))`). `R/predict-parameters.R:301-302` now feeds
`basis$eta +/- z*se_link` into it, and `predict_parameters_link_se()`
(`R/predict-parameters.R:349-361`) is written to return `NA_real_` per row, with
`ok <- is.finite(se_link)` and `conf.status = "wald_unavailable"`
(`:320,329`) existing precisely to handle that case. The commit removed a case
the surrounding code declares supported. I could not reach it end to end (a
fully-`NA` `vcov` aborts earlier in `drm_fixed_effect_basis_covariance()`, and an
`NA` covariate is rejected upstream), so the trigger — a finite but indefinite
`V`, most likely near a clamp boundary — is **UNVERIFIED** as an end-to-end
reproduction, but the crash at the call-site expression is verified.

**Item 5 (`sd(group)`) is correct.** `predict_random_scale_dpar()`
(`R/methods.R:6468`) now applies `drm_softclamp_log_sd()` then
`drm_exp_sd_logscale_guarded()`. That matches the kernel exactly:
`src/drmTMB.cpp:2474-2486` computes `eta_sd = X_sd_mu * beta_sd_mu` and wraps it
in the same two functions, gated only on `use_logsigma_clamp` and **not** on
family — so the R side correctly does not gate on
`drm_clamped_scale_families()` here either (unlike `drm_clamped_sigma_eta()`,
which must). It also matches `sd_mu_group_values()` / `sd_phylo_group_values()`
(`R/drmTMB.R:23062-23092`), hence `fit$sdpars`. Accept as written.

#### Negative control

`scratchpad/m2-repair-red.txt` holds two runs. The first is the `se = FALSE`
fixture and its four containment failures read `actual: <NA>` — measuring
nothing, exactly as the brief suspected. The second run is the `se = TRUE`
fixture and reads `actual: FALSE` at `test-dinnage-audit-m2.R:170,171,180,181`,
which is the right reason. So the final red proof for item 4 **is** from the
`se = TRUE` fixture. Good. Item 5's red is in run 1 only (`:178`, `1.2706 vs
1.2623`, `0.1211 vs 0.7788`) — a genuine numeric mismatch independent of the
`se` defect, so that is a valid red. Re-ran `test-dinnage-audit-m2.R` at HEAD:
16 assertions, all green.

Two limits on what the green proves. (a) The containment assertion is the *only*
new assertion; nothing tests the SE, the width, or coverage, so the regression
above is invisible to the suite. (b) Item 5's green compares
`predict(dpar = "sd(id)")` with `fit$sdpars`, and both now route through the same
R helper `drm_softclamp_log_sd()`. It is a valid check of the eta construction,
but it is **not** a check that R's clamp equals the kernel's — that comparison
(against `report$sd_mu_group`, which `src/drmTMB.cpp:2499` already REPORTs) is
still absent.

#### Contract

`?predict_parameters` (`R/predict-parameters.R:1-64`) says nothing about the
clamp. Worse, `:23-25` says "response-scale intervals use the model link and a
delta method standard error", which after this commit describes neither
endpoint: the endpoints are a monotone transform of the raw Wald interval, and
the `std.error` is a delta SE for a different quantity. The `conf.status` column
reads `"wald"` for all 200 rows on the clamp-active fixture — including the 100
rows whose interval is an artifact of the band.

The `NEWS.md` M2 bullet (`NEWS.md:36-57`) *has* been extended to name
`predict_parameters()` and `predict(dpar = "sd(group)")`, so it is no longer
incomplete. It is now inaccurate in a different way: "each endpoint now passes
through the same monotone map, so containment holds" is true and is offered as
the repair, with no mention that containment was bought with the interval's
coverage. The closing line, "Reporting the clamped value makes such a fit honest,
not correct: when `check_drm()` says the clamp is active, rescale the response
and refit", is the right instinct — but `check_drm()` does not say it for the
`sd(group)` case (see Scope 5), and a zero-width interval is not what "honest"
looks like.

#### Scope — other raw-eta consumers

Fixed: `R/methods.R:2942` (`predict.drmTMB`), `R/methods.R:6882`
(`drm_marginal_predict`, the `simulate()` path), `R/methods.R:6468`
(`predict_random_scale_dpar`, this commit), `R/predict-parameters.R:301-302,309`
(this commit). `emmeans` is `dpar = "mu"`-only
(`R/emmeans-preflight.R:1-40`) and so is not affected;
`R/distributional-outputs.R` (quantile / exceedance / centile chart) and
`prediction_grid()` / `marginal_parameters()` all route through
`predict.drmTMB()` and inherit the fix.

Still raw, measured or read:

1. `R/methods.R:4723` and `R/methods.R:4729` — `drm_constant_residual_sigma()`
   returns `exp(b0)` / `exp(b0 + omega2_sum)` from the RAW sigma intercept. This
   feeds `summary()$derived` (`R/methods.R:4591`) and
   `heritability()`/`icc()`/`repeatability()` (`R/heritability.R:296`).
   **Measured** on a clamp-active fit (band `c(-0.2, 0.2)`, margin `0.05`, true
   residual sd 3): `sigma(fit)[1] = 1.284` while `summary()$derived$residual_sd
   = 3.074` — the same fit reports two residual SDs 2.4x apart, one from a
   surface M2 fixed and one from a surface it did not. This is the highest-value
   unfixed item, because the variance-ratio denominator is the whole quantity.
2. `R/methods.R:5064` — `summary_parameter_delta_derivative()` uses
   `exp = exp(eta)` at the raw `link_estimate`, i.e. the same missing `c'` factor
   as Mechanism above, for the summary table's `sigma` row SE.
3. `R/profile.R:4509` (`profile_transform_newdata_interval`, `log = exp(eta_interval)`)
   and `R/profile.R:1585` (`estimate = exp(unname(beta[[1L]]))` for the
   distributional-scale target) — response-scale profile output for `sigma` is
   built on the raw predictor. Note the asymmetry: `profile()` already has a
   clamp-aware refusal for the *direct-SD* targets
   (`drm_profile_direct_sd_clamp_trace`, `R/profile.R:4322-4377`;
   `clamp_limited` at `:1118-1121`, `:3446-3452`, `:3514-3530`) but **no**
   equivalent trace for the residual `log_sigma` predictor.
4. `R/julia-bridge.R:5567` — same `exp(unname(beta[[1L]]))` pattern for the
   bridge's scale profile target. Whether DRM.jl clamps at all is **UNVERIFIED**;
   if it does not, this is correct for that engine and should be commented as
   such.
5. `R/drmTMB.R:3557` — `drm_logsigma_clamp_active()` reads only `log_sigma`,
   `log_sigma1`, `log_sigma2`, never `log_sd_mu_group` (which
   `src/drmTMB.cpp:2499` REPORTs). So a fit whose only saturated predictor is a
   modelled random-effect SD gets no clamp note from `check_drm()` and no
   fit-time warning. This commit makes that gap bite harder: **measured** on the
   M2 test's own `sd(id)` fixture, 42 of 48 groups are clamp-bent and the
   reported `sd(id)` spread collapses from a raw `[0.031, 3.553]` (115x) to
   `[0.779, 1.284]` (1.6x). The new value is what the likelihood used and is the
   right thing to report — but a reader will read that 1.6x as between-group
   heterogeneity when it is the band.

#### Concrete change

1. **REQUIRED.** Do not ship the clamped Wald endpoints unflagged. The smallest
   change consistent with the rest of the package is to reuse the status
   `profile()` already uses: when `drm_clamped_sigma_eta()` moves a row's eta,
   return `std.error = conf.low = conf.high = NA_real_` and
   `conf.status = "clamp_limited"`, `interval_source = "not_available"` for that
   row, exactly as `drm_profile_clamp_limited_confint_row()`
   (`R/profile.R:3514-3530`) does. The acceptable alternative is to restore the
   RAW endpoints (which have near-nominal coverage, table above) and add an
   explicit `clamp_active` flag plus a documented sentence that on flagged rows
   the point estimate is the clamped value the likelihood used while the interval
   is for the unclamped predictor. What must not ship is a zero-width unflagged
   interval.
2. **REQUIRED.** Make `std.error` and the endpoints refer to the same quantity.
   If any clamped endpoint survives, multiply `se_link` by
   `c'(eta) = sech^2((eta - hi)/m)` (upper) / `sech^2((lo - eta)/m)` (lower),
   1 inside the band, at `R/predict-parameters.R:305-315`. As shipped the two
   halves of the same row disagree by up to 6.1e9x.
3. **REQUIRED.** Add the coverage assertion the containment test does not make:
   on a clamp-active fixture with an UNCLAMPED truth, assert that a saturated
   row does not return a finite interval of width < some epsilon claiming to be
   a `"wald"` interval. Containment alone cannot fail on this defect — it is
   satisfied trivially by a point.
4. **REQUIRED.** Guard the `NA` path: compute `lo_link`/`hi_link` only for
   `ok` rows (`R/predict-parameters.R:288-302`), or make
   `drm_softclamp_log_sd()` `NA`-safe by masking with `!is.na(x) & x > hi`. One
   line either way; the surrounding `wald_unavailable` machinery already
   declares the case supported.
5. **REQUIRED.** Close the `summary()`/`icc()`/`repeatability()` inconsistency at
   `R/methods.R:4723,4729`, or state in `?summary.drmTMB` and the accessor pages
   that `residual_sd` is the unclamped predictor while `sigma()` is the clamped
   one. Two different residual SDs from one fit with no explanation is the kind
   of thing the audit exists to catch. (Cross-lane: this touches the S2 lane's
   function, so it may belong in that lane rather than this commit.)
6. **REQUIRED.** Soften the `NEWS.md:51-52` sentence. "each endpoint now passes
   through the same monotone map, so containment holds" states the invariant that
   was gained without the coverage that was lost. Say what the interval now is,
   and that a clamp-bent row's interval is not evidence about `sigma`.
7. **OPTIONAL.** Extend `drm_logsigma_clamp_active()` (`R/drmTMB.R:3557`) to read
   `log_sd_mu_group` / `log_sd_phylo_group`, so the `sd(group)` saturation this
   commit now surfaces silently is also reported by `check_drm()`.
8. **OPTIONAL.** Add the R-vs-kernel clamp equality test the item-5 green does
   not provide: compare `predict(fit, dpar = "sd(id)")` with
   `exp(fit$obj$report(...)$log_sd_mu_group)` rather than with `fit$sdpars`,
   which shares R's helper.
9. **OPTIONAL.** Add one sentence to `?predict_parameters`
   (`R/predict-parameters.R:23-25`) naming the clamp and correcting "response-scale
   intervals use ... a delta method standard error", which is no longer what the
   endpoints are.

---

### M2 follow-up 2 (e86359fe2)

VERDICT: ACCEPT-WITH-CHANGES — the rejected defect is genuinely gone (no
zero-width unflagged interval survives, `std.error` and the endpoints now
refer to the same quantity, and the `NA`-into-clamp crash path is removed by
deleting the clamp call rather than by guarding it), but the refusal rule is a
data-dependent selection on the *estimate*, and I measure that the intervals it
keeps and labels `"wald"` under-cover progressively near the band edge
(0.985 -> 0.882 over 996 replicates) while the unconditional raw interval is
0.98 everywhere; that unmeasured selection cost, a help sentence that justifies
the rule with a flatness claim false at its own boundary, and a public
`conf.status` table that does not list the new value are what still need fixing.

Reviewed at `e86359fe2` on the worktree
`/Users/z3437171/local-scratch/lanes/drmTMB-audit-dinnage-wave1`; `HEAD` had
already advanced to `d61f65183` while this review ran, and where that matters it
is said in place. Probe scripts: `scratchpad/f2-probe1.R`, `f2-probe2.R`,
`f2-probe3.R`, `f2-scope.R`, `f2-re.R`, `f2-neg.R`, `f2-cov.R`, `f2-cov2.R`.

#### Mechanism — is "raw eta outside `[lo, hi]`" the right definition of clamp-bent?

**As a definition of "the clamp touched this row", it is exact, not a
threshold.** Re-derived from `drm_softclamp_log_sd()`
(`R/drmTMB.R:23037-23059`): the function assigns only under `x > hi` and
`x < lo`, so it is the *identity* on the closed band, and `c'(eta)` is
`sech^2((eta-hi)/m)` above, `sech^2((lo-eta)/m)` below, `1` inside — continuous
and equal to 1 at each knot. So "raw eta outside `[lo, hi]`" is the exact
support of the clamp's action, and `predict_parameters_clamp_bent()`
(`R/predict-parameters.R:376-402`) agrees with a hand classification on every
row I checked: 200/200 on the Gaussian fixture, 150/150 on a `biv_gaussian`
`sigma1` fit, 250/250 on an `nbinom2` dispersion fit. Evidence.

**But the rule's justification in the help text is false at its own boundary.**
The new roxygen (`R/predict-parameters.R:32-33`) says the endpoints are `NA`
because "the likelihood is flat with respect to that row's unclamped
predictor". Measured on the test file's own fixture (`m2_wald_fixture()`,
band `c(-1, 1)`, margin `0.3`, 100 of 200 rows bent), `c'(eta)` over the bent
rows runs from `0` to `0.9993`:

| `c'(eta)` among the 100 bent rows | count |
| --- | --- |
| `> 0.99` | 3 |
| `> 0.95` | 11 |
| `> 0.90` | 13 |
| `> 0.50` | 28 |

and 18 of the 100 bent rows are moved by the clamp by **less than 0.1 of their
own `se_link`** (11 by less than `1e-3` on the link scale). The likelihood is
not flat at those rows; the clamp is numerically invisible there. A
derivative-based rule (`bent` when `c' < t`) would admit them, but it would
only move the cliff, not remove it. The defensible statement is the one about
the *estimand*, not about flatness: the clamp bent that row, so a Wald interval
built on the raw predictor is not an interval for the reported (clamped)
quantity, and where the bend is strong no Wald interval exists at all. Fix the
sentence, keep the rule.

**Does refusing rows just outside the band lose anything? Measured: yes, and in
a way the test cannot see.** Honest DGP — true `sigma(x) = exp(1.6x)`
**unclamped**, band `c(-1, 1)` margin `0.3` as a numerical guard, `n = 200`,
996 usable replicates, link scale, `scratchpad/f2-cov2.R`. `cov_RAW_all` is the
raw-eta Wald interval evaluated on *every* replicate; `cov | KEPT` is the same
interval restricted to the replicates in which the shipped rule actually
returns it (`conf.status == "wald"`):

| true `eta` | inside band? | refusal rate | `cov_RAW_all` | n kept | `cov \| KEPT` (± se) |
| --- | --- | --- | --- | --- | --- |
| 0.880 | yes | 0.274 | 0.981 | 723 | 0.985 ± 0.005 |
| 0.960 | yes | 0.525 | 0.982 | 473 | 0.979 ± 0.007 |
| 1.000 | at edge | 0.680 | 0.982 | 319 | 0.969 ± 0.010 |
| 1.040 | no | 0.780 | 0.984 | 219 | 0.959 ± 0.013 |
| 1.088 | no | 0.885 | 0.985 | 115 | 0.930 ± 0.024 |
| 1.120 | no | 0.932 | 0.984 | 68 | **0.882 ± 0.039** |
| 1.200 | no | 0.992 | 0.984 | 8 | 0.250 ± 0.153 |

Three readings, in descending strength.

1. **The refusal is conditioned on the estimate, so it truncates the sampling
   distribution of the intervals that survive.** The unconditional raw interval
   is well calibrated at every row (0.981-0.985 against a nominal 0.95 — mildly
   conservative, honestly so). Restricted to the rows the shipped rule keeps and
   labels `"wald"`, coverage falls monotonically across seven grid points to
   0.882 at `eta = 1.12` and 0.25 at `eta = 1.20`. The single worst point rests
   on 68 kept replicates (1.7 se below nominal) and the 8-replicate point is
   anecdote, but the **monotone trend over 996 fits with an obvious mechanism**
   is not: keeping an interval only when the point estimate landed inside the
   band systematically keeps the replicates whose estimate was pulled toward the
   band and away from the truth. This is a *new* defect relative to
   pre-2a5b0665e behaviour, which had no selection and covered at 0.98
   everywhere. The `"wald"` label is an inference claim of nominal coverage; on
   the near-edge rows the selected ensemble does not deliver it.
2. **The two options the previous review sanctioned are not equivalent, and the
   commit took the weaker one on coverage.** Option 2 — raw endpoints everywhere
   plus an advisory `clamp_active` flag — has no selection effect by
   construction. I am not asking for the change (option 1 is defensible on the
   grounds that a refusal cannot mislead and a wrong number can, and it matches
   `profile()`'s existing vocabulary), but the cost must be recorded rather than
   assumed away.
3. **The availability cost lands hardest on rows that are not saturated.** At
   `eta_true` of 0.96 and 1.00 — inside or exactly at the band — 52% and 68% of
   replicates return no interval. A user asking about a covariate value whose
   true scale is inside the guard band gets "not available" the majority of the
   time, decided by sampling noise in `beta_sigma`.

**The estimate/interval pairing is the prescribed one, and the help says so —
barely.** Verified on the fixture: on bent rows `estimate` equals
`clamp(raw eta)` exactly (`all.equal` TRUE) and is *not* the raw eta, on both
scales, while `conf.low`/`conf.high`/`std.error` are `NA`. That is exactly what
item 1 asked for. The roxygen conveys it only through the parenthetical
"the reported (clamped) quantity" (`R/predict-parameters.R:33-34`); the help
page never states plainly that the `estimate` column for a `sigma` dpar is the
clamped scale the likelihood evaluated rather than `exp(eta)`.

**Also verified, on the committed tree:** with `newdata`, `predict()`'s link
estimate equals `clamp(basis$eta)` to machine zero even for `sigma ~ x + (1|id)`
(max abs difference 0, vs 4.59 against the raw `basis$eta`), so the flag is
computed on the same predictor the estimate comes from; and containment holds on
every kept row of that fit (0 violations of 111).

#### Negative control

`scratchpad/pp-repair-red.txt` is a genuine red for items 1-3, and I checked
each failure against 2a5b0665e's formula rather than trusting the label.

* Failures 1-8 (`test-dinnage-audit-m2.R:231-244`): status `"wald"` and non-`NA`
  endpoints on all 100 clamp-bent rows. That is what
  `conf.status = ifelse(ok, "wald", "wald_unavailable")` had to produce. Right
  reason.
* Failures 9-10 (`:307-308`): the in-band endpoint mismatch. I recomputed the
  old map by hand — `hi + m*tanh((x-hi)/m)` / `lo - m*tanh((lo-x)/m)` at
  `lo = -1, hi = 1, m = 0.3` — on the four numbers printed in the red proof:
  `-1.102272 -> -1.098486`, `-1.017310 -> -1.017291`, `1.083449 -> 1.081361`,
  `1.127844 -> 1.120629`. All four reproduce the red's `actual` column to six
  decimals. So the old code bent the *endpoint* even on rows whose own eta was
  in the band, and that is precisely why those rows failed. Right reason, exactly.
* Failures 11-12 (`:315,317`): a clamp-bent row labelled `"wald"`, and a
  zero-width `"wald"` interval. The two defects the previous review named. Right
  reason.

**Item 4 has no negative control, and did not need one.** The third new block
(`:337-364`, the `se = FALSE` fit) passed on 2a5b0665e as well — the trailing
dots in the red proof's progress line. I confirmed why: with `se = FALSE`,
`drm_fixed_effect_basis(covariance = TRUE)` *errors*
("Fixed-effect covariance is unavailable because `TMB::sdreport()` was skipped"),
so `predict_parameters_interval()` exits at the early `wald_unavailable` return
(`R/predict-parameters.R:293-298`) and never reaches the clamp at all. The test
therefore exercises a path that was already safe. The real repair for item 4 is
better than the guard that was asked for: the commit **removes the
`drm_softclamp_log_sd()` call from the interval path entirely**, so the crash is
structurally unreachable, not merely masked. (The underlying helper is still
`NA`-unsafe — `drm_softclamp_log_sd(c(0, NA, 2), band c(-1,1,0.3))` still
errors "NAs are not allowed in subscripted assignments" — but its remaining
callers are fed etas that are validated finite upstream. **UNVERIFIED** whether
any reachable path feeds it an `NA`.)

**Green, re-run in this worktree at `e86359fe2`:** `test-dinnage-audit-m2.R`
42 assertions, 0 failures. Neighbours also green and unregressed:
`test-predict-parameters.R` (80), `test-marginal-parameters.R` (30),
`test-plot-parameter-surface.R` (46), `test-distributional-outputs.R` (33).

**What the green does not cover.** (a) No assertion measures coverage, width, or
availability — the new selection effect above is invisible to the suite, exactly
as the previous round's regression was. The item-3 assertion
(`widths >= 1e-6`) is the right shape but it only rules out the *previous*
failure mode. (b) Only `gaussian` is exercised. I closed that by hand, not in
the suite: `biv_gaussian` `sigma1` flags 92/150 rows and `nbinom2` `sigma`
flags 13/250, both matching an independent hand classification exactly.

#### Contract

**The roxygen is the source of truth, and at `e86359fe2` it was not what
ships — since repaired downstream.** `git show e86359fe2:man/predict_parameters.Rd`
contains no occurrence of "clamp": the commit changed the roxygen without
running `devtools::document()`, so as committed the entire new contract was
invisible at `?predict_parameters`. It was regenerated two commits later, as a
side effect of `d61f65183` (`man/predict_parameters.Rd`, +12 lines), and the
current `HEAD` Rd carries the clamp paragraph verbatim. Recorded rather than
required: the defect is real in the commit under review and already discharged
in the branch.

**The new status is properly registered, which is the part that is right.**
`clamp_limited` is already in `interval_status_levels()`
(`R/profile.R:1442-1457`) and `not_available` in `interval_source_levels()`
(`:1459`), so `plot_parameter_surface()` excludes those rows from ribbons
without any change (`R/plot-parameter-surface.R:342-366`) and the four
neighbouring test files stay green. Reusing `profile()`'s vocabulary was the
right call.

**But the public vocabulary table does not list it.**
`vignettes/articles/model-workflow.Rmd:509-521` is the canonical "read
`conf.status` as an action column" table — the one
`vignettes/first-week-intervals.Rmd:141-145` sends readers to. It lists 11 of
the 12 `interval_status_levels()` values. The only one missing is
`clamp_limited`, and this commit is what makes it reachable from a second public
surface.

**`R/predict-parameters.R:23-25` is accurate again.** "Response-scale intervals
use the model link and a delta method standard error" was false under
2a5b0665e; with the raw endpoints and the derivative back at the raw eta it is
true once more for every row that returns an interval. Previous OPTIONAL item 9
is discharged.

**NEWS: the sentence under review is not in the commit.** `e86359fe2` touched
two files (`R/predict-parameters.R`, `tests/testthat/test-dinnage-audit-m2.R`);
`git show e86359fe2:NEWS.md` has no wave-3 M2 bullet at all. The text quoted in
my brief lives only in the **uncommitted** working-tree `NEWS.md` (lines 36-64).
Judged as a draft, it is honest about the history — it names the zero-width
collapse and the measured coverage 0, and it does not repeat 2a5b0665e's
containment framing. It is silent on the one thing a user needs to plan around:
**which** rows lose their interval, and that the loss is decided by where the
estimate landed, not by where the truth is.

#### Scope

**Inside `R/predict-parameters.R`, nothing else bypasses the flag.** Traced all
four early returns (`:262-299`): `not_requested`, `newdata_required`
(so fitted-row calls never produce an interval at all, clamp or no clamp),
`is_random_scale_dpar` -> `wald_unavailable` (so `sd(group)` needs no
`clamp_limited` analogue), and the basis-error `wald_unavailable`. The single
`"link"`/`"response"` branch at `:334-352` is the only place endpoints are
built, and both arms are masked by `!ok | clamp_bent` at `:355-357`. `mu`,
`nu`, `rho12`, `zi`, `hu` correctly never flag, matching the kernel, which
soft-clamps only `log_sigma`/`log_sigma1`/`log_sigma2` and the direct-SD
predictor. There is no separate "quantile" branch in this file; the quantile and
centile surfaces (`R/distributional-outputs.R`, `R/family-dpq.R:1270`) and
`marginal_parameters()` (`R/marginal-parameters.R:86`) all call
`predict_parameters()` with `conf.int` left at `FALSE` and read only `estimate`,
which is the clamped value — consistent, and they overwrite `conf.status` with
`not_requested` (`R/marginal-parameters.R:153`), so no status is silently
propagated.

**One residual asymmetry, stated not fixed.** 11 of the 100 *kept* rows on the
fixture have a raw Wald endpoint lying outside the band, so an interval labelled
`"wald"` reaches into a region the likelihood cannot evaluate as a scale. That
is the correct interval for the raw predictor under the "band is a numerical
guard" reading, and it is the behaviour the previous review endorsed; it is
worth one sentence rather than a code change.

**Gate mismatch between the two clamp predicates (low priority).**
`predict_parameters_clamp_bent()` accepts `length(band) >= 2` and checks
`anyNA(band[1:2])` (`R/predict-parameters.R:390-394`), while
`drm_softclamp_log_sd()` requires `length(band) >= 3` and all three entries
finite (`R/drmTMB.R:23044-23048`). A band with a non-finite margin would make
the clamp a no-op while the flag still fired, refusing intervals with no clamp
in force. `drm_control()` always constructs a length-3 band
(`R/drmTMB.R:638-647`) and I measured `c(-1, 1, 0.3)` on the fixture, so I
believe this is unreachable through the public API; **UNVERIFIED** whether a
non-finite `logsigma_clamp_margin` can survive validation.

**The `sd(group)` half of 2a5b0665e is untouched and still correct.**
`git diff 2a5b0665e e86359fe2 -- R/methods.R R/heritability.R` is empty, and
reading `git show e86359fe2:R/methods.R` (not the working tree, which another
lane is editing): `predict_random_scale_dpar()` at `:6457-6472` applies
`drm_softclamp_log_sd(eta, object$model$tmb_data)` before the `link`/`response`
split, then `drm_exp_sd_logscale_guarded()` on the response arm — the same two
functions in the same order as `src/drmTMB.cpp:2482-2485` and
`sd_mu_group_values()`, gated on `use_logsigma_clamp` and not on family, which
is correct for this predictor. Unchanged from the version accepted last round.

#### Concrete change

1. **REQUIRED.** Replace the "the likelihood is flat with respect to that row's
   unclamped predictor" clause (`R/predict-parameters.R:32-33`). It is false for
   13 of the 100 bent rows on the file's own fixture (`c' > 0.90`, up to
   0.9993) and for the 18 rows the clamp moves by less than 0.1 `se`. Say
   instead that the clamp bent that row, so the raw-predictor Wald interval is
   not an interval for the reported clamped quantity, and that where the bend is
   strong no Wald interval is defined at all.
2. **DISCHARGED (was REQUIRED).** `e86359fe2` changed the roxygen without running
   `devtools::document()`, so as committed the new contract never reached
   `man/predict_parameters.Rd`. `d61f65183` regenerated it. No action; noted so
   the pattern (roxygen edited, `document()` skipped) is visible.
3. **REQUIRED.** Add a `clamp_limited` row to the `conf.status` action table at
   `vignettes/articles/model-workflow.Rmd:509-521` — the only member of
   `interval_status_levels()` it omits, and now reachable from a second public
   surface. Action text: the clamp bent this row's predictor, so no Wald
   interval is reported; check `check_drm()`, rescale the response or widen
   `drm_control(logsigma_clamp = )`, and refit before interpreting the scale.
4. **REQUIRED.** Record the availability/selection cost, in the help page and in
   the NEWS bullet, in one sentence each: whether a row returns an interval
   depends on where the *estimate* fell relative to the band, not on where the
   truth is, so near the band edge a majority of rows whose true predictor is
   inside the band will report no interval (52% at `eta_true = 0.96`, 68% at
   1.00, measured), and the intervals that are returned there are conditioned on
   that selection. This is the honest counterpart of the previous round's
   "coverage 0" disclosure and it should not have to be rediscovered.
5. **REQUIRED.** Land the NEWS bullet. The sentence this review was asked to
   judge is not in `e86359fe2`; it is uncommitted working-tree text. As drafted
   it is accurate about the code and about the history — amend it per item 4 and
   commit it, so the released note and the shipped behaviour agree.
6. **OPTIONAL but high value.** Add the coverage assertion the suite still lacks,
   in the shape the previous review's item 3 intended but one level up: on an
   **unclamped-truth** DGP, assert that the interval returned on rows labelled
   `"wald"` covers at approximately nominal rate, and record the refusal rate.
   Even a 200-replicate pinned-seed check would have caught the selection effect
   above. Without it, the file's contract is "the code does what the code does".
7. **OPTIONAL.** Add the two non-Gaussian cases I verified by hand:
   `biv_gaussian` `sigma1` and one dispersion family (`nbinom2`), asserting the
   flag matches an independent hand classification. The family gate is currently
   exercised on 1 of `drm_clamped_scale_families()`'s 14 entries in the suite.
8. **OPTIONAL.** Rename the `se = FALSE` block (`test-dinnage-audit-m2.R:337`)
   so it does not read as the red for item 4. It passes on both trees; item 4 is
   satisfied by deleting the clamp call from the interval path, which is
   stronger, and the block's real value is as a regression guard on the early
   `wald_unavailable` return.
9. **OPTIONAL.** Make the two clamp predicates share one band-validity helper
   (`R/predict-parameters.R:390-394` vs `R/drmTMB.R:23044-23048`), so the flag
   can never fire on a band the clamp itself treats as disabled.
10. **OPTIONAL.** One sentence on each of: that the `estimate` column for a
    `sigma` dpar is the clamped scale the likelihood evaluated, not `exp(eta)`;
    and that a kept `"wald"` interval may have an endpoint outside the band
    (11 of 100 kept rows on the fixture), which is correct for the raw predictor
    and should be expected rather than reported as a bug.

---

### S2b follow-up (4ae2f5d99, d61f65183)

VERDICT: REJECT — items 2-6 are genuinely met and `d61f65183`'s direction is
right and should be kept, but replacing the label-based refusal with a measured
one introduced the same defect it was asked to remove, in the opposite
direction: `phylo()` on `sigma` alone is now refused as *"measured and does not
have a unit diagonal"* when its tip-level correlation diagonal is exactly 1
(measured), which is a capability regression against the parent commit and
falsifies the NEWS sentence this repair was written to make true.

*Reviewer: Fisher, fresh context, read-only except this file. Worktree
`/Users/z3437171/local-scratch/lanes/drmTMB-audit-dinnage-wave1`. Reviewed
`4ae2f5d99` and `d61f65183` only. Nothing recompiled. Every number below was
measured in this worktree unless marked UNVERIFIED. Probe scripts:
`<scratchpad>/fisher2-*.R`.*

#### Mechanism

**The measured-diagonal rule is the right rule, and it is applied to the wrong
matrix.** `drm_structured_sigma_unit_diagonal()` (`R/methods.R:4817-4881`)
inverts `phylo_mu$precision$precision` whenever `structured_mu_q(phylo_mu) == 1L`.
For `spatial(1 | site, coords = )` that matrix is the 25x25 site-level
precision and the rule works exactly as advertised — **measured:
`diag(solve(Q))` in `[1.000001, 1.000001]`, `unit_diagonal -> TRUE`,
`summary(fit)$derived` returns 1 row, `residual_sd = 0.7415`** on
`bf(y ~ x + (1 | g), sigma ~ spatial(1 | site, coords = coords))`. Item 1 is met
for `spatial()`.

**But `phylo()` on `sigma` alone is `q == 1` too, and its precision is the
augmented tips-plus-internal-nodes matrix.** The commit's own comment
(`R/methods.R:4830-4841`) attributes the latent-node basis to `q > 1L` joint
blocks; that is false. Measured on
`bf(y ~ 1 + (1 | g), sigma ~ 1 + phylo(1 | species, tree = tree))`, 20 tips,
converged (`convergence = 0`):

```
q = 1   type = phylo   dim(precision) = 38 x 38
range(diag(solve(Q))) = [0.5540601, 1]          -> unit_diagonal = FALSE
drm_sigma_random_effect_omega2_sum()  -> NA, reason "structured_sigma_non_unit_diagonal"
summary(fit)$derived                  -> 0 rows
repeatability(fit)                    -> abort: "...whose correlation matrix was
                                          MEASURED and does not have a unit diagonal"
```

The tip-level correlation is unit — `range(diag(ape::vcv(tree, corr = TRUE)))`
is `[1, 1]`, and `diag(solve(Q))[1:20]` (the tip rows) is **exactly 1** for all
20 tips; only the 18 internal-node rows range down to 0.554. So the package now
tells the user a measured falsehood about a quantity that is defined, which is
the precise D-252 failure the predecessor's item 1 named, and the commit message
promises *"never a false 'not unit'"*. It is also a **capability regression**:
with the pre-`4ae2f5d99` predicate restored in-session
(`assignInNamespace("drm_structured_sigma_unit_diagonal", function(...) TRUE)`),
the same fit yields `nrow(derived) = 1` and a working
`repeatability()` (`estimate 1.11e-10, se 2.72e-06`). The suite cannot see this
because fixture C puts `phylo()` on **both** endpoints, which is `q = 2` and
takes the trusted-by-construction branch.

**The fix is cheap and exact, and the object already carries what it needs.**
`drm_phylo_augmented_precision()` returns `tip_node_index` (and
`species_node_index` when a species factor is supplied) —
`R/phylo-utils.R:258` et seq.; measured `str()` shows both fields. Measuring
`diag(solve(Q))[tip_node_index]` rather than the whole augmented diagonal gets
`phylo()` right, keeps `spatial()`/`relmat()`/`animal()` right (their precision
is already indexed 1:1 by the modelled unit), and — indexed by the right
endpoint's rows — would also retire the `q > 1L` "trusted by construction"
branch entirely. The same latent-basis failure mode presumably reaches
`phylo_interaction()` on `sigma` (a Kronecker of two augmented precisions);
UNVERIFIED, I did not fit one.

**The `type == "phylo"` trust inside a `q > 1` block is sound today, and I
re-verified the premise independently rather than inheriting it.** `phylo()`'s
formals are `function(term, tree)` (`R/formula-markers.R:196`), and all three
call sites of the precision builder take the default —
`R/drmTMB.R:14083`, `14146`, `14147` all call
`drm_phylo_augmented_precision(tree, species = )` with no `correlation`
argument, and `grep -rn "correlation = FALSE" R/` returns only the two comment
lines added by this commit. `correlation = TRUE` forces
`require_ultrametric = TRUE` (`R/phylo-utils.R:273`) and divides by tree height
(`R/phylo-utils.R:251-252`). So the claim holds. It is a *grammar* guarantee, not
a *matrix* guarantee, and it becomes unnecessary once the diagonal is measured on
the tip rows.

**The prefix strip is safe.** `sub("^(mu|sigma):", "", names(sd_values))`
(`R/heritability.R:458`) feeds only the `is_structured` classification; positions
are then assigned by **rank within the `log_sd_mu` / `log_sd_phylo` pools**
(`R/heritability.R:465-479`), never by name, so two terms colliding to the same
stripped label cannot cross-assign. In `derived_summary_random_effect_kind()`
(`R/methods.R:4927-4933`) the strip also removes a `sigma:` prefix, but the only
caller iterates `object$sdpars$mu` (`R/methods.R:4629`), so a `sigma`-endpoint
label never reaches it. A group literally named `mu` gives the label
`(1 | mu)`, which does not match `^(mu|sigma):`. No collision found.

**And the strip is not merely non-harmful — the numbers behind it are right.** I
re-derived fixture C's share and its delta SE from `fit$sdr$cov.fixed` by hand
(`share = e^{2 t_mu} / (e^{2 t_mu} + e^{2 b0 + 2 e^{2 t_s}})`, gradient by
`numDeriv::grad`, contracted with the 3x3 submatrix at positions
`log_sd_phylo[mu]`, `beta_sigma`, `log_sd_phylo[sigma]`): **independent
0.11818891, package 0.11818891, estimate 0.71549514 both**. The `eta_cor_phylo`
position is correctly excluded — `rho(u_mu, u_sigma)` cancels out of the marginal
variance, so its gradient entry is zero. The rank-order mapping from prefixed
labels to `log_sd_phylo` positions is therefore right, not just non-aborting.

**Tolerance and conditioning.** `tol = 1e-3` on `abs(d - 1)`
(`R/methods.R:4880`) is well chosen: an accepted worst case propagates a relative
error of about `2*sum(omega^2)*1e-3` into `residual_variance` (0.2% at
`omega = 1`), while an `animal()` pedigree with any inbreeding (`diag = 1 + F`)
is correctly refused. The `tryCatch` on `Matrix::solve` returns `NA` -> "not
checked" on a hard failure, which is the honest branch. The gap is **near**
singularity: an ill-conditioned inversion returns finite garbage, `d` drifts off
1, and the caller reports *"measured and does not have a unit diagonal"* — the
same false-claim class again. No `rcond`/condition check is present.

**No size guard, and the cost is not negligible.** The inversion is dense
(`as.matrix(Matrix::solve(precision))`) and is recomputed on every `summary()`,
`heritability()`, `icc()` and `repeatability()` call — `drm_constant_residual_sigma()`
has exactly two callers (`R/heritability.R:296`, `R/methods.R:4612`) and neither
caches. Measured on a synthetic exponential-correlation precision: **n = 500 ->
0.05 s, n = 1500 -> 1.19 s, n = 3000 -> 9.63 s / 72 MB dense**. A coords-based
spatial `sigma` fit with a few thousand sites therefore pays ~10 s per accessor
call for a check whose answer never changes within a fit. Not a correctness
defect; a usability one (D-139).

**The clamp question (`d61f65183`), and it is the sharper of the two.** The
kernel does not clamp the intercept — it clamps the **assembled** predictor:
`log_sigma = X_sigma * beta_sigma`, then every random-effect contribution is
added (`src/drmTMB.cpp:811, 994, 1033`), and only then
`drm_softclamp_log_sigma(log_sigma, ...)` is applied to the whole vector
(`src/drmTMB.cpp:2437`) before `sigma = exp(log_sigma)`. So the quantity the
likelihood integrates is `E[exp(2*c(b0 + u))]` with `c` the soft clamp. After
`d61f65183`, `drm_constant_residual_sigma()` (`R/methods.R:4742-4746`) computes
`exp(2*c(b0) + 2*sum omega_k^2)` — the second moment of a lognormal centred at
`c(b0)` and **not** clamped. That is the moment of no distribution the kernel
uses. Three regimes, all measured on a 40x12 fixture with
`bf(y ~ 1 + (1|g), sigma ~ 1 + (1|g))` against a 2e6-draw Monte Carlo of the
kernel's own `E[exp(2*c(b0 + omega*z))]`:

| band, margin | clamp | `residual_sd` | kernel-consistent | ratio | pre-`d61f65183` |
|---|---|---|---|---|---|
| `c(-12,12)`, 3 | inactive | 1.8533 | 1.8517 | **1.001** | 1.8533 |
| `c(-1.2,-0.6)`, 3 | active, partly bent | 2.5128 | 1.7142 | **1.466** | 2.5340 |
| `c(-1.2,-0.6)`, 0.5 | saturated | 0.9080 | 0.9048 | **1.003** | 343.14 |
| `c(-1.2,-0.6)`, 0.2 | saturated | 0.6912 | 0.6703 | **1.031** | 8.10 |

Read three things off this. (i) *"a no-op when the clamp is inactive"* is exactly
true (1.001). (ii) In the **saturated** regime the commit is a large, real repair
(343 -> 0.908 against a truth of 0.905): `c(b0)` is bounded, so the wild
over-statement disappears. (iii) In the **partly bent** regime — the one a real
clamp-active fit actually lands in — the commit moves the number by 1% of the
error and leaves a **47% over-statement of the residual variance standing**,
because the clamp's contraction of the random part is exactly what the formula
omits. This is not cosmetic: on that fit `summary()$derived` reports
`residual_variance = 6.314` against a kernel-consistent `2.939`, and
`repeatability()` returns **0.0592 (se 0.0355)** where the kernel-consistent
value is **0.1208** — the reported point estimate is 2.0x low and the true value
sits 1.7 SE outside it, with no flag on the row. The sibling repair
`e86359fe2` refuses exactly this situation one module over
(`conf.status = "clamp_limited"`, `NA` interval); `summary()$derived` and the
accessors report a bare number for the same reason. `drmTMB()` and `check_drm()`
do warn that the clamp is active and that estimates near it are unreliable — that
is real mitigation and should be credited — but it is a fit-level warning, not a
statement about this row.

Exactly: under a soft clamp the marginal is `E[exp(2*c(b0+u))]`, which is bounded
by `exp(2*(hi+m))` however large `omega` is, whereas the code's
`exp(2*c(b0) + 2*sum omega^2)` is unbounded in `omega`; the two agree only where
`c` is the identity over essentially all the mass of `b0 + u`. **The code should
refuse on a clamp-active fit** (`NA` with a named reason) rather than ship a
hybrid, which is also what makes it consistent with `e86359fe2`.

#### Negative control

**Legitimate this time, and better than its predecessor — but blind on the
commit's headline claim.** `<scratchpad>/s2b-repair-red.txt` shows five failures
against the pre-fix tree and all five are substantive, not arity artefacts:
(1) `expect_message(print(summary(fit)), "random slope on sigma")` fails —
item 5; (2-4) fixture C's user-facing arm fails with `nrow(derived) = 0`,
`residual_variance = NA`, `estimate = NA` against expected `0.3`/`0.7` — item 2;
(5) `repeatability(fit)` aborts at `R/heritability.R:313`. The predecessor's two
complaints are both answered: the run reaches fixture C (it did not before), and
nothing here fails on a changed signature.

**Green re-run, mine, this worktree:**
`testthat::test_local(filter = "dinnage-audit-s2")` -> `FAIL 0`, `PASS 35`,
`WARN 1` (the optimizer-preset escalation on the phylo fixture, not an
assertion). Fixture C's `skip_if(elapsed > 60, ...)` is gone (item 3 met) and the
fixture now asserts at `summary()$derived`, `repeatability()` and `icc()`.

**The gap: `drm_structured_sigma_unit_diagonal()` has no test anywhere.**
`grep -rln "drm_structured_sigma_unit_diagonal\|structured_sigma_diagonal_not_checked\|structured_sigma_non_unit_diagonal" tests/ R/` returns `R/methods.R` and
nothing else. The commit's *leading* claim — that
`sigma ~ spatial(1 | site, coords = )` now gets the closed form — has neither a
red nor a green assertion; I had to fit it myself to confirm it. That is also
why the `phylo()`-on-`sigma`-alone regression shipped: no fixture exercises
`q == 1` phylo on `sigma`, and no fixture exercises a genuinely non-unit matrix
to prove the refusal still fires when it should.

#### Contract

**`man/summary.drmTMB.Rd` is regenerated and in sync** with the roxygen block
(`R/methods.R:4184-4197` vs `man/summary.drmTMB.Rd:88-96`, same text), and it
says what item 4 asked: `residual_sd` is `sqrt(residual_variance)` =
`sqrt(E[sigma^2]) = exp(b0 + sum omega_k^2)`, the `sigma` parameter row is the
conditional/median `exp(b0)`, they coincide only when `sigma` carries no random
effect, and both are `scale = "response"` because they are two quantities rather
than two scales. Item 4 met. `man/predict.drmTMB.Rd` /
`man/sigma.drmTMB.Rd` dropping the `\link` to an internal function is correct
(the R CMD check complaint is real; the function is not exported).

**NEWS item 6 was applied and is honest.** `NEWS.md:83-88` now separates the
estimation claim from the inference claim in as many words — *"That change
corrects WHICH quantity the interval brackets; it does not make the bracket
nominal"* — with the measured 0.910 / 0.928 over 500 replicates each and the
credit that the shortfall predates the change. This is the wording I asked for.

**Two sentences in that same bullet are now falsified by the regression.**
`NEWS.md:79-80`: *"including a phylogenetic random intercept on `sigma` under
the default unit-diagonal correlation"* — true only when `phylo()` is **also** on
`mu`; measured false for `phylo()` on `sigma` alone. And `NEWS.md:89-91`:
*"Random slopes on `sigma`, or a structured effect whose correlation diagonal is
not one, give `NA` with a message naming why"* — the `phylo()`-on-`sigma`-alone
fit has a diagonal that **is** one and gets the `NA`. The man page's
*"without a verified unit-diagonal correlation"* wording survives the regression
intact, but the user-visible message text does not: it now asserts a measurement
that was not made on the right basis.

**Nothing anywhere records the clamp caveat** (the predecessor's OPTIONAL item
8). It was optional when the number was transparently the unclamped moment; it is
not optional now that `d61f65183` advertises scale consistency with `sigma()`
while leaving a measured 47% residual-variance over-statement and a 2.0x
distortion of `repeatability()` on a partly-bent fit.

**Item 5 is met.** The new branch in `print.summary.drmTMB()`
(`R/methods.R:4455-4465`) emits the reason via `cli::cli_text()` when the derived
table is empty and the attribute is set, and the fixture asserts it with
`expect_message`. Confirmed green.

#### Scope

- **Still unmet from the predecessor's list:** item 7 (a `(1 | p | id)` fixture —
  `grep "| p |" tests/testthat/test-dinnage-audit-s2.R` is empty; the `rho`
  cancellation remains load-bearing and untested, though I re-verified it
  numerically above via the zero `eta_cor_phylo` gradient), item 8 (clamp caveat,
  now upgraded — see REQUIRED 3), item 9 (the two unreachable-today S2 routes are
  still unrecorded), item 10 (`docs/design/parity-matrix.md:90` still reads
  *"delta-method Wald interval with a small-N sanity check, no coverage study"*,
  which is no longer true and does not mention the moved estimand).
- **Blast radius of the regression is bounded to the `sigma` endpoint.** The
  diagonal check fires only when `which(endpoint_dpars == "sigma")` is non-empty
  (`R/methods.R:4786-4788`), so `phylo()`-on-`mu`-only fits — the main
  heritability path — are untouched. Verified by reading the branch, not assumed.
- **`spatial_mu_residual_scale()` (`R/check.R:3418-3430`) still reports a third
  residual scale** (`mean(sigma(object))`). Unchanged by these commits and still
  undocumented; a note, not a finding.
- UNVERIFIED: `phylo_interaction()` and `animal()`/`relmat()` on `sigma` with
  `q == 1`. `relmat()`'s user-supplied `Q` is indexed by the modelled unit and
  should be fine; `phylo_interaction()`'s Kronecker of two augmented precisions
  looks like the same latent-basis trap as `phylo()`, but I did not fit one.
- UNVERIFIED: I did not run DRM.jl; the bridge fence at
  `docs/design/parity-matrix.md:90` still stands on its own measured receipt.

#### Concrete change

1. **REQUIRED — measure the diagonal on the modelled-unit rows, not the whole
   augmented basis.** `phylo()` on `sigma` alone is `q == 1` with a 38x38
   tips-plus-nodes precision, so `drm_structured_sigma_unit_diagonal()`
   (`R/methods.R:4849-4881`) measures `[0.554, 1]` and returns `FALSE`, and the
   user is told the correlation matrix *"was measured and does not have a unit
   diagonal"* when `diag(solve(Q))[1:20]` is exactly 1 on every tip. Index
   `diag(solve(Q))` by `precision$tip_node_index` (or `species_node_index` when a
   species factor is supplied) — both are already on the object. Done for the
   right endpoint's rows this also retires the `q > 1L` trusted-by-construction
   branch, so the `type == "phylo"` guess disappears from the code entirely.
   Until this lands, the parent commit's behaviour was strictly better for this
   configuration.
2. **REQUIRED — give the new helper a test, in all three directions.** It has
   none. (a) `sigma ~ spatial(1 | site, coords = )` accepts and yields a derived
   row plus a finite `repeatability()` — this is the commit's headline claim and
   is currently unasserted. (b) `sigma ~ 1 + phylo(1 | species, tree = )` with
   **no** `phylo()` on `mu` accepts and returns the closed form — the arm that
   regressed. (c) A structured `sigma` matrix whose diagonal genuinely is not one
   still refuses with `structured_sigma_non_unit_diagonal`, so the repair of (a)
   and (b) cannot be mistaken for switching the guard off.
3. **REQUIRED — refuse, or flag, the marginal on a clamp-active fit.** The kernel
   clamps the assembled predictor (`src/drmTMB.cpp:2437`, after the random-effect
   contributions at `994`/`1033`), so the integrated quantity is
   `E[exp(2*c(b0+u))]`, bounded by `exp(2*(hi+m))`; the shipped
   `exp(2*c(b0) + 2*sum omega^2)` (`R/methods.R:4742-4746`) is unbounded in
   `omega` and is the moment of no distribution the likelihood uses. Measured on a
   converged, partly-bent fit: `residual_variance` 6.314 vs a kernel-consistent
   2.939 (1.47x on the SD), and `repeatability()` 0.0592 (se 0.0355) against a
   kernel-consistent 0.1208 — 2.0x low, 1.7 SE outside, unflagged. Return
   `NA_real_` with a named reason (e.g. `clamp_active_marginal_undefined`) when
   `drm_softclamp_log_sd()` bends any fitted row, matching `e86359fe2`'s
   `conf.status = "clamp_limited"` treatment of the same defect. Keep
   `d61f65183` either way: it is a genuine repair in the saturated regime
   (343 -> 0.908 against 0.905) and an exact no-op when the clamp is inactive
   (ratio 1.001).
4. **REQUIRED — bring `NEWS.md` back in line with what the code does.**
   `NEWS.md:79-80` claims support for *"a phylogenetic random intercept on
   `sigma`"* (true only alongside `phylo()` on `mu`) and `NEWS.md:89-91` claims
   the `NA` is reserved for *"a structured effect whose correlation diagonal is
   not one"* (it now also catches one whose diagonal **is** one). Fix the code per
   REQUIRED 1 and both sentences become true again; if REQUIRED 1 is deferred,
   the sentences must be narrowed and the deferral dated.
5. OPTIONAL — report an ill-conditioned inversion as *"not checked"*, not *"not
   unit"*. `tryCatch` catches a hard failure, but a near-singular precision
   returns finite garbage whose diagonal drifts off 1 and is then reported as a
   measurement. An `rcond`/condition guard routes it to the honest branch.
6. OPTIONAL — guard or cache the inversion. It is dense and recomputed on every
   `summary()`/`heritability()`/`icc()`/`repeatability()` call (two uncached
   callers: `R/heritability.R:296`, `R/methods.R:4612`). Measured: 0.05 s at
   n = 500, 1.19 s at n = 1500, **9.63 s and 72 MB at n = 3000**. Cache the
   verdict on the fit, or skip the check above a size threshold and report *"not
   checked"*.
7. OPTIONAL — the predecessor's items 7, 9 and 10 are all still open: the
   `(1 | p | id)` fixture, the two unreachable-today S2 routes as guarded
   assumptions, and `docs/design/parity-matrix.md:90` (*"no coverage study"* is no
   longer true and the estimand moved).

---

## Part B — documents (274, 275, S3 help page)

### B1 — `docs/design/274-bootstrap-interval-bias.md` (S6, #1315)

**VERDICT: ACCEPT-WITH-CHANGES — the recommendation (A now, B/C opt-in, default
unchanged pending §7) is sound and I endorse it, but §4 claims to explain the
2.35x when its own algebra predicts 1.0x for the quantity #1315 defines, and
§7's refit budget silently drops the three-seed multiplier, understating the run
by ~3x.**

#### Mechanism

I re-derived §4 independently.

*The parametric-bootstrap step is right.* With bias `b = E[theta_hat] - theta`,
refitting data simulated at `theta_hat` gives `E*[theta_hat*] = theta_hat + b(theta_hat)`.
For this particular target the step is not just approximate but **exact**: the ML
bias of `log sigma_hat` in a Gaussian linear model is
`0.5*(log 2 + digamma(k/2) - log n)` with `k = n - p`, which is **free of the true
`log sigma`**. So `b(theta_hat) = b` identically, and the bootstrap draws sit at
`theta_hat + b`, i.e. `theta + 2b` in expectation over the outer sampling.

*The basic-interval cancellation is right.* Midpoint of `2*theta_hat - q*` is
`2*theta_hat - (theta_hat + b) = theta_hat - b = theta`. Correct, and it is
correct **precisely because** the bootstrap midpoint is `theta_hat + b` and not
`theta_hat + 2b`. §4's two halves are internally consistent with each other.

*They are not consistent with §2.* §2 states, correctly transcribing #1315, that
the measured quantity is "bootstrap **midpoint offset from the ML estimate** …
-0.05479 against an ML bias of -0.02330". Under the derivation just given, that
quantity equals **`b` (ratio 1.00)**, not `2b`. §4 then writes "*That is the
mechanism behind the 2.35x ratio: with b = -0.02330, 2b = -0.04660*" — matching
an offset-from-**truth** prediction to an offset-from-**estimate** measurement.
The two cannot both stand. Either
(i) #1315's label is loose and Russell's -0.05479 is `midpoint - theta` (my
leading hypothesis: `2b = -0.0466` vs `-0.0548` is a fair match, and §8's own
wording — "*the interval's offset from the truth relative to the point
estimate's own bias*" — is the correct framing), or
(ii) the label is right, in which case **the note's mechanism does not explain
the finding at all** and something package-specific is adding a second dose.

This is not pedantry, because **the adequacy of the proposed fix depends on
which it is.** If the offset from `theta_hat` is `b`, the basic interval (option
B) centres on the truth. If it is genuinely `2b`, the basic interval lands at
`theta - b` — over-correcting to the other side by the same amount. Option B
cannot be validated without resolving this.

Two smaller mechanism points:

- §4's flagged speculation ("*the residual gap … is plausibly the convex `exp()`
  back-transform*") is **sign-wrong** under the natural reading. The interval is
  taken on the log scale and back-transformed (`bootstrap_percentile_interval()`,
  `R/profile.R:2978-2993`); by Jensen, `(exp(q_lo)+exp(q_hi))/2 >= exp((q_lo+q_hi)/2)`,
  so convexity moves the back-transformed midpoint **up**, shrinking a negative
  offset. It cannot enlarge `2b` to `2.35b`. Delete the speculation or replace it.
- §4 never mentions a mechanism that **is** present and does push in the observed
  direction: the bootstrap distribution of `log sigma_hat*` is left-skewed, so the
  symmetric-percentile **midpoint sits below the median**, adding roughly -0.005
  at `n = 100, k ~ 96` on top of `b`. Worth one sentence; it is a second reason
  percentile midpoints are not the bootstrap mean, and it does not vanish as the
  bias does.

Monte Carlo resolution, which the note does not report: with `sd(log sigma_hat)
~ 1/sqrt(2k) ~ 0.072` and 250 replicates, the MCSE on the denominator `b` is
~0.0045, so **the 2.35 ratio carries an MCSE of ~0.46** (95% interval roughly
[1.45, 3.25]). It excludes 1.0 but is entirely compatible with 2.0 — which is
evidence *for* reading (i), and which the note should state rather than treating
2.35 as a fixed target to be explained.

#### Evidence

All numbers in §2 match `gh issue view 1315` verbatim (-0.05479, -0.02330, 2.35x,
0.852/0.896/0.912, 14.5-14.8% / 0.0-1.0%, 0.928/0.895 vs 0.952/0.900). They are
**faithful transcriptions**, not independent verifications; Russell's study is
outside this repository and is **UNVERIFIED** here. §2 says so implicitly by
citation but should say so in words.

§3 citations, re-grepped one by one in this worktree:

| claim | verdict |
|---|---|
| `confint.drmTMB()` at `R/profile.R:404` | correct |
| `method` at line 408, default `"wald"` | correct |
| bootstrap branch at line 489 | correct |
| `drm_bootstrap_confint()` called at line 508 | correct |
| `drm_bootstrap_confint()` defined at line 2608, formals 2608-2619 | correct |
| `stats::simulate(...)` at **lines 2646-2651** | **WRONG — it is 2649-2654** |
| `probs <- c(...)` at **line 2679** | **WRONG — it is 2684** |
| `bootstrap_percentile_interval()` at 2978, `type = 8` | correct |
| `bootstrap_uses_link_percentiles()` at 3003 | correct |
| `bias_correct` at line 423, `bootstrap_re_form` at 424 | correct |
| `bias_correct` absent from the bootstrap path | correct — the `return(drm_bootstrap_confint(...))` call at 508-519 passes no such argument |
| `conf.status` variants at 2760-2765 | correct (assignment at 2765) |
| `man/confint.drmTMB.Rd:188-189` | correct |

Two off-by-a-few line citations out of thirteen. Minor, but #1315's own text
carries the same `2679` — so the note inherited the issue's number instead of
re-grepping it, which is the habit worth correcting rather than the digits.

**Timing number: NOT INDEPENDENTLY REPRODUCED.** I attempted a re-measurement in
this worktree and abandoned it: the M1 lane is concurrently rebuilding the
compiled object here (`scratchpad/drmTMB.cpp.patched`, `m1-compile.log` in
flight), so any timing taken now measures a different `.so`. Recorded as
UNVERIFIED rather than agreed. Two independent reasons to distrust it anyway:
it is a **single unreplicated run**, and an `R = 10` measurement conflates fixed
overhead (`simulate()`, setup, `sdreport`) with the marginal per-refit cost, so
`1.9154/10 = 0.192 s/refit` is an **upper bound** — the note should say so and
should report the estimate as conservative.

#### Contract

A user reading §8's draft would conclude: bootstrap intervals are percentile
intervals; on small-`n`-biased scale targets they are offset from the truth by
about twice the point estimate's own bias; prefer Wald or profile there. That is
an honest and useful contract and I would ship it. §8's wording is, notably, the
*correct* framing of the mechanism — it is §2 and §4 that need to be brought into
line with §8, not the reverse.

What a user would **not** learn, and should: that `bias_correct` is silently
inert under `method = "bootstrap"` (`R/profile.R:508-519`). That is a live
documentation defect the note discovered (§3) and then did not put into §8.

#### Negative-control check

- Does the timing follow from 0.19 s/refit? `0.1915*199 = 38.1 s/replicate`;
  `*250 = 9528 s = 2.65 h`. Arithmetic ✓.
- **Does the refit budget follow from the DGP?** No. §7 scenario 1 specifies
  "250 replicates, R = 199, **three seeds**", then §7's refit count is
  `250 x 199 = 49,750` for scenarios 1+2 — **the seed multiplier is gone**. Three
  seeds x 250 replicates is 149,250 refits for scenario 1 alone; total becomes
  ~199,000 refits and **~24-27 hours serial, not 8-9**. Either the 250 replicates
  are meant to be split across the three seeds (then say so) or the estimate is
  3x low. Under D-139 an estimate is the deliverable, so this must be fixed
  before the ask goes to Shinichi.
- MCSE: the note states "~0.014 at p=0.9 with 250 reps". Re-derived:
  `sqrt(0.9*0.1/250) = 0.019`. 0.014 is the value at **p = 0.95**
  (`sqrt(0.95*0.05/250) = 0.0138`). At the observed 0.852 it is 0.0225.
- Scenario 3 scaling: `2 x 2.65 = 5.3 h`, not the stated 5.5. Trivial, but it is
  the same habit as the seed slip.

#### Is §7 a runnable ADEMP spec?

Structurally yes — estimands, methods, DGPs, performance measures, compute target,
and a pre-run are all present, and the "three interval methods add no refits"
observation is correct and is the spec's best idea. Three gaps block it from being
runnable as written:

1. It measures only `(midpoint - theta_hat)/(E[theta_hat] - theta)`. That ratio
   **cannot discriminate** between the two readings above. It must also record
   `midpoint - theta` (offset from truth).
2. No pre-specified rule for failed refits. The pilot itself lost 1 of 10, which
   §7 waves off as "sampling noise" — a **speculation**, and a 10% refit-failure
   rate is not a nuisance, it is a selection mechanism acting on the very
   quantiles the interval is made of. Pre-specify: drop, or abort the replicate,
   and report the rate per scenario.
3. 250 replicates gives an MCSE of ~0.46 on the headline ratio (above). Either
   raise the count for the ratio estimand or report the ratio with its MCSE and
   stop treating 2.35 as a point to be matched.

#### Concrete change

1. **(REQUIRED)** Reconcile §2 and §4. State which quantity `-0.05479` is —
   offset from `theta_hat` or from `theta` — mark the reading as AGENT-INFERRED
   if it cannot be settled from #1315, and correct "*that is the mechanism behind
   the 2.35x ratio*" so the note does not claim a match it has not got. Adopt §8's
   framing ("offset from the truth relative to the point estimate's own bias") in
   §4.
2. **(REQUIRED)** Fix §7's refit budget and time estimate: either state that the
   250 replicates are split across three seeds, or multiply through (~199,000
   refits, ~24-27 h serial). D-139 requires the estimate to be the honest one.
3. **(REQUIRED)** Add `midpoint - theta` to §7's estimands, and a pre-specified
   failed-refit rule with the rate reported per scenario.
4. **(REQUIRED)** Correct the MCSE sentence: 0.019 at p = 0.9, 0.0138 at p = 0.95,
   0.0225 at the observed 0.852.
5. **(REQUIRED)** Fix the two line citations (`2649-2654`, `2684`) and mark
   Russell's numbers as transcribed-from-#1315, UNVERIFIED in this repository.
6. **(OPTIONAL)** Delete or replace the `exp()`-convexity speculation (sign-wrong)
   and add the left-skew / midpoint-vs-median mechanism in its place.
7. **(OPTIONAL)** Label the 0.192 s/refit as an unreplicated upper bound that does
   not separate fixed overhead, and record that re-measurement in this worktree is
   blocked while the M1 lane rebuilds the `.so`.
8. **(OPTIONAL)** Add the silently-inert `bias_correct` to §8's help-page draft.

---

### B2 — `docs/design/275-repeatability-scale-and-residual-variance.md` (S2/#1301, D-252)

**VERDICT: ACCEPT-WITH-CHANGES — §3's evidence is exact and §4's lognormal
derivation is right, but §5 asserts that both call sites "inherit the corrected
value … with no further change" and that is false for `drm_variance_ratio()`,
which never uses the returned value in its arithmetic.**

#### Mechanism

*§4's moment is correct.* For `u ~ N(0, omega^2)`, `E[exp(2u)] = exp(2*omega^2)`,
so `E[sigma(u)^2] = exp(2*b0 + 2*omega^2)` and `sqrt(E[sigma^2]) = exp(b0 + omega^2)`,
exceeding the median `exp(b0)` by `exp(omega^2)`. Re-derived; the note's statement
of the SD-scale and variance-scale inflation factors is right. The crossed-effects
generalisation `exp(b0 + sum_k omega_k^2)` is also right, since independent `u_k`
give `E[exp(2*sum u_k)] = exp(2*sum omega_k^2)`.

*§4's magnitudes are right; §4's plausibility check is not.* Re-derived:
`exp(2*0.8^2) - 1 = +259.66%`, `exp(2*0.4^2) - 1 = +37.71%` ✓, and `60.6/8.51 = 7.121` ✓.
But the note writes "*the pure-variance bias ratio (exp(1.28)/exp(0.32) = 9.53)*".
`exp(1.28)/exp(0.32) = 2.612`, and the quantity the note evidently means — the
ratio of the two variance-scale **excesses** — is `(e^1.28 - 1)/(e^0.32 - 1) = **6.885**`.
The 5.17 figure is right under that reading (`(e^0.64-1)/(e^0.16-1) = 5.167`), so
the arithmetic is inconsistent within one sentence. **Correcting it falsifies the
note's own conclusion**: 7.12 does **not** sit between 5.17 and 6.885, it sits just
above both.

*And the correction makes the check far stronger than the note realises.* Write
the ratio-level error as `r_wrong/r_true - 1 = (k-1)*s2/(V + s2)` with
`k = exp(2*omega^2)`, `s2` the true residual variance, `V` the RE variance. The
factor `s2/(V+s2)` is common to both `omega` settings, so it **cancels in the
ratio of ratios** — the prediction is *exactly* `6.885`, **independent of the
unknown `total_re_var`**, and Russell's 7.121 matches it to **3.4%**. Better still,
inverting either figure recovers the missing ingredient:
`0.606/(e^1.28-1) = 0.2334` and `0.0851/(e^0.32-1) = 0.2257` — two independent
estimates of `s2/(V+s2)` agreeing to 3%, implying `V ~ 3.3 * s2`.

So §4's closing verdict ("*the precise 60.6%/8.51% figures cannot be independently
re-derived from the issue text alone, since Russell's total_re_var is not given*")
is **too pessimistic and should be replaced**. They can be, and they check out. The
`AGENT-INFERRED plausibility only` caveat can be upgraded to a quantitative
confirmation — which is a better answer to Russell than the one currently written.

#### Evidence

Every file:line in §3 and §4 re-grepped against `HEAD` (`46b9b19ec`), where the
note was written. **All correct**, including the ones easiest to get wrong:

- `drm_derived_summary_rows()` at `R/methods.R:4553`, Gaussian gate at 4554,
  `sigma <- drm_constant_residual_sigma(object)` at 4557, `residual_variance <- sigma^2`
  at 4577, `denominator <- total_re_var + residual_variance` at 4591 — all exact.
- `drm_constant_residual_sigma()` at `R/methods.R:4650-4668`, returning
  `exp(unname(beta[[1L]]))`; its three guards are exactly the three the note names,
  and none of them detects a random effect on `sigma` — confirmed by reading the
  function in full.
- `drm_dpar_link(object, "sigma") == "log"` check at 4653 ✓;
  `has_sigma_random_effects()` at `R/methods.R:6182-6190` ✓, and it does read
  precisely the two sources §5 proposes to reuse.
- `R/heritability.R`: Gaussian abort at 279-280 ✓, `drm_constant_residual_sigma()`
  call at 285 ✓, `denom_positions` construction within 315-320 ✓ (assignment at
  318), `drm_variance_ratio_reject_random_slopes()` at 386 ✓, roxygen at 9-11 and
  27-31 ✓, rename note at 25 ✓, `man/heritability.Rd:98` ✓,
  `man/summary.drmTMB.Rd:60-70` ✓.
- Exactly two call sites of `drm_constant_residual_sigma()` in `R/` ✓.

This is the most disciplined citation set I have reviewed in this audit. One
durability caveat, not an error: the worktree has drifted **+17 lines** in
`R/methods.R` from another agent's uncommitted edit (the function now starts at
4570), so every number above will be stale once M1/M2 land. Pin the note to the
commit it cites.

One over-reading: §3(iv) says the roxygen at `R/heritability.R:25` records that
"`phylo_total_variance_share` **and `heritability()`** were both called
`phylogenetic_signal`". The text there is about the `summary()` derived **rows**
(`repeatability` and `phylogenetic_signal`), not about `heritability()`. The
substantive point — no separate phylo-signal accessor exists — holds.

#### Contract

For the `summary()$derived` reader, the note's account is right and the proposed
fix would reach them: `residual_variance <- sigma^2` at `R/methods.R:4577`
consumes the helper's return value directly.

For the `heritability()`/`icc()`/`repeatability()` reader it is **not**, and this
is the finding of the review. See the negative control.

#### Negative-control check

**(a) "No link/distribution variance is added" — SURVIVES, confirmed.** I read
`drm_derived_summary_rows()` (`R/methods.R:4553-4622`) and `drm_variance_ratio()`
(`R/heritability.R:266-348`) in full, plus `drm_variance_ratio_delta()`
(`R/heritability.R:465-495`). There is no `pi^2/3`, no `pi^2/6`, no `+1`, and no
family-specific additive term anywhere on either path. The denominators are
`total_re_var + sigma^2` and `sum(exp(2*theta[denom]))` respectively. §3(ii) is
verified.

**(b) "Both current callers inherit the corrected value … with no further change"
— DOES NOT SURVIVE.** `drm_variance_ratio()` uses the helper's return value
**only as a gate**:

```r
sigma <- drm_constant_residual_sigma(object)          # R/heritability.R:285
if (!is.finite(sigma)) { cli::cli_abort(...) }        # 286-291
...
resid_position <- which(names(object$opt$par) == "beta_sigma")   # 306
denom_positions <- c(positions[denom_idx], resid_position)       # 318
```

and `drm_variance_ratio_delta()` then computes
`exp(2*theta[focal]) / sum(exp(2*theta[denom]))` from `object$opt$par` — so the
residual enters as `exp(2*beta_sigma) = exp(2*b0)`, the **median squared**,
regardless of what the helper returned. Three consequences:

1. **The helper fix changes nothing for `heritability()`/`icc()`/`repeatability()`.**
   A fit with a random intercept on `log(sigma)` currently returns `exp(b0)`
   (finite) → gate passes → wrong ratio. After the fix it returns
   `exp(b0 + sum omega^2)` (finite) → gate passes → **the same wrong ratio**. The
   S2 defect in these accessors lives in `drm_variance_ratio_delta()`'s use of
   `resid_position`, not in the helper. §5 must say so and scope the delta path in.
2. **The `NA` branch would emit a false diagnosis.** If the helper returns
   `NA_real_` for a phylo-on-`sigma` or random-slope-on-`sigma` fit,
   `drm_variance_ratio()` aborts at `R/heritability.R:287-290` with "*This fit has
   a `sigma` predictor, a non-log link, or a known-dispersion override*" — none of
   which is true of such a fit. The message must move with the return value.
3. **On `summary()$derived` the `NA` branch reintroduces the silent refusal the
   note itself criticises.** `drm_derived_summary_rows()` responds to a non-finite
   `sigma` by returning `empty_derived_summary_parameters()`
   (`R/methods.R:4558-4560`) — the quiet omission §3(iii) flags as the weaker of
   the two refusal styles. §5's "`NA_real_` **with a message**" must therefore
   specify *where* the message is raised, because the current call site swallows it.
4. **The SE, not just the estimate.** The corrected residual variance
   `exp(2*b0 + 2*sum omega_k^2)` is a function of the `omega_k`, so the delta-method
   gradient in `drm_variance_ratio_delta()` must extend over the `log_sd_sigma`
   positions and `cov_fixed` must be indexed accordingly. A fix that corrects the
   point estimate and leaves the SE built from the `mu` SDs plus `beta_sigma` alone
   would under-state uncertainty in exactly the regime the fix exists for. This is
   an inference claim, and §5 currently does not touch it.

#### Concrete change

1. **(REQUIRED)** Replace §5's "*Both current callers … inherit the corrected
   value or the refusal with no further change*" with the true statement:
   `drm_derived_summary_rows()` inherits it; `drm_variance_ratio()` uses the
   helper only as a gate and recomputes the residual from `beta_sigma` at
   `R/heritability.R:306/318` via `drm_variance_ratio_delta()`
   (`R/heritability.R:465-495`), so the accessors need their **own** change.
2. **(REQUIRED)** Extend §5 to name the delta path explicitly: the residual entry
   of `denom_positions`, and the fact that a corrected residual depends on the
   `omega_k`, so **both** the estimate and the delta-method SE must change.
   Without this the next slice ships a half-fix and the note says it is whole.
3. **(REQUIRED)** Specify where the refusal message is raised. `drm_variance_ratio()`'s
   existing abort text at `R/heritability.R:287-290` becomes false under the `NA`
   branch and must be updated; `drm_derived_summary_rows()` currently converts a
   non-finite `sigma` into a **silent** empty frame (`R/methods.R:4558-4560`),
   which §3(iii) already names as the weaker refusal.
4. **(REQUIRED)** Fix §4's `9.53` to `6.885`, and replace the "sits between
   5.17 and 9.53" sentence — the corrected bracket does not contain 7.12.
5. **(REQUIRED)** Replace §4's "cannot be independently re-derived … since
   Russell's `total_re_var` is not given" with the ratio-of-ratios argument: the
   common factor `s2/(V+s2)` cancels, the prediction is exactly 6.885, Russell's
   7.121 matches to 3.4%, and inverting either figure gives `s2/(V+s2) ~ 0.226-0.233`
   (i.e. `V ~ 3.3*s2`) from two independent routes agreeing to 3%. The mechanism is
   **quantitatively confirmed**, not merely plausible — say so.
6. **(OPTIONAL)** Pin the §3/§4 line numbers to the commit (`46b9b19ec`);
   `R/methods.R` has already drifted +17 lines in this worktree.
7. **(OPTIONAL)** Correct §3(iv)'s reading of `R/heritability.R:25` (the rename
   note concerns the `summary()` derived rows, not `heritability()`).
8. **(OPTIONAL)** §7's drafted sentence says "`drm_constant_residual_sigma()`
   requires a constant `sigma ~ 1` fit" — it does not; it requires a single fixed
   `(Intercept)` coefficient, which is exactly why a random effect slips past it.
   Say the true thing.

---

### B3 — roxygen diff of `drm_phylo_penalty()` (`R/penalty.R`, S3/#1312)

**VERDICT: ACCEPT-WITH-CHANGES — the new prose is correct on every point the
locked decision required, and I verified the algebra and the 0.334 myself; what
is missing is the regenerated `.Rd` and one neighbouring sentence that still
advertises the behaviour the new paragraph has just retracted.**

#### Mechanism

Re-derived from source, not from the note.

The compiled penalty is `pen_k = lam*sd_k - log_sd_phylo(k) - log(lam)` with
`sd_k = exp(log_sd_phylo(k))` — `src/drmTMB.cpp:105`, inside
`drm_phylo_penalty_value()` whose header comment at `src/drmTMB.cpp:87-91` names it
"*an exponential prior on each phylogenetic SD = exp(log_sd_phylo) with the
log-Jacobian*". `docs/design/172-phylo-penalized-map.md:44-53` states the identical
formula under "Mathematical contract" and identifies the `-log_sd_phylo(k)` term as
the `|d sd / d log_sd|` Jacobian. The roxygen's rendering — "`rate * sd - log(sd) - log(rate)`"
— is **character-for-character the compiled expression**.

Calibration: if `sd ~ Exp(lam)` then `P(sd > sd_u) = exp(-lam*sd_u) = exp(log(sd_alpha)) = sd_alpha`.
The new "holds **exactly** for this prior" is true.

Mode: minimise `f(t) = lam*e^t - t - log(lam)` over `t = log(sd)`.
`f'(t) = lam*e^t - 1 = 0` gives `e^t = 1/lam`, i.e. **`sd = 1/rate`**, and
`f(t) -> +Inf` as `t -> -Inf`, so the mode is interior and never zero. Verified.

Numbers: `rate = -log(0.05)/1 = 2.99573` (the page says 2.996 ✓);
`1/rate = 0.33380` (the page says 0.334 ✓). Both re-derived from the function's own
defaults `sd_u = 1, sd_alpha = 0.05` at `R/penalty.R:71`.

#### Evidence — checked against the four things the page had to do

| requirement | verdict |
|---|---|
| does **not** describe the object as `Gamma(2, rate)` | **PASS** — the string "Gamma" appears nowhere in the diff or the file |
| **does** state the mode at `1/rate` | **PASS** — `R/penalty.R:25-27` |
| the 0.334 figure is right | **PASS** — re-derived above |
| carries the "no null test on a MAP fit" sentence | **PASS** — `R/penalty.R:28-32`, and it goes further than yesterday's item 2 asked, giving the *reason* ("the estimator cannot report zero regardless of the data") |
| keeps Simpson as the prior's source | **PASS** — `R/penalty.R:9-10` and the `@references` block |
| keeps Chung | present in `@references` but now **unmotivated in the body** — see change 3 |

#### Contract

Under the old page a user believed: this penalty shrinks a weakly identified
phylogenetic SD toward zero, and `P(sd > sd_u) = sd_alpha`. The second half was
true; the first was not, and it is what produced Russell's finding. Under the new
page they learn the first half is false and why, and are told not to build a null
test on it. That is a **strict improvement in honesty with no numeric change**, and
it retracts nothing that was true. This is the right resolution of S3 and I endorse
it.

#### Negative control

`man/drm_phylo_penalty.Rd` is **untouched** (timestamp 2026-09-13; its `\details{}`
at lines 35-41 still carries only the old two paragraphs). The diff edits `R/` only.
Until `devtools::document()` runs, `?drm_phylo_penalty` shows the **old, now
known-misleading** text — i.e. the fix is invisible to every user who reads the help
page rather than the source. This is the one way the change could be called "landed"
and not be.

Second: `grep -rn "no phylogenetic variance" R/ man/` returns exactly two live
hits — `R/penalty.R:13` and `man/drm_phylo_penalty.Rd:37`, both the *retained*
first paragraph. That paragraph still tells the reader the penalty "regularises …
toward the simpler 'no phylogenetic variance' model", fourteen lines before the new
paragraph explains the estimate can never get there. Not a contradiction in the
strict sense ("toward" is not "to"), but it is the exact sentence that set Russell's
expectation, and leaving it unqualified means a skimmer's belief is unchanged.

#### Concrete change

1. **(REQUIRED)** Run `devtools::document()` and commit the regenerated
   `man/drm_phylo_penalty.Rd` in the same commit. Until then `?drm_phylo_penalty`
   still serves the old text and the fix does not exist for users.
2. **(REQUIRED)** Qualify the retained sentence at `R/penalty.R:11-13`: the prior
   places mass near the base model, but the **reported point estimate** does not
   shrink to it — with a cross-reference to the new paragraph. One clause is enough.
3. **(OPTIONAL)** Give Chung et al. (2013) its one-line reason in the body, per
   yesterday's §1 item 1 ("*keep Chung as the reference for why an off-zero,
   non-degenerate estimator is a defensible thing to want*"). As it stands the
   citation sits in `@references` with nothing pointing at it, which invites the
   next reader to re-derive the `Gamma(2)` misreading that started S3.
4. **(OPTIONAL)** "an exponential prior on the SD scale **with mass at zero**"
   (`R/penalty.R:10`) is PC-prior shorthand for "mass at the base model"; the
   density at zero is `lam`, finite and non-atomic. Since the whole page now turns
   on what does and does not happen at zero, "with its mode at zero" or "with
   substantial mass near zero" is the safer phrasing.
5. **(OPTIONAL)** Tell the user what to do instead, not only what not to do: compare
   against an unpenalised fit, or report the penalised SD as a regularised estimate
   rather than a test statistic. The page currently ends on a prohibition.

---

### Ruling on 275 §5

**RULING: CONCUR — on scale-independence, which is the sentence I was asked to
rule on and which is correct; but the paragraph it sits in must not ship
unamended, and the fix must not "proceed now" in the form §5 specifies.**

*Why I concur on the sentence.* The claim is that the S2 fix is orthogonal to the
D-252 latent/liability/observed naming decision "*because both current call sites
never leave the Gaussian, identity-link case where that three-way distinction does
not arise*". I verified both gates directly: `R/methods.R:4554` returns an empty
frame unless `model_type == "gaussian"`, and `R/heritability.R:278-282` aborts
unless the same. For a Gaussian fit with an identity-link mean, `g` in Eq 3b is the
identity so `l = eta`, and the Gaussian observation mean is `eta` itself —
latent = expected = observed, and `sigma^2` plays `V_O` in Eq 4 with no addition or
subtraction. I also ran the negative control: **no** `pi^2/3`, `pi^2/6` or `+1`
appears on either path (both functions read in full), so Eq 24's `V_L` is genuinely
absent rather than hidden. And the log link on the `sigma` *parameter*
(`R/methods.R:4653`) is a positivity transform on a working parameter, not the
paper's mean-structure link — it changes which number is correct, never which scale
is reported. The fix is a **numerator/denominator ingredient change inside a
formula whose scale is already settled**. D-252 is a *naming* decision for
non-Gaussian families that these two call sites structurally cannot reach.
Waiting would be waiting on nothing.

*Why the paragraph still cannot ship, and the fix cannot proceed as written.*
Two sentences above, §5 says both callers inherit the corrected value "with no
further change". They do not. `drm_variance_ratio()` consumes
`drm_constant_residual_sigma()` **only as a finiteness gate** (`R/heritability.R:285-291`)
and then rebuilds the residual from `beta_sigma` (`R/heritability.R:306, 318`) inside
`drm_variance_ratio_delta()`, which computes
`exp(2*theta[focal]) / sum(exp(2*theta[denom]))` (`R/heritability.R:465-495`). A
contributor who implements §5 verbatim will correct `summary()$derived`, leave
`heritability()`/`icc()`/`repeatability()` reporting the identical wrong ratio
Russell measured, and — because the gate now passes on a finite corrected value —
will have removed the only thing that could ever have stopped it. The scale
question is settled; the **scope** question is not, and §5 currently states it
wrongly. Fix B2 items 1-3 and the slice is clear to proceed without D-252.

*On the phylogenetic case.* See below — the proposed `NA` for phylo-on-`sigma`
is over-conservative, and it is over-conservative in precisely the way D-252
exists to forbid: *"Never return NaN for a quantity that is defined — a refusal is
a claim, and this one was false."*

**Phylo-on-sigma answer.** A phylogenetic random effect on `log(sigma)` should get
the **same** `exp(b0 + omega^2)` form, not `NA`, whenever the phylogenetic matrix is
on drmTMB's default correlation scale: the tree correlation governs only the
*joint* law of the tip effects, and a residual variance is a *per-observation
marginal* moment, so with `u ~ N(0, omega^2 * C)` and `C_ii = 1` every tip has
`u_i ~ N(0, omega^2)` and `E[sigma_i^2] = exp(2*b0 + 2*omega^2)` identically — `C`
cancels out entirely. That unit diagonal is real and not assumed: `drm_phylo_covariance()`
divides by `info$height` when `correlation = TRUE`
(`R/phylo-utils.R:250-252`) and enforces ultrametricity for exactly that path
(`R/phylo-utils.R:226, 273` passing `require_ultrametric = correlation`;
`R/phylo-utils.R:109-113` explains that the scalar height normalisation is what
requires it), and `R/julia-bridge.R:487` records the same convention
("*drmTMB standardises via `ape::vcv(tree, corr=TRUE)` and is height-invariant*").
The **one** case that genuinely warrants `NA` is `correlation = FALSE`, the raw
branch-length Brownian path admitted for non-ultrametric trees, where the diagonal
is the root-to-tip depth and varies by tip: there `E[sigma_i^2] = exp(2*b0 + 2*omega^2*V_ii)`
differs per observation and no single scalar residual exists. So the refusal should
be conditioned on the **diagonal of the structured matrix**, not on the word
"phylogenetic". The random-slope-on-`sigma` refusal is right to keep as `NA` —
there the marginal variance depends on the covariate value, so the quantity is
design-dependent and a scalar would be a fiction (a design-averaged value is
computable and could be offered later, but only as a named, documented estimand).

---

Nothing in this review was taken on trust: every file:line was re-grepped in this
worktree, every algebraic claim re-derived, and every arithmetic figure recomputed.
Where a number could not be checked from this repository — Russell's raw draws, his
`total_re_var`, and the 1.915 s pilot timing (blocked by the concurrent M1 rebuild
of the compiled object) — it is marked UNVERIFIED rather than agreed.
