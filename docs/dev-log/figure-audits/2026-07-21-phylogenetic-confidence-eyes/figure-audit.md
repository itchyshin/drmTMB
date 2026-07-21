# Figure audit: phylogenetic Confidence Eyes

## Purpose

The Gaussian phylogenetic example should let readers compare the fitted
phylogenetic and residual standard deviations while seeing the uncertainty
around each estimate. Because the interval is part of the scientific message,
the project Confidence Eye convention applies.

## Audit table

| Figure | Source object | Visual data grain | Uncertainty source | Reader risk | Verdict and fix |
|---|---|---|---|---|---|
| `gaussian-figure` | exact name-matched rows from `fit$sdpars$mu`, `sigma(fit)`, and `confint(fit, parm = "variance_components")` | two response-scale SD estimates from one simulated Gaussian fit | finite default 95% Wald regions, constructed on the log-SD scale and back-transformed | an ordinary interval bar hides the package's preferred Confidence Eye convention; an eye can also be mistaken for a posterior distribution if it is left unexplained | PASS after replacing bars with pale Confidence Eyes, retaining hollow raw-estimate markers, stating the frequentist interpretation, and explaining the small shift caused by the default phylogenetic interval correction |

## Visual and statistical checks

- Exact parameter-name matching and fit-within-interval assertions from the
  preceding repair remain in place.
- Both eyes terminate at their paired finite 95% endpoints; the x-axis begins
  at zero and remains on the response-scale SD.
- The pale shape is described as a compatibility display, not a posterior
  density.
- The raw fitted SD remains visible as a hollow circle. The phylogenetic point
  is not forced onto the eye peak because the default small-sample correction
  shifts the interval centre.
- Direct labels remove the need for a legend. The Okabe-Ito blue remains
  legible in colour and the geometry remains interpretable without colour.
- The source PNG and 390-pixel rendering were inspected directly and are
  retained beside this audit.
- The expanded capability table uses a 760-pixel minimum width inside a
  horizontally scrollable container. The mobile viewport no longer breaks
  technical terms into unreadable fragments.

## Correction to the preceding audit

The preceding Tufte-led repair correctly fixed the interval-row mismatch, but
its flat forest display missed the project skill's hard gate: when uncertainty
is the main message, Confidence Eyes are preferred. The user identified that
miss. This follow-up retains the sound name-matching repair while correcting
the visual language.

## Residual limitation

This remains one illustrative fit. The eye summarizes the returned interval;
it does not establish coverage, provide a variance-boundary test, or represent
a Bayesian posterior.
