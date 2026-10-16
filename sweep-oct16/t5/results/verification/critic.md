# t5 completeness critic: final decisions on C1–C4 and coverage gaps

**What I did.** I read the t5 results (summary.md, cells.csv, julia_direct.csv, julia_probes.csv, r_probe_*.csv, bridge.csv) and the t5 scripts. I read DRModels and drmTMB code at the pins. I read the diffs of open PRs #1045, #1057, #1082, #1095 and #1096, and the comments on #1089, through the GitHub REST API (read-only; nothing was posted). I recomputed some comparisons from the committed CSVs. I ran one new probe, on Poisson with whole rows missing. Its script and output are `<scratchpad>/verify/t5-completeness-critic/rowmissing.jl` and `<scratchpad>/verify/t5-completeness-critic/rowmissing.out`. I re-ran nothing else.

## 1. Final decisions

### C1: a Union{Missing,Float64} predictor with no missing values is fitted as a factor
**Action:** new issue. **Target:** itchyshin/DRModels.jl. **Severity:** high.

**Rationale.**
- **What goes wrong.** `_design` narrows only the response (gaussian_core.jl:391). It sends the raw predictor column to `schema` and `modelcols` (:411, :421). StatsModels 0.7.10 then dummy-codes any vector whose element type is not a Number (schema.jl:207).
- **drm_listwise does not help.** It returns the columns un-narrowed when it drops no rows (missing_data.jl:111).
- **Severity: the repro lens wins.** It ran what the skeptic only read: `df[completecases(df), :]`, `subset` and `filter` all keep the Union type and give the saturated fit (190 coefs). It also measured the dangerous form. With a covariate that has only a few distinct values, all three families return a plausible fit with `converged=true` (6, 9 and 7 coefs; loglik within about 1.7 of the correct fit). Gamma with the default `:LA` is saturated and still reports `converged=TRUE`.
- **Venue: a new issue, not a comment on #1089.**
  - The trigger contains no missing values, so it falls outside #1089's title and ask.
  - The lane's own #1089 comment (6224084518) does not mention it.
  - A fix for #1089 that drops rows the way drm_listwise does would leave this case broken. #1057's missing_data.jl hunks do not touch line :111 (I checked the PR diff).
  - The new issue should cross-reference #1089 (same categorical-coding root cause as its KeyError), #1086 (the schema_cache confound) and #474.

**Corrections to the claim's wording.**
- **State the behaviour per marginal:**
  - Gaussian: saturated fit; `converged=false` with many distinct x values, `true` with few.
  - Poisson, default `:LA`: loud but cryptic error, "matrix contains Infs or NaNs". Poisson with `:Laplace`: silent, `converged=true`.
  - Gamma, `:LA`: silent, `converged=TRUE`.
  - With few distinct x values: silent and plausible in all three families.
