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
R_PROFILE_USER=/dev/null Rscript --no-init-file analyse_a1_ml_reml_smoke.R <temporary-output-root> 1
```

All six fits produced a valid finite profile row and retained one ML plus one
REML row for each generated dataset.  Each profile covered the truth in this
single smoke attempt; no zero lower profile endpoint occurred.  These outcomes
are not coverage proportions and must not be interpreted as interval
calibration.

## Oracle gate outcome

This smoke was re-run after the six-row oracle passed.  `lme4` validates
drmTMB's ML endpoint profiles and ML/REML point-estimate/likelihood parity;
the matched direct restricted-likelihood profile validates the REML endpoints.
All six deterministic oracle rows pass.  The remaining full-campaign gate is
written compute approval, not an unresolved local oracle discrepancy.
