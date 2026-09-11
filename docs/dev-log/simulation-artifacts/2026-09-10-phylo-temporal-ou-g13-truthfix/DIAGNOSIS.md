# Intercept-coverage diagnosis

This no-fit diagnostic reads the stored `selected-fit` and `profiles` records
from the sealed G12 task archives. Its complete per-interval table and the
extractor scripts are retained on Totoro in
`g13-endpoint-diagnostic-de65cab2-r2/` and `receipts/g13-raw-profile-diagnostic-r2.R`.

For the three primary intercept rows, actual interval coverage and coverage of
a symmetric interval centred on the selected estimate differ by at most 0.003.
The mean and median profile-midpoint shifts are effectively zero. Thus neither
endpoint displacement nor the corrected truth registry explains the failure.

The profile half-widths are close to 1.96 times the empirical intercept SD:
P1 0.689/0.353, P2 1.174/0.599, and P3 0.708/0.363. Yet standardized intercept
errors have SD 1.945, 1.348, and 1.709 respectively, with two-sided 97.5%
absolute quantiles 5.545, 2.703, and 3.948. Corresponding slope standardized
errors have SD 0.98--1.05 and achieve near-nominal coverage.

The evidence establishes heavy-tailed intercept error relative to the retained
profile widths. It does not by itself identify the cause. The next diagnostic
must separate conditional-on-tree behaviour from nuisance variance-component
and profile-approximation effects before changing the estimator, interval
method, thresholds, or temporal scope.

On the independent small dense-oracle fixture, the fast full-profile intercept
endpoints differ from the dense marginal-likelihood endpoints by at most
0.00073. The regression test now checks both intercept and slope targets. This
rules out a basic endpoint discrepancy on that fixture, but does not establish
calibration in the larger campaign cells.
