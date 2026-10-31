# After-task — phylogenetic-stable plus independent OU recovery diagnosis

## 1. Goal

Run the G9 predeclared 24-fixture point-recovery check, retain every attempt and diagnose any failure without altering seeds or thresholds.

## 2. Implemented

Added an immutable recovery runner with 12 balanced and 12 unbalanced fixtures, two positive OU-decay starts per fit, component-level estimates, criterion table, provenance and session record. Retained all failed and corrected-run artifacts.

## 3a. Decisions and Rejected Alternatives

G9 remains unmet. The 50-species corrected denominator and a separate 80-species high-information diagnostic retain the same seeds and thresholds. No further sample-size escalation, seed change, dropped fixture or threshold relaxation was used to seek a pass.

## 4. Files Touched

- `tools/run-phylo-temporal-ou-recovery.R`
- `docs/dev-log/simulation-artifacts/2026-09-09-phylo-temporal-ou-local-recovery*/`
- G9 ledger, check log, this report and matching plan-versus-actual record

## 5. Checks Run

The runner completed v3, v4 and v6 denominators. v4 and v6 each had 24 finite selected fits and 48 retained attempts. Their criteria CSV files show the fixed-effect error failure; all artifacts contain provenance, estimates, attempts, criteria and session information.

## 6. Tests of the Tests

v1 exposed the formula-environment requirement that `phylo()` receive a bound tree name. v2 exposed an `unlist()` argument error. v3 then ran the full denominator and revealed ordered between-species treatment assignment; v4 independently permuted the balanced treatment. v5 exposed a provenance-scope error after fitting, repaired in v6. Each failed artifact was preserved rather than overwritten.

## 7a. Issue Ledger

The corrected 50-species denominator had mean absolute fixed-effect error 0.182 against the predeclared 0.150 limit. Coefficient-specific means were intercept 0.339, between 0.131 and within 0.076. The 80-species diagnostic reduced the aggregate error to 0.165 but still failed. SD and decay recovery passed in both complete denominators.

## 8. Consistency Audit

The generator uses a phylogenetic stable draw from `A`, independent per-species dense OU draws, unbalanced retained schedules, shuffled observation rows, balanced between-species treatment independently permuted from tree order, and independently permuted within-species treatment. It preserves the distinct stable, temporal and residual components specified by P1.

## 9. What Did Not Go Smoothly

The first two runs failed before fitting because programmatic formula and list construction were incorrect. These were runner defects, not model evidence. The complete denominators then revealed the substantive intercept-recovery failure.

## 10. Known Residuals

G9 does NOT pass. The evidence does NOT qualify profile coverage, campaigns, Wald inference, variance/decay intervals, forecasting or any later temporal structure.

## 11. Team Learning

A finite-fit rate can hide a meaningful recovery problem. Recovery records need coefficient-specific errors, immutable failure artifacts and a rule against post-result sample-size escalation.

## 12. Cross-Product Coverage

This diagnosis does NOT cover the separable phylogeny-by-OU field, homogeneous or heterogeneous Toeplitz, heterogeneous AR1, ARMA, seasonal, random-walk or temporal Matérn models.
