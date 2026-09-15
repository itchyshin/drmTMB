# Percentile bootstrap intervals double the ML bias on biased targets (S6, #1315)

## 1. Purpose and reader

Two readers. Shinichi is deciding whether `confint(method = "bootstrap")`
needs a code change, a documentation change, or neither, and on what
timeline. A contributor implementing the eventual fix needs the mechanism,
the exact call sites, and a simulation plan they can run without re-deriving
any of this. This note gives both.

## 2. The finding

Source: Russell Dinnage's independent evaluation of drmTMB 0.7.0 at commit
`945da24f` (`rdinnager/drmTMB_eval`, `REPORT.md` §4, Appendix A row S6,
severity major), filed as issue #1315.

Design: a mildly biased `sigma` intercept (`gamma0 = -0.4` on the log-sigma
scale), `n = 100`, `R = 199` (package default), 250 replicate datasets,
Wald/profile/bootstrap intervals on the same fits, reproduced on two
further seeds. Convergence was 100%, no dropped replicates.

On the `sigma` intercept: bootstrap midpoint offset from the ML estimate is
**-0.05479** against an ML bias of **-0.02330** — a **2.35x** ratio.
Coverage: bootstrap **0.852**, Wald **0.896**, profile **0.912** (nominal
0.95). The loss is one-sided: misses **high** on 14.5-14.8% of replicates,
misses **low** on 0.0-1.0%. On the unbiased `mu:x1` coefficient there is no
gap: bootstrap 0.928/0.895 (two seeds) vs Wald 0.952/0.900. Russell's
proposed fix: "use Wald or profile on the scale intercept... or ship a
bias-corrected variant (e.g. BCa)."

All numbers in this section are **transcribed from #1315 verbatim, not
independently verified in this repository** — Russell's raw draws and his
`REPORT.md` are outside this repository, so treat them as UNVERIFIED here
even though they match the issue text exactly.

Related in-house reading, cited as background only: dr26
(`~/shinichi-brain/projects/deep-research/README.md` line 43) found REML
CIs under-cover badly at small/unbalanced N while a REHE bootstrap stayed
near nominal; dr24 (same file, line 47) found plug-in SEs under-cover at
84-89% for nominal 95% and that bootstrap adds finite-sample precision once
the estimator is handled correctly. Neither is about a percentile interval
built from a *biased* estimator, which is this issue's mechanism (§4).

## 3. Where the code stands

Verified against `R/profile.R` on this branch by direct `grep`/`sed`.

- `confint.drmTMB()` starts at `R/profile.R:404`; `method` (line 408) is
  `c("wald", "profile", "bootstrap")`, default `"wald"` — bootstrap is
  opt-in.
- The bootstrap branch, `if (identical(method, "bootstrap"))`, is at
  `R/profile.R:489` and calls `drm_bootstrap_confint()` at line 508.
- `drm_bootstrap_confint()` is defined at `R/profile.R:2608`. It draws `R`
  replicates via `stats::simulate(object, nsim = R, seed = seed, re.form =
  re_form)` (lines 2649-2654), refits each (`bootstrap_refit_one()`), and
  sets `probs <- c((1-level)/2, (1+level)/2)` at line 2684.
- The interval is `bootstrap_percentile_interval()` at line 2978:
  `stats::quantile(draws, probs, type = 8)`, taken on the log scale and
  back-transformed when `bootstrap_uses_link_percentiles()` (line 3003) is
  true (`exp`-transformed targets such as `sigma`), else taken directly.
  No basic/reflected interval, no bias correction, no acceleration exists
  in this function or its helpers.
- `bias_correct = c("location", "none", "group")` is a `confint.drmTMB()`
  argument (line 423) but is absent from `drm_bootstrap_confint()`'s
  formal argument list (lines 2608-2619) and from the bootstrap branch
  (lines 489-520) — it is consumed only by the Wald path and silently
  unused under `method = "bootstrap"`.
- `conf.status` for bootstrap is `"bootstrap"` or `"bootstrap_at_boundary"`
  (lines 2760-2765); no bias-correction status variant exists.

## 4. Mechanism: why a percentile interval re-applies the bias

Let `theta` be the truth and `theta_hat` the ML estimate, with bias
`b = E[theta_hat] - theta` (here `b = -0.02330` on the log-sigma scale).

A **parametric** bootstrap treats `theta_hat` as the truth: it simulates `R`
datasets from the fitted model and refits each with the same estimator.
Each refit's expectation is not `theta_hat` but `theta_hat + b`, because the
same biased estimator is now applied to data generated at `theta_hat`. The
bootstrap distribution is centred near `theta_hat + b = theta + 2b`, not
`theta_hat` and not `theta`.

