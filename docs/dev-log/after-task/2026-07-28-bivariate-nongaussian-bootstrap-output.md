# Bivariate non-Gaussian bootstrap-output repair

## Goal

Make the direct lognormal `rho12` interval example readable on the pkgdown
article without concealing the bootstrap diagnostic.

## Changed

- Suppressed repeated bootstrap optimiser warnings and messages in the rendered
  vignette chunk only.
- Replaced the raw interval table with one explicit retained-refit diagnostic.
- Replaced the clipped, sparse forest plot with a labelled confidence-eye
  display. Its caption says explicitly that the taper is a visual interval cue,
  not a sampling distribution, likelihood, or posterior.
- Hid plotting code from article readers while retaining it in source.

## Evidence and boundary

An installed-package render completed successfully. The rendered page contains
one dynamic retained-refit diagnostic and no repeated optimiser chatter. This
is presentation-only: it changes no estimator, bootstrap procedure, interval
calculation, capability status, or public inference claim.
