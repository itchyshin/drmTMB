# After Task: Arc 6 K1 tail-orientation repair

## 1. Goal

Correct the private Bernoulli × ordinary-NB2 rectangle likelihood's demonstrated
negative-tail numerical defect without widening into staged-inference work.

## 2. Implemented

The private rectangle helper now integrates conditional Bernoulli probability
over the bounded NB2 CDF interval. It retains the exact eta-zero factorization,
uses log-scale endpoint rescaling, and maps quadrature error back to final
probability scale. Focused tests add a compact normal/tail/near-boundary matrix
and the retained `alpha = -4` regression.

## 3a. Decisions and Rejected Alternatives

The CDF substitution uses `u = Phi(z_N)` and evaluates the appropriate
conditional-normal Bernoulli event. The independent test oracle instead
integrates `dnorm(z_N) * P(B | Z_N = z_N)` over the NB2 latent interval. The
defining `alpha = -4` row also requires the pinned 2-D Genz rectangle result.

Rejected: retaining the unbounded Bernoulli-half-line orientation, accepting a
guard-only unavailable result at `-4`, clipping tails, or relying on the
production CDF-scale calculation as its own oracle.

## 4. Files Touched

- `R/associate-pairs.R`
- `tests/testthat/test-associate-pairs-bernoulli-nb2.R`
- `tests/testthat/test-associate-pairs-staged-sandwich.R`
- K1 ultra-plan and retained receipt under `docs/dev-log/`

## 5. Checks Run

Both focused test files passed after the final hardening, with `R_PROFILE_USER`
disabled and `devtools::load_all(quiet = TRUE)`. `git diff --check` passed.

## 6. Tests of the Tests

The new `alpha = -4` test failed before the repair by about `0.090524` log
units. It now agrees with opposite-orientation 1-D and independent 2-D oracles
within `1e-10`. Existing malformed-input, endpoint, and quadrature-error paths
remain tested.

## 7a. Issue Ledger

No issue or PR action: this is a bounded continuation of the retained Arc 6 F1
stop, and no duplicate issue was opened.

## 8. Consistency Audit

Searched `README.md`, `ROADMAP.md`, `NEWS.md`, `docs`, `vignettes`, `R`, and
`tests` for `alpha = -4`, `negative-tail`, `Bernoulli x ordinary-NB2`, and
`CDF-scale`. No public or capability wording required revision: this is an
internal numerical correction with no supported-surface change.

## 9. What Did Not Go Smoothly

The first rescaled implementation returned quadrature error on the scaled
integral and allowed the converted absolute tolerance to terminate rare-event
quadrature too early. Rose's review caught both defects before closeout.

## 10. Known Residuals

K1 validates only private point likelihoods. The independent `alpha = -4`
Hessian remains non-finite, so F1 has not passed, F3 remains stopped, and there
is no sandwich, interval, recovery, coverage, public, or ledger claim.

## 11. Team Learning

For rare rectangle probabilities, an apparently small absolute quadrature error
is not evidence. Preserve the error's final probability scale and keep relative
accuracy binding. A test oracle must differ in integration orientation at the
defining regression point.

## 12. Cross-Product Coverage

This arc does NOT cover the product of the repaired B×NB2 point likelihood with
staged-sandwich derivatives, full-refit provenance, interval construction,
coverage, predictor-dependent association, other pair adapters, random or
structured effects, missingness, weights, offsets, REML, public extractors, or
any capability cell. It covers only fixed-margin row probability evaluation for
the existing private Bernoulli × ordinary-NB2 adapter.

## Next Actions

Start a fresh derivative-oracle-only F1 plan if approved. It must resolve the
negative-tail gradient/Hessian reference before F3's deterministic matrix can
reopen; any F3 smoke needs a separate written approval.
