# Independent review: PR #1368, Dinnage Arc 3 Wave A1 docs

Reviewer: Cursor reviewer subagent, independent of the builder
Date: 2026-09-15
PR: https://github.com/itchyshin/drmTMB/pull/1368
PR head: `cursor/dinnage-arc3-a1-docs-20260915`
Review branch: `cursor/dinnage-arc3-a1-review-20260915`

## Verdict

ACCEPT-WITH-CHANGES.

The PR is a narrow documentation-only slice. It correctly updates the visible documentation for #1334 and #1345, and it fixes the stale `mi()` capability table for #1323. It does not complete the full A1 handover set. Seven listed issues remain owed on the PR, and #1323 still misses the issue's explicit failing/passing test acceptance criterion.

No scope expansion, likelihood change, parameter-transform change, or hidden API change was found in the reviewed diff. No package tests were run for this review; evidence is from `gh pr view 1368`, `gh pr diff 1368`, issue-body acceptance criteria, and targeted greps of the PR head.

## Findings

### P2: #1323 still lacks the requested regression test

Status: ACCEPT-WITH-CHANGES.

The documentation correction itself is right: the capability table now lists `lognormal()`, `Gamma(link = "log")`, `student()`, and `beta_binomial()` as one-binary-`mi()` response families (`vignettes/capability-and-limits.Rmd:593` on the PR head), and NEWS credits Russell's Md-F finding (`NEWS.md:11`-`NEWS.md:15`). The issue acceptance criteria, however, explicitly ask for "a test that fails on 945da24f-behaviour and passes after" plus NEWS. PR #1368 changes only `NEWS.md`, `R/family.R`, `R/formula-markers.R`, generated `.Rd` files, and the capability vignette; no `tests/` file is touched.

Requested change before treating #1323 as fully closed: add a small doc-regression or capability-table test, or explicitly amend the issue/PR scope so the missing test is a recorded follow-up rather than an implied closeout criterion.

## Per-issue status

| Issue | Review status | Done on PR #1368? | Notes |
| --- | --- | --- | --- |
| #1317 | REJECT as closed by this PR | No | Still owed. No `REML`/`confint()` documentation change appears in the PR. The PR body also lists this as blocked by the A3 lane. |
| #1320 | REJECT as closed by this PR | No | Still owed. No `predict.drmTMB` documentation or `type = "mean"`/`type = "response"` clarification appears in the PR. |
| #1323 | ACCEPT-WITH-CHANGES | Partly | Table and NEWS are corrected (`vignettes/capability-and-limits.Rmd:593`, `NEWS.md:11`-`NEWS.md:15`), but the issue's requested failing/passing test is absent. |
| #1334 | ACCEPT | Yes | `meta_V()` now states positional matching and no dimname reordering in roxygen and generated Rd (`R/formula-markers.R:10`-`R/formula-markers.R:13`, `man/meta_V.Rd:14`-`man/meta_V.Rd:16`, `man/meta_known_V.Rd:14`-`man/meta_known_V.Rd:16`), with NEWS credit (`NEWS.md:17`-`NEWS.md:20`). |
| #1341 | REJECT as closed by this PR | No | Still owed. No new `emmeans` see-also/section or `DHARMa::createDHARMa()` example is added. The PR body lists this as blocked by the A3 lane. |
| #1345 | ACCEPT | Yes | `cumulative_logit()` now documents integer-coded ordinal responses as accepted at face value and recommends ordered factors for labelled scientific order (`R/family.R:410`-`R/family.R:413`, `man/cumulative_logit.Rd:29`-`man/cumulative_logit.Rd:32`), with NEWS credit (`NEWS.md:5`-`NEWS.md:9`). |
| #1346 | REJECT as closed by this PR | No | Still owed. No `residuals.drmTMB` Pearson-residual convention update for `student`, `skew_normal`, or `beta` is added. The PR body lists this as blocked by the A3 lane. |
| #1349 | REJECT as closed by this PR | No | Still owed. `student()` documentation is not changed, despite the PR body noting this path was available for a follow-up commit. |
| #1354 | REJECT as closed by this PR | No | Still owed. No `sigma.drmTMB` return-shape/interface note is added. The PR body lists this as blocked by the A3 lane. |
| #1359 | REJECT as closed by this PR | No | Still owed. No `confint.drmTMB` Value-section clarification about fully qualified output labels is added. The PR body lists this as owned by A2. |

## Review checks

- Package scope: preserved. The diff is documentation-only and stays within univariate/bivariate DRM documentation.
- Likelihood coherence: not affected. No likelihood code changed.
- Parameter transforms: not affected. No transform code changed.
- Simulation tests: not relevant to the two pure documentation clarifications, but #1323 still has an explicit missing test acceptance criterion.
- Docs/examples: updated for #1323, #1334, and #1345 only; the rest of the named A1 issues remain owed.
- API consistency: no new inconsistency found. The `meta_known_V()` alias page inherits `meta_V()` wording, which is appropriate for compatibility documentation.
