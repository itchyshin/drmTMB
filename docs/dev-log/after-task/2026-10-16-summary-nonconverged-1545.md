# 2026-10-16: summary() flags non-converged fits (#1545), stacked on #1513

Reader: Shinichi and Engine A, deciding whether this branch can become a PR
once #1513 lands.

## Task goal

A fit whose optimizer did not converge printed `convergence: 1 (not
converged; see check_drm())` under `print()`, but only `convergence: 1`
under `summary()`, with no warning and no optimizer message (#1545, found on
the Student t fits in
<https://github.com/itchyshin/drmTMB/pull/1504#issuecomment-6209252414>).
Acceptance: a test that fails on the base, a fix, a list of sibling paths,
the full suite and a C17 recertification on the stack, and an R/Julia parity
check. By Engine A's rule the work sits on a WIP branch stacked on #1513's
head `dd5c1543` with no PR until #1513 lands, and no `src/` file is touched.

## What changed

`summary.drmTMB()` stores `convergence_message` (the optimizer message) next
to `convergence`. A new helper, `drm_cli_convergence()` in `R/methods.R`,
prints one rule for a non-converged fit: `convergence: 1 (not converged; see
check_drm())`, then `convergence message: <message>` on its own line. The
decision is `drm_convergence_label()` (`R/drmTMB.R`), so a native fit is
flagged exactly when the fit-time convergence warning fires. Converged fits
print as before.

- `print.summary.drmTMB()` prints the two lines before its first table, next
  to the existing unavailable-SE line, rather than after the parameter,
  covariance and derived tables. A converged summary keeps `convergence: 0`
  as its last line.
- `print.drmTMB()` uses the same helper, so it now also shows the message.
- Julia-engine fits: `print.drmTMB_julia()` (which `drmTMB_julia_joint` fits
  inherit) and `print.drmTMB_julia_xfam()` printed a bare code; they now use
  the helper. `summary.drmTMB_julia()`, `summary.drmTMB_julia_xfam()` and
  `summary.drmTMB_julia_joint()` store `convergence` (the exact code, so
  `$convergence` never partial-matches `convergence_message`) and
  `convergence_message`. The shared `print.summary.drmTMB_julia()` prints the
  same two lines, and keeps its word form for an object without a code. The
  Julia message is the text `drm_julia_opt_slot()` composes from DRM.jl's
  `converged` flag and iteration count, because DRM.jl sends no optimizer
  message.
- `check_drm()`: `convergence_status()` returns `"degenerate"` both for a
  converged-but-degenerate fit and for a fit whose optimizer failed, and the
  `convergence_status` row explained both as "the optimizer reported
  success". The #1545 fits read that way, in the table that `print()` and
  `summary()` point to. The row now branches on `drm_optimizer_converged()`;
  its value (`degenerate`) and status (`note`) are unchanged.

Files: `R/methods.R`, `R/julia-bridge.R`, `R/julia-joint-methods.R`,
`R/check.R`, `man/summary.drmTMB.Rd` (hand-edited; byte-identical to
roxygen2's rendering of the new `@return`), `NEWS.md`,
`tests/testthat/test-fit-convergence-warning.R`,
`tests/testthat/test-julia-joint-methods.R`,
`tests/testthat/test-dinnage-audit-wave4b1.R`, the C17 manifest and receipt,
`docs/dev-log/check-log.md`, and this report. `src/`, `R/drmTMB.R` and the
likelihood are byte-identical to `dd5c1543`.

## Receipt

Branch `claude/inspiring-mendel-xrmnl7`, stacked on #1513 head
`dd5c15435ebed8a3f05eb01af5bdee3b657667c4`. Code-final commit
`858e8be93ee9ff5e7368e4fac5b9108bfe89314a`. The commits after it change only
`docs/`. Environment: this cloud container, R 4.3.3, TMB 1.9.10, Matrix
1.6-5, glmmTMB 1.1.8, cli 3.6.2, rlang 1.1.3, testthat 3.2.1,
`LC_CTYPE = C`. `{JuliaCall}`, `{tweedie}`, `{DHARMa}`, `{fmesher}` and
`{detectseparation}` are not installed, and Julia cannot be installed (its
download hosts are blocked). R 4.3 has no base `%||%`, which drmTMB's `R/`
calls (see Known limitations), so the test runner defined it in the global
environment. Package code was not changed for this.

**Full suite** at `858e8be9`. `testthat::test_dir()` ran as four
`DRMTMB_TEST_SHARD` shards with `NOT_CRAN=true` against an installed build
of the stack: 441 files, 3,255 tests, **48,728 passed expectations**, 110
skipped tests (live Julia: 0 ran, 72 skipped), 15 failing or erroring tests.
Shard wall times: 679, 833, 1,344 and 753 s. The same 15 tests fail
identically on an installed build of #1513's head `dd5c1543` without #1545,
run from that commit's own test files. The two sets match by file and test
name, with none unique to either side, so none of the 15 comes from this
branch. All 15 are environment failures in this container:

| Tests | File | Cause |
| --- | --- | --- |
| 3 + 1 | `test-julia-fe-only-fence.R`, `test-julia-joint-call.R` | `{JuliaCall}` not installed |
| 2 | `test-numeric-kernel-oracle.R` | `{tweedie}` not installed |
| 2 + 2 | `test-comparators.R`, `test-comparators-phase19.R` | the `sigma` versus glmmTMB `disp` comparisons fail under glmmTMB 1.1.8 (inferred to be the version; not bisected) |
| 1 | `test-missing-predictor-prediction.R:291` | `crossprod` on a non-numeric matrix; #1513 records the same error on its unmodified head |
| 1 | `test-reml-phylo-location.R:172` | REML phylo q2 fit returns convergence 1 here; #1513's suite records the same VM failure |
| 1 | `test-associate-pairs-gaussian-bernoulli.R:213` | snapshot call frame `rd()` versus `mth()` (rlang/cli versions) |
| 1 | `test-reader-vignette-contracts.R:329` | invalid UTF-8 regex under `LC_CTYPE = C` |
| 1 | `test-phase18-structured-workflow-registry.R:126` | the test expects a checkout path; the run used an installed library |

**C17** at `858e8be9`: `python3 tools/recertify-c17.py --label
pr-1545-on-1513`, default exact tolerance. Before it ran,
`tools/ci-receipt-staleness.sh` reported `current source blob differs for
R/methods.R`. mc-0568, mc-0569 and mc-0576 reproduced
`mean_tau_relative_error` with `|change| 0.000e+00` (0.0990031773626767,
0.166077467303224, 0.0613049351609715). Then `capability_ledger.py --check`
returned OK, 80 ledger unit tests passed, and the C14/C17 receipt-equivalence
check passed. Receipt:
`docs/dev-log/implementation-recovery/2026-10-16-pr-1545-on-1513-c17c2-c14-final-source-compatibility/`.
The tool refuses to run while the tracked
`2026-08-01-lane-c-c17c1-c14-model15-compatibility-run-1/` exists, so that
directory was moved aside for the run and restored with `git checkout`. The
receipt's `dirty-state.txt` therefore lists it as deleted, as #1508's
recertification did. The `lss-tip-identity` Julia receipt was already stale on
`main` and on #1513; it needs a live Julia and is not regenerated here.

## Checks and the tests of the tests

- **Reproduction**, scratch script, not committed. The Simulator's data files
  are only on the shared box, so the wave J-sim DGP was regenerated (G = 30,
  n = 600, the same seeds; draw order assumed). At `ca3ddef`, 2 of 9 fits end
  in `false convergence (8)` at beta_nu about 14 (nu = 200, reps 1 and 3).
  `print()` says "not converged", `summary()` prints only `convergence: 1`,
  and `summary()` raises no warning. With the fix, `summary()` flags the fit
  and prints `false convergence (8)`.
- **On the stack**, which carries #1504's large-nu Student kernel, all 9
  regenerated fits converge (`relative convergence (4)`, beta_nu about 22,
  the Gaussian limit). This agrees with the Simulator's finding that the
  false convergence came from drmTMB's large-nu objective error. The display
  defect is independent of that: an optimizer-starved Student t fit
  (`iter.max = 1`, `eval.max = 2`, `newton_polish = FALSE`) still ends with
  code 1, and the fix flags it.
- **Red proof**:
  - `test-fit-convergence-warning.R` (14 tests): 7 fail on `dd5c1543` and
    the same 7 on `ca3ddef`. All 14 pass on the stack (68 expectations).
  - The joint test in `test-julia-joint-methods.R` fails on both bases and
    passes on the stack.
  - The new A-3 assertion in `test-dinnage-audit-wave4b1.R` passes on both
    sides by design: it guards the "reported success" text the fix must keep
    for converged-but-degenerate fits.
- **Width and order.** Output is captured by sinking stdout and messages into
  one connection, so the test can check that the flag comes before the
  coefficient table. Whitespace is squashed because cli wraps long messages;
  the tests also pass at `cli.width = 40`.
- **Adversarial review.** Four lenses (correctness, architecture, user,
  tests); each finding was checked by an independent verifier. Five findings
  were confirmed, all nits, and all are fixed in `858e8be9`:
  - Julia summaries let `$convergence` partial-match the message;
  - two comments claimed a shared rule the Julia summary did not follow;
  - no assertion pinned the converged-but-degenerate `check_drm()` text (the
    verifier showed a mutant that survived the suite);
  - a converged Julia `print()` check passed on empty output.

## Sibling paths

Changed: `print.drmTMB`, `print.summary.drmTMB`, `print.drmTMB_julia` (and
joint fits by inheritance), `print.drmTMB_julia_xfam`,
`print.summary.drmTMB_julia` (shared by the plain, cross-family and joint
Julia summaries), and the `check_drm()` `convergence_status` row.

Already correct: the `check_drm()` `optimizer_convergence` row, which shows
the nlminb message, and its Julia counterpart; `is_converged()`; and the
native fit-time warning.

Absent: drmTMB has no `tidy()`, `glance()`, `format()` or `knit_print()`
methods (NAMESPACE, `R/`), so there is nothing to change there.

Out of scope, listed for follow-up:
- `AIC()`/`BIC()`/`aicc()`, `anova()`, `lrt_boundary()`, heritability and
  pair-association prints accept non-converged fits without a flag.
- `convergence_status()` has no Julia method.
- The `optimizer_convergence` row says "nlminb" even when the `optim`
  fallback produced the fit.

The design choice was to print, not to warn. lme4 1.1.35.1 prints the
optimizer code and message in `print.summary.merMod()` (through
`.prt.warn()`), and `summary.merMod()` raises no convergence warning (its
only warning is "additional arguments ignored"). glmmTMB 1.1.8 warns about
convergence only at fit time, in `finalizeTMB()`; its print and summary
methods carry no convergence text. Both were checked in the installed
sources. drmTMB already warns at fit time (class
`drmTMB_convergence_warning`), and the package's store-and-print precedent
is the unavailable-SE line, so `summary()` stays silent and its printed form
says what happened.

## R/Julia parity (DRModels.jl `f71b2923`, read from the source; not run)

- The REPL display (`src/summary.jl:210-216`) flags a non-converged fit only
  with the token `converged = false`.
- `print` (`src/gaussian_core.jl:2614-2621`) says `NOT converged`, reading
  the raw `fit.converged`.
- `summary(fit)` is `coeftable(fit)` (`src/summary.jl:294`) and carries no
  convergence information, so DRModels.jl has the same gap #1545 fixes here.
- DRModels.jl keeps no optimizer termination reason; the bridge sends only
  `converged` and `iterations` (`src/bridge.jl:1644`, `:1659`).
- On the Simulator's two files DRModels.jl reached the Gaussian-limit
  optimum, so its `show` would correctly say converged there.

Whether its LBFGS fails on the regenerated data was not checked, because
Julia could not be run here.

## What did not go smoothly

- **Build.** The R package repositories are blocked in this container; R
  packages came from the Ubuntu archive instead.
- **Rebase.** The first full suite ran on `ca3ddef`. It was stopped when
  Engine A asked for the stack, and a second was stopped when the review
  changed code. The suite reported here ran once, on the final code.
- **`NEWS.md` conflict.** #1513's base is 46 commits behind `main`. The
  incoming side carried `main`-only bullets that are not on that base, so the
  conflict was resolved by keeping #1513's section and adding only the #1545
  bullet.

## Known limitations and next actions

- **R version floor.** drmTMB calls base `%||%` (R >= 4.4.0) in
  `R/julia-bridge.R`, `R/julia-diagnostics.R`, `R/julia-family-registry.R`
  and `R/mspl-estimator.R`, while DESCRIPTION says `R (>= 4.1.0)`. On R 4.1 to
  4.3 those paths error with `could not find function "%||%"`. CI uses R
  release, so it does not see this. There is no open issue; suggested fix: an
  internal `%||%` definition or a higher R floor.
- **Julia fit-time warning.** Julia-engine fits that DRM.jl reports as not
  converged raise no fit-time warning, while native fits do. Every Julia
  route returns through one line of `drmTMB()` (`R/drmTMB.R`, the
  `return(drmTMB_julia_bridge(...))` call), so the parity fix is a single
  `drm_warn_if_not_converged()` call. It was left out because live-Julia
  tests cannot run here. There is no open issue.
- **DRModels.jl.** Suggested follow-up: store the Optim termination status,
  add a convergence line to `summary()`/`coeftable()`, and send the status
  string across the bridge so that R can show the real reason.
- **PR.** Open the PR (`Refs #1545`) once #1513 lands. If #1513 merges with a
  different head, rebase this branch and recertify C17 again.

## GitHub issue maintenance

Searched for overlapping open issues on `%||%`/R 4.4 and on Julia fit-time
non-convergence warnings; found none. No issue was opened, commented on or
closed: Engine A's rule for this lane is to report and stop.
