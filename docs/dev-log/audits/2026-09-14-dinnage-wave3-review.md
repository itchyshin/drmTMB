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

### S2b

*(Left for a later reviewer.)*

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