- **Remove Vector{Any} from the defect.** bridge.jl:1558-1565 relies on purpose on a `Vector{Any}` column becoming categorical, to implement R's `factor(x)`. The fix must therefore narrow with `nonmissingtype` (Union{Missing,T} → T), the way StatsModels' `missing_omit` does. It must not use blanket `identity.` narrowing. Union{Nothing,Float64} is also out of scope.
- **Do not cite docs/src/reference/model-specification.md:83-84 as a trigger.** That example is the `mi(x)` joint route (gaussian_core.jl:589-595) with real missing values.
- **Reproductions need a fresh `bf()` for every fit.** The schema cache on the formula object (#1086) can otherwise mask or carry over the bug.

### C2: a NaN or Inf predictor returns a fit made of starting values on Poisson and other (1|g) routes
**Action:** new issue. **Target:** itchyshin/DRModels.jl. **Severity:** low.

**Rationale.**
- **I am overriding both lenses on venue.** Both recommended a comment on #1045, but #1045 is not a usable ledger entry for this:
  - It is a draft marked "Do not merge". REST shows it was last updated 2026-10-09 and has 0 comments.
  - It predates the pin and will need a rebase.
  - Its Fixes list (#1009, #1012, #1019, #1021) does not include predictors.
  - CLAUDE.md makes Issues the ledger, and the lane's own #1089 comment promised the NaN-x case would be "filed or linked separately".
- **Issue body.**
  - Say that #1045 head df0c8f4 fixes the case; both lenses ran it.
  - Ask #1045 to add `Fixes #<new>` plus regression tests for Poisson, Gamma, NB2 and Binomial (1|g), and for the `:Laplace` route, with a NaN or Inf on a row whose response is observed. Mentioning #1045 in the issue creates the back-link, so no separate PR comment is needed.
  - Cross-reference #1089 and #1019.
- **Severity: the skeptic wins.** Every returned fit is flagged by at least one of: loglik −Inf or −1e18, `converged=false`, the show() header, aic returning NaN with a warning, or check_drm ok=false. Only coeftable and stderror look normal. `drm_listwise` already drops NaN and Inf rows (`_is_missing_cell`, missing_data.jl:22). The bridge drops NA rows in R before the call (julia-bridge.R:765-767 and 2950-2961).
- **Scope for the issue body, from the repro lens:** NB2, Binomial and Student (Binomial and Student set the raw `fit.converged=true`), Poisson (1+x|g), Poisson REML, and `:Laplace` on Poisson, NB2, Binomial and Gamma.

**Corrections to the claim's wording.**
- Replace "silent wrong result" with: "no error, and a coefficient table of starting values with finite SEs".
- Three in-code statements are false and should be fixed in the same PR: missing_data.jl:3-7, missing_data.jl:57-58 and gaussian_core.jl:1324.
- Open PR #1095 changes the `:Laplace` sentinel gradient to NaN (ordinary_laplace.jl:141). Describe the symptom on the default `:LA` route so the issue text does not go stale.

### C3: a missing value in the grouping column becomes an extra random-effect level
**Action:** new issue. **Target:** itchyshin/DRModels.jl. **Severity:** medium (both lenses agree).

**Rationale.**
- **Venue: the repro lens wins** (a new issue, not a comment on #1089).
  - The failure is a silent wrong model, not a loud error.
  - The cause is in a different place. `_group_index` (gaussian_ranef.jl:212-219) uses `missing` and NaN as ordinary Dict keys. `_split_ranef` (:137-138) routes the grouping column around the StatsModels schema, so it never raises #1089's KeyError.
  - No open PR covers it. #1045's predictor checker explicitly skips grouping factors (from the PR's gaussian_core.jl hunk). #1057's input_validation.jl adds only length checks.
  - The lane's #1089 comment already announced that this would be filed separately.
- **Cross-reference** #1089, and #1022 and #1057, which are the natural vehicle for validating the group column.

**Corrections to the claim's wording.**
- Evidence for "26 groups" must come from the fit, not from the probe script's `n_groups_seen`: `ranef` has length 26, and the loglik equals a fit with a literal 26th level to 15 digits.
- engine="julia" protection was measured only for Gaussian. For Poisson and Gamma it holds by construction, because the R-side drop is the same family-agnostic function (julia-bridge.R:2950-2961), but those fits died at #1551.
- NaN in a numeric group column is pooled the same way.
- Cite the existing guards as the pattern to extend: temporal.jl:242-244, gaussian_lss.jl:298-299, inference.jl:1969.
- Workaround: `drm_listwise`.

### C4: g_tol on the :Laplace route
**Action:** comment on itchyshin/DRModels.jl#947. **Severity:** low.

**Rationale.**
- **Both lenses agree on the mechanism.** The guard at ordinary_laplace.jl:165 (`nllhat > nll(res_fast)`) throws away an LBFGS polish that met g_tol, over an objective difference of 1–6 ulps. The point it keeps then passes the relative-gradient rule (sparse_laplace_glmm.jl:225-230), so the Newton polish at :180 never runs.
- **The skeptic wins on "is it a contract defect".** The 2e-8 gap is well inside the route's documented 1e-5 bar, and the converged policy is deliberate (#491, D-179).
- **The repro wins on "is it a real wart".** g_tol is inert below about 1e-6 and non-monotone: tightening it moved poisson_y20_x20 (dup) from 3.0e-12 to 3.5e-10 away from native. That contradicts #813's own rule against value-based acceptance, and the "tighten g_tol" advice in convergence.md:65, which #947 already tracks.
- **No new issue.** None of the open PRs that touch ordinary_laplace.jl (#1082, #1095, #1096) changes :165; I checked the diffs.

**Receipt wording.** "FAIL against the brief's 1e-8 bar. The cause is DRModels' optimiser stopping point (ordinary_laplace.jl:165), within the route's 1e-5 contract. It is not a weights or NA defect."

## 2. Gaps, highest priority first

1. **Receipt mis-attributions that change verdict text.**
   - **Poisson/Gamma bridge rows should read "BLOCKED (#1551)", not "FAIL".** This applies to both "nobs: bridge = native" and "engine = julia = native". The crash happens after the Julia fit, in the label echo (bridge.jl:1880), so no NA-drop mismatch was measured. The drop rule itself is the family-agnostic `drm_julia_drop_missing_rows`, which the 9/9 Gaussian cells already exercise.
   - **Even after #1551 is fixed, Poisson/Gamma parity is not testable until `marginal` is forwarded.** Otherwise the comparison is AGHQ-5 against Laplace, which differs by up to 4.5e-2 in logLik.
   - **The "DRModels direct on duplicated rows = native integer weights" FAIL is not a weights result.** Native integer-weight fits equal duplicated-row fits to 1.5e-10, so this row compares DRModels and native on the same duplicated data. The non-duplicated `:Laplace` comparison passes at 4.6e-9. The FAIL is optimiser stopping (C4). DRModels' weights semantics remain untested, because `drm` has no `weights` keyword.

2. **Fix-scope facts the verifiers did not establish.** These change the text of the C1 and C3 issues.
   - The bridge relies on Vector{Any} being coded as a factor (C1 above).
   - The `identity.` narrowing on drm_listwise's drop branch (missing_data.jl:118) would also turn a `Vector{Any}` numeric factor column into a continuous Float64 column. I read this, did not run it. The C1 fix should not copy `identity.` to the no-drop branch.
   - The verifiers judged "no existing tracking" from PR bodies. I confirmed it from the diffs for #1045, #1057, #1082, #1095 and #1096.

3. **The issue snapshot is stale.** It ends at DRModels #1108 and drmTMB #1549, before the lane's own filings. A live read shows new items from the concurrent t4 lane (DRModels #1109; drmTMB #1552 and #1553), whose titles do not overlap C1–C4. I checked titles only, so search the bodies again just before filing.

4. **Some bars were measured on nobs only.** I recomputed them from the committed CSVs; none of this changes a verdict, but these lines should go into compare.R.
   - drm_listwise vs complete cases: ΔlogLik and Δb_mu1 are exactly 0 in 27/27 cells.
   - Raw `drm` vs complete cases on Poisson/Gamma cells with NA only in y: ΔlogLik = 0 in 4/4.
   - Bridge duplicated-row fits vs native integer weights: Δcoef 3.3e-11 (the summary reports only logLik).
   - The NaN-coded leg (JD_nan: 14 errors, 13 fits) has no row in compare.R or summary.md, so C2's lane evidence currently lives only in julia_direct.csv.

5. **One hypothesis tested and refuted.** I suspected C1 could also be reached inside DRModels itself: `_subset_table_rows` keeps the Union type (gaussian_core.jl:1312), and x could be missing only on rows whose y is also missing. With `missing` coding, Poisson `:LA` and `:Laplace` both throw `KeyError` instead (rowmissing.out); the fit on the remaining complete rows gives loglik −113.843. So this pattern belongs to #1089, not C1. It is a useful data point for #1089: the same pattern coded as NaN fits correctly (C2 repro), but coded as `missing` it errors.

6. **Modalities not run (low priority).**
   - The draft heads DRModels #1061 (prior weights) and drmTMB #1502 (weights under engine="julia") were not run. Running them, as the verifiers did for #1045, would give forward-looking evidence for the integer-weights bar on Julia.
   - engine="julia" with Gaussian `miss_control(response="include")` and NA in x was not run. In that case R skips its row drop (julia-bridge.R:765-767). Gaussian fails loudly on both codings, and `include` is refused for non-Gaussian families (julia-bridge.R:1143-1152), so I expect no verdict change.
   - C4 was not measured on Binomial, NB2 or Beta `:Laplace`; this does not change the low disposition.
   - CSV.jl's default `missingstring=""` reads R's "NA" cells as strings, which StatsModels then fits as a factor in any package. The C1 issue's realistic-input example should say `CSV.read(...; missingstring="NA")`.