# After Task: Phase B — link-general MSPL Jeffreys penalty (2026-08-09)

## 1. Goal

Make the MSPL fixed-effect Jeffreys penalty link-general **internal scaffolding**,
evaluated on the log scale, while the public MSPL entry point stays logit-only.
This is the second half of design 252 §1, which could not be done on the Arc D
branch because MSPL is on neither that branch nor `main`.

## 2. Implemented

`mspl_logit_jeffreys()` is renamed `mspl_jeffreys()` and gains a `link` argument.
A new internal `mspl_log_weight(eta, n_trials, link)` returns the log of the
binomial **expected (Fisher)** working weight, per link, in closed form on the
log scale:

| link | log w − log n |
|---|---|
| logit | `− softplus(eta) − softplus(−eta)` (the pre-existing path, untouched) |
| probit | `2·dnorm(eta, log) − pnorm(eta, log.p) − pnorm(eta, lower=FALSE, log.p)` |
| cloglog | `2·eta − exp(eta) − log(mu)`, with `log(mu)` from `mspl_log_cloglog_mu()` |

`mspl_link_mu()` supplies the unclamped inverse link, replacing two
`stats::plogis(eta)` calls. A finiteness guard returns a new
`"non_finite_log_weight"` failure code before any scaling.
`drm_validate_mspl_request()` is **unchanged** — MSPL still rejects non-logit.

## 3a. Decisions and Rejected Alternatives

**`stats::make.link()` was rejected**, contradicting design 252 §4 which
prescribes it. `make.link()`'s `linkinv`/`mu.eta` clamp to `[eps, 1−eps]` and
`cloglog$mu.eta` floors at `.Machine$double.eps`. Using them would change the
penalty **value**, not merely its tail accuracy, and would break the exact logit
reduction — a silent reparameterisation. Design 252 §4 should be corrected.

**The C++ site was deliberately NOT generalised.** `src/drmTMB.cpp:4965-4968`
carries the identical logit-only `logspace_add` weight. Since the entry guard
rejects non-logit, the TMB objective can never see the new links, so
generalising it now would add an unreachable branch to compiled code. Both sites
carry a comment naming the other; the arc that opens the entry point must
generalise them together.

**The entry point stays logit-only** (design 252 §7). Kosmidis & Firth's
finiteness result is *fixed-effect*; drmTMB's MSPL is *mixed-effect*, and
Sterzinger & Kosmidis leave those bounds as future work.

## 4. Files Touched

`R/mspl.R`, `R/mspl-estimator.R` (one call-site rename plus an explicit
`link = "logit"`), `tests/testthat/test-mspl-kernels.R` (9 call-site renames),
`tests/testthat/test-mspl-link-general.R` (new),
`scratchpad/phaseB-mspl-map.md` (new). No `src/`, no ledger, no `DESCRIPTION`.

## 5. Checks Run

`devtools::document()` clean. `test-mspl-link-general.R` 32 pass,
`test-mspl-kernels.R` 52 pass, `test-mspl-estimator.R` 143 pass — the entry-guard
rejection block at `:591-598` unchanged and still passing. Full `devtools::test()`
and `--as-cran` re-run on the final tree.

## 6. Tests of the Tests

**The logit-equivalence evidence is the load-bearing claim, and its first two
forms were both weak.** Noether found that the in-test reference re-derived the
implementation's own expression, so it would have agreed even if both were
wrong — a regression pin, not a proof. She also found the expected-vs-observed
information test asserted equality against the same closed form the
implementation encodes, i.e. self-referentially.

Both were replaced:

- **Expected information** is now built as `E_y[observed] = mu·obs(y=1) +
  (1−mu)·obs(y=0)` from `numDeriv::hessian` on the actual Bernoulli
  log-likelihood — sharing no algebra with the implementation — with a sanity
  check against the textbook closed form and a `skip_if_not_installed()` guard
  (`numDeriv` is Suggests, `DESCRIPTION:59`).
- **Bit-identity** was verified against the genuine independent reference: the
  pre-change `mspl_logit_jeffreys()` extracted with `git show HEAD:R/mspl.R`.
  Old and new agree under **`identical()` — not to a tolerance** — on
  `log_weight`, `half_logdet` and `c_n` across **200 random designs**
  (n = 20..120, p = 2..4, beta scales to 6, i.e. into the near-separated
  regime). Reproduce with `/tmp/equiv.R`-style: `sys.source` the old file into
  an environment and `stopifnot(identical(...))` over a random grid.

The committed test pins the same fixture at `1e-12` rather than bit-identity,
because writing a double into source does not reliably round-trip (both
`dput()`'s 15 digits and `sprintf("%.17g")` lost ULPs on some values). That is a
limit of the serializer, not the computation, and is stated in the test.

## 7a. Issue Ledger

None opened or closed.

## 8. Consistency Audit

Ledger, census and `DESCRIPTION` untouched. `make.link`/`linkinv`/`mu.eta`
appear in `R/mspl.R` only inside the comment forbidding them. The MSPL entry
point still errors on probit and cloglog.

## 9. What Did Not Go Smoothly

**A real defect in the first implementation, found by review, not by tests.**
The cloglog form `log(-expm1(-exp(eta)))` is correct as `eta → +Inf` but wrong
as `eta → −Inf`: `exp(eta)` underflows to exactly 0 below `eta = −745.13`, so
`log(0) = −Inf` and the weight became **`+Inf` — the wrong sign of infinity**
for a weight tending to zero. Measured: `eta = −745` gave `−745.56` (correct),
`eta = −746` gave `+Inf`. Fixed with a series branch
(`eta + log1p(-x/2)` for `x < 1e-8`), giving the correct limit `log(n) + eta`;
now exact to `0.00e+00` at `eta = −1000`. A downstream guard was converting the
`+Inf` into a failure rather than corrupting a fit, but it would have become the
dominant weight in `max()` had that guard ever been relaxed.

**`ifelse()` was the wrong branching tool.** It evaluates both arms over the
whole vector, so the series arm ran at large positive `eta` and produced NaN
warnings in the discarded branch. Replaced with index-based branching.

**One sub-agent brief contained a contradiction** — "update every call site in
`R/`" alongside "do not touch `R/mspl-estimator.R`", which held one. The agent
flagged the conflict instead of guessing, which was correct; the orchestrator
fixed that line and made `link = "logit"` explicit there so the estimator can
never silently inherit a future default change.

## 10. Known Residuals

The C++ weight at `src/drmTMB.cpp:4965-4968` remains logit-only by design — a
latent divergence, fenced by comments at both sites and unreachable while the
entry guard holds. MSPL still ships standard errors and no intervals. Design 252
§4's `stats::make.link()` prescription is wrong and should be corrected in that
document.

## 11. Team Learning

Noether's review earned its tier: it confirmed the algebra, then found a defect
in a regime nobody had tested and two tests that passed for the wrong reason.
The general lesson is that *a test whose reference re-derives the implementation
proves only internal consistency* — an independent reference has to come from
somewhere else entirely, and here that was the previous implementation itself,
via git.

## 12. Cross-Product Coverage

None. MSPL has no Julia or sister-repo counterpart; the Jeffreys penalty is
drmTMB-specific.
