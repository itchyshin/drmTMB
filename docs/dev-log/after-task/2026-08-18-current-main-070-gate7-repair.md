# After Task: 0.7.0 Gate 7 shipped-truth and CRAN-time repair

## 1. Goal

Repair the blockers found by the fresh Grace/Rose/Pat review of candidate
`6b45164b…` without treating that rejected artifact as the final 0.7.0
candidate or authorising CRAN submission.

## 2. Implemented

The shipped release story now agrees with the code. `NEWS.md` records that
MSPL's earlier logit-only boundary was superseded by the later 0.7.0 probit and
complementary log-log admission. The installed trust dossier now tells the
reviewer to install `drmTMB` from the source or release candidate under review;
only its comparator packages are described as available on CRAN.

The CRAN check lane is now a reviewed 48-context smoke allowlist. It covers
release identity, formula parsing, ordinary families, representative
structured/missing/meta routes, public methods, MSPL, offsets, and reader/S3
compatibility. `NOT_CRAN=true` still runs all 334 test files in repository CI,
so no test or evidence campaign was deleted or weakened.

## 3a. Decisions and Rejected Alternatives

No likelihood, parameterisation, estimator, formula grammar, or inference
claim changed. The repair only makes NEWS describe the already implemented
MSPL link contract in `R/mspl-estimator.R`, and separates a bounded CRAN smoke
lane from the unchanged full CI suite.

Candidate `6b45164b…` was rejected as the final artifact rather than patched in
place. Adding more exclusions to the historical regex was rejected in favour
of an explicit allowlist, whose selected surface and runtime are directly
testable. The initial theory that the old anchors were ineffective was also
rejected after reproducing `test_check()` with its real bare-context mode.

## 4. Files Touched

- `NEWS.md`, `inst/trust-dossier/README.md`, and
  `inst/trust-dossier/run.R` repair shipped release identity.
- `tests/testthat/test-release-identity.R` guards the two contradiction
  classes.
- `tests/testthat.R`, `tests/testthat/helper-cran-lane.R`, and
  `tests/testthat/test-cran-lane-filter.R` define and guard the CRAN smoke
  allowlist.
- `AGENTS.md`, `docs/dev-log/coordination-board.md`, and the historical
  2026-08-18 Ligges handover now point readers to the active current-main
  repair and preserve the submission/#1033 boundaries.
- This report is the repo-visible task receipt. `docs/dev-log/check-log.md` and
  `docs/dev-log/team-improvements.md` were deliberately not edited because
  file-level lane preflight reports concurrent/ref-carried work not present in
  this checkout.

The worktree also contains uncommitted evidence and `cran-comments.md` edits
for rejected candidate `6b45164b…`. They are not part of the repair commit and
must not be promoted into the next ledger or submission text.

## 5. Checks Run

- Focused `cran-lane-filter|release-identity`: 47 expectations, 0 failures.
- Installed-package CRAN smoke lane after the final helper move:
  `FAIL 0 | WARN 19 | SKIP 24 | PASS 3568`. One measured run completed in
  60.24 seconds; a later contended repetition used 49.10 CPU seconds but 273.38
  wall seconds. Windows timing therefore remains an external gate rather than
  an extrapolated claim.
- Repair-probe `R CMD build --no-manual`: success.
- Repair-probe `R CMD check --as-cran --run-donttest --no-manual`, with
  `R_PROFILE_USER=/dev/null` and `NOT_CRAN=false`: 0 errors, 0 warnings, 1
  expected `New submission` NOTE. Its check-native test stage was 61 seconds.
- `git diff --check`: clean before the closure report.
- Source/code scan confirmed `R/mspl-estimator.R` admits exactly `logit`,
  `probit`, and `cloglog`.

The first sandboxed check attempt failed during CRAN incoming feasibility
because DNS was unavailable. The retained terminal clean result is the rerun
with network access, not the failed sandbox probe.

## 6. Tests of the Tests

The base revision contains both stale phrases that the new release-identity
test rejects: `MSPL) entry point remains **logit-only**` in NEWS and `all on
CRAN` attached to `drmTMB` in both trust-dossier entry points. The repaired
source passes the negative assertions and also requires the constructive
replacement text.

The CRAN-lane contract checks both testthat's bare-context mode (used by
`test_check()`) and full-path mode. It requires the selected files to equal the
allowlist exactly, rejects Julia and evidence-campaign suites, and requires
representative ordinary, structured, missing-response, meta-analysis, public
method, and release-identity files. This dual-mode assertion was added after an
initial diagnostic incorrectly inferred testthat's real path semantics from a
private helper call with `full.names=TRUE`.