The **percentile** interval reports quantiles of that distribution directly
— centred near `theta + 2b`, offset from the truth by `2b`. Issue #1315
labels the measured `-0.05479` as the "bootstrap midpoint offset from the
ML estimate," i.e. `midpoint - theta_hat`; under this derivation that
quantity should equal `b` (ratio 1.00 to the ML bias), not `2b`. It does
not — the measured ratio is 2.35x, not 1.00x — so the label as literally
read is inconsistent with the algebra. **AGENT-INFERRED** (this cannot be
settled from #1315's text alone, which does not resolve the
inconsistency): the quantity Russell most likely reports is
`midpoint - theta`, the interval's **offset from the truth relative to the
point estimate's own bias** (§8's framing, adopted here) — `2b = -0.04660`
is a much closer match to `-0.05479` (17.5% apart) than `b = -0.02330` is
(135% apart), and the ratio's Monte Carlo uncertainty (~0.46, §7) excludes
1.0 while remaining compatible with 2.0. Under that reading this section's
algebra is consistent with #1315 to within Monte Carlo noise; it does not,
however, establish an exact match to 2.35x, and this note no longer treats
2.35 as a fixed target to be explained.

The **basic** (reflected) interval instead reports `2*theta_hat - q*`.
Substituting `q* ~ theta_hat + b +/- margin`:

```
2*theta_hat - q* = 2*theta_hat - (theta_hat + b +/- margin)
                  = (theta + b) - b -/+ margin = theta -/+ margin
```

`b` cancels algebraically — the basic interval centres near the truth,
removing exactly the term the percentile interval doubles (Efron &
Tibshirani 1993, ch. 13). On `mu:x1`, `b ~ 0`, so both intervals coincide —
consistent with Russell's finding of no gap there.

## 5. Options, with cost and user-visible change

**(A) Document the bias-doubling; recommend Wald/profile for scale
intercepts at small n.** Zero code (draft in §8). No behaviour change.

**(B) Add an interval-shape argument, default unchanged.** Small code.
`confint.drmTMB()` has no argument named `interval` or `type`; the naming
precedent for a bootstrap-only knob is the `bootstrap_*` prefix already
used by `bootstrap_re_form` (line 424). Proposed:
`bootstrap_interval = c("percentile", "basic")`, default `"percentile"`
(no change unless a caller opts in), computed on the same link/response
scale `bootstrap_uses_link_percentiles()` already selects, reusing the
existing `R` draws — no new simulation.

**(C) Bias-corrected percentile (BC).** Cheap, uses only existing draws:
`z0 = qnorm(mean(draws < theta_hat))` shifts the percentile levels (Efron &
Tibshirani 1993, ch. 14). No acceleration term, no extra refits. Could ship
as a third `bootstrap_interval` choice alongside (B).

**(D) BCa.** Needs an acceleration constant from `n` jackknife refits per
target — 100 extra refits per target per replicate at `n = 100`, on top of
`R = 199` already paid. Out of reach for routine use here; scoped, not
implemented.

**(E) Change the default to basic or BC.** Changes finite-sample behaviour
for every existing bootstrap caller, not just Russell's case — an
estimand/contract change needing simulation evidence first (§7).

## 6. Recommendation

Ship (A) now (zero code). Ship (B) and (C) as opt-in choices in the same or
a following patch — small, additive, low regression risk on the unbiased
case. Do not change the default (E) without running §7: Russell's unbiased-
target numbers (bootstrap 0.928/0.895 vs Wald 0.952/0.900) show the
percentile interval is not broken in general, only on targets whose
estimator is itself biased at the fitted n, and swapping the default could
move other currently-fine `exp`-transformed targets without net benefit —
which is also why the structured-RE bias correction in
`docs/design/219-structured-re-small-sample-bias-correction.md` is a
separate, opt-in, Wald-only mechanism rather than a blanket default change.
This agrees with Russell's own "document, or add a variant" framing.

## 7. D-139 pre-run specification for a default change (E)

**Estimands.** Per target: coverage of the nominal 95% interval; one-sided
miss rates (high/low separately); midpoint-offset ratio
`(midpoint - theta_hat) / (E[theta_hat] - theta)`, reproducing Russell's
2.35x as a comparable number per method; and, separately, `midpoint - theta`
(offset from the truth) — the ratio alone cannot discriminate between the
`b`-scale and `2b`-scale readings of #1315's `-0.05479` (§4), so the
offset-from-truth estimand must be recorded directly rather than inferred
from the ratio.

**Methods.** Percentile (current default), basic, BC (§5), Wald, profile —
percentile/basic/BC read the same `R` draws differently; Wald/profile need
no draws.

**DGP.** (1) `n = 100`, `sigma` intercept `gamma0 = -0.4` — Russell's
design, 250 replicates, `R = 199`, three seeds (his two plus one fresh
seed for independent reproducibility). (2) Same fits, `mu:x1` as the
unbiased control (no separate replicate set needed). (3) `n = 400`, same
`gamma0`, 250 replicates, `R = 199`, one seed — tests whether the bias (and
doubling) shrinks enough at 4x n to matter.

**Performance measures.** Coverage, one-sided miss rates, midpoint-offset
ratio, midpoint-offset-from-truth, Monte Carlo SE on coverage (0.019 at
p=0.9, 0.0138 at p=0.95, 0.0225 at Russell's observed 0.852, all with 250
reps), refit failure rate.

