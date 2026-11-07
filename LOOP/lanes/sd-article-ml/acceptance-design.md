# Proposed execution acceptance ledger

This file specifies the gates to register before execution. No fit/test/render command below was run during planning. The full programme retains its original G0-G4/G6-G8; these first-delivery gates close only this milestone.

## Exact roots and environment

Select approved, leased R_ROOT and J_ROOT from the pinned source/worktree map, and a separate writable OUT directory. Never infer a clean lane from its branch name. Keep foreign wiring edits and the protected stash. Live bridge commands use NOT_CRAN=true, DRMTMB_JULIA_TESTS=true, DRM_JL_PATH pointing at J_ROOT, JULIA_PROJECT pointing at J_ROOT, JULIA_HOME pointing at the selected Julia bin directory, OPENBLAS_NUM_THREADS=1 and JULIA_NUM_THREADS=1. Register exact invocation, source hashes and expected runtime before running; a skip is not a live pass.

## M1-PIN: ownership and source identity

CHECK: lane_preflight.sh ROOT --file each owned path, lane_lease.sh scoped OWNS, git status/diff, git rev-parse HEAD and remote main read.
EXPECT: source pins and foreign paths recorded; lease GRANTED; no overlap resolution by unilateral edits. Repo roots and exact source hashes are part of every evidence receipt.

## M1-MATRIX: row-preserving status audit

CHECK: join required-rows.tsv with source-admission descriptors, tests/receipts and independent reviews, by exact row_key. Compare the input/output row-key sets, and generate the user table from that result.
EXPECT: no lost required row, duplicate identity or promotion from file presence; separate admission, implementation, exact-source runtime, receipt linkage, independent review, output, docs and calibration fields. Unknown and blocked rows retain a reason and next ticket. A machine-check of the join and a deliberately removed row must respectively pass and fail. The input denominator is pinned, never turned into a support percentage.

CHECK (existing reconciler, from R_ROOT): python3 tools/general-sd-regression/reconcile_evidence.py --root "$R_ROOT" --rows "$R_ROOT/docs/dev-log/general-sd-regression/required-rows.tsv" --evidence "$R_ROOT/docs/dev-log/general-sd-regression/direct-sd-evidence.tsv" --summary "$OUT/direct-sd-summary.md"
EXPECT: EVIDENCE_RECONCILIATION_PASS; no current-source or calibration grant inferred from this join. This command writes its summary at OUT.

## M1-PREDICT: structured stored-row prediction

CHECK: targeted pure-R payload tests before implementation, then a live native/bridge/direct fixture test using already admitted batch-34 structured exports. Extend the existing test-julia-conditional-prediction.R and test-julia-b34-structured-fitted-bridge.R instead of bypassing public predict().
EXPECT: the pre-fix structured case fails for the stated semantic mismatch; repaired stored link prediction equals independently assembled X beta + eta_re and response prediction equals the appropriate link inverse and conditional fitted value. Cover shuffled rows/group levels, non-unit matrix diagonals, missing/malformed/failed payloads, alias/selector targets and save/reload. Ordinary Gaussian predictions and fresh RE=0 newdata predictions preserve their established contract. No newdata conditional extrapolation or conditional-SE claim is earned.

Example focused invocation after the runtime smoke: Rscript -e 'devtools::test(filter="julia-(conditional-prediction|b34-structured-fitted-bridge)", reporter="summary", stop_on_failure=TRUE)'
EXPECT: all relevant blocks actually execute, no failures/errors; a deliberately permuted eta_re or removed contribution must fail a meaningful assertion. Record any unrelated warning separately.

## M1-NUMERICAL: reproduce before fixing

CHECK: exact-source probes for the retained ZeroOneBeta extreme seeds, NB2 animal best-objective discrepancy, and Binomial extreme-SD convergence flag. Record every attempt, objective, gradient, boundary/rank and error status.
EXPECT: each finding is reproduced with its exact scope, superseded by current evidence, or remains explicitly unresolved with a blocker. No failure is removed from the accounting. Catching an exception, clipping the data or substituting fake finite SEs cannot count as a numerical repair. The already merged stored-loglik fix is a reuse/regression check only.

## M1-ARTICLE: clean public workflow and estimand

CHECK: fresh-session R native, R engine=julia and direct Julia runs for each displayed example, using public functions; rendered R HTML, rendered Julia page and actual figure inspection.
EXPECT: all code/output is generated; each fit names family, effect/provider, link, method and approximation; each displayed prediction names its quantity. Include a continuously varying SD predictor, retain Bernoulli/Poisson introduction, and check the Gamma non-unit-diagonal candidate before admitting it. Distinguish latent multiplier, marginal SD and residual sigma; RE=0 is not an integrated mean. Never replace a failing example with an easier target and call the planned example done.

CHECK: independent Pat reader runs the instructions and answers the five interpretation questions in PLAN.md.
EXPECT: no internal helper/payload knowledge needed; limitations and valid next actions visible to the reader.

## M1-REGRESSION: affected code and source-bound evidence

CHECK: focused and neighboring R/Julia files, affected bridge tests, original universe/selector tests and the required full package/docs ladder for actual changes. Follow the measured pre-run rule if a full serial suite or receipt campaign could exceed three hours.
EXPECT: new failures attributed and fixed, known failures retained with honest scope; no silent tolerance changes. Existing tests that intentionally assert refusals are changed only when the route was actually admitted and independently checked.

CHECK: assess affected receipt groups and rerun those whose current-source claim moved; preserve prior evidence; regenerate the existing lss-tip-identity receipt last with tools/run-julia-phylo-labels-public.R, then tools/check-julia-phylo-labels-receipt.R NEW_JSON --current and ci-receipt-staleness.sh with DRM_JL_PATH set.
EXPECT: clean runner/current-source/hash checks on the accepted paired refs, including Julia-side hashes; no overwrite of old evidence, no weakening of hash/tolerance rules, no broad parity or calibration claim.

## M1-REVIEW/LAND: independent panel, integration and publication

CHECK: reverify the on-disk CHECK/EXPECT gates, then one fresh 2-Luna-build + 1-Sol-ceiling completion panel. Give reviewers artifacts and exact pins; authors do not approve their own changes. Run closeout.py check, slop_check.py and exact-draft assessment-check; compare planned versus actual work.
EXPECT: blocking findings addressed or the affected slice remains open; row and claim boundaries survive. Generated files and source agree; files staged explicitly; no foreign work included.

CHECK: pr_merge_when_green.sh on exact approved heads; then main workflows on each merge SHA; current deployed R/Julia page retrieval, link and render verification where publication is authorized by the existing gates.
EXPECT: all required checks settled before merge; real main post-merge jobs pass; deployed article matches accepted source/artifact. No release, no settings bypass and no claim of full-programme completion from this first delivery.
