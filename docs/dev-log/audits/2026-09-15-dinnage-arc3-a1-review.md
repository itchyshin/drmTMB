# Independent review: PR #1368, Dinnage Arc 3 Wave A1 docs

Reviewer: Cursor reviewer subagent, independent of the builder
Date: 2026-09-15
PR: https://github.com/itchyshin/drmTMB/pull/1368
PR head: `cursor/dinnage-arc3-a1-docs-20260915`
Review branch: `cursor/dinnage-arc3-a1-review-20260915`

## Verdict

ACCEPT-WITH-CHANGES.

The PR is a narrow documentation and doc-regression-test slice. Commit `da35dad3c` fixes the two previous review gaps: #1323 now has the requested failing/passing capability-table regression test, and #1349 now has a NEWS credit for Russell Dinnage's Mi-11 report. The PR body also correctly moves #1359 into the done list.

One PR-body update is still needed before treating the PR text as the A1 status map: A3 has released `R/methods.R` and `R/drmTMB.R`, so #1317, #1320, #1341, #1346, and #1354 are no longer lease-blocked. They are still owed until landed, but the PR body should stop saying they remain blocked on the A3 lane.

No scope expansion, likelihood change, parameter-transform change, or hidden API change was found in the reviewed diff. Narrow validation was rerun on the PR head: `Rscript -e 'devtools::test(filter = "dinnage-audit-wave1")'` passed with 16 pass, 0 fail, 0 warn, 0 skip.

## Findings

### P3: PR body still describes released A3 paths as blocked

Status: ACCEPT-WITH-CHANGES.

The current PR body says #1317, #1320, #1341, #1346, and #1354 "remain blocked on the A3 `R/methods.R` / `R/drmTMB.R` lane" and tells the branch to rebase if A3 merges first. That is stale after A3 released those paths. Please revise the section to say these issues are still owed until landed, but no longer lease-blocked by A3.

This is not a code blocker, but it matters because the PR body is being used as the handoff/status map.

## Per-issue status

| Issue | Review status | Done on PR #1368? | Notes |
| --- | --- | --- | --- |
| #1317 | REJECT as closed by this PR | No | Still owed. No `REML`/`confint()` documentation change appears in the PR. No longer lease-blocked by A3, per the released `R/methods.R` / `R/drmTMB.R` paths. |
| #1320 | REJECT as closed by this PR | No | Still owed. No `predict.drmTMB` documentation or `type = "mean"`/`type = "response"` clarification appears in the PR. No longer lease-blocked by A3. |
| #1323 | ACCEPT | Yes | Table and NEWS are corrected (`vignettes/capability-and-limits.Rmd:593`, `NEWS.md:11`-`NEWS.md:15`), and commit `da35dad3c` adds the requested doc-regression test (`tests/testthat/test-dinnage-audit-wave1.R:5`-`tests/testthat/test-dinnage-audit-wave1.R:18`). |
| #1334 | ACCEPT | Yes | `meta_V()` now states positional matching and no dimname reordering in roxygen and generated Rd (`R/formula-markers.R:10`-`R/formula-markers.R:13`, `man/meta_V.Rd:14`-`man/meta_V.Rd:16`, `man/meta_known_V.Rd:14`-`man/meta_known_V.Rd:16`), with NEWS credit (`NEWS.md:17`-`NEWS.md:20`). |
| #1341 | REJECT as closed by this PR | No | Still owed. No new `emmeans` see-also/section or `DHARMa::createDHARMa()` example is added. No longer lease-blocked by A3. |
| #1345 | ACCEPT | Yes | `cumulative_logit()` now documents integer-coded ordinal responses as accepted at face value and recommends ordered factors for labelled scientific order (`R/family.R:409`-`R/family.R:412`, `man/cumulative_logit.Rd:29`-`man/cumulative_logit.Rd:32`), with NEWS credit (`NEWS.md:5`-`NEWS.md:9`). |
| #1346 | REJECT as closed by this PR | No | Still owed. No `residuals.drmTMB` Pearson-residual convention update for `student`, `skew_normal`, or `beta` is added. No longer lease-blocked by A3. |
| #1349 | ACCEPT | Yes | `student()`/`?student` no longer makes the false uniqueness claim (`R/family.R:112`, `man/student.Rd:21`), and NEWS now credits Russell's Mi-11 report (`NEWS.md:17`-`NEWS.md:19`). |
| #1354 | REJECT as closed by this PR | No | Still owed. No `sigma.drmTMB` return-shape/interface note is added. No longer lease-blocked by A3. |
| #1359 | ACCEPT | Yes | `confint.drmTMB` now states that returned `parm` values are fully qualified and warns callers to normalize before joining compact labels (`R/profile.R:176`-`R/profile.R:179`, `man/confint.drmTMB.Rd:170`-`man/confint.drmTMB.Rd:173`), with NEWS credit (`NEWS.md:26`-`NEWS.md:29`). The PR body correctly lists it as done. |

## Review checks

- Package scope: preserved. The diff stays within univariate/bivariate DRM documentation and one doc-regression test.
- Likelihood coherence: not affected. No likelihood code changed.
- Parameter transforms: not affected. No transform code changed.
- Simulation tests: not required for this documentation-only slice. The requested #1323 regression test is now present and passed in the narrow test run.
- Docs/examples: updated for #1323, #1334, #1345, #1349, and #1359. The PR body needs one status-map wording update for the now-released A3 paths.
- API consistency: no new inconsistency found. The `meta_known_V()` alias page inherits `meta_V()` wording, which is appropriate for compatibility documentation.
