# After Task: MR-T7 Missing-Response Certification

## 1. Goal

Close the MR-T0–MR-T7 missing-response arc by proving that all 18 fitted
response routes have independent G3 recovery evidence and that code, tests,
the capability ledger, public documentation, pkgdown, and release records
describe the same bounded support surface.

## 2. Implemented

MR-T7 adds no likelihood or public API. It reconciles the generated
18-route ledger with the live R builders, refreshes six estimator-surface
source citations shifted by MR-T1–MR-T6 insertions, replaces an empty
post-completion family-gate loop with a direct completed-inventory assertion,
and updates the missing-data design and capability prose through MR-T6.

The authoritative result is 18 fitted routes, 18 verified at G3, and zero at
G0–G2. A G3 tick remains route-specific: it proves fixed-seed 25% MCAR recovery
for every fitted distributional parameter and the named fixed/random route; it
does not imply interval calibration or broad structured-effect support.

## 3a. Decisions and Rejected Alternatives

- Kept the 668-cell general model census separate from the 18-route
  missing-response ledger rather than multiplying missingness over every model
  cell.
- Kept G4 interval feasibility and G5 coverage outside this arc. The proposed
  14,400-fit coverage campaign was not run.
- Did not use Totoro, DRAC, DRM.jl, or an external literature search. The native
  R/TMB builders and kernels remain authoritative.
- Did not silence the local `--as-cran` spelling NOTE by expanding
  `inst/WORDLIST` or weakening the test. Under `NOT_CRAN=true`, the report-only
  spell test intentionally writes a template and reports current candidates;
  CRAN mode removes that comparison. The diagnostic NOTE is recorded rather
  than hidden behind devtools' incorrect zero-note summary, and a separate
  final-tree check with explicit `NOT_CRAN=false` proves the actual CRAN mode.
- Preserved `v0.5.0` at `095409c0`; all missing-response work is on development
  version `0.5.0.9001`.

## 4. Files Touched

- `AGENTS.md` and
  `docs/dev-log/2026-07-11-missing-response-all-families-ultra-plan.md`:
  synchronized MR-T7 entry state and remaining gates.
- `docs/dev-log/dashboard/estimator-surface-conformance.tsv`: refreshed six
  exact source-line citations without changing any expected behavior.
- `tests/testthat/test-missing-response-family-gate.R` and
  `tests/testthat/test-missing-data-capability-gate.R`: converted two empty
  all-families loops into direct fitted-family inventory assertions.
- `tools/capability_ledger.py` and
  `vignettes/includes/capability-ledger-family-map.md`: added the generated
  full per-family map to the pkgdown input set.
- `docs/design/149-missing-data-design.md`: marked MD10 as the historical
  six-route baseline and added explicit MR-T5/MR-T6 rows.
- `vignettes/capability-and-limits.Rmd`, `vignettes/missing-data.Rmd`, and
  `NEWS.md`: removed stale allow-list/G0 wording, published both capability
  views, and recorded the bounded 18/18 closeout.
- This report, the check log, and the final handover record the certification
  evidence and remaining external gates.

## 5. Checks Run

- `python3 tools/capability_ledger.py --check`: 30 generated outputs matched.
- Six Python generator tests passed, including stale-output and evidence-free
  promotion failures.
- `tools/check-capability-runtime.R`: 18 routes, 18 verified, zero G0–G2.
- `devtools::document()`: completed without generated documentation drift.
- Final-tree `devtools::test()` under `NOT_CRAN=true`: 37,542 passed, 62 known
  warnings, 24 expected unavailable-Julia skips, and zero failures in 1,507.1
  seconds. No empty-test skip remains.
- Final-tree `devtools::check(document = FALSE, args = "--as-cran",
  env_vars = c(NOT_CRAN = "false", ...))`: zero errors, zero warnings, and
  zero notes in 5 minutes 51.8 seconds. The CRAN-mode installed-package tests
  passed in about 152 seconds and the vignette rebuild passed in 75 seconds.
- `pkgdown::check_pkgdown(); pkgdown::build_site(preview = FALSE);
  pkgdown::check_pkgdown()`: both checks reported no problems and every article
  and reference page rendered.
- The two repaired family-inventory files passed 18/18. The full missing-data
  suite passed 1,314 with two known beta-binomial warnings and two unavailable
  Julia skips. Both affected articles rebuilt successfully.
- Three independent repaired-tree adversaries returned BRANCH-LOCAL DONE:
  Rose/Noether for ledger, likelihood, and claim alignment; Fisher/Curie for
  recovery and tests-of-tests; and Grace/Pat for package, site, and user-facing
  truth. Each listed the external publication gates separately.
- Final branch and final-main three-OS CI, sanitizer, and Pages evidence are
  recorded in the parent issue after those external gates complete.

## 6. Tests of the Tests

The first full MR-T7 run failed six estimator conformance expectations because
their evidence windows cited pre-MR-T1 source lines. Exact error strings still
existed at the intended gates; refreshing only the six line citations restored
the focused conformance suite to 152/152 and the full suite to zero failures.

