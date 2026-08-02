# Arc 6 K1 tail-orientation repair receipt

**Status:** PRIVATE POINT-KERNEL PASS; F1 DERIVATIVE GATE STILL STOPPED
(2026-07-26).

K1 corrects an existing internal Bernoulli × ordinary-NB2 latent-normal
rectangle likelihood calculation. It is not a sandwich-SE, interval, recovery,
coverage, public-readiness, or capability claim.

## Run identity

| Item | Value |
| --- | --- |
| Starting source SHA | `cc7a4b06` |
| R runtime | 4.6.0 |
| Numerical packages | `mvtnorm` 1.4.1; `numDeriv` 2016.8.1.1 |
| Production orientation | bounded NB2 CDF interval with conditional Bernoulli probability |
| Independent 1-D orientation | NB2 latent-normal interval, `dnorm(z) * P(B | Z_N = z)` |
| Independent 2-D comparator | explicit `mvtnorm::GenzBretz(maxpts = 250000L, abseps = 1e-12, releps = 1e-12)` |

## Defining repair result

| `alpha` | Old production log probability | Repaired production | 1-D latent-interval oracle | 2-D Genz comparator | Disposition |
| --- | ---: | ---: | ---: | ---: | --- |
| `-4` | `-323.376379095663` | `-323.285855233765` | `-323.285855233765` | `-323.285855234021` | PASS at `1e-10` |
| `-7` | `NA` / unavailable | `NA` / unavailable | not a derivative certificate | `-Inf` in the retained staged oracle | Valid fail-closed boundary |

The repaired `-4` integration error is reported on the final probability scale
(`3.891407e-150`); its relative integration error is `9.803241e-10`. The
absolute tolerance is converted to the rescaled quadrature scale, capped so it
cannot weaken the binding relative-error acceptance rule.

## Deterministic matrix and checks

The private B×NB2 fixture matrix passes eta-zero factorization, both Bernoulli
outcomes, both association signs, NB2 zero/ordinary/high counts, `alpha = ±4`,
near-boundary `±7`, and retained endpoint/quadrature failure paths. The
defining negative tail requires both independent oracles; other finite Genz
underflows are recorded as test-only `oracle_unresolved` rather than a pass.

Focused commands passed:

```r
devtools::load_all(quiet = TRUE)
testthat::test_file("tests/testthat/test-associate-pairs-bernoulli-nb2.R")
testthat::test_file("tests/testthat/test-associate-pairs-staged-sandwich.R")
```

The staged file now records the repaired `-4` point agreement but retains the
non-finite independent numerical Hessian. Its internal finite difference
ladder is therefore not external derivative certification.

## Review and fence disposition

- **Noether:** PASS for the private point kernel; CDF-scale substitution,
  zero-count handling, error scaling, and eta-zero factorization are coherent.
- **Fisher:** PASS for the point repair; the defining `-4` row has opposite-
  orientation one-dimensional and mandatory 2-D independent checks.
- **Rose:** PASS only after this plan correction and receipt; the correction is
  internal point-likelihood work and not an inference result.

No F3 smoke or refits, F4/F5 work, Totoro/DRAC computation, public API or
documentation work, `vcov()`, `confint()`, profiles, capability-ledger changes,
Arc D/F5 work, or direct `biv_lognormal()` `rho12` work occurred.

**Next approval fence:** K1 does not pass F1. A fresh, derivative-only F1
design must first provide an independently stable gradient/Hessian reference
for `alpha = -4`, or separately justify a fail-closed derivative outcome. It
then requires fresh Noether/Fisher/Rose review and owner approval before F3's
deterministic matrix may reopen. A one-cell F3 smoke remains separately gated.

> Related: [K1 ultra-plan](2026-07-26-arc6-k1-tail-orientation-repair-ultra-plan.md) ·
> [F1 tail-stop receipt](2026-07-26-arc6-f3-f1-tail-stop-receipt.md)
