# Native Beta q1 structured-intercept SD check fragment

2026-10-28, worktree `codex/general-sd-regression`. Scoped R admission change:
Beta relmat K/Q and coordinate spatial q1 intercepts now accept a group-level
SD predictor; existing q2 routes retain their admission. The exact pre-fit
contract is `pre-fit-alignment.md`.

Commands and outcomes: assembly-only evaluation, 13 passed (`assembly.log`);
`devtools::test(filter="beta-structured-intercept-q1-sd-regression",
reporter="summary", stop_on_failure=TRUE)`, 53.34 s and green (`focused.log`);
`devtools::test(filter="beta-(structured-intercept-q1|relmat-q2|spatial-q2)-sd-regression",
reporter="summary", stop_on_failure=TRUE)`, 129.80 s and 167 success markers
(`targeted.log`). Both test commands used one BLAS and OpenMP thread. The
synthetic example converged at SD slope 0.5086127 in 10.76 s (`example.log`).
No live Julia test or coverage run was performed.

The frozen scalar oracle compares Laplace likelihood and conditional predictor
with absolute 1e-4 limits, latent gradient below 1e-5, and finite-difference
score/Hessian below 1e-4/2e-4. All q1 and neighboring q2 assertions passed.
The extracted prior builder was run in an isolated R environment; its q1
rejections are in `reconstructed-before.log`. The older `red.log` is narrative,
not raw stdout. `git diff --check` passed on the scoped source/test paths.
