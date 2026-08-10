# Lane S S0 — plan versus actual reconciliation

## Basis and outcome

This reconciliation covers the six quarantined S0 artifacts, the retained routing receipts, the current worktree state, and the after-task structural check.  The exact worktree base is `b441227fa0e11f9ab4347fc963266801cfb75a5f`; `git worktree list` contained **22** entries.  The pre-M0 file fence contained only the six S0 artifacts as untracked work: no tracked package, test, public-documentation, metadata, release, PR, or merge edit was present.

**Final verdict: S0 is NOT-DONE.**  The retained STOP is valid and reproducible, but it is not a PASS and does not authorize S1.

## Compact actuals

| Plan row | Planned condition | Actual, verified | Reconciliation |
|---|---|---|---|
| G0 | Recycle one owner-released clean worktree; do not create worktree 23 | Recycled worktree at the stated base; count remained 22. | **Match** |
| R0 | Luna recon | Luna-medium receipt mapped the narrow fit surfaces and dependencies. Its first isolated R invocation could not make a temporary file; the parent reran the probe with `TMPDIR=/private/tmp` and an explicit library path. | **Drift — R0 / Luna (Ebbinghaus):** initial R/temp probe was inconclusive and its filesystem fallback over-scanned package locations. **Adaptive correction:** explicit temporary and library routing restored a bounded dependency probe. |
| S0-A | Terra-high symbolic/fixture contract | Terra-high receipt exists. It froze the full-rank `mu_complete` intercept as finite. The LP oracle later returned `-Inf`. | **Drift — S0-A / Noether:** the coordinate-specific finite-intercept truth was not invariant over the separating cone. The retained failure, rather than a rewrite, is correct. |
| S0-B | Terra-high dependency setup, harness, deterministic binomial run | Terra-high receipt exists. `detectseparation 0.4.0` was installed from retained source tarball (`SHA-256 339d4384735934466826812c2a8ece689e03b0d5d620a3cbe1602cb9f35a59de`), with isolated CRAN macOS binary LP dependencies after local source compilation hit missing Fortran runtime paths. Exact-source `drmTMB 0.6.0` was built into `/private/tmp/drmTMB-separation-s0-pkglib`. Final TSV: 82 rows, 31 gates (30 PASS, 1 FAIL), 51 fit rows, 0 fit errors. | **Adaptive:** isolated binary dependencies preserved the source-tarball oracle and did not alter the package or user library. **Drift — S0-B / Curie:** all-success/all-failure fixtures initially had an unnecessary `x`; they were corrected to the approved intercept-only designs and rerun. The material core failure remained unchanged. |
| S0-C | Objective-ray and hurdle adjudication only after every binomial gate passes | Not entered. No exact-row controls, compiled-objective rays, or hurdle rows occur in the TSV/harness execution. | **Adaptive withholding, not a dropped slice:** its prerequisite failed. |
| V0 | Luna mechanical verification | Luna reran the exact command, reproduced the declared nonzero exit, and verified unchanged TSV hash and the sole failure: `mu_complete / detectseparation / (Intercept) / oracle -Inf / expected finite`. Verdict: `MECHANICAL_STOP_EVIDENCE_VALID`. | **Match** |
| D-43 | One panel: two Terra-high and one Sol-high | Routing receipt records Noether and Fisher as Terra-high and Rose as Sol-high, all read-only. Each returned `NOT-DONE` (3/3). | **Match** |
| C0 | Closeout | After-task report is present; the required-section compiler returned `after-task structure check passed`. | **Match** |
| M0 | Reconciliation | This record. | **Match** |
| H0 | S1 handoff only after S0 PASS | No S1/GLMM handoff or work. | **Adaptive withholding, not a dropped slice:** S0 did not pass. |

## Material evidence state

The frozen `mu_complete` coordinate expectation is the only failed gate: the maintained oracle reports `-Inf` for its intercept where the contract required `finite`; the slope remains `+Inf`.  The evidence supports neither a detector nor a drmTMB defect claim.  It instead shows that complete separation here admits a cone of improving rays, so that one coordinate direction is not uniquely fixed.  The failure was retained, the process stopped as declared, and V0 independently reproduced that state.

The conditional downstream work is therefore correctly absent.  In particular, no compiled drmTMB fixed-parameter objective-ray agreement, zero-weight/offset/response-mask control, hurdle factorization or invariance result, package diagnostic, warning, interval, API, or public capability claim was produced.  This is a prerequisite stop, not a cancellation of the planned S0-C scope.

## Routing, safety, and public-boundary reconciliation

- **Per-slice routing: match; date-wide audit: fail.** R0 and V0 were Luna-medium; S0-A and S0-B were Terra-high; D-43 used exactly two Terra-high reviewers plus one Sol-high reviewer. The retained dispatch receipts contain Luna 2, Terra 5, and Sol 1. The required `codex-routing-audit.py --date 2026-08-08 --enforce --require-luna --max-compactions-per-session 1` nevertheless exited `1`: its date-wide native-session census was dominated by unrelated Sol sessions, and it recorded three compaction windows for this parent task rather than the plan's maximum of one. The retained lane receipts support the planned slice routing, but they do not convert the global audit into a pass.
- **Safety gate: match.** The harness wrote the complete retained TSV, exited nonzero on its predeclared falsifier, and did not reinterpret the failed expectation to obtain a pass. V0 validated that retained STOP.
- **Scope and public boundary: match.** The six artifacts remain quarantined. The after-task audit and status fence show no tracked package/public/release change and no work on zi, beta-binomial/count separation, penalties, intervals, package API/warnings, gllvmTMB, release, PR, or merge work.
- **Fence chronology: adaptive clarification.** V0 counted the five artifacts that existed before the verifier saved its own receipt. The closeout then added that receipt and this plan-actual record, for seven quarantined S0 artifacts in the final worktree. This is expected sequencing, not a package-scope change.

## Reconciliation verdict

S0 remains **NOT-DONE with `MECHANICAL_STOP_EVIDENCE_VALID`**.  The material plan drifts are the flawed S0-A finite-intercept contract, surfaced and retained by S0-B, and the context brake: the routing audit recorded three parent compaction windows against the declared maximum of one. The transient R/temp reconnaissance issue and intercept-only-fixture correction were bounded adaptations with recorded owners. S0-C and H0 were correctly withheld by their explicit gates. No S1 handoff, public claim, package integration, release action, PR, or merge is licensed by this record.
