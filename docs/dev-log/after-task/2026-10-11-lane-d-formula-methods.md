# Lane D: formula, data, and methods correctness

## Goal

Fix the lane D code-review findings from the 2026-10-11 bug-fix campaign
where `drmTMB` accepted an ordinary input and then failed in a misleading way
or silently did something else: character predictors in `predict(newdata)`
(#1497), unused `...` arguments (#1486), numeric relatedness ids (#1485), and
the `simulate(re.form =)` documentation (#1487). Each finding was reproduced
on `main` at `75845a3d` before it was changed.

## Implemented

- **#1497.** `drm_prepare_model_matrix_newdata()` restored training levels
  only for factor template columns. A character (or logical) column reached
  `model.matrix()` as is, which built its levels from the prediction rows. A
  partial grid then failed to align with the coefficients, a one-row grid hit
  the base-R "contrasts can be applied only to factors with 2 or more levels"
  error, and an unseen value never reached the designed unknown-level message.
  Character and logical template columns are now converted with `factor()`
  first, the same coding `model.matrix()` used at fit time.
- **#1486.** `drmTMB()` called `list(...)`, which evaluated every extra
  argument. `subset = cyl == 4` therefore failed with "object 'cyl' not
  found". The guard now checks `...length()` and the unevaluated names. It
  names each unused argument (`drmTMB_unused_dots_error`) and adds next steps
  for `subset`, `na.action`, and misspelt formals.
- **#1485.** `relmat()`/`animal()` matched ids through `as.character()`, so the
  double `100000` became `"1e+05"` and never matched labels written
  `"100000"`, although the same ids stored as integers did match. The new
  `drm_id_labels()` writes whole-number doubles as plain digits. It is used
  for the grouping column, inside `drm_known_relatedness_precision()`, and for
  pedigree `id`/`dam`/`sire`.
- **#1487.** The `simulate.drmTMB()` documentation said `re.form` matched the
  lme4/glmmTMB convention. The explicit values actually mean the reverse of
  `lme4::simulate.merMod()`; only the default behaviour (fresh draws) agrees.
  The roxygen text, `man/simulate.drmTMB.Rd`, and design doc 243 now say so.
  The behaviour is unchanged; changing it is an owner decision.
- **#1484.** The `miss_control(predictor = "fail")` check read the call
  syntax, so `missing = ctl` (a stored control) or
  `miss_control(predictor = pf)` dropped rows with missing predictors
  silently, while the same control written out in the call errored.
  `miss_control()` now records which arguments were supplied
  (`attr(, "explicit")`), and `drmTMB()` reads that record from the evaluated
  object. Every literal spelling keeps its old meaning:
  `miss_control(response = ...)` and an omitted `missing` still drop
  incomplete rows. Plain-list controls never trigger the check. With the
  coordinator's agreement, this touches only `miss_control()` and the old
  helper in lane A's `R/missing-data.R`.

## Not changed here

- #1480, #1495, #1482, #1481, and #1460 already have open PRs (#1500, #1501,
  #1503) that touch the same functions. They were left alone to avoid
  duplicate or conflicting fixes.
- #1354: the `?sigma.drmTMB` interface note it asks for is already on `main`.
  Only the NEWS credit is missing, and NEWS is not edited by campaign lanes.

## Files Changed

`R/methods.R`, `R/drmTMB.R`, `R/phylo-utils.R`, `R/missing-data.R`
(`miss_control()` and its helper only), `man/simulate.drmTMB.Rd`,
`man/miss_control.Rd`, `docs/design/243-marginal-simulation-and-re-form.md`,
and four new test files: `test-predict-character-predictors.R`,
`test-drmTMB-unused-dots.R`, `test-relmat-numeric-ids.R`, and
`test-miss-control-evaluated.R`.

## Checks Run

Each new test file was run against an installed build of unmodified `main`
(all four fail with the reported errors) and against the branch (all pass).
The full suite was then run against the installed branch build; the totals
are in the PR comment.

## Tests Of The Tests

The new tests fail on `main` for the reason each issue reports: alignment and
contrasts errors (#1497), "object not found" and an unnamed message (#1486),
"does not cover every observed level" with `"1e+05"` labels (#1485), and a
silent fit for a stored control (#1484).

## Consistency Audit

The predict fix shares a loop with #1501's contrast restore, so the two PRs
will produce a small textual conflict in `drm_prepare_model_matrix_newdata()`.
The intended merge keeps both: convert character sources first, then keep the
fitted contrasts on the rebuilt factor. `confint(bootstrap_re_form =)` uses
the same `NULL`/`NA` meaning as `simulate()`; its documentation is owned by
lane C.

## What Did Not Go Smoothly

Five of the eleven issues already had open fix PRs from an earlier triage
pass. Their PR links are visible only in each issue's `closed_by_pull_requests`
field, so checking that field before coding saved duplicate work.

## Team Learning

Before starting a campaign issue, read the issue's linked PRs as well as its
comments.

## Design-document Updates

`docs/design/243-marginal-simulation-and-re-form.md` no longer claims the
lme4/glmmTMB `re.form` convention.

## pkgdown/documentation Updates

`?simulate.drmTMB` (roxygen and Rd).

## GitHub Issue Maintenance

None. Issues stay open until the owner merges.

## Known Limitations and Next Actions

The whole-file C17 receipt and the main-only tip-identity receipt hash the
edited R files. The C17 receipt is regenerated on this branch and may need
regenerating again at merge time. The tip-identity receipt needs Julia and
can only be refreshed on main.
