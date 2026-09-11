# After Task: temporal OU review repairs

**Branch:** `codex/temporal-ou-v1-20260908`  
**Date:** 2026-09-08  
**Scope:** review repairs after the temporal OU point-fit implementation.

## 1. Goal

Make the Gaussian OU temporal route numerically stable at very small positive
decay, distinguish decay from AR1 correlation in the public fit object, and
make its deferred inference boundary visible in code and documentation.

## 2. Implemented

The OU transition variance now remains positive for very small positive decay.
OU decay is exposed through `decaypars`, rather than the AR1 correlation
extractor. The profile inventory identifies `theta_temporal` with an
exponential transformation and a deferred-inference note. OU covariance and
Wald methods now give an explicit unavailable-inference diagnostic.

## 3a. Decisions and Rejected Alternatives

The higher, positive-definite point near the inherited C1 residual-SD boundary
was not selected as an inference repair because it is not the finite ML
solution. We retained the point-fit OU route and its inference guard. We also
did not implement a CppAD `expm1()` call because the template does not expose
that overload; the native likelihood instead uses an AD-safe conditional Taylor
form for `1 - exp(-x)`.

## 4. Files Touched

The native likelihood (`src/drmTMB.cpp`), temporal extraction and simulation
helpers, fit summaries, interval-target inventory, formula diagnostics, tests,
README, NEWS, likelihood design note, temporal vignette, and the OU Unlazy
ledger were updated. This report and `docs/dev-log/check-log.md` retain the
closure evidence.

## 5. Checks Run

| Check | Outcome |
| --- | --- |
| `devtools::test(filter = "temporal", reporter = "summary")` | PASS: AR1 and OU temporal suites completed with no failures. |
| `Rscript --vanilla tools/temporal-ou-gates.R G2` | `TEMPORAL_OU_G2_PASS`. |
| `Rscript --vanilla tools/temporal-ou-gates.R G10` | `TEMPORAL_OU_G10_PASS`. |
| `Rscript --vanilla tools/temporal-ou-gates.R G11` | `TEMPORAL_OU_G11_PASS`; source-built vignette rendered. |
| `R --vanilla CMD build .` | PASS; built `drmTMB_0.7.1.tar.gz`. |
| `R CMD check --no-manual drmTMB_0.7.1.tar.gz` | `Status: OK`. |
| Independent mathematical review | APPROVED after the small-decay and unavailable-summary repairs. |
| Independent reader review | APPROVED after interface, ledger, and vignette repairs. |

## 8. Consistency Audit

```sh
rg -n -i -C 1 "temporal.*ar1|ar1.*temporal|temporal.*ou|ou.*temporal" \
  README.md NEWS.md docs/dev-log/internal-roadmap.md \
  docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md \
  docs/design/03-likelihoods.md vignettes/formula-grammar.Rmd _pkgdown.yml R tests/testthat
```

The inventory consistently describes AR1 as an integer-time, signed-persistence
model and OU as a numeric-elapsed-time, positive-decay point-fit route. The
remaining AR1-only text is fenced to AR1-specific integer-time or qualified
Wald behavior.

## 6. Tests of the Tests

The new OU regression checks fail on the prior implementation: `theta_temporal
= -37` previously gave a non-finite objective, OU appeared in `corpars`,
`profile_targets()` mapped it as a `tanh` correlation, and public `vcov()`
returned unqualified covariance. The tests now require a finite objective,
`decaypars$temporal`, an `exp(theta_temporal)` deferred target, public inference
guards, and an explicit unavailable-standard-error status. The dense oracle
continues to check the full observed-information covariance internally without
presenting it as public inference.

## 9. What Did Not Go Smoothly

The first build invocation only reported its initial stage, so the final build
was rerun as `R --vanilla CMD build .`; it passed. Independent review also
found that a default OU summary initially labelled unavailable standard errors
as `ok`. The repaired summary now labels them `temporal_wald_unqualified` and
prints the calibration deferral.

## 11. Team Learning

An elapsed-time correlation kernel should never be routed through a generic
correlation extractor solely because AR1 uses the same latent TMB coordinate.
The public parameter kind, transform, target registry, and user-facing summary
must change together. Numerical transition variances need a stable expression
even when a boundary is not an intended fitted result.

## Design-Doc Updates

`docs/design/03-likelihoods.md` now names both temporal structures and states
the OU transition and decay interpretation. The formula grammar remains the
admission authority and continues to mark OU Wald inference as deferred.

## pkgdown and Documentation Updates

The temporal vignette now has a runnable, self-contained irregular-time OU
example, extraction through `decaypars`, and an explanation that rescaling time
changes the numerical decay rate inversely. README and NEWS distinguish AR1's
Hessian-qualified mean-coefficient intervals from OU point estimates.

## 7a. Issue Ledger

No issue was opened or edited. This is a local, unpushed implementation lane;
the work did not match an identified open issue.

## 10. Known Residuals

The inherited AR1 C1 residual-SD boundary remains unresolved. Therefore OU
`vcov()`, Wald `confint()`, and `summary(..., conf.int = TRUE)` are deliberately
unavailable, and G7--G9 and G14--G15 remain open. No recovery campaign or
coverage campaign was launched. A future method decision must address the
shared residual-variance boundary before qualifying mean-coefficient inference.

## 12. Cross-Product Coverage

The deterministic oracle covers OU-only and ordinary-intercept-plus-OU models,
unequal elapsed gaps, shuffled rows, independent series, score and Hessian
agreement, and the public inference refusal. Documentation covers AR1 integer
occasion data and OU numeric elapsed-time data. This task does not cover
non-Gaussian families, REML, forecasts, temporal slopes, interval calibration,
or any retained recovery campaign.
