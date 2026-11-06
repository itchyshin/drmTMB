# Independent review: shared Julia test namespace repair

Verdict: no blocking error found in this bounded test-only repair. This accepts the alias correction and its stated scope. It does not certify the full quadrature assertions or the new CI run.

## Change inspected

The patch removes `const D = Distributions` from `test/test_iid_sd_quadrature_accuracy.jl` and changes all 29 `D.` references to `Distributions.`. It retains `import Distributions`. The header now describes the existing assertions: absolute log-likelihood error below `1e-4` at fitted and +/-0.8 SD-intercept shifts, and below `1e-2` at the +2.0 stress shift. The assertions themselves remain at lines 306 and 309.

The saved before-file matches the current Git HEAD version. A separate text comparison showed that the after-file is exactly the before-file with the alias declaration removed, its dotted references qualified, and comment-only lines disregarded. No fixture, seed, fit call, density, assertion or tolerance changed. Before SHA-256: `2e65f5a6ba96b056031a62dd41623694c7f80873c25f64f2e288e5696bcf3473`. After SHA-256: `73884b13e649c3bdab0f9b51bfdb08da72095dd089a96bcd78cedac059849d04`.

## Evidence inspected

- `julia-namespace-red-110-final.log` reproduces `invalid redefinition of constant Main.D` at the old line 23.
- `julia-namespace-green-110.log` records three namespace assertions passing after including the actual repaired file while `Main.D` is already `DRModels`.
- The repro script uses the pre-existing `DRM_QUAD_EXPLORE` guard in an isolated process. It explicitly prints that full quadrature fit assertions were not run by this smoke. That guard was not added or broadened by the patch.
- `julia-namespace-ast-check.log` records three passing structural checks. The script compares the whole parsed file after normalizing the alias and line nodes; it also proves a deliberately changed tolerance breaks equality.

The namespace smoke and AST check support different claims. The smoke demonstrates that this include no longer tries to replace the existing module constant. The structural check, corroborated by the independent text comparison, supports unchanged test expressions. Neither reports a successful numerical quadrature campaign.

## Neighbour and scope checks

All eight remaining top-level `const D` declarations under `test/` bind `DRModels`. The edited file's other three top-level names, `_SPECS`, `_ROUTES` and `_SEEDS`, each have one constant declaration in the test tree. The only `DRM_QUAD_EXPLORE` occurrence found in the inspected test/workflow tree is the existing guard in this file. No workflow change disables its full assertions.

`git diff --name-only` shows only `test/test_iid_sd_quadrature_accuracy.jl`. The foreign-owned `test/test_binomial_sd_public.jl` has no diff. Julia engine source is unchanged.

## Remaining acceptance

The new full CI run must execute the ordinary unguarded suite and pass on its exact accepted head. The isolated Julia 1.13 namespace result was still pending when this review was requested; no result is inferred here. Existing source-bound scientific and article receipts do not become full-suite CI receipts from this namespace check.

No source edit, Julia test, fit, CI command, commit or merge was performed by this reviewer. This review does NOT extend the first delivery to G5 calibration, D-342 REML policy or the wider family/provider programme.


## Julia 1.13 follow-up

Inspected `julia-namespace-green-113.log` after its process completed. It records the repaired file loaded from the isolated worktree and the same three namespace assertions passing on Julia 1.13. The log ends with `NAMESPACE_ONLY_PASS; full quadrature fit assertions not run by this smoke`. Its SHA-256 is `f4522c9ad7050e0b50cbaf379a27651c7c4596cc418bb63a9255e1382f62ed34`.

This supplies the previously pending second-version namespace smoke. The bounded no-blocker verdict is unchanged. Full unguarded quadrature assertions and exact-head CI remain required; neither is inferred from these three assertions. The parent is separately recording the integration update in the Julia documentation closeout files. No new test or other execution was performed by this reviewer.
