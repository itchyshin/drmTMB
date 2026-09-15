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

*(Left empty for the code reviewer.)*

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
