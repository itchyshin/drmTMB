# Coefficient label parity: pre-run contract

Root owns this new evidence directory and new diagnostic tools. Read-only
source audit until name mismatches are reproduced and recovery refs inspected.
No edits to denied Gaussian engine files or foreign ZOB changes.

CHECK: ordinary Rscript fits a small Gaussian model with quadratic, factor and
interaction terms; compare exported names to stats::model.matrix and attempt
those exact names through public confint. Keep errors.
EXPECT: either exact public name/selector agreement or retained per-target
errors exposing a repairable contract gap. This is a diagnostic, not a pass
gate, speed comparison, coverage study or whole-programme qualification.

Estimate: under one minute, 120-second watchdog; one Julia and BLAS thread.

## Implementation and final verification contract

Version `bridge_formula_labels_v1` carries public coefficient/covariance labels,
ordered raw coefficient labels, and an exact public-to-raw map. Preserve all
numerical values, covariance coordinates and fitting choices. Legacy objects
without metadata retain their established spelling. Corrupt versioned metadata
must fail before Julia startup; no punctuation-based guessing is permitted.

The final public runner registers six model-matrix cases (quadratic, punctuated
factor, two-factor interaction, no intercept, declared factor levels, transforms)
and three targets, each through public R and the direct Julia primitive for
profile and bootstrap. Missing or failed cases stay in the denominator. Compare
point estimates within1e-5 and Gaussian ML log likelihood within1e-7 to an
independent least-squares calculation; compare profile endpoints within1e-5 to
an exact Gaussian LR oracle. Seeded bridge/direct bootstrap endpoints must match
within1e-10, with all six refits recorded. Six refits test dispatch, not coverage.

Pre-run: all six R matrices have full column rank (96rows, respectively7/6/9/6/6/5
columns). Estimate under two minutes including startup,180second watchdog. Run
only after source freeze. Save JSON/RDS/log, source manifests and git revisions;
any changed source or failed numerical/name check makes the run fail.

Source review found and tests reproduced generated-column overwrite (Julia
collision-red001:6pass7fail1dimensionerror). Pure R RED missinghelper is only a
contract test; the actual user-facing label failure is probe001. R green004 had
an invalid synthetic predictor matrix; green005 differed only in vector names.
Both are retained. Corrected green006 passes34checks including a full unequal
covariance matrix, punctuation-preserving prediction and raw dispatch before
startup. Rose approved that bounded R adapter; live integration remains pending.

## Review expansion before public004

Add four cases without removing the original six: reversed two-factor
interaction, unary-plus arithmetic, explicitly parenthesized arithmetic and
a decimal-spelled integer exponent. Compare unique coefficient names as a
complete set and compare numerical coefficients by those names. The source
must preserve its original coefficient/V coordinate order; matching R's textual
enumeration must never relabel or permute only one numerical axis. Native and
Julia order remain visible in the receipt. This replaces the overly strict
positional-name check, not the numerical tolerance or any required case.

public002 retained all six cases and twelve inference operations: four cases
passed, two failed only on interaction name spelling, and all twelve inference
operations passed their bounded comparisons. public003 failed during startup
before model evidence could be saved; its raw log is retained. The runner now
also saves setup failures when runtime metadata is unavailable. Independent
startup001 succeeded in13.62seconds with existing Julia cache access.

The final denominator is ten point-model cases plus twelve inference operations.
Estimate one minute; retain the180second limit. R pure green007 passes36checks,
including newdata far from the training range using the retained scale/poly
bases and a deliberately rebuilt-basis comparator that disagrees.

## Covariance review expansion before public005

Keep the same ten models and twelve inference operations. Retain each complete
coefficient vector and covariance matrix, including the primitive bridge values
before R construction. Require exact transport identity and coefficient axes.
Independently rebuild the Gaussian observed Hessian at the retained mean and
log-SD coefficients and compare its inverse to the named covariance matrix
within1e-7 absolute error. The mean/log-SD cross derivative is
`2 * crossprod(X, y-X%*%beta) / sigma^2`; the log-SD second derivative is
`2 * RSS / sigma^2`. This catches numerical-axis errors without another fit.
Add changed covariance, reordered covariance and changed primitive coefficient
negative controls to the previous eight damaged receipts (eleven total).

public004 passed all ten means/loglik/name checks and twelve inference
operations in42.486seconds but did not retain these covariance arrays. Keep it
as bounded historical evidence, not covariance certification. The source
review also found numeric-token spelling at scientific-notation boundaries;
the final source must pass the added exact native-label fixtures.

## Final review expansion before public006

Anchor the retained full coefficient vector to the independently checked mean
coefficients and likelihood. Add two coherent-damage controls that change a
mean or log-SD coordinate and recompute its covariance; unchanged standalone
point summaries must not conceal a changed full fit. The checker now has
thirteen damaged receipts. Tolerances and all ten cases remain unchanged.

public005 passed its existing ten-model covariance/transport checks and twelve
inference operations in43.561seconds. Its raw/full arrays are retained, but the
stronger parameter-link checks and final formatter source still need re-running.
Julia combined001 had301passing assertions and one real regression: nested
`log1p(1 + I(x1^2))` lost admission in label reconstruction. Preserve that error.
A generated317-value R numeric-label fixture (R4.6.0, scipen0) replaces isolated
threshold assumptions with fixed/scientific notation, precision and magnitude
coverage. No model is fitted to generate those strings.

## Nested-expression expansion before public007

public006 passed all ten point cases and twelve inference operations in
43.706seconds; Rose independently ran its checker and thirteen damage controls.
combined002 passed952assertions and the new reader example in71.606seconds with
105unchanged inputs. These remain valid bounded historical results.

Further source review found lost parentheses in nested scalar-function labels.
The ten-expression `native-nested-labels.tsv` records both native R names and
eight evaluated rows, including necessary and redundant parentheses, powers,
subtraction, denominators and multiple materialised atoms. It also exposed
formula-power expansion being applied inside scalar functions. Repair that
context while retaining the existing formula-level expansion/refusal tests.
The final public denominator grows to twelve point cases by adding nested
precedence and redundant-parenthesis cases; no original case is removed. The
twelve inference operations and all tolerances are unchanged. Estimate remains
under two minutes per run, with the180second cap.

## Scalar-provenance expansion before public008

public007 passed twelve point cases and twelve inference operations in44.462s;
its checker rejected thirteen damaged receipts. combined004 passed987assertions
in76.634s with106unchanged inputs. Rose withheld finalapproval because nested
scale() still loses parentheses and scale materialization ignores outer source
scope. A separate native-scalar-labels.tsv now adds twelve generated name/value
references spanning scale, mixed scale/I, plain scalar functions, scientific
numbers and unaryminus. The public denominator becomes fifteen point cases
(nested_scale, mixed_scalar, scalar_plain added); all original cases, twelve
inference operations and declared tolerances are retained. No campaign is run.

Rose approved the per-parameter provenance architecture but found that the new
scanner preempted previously admitted ifelse comparison/comma syntax. Preserve
that admission; native-conditional-labels.tsv adds four independent label/value
rows. Public008 now has sixteen point cases (conditional_scalar added), with
the same twelve inference operations and unchanged numerical tolerances.

The final lexical neighbour audit found unary ! emitted with binary spacing.
The native conditional grid grows4→13 rows, preserving the initial four-row
version; added rows exercise nondegenerate branches, !, !=, &, |, >=, == and
nested negation/calls. Public008 includes negated_scalar as its seventeenth
point case; no earlier case or inference operation is removed. Runtime estimate
remains under two minutes, with180second cap.
