# Fixed-tree intercept calibration diagnostic

## Trigger

The retained G13 campaign leaves its fixed-effect interval claim unqualified:
P1--P3 intercept coverage is 0.870, 0.922, and 0.895 while all six slope rows
meet the predeclared criteria. The corrected truth registry, endpoint-centering
check, and independent dense-profile comparison do not explain this result.

## Question

Does the intercept failure arise only after averaging over newly generated
phylogenies, or does it remain when the phylogeny is held fixed and only random
effects, predictors, temporal deviations, and residuals are regenerated?

## Bounded pre-run

Use the frozen P1, P2, and P3 designs, one deterministic tree per cell, and
five independent response seeds per tree. Retain both `tmbprofile` fast and
default intercept profiles, the selected estimate, convergence/Hessian status,
and elapsed time. Compare endpoint differences to the independent dense profile
for one selected fixture per cell.

The G10 measurement was 335 seconds for 20 fits and all three fast profiles
(about 17 seconds per data set). Fifteen fast-profile fits therefore estimate
at about 4--7 CPU minutes. The pre-run stays below 30 minutes at one CPU and
4 GiB, and uses Totoro durable storage. It is diagnostic only: five replicates
cannot establish coverage or alter G13.

## Decision rule

- If fast and default endpoints materially differ, investigate profile controls
  before any wider calibration.
- If they agree and fixed-tree intercept errors remain heavy-tailed, investigate
  nuisance variance-component uncertainty and alternative interval targets.
- If they agree and fixed-tree errors are near nominal, a separately authorized
  conditional-tree calibration campaign is needed before revising the public
  scope.

No temporal structure after OU may begin from this diagnostic. The original G12
archives and G13 results remain immutable.
