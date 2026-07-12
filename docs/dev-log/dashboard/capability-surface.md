# drmTMB capability surface

_Generated from `capability-ledger/` by `tools/capability_ledger.py`; do not hand-edit this file._

The model surface and missing-response execution axis answer different questions. The first records what a model cell fits and what inference evidence exists. The second records whether an exact user-visible route handles missing responses. A missing-response tick never promotes the model's inference tier.

## Snapshot

- Model surface: **668 cells** across **18 routes**.
- Runtime status: **288 implemented**, **339 rejected by design**, **41 not implemented**.
- Evidence: **4 supported**, **16 inference-ready**, **44 interval-feasible**, **155 recovery-grade**.
- Missing-response board: **18 routes; 0 G0; 0 G1; 0 G2; 18 verified (G3+)**.

## Missing-response execution board

G0 = rejected; G1 = implemented; G2 = masking validated; G3 = recovery; G4 = interval feasible; G5 = inference-ready. The verified tick begins at G3.

| Route | Runtime state | Evidence gate | Work state | Next gate |
|---|---|---:|---|---|
| `gaussian` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `biv_gaussian` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `student` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `lognormal` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `gamma` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `poisson` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `nbinom2` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `zi_poisson` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `zi_nbinom2` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `beta` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `truncated_nbinom2` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `hurdle_nbinom2` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `cumulative_logit` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `beta_binomial` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `zero_one_beta` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `tweedie` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `skew_normal` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `binomial` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |

### Route-level evidence rule

Mixture routes have their own masking and recovery evidence. A zero-inflated or hurdle route never inherits a tick from its Poisson, NB2, or truncated-NB2 base family.

Each route's displayed gate and work state come from its own ledger evidence. Verified routes have passed direct sentinel mutation, residual/accounting, and named recovery audits; no route inherits a tick from a base family.

## Per-family model-surface summary

| Route | Cells | Implemented | Rejected | Not implemented | Highest evidence |
|---|---:|---:|---:|---:|---|
| `beta` | 24 | 7 | 17 | 0 | inference ready with caveats |
| `beta_binomial` | 32 | 4 | 28 | 0 | interval feasible |
| `binomial` | 12 | 2 | 10 | 0 | inference ready with caveats |
| `biv_gaussian` | 154 | 140 | 13 | 1 | supported |
| `cumulative_logit` | 13 | 3 | 10 | 0 | interval feasible |
| `gamma` | 24 | 5 | 19 | 0 | interval feasible |
| `gaussian` | 66 | 52 | 12 | 2 | supported |
| `hurdle_nbinom2` | 48 | 4 | 44 | 0 | interval feasible |
| `lognormal` | 23 | 4 | 19 | 0 | interval feasible |
| `nbinom2` | 30 | 19 | 8 | 3 | inference ready with caveats |
| `poisson` | 29 | 15 | 9 | 5 | inference ready with caveats |
| `skew_normal` | 28 | 4 | 23 | 1 | interval feasible |
| `student` | 24 | 8 | 16 | 0 | interval feasible |
| `truncated_nbinom2` | 23 | 4 | 19 | 0 | interval feasible |
| `tweedie` | 28 | 4 | 23 | 1 | interval feasible |
| `zero_one_beta` | 64 | 5 | 32 | 27 | interval feasible |
| `zi_nbinom2` | 34 | 4 | 29 | 1 | interval feasible |
| `zi_poisson` | 12 | 4 | 8 | 0 | interval feasible |

## Evidence and detailed cells

Use the generated HTML surface for filters, route anchors, claim boundaries, next gates, and direct evidence links. Machine-readable sources are `capability-ledger/cells.tsv`, `evidence.tsv`, and `transitions.tsv`.

## Per-family capability reference

This retains the original whole-package map. Its missing-response column is regenerated from the corrected 18-route ledger.

