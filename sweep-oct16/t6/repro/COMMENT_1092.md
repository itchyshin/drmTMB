## sweep-oct16 t6: still invlink(Xβ), RE = 0, matching drmTMB newdata

Lane t6 on pin `f71b292`. For every (1|g) cell that both engines fitted (gaussian, student, gamma, poisson, nbinom2, binomial, beta), `predict(fit, newdata)` / `predict_parameters(..., type = :response)` equals drmTMB `predict(newdata)` to ≤ 2e-9 on the shared 3-row grid (population-level Xβ, RE set to 0). The docstring still says "integrated out".

**Expected (this issue):** reword to "random / structured effects set to zero".
**Actual:** wording unchanged at `f71b292`; numerical behaviour matches drmTMB (good for the twin) and does *not* integrate RE on a nonlinear link.

### Source
Simulated RE cells, seeds `20261016600+`. CSVs under `sweep-oct16/t6/data/*_re.csv`. drmTMB `ca3ddefa5`, DRModels.jl `f71b292`.

No new code defect beyond the docs claim already filed here.

Refs #1092. Not closing.
