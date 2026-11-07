# Next design: targeted random-effect SD and correlation priors

User direction, 6 November 2026: after the current Gaussian random-intercept coefficient-prior slice, plan priors for specific random-effect parameters in complex models with multiple blocks. Blanket application should be optional and explicit. This extension is outside the current implementation.

Use SD/correlation target classes with unique block identity, distributional parameter, grouping factor, and coefficient or correlation-block selection. Group alone is insufficient for repeated grouping terms. Preview exact targets and scales; reject ambiguous, empty and overlapping selections. Default fits have no added priors. SDs may have different prior scales. Correlation priors must preserve a valid whole covariance matrix.

Stages: one iid block SD target; correlated intercept/slope SD targets; correlation-block priors; then supported structured blocks. Each stage needs fresh equations, selectors and independent numerical checks. Decide natural-versus-transformed density/MAP coordinates and any Jacobian convention explicitly. A prior on positive SD differs from one on log-SD regression coefficients.

Boundary validation includes truly zero and weakly identified variance components, several prior strengths, objective/derivative checks and sensitivity summaries. An SD prior discouraging zero can stabilize computation while forcing an absent component away from zero; convergence does not establish data support.

The current glmmTMB manual describes SD/correlation selectors and flags repeated-group ambiguity (https://glmmtmb.r-universe.dev/glmmTMB/doc/manual.html). Ben Bolker's vignette includes a gamma SD prior for a singular-fit example (https://glmmtmb.github.io/glmmTMB/articles/priors.html). These inform the future design without qualifying every structure or correlation prior.