## 8. Consistency Audit

The exact searches were:

```sh
rg -n -i "MSPL.{0,80}logit-only|logit-only.{0,80}MSPL|all on CRAN.{0,80}drmTMB|drmTMB.{0,80}all on CRAN" README.md NEWS.md DESCRIPTION _pkgdown.yml inst vignettes R tests docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md
rg -n "probit|cloglog" R/mspl-estimator.R tests/testthat/test-mspl-link-dispatch.R tests/testthat/test-mspl-nonlogit-links.R
rg -n "6b45164b|5153ae7e|platform-clean|submit_cran|19 August|#1033|_julia_skip2_artifacts" AGENTS.md docs/dev-log/coordination-board.md docs/dev-log/handover/2026-08-18-codex-handover.md
```

The only remaining “initially logit-only” NEWS sentence is explicitly
superseded in place. Historical handover facts remain verbatim under a new
supersession banner. Governance consistently says candidate `6b45164b…` is
predecessor evidence and that new exact bytes plus a full platform ladder are
still required.

No equations, examples, vignettes, roadmap claims, known-limitations entries,
formula-grammar text, or pkgdown navigation needed a change because package
behaviour did not change.

## 7a. Issue Ledger

Open issue #61 is the existing CRAN-readiness umbrella and already covers
release checks, evidence consistency, and the no-submission-before-agreement
guard. No duplicate issue was opened and no issue comment was posted before
the repair PR. PR #1033 was neither inspected nor modified.

## 9. What Did Not Go Smoothly

The first timing profiler forced `testthat:::find_test_scripts(...,
full.names=TRUE)`, which made the old start-anchored exclusions appear broken.
`test_check()` actually asks for bare names. That diagnosis was retracted in
the same session, the prose was corrected, and the final contract now tests
both modes. The underlying 14-minute Windows result remains real: the old
exclusions were valid but insufficient.

The first `--as-cran` attempt could not reach CRAN/Bioconductor in the sandbox
and was not counted. A repeated standalone smoke later encountered severe
wall-clock contention despite low CPU use; the check-native 61-second receipt
and future win-builder results are kept separate from that diagnostic.

## 11. Team Learning

Test the public runner's semantics before diagnosing a private helper. For
large evidence-oriented package suites, a reviewed CRAN allowlist is easier to
audit than a growing exclusion regex: new campaign tests remain full-CI-only
until their CRAN purpose and runtime are explicit. The irreversible boundary
protected here is a submission delayed or rejected by excessive check time;
the useful full validation suite remains available on all repository-CI runs.

## 10. Known Residuals

This is source-repair evidence, not a new immutable candidate and not
`platform-clean` or `submission-ready`. The 60/61-second local measurements do
not establish Windows duration. Candidate `6b45164b…` remains valid predecessor
platform evidence for its exact bytes only. The 19 testthat warnings are
expected fit-level warnings counted by the suite, not `R CMD check` warnings.

No `submit_cran()` call was made. No submission is authorised on 19 August.
PR #1033 and `_julia_skip2_artifacts/` remain protected.

## 12. Cross-Product Coverage

This repair changes only drmTMB's shipped prose and test routing. It does not
change DRM.jl, gllvmTMB, a downstream package, a simulation claim, a capability
ledger row, or any public model behaviour. Julia remains an optional backend;
the CRAN hard stop already on `main` is unchanged.

This slice **does NOT cover** a new family, likelihood, REML provider, MSPL
penalty, fitting engine, missing-data mechanism, aggregation route, random or
structured effect, interval, recovery result, coverage result, or capability
tier. It does not certify DRM.jl, gllvmTMB, or any downstream consumer.

## Next Actions

1. Commit the narrow repair, open a PR, and require its full `NOT_CRAN=true`
   Ubuntu package check to pass before merge.
2. Merge, cut new immutable 0.7.0 bytes from clean current `main`, and rerun
   local exact-byte check, inventory/hash/size, 3-OS CI, R-hub diagnostics,
   and all three win-builder arms.
3. Rewrite `cran-comments.md` and the release ledger only for those new bytes,
   then obtain fresh Grace/Rose/Pat verdicts and return the evidence packet to
   Shinichi for a separate submission decision.
