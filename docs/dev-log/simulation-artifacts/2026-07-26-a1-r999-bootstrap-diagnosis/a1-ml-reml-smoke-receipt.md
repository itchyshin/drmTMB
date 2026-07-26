# Scalar A1 ML-versus-REML smoke receipt

## Scope

This is plumbing evidence only.  It is not coverage evidence, does not identify
the cause of the prior profile asymmetry, and does not authorize a Totoro run.

## Command and result

On 2026-07-26, the runner executed one deterministic attempt in each frozen
cell under both estimators, then analysed the six retained rows:

```sh
for cell in 1 2 3; do
  R_PROFILE_USER=/dev/null Rscript --no-init-file a1_ml_reml_smoke.R "$cell" 1 <temporary-output-root>
done
R_PROFILE_USER=/dev/null Rscript --no-init-file analyse_a1_ml_reml_smoke.R <temporary-output-root>
```

All six fits produced a valid finite profile row and retained one ML plus one
REML row for each generated dataset.  Each profile covered the truth in this
single smoke attempt; no zero lower profile endpoint occurred.  These outcomes
are not coverage proportions and must not be interpreted as interval
calibration.

## Oracle gate outcome

The external lme4 oracle passed all ML fixture rows and the REML `g = 50` row.
The REML profile endpoint comparisons failed at `g = 10` and `g = 25`, despite
matching likelihoods and point estimates.  The largest upper-endpoint delta was
0.0798 at `g = 10`, exceeding its 0.0112 tolerance.  Per the frozen protocol,
this blocks a full campaign and requires a separate REML-profile geometry or
oracle investigation before the packet can be approved.
