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

## C17 cheap-mode recert (CI)

`ubuntu-latest` failed `mc-0568` because `R/drmTMB.R` / `src/drmTMB.cpp`
moved while the authenticated model-15 fingerprint did not. Re-ran
`tools/run-lane-c-c17c1-c14-model15-compatibility.R` against
`e394aaf85`. 12/12 `fit_ok`. `mean_tau_relative_error` is
bit-identical to the beta-binomial receipt
(0.0990017646754622 / 0.166085237666842 / 0.0613064198360253).
`source_fingerprint` left alone. Receipt:
`docs/dev-log/implementation-recovery/2026-08-27-s6-a7-student-c17/`.

## Not this PR

Shared-leaf ABI, student × gaussian, k=2, `impute_joint`, zi-*,
capability `covered`. drmSEM consumer is a follow-up after merge.
