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

The fixed-tree pre-run then held one deterministic phylogeny per primary cell,
regenerated five independent responses, and compared fast with default public
profiles. Their mean endpoint differences were 0.00044--0.00065. Profile
coverage in those five draws was 3/5, 4/5, and 5/5 for P1--P3, so holding the
tree fixed provides no evidence that tree resampling removes the P1/P2
shortfall. This is a mechanism signal, not a coverage estimate.

An independent no-fit calculation regenerated those same 15 datasets and used
the known generating phylogenetic-plus-independent-OU covariance in ordinary
Gaussian GLS. Its five-draw intercept coverage was 4/5, 5/5, and 5/5, versus
3/5, 4/5, and 5/5 for the retained default profiles. Mean GLS/profile interval
widths were 1.370/1.253 (P1), 2.438/1.983 (P2), and 1.235/1.601 (P3). These
small comparisons make finite-sample uncertainty from estimated covariance
parameters the leading remaining hypothesis. They do not establish that cause
or demonstrate calibrated replacement intervals.

A paired, model-matched reference implementation has not yet been run. Thus
neither this diagnosis nor the G13 coverage failure is evidence of a drmTMB
implementation defect. The revised decision is to retain the present
point-fitting and unqualified-profile scope, block later temporal structures,
and prepare a separately approved comparative-calibration campaign only after
specifying a model-matched reference or documenting why none is available.

A later 15-dataset paired pre-run did fit the same additive Gaussian model in
drmTMB and glmmTMB 1.1.14, using `propto` for the phylogenetic stable effect
and `ou` for independent within-species deviations. All profiles were
available, all paired cover/not-cover outcomes agreed, and the largest paired
differences were 0.000010 for the estimate and 0.001795/0.001701 for lower and
upper endpoints. This rules out an appreciable drmTMB-versus-glmmTMB profile
mismatch in the tested P1--P3 draws. It is not a calibration result and does
not prove either implementation is nominally calibrated.