| Response | dpars | Fixed | Random (int/slope) | Structured (phylo/spatial/animal/relmat) | REML | Interval tier | Miss-response | Miss-predictor mi() |
|---|---|---|---|---|---|---|---|---|
| **gaussian** | mu, sigma | ✓ | ✓ int + ✓ slope on **mu AND sigma** (correlated/labelled blocks) | mu **&** sigma: phylo, spatial, animal, relmat (+phylo_interaction); one at a time | ✓ (Gaussian-gated; structured scope-restricted under REML) | **Inference-ready** (8 structured anchor cells + fixed recovery); highest in pkg | G3 ✓ recovery verified | ✓ **broad** impute catalogue |
| **biv_gaussian** | mu1, mu2, sigma1, sigma2, rho12 | ✓ | ✓ int + ✓ slope on mu1/mu2 and sigma1/sigma2 (biv covariance surface) | **phylo, spatial, animal, relmat** on mu location (q2); q4 all-four extends to sigma1/sigma2; one source at a time ⚑ | ✓ (phylo location **only** under REML) | **Inference-ready** (phylo/relmat q2 mean-mean corr); else recovery; pdHess caveat | G3 ✓ recovery verified | — (none) |
| **nbinom2** | mu, sigma, zi | ✓ | mu ✓ int + ✓ slope (not with zi); sigma **int only** (not with zi/mu-RE); zi — | mu **&** sigma: phylo, phylo_interaction, spatial, animal, relmat | — | **Inference-ready** (mu+sigma fixed); structured recovery | G3 ✓ recovery verified | one binary (bernoulli) |
| **poisson** | mu, zi (no sigma) | ✓ | mu ✓ int + ✓ slope (not with zi); zi fixed-only | mu: phylo, phylo_interaction, spatial, animal, relmat; **spatial also on zi** | — | **Inference-ready** (mu fixed); structured recovery | G3 ✓ recovery verified | one binary (bernoulli) |
| **beta** | mu, sigma | ✓ | mu ✓ int + ✓ slope; sigma RE rejected | **animal only** (mu int/slope, sigma int); no phylo/spatial/relmat | — | **Inference-ready** (mu+sigma fixed, **interior (0,1) only**); animal recovery | G3 ✓ recovery verified | one binary (bernoulli) |
| **binomial** | mu only (logit) | ✓ | **none** (RE not implemented) | none | — | **Inference-ready** (mu fixed) | G3 ✓ recovery verified | one binary (bernoulli) |
| **student** | mu, sigma, nu | ✓ | mu ✓ int + ✓ slope; sigma RE rejected; nu fixed | **spatial on mu** (q1); **phylo on nu** (int) only | — | Feasible/recovery (mu/sigma/nu fixed + mu RE); nu~phylo diagnostic | G3 ✓ recovery verified | — |
| **gamma** | mu, sigma (log link only) | ✓ | mu ✓ int + ✓ slope; sigma RE rejected | **relmat on mu** (int/slope) only | — | Feasible/recovery (mu match glm; no coverage sim); mu~relmat recovery | G3 ✓ recovery verified | — |
| **truncated_nbinom2** | mu, sigma, hu | ✓ | mu ✓ int + ✓ slope (**rejected when hu present**); sigma RE rejected; hu — | **relmat on hu** (int) only; none on mu/sigma | — | Feasible (mu/sigma fixed + mu RE int); slope recovery | G3 ✓ recovery verified | — |
| **hurdle_nbinom2** (=truncated_nbinom2 + hu~) | mu, sigma, hu | ✓ | inherits truncated_nbinom2 (mu int/slope, not with hu) | relmat on hu (int) | — | Feasible (mu/sigma/hu fixed); hu~relmat recovery | G3 ✓ recovery verified | — |
| **cumulative_logit** | mu only (logit) | ✓ | **none** (ordinal RE not implemented) | **phylo on mu** (int) only | — | Feasible (fixed + cutpoints); mu~phylo recovery | G3 ✓ recovery verified | — |
| **lognormal** | mu, sigma | ✓ | mu ✓ int (slope = recovery); sigma RE rejected | none | — | Feasible/recovery (mu/sigma fixed + mu RE int) | G3 ✓ recovery verified | — |
| **beta_binomial** | mu, sigma | ✓ | mu ✓ int + ✓ slope; sigma RE rejected | none | — | Feasible (mu/sigma fixed + mu RE); ≠ binomial calibration | G3 ✓ recovery verified | — |
| **skew_normal** | mu, sigma, nu | ✓ | **none** on any dpar | none | — | Feasible (mu/sigma); nu diagnostic only | G3 ✓ recovery verified | — |
| **tweedie** | mu, sigma, nu (nu int-only) | ✓ | **none** on any dpar | none | — | Feasible (all fixed) | G3 ✓ recovery verified | — |
| **zero_one_beta** | mu, sigma, zoi, coi | ✓ (fixed-only) | **none** on any dpar | none | — | Feasible (smoke-only coverage); use over beta() for exact 0/1 | G3 ✓ recovery verified | — |
| **zi_poisson** (=poisson + zi~) | mu, zi | ✓ | mu RE rejected when zi present → effectively fixed-only | zi~spatial, mu~spatial (recovery) | — | Feasible (mu/zi fixed); spatial recovery | G3 ✓ recovery verified | one binary (poisson gate) |
| **zi_nbinom2** (=nbinom2 + zi~) | mu, sigma, zi | ✓ | RE not with zi → fixed-only in zi models | mu~spatial (diagnostic only) | — | Feasible (mu/sigma/zi fixed); mu~spatial diagnostic | G3 ✓ recovery verified | one binary (nbinom2 gate) |
