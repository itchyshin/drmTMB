# Structured Coverage Unblock Pilots

## Purpose

This artifact banks SR064-SR066 as labelled pilot runs. It follows the ADEMP
framing of Morris, White, and Crowther (2019) and the simulation-reporting
discipline of Williams et al. (2024): aim, data-generating mechanism,
estimands, methods, and performance measure are explicit.

## A — Aims

The primary aim is to verify that q1, q2, and q4 structured random-effect
coverage rows can be generated with target-specific fit, Hessian, interval, and
coverage accounting.

The secondary aim is to keep q4 diagnostic outcomes visible rather than turning
failed or unavailable intervals into a coverage claim.

## D — Data-Generating Mechanism

All pilots use small Gaussian phylogenetic synthetic data generated on a random
coalescent tree:

- q1: one response with a phylogenetic location random intercept;
- q2: two responses with a shared q2 phylogenetic location block;
- q4: two responses with phylogenetic fields on `mu1`, `mu2`, `sigma1`, and
  `sigma2`.

The condition count is deliberately tiny. The pilot is a pipeline and status
contract check, not a calibrated Monte Carlo study.

## E — Estimands

The estimands are the true structured SDs used in the data-generating process.
Each fitted row compares the true SD with the fitted Wald interval when that
interval is finite and available. Boundary intervals and unavailable intervals
are counted separately from finite intervals.

## M — Methods

Each cell is fitted with native `drmTMB` / TMB maximum likelihood. Intervals use
the existing Wald route because this pilot is a fast status gate.

## P — Performance Measures

The summary table reports attempted fits, successful fits, converged fits,
positive-Hessian fits, interval rows, finite interval rows, empirical coverage
for finite intervals, and binomial MCSE for that finite-interval coverage.

## Pilot Outcome

The corrected summary is intentionally diagnostic:

- q1 had three successful, converged, positive-Hessian fits; three interval
  rows; one finite interval; and that one finite interval covered the true SD.
- q2 had six successful and converged fit-target rows, but no positive-Hessian
  fits and no finite intervals.
- q4 had eight fit-target rows, but no converged fits, no positive-Hessian
  fits, and no finite intervals.

## Interpretation

This artifact banks that SR064-SR066 were run as labelled pilots with
target-specific failure accounting. It does not bank interval reliability, q4
coverage, Ayumi-scale coverage, native q4 REML, R-via-Julia bridge support,
non-Gaussian REML, or AI-REML.

## Files

- `run-pilot.R`: repeatable pilot runner.
- `tables/structured-coverage-pilot-rows.csv`: per-target rows.
- `tables/structured-coverage-pilot-summary.csv`: cell-level summary.
