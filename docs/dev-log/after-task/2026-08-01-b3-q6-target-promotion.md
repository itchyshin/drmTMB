# After Task: B3 q6 target-level interval-feasible promotion

## 1. Goal

Promote exactly four retained direct `mu2` q6 response-SD targets—`mc-0102`, `mc-0124`, `mc-0146`, and `mc-0168`—from `point_fit_recovery` to `interval_feasible`, while keeping their four linked whole-q6 Mission Control cells at `point_fit / planned / planned`.

## 2. Implemented

B3 now represents the four direct targets explicitly in the canonical capability ledger and in a four-row Mission Control sidecar. Each target is bound to one retained serial receipt from runner `a8d068e641105473b3f30723a92c909467a46fac`, tree `26609fbcedae06752505078dca9a1daed623ea8d`, seed `20260731`, and information rung `high_n72_each20`.

The claim is targetwise interval feasibility only. B3 does not claim coverage, calibration, inference readiness, provider-wide behavior, whole-q6 behavior, another target, another seed or fixture, REML, or public support.

## 3a. Decisions and Rejected Alternatives

The exact target is a direct response-scale random-effect SD:
`sd:mu:mu2:<provider>(1 | p | <group>)`. The profile operates internally on `log_sd_phylo` and reports `exp(log_sd_phylo)` on the response-SD scale. Every retained trace row records `scale=response`, `transformation=exp`, `tmb_parameter=log_sd_phylo`, and internal index `4`.

The immutable authorization file incorrectly labels `target_truth=0.4` as `latent_log_sd`. The B3 packet retains that file byte-for-byte for its authorization hash but adds an explicit correction: `target_truth=0.4`, `target_truth_scale=response_sd`, with the historical label recorded as erroneous metadata. No canonical or generated B3 surface propagates `0.4` as a log-SD truth.

B3 rejected a whole-q6 promotion because one direct `mu2` interval cannot
establish feasibility for the companion `mu1` targets or the 15 derived
correlations. It also rejected a new profile run, substitute fixture, coverage
campaign, and evidence-class vocabulary because none was needed for the
approved targetwise reconciliation.

## 4. Files Touched

The source transition adds:

- the four-row promotion packet under `docs/dev-log/evidence/`;
- the exact four-row q6 `mu2` target sidecar;
- four changed `cells.tsv` rows, four appended `evidence.tsv` rows, and four appended `transitions.tsv` rows;
- the immutable serial authorization, four receipt quartets, four supervisor logs, independent audit, and focused R audit test;
- exact-four guards in `tools/capability_ledger.py`, `tools/validate-mission-control.py`, and focused Python tests;
- Mission Control loading and rendering for the target sidecar.

The capability generator refreshed only the affected census, widget, bivariate-Gaussian, Markdown, and HTML outputs. No package R/C++ implementation, formula grammar, q12 artifact, E0 row, K=12 control, missing-response route, Lane A/C source, or compute configuration changed.

## 5. Checks Run

Gate 1 ran the E0 readiness verifier, B2 exit-dossier validator and focused tests, independent serial audit, and mechanical four-receipt verifier in an isolated frozen snapshot. All passed. The 22 authorization/result artifacts and the audit runner remain byte-identical to commit `574c1108e16e3b0fe4ba88e254a34673508db901` (23/23 source-bound files), including the authorization SHA-256 `e96cda2d7da3a301aa52866d8833e84c21831e727feb52635ad30487d04c336f`. The focused R test retains the same six source-checkout assertions but now skips in a built source package, where `.Rbuildignore` intentionally excludes top-level `tools/`.

On refreshed base `5ff94d86c534d21155d6b46740c48234420e0b79`:

- `python3 tools/capability_ledger.py --check`: PASS, 30 generated outputs;
- `python3 -m unittest tools/tests/test_capability_ledger.py`: PASS, 46 tests;
- `python3 -m unittest tools/tests/test_b3_q6_target_promotion.py`: PASS, 3 tests;
- the independent serial audit: PASS, 4/4 receipts;
- `tests/testthat/test-b2-q6-serial-proof-receipt-audit.R`: PASS, 6 expectations in a source checkout; expected SKIP in an extracted source tarball without top-level `tools/`;
- `git diff --check -- . ':(exclude).../supervisor-logs/*.log'`: PASS for every authored or generated B3 file and every imported TSV/script/test. The unscoped check reports historical trailing spaces in the four immutable supervisor logs; those bytes are retained deliberately so the 23/23 immutable source-identity proof remains valid;
- final lane preflight: no foreign Claude lane detected; this remains weak evidence, not proof of sole ownership.

