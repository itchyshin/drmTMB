# After Task: Native reader contract

## 1. Goal

Make established native `drmTMB` workflows readable through exported,
documented interfaces rather than private fit slots. The task covered the
reader-vignette corpus, a minimum stable post-fit schema, and ten scientific
journeys. It did not change a likelihood, estimand, formula grammar, evidence
tier, or calibration claim.

## 2. Implemented

PR 1 adds a complete vignette manifest and exact private-access exceptions,
a fail-closed development linter with adversarial tests, and public-extractor
migrations in 13 reader articles.

PR 2 documents the stable native schemas for `check_drm()`, `summary()`,
`ranef()`, `fitted()`, and `predict_parameters()` in a dedicated roxygen/Rd
contract page. It turns the ten reader workflows into shared fixtures with
distinct scientific assertions.

Three verification defects found during package gates were repaired. The reader
audit no longer reloads an already loaded package namespace, and the q6 receipt
audit quotes paths containing spaces. Exact-head CI then showed that reader
prose placed beside `R/methods.R` invalidated a capability receipt that pins the
whole file even though its authenticated model-15 surface was unchanged. The
prose now lives in `R/reader-contracts.R`, and `R/methods.R` is byte-identical
to its receipt. None of these repairs changes a model or inference result.

## 3a. Decisions and Rejected Alternatives

The contract stabilizes the smallest useful reader tables, not every component
of a fit object. Existing compatibility relays remain available but are not
promised as stable reader interfaces. `ranef(no_random_fit)` continues to return
`list()`; changing that established behavior to an error was rejected after the
source-tarball suite caught the incompatibility. A requested absent named block
still gives an actionable error.

The arc hardened existing verbs instead of adding a reporting helper. It also
rejected any silent `predict_parameters()` shape redesign: core fields retain
their relative order, optional interval fields remain optional, and appended
`newdata` names are made deterministically unique.

## 4. Files Touched

PR 1 changes `inst/reader-contracts/`, `tools/check-reader-contracts.R`, its
test file, and 13 reader articles. The initial eight were animal, convergence,
meta-analysis, model-selection, phylogenetic, phylogenetic-spatial,
relatedness-matrix, and spatial workflows. The D-43 sweep additionally changed
bivariate-coscale, formula-grammar, implementation-map, model-map, and
which-scale, and then repaired phylogenetic-spatial again.

PR 2 changes the public documentation beside `R/check.R` and
`R/predict-parameters.R`, adds `R/reader-contracts.R` and its generated Rd
page, updates the reader schema and journey tests, and repairs two audit
scripts. Closeout adds this report, the plan-versus-actual record, and a
check-log entry. The final PR does not change `R/methods.R` relative to PR 1.

No formula or likelihood design document changed because the work governs
public extraction and documentation, not model mathematics.

## 5. Checks Run

- Reader schema: 34 expectations passed.
- Ten shared reader journeys: 53 expectations passed; all fits, diagnostics,
  report outputs, scientific assertions, and deliberate unsupported-target
  requests passed.
- Reader-vignette linter: 21 expectations passed; the live 37-article corpus
  reported `Reader vignette contract: OK`.
- Capability-ledger generation passed for 31 outputs, and all 73 ledger unit
  tests passed with the C17/C14 current-source compatibility receipt intact.
- The initial eight-article set and the six-article D-43 repair set rendered
  successfully. This covers 13 unique changed articles; the repaired rendered
  HTML contains no `sdpars$`, `corpars$`, or `random_effects` extraction route.
- `pkgdown::check_pkgdown()` reported `No problems found`.
- Exact source build followed by `R CMD check --as-cran`: 0 errors, 0 warnings,
  and one expected new-submission NOTE. Receipt:
  `/private/tmp/drmtmb-native-reader-check-final2-20260814/drmTMB.Rcheck/00check.log`.
- Complete native `devtools::test()` suite: exit 0 with no failures. It retained
  70 expected condition/deprecation warnings and 26 explicit skips; Julia
  engine paths were deliberately unavailable under the approved post-0.7
  boundary.
- Repaired PR 1 head `c1a756ee9` passed both required checks in GitHub run
  `31813020416`; GitHub reports PR #1027 clean and mergeable.
- The fresh D-43 panel returned 3/3 `DONE`: Emmy, Fisher, and Rose reported no
  unresolved P0-P2 after the prose-route and scientific-journey repairs.
- The five protected files retained their exact lane-receipt blob hashes.

## 6. Tests of the Tests

