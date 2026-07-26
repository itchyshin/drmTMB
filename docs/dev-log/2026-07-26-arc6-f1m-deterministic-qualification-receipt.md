# Arc 6 F1M — private deterministic qualification receipt

**Disposition:** `F1_PASS` for the private, fixed-effect, complete-pair Bernoulli × ordinary-NB2 `association = ~1` staged-alpha route.  This is a deterministic likelihood-and-derivative qualification only.  It is not a sandwich-SE, interval, recovery, coverage, or public-readiness result.

## Scope and provenance

- F1M implementation base: `d271faa3` (`test(arc6): add independent staged derivative oracle`).
- Changed implementation surface: only `tests/testthat/test-associate-pairs-staged-sandwich.R`; the production kernel and public surface were not changed.
- R runtime: 4.6.0; `mvtnorm` 1.4.1; `numDeriv` 2016.8.1.1; `statmod` 1.5.2; `testthat` 3.3.2.
- F1D remains retained negative evidence.  F1E's independent analytic oracle remains the reference route; F1M extends its fixture coverage and does not relabel F1D as a pass.

## Frozen contract

The independent oracle evaluates the Bernoulli conditional-normal probability over the NB2 CDF jump.  For an NB2 zero count, the lower latent endpoint remains mathematically `-Inf`: the test-only oracle changes variables to the bounded CDF scale rather than substituting a finite lower endpoint.  Its `u = U t^2` node transform regularizes the integrable endpoint singularity without changing the analytic CDF-scale derivative identities.

Every finite case requires both 512↔1024 and 1024↔2048 analytic coordinate ladders to satisfy

`abs(left - right) <= max(1e-8, 2e-10 * max(1, abs(left), abs(right)))`.

Only then are production derivatives compared to that independent route with the frozen `2e-3` gradient and `3e-3` Hessian tolerances.  The `a = -4` point also retains its pinned Genz agreement at `1e-10`.  An unresolved analytic derivative remains `derivative_unqualified_test_only`; no runtime status was added or changed.

## Completed matrix

| Fixture | Disposition |
| --- | --- |
| Interior: `a=0.22`, `B=1`, `Y_N=3` | finite and independently qualified |
| Eta-zero: `B=0/1`, `Y_N=0/3` | factorization and full derivative checks passed |
| Moderate signs: `a=-0.35,+0.35`, `Y_N=3` | separately qualified; no sign-symmetry substitution |
| Tail pair: `a=-4,B=1`; `a=+4,B=0` | finite and independently qualified; `-4` retained Genz agreement |
| Response-order swap | transformed gradient/Hessian equality and failure propagation passed |
| Near boundary: `a=-7` | retained fail-closed `unavailable` / `nonfinite_derivative` outcome |
| Near boundary: `a=+7` | finite and independently qualified |
| Structural invalid endpoint / forced quadrature error | existing fail-closed behavior unchanged |

The retained fixture taxonomy distinguishes protocol/input mismatch, missing evidence, unexpected boundary disposition, non-finite or unstable production derivatives, endpoint-oracle failure, independent derivative unresolved/unstable/disagreement, point-oracle mismatch, row-kernel failure, and structural regression.  The complete observed aggregate disposition is `F1_deterministic_gate_passed`.

## Verification and review

Focused verification passed:

```r
devtools::test(filter = "associate-pairs-(staged-sandwich|bernoulli-nb2)$", reporter = "summary")
```

`git diff --check` also passed.  Noether, Fisher, and Rose each returned `F1_PASS`; a fresh D-43-style panel (two independent Terra reviews and one Sol review) also returned three `F1_PASS` verdicts.  The panel's scope was this private deterministic gate only.

## Exact next approval fence

The attached F3 packet is documentation only.  Before one local F3 provenance smoke, the owner must give a **fresh written approval** naming the final post-F1M source SHA and authorizing exactly one attempt under that packet.  It does not authorize a retry, a refit beyond that one smoke, an F4 campaign, remote compute, public API exposure, or a public inference claim.
