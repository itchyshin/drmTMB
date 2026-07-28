# Bivariate non-Gaussian confidence-eye audit

## Reader task

Compare the Wald, profile, and full-refit bootstrap 95% intervals for the
direct log-residual `rho12` in the penguin model, while seeing the retained
bootstrap fraction rather than mistaking it for hidden precision.

## Disposition

| Figure | Intended evidence | Previous failure | Repair |
|---|---|---|---|
| `penguin-intervals` | One fitted association and three calculated intervals | Repeated warnings, raw console table, visible plotting code, clipped bootstrap label, and excess whitespace | Suppress repeated warnings, retain an explicit diagnostic, hide redundant code/table, and use labelled confidence eyes. |

Florence: the former display did not fit its third label and made a simple
comparison visually awkward.  The new panel uses a stable zero reference,
direct labels, one point estimate per interval, and sufficient right margin for
the retained-refit note.

Tufte: remove console debris and redundant ink; leave the numerical interval,
point, and diagnostic label.

Fisher: an eye-shaped interval can imply a probability density.  The caption
therefore declares the taper a visual interval cue only, not a likelihood,
sampling density, or posterior distribution.

Pat: failed bootstrap refits remain legible in a single plain-language
diagnostic rather than being repeated dozens of times.

## Boundary

This is presentation-only: it changes no estimator, bootstrap, interval,
capability status, or inference claim.