**Failed-refit rule (pre-specified).** Russell's pilot lost 1 of 10 refits
at `R = 10`; a ~10% refit-failure rate is a selection mechanism acting on
the same draws the interval is built from, not sampling noise to wave off.
Rule: a non-converged refit is **dropped** from that replicate's draws (not
imputed), the replicate itself is retained provided at least half of `R`
refits converged, and the per-scenario refit-failure rate is reported
alongside coverage rather than only checked for non-emptiness.

**Refit count.** Scenario 1 is specified with three seeds (above), so its
refit count is `3 x 250 x 199 = 149,250` (covers scenario 2's target from
the same draws — no separate refits). Scenario 3 uses one seed:
`250 x 199 = 49,750`. **Total ~199,000 refits.** The three interval methods
add no refits — they are three summaries of the same draws; only
Wald/profile skip refits entirely.

**Time estimate (measured).** One `confint(fit, method = "bootstrap", R =
10)` on a Gaussian `sigma ~ 1` fit, `n = 100`, in this worktree via
`Rscript -e "pkgload::load_all('.', quiet = TRUE); ..."` (no compile, `.so`
current):

```
SINGLE_BOOTSTRAP_R10_SECONDS: 1.915445
```

(9/10 refits converged; this is also the pilot evidence for the
failed-refit rule above, not sampling noise to wave off.) That is
**~0.192 s/refit at n=100** — ~38.1 s/replicate at `R=199`, ~2.65 hours
single-core for one seed's 250 replicates. Scenario 1 needs **three seeds**
(above): `3 x 2.65 ~ 7.95 hours single-core` for scenarios 1+2. Scenario 3
(`n=400`, one seed) is not measured directly — UNVERIFIED assumption:
2-2.5x the per-refit cost of n=100, giving **~5.3-6.6 hours single-core**
(`2 x 2.65 = 5.3`, not 5.5). **Total serial estimate: roughly ~199,000
refits, ~24-27 hours, single core** — the three-seed multiplier for
scenario 1 dominates the total and must not be dropped (D-139: an estimate
is the deliverable). This is well past the 30-minute D-139 line, so this
needs the estimate, the pre-run test below, and sign-off before the full
run, and must not run on GitHub Actions (D-50).

**Compute target.** Totoro, capped at <=150 cores (D-143). Replicates are
embarrassingly parallel across the outer index; even 50 cores brings the
~24-27 hour serial estimate under an hour of wall time before per-replicate
overhead — which the pre-run below should surface first.

**Required pre-run.** 1 replicate, 1 seed, at both `n=100` and `n=400`,
full `R=199` (not `R=10`), confirming non-empty finite output for every
method and target before requesting Totoro time.

## 8. Help-page paragraph draft (not applied)

Draft for `?confint.drmTMB`, near the existing text at
`man/confint.drmTMB.Rd:188-189`:

> `method = "bootstrap"` returns a **percentile** interval: the
> `(1-level)/2`/`(1+level)/2` quantiles of the refit draws (Efron &
> Tibshirani 1993). When the ML point estimate is itself biased at the
> fitted sample size — as scale (`sigma`) intercepts and other
> variance-like targets commonly are at small n — the percentile interval
> inherits that bias twice, because each refit re-applies the same biased
> estimator to data simulated at the already-biased fit. On a documented
> case (`gamma0 = -0.4` sigma intercept, n = 100), this roughly doubled the
> interval's offset from the truth relative to the point estimate's own
> bias, lowering coverage from nominal 0.95 to 0.852 (Wald: 0.896; profile:
> 0.912), missing high on ~14.5-14.8% of replicates and low on <=1%.
> Targets with negligible ML bias at the fitted n are unaffected. For scale
> intercepts and other small-n-biased targets, prefer `method = "wald"` or
> `method = "profile"`.

## 9. Not covered by this note

No code change is made here; §5's (B)/(C)/(D) are scoped, not implemented.
No simulation beyond the single-replicate timing check in §7 was run — the
250-replicate campaign is specified, not executed. Whether other
`exp`-transformed targets (dispersion, other SD targets) share this
failure is not measured; scenario 3 only probes whether *this* target's
bias shrinks with n. The BCa jackknife cost (§5D) is described, not
benchmarked. No reconciliation with the Wald-only structured-RE
`bias_correct` mechanism is attempted; a future bootstrap BC/BCa and that
correction target overlapping classes and should be reconciled in naming
and defaults before both ship.

## 10. References

- Efron, B., & Tibshirani, R. J. (1993). *An Introduction to the
  Bootstrap*. Chapman & Hall. (Percentile, basic, BC, BCa: chs. 13-14.)
- DiCiccio, T. J., & Efron, B. (1996). Bootstrap confidence intervals.
  *Statistical Science*, 11(3), 189-228.
- Davison, A. C., & Hinkley, D. V. (1997). *Bootstrap Methods and Their
  Application*. Cambridge University Press.
- Morris, T. P., White, I. R., & Crowther, T. J. (2019). Using simulation
  studies to evaluate statistical methods. *Statistics in Medicine*,
  38(11), 2074-2102. (ADEMP framework, used in §7.)
- Dinnage, R. Independent evaluation of drmTMB 0.7.0.
  `https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md` §4,
  Appendix A row S6. Filed as drmTMB issue #1315.