`python3 tools/validate-mission-control.py` and `python3 tools/qseries_v1_release_check.py --summary` remain red for 15 pre-existing absolute paths into the absent historical `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot` worktree. The same 15 errors were present on clean `origin/main` before B3; no B3 validation error is present. This lane did not alter those foreign DRM.jl/dashboard records.

PR #879's first Ubuntu `R CMD check` run correctly exposed the source-package context error: the focused audit test attempted to source a top-level development tool that `.Rbuildignore` excludes. The repair follows the repository's established development-tool test pattern: assert all six expectations in a source checkout and skip only when the tool is absent from the built source package. An extracted-tarball rehearsal reproduced that expected skip before the repair was pushed.

## 6. Tests of the Tests

The focused B3 tests fail closed on the exact four-ID allowlist, paired-`mu1` non-inheritance, whole-q6 `planned` statuses, evidence/transition counts, target identity, receipt presence, and trace/interval SHA-256 hashes. Mission Control validation additionally checks packet schema, authorization hash, finite ordered estimate-containing endpoints, response-scale trace semantics, exact provider and whole-cell links, and explicit exclusions. These checks exercise the promotion boundary rather than only detecting file presence.

## 8. Consistency Audit

Noether’s compatibility audit confirmed that the parser, profile registry, bivariate-Gaussian TMB path, extractor identity, and ledger mapping remain compatible with the retained receipts. The branch was initially created from then-current `origin/main` at `402aca4c`; when Lane C subsequently advanced main by 26 commits, B3 was stashed, fast-forwarded, and reconciled onto `5ff94d86`. All ten C16 promotions were preserved. The frozen recovery counts therefore reconcile as `178 - 4 = 174`, or `179 - 4 = 175` including the approved inserted row.

The fresh completion panel returned 3/3 PASS. Fisher approved exactly the four
targetwise promotions and withheld every broader inference claim. Noether
confirmed the response-SD, `exp(log_sd_phylo)`, index-4 identity and the
metadata correction. Rose confirmed the exact-four source/generated diff,
preservation of all C16 and whole-q6 rows, and absence of B3 validation errors.
All three treated the 15 missing historical DRM.jl paths as a disclosed
foreign baseline that does not authorize expansion of B3.

## 7a. Issue Ledger

No issue, PR, or public-site update was requested. B3 therefore made no GitHub issue change. The stale external DRM.jl evidence paths belong to a separately scoped dashboard/DRM.jl maintenance lane and were not reassigned here.

## 9. What Did Not Go Smoothly

The first capability write exposed an unnecessary new evidence-class name. B3 retained the existing `estimator_diagnostic` vocabulary instead of widening the schema.

More importantly, `origin/main` advanced during implementation. Comparing against the refreshed main exposed apparent Lane C reversions before they could be staged as B3. The branch was refreshed and conflicts were resolved by preserving both C16 and B3, then regenerating outputs. This confirmed why a second base/diff audit is necessary before review.

The global Mission Control validator cannot become green inside B3 without changing unrelated historical DRM.jl evidence paths, which the lane boundary forbids.

## 10. Known Residuals

Each promotion covers one named direct target, one high-information fixture, and one retained seed. It establishes finite, ordered, unclamped profile endpoints containing the estimate; it does not establish interval coverage, calibration, nominality, robustness across fixtures, or whole-q6 feasibility.

The full Mission Control and q-series wrapper commands remain red on inherited foreign absolute-path evidence. B3-specific Mission Control validation and rendering are covered by the focused tests and by the new exact-four checks inside the global validator, but the repository-wide validator is not globally green.

## 11. Team Learning

For source-of-truth reconciliation lanes, recheck `origin/main` immediately before generation and again before the completion panel. A clean worktree at task start does not protect against a concurrent same-platform merge.

Immutable evidence can contain incorrect metadata. Preserve the original bytes and authorization hash, but add a canonical correction layer with a validator that binds the corrected interpretation to the underlying trace semantics.

## 12. Cross-Product Coverage

Covers: four named bivariate-Gaussian ML q6 direct `mu2` response-SD targets,
their retained high-information serial receipts, target-level capability
ledger representation, and target-level Mission Control rendering.

Does NOT cover: paired `mu1` targets, q6 slopes or correlations, whole-q6
feasibility, q12, E0, K=12, Lane A/C, missing response, REML, coverage,
calibration, inference readiness, public support, API behavior, or compute.

## Next Actions

A separately authorized dashboard/DRM.jl maintenance lane must repair or supersede the 15 absent historical worktree paths. After that repair lands, rerun the global Mission Control validator and q-series release summary without changing B3’s four target rows.

Do not begin coverage, calibration, q12, another q6 target, E0, K=12, Lane A/C, missing-response, API, or compute work from this report.
