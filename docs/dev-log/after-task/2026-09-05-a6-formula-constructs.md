# A6: formula constructs through the bridge with R-contrast fidelity (DRM.jl #467 + #609 factors; design 258)

**Reader**: anyone touching `drm_julia_bridge_payload_coef_labels()`
(`R/julia-bridge.R`), DRM.jl's `_bridge_coef_vector` / `_bridge_check_coef_labels_fidelity`
(`src/bridge.jl`), or the parity leaf ledger `.unlazy/parity/gates/leaf-a6.md`;
anyone wondering why `engine = "julia"` now refuses an ordered factor, a
`contr.sum` factor, or a character column whose level order R and Julia sort
differently -- and why it did NOT need to change anything for `factor()`,
`I(x^2)`, `poly(x, 2)`, `(x + z)^2` or `- term` themselves.

Two PRs, DRM.jl first: itchyshin/DRM.jl#640 (branch `claude/parity-a6-drmjl`,
head 6af7a14a4 on `main` 71e0d3379) and the drmTMB PR from
`claude/parity-a6-drmtmb` (this report's branch). The drmTMB live tests need
DRM.jl #640; until it is merged and the pin advanced, the ledger's G7 stays
BLOCKED-on-DRM.jl-PR-640.

## 1. Goal

Make the five formula constructs the A6 ledger names (`factor()`, `I()`,
`poly()`, `^`, `-`) round-trip through `engine = "julia"` with base-R
`model.matrix()` names AND the same design -- treatment contrasts, declared
factor level order -- as `engine = "tmb"`, with a RED control proving a
level-order disagreement fails by NAME rather than silently by number.

## 2. Implemented

What the RED measurement (G1, this run, unmodified pin DRM.jl 430ef64cc,
`scratch a6r/g1-probe.R`) actually showed, before any change:

- The five constructs were already fine. Names identical (`TRUE`) and
  max|coef diff| `factor(g_chr)` 1.635e-11, `g_fac` (3 levels declared
  low<mid<high) 3.725e-12, `factor(g_fac)` 3.725e-12, `x * g_fac` 2.626e-14,
  `I(x^2)` 2.626e-14, `poly(x, 2)` 2.609e-14, `(x + z)^2` 2.628e-14,
  `x + z - z` 2.622e-14, `sigma ~ g_fac` 2.889e-11; |dlogLik| <= 2.217e-12.
  The ledger's premise "refuses or mis-parses" did not reproduce at this pin
  (the #467 fixtures and design 258 S3/N1 had already closed it).
- The RED was CONTRAST fidelity, name-identical and SILENT. `options$coef_labels`
  is echoed positionally, so any design with the same column count came back
  under R's names: a character column with mixed-case levels (R `en_AU`
  collation `alpha < Beta < gamma`, Julia codepoint `Beta < alpha < gamma`)
  max|coef diff| 4.618e-01 (`-0.230884` vs `0.230884` under the same name
  `factor(m_chr)Beta`); an ordered factor (R: contr.poly `.L/.Q`) 1.180e+00;
  a `contr.sum` factor 1.757e+00; a factor whose levels were reversed on the
  Julia side only: `NO ERROR`, raw `g_fac: mid | g_fac: low` reported as
  `mu_g_facmid | mu_g_fachigh`.

Changes:

- **DRM.jl (#640, commit 424e2665e)**: `_bridge_check_coef_labels_fidelity` --
  every regression block DRM.jl can render itself
  (`_bridge_rendered_regression_blocks`, factored out of the self-rendering
  `_bridge_public_to_raw_coef_map` so both paths share ONE renderer) must
  render to exactly the supplied base-R names, in order; otherwise the fit is
  refused naming the dpar, R's spelling, DRM.jl's spelling and the Julia raw
  columns, with an actionable hint. Blocks DRM.jl cannot render (the `raw,
  raw` fallback, `vouched == false`) and blocks with no formula counterpart
  (`phylocov`, `resd`, `sd`) are still echoed verbatim; the count check is
  unchanged and still fires first.
- **DRM.jl (#640, commit 6af7a14a4)**: `_bridge_bool_column_atoms` renders a
  `Vector{Bool}` covariate as R's `<sym>TRUE` (plain and in interactions),
  because the walk-around found `y ~ x + flag` refused as `flagTRUE` vs
  `flag` although the designs are the same 0/1 column (2.626e-14 at the pin).
- **drmTMB (`R/julia-bridge.R`, producer only)**: after `model.frame()`, the
  producer builds R's actual design and the same frame forced to
  `contr.treatment`; on any numeric difference it aborts BEFORE Julia
  starts, naming each factor/character/logical column and why (ordered
  factor / explicit `contrasts` attribute / `options("contrasts")`). A
  `contrasts` attribute that IS treatment coding passes. This is the first
  line; DRM.jl's check is the second, for disagreements the R data cannot
  show (the locale case, the reversed-levels case).
- **drmTMB tests**: `tests/testthat/test-julia-formula-constructs.R` (new).

## 3a. Decisions and Rejected Alternatives

- **Refuse, do not re-base, a character column whose R level order differs
  from Julia's.** The honest fix is for drmTMB to marshal character
  covariates as R-ordered factors (then Julia receives a `CategoricalVector`
  with R's levels, exactly as a declared factor already does -- measured:
  `factor(m_chr)` declared in R restores parity, `<= 1e-4`). That lives in
  `drm_julia_bridge_data()` / the payload, outside this leaf's OWNS, so it is
  filed as a residual, and the refusal message tells the user to declare the
  factor. Rejected: teaching DRM.jl R's collation -- impossible in general.
- **Two lines of defence rather than one.** R-side: catches every contrast
  disagreement visible in the R data, before Julia starts, with a message
  in drmTMB's own vocabulary. DRM.jl-side: catches what only the Julia design
  can show. Rejected: R-side only (cannot see Julia's level order) and
  DRM.jl-side only (an ordered factor would then fail with a
  `grp.L`-vs-`grpmid` message that does not say "ordered").
- **Compare designs numerically (`all.equal` of two model matrices), not
  contrast NAMES.** Rejected: inspecting `attr(col, "contrasts")` strings --
  a matrix-valued contrasts attribute, or `options("contrasts")`, would slip
  through a string check; the numeric comparison is the definition.
- **Fidelity errors propagate; a rendering failure is not swallowed.** A
  block DRM.jl cannot render is skipped only via the existing `raw, raw`
  fallback path, never via a `try/catch` around the renderer. Rejected:
  catching renderer errors as "not vouched" (silent skip, the failure mode
  design 258 S3 forbids).
- **Rebased the DRM.jl branch onto `main` 71e0d3379** (one commit past the
  pin, only `tools/totoro_run_suite.sh`) so the suite ran on the merge
  result.

## 4. Files Touched

drmTMB (`claude/parity-a6-drmtmb`):
- `R/julia-bridge.R` -- `drm_julia_bridge_payload_coef_labels()` only: the
  treatment-contrast comparison and abort between `model.frame()` and
  `model.matrix()` names.
- `tests/testthat/test-julia-formula-constructs.R` -- new.
- `docs/dev-log/after-task/2026-09-05-a6-formula-constructs.md` -- this file.
- `.unlazy/parity/gates/leaf-a6.md` -- the ledger (EVIDENCE lines), in the main checkout.

DRM.jl (`claude/parity-a6-drmjl`, PR #640):
- `src/bridge.jl` -- `_bridge_coef_vector` (one call), `_bridge_rendered_regression_blocks`
  (new, extracted), `_bridge_check_coef_labels_fidelity` (new), `_bridge_public_to_raw_coef_map`
  (now uses the extracted renderer), `_bridge_bool_column_atoms` (new), `_bridge_render_formula_block`
  (uses it).
- `test/test_bridge_formula_constructs.jl` -- new.
- `test/runtests.jl` -- one `include` line (outside OWNS; a test file that never runs is not a test).
- `test/test_bridge_coef_labels_echo.jl` -- arbitrary renamed labels (`x_renamed`, `sigma_only`)
  become base-R spellings (outside OWNS; forced by the contract change -- the echo no longer accepts
  a name DRM.jl's own rendering contradicts).

Evidence (not committed to either repo):
- pin clone `docs/dev-log/evidence/parity-fixtures.tsv` -- 8 rows appended (below).
- scratch `a6r/`: `g1-probe.R/.log`, `a6-parity-rows.R/.tsv/.log`, `neighbours.R/.log`,
  `red-control-jl.log`, `red-control-r.log`, `r-live-fixed.log`, `r-live-fixed2.log`,
  `r-nojulia-suite.log`, `r-live-suite.log`, `jl/*.log`.

## 5. Checks Run

Parity rows (appended to the pin clone TSV, DRM.jl 430ef64, drmTMB 146186fa8, tol 1e-4):

```
formula_factor_3lvl_nonalpha  PARITY_PASS  coef_diff=2.626e-14  loglik_diff=1.592e-12
formula_factor_call           PARITY_PASS  coef_diff=2.626e-14  loglik_diff=1.592e-12
formula_factor_interaction    PARITY_PASS  coef_diff=2.777e-12  loglik_diff=1.222e-12
formula_I_x2                  PARITY_PASS  coef_diff=2.631e-14  loglik_diff=2.558e-13
formula_poly_x_2              PARITY_PASS  coef_diff=2.620e-14  loglik_diff=3.126e-13
formula_power_xz_2            PARITY_PASS  coef_diff=2.613e-14  loglik_diff=1.307e-12
formula_minus_term            PARITY_PASS  coef_diff=2.612e-14  loglik_diff=8.527e-14
formula_sigma_factor          PARITY_PASS  coef_diff=4.640e-11  loglik_diff=1.307e-12
```
every row: `names identical (tmb vs julia): TRUE; all named coefficients compared`.

DRM.jl on 6af7a14a4 (local, Julia 1.10.0): `test_bridge_formula_constructs.jl` 179/179;
`test_bridge_formula_labels.jl` 819/819; `test_bridge_coef_labels_echo.jl` 42/42;
`test_bridge_base_r_names.jl` 20/20; `test_bridge_lss_labels.jl` 10/10; on 424e2665e also
`test_bridge_formula_translation.jl` 52/52, `test_bridge_materialization_collision.jl` 14/14.
Full suite on Totoro (`tools/totoro_run_suite.sh 6af7a14a4…`, Julia 1.12.6, 1 core):
TOTORO_RESULT_PENDING.

drmTMB:
- `test-julia-formula-constructs.R` no-Julia: all pass, 3 live tests skipped
  ("DRM.jl engine not available"). Live against wt-a6-drmjl (6af7a14a4):
  36 expectations, `3 live tests ran`, 0 failures.
- No-Julia julia suites (`test_dir` filter
  `julia|coefficient-labels|xfam-bridge|biv-student|binomial-response|mspl-estimator|cran-lane-filter`,
  DRM_JL_PATH unset, NOT_CRAN=true): on 146186fa8 files=46 failed=0 warnings=0 skipped=36 passed=1685;
  on the rebased head f751693f6 (origin/main 67703f541 + 2 commits, incl. the logical-covariate test):
  files=47 failed=0 warnings=0 skipped=36 passed=1709 (`a6r/r-nojulia-suite-rebased.log`).
- LIVE julia suites against wt-a6-drmjl (same filter, hunting false refusals from the fidelity
  check across every route, DRMTMB_JULIA_TESTS=true, on 146186fa8 with DRM.jl 424e2665e -> 6af7a14a4 mid-run
  for callr-spawned files): LIVE_TOTALS files=47 failed=0 warnings=11 skipped=0 passed=2079
  (`a6r/r-live-suite.log`; the 11 warnings are DRM.jl model warnings -- singular-Hessian
  pseudo-inverse, non-unit tree height, aic on a REML fit -- none about labels). The
  formula-constructs file re-run live on the rebased head f751693f6: 3 live tests ran, 0 failures.
- Walk-around (`a6r/neighbours.R`, live, fixed DRM.jl): `x + x:g_fac` (interaction without
  main effect) 2.626e-14; `0 + g_fac` and `g_fac - 1` (full dummy) 2.619e-14; `g_fac * h_fac`
  2.633e-14; factor in both dpars 1.887e-11; `poly(x, 2) * h_fac` 2.009e-12;
  `I(x^2)` + `sigma ~ I(z^2) + h_fac` 2.239e-12 -- all names identical. Logical covariate:
  refused before the Bool fix ("flagTRUE" vs "flag"), passes after it (in the live test list).

## 6. Tests of the Tests

- DRM.jl RED control: `src/bridge.jl` with the fidelity call replaced by a comment ->
  `test_bridge_formula_constructs.jl` FAILS: 89 pass / 1 fail,
  `NOT REFUSED: ["mu_(Intercept)", "mu_x", "mu_grpmid", "mu_grphi", "sigma_(Intercept)"]`
  (`a6r/red-control-jl.log`); restored byte-identically, sha256
  `06a70828d057a8824f5328d6328d7d0920c3f86d5e4b6709dff448b280c35781` before == after.
- drmTMB RED control: producer with `if (FALSE && any(coded))` -> the no-Julia refusal
  tests FAIL (7 failures at `test-julia-formula-constructs.R:78,82,84,91,107,111,112`,
  `a6r/red-control-r.log`); restored byte-identically, sha256
  `6ade75ed59cf13bb088578bd1e2a9499f5e911ce4e91cd119f2dc7d61360d67e` before == after.
- The G5 live RED control asserts the refusal names BOTH spellings (`g_fachigh` from R,
  `g_faclow` from DRM.jl); at the pin the same reversal was `NO ERROR` (G1).
- The native-engine control: the ordered factor the producer refuses is still accepted by
  `engine = "tmb"` with names `(Intercept), x, g_ord.L, g_ord.Q` -- the refusal is
  engine-specific, not a formula error.

## 7a. Issue Ledger

- DRM.jl #467 (formula constructs via `drm_bridge`): the five constructs measured at parity
  at 430ef64cc; contrast fidelity closed by #640.
- DRM.jl #609 (factors case): the 3-level, non-alphabetical, declared-order factor is
  `formula_factor_3lvl_nonalpha` above and the G5 RED control.
- design 258 S7: the echo is now fidelity-checked; S7.2/S7.3 text does not yet say so
  (residual, doc not in OWNS).
- Found, deferred (outside OWNS): character covariates should cross as R-ordered factors
  (see 3a); an unused factor level (`factor(..., levels = c(..., "never"))`) gives R 5
  columns (an all-zero column the native engine still fits) vs Julia 4 -> refused by the
  count check, pre-existing.

## 8. Consistency Audit

- Every construct in the ledger, plus the factor shapes next to them (interaction-only,
  no-intercept full dummy, two-factor cross, factor in both dpars, poly x factor,
  I() on both dpars, logical), measured live against the fixed DRM.jl (section 5).
- All six DRM.jl bridge-label test files re-run on the branch head; drmTMB's live
  `coefficient-labels` echo tests (relmat structured route, cross-family) are in the LIVE
  suite run above, so the fidelity check was exercised on structured/xfam routes too.
- The previous attempt's uncommitted DRM.jl diff was kept only after re-reading it line by
  line and re-measuring every number it relied on in this run (its probes were re-run, not
  trusted): the `vouched` flag (`public === raw` identity on the fallback path), the
  CumulativeLogit intercept projection, and the `raw_names[range]` alignment check all
  re-verified by the 179-test file.

## 9. What Did Not Go Smoothly

- I passed `threads = FALSE` to `drmTMB()` in the first G1 probe (the standing rule's
  "threads = FALSE always" is about BLAS/`OPENBLAS_NUM_THREADS`, not a `drmTMB()` argument);
  every case errored "does not use arguments in `...`" until removed.
- `pkill -f <script name>` inside an ssh one-liner that ALSO spells the script name killed its
  own shell twice; fixed by separating the kill and the relaunch into two ssh calls and using
  `[t]otoro_…` bracket patterns.
- The compound "commit && push && ssh relaunch" command tripped the destructive-command guard;
  split into plain steps.
- The first Totoro suite run (424e2665e) was superseded by the Bool-covariate commit and
  killed; the suite was relaunched on 6af7a14a4.

## 10. Known Residuals

- G7 (merge + pin advance) is the integrator's; the drmTMB live tests need DRM.jl #640
  merged before they can run in any lane other than a local `DRM_JL_PATH` pointing at the
  branch.
- Character covariates are refused (not re-based) when R's collation order differs from
  Julia's; the marshalling fix is outside OWNS.
- Design 258 S7 prose not updated (not in OWNS).
- The DRM.jl RED control was measured on the 146-test version of the file (first commit);
  the second commit added tests but did not touch the fidelity check.
- The LIVE suite totals were measured on 146186fa8 (pre-rebase; the rebase onto origin/main
  67703f541 touched `R/julia-bridge.R` only in the family-registry functions, applied cleanly);
  only the formula-constructs file was re-run live on the rebased head.

## 11. Team Learning

- A positional echo of names is a claim about the DESIGN, and the count check only guards
  the shape. Any time one side supplies names for the other's columns, compare the other
  side's own rendering of those columns before trusting the names -- and keep the check
  where the design lives.
- "Refuses or mis-parses" premises age fast in a two-repo programme: re-measure the RED
  before building the fix; here the real defect was one level down (contrasts), silent, and
  name-identical.
- A design-level refusal must be tested against the shapes the engines DO agree on
  (logical covariates, full dummy coding, interaction-only factors), or the check ships
  false refusals.

## 12. Cross-Product Coverage

The cross-cutting thing touched is the `engine = "julia"` coefficient-label round trip
(`options$coef_labels` -> `_bridge_echo_coef_labels` -> fidelity check).

Covers ✓: univariate Gaussian mu/sigma blocks for factor() / declared factor / character /
logical covariates, interactions, `I()`, `poly()`, `^`, `-`, full dummy coding, sigma-side
factors; bivariate `biv_gaussian` mu1/mu2 (DRM.jl test (d)); the R-side refusal for
ordered / contr.sum / options("contrasts") factors on any dpar the producer labels.

does NOT cover ✗: non-Gaussian families beyond what the LIVE julia suite exercises (the
fidelity check runs on every family's fit, but only the routes in the suite were measured);
`cumulative_logit` cutpoint projection under a supplied echo with a factor (renderer path
exists, not measured here); LSS `sd()`/`sd_phylo()` blocks (deliberately skipped by the
check, echoed verbatim); `newdata` prediction with materialised columns (#467's own
residual); character covariates with locale-dependent order (refused, not fixed); an
unused factor level (count refusal, pre-existing); DRM.jl on Julia 1.12 beyond the Totoro
suite run.
