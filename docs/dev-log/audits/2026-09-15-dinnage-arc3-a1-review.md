# Independent review: PR #1368, Dinnage Arc 3 Wave A1 docs

Reviewer: Cursor reviewer subagent, independent of the builder
Date: 2026-09-15
PR: https://github.com/itchyshin/drmTMB/pull/1368
PR head: `cursor/dinnage-arc3-a1-docs-20260915`
Review branch: `cursor/dinnage-arc3-a1-review-20260915`

## Verdict

ACCEPT-WITH-CHANGES.

The PR is a narrow documentation-only slice. It correctly updates the visible documentation for #1334, #1345, and #1359, and it fixes the stale `mi()` capability table for #1323. The new #1349 commit fixes the false `student()` uniqueness claim in the family page, but it still lacks the issue's required NEWS credit. It does not complete the full A1 handover set: #1317, #1320, #1341, #1346, and #1354 remain owed and are blocked on roxygen paths leased by A3.

No scope expansion, likelihood change, parameter-transform change, or hidden API change was found in the reviewed diff. No package tests were run for this review; evidence is from `gh pr view 1368`, `gh pr diff 1368`, issue-body acceptance criteria, and targeted greps of the PR head.

## Findings

### P2: #1323 still lacks the requested regression test

Status: ACCEPT-WITH-CHANGES.

The documentation correction itself is right: the capability table now lists `lognormal()`, `Gamma(link = "log")`, `student()`, and `beta_binomial()` as one-binary-`mi()` response families (`vignettes/capability-and-limits.Rmd:593` on the PR head), and NEWS credits Russell's Md-F finding (`NEWS.md:11`-`NEWS.md:15`). The issue acceptance criteria, however, explicitly ask for "a test that fails on 945da24f-behaviour and passes after" plus NEWS. PR #1368 changes only `NEWS.md`, `R/family.R`, `R/formula-markers.R`, generated `.Rd` files, and the capability vignette; no `tests/` file is touched.

Requested change before treating #1323 as fully closed: add a small doc-regression or capability-table test, or explicitly amend the issue/PR scope so the missing test is a recorded follow-up rather than an implied closeout criterion.

### P2: #1349 still lacks the required NEWS credit

Status: ACCEPT-WITH-CHANGES.

The documentation correction itself is right: the false claim that Student-t is "the one implemented family" whose public `sigma` is a scale rather than `SD[y]` is gone, and the new wording keeps the Student-t-specific scale explanation (`R/family.R:112`, `man/student.Rd:21` on the PR head). The issue acceptance criteria also require a NEWS entry crediting Russell's report. The current A1 NEWS section credits #1345, #1323, #1334, and #1359, but a targeted grep found no Mi-11/#1349 Student-t scale credit.

Requested change before treating #1349 as fully closed: add a NEWS bullet crediting Mi-11/#1349.

### P3: PR body is stale about #1359

Status: ACCEPT-WITH-CHANGES.

The current PR body still lists #1359 as queued/blocked on `R/profile.R`, but the refreshed diff includes commit `b7331b187` and the documentation now satisfies the #1359 Value-section acceptance (`R/profile.R:176`, `man/confint.drmTMB.Rd:170`, `NEWS.md:22`-`NEWS.md:25` on the PR head). Update the PR body so the remaining owed/blocked list does not contradict the code.

## Per-issue status

| Issue | Review status | Done on PR #1368? | Notes |
| --- | --- | --- | --- |
| #1317 | REJECT as closed by this PR | No | Still owed. No `REML`/`confint()` documentation change appears in the PR. The PR body also lists this as blocked by the A3 lane. |
| #1320 | REJECT as closed by this PR | No | Still owed. No `predict.drmTMB` documentation or `type = "mean"`/`type = "response"` clarification appears in the PR. |
| #1323 | ACCEPT-WITH-CHANGES | Partly | Table and NEWS are corrected (`vignettes/capability-and-limits.Rmd:593`, `NEWS.md:11`-`NEWS.md:15`), but the issue's requested failing/passing test is absent. |
| #1334 | ACCEPT | Yes | `meta_V()` now states positional matching and no dimname reordering in roxygen and generated Rd (`R/formula-markers.R:10`-`R/formula-markers.R:13`, `man/meta_V.Rd:14`-`man/meta_V.Rd:16`, `man/meta_known_V.Rd:14`-`man/meta_known_V.Rd:16`), with NEWS credit (`NEWS.md:17`-`NEWS.md:20`). |
| #1341 | REJECT as closed by this PR | No | Still owed. No new `emmeans` see-also/section or `DHARMa::createDHARMa()` example is added. The PR body lists this as blocked by the A3 lane. |
| #1345 | ACCEPT | Yes | `cumulative_logit()` now documents integer-coded ordinal responses as accepted at face value and recommends ordered factors for labelled scientific order (`R/family.R:409`-`R/family.R:412`, `man/cumulative_logit.Rd:29`-`man/cumulative_logit.Rd:32`), with NEWS credit (`NEWS.md:5`-`NEWS.md:9`). |
| #1346 | REJECT as closed by this PR | No | Still owed. No `residuals.drmTMB` Pearson-residual convention update for `student`, `skew_normal`, or `beta` is added. The PR body lists this as blocked by the A3 lane. |
| #1349 | ACCEPT-WITH-CHANGES | Partly | `student()`/`?student` no longer makes the false uniqueness claim (`R/family.R:112`, `man/student.Rd:21`), but the required NEWS credit is absent. |
| #1354 | REJECT as closed by this PR | No | Still owed. No `sigma.drmTMB` return-shape/interface note is added. The PR body lists this as blocked by the A3 lane. |
| #1359 | ACCEPT | Yes | `confint.drmTMB` now states that returned `parm` values are fully qualified and warns callers to normalize before joining compact labels (`R/profile.R:176`-`R/profile.R:179`, `man/confint.drmTMB.Rd:170`-`man/confint.drmTMB.Rd:173`), with NEWS credit (`NEWS.md:22`-`NEWS.md:25`). The PR body should be updated because it still lists this as queued. |

## Review checks

- Package scope: preserved. The diff is documentation-only and stays within univariate/bivariate DRM documentation.
- Likelihood coherence: not affected. No likelihood code changed.
- Parameter transforms: not affected. No transform code changed.
- Simulation tests: not relevant to the pure documentation clarifications, but #1323 still has an explicit missing test acceptance criterion.
- Docs/examples: updated for #1323, #1334, #1345, #1349, and #1359, with #1323 and #1349 still missing one acceptance item each.
- API consistency: no new inconsistency found. The `meta_known_V()` alias page inherits `meta_V()` wording, which is appropriate for compatibility documentation.
