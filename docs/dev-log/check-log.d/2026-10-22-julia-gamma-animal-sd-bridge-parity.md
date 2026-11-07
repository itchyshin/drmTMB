# 2026-10-22: Gamma animal SD R-to-Julia bridge parity

The bridge now maps one Gamma q1 animal-intercept direct-SD formula to the
Julia candidate's fitted `sd` block and avoids adding an extra synthetic
`resd` label. The matching rule requires provider, group, parameter, and a
unique coefficient match; an ambiguous q2 animal term remains a `resd` block.

The focused `julia-gamma-sd` filter passed with four live Julia bridge tests,
including one same-data native TMB/Julia synthetic comparison using a
unit-diagonal supplied covariance. The neighbouring `julia-structured` filter
passed with one live test. The no-Julia run also passed its label tests and
skipped the four live cases as expected. This is one candidate point-parity
fixture, not broad structured parity or interval calibration.

GitHub issue lookup was attempted but the API connection to `api.github.com`
failed. Site and full package checks were not run. Details:
`docs/dev-log/after-task/2026-10-22-julia-gamma-animal-sd-bridge-parity.md`.
