# After Task: Arc D — binomial probit/cloglog R surface (2026-08-09)

## 1. Goal

Make `binomial(link = "probit")` and `binomial(link = "cloglog")` reachable from
R. The C++ engine already implemented both (commit `5b6c13197`); the links were
deliberately unreachable because the admissibility guard was still logit-only.
This task opened the R surface, tested it, and stopped short of any shipping or
capability-ledger claim.

## 2. Implemented

Five R edits, one more than the inherited plan named. `drm_family_type()`
(`R/drmTMB.R:2828`) now admits all three links via a new
`drm_binomial_links()` helper, with `drm_binomial_link_code()` mapping to the
`0/1/2` codes in `src/drm_numeric.h:103`. The fitted link is carried on the spec
(`drm_build_binomial_spec()` gains `link`; `object$model` **is** the spec, so one
field serves both the runtime link table and the TMB data), and the binomial
branch of `make_tmb_data_core()` now derives `link_code` from it instead of
hard-coding `0L`.

On the read side, `drm_dpar_link()` (`R/methods.R:5613`) returns the fit's actual
link rather than the constant `"logit"`, `drm_inverse_link()` gained
`probit = stats::pnorm(eta)` and `cloglog = -expm1(-exp(eta))`, and
`predict_parameters_inverse_link_derivative()`
(`R/predict-parameters.R:347-348`) gained `probit = stats::dnorm(eta)` and
`cloglog = exp(eta - exp(eta))`.

`tests/testthat/test-binomial-links.R` is new (66 assertions):
`glm()` parity for both links, random-intercept recovery, the
link/response round-trip, standard errors through `predict_parameters()`,
extreme-η tail accuracy against a naive `1e-12` probability clamp, and
`cauchit` still rejected. `test-binomial-response.R:206-213` flipped from
asserting probit is rejected to asserting it fits, with the rejection assertion
repointed at `cauchit`.

## 3a. Decisions and Rejected Alternatives

**A new link inherits binomial's capability-ledger evidence cells** (owner
decision; design 252 §9 rewritten from open question to settled). A link is not
a new family: same likelihood, same parameters, only `g(mu)` changes. No
campaign, no census movement, claim ceiling stays `point_fit_recovery`.

**`%||%` was rejected outright.** It appears nowhere in `R/`, rlang is not
imported, and base R's `%||%` arrived in R 4.4.0 against a
`Depends: R (>= 4.1.0)` floor. Explicit `if (is.null(x))` throughout.

**gllvmTMB's probability clamp was again refused.** The dispatch pattern and
`gll_log_pnorm` were adopted; `gll_clamp(p, 1e-12, 1-1e-12)` was not, because it
is a downgrade against drmTMB's `logspace_add` path.

**Shipping is not decided.** Default target stays 0.7.1; the 0.7.0-vs-0.7.1 call
is held to the D8 review. Building did not commit to shipping.

No likelihood, estimator, parameterization, or formula grammar changed. `mu`,
`sigma`, `rho12`, `sd(group)`, `phylo()` are untouched. MSPL stays logit-only.

## 4. Files Touched

`R/drmTMB.R`, `R/methods.R`, `R/predict-parameters.R`, `R/associate-pairs.R`
(comment), `R/missing-data.R` (comment), `NEWS.md`, `man/drmTMB.Rd`,
`docs/design/252-binomial-link-generalisation.md`,
`tests/testthat/test-binomial-response.R`,
`tests/testthat/test-binomial-links.R` (new),
`scratchpad/arcD-S0-recon.md` (new).

No file under `src/`, no capability ledger, no census, no `DESCRIPTION`.

## 5. Checks Run

`devtools::document()` clean. Targeted: `test-binomial-links.R` 66 pass,
`test-binomial-response.R` 60 pass, `test-julia-phylo-nongaussian.R` 15 pass /
2 pre-existing skips (DRM.jl absent). Full `devtools::test()` and
`--as-cran` were re-run after the defect in §9 was fixed.