The initial independent reviews returned NOT DONE and the full/broader
missing-data runs exposed two empty `test_that()` blocks:
old drift guards iterated only over unvalidated fitted families, but none
remained. MR-T7 now asserts that the candidate family types equal the completed
allow-list (with bivariate Gaussian handled separately). Count-mixture aliases
retain their independent route-specific G2/G3 files and do not inherit these
assertions.

The site review also found that the canonical dashboard preserved the original
per-family map but the public pkgdown article did not. The generator now emits
that map as output 30 and the article renders it beside the route board. All
three reviewers returned DONE only after these repairs and final-tree reruns.

Across MR-T1–MR-T6, the direct retape helper mutates two support-valid sentinels,
checks objective and gradient agreement within `1e-8`, then independently
optimizes and checks coefficients and log likelihood within `1e-6`. Each
recovery test asserts the realized 25% MCAR design. These tests establish
single-DGP recovery, not replicated coverage.

## 7a. Issue Ledger

Parent issue [#761](https://github.com/itchyshin/drmTMB/issues/761) owns the
entire arc. PRs #762 and #765–#770 landed MR-T0–MR-T6 sequentially, and each
route/gate delta is recorded on #761. The MR-T7 closeout PR and final external
workflow URLs are added to the same issue; it is closed only after synchronized
`main`, three-OS CI, all three sanitizers, and live Pages are verified.

CRAN feedback remains an isolated release track. No CRAN acceptance claim is
made here. Superseded release PR #763 was closed after verifying that #764 had
already merged the identical eight-file fix into `main`; its release branch and
the frozen tag remain preserved.

## 8. Consistency Audit

The audit covered `README.md`, `ROADMAP.md`, `NEWS.md`,
`docs/dev-log/known-limitations.md`, `docs/design/149-missing-data-design.md`,
both missing-data/capability vignettes, the ledger, runtime oracle, and generated
site. Exact searches included:

```sh
rg -n -i 'only.*(gaussian|six)|six.*response|missing-response routes.*G0|12.*G0|3.*G0|6.*verified|15.*verified' README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/149-missing-data-design.md vignettes
rg -n 'G4|G5|coverage|inference_ready|supported|REML|response plus `mi\(\)`|MNAR' NEWS.md ROADMAP.md docs/dev-log/known-limitations.md docs/design/149-missing-data-design.md vignettes docs/dev-log/dashboard/capability-ledger
```

The 18-route board and the preserved 668-cell per-family capability view remain
separate and visible. Public claims stop at G3 and state the route/effect
boundary.

## 9. What Did Not Go Smoothly

The first full suite found six stale source citations rather than functional
failures. A compact exact-string audit located the new lines and avoided
touching code or expectations. The local spell test also made raw
`R CMD check` report one NOTE while devtools summarized zero notes; inspecting
`spelling::spell_check_test()` showed that this is its `NOT_CRAN=true`
report-only comparison, not a package check failure. A first attempted CRAN-mode
rerun was stopped when the check banner showed that devtools had overridden the
shell and restored `NOT_CRAN=true`; passing `NOT_CRAN=false` through the
function's `env_vars` argument produced the final 0/0/0 result.

Several recovery contexts dominate runtime, especially legacy q6/q8 and NB2
checks. They completed successfully, so no test was moved, weakened, or rerun on
external compute.

## 10. Known Residuals

G3 is one fixed-seed recovery design per route. It is not G4 interval
feasibility or G5 replicated coverage. Dense known-`V` partial bivariate rows,
response masking combined with `mi()`, MNAR, non-Gaussian REML, multiple
missing predictors, and blanket random/structured masking remain unsupported
or unclaimed.

The external closeout gates are branch/final-main three-OS R-CMD-check,
`clang-asan`, `clang-ubsan`, `gcc-asan`, deployed Pages inspection, and clean
main/issue synchronization. Their authoritative URLs live on #761 because they
occur after the closeout tree is published.

## 11. Team Learning

A behavior ledger that stores source-line evidence needs a mechanical
line-window audit after large insertions. More importantly, a loop over
“remaining unsupported cases” becomes vacuous when a project finishes; final
certification should replace it with a positive completed-inventory assertion.

Release gates must report raw tool status as well as wrapper summaries and must
verify their effective environment. Here, devtools' summary contradicted the
raw local NOTE, and its default argument overrode the shell's `NOT_CRAN=false`.
The accepted evidence is the later run whose banner and final status both prove
the intended CRAN mode.

## 12. Cross-Product Coverage

This arc covers `missing = miss_control(response = "include")` only for the 18
fitted response routes and only for each route's explicitly evidenced fixed,
ordinary-random, or independent-bivariate structure. It covers builder
admission, observed-only validation/starts, full row-density guards, sentinel
invariance, output accounting, malformed neighbours, and every-dpar recovery.

It does NOT cover response plus `mi()`, multiple missing predictors, dense
known-`V` partial bivariate responses, random/structured variants beyond the
named recovery route, REML with explicit missingness, alternative engines,
MNAR mechanisms, interval calibration, or coverage. It does NOT promote the
general capability census' `inference_ready` or `supported` tiers.
