# 2026-10-18: Bernoulli correlated q2 review repairs

The independent review identified unstable Julia `sqrt(1 - tanh(eta)^2)`,
missing native TMB fits for partial SD targets, and missing Julia slope-only
bootstrap-refit coverage. Julia now computes the innovation with a stable
sech expression in both the likelihood and marginal simulator. The focused
Julia suite passed 105 assertions, including a finite objective and gradient
at Fisher-z 10, a simulator check at Fisher-z 20, and slope-only bootstrap
refitting. The focused native correlated-SD test file passed, including
intercept-only and slope-only TMB fits and covariance checks. No interval
calibration was performed.

At Fisher-z 20 the Julia quadrature objective is still non-finite, so the
likelihood boundary remains unresolved even though the simulator's innovation
stays nonzero. Canonical formula and likelihood design docs remain to be
reconciled after review of their active ref diffs; a bounded candidate contract
is recorded in `general-sd-regression/bernoulli-correlated-q2-contract.md`.
The report structure validator passed; its final acceptance-ledger check exited
1 because nine general-programme gates remain open. Live R-to-Julia bridge and
save/reload parity for correlated q2 also remain untested.
