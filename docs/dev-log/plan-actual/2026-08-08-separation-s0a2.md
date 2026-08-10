# Separation S0-A2 plan versus actual

Final verdict: NOT-DONE. The corrected binomial cone slice produced a valid, independently reproduced retained STOP.

| Planned item | Actual result | Disposition |
|---|---|---|
| Continue in the isolated owner-released Lane S worktree | Preflight found no active foreign lane or process using the worktree | Matched |
| Preserve the original S0 STOP and reviewed S0-A2 contract | Prior artifacts remained unchanged; new files are additive | Matched |
| Use the exact isolated R runtime and maintained detector | drmTMB 0.6.0, detectseparation 0.4.0, ROI/lpsolve stack, brglm2 1.1.0, TMB 1.9.21, R 4.6.0 recorded | Matched |
| Resolve full-rank binomial geometry with the normalized improving cone and strict-margin checks | Separated fixtures resolved, but overlap returned solver status 0 with residual 1 and was classified unresolved | STOP, scientifically correct fail-closed behavior |
| Check coefficient directions by feasibility, not a single arbitrary ray | Shifted, mirrored, centered, quasi-complete, and intercept-only direction gates passed | Partial match |
| Compare detectseparation classifications | Declared separated fixtures agreed; overlap completion claim withheld because the independent cone certificate failed | Partial evidence only |
| Evaluate exact-source drmTMB objective rays | 121 compiled/direct objective-ray gate rows passed | Matched, but insufficient for overall PASS |
| Compare glm and brglm2 | glm evidence recorded; ten brglm2 calls failed because type = AS_mean was rejected | Comparator deviation retained; non-gating |
| Run exact-row controls only after the core passes | Core failed; controls recorded not_run_after_core_failure | Matched stop rule |
| Mechanically verify hashes, schema, counts, rerun, and file fence | Fresh Luna workspace-write verifier reproduced exit 1 and a byte-identical TSV; first read-only attempt was retained as invalid | Matched after one infrastructure correction |
| Run one D-43 completion panel | Noether, Fisher, and Rose returned NOT-DONE (3/3) | Milestone withheld |
| Audit ultra-plan routing | Retained receipts were 2 Luna, 2 Terra, 1 Sol; the date-wide audit failed on unrelated combined-session composition and compaction counts | Lane routing matched; global audit failure retained |
| Stop before hurdle and S1 | No hurdle or S1 stage rows exist | Matched |
| Make no package, public, release, PR, push, or merge changes | Only four evidence/receipt files belong to this slice; no prohibited surface changed | Matched |

## Material deviations

The core scientific deviation is the LP backend contradiction on the overlap negative control. It prevents the intended exact finite-MLE existence result. The brglm2 interface mismatch removes that optional comparator evidence but did not cause the gate failure. The first verifier's read-only environment could not rerun the harness; a fresh narrowly writable verifier resolved that mechanical limitation without modifying retained results.

## Claim boundary

The evidence supports only partial consistency for the declared separated full-rank fixed-design binomial fixtures and their objective recession directions. It does not establish a complete fixed-design detector contract, an overlap certificate, a hurdle result, GLMM theory, or any drmTMB package capability.

## Handoff state

Stop here. Any further correction needs a new explicit contract for a trustworthy overlap infeasibility certificate and a version-correct optional brglm2 comparator. It must not automatically proceed to controls, hurdle, S1, or package integration.
