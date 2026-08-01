# Plan versus actual: B3 q6 target-level promotion

## Planned claim

Promote exactly `mc-0102`, `mc-0124`, `mc-0146`, and `mc-0168` to targetwise `interval_feasible`; keep all four linked whole-q6 cells `planned`; run no profile, retry, substitute, coverage, API, or compute work.

## Phase reconciliation

| Phase | Planned | Actual |
| --- | --- | --- |
| Fresh lane | Clean branch from current `origin/main` | Created at `402aca4c`; refreshed to `5ff94d86` after Lane C merged during B3 |
| Evidence revalidation | E0, B2 exit, serial receipt audit, exact four hashes | PASS in isolated frozen snapshot; 23 immutable authorization/result/audit-runner files remain byte-identical; the focused test adds a package-build skip guard |
| Compatibility review | Current formula/profile/extractor equivalence | Noether PASS; response-SD semantics unchanged |
| Target split | Four-row sidecar; whole q6 remains planned | Implemented and fail-closed in Mission Control validator/tests |
| Owner checkpoint | Exact four-cell packet before write | Delivered; exact authority `approve B3 four-cell promotion` received |
| Canonical write | Four cells, four evidence rows, four transitions | Implemented; no fifth cell changed |
| Generation | Capability and Mission Control after source transition | Capability outputs regenerated; sidecar loaded and rendered after authorization |
| Completion panel | Fresh Fisher, Noether, Rose | 3/3 PASS on the refreshed `5ff94d86` state; every broader claim withheld |
| Closeout | After-task report and recovery checkpoint | Completed in this lane |

## Deviations

The historical authorization’s `latent_log_sd` truth-scale label was found to be wrong. B3 preserved the immutable authorization and added an explicit `response_sd` correction in the canonical packet and validator.

PR #879's first Ubuntu check found that the focused development-tool audit test could not run from a built source package because top-level `tools/` is intentionally excluded. The test now keeps its six source-checkout assertions and skips only in that package-build context, matching existing repository practice.

The global Mission Control and q-series commands were already red on 15 missing absolute DRM.jl worktree paths. B3 did not repair those foreign rows. All B3-specific checks pass, but the global baseline remains disclosed rather than reported green.

The work exceeded the initial simple-write path because `origin/main` advanced by 26 Lane C commits during execution. The final diff is reconciled to the refreshed base and preserves every Lane C promotion.

## Scope audit

No profiles were rerun. No retained attempt was retried or substituted. No q12, E0, K=12, Lane A/C, missing-response, package API, R/C++ implementation, or remote-compute surface was changed.
