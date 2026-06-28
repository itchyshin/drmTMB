# After-task: Q-Series v1 consolidation after the default small-sample interval arc

Meta: 2026-06-28 · Codex · branch `claude/local-coverage-grids-sigma-q2`.

## 1. Goal

Close Q-Series v1 as a durable, row-level evidence and status arc. The target was
not broad structured-RE `supported` support; it was to preserve the pushed
small-sample interval branch, reconcile stale status prose, record the final
validation gates, and stop before starting sigma, spatial q2, REML, q4/q8, count,
or non-Gaussian work.

## 2. Implemented

- Pushed `claude/local-coverage-grids-sigma-q2` to origin before making new edits,
  so the incoming 16-commit arc at `922defda` is no longer local-only.
- Updated `docs/design/218-structured-q-series-completion-map.md`,
  `README.md`, `NEWS.md`, `ROADMAP.md`,
  `docs/design/01-formula-grammar.md`, and the 2026-06-28 handover so they agree
  with `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`.
- Recorded the current row truth: the TSV has 104 rows; exactly
  `qseries_phylo_q2_mu1_mu2_one_slope` and
  `qseries_relmat_q2_mu1_mu2_one_slope` are `inference_ready` for interval and
  coverage status; no structured row is `supported`.
- Added this after-task report and a check-log entry with the validation commands
  and the next-arc boundary.

## 3a. Decisions and Rejected Alternatives

Q-Series v1 stops at consolidation. The branch now accepts the default
small-sample correction for location-axis structured SD targets, with t(g - 1)
width plus the simulation-calibrated `log(g/(g - 1))` centre shift. That shift is
not REML in closed form; it is about 2x the leading-order REML SD term and was
accepted because the engine grids support the narrower row-level claim.

Rejected alternatives:

- Do not call q2 `supported`. Fisher/Rose kept this blocked because of the
  measured right-tail miss asymmetry and g-dependent under-correction.
- Do not say all four providers are `inference_ready`. The all-provider g=8
  number is correction evidence; the row-status promotion is only phylo and
  relmat.
- Do not start sigma in the same patch. Sigma is the next bounded compute arc,
  but it needs its own default-channel/denominator sign-off.
- Do not promote spatial q2, animal q2, q4/q8, count, non-Gaussian structured
  rows, or REML/AI-REML neighbours by analogy.

## 4. Files Touched

- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/handover/2026-06-28-codex-handover.md`
- `docs/dev-log/after-task/2026-06-28-q-series-v1-consolidation.md`

## 5. Checks Run

- `git push -u origin claude/local-coverage-grids-sigma-q2`: pushed
  `c1e9d15a..922defda` and set upstream tracking.
- `python3 tools/validate-mission-control.py`: `mission_control_ok`, including
  104 structured RE Q-Series cells.
- `git diff --check`: no output.
- Forbidden-claim scan over README, NEWS, ROADMAP, formula grammar, doc 218, and
  the handover: only contextual guard hits remained (`not a claim that all four
  providers are inference_ready`; `Do NOT re-label the shift "REML in closed
  form"`).
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::test()'`: FAIL 0 / WARN 17 / SKIP 43 / PASS 19588; duration
  548.5 s.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::check()'`: Status OK, 0 errors / 0 warnings / 0 notes; duration
  11m 59.9s.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'pkgdown::check_pkgdown()'`: no problems found.

## 6. Tests of the Tests

`tools/validate-mission-control.py` is the main status guard for this patch. It
loads the Q-Series TSV, counts 104 support cells, and still restricts
`inference_ready` to the two allowed q2 phylo/relmat rows. The broader test suite
also reran `test-wald-small-sample-default.R` and the structured conversion
contract tests inside both `devtools::test()` and built-package `devtools::check()`.
No deliberate mutation was introduced in this consolidation pass; the earlier
Rose audit records that non-certified row flips and `supported` over-promotion
are validator errors.

## 7a. Issue Ledger

- Fixed stale branch-state wording in the handover: the work is pushed and the
  validated incoming arc head is `922defda`, not a local-only 15-commit state at
  `9ae75bf1`.
- Fixed stale table-size/status wording: current Q-Series authority is 104 rows,
  not the older 106-row narrative.
- Fixed stale narrative that implied every structured row still had planned
  interval/coverage status.
- Added the missing final after-task/check-log closeout for the default
  correction plus q2 phylo/relmat `inference_ready` promotion.
- Deferred PR CI to the PR gate after this consolidation commit is pushed.

## 8. Consistency Audit

Ada, Rose, Fisher, Gauss, and Grace returned read-only audits. Their shared
boundary is now reflected in the edited files: q2 phylo/relmat remain
`inference_ready`, `supported` remains withheld, sigma is next but separate,
q4/q8 remain blocked by Hessian/finite-denominator issues, and count/non-Gaussian
structured claims stay outside this arc.

The local scan checked the main narrative surfaces for stale `15 commits`,
`106 cells`, broad all-four-provider `inference_ready`, `supported` engineering,
and REML-in-closed-form language. Remaining hits are explicit cautions rather
than claims.

## 9. What Did Not Go Smoothly

The first attempt to spawn fresh reviewer agents hit the thread limit because
existing team threads were still open. Waiting on the existing team threads
recovered the needed Ada/Rose/Fisher/Gauss/Grace audits, and those completed
threads were then closed. The initial forbidden-claim scan also tripped on shell
quoting because the pattern included backticks; rerunning it as a single-quoted
pattern resolved that.

## 10. Known Residuals

- PR CI still has to run on the pushed consolidation commit.
- `supported` for q2 remains a research/engine arc: skew-aware intervals or a
  derived and tested bivariate structured-location REML route.
- Sigma can move toward `inference_ready` next, but only as its own bounded
  default-channel compute arc with denominator, `pdHess`, finite-interval, and
  one-sided-miss reporting.
- Spatial q2, animal q2, q4/q8, count recovery, non-Gaussian structured
  covariance, and non-Gaussian REML remain future row-level arcs.

## 11. Team Learning

The finish line for a status arc is not the most exciting possible label. It is
the point where the validator table, public docs, check log, after-task report,
and CI story all say the same narrow thing. For this lane, that narrow thing is
strong and useful: two q2 location-axis structured SD rows are
`inference_ready`, and the project is honest about why `supported` is still out
of reach.
