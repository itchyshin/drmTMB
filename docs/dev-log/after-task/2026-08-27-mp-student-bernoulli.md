# After Task: student × Bernoulli `has_mi` (`mp-student-bernoulli`)

**Lane.** `cursor/lane-s6-student-mi` at
`~/local-scratch/lanes/drmTMB-s6-student-mi`. Isolated from
family-gate and the nbinom2 sibling.
**Issue.** [#962](https://github.com/itchyshin/drmTMB/issues/962) hard
case. Shinichi authorized parallel work.

## Design decision

Do **not** extend `drm_response_log_density`. Extract
`drm_student_log_density(y, mu, log_sigma, eta_nu)` and clone the
lognormal identity-`μ` Bernoulli 2-point sum. Recorded in
`LOOP/notes/A7-student-nu-abi.md` (Gauss self-check included).
`A7-post-lognormal-queue.md` said WAIT on `nu`; this cell ships
without the ABI change that wait was protecting.

## What landed

- C++ helper + `model_type == 3` `has_mi && mi_family == 1`
- R `impute=` on `drm_build_student_ls_spec`; allow-list last
- Tests, ledger `mp-student-bernoulli` (G3, capability stays partial)
- NEWS

## Not this PR

Shared-leaf ABI, student × gaussian, k=2, `impute_joint`, zi-*,
drmSEM consumer / capability `covered`.
