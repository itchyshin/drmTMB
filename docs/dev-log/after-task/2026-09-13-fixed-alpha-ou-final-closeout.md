# After Task: Fixed-alpha phylogenetic OU final closure

## 1. Goal

Leave a durable, honest endpoint for the fixed-alpha OU work: preserve the
useful experimental helper, retain the negative evidence against expanding
free-rate OU now, and give a future developer one unambiguous restart point.

## 2. Implemented

`ou_sensitivity()` remains the earned public surface: a univariate,
complete-response Gaussian, location-side phylogenetic-intercept sensitivity
helper that compares BM with prespecified fixed OU decay values on unchanged
data, tree, formula, controls and ML settings. BM remains the default. The
R7 empirical/simulation receipt supports retaining that narrow helper but does
not support free-alpha OU, correlated OU, conditional-AIC selection, or a
full OU-v1 promotion.

## 3a. Decisions and Rejected Alternatives

Keep BM as the default and retain fixed-alpha sensitivity as an experimental
robustness tool. Reject, for this closed arc, free-rate OU, cross-field OU
correlation, conditional-AIC process selection, and full OU-v1 expansion:
the retained evidence does not support any of those claims.

## 3b. Mathematical Contract

For each declared root-depth-normalized value `alpha`, the native model fixes
`log_decay_phylo = log(alpha / tree_height)`. It changes only the location-side
OU covariance assumption. The displayed likelihoods and AIC values are
conditional sensitivity summaries, not rate estimates, intervals, or evidence
that either BM or OU is generally preferable.

## 4. Files Touched

- `docs/dev-log/evidence/ou-fixed-alpha-r7/` retains the four qualified
  applications and the full AVONET feasibility/boundary receipt.
- `docs/dev-log/evidence/temporal-future-issue-draft-2026-09-13.md` records
  the separate unfinished temporal programme for the existing tracker.
- `docs/dev-log/known-limitations.md` now links free-rate/correlated OU to
  issue #1305.

## 5. Checks Run

The focused `ou-sensitivity` tests, native OU covariance/parser tests, and
R7's 15 qualified small application cells passed before this closure. The
historical full package check and pkgdown limitations remain recorded in the
earlier after-task reports; this documentation-only closeout does not upgrade
either to a pass.

## 6. Tests of the Tests

The R7 panel retains two fixed-seed OU-generated data sets, including a
stronger-signal variant, even though BM had the lowest AIC in both. This makes
the decision depend on retained negative evidence rather than a
positive-control-only comparison.

## 8. Consistency Audit

The exact R7 receipt, the experimental helper documentation, and the
limitations inventory agree: BM is default; fixed-alpha location-side
sensitivity is experimental; free-rate and correlated OU are parked.

## 7a. Issue Ledger

Issue [#1305](https://github.com/itchyshin/drmTMB/issues/1305) is now the
public future-work record for free-rate and correlated phylogenetic OU. It
lists the required narrow-estimand, independent-likelihood, recovery, and
continuous-time correlated-process gates. No duplicate issue is needed.

Temporal work is distinct. Existing issue [#1302](https://github.com/itchyshin/drmTMB/issues/1302)
is the correct tracker; the local draft records its current status and the
remaining temporal random-effects programme without conflating it with OU.

## 9. What Did Not Go Smoothly

The 657-species AVONET feasibility batch had a false-converged BM fit and
careful-preset OU fits, so it cannot support an AIC conclusion. More
importantly, neither real-data nor fixed-seed simulated comparisons made the
true-grid OU member reliably preferred. Clean convergence alone was not
decision-bearing evidence.

## 11. Team Learning

Fixed assumptions can be an honest robustness workflow when they are visible
to the user. Estimating or comparing free OU rates is a different inferential
problem and needs replication, profile geometry and recovery evidence before
the grammar expands.

## 10. Known Residuals

There is no free alpha, scale-side OU, cross-field OU correlation, direct-SD,
random-effect, REML, missing-response, bivariate/non-Gaussian, `newdata`, or
forecast support in this helper. Temporal random effects have their own
separate, partly complete programme and must not inherit this result.

## 12. Cross-Product Coverage

This closure covers only the location-side, fixed-alpha, univariate complete
Gaussian phylogenetic-intercept helper. It does not cover a temporal
covariance, a sigma-side OU field, cross-field correlation, direct-SD terms,
slopes, bivariate or missing-response layouts, non-Gaussian families, REML,
forecasting, or `newdata`.

## Next Actions

Do not reopen full OU v1 merely because the helper is useful. Resume
free-rate/correlated phylogenetic OU only through #1305. Update #1302 with
the retained temporal summary before beginning any new temporal structure;
start from one estimand and one independent oracle rather than a broad
"temporal parity" target.