## 6. Tests of the Tests

The round-trip test would pass vacuously if `drm_inverse_link()` silently used
`plogis` for a probit fit, so it asserts the value equals `pnorm(eta)` *and*
`expect_false` that it equals `plogis(eta)`. The tail test is the only evidence
that refusing gllvmTMB's clamp was right, so it compares against what the clamp
would have produced rather than merely asserting finiteness.

## 7a. Issue Ledger

No issue opened or closed. Design 252 §5 and §9 moved from open to resolved.

## 8. Consistency Audit

The capability ledger and frozen census are unchanged, confirmed by
`git status`. `DESCRIPTION` remains `0.6.0`. The Julia bridge still rejects
probit and cloglog, proven by `test-julia-phylo-nongaussian.R:54-64` passing
unchanged — a regression test that predates this arc, which is what makes it
real evidence rather than a test written to agree with the change.

## 9. What Did Not Go Smoothly

**Three "complete" claims failed on re-run, and the worst was already pushed.**

1. The plan review found `predict_parameters_inverse_link_derivative()` had no
   probit/cloglog arm. Once `drm_dpar_link()` returned `"probit"`, every
   standard-error request on a probit fit would have aborted. The handover,
   design 252's own inventory, and the first decomposition all missed it.
   *Lesson: an inventory of who **sets** the link is not an inventory of who
   **reads** the link string.*
2. The S0 scout graded two `profile.R` sites as breaks. Neither has a `logit`
   arm either, so both already fail for any binomial fit — a pre-existing
   limitation, not a regression. It also reported writing a file it never wrote.
   *Grade a site by whether the NEW string behaves differently from the OLD one,
   not by whether the switch lacks an arm.*
3. **The full suite found 223+ failures from a defect already on `origin`.**
   `make_tmb_data_core()` has **19** model_type declarations, not 17. The
   bivariate branch (`R/drmTMB.R:20199`) declares its type through a `switch()`
   rather than a literal `model_type = <n>L,`, so the grep that found the other
   17 could not match it. It was left without a `link_code`, and every
   bivariate Gaussian / lognormal / Student-t fit died with
   *"Error when reading the variable: 'link_code'"*. Fixed, with a comment at the
   site naming the grep blind spot, plus an audit confirming all 19 declarations
   now carry one.

**Blast radius of item 3, measured rather than assumed.** `git show HEAD:R/drmTMB.R`
confirms the defect is in the *committed, pushed* branch head `96d3896aa`, so it
was not introduced by this task's edits. But `git show origin/main:R/drmTMB.R`
contains **zero** occurrences of `link_code` — the engine commit is not on `main`
at all. So **`main` was never affected**; the defect was confined to
`claude/binomial-link-generalisation` for its whole life and is now fixed there
before any PR. It shipped in the engine commit, was pushed, and was invisible to
every targeted test run. Only the full suite caught it.

## 10. Known Residuals

The MSPL entry point stays logit-only (design 252 §7) — extending it is a
research arc, since Kosmidis & Firth's finiteness result is fixed-effect while
drmTMB's MSPL is mixed-effect. Response-scale profiling remains unsupported for
binomial at any link (`R/profile.R:3754`, `:3766` — pre-existing). No interval
or coverage evidence exists for the new links; they inherit binomial's cells and
claim no more. Whether they ship in 0.7.0 or 0.7.1 is undecided.

## 11. Team Learning

A pre-execution plan review is cheap and caught a blocker that three documents
missed. Sub-agent claims must be re-run: three of four returned something that
did not survive verification. And a targeted test run cannot substitute for the
full suite — the most serious defect here was in code no probit test would ever
touch.

## 12. Cross-Product Coverage

gllvmTMB implements these links already; the dispatch pattern and
`gll_log_pnorm` were adopted with provenance in `inst/COPYRIGHTS`, its
probability clamp deliberately refused. DRM.jl implements the logit mean only,
so the bridge rejects the new links rather than silently fitting a different
model.
