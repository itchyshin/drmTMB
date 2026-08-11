# G1 CANNOT RUN AS PRE-REGISTERED — the TMB MSPL penalty is hardcoded to logit

Found 2026-08-11 while executing slice S0/S1 of the non-logit MSPL evidence campaign, **before any
compute was spent.** Status: **campaign halted at the pre-run gate, pending a decision.**

## The finding

`src/drmTMB.cpp:4963-4997` computes the MSPL fixed-effect Jeffreys penalty. Its working weight is
written out inline:

```cpp
log_weight_mspl(i) =
  log(weights(i) * trials(i)) -
  logspace_add(Type(0.0), eta_fixed_mspl(i)) -
  logspace_add(Type(0.0), -eta_fixed_mspl(i));
```

That is `log(n) − softplus(η) − softplus(−η)`: the **logit** working weight, and only the logit one.
There is no `link_code` branch anywhere in the block, and no MSPL-specific link data member
(`DATA_INTEGER(use_mspl)`, `DATA_SCALAR(mspl_c_n)`, `DATA_INTEGER(mspl_q)` — that is the whole set).

**Consequence.** Bypassing the R-level guard at `R/mspl-estimator.R:179-184` would let a probit or
cloglog model through, and the C++ would then penalise it with the **logit** Jeffreys weight. Every
fit would run, converge, and return finite, plausible numbers — computed from the wrong penalty.
G1 would have measured an estimator nobody intends to ship and reported it as evidence for probit
and cloglog.

This is the failure mode design 253 §7 already named once, one layer deeper. Its own words, about
the R-side version of exactly this bug: *"a test that only checked 'probit runs' would have passed
against the broken version."*

## Why this was not visible from the R side

`R/mspl.R`'s kernels **are** link-general, and slice G0 verified them against `glm()` and `brglm2`
this session (`G0-ORACLE.md`: weight parity max relative deviation 4.8e-8, Jeffreys-determinant
parity 5.6e-10, and `mspl_penalty_components()` demonstrably changes with link — 5.671 / 6.507 /
6.428 for logit / probit / cloglog on identical inputs). All three checks PASS.

But those kernels are not what the TMB engine evaluates. `R/mspl.R`'s own file header says they
"do not fit a model" and act "on inputs supplied by a future fitting adapter." **There are two MSPL
implementations, and only the R one is link-general.** A reviewer reading `R/mspl.R` — as the
2026-08-11 handover's §5 did, concluding the penalty shape "is right for all three links" — sees a
link-general implementation and reasonably infers the fitted estimator is too. It is not.

## The fix is small, and half of it is already written

`src/drm_numeric.h:134` defines `drm_binom_log_mu_eta(eta, link_code)`, returning `log|dμ/dη|` for
logit, probit and cloglog. Its comment states its purpose exactly:

> *"Used ONLY by the MSPL Jeffreys weight `n * (dmu/deta)^2 / (mu * (1 - mu))`."*

**It is never called.** `grep -rn drm_binom_log_mu_eta src/` returns the definition and nothing else;
the only other mention is a comment in `tests/testthat/test-binomial-links.R`. The link-general
primitive was written for this weight and then not wired in. Together with `drm_binom_log_mu()`
(same header, returns `log μ` and `log(1−μ)` per link), the replacement is one expression:

```cpp
DrmBinomLogMu<Type> lm = drm_binom_log_mu(eta_fixed_mspl(i), link_code);
log_weight_mspl(i) = log(weights(i) * trials(i))
                   + Type(2.0) * drm_binom_log_mu_eta(eta_fixed_mspl(i), link_code)
                   - lm.log_mu - lm.log_one_minus_mu;
```

`link_code` is already in scope (`DATA_INTEGER(link_code)`, line 350).

**This is not a null change.** It rewrites a shipped numerical kernel on the separation ray, where
the log-scale stability work in this block exists precisely because probabilities underflow. The
cloglog negative tail is the known hazard: `R/mspl.R:71-100` documents at length that the naive form
returns `+Inf` — the wrong sign of infinity for a weight tending to zero — below `η ≈ −745`, and
needs a series expansion. `drm_binom_log_mu()` handles `log(1−μ) = −exp(η)` exactly, but the
composed weight must be re-checked in both tails against the R kernels before it is trusted.

## What this changes about the plan

The approved plan fenced the guard bypass as **evidence-only, never merged**. That framing assumed
an R-level bypass. It no longer holds: G1 now requires a genuine change to shipped C++, which is a
correctness fix in its own right rather than scaffolding to be discarded.

So the decision is no longer "run the campaign." It is, in order:

1. **Wire the link into the TMB MSPL weight** and prove it against the G0-verified R kernels in both
   tails, at machine precision, before any campaign fit. This is a small, testable, mergeable fix.
2. **Rebuild on Totoro.** `~/R/f1lib` currently holds drmTMB **0.6.0**; `main` is **0.7.0**. The
   existing build is stale independently of this finding.
3. **Then** run the calibration probe and G1 as pre-registered.

`PREREGISTRATION.md` (88 cells, 88,000 fits) stands as written and needs no revision — its grid,
endpoints and control rule are unaffected. Only its prerequisite changed.

## What is NOT claimed here

The mathematics is untouched and remains proved: Kosmidis & Firth (2021), Thm 1 + §3.1 + Table 1
give finiteness for any link with `ω(η) → 0` in both tails, logit, probit and cloglog included. This
is an implementation defect, not a counterexample. It says nothing about whether probit/cloglog MSPL
*should* ship — that decision still waits on evidence that does not yet exist, which is the point.

The MSPL entry-point guard was not touched. No source file was modified by this slice.
