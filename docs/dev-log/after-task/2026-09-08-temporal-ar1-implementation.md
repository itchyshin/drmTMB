# After Task: Gaussian temporal AR1 random effects

## Goal

Implement the approved native Gaussian temporal AR1 model with an optional
same-ID ordinary intercept and mean-coefficient Wald uncertainty.

## Implemented

`temporal(1 | id, time = occasion, structure = "ar1")` fits a stationary
Gaussian AR1 intercept process with genuine integer gaps. It may accompany
`(1 | id)`, which separates stable between-ID variation, temporal variation,
and residual `sigma`. The native ML route uses signed persistence starts,
labelled extractors, in-sample fitted values/residuals, and fresh or
conditional simulation. `vcov()`, `summary()`, and Wald `confint()` expose
mean-coefficient uncertainty only when the full observed Hessian is valid.

## Mathematical Contract

The implemented covariance is `s_b^2 11' + s_a^2 R(phi) + sigma^2 I` within
each ID, with independent IDs and `R_ij = phi^abs(t_i - t_j)`. The C++ first
state and transitions include their stationary normalizers. A log-sech
transition-scale calculation avoids cancellation near the persistence boundary.

## Files Changed

The provider spans `R/temporal.R`, formula parsing, TMB data/parameters and
likelihood code, methods/profile support, parser/oracle/identity/smoke tests,
the temporal vignette and reference topic, validation gate runner, final-source
recovery and pilot artifacts, and status documentation.

## Checks Run

Unlazy G1--G14 are met. G4 compares objective, score, Hessian, and the fixed
effect covariance block with independent dense references; G5 detects six
deliberate covariance/normalizer mutations; G11 retains 24 recovery attempts;
G12 retains 50 pilot attempts; G13 renders the reader vignette; and G14 runs
an isolated standard `R CMD build` plus `R CMD check` and requires `Status: OK`.
The final G14 run passed.

## Tests Of The Tests

The dense oracle uses independent marginal Gaussian covariance calculations
and two finite-difference Hessian steps. Mutation references fail for
compressed gaps, shared series, an omitted intercept, omitted normalizers, and
the wrong process scale. The non-temporal regression guard first failed because
its test used parameter count rather than residual degrees of freedom; correcting
that test left the model estimate unchanged.

## Consistency Audit

The final scans covered `README.md`, `NEWS.md`,
`docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`,
`docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, and
`_pkgdown.yml` with `rg -n -i 'temporal|ar1'` and
`rg -n -i 'temporal.*(planned|later|unsupported)|ar1.*(planned|later|unsupported)'`.
README, NEWS, roadmap, limitations, grammar, vignette, and navigation now name
the fitted route and its boundary. No open GitHub issue matched `temporal AR1`;
no external issue action was taken.

## Reviews

Noether’s mathematical review led to the explicit unit-weight rejection, the
full observed-Hessian covariance oracle, and stable boundary transition scale.
Pat’s reader review led to the within-site interpretation, duplicate-key
guidance, and simulation-mode explanation. The integration audit required
source-fingerprinted successor recovery/pilot artifacts and explicit pilot
limits; both were added.

## What Did Not Go Smoothly

The initial retained pilot preceded a numerical hardening commit, so it could
not evidence the final source. It is preserved as history and was repeated
without overwriting it. The Unlazy ledger initially resolved checks relative to
its own directory and used a two-minute timeout; root CWD and a 30-minute G14
timeout fixed those execution controls.

## Known Limitations

G16--G18 are intentionally unmet. The final-source five-seed pilot has 4/5
mean-coefficient interval availability in primary C1 because one fit has a
non-positive-definite Hessian. Consequently no 5,000-dataset campaign ran, no
coverage claim is made, and variance/persistence intervals, forecasting,
`newdata`, OU, slopes, REML, and wider families remain unavailable.

## Next Actions

Diagnose the C1 residual-boundary/Hessian behavior before asking for G17
campaign authority. If authorized later, run the immutable 5,000-dataset
array campaign on DRAC/Fir and let G16/G18 recompute its complete denominators.