The linter tests plant arbitrary object names, bracket access, bare and
backticked private extraction routes, broadened contributor permissions,
unauthorized but well-formed exceptions, missing and duplicate manifest rows,
invalid fields, and stale exceptions. Each defect is rejected. Public
`summary(fit)$parameters`, `summary(fit)$covariance`, and `ranef(fit)$terms`
are explicit non-false-positive sentinels.

The journey tests reuse the exact fit/data pairs that produce the ten-row audit
receipt. They check probability sums, denominator semantics, ordinal cutpoint
scale, structured deviations and SD targets, response-scale `rho12`, known
sampling variance, missing-row accounting, and the lognormal response-mean
distinction. Every journey also proves that the public unknown-target error is
the reason an unsupported profile request fails.

The schema tests include a second-order `row`/`newdata_row` collision and prove
that output names remain unique. The full-suite compatibility failure for
`ranef(no_random_fit)` was retained as evidence that the gate can detect an
unintended public behavior change.

## 7a. Issue Ledger

No new issue was opened. This arc hardens existing behavior and documentation;
it does not close the separate Julia, MSPL, CRAN re-freeze, calibration, or
new-estimand issues. PR 1 and the stacked PR 2 are the review surfaces.

## 8. Consistency Audit

Every `vignettes/*.Rmd` file appears exactly once in the corpus. Reader articles
have no unrecorded access to `opt`, `sdr`, `sdpars`, `corpars`,
`optimizer_used`, `optimizer_attempts`, `obj`, `model`, `missing_data`, or
`random_effects`. Contributor permissions and explanatory exceptions are exact
immutable records rather than general allowlists.

The public schema prose and executable tests agree on response scale,
distributional-parameter scale, interval status, interval provenance, and the
advanced/internal boundary. No source, generated Rd, test, or article claims
that `ranef()$terms` is a random-effect SD extractor. The changed articles use
`check_drm()`, `is_converged()`, reader tables from `summary()`,
`profile_targets()`, `corpairs()`, `sigma()`, and `ranef()$terms` in place of
private fit slots.

## 9. What Did Not Go Smoothly

The first PR 1 CI run sourced a top-level `tools/` file from an installed source
tarball even though `.Rbuildignore` intentionally excludes that directory. The
repaired test skips only in that installed context; local development still
runs the live linter.

The first PR 2 architecture review caught an overbroad `ranef()` promise and a
second-order `newdata` name collision. The first source-tarball check caught an
attempted no-random-effect behavior change. All were repaired before the final
gate. An initial sandboxed CRAN check was discarded because DNS failure stopped
at incoming feasibility; only the networked, complete check above counts.

The first closeout draft used descriptive headings rather than the executable
after-task schema. The repository validator caught that omission before the
completion panel, and this report now uses the required structure.

The first manually dispatched PR 2 exact-head run failed before package check
because its source-compatibility receipt pins all of `R/methods.R`. The changed
bytes were reader-contract prose plus a message clarification, not model-15
behavior, and the validator correctly classified the receipt as stale rather
than wrong. Updating the capability ledger was outside this arc. Instead, the
message change was reverted and the same tested contract was moved to a
dedicated roxygen/Rd page. The full 73-test ledger suite now passes without a
receipt or capability-file change.

Rose's first D-43 review found that prose-only private routes such as
`sdpars$mu` could evade the syntax-oriented linter. A manifest-driven sweep
migrated every reader-facing instance, and the linter now detects bare and
backticked extraction routes. Fisher's D-43 review also made the bivariate DGP
match its disturbance-dependent correlation question and required nonempty,
profile-ready phylogenetic and spatial SD targets.

## 10. Known Residuals

The contract is native-only. Julia remains post-0.7. `summary()` compatibility
relays and advanced `ranef()` covariance/mesh components remain available but
are not stable reader schemas. D-43 is green; the repaired stacked PR 2 still
requires a new external exact-head CI after push. Neither PR is merged by this
task.

## 11. Team Learning

A reader contract should stabilize the smallest useful table, not every
component of a fit object. Development audits used from tests must avoid
reloading the package namespace because that can invalidate mocks in later
test files. Path portability applies to verification tools too: `system2()`
arguments containing a repository path must be quoted. Finally, closeout prose
must be tested against the repository’s executable protocol rather than judged
by visual completeness alone.

## 12. Cross-Product Coverage

This arc covers native post-fit reader extraction for the ten deterministic
workflows and the five documented verbs. It does NOT cover Julia engines, MSPL,
new models or likelihoods, new estimands, REML expansion, profile or coverage
calibration, capability-ledger promotion, remote compute, or the CRAN re-freeze.
It does not make advanced covariance-block or mesh components stable reader
schemas, and it does not convert smoke evidence into an inference-readiness
claim.
