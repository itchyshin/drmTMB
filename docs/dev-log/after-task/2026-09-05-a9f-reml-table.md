# A9f: REML support by route, one generated table across both engines (#1142 remainder)

**Reader**: anyone deciding what #1142 / DRM.jl #624's "REML wherever possible" should
cover next (A11 or a follow-up leaf); anyone hitting a raw Julia stack trace on a REML
request through `engine = "julia"` and wanting to know if it's a known gap; anyone
maintaining `inst/extdata/julia-capabilities.tsv` or the REML gates in `R/julia-bridge.R`
/ `R/drmTMB.R`.

Leaf ledger: `.unlazy/parity/gates/leaf-a9f-reml-table.md`. Worktree branch
`claude/parity-a9f-reml-table` off `origin/main` (66f0a93f6, after #1169/#1177/#1179).
DRM.jl pin `430ef64cc`.

## 1. Goal

Build ONE generated, regenerable table showing REML support per route across native
`engine = "tmb"`, native DRM.jl, and the R<->Julia bridge, measured with the
`estim_method` oracle (DRM.jl #625), with a gaps column -- not implement any REML
capability. This is the deferred remainder of #1142 ("REML support in one generated
table per route").

## 2. Resume note

This is a resume of a session killed by a cap after ~10 minutes. `git status`/`git log
origin/main..HEAD` at the start showed the worktree branch clean and 22 commits BEHIND
`origin/main` (not ahead) -- the previous attempt left no uncommitted work in this
worktree to re-verify. The branch was fast-forwarded to `origin/main` (66f0a93f6) before
any new work started; nothing was "kept from a previous attempt" because nothing was
there.

## 3. Implemented

- `tools/write-reml-route-table.R` -- defines `drm_reml_route_table_rows()` (the 30-row
  data) and `drm_reml_route_table_lines()` (markdown renderer); writes
  `docs/design/261-reml-by-route.md` only when run as `Rscript
  tools/write-reml-route-table.R` (guarded by `sys.nframe() == 0L`), so
  `source()`-ing it for a test has no file-write side effect.
- `docs/design/261-reml-by-route.md` -- GENERATED, 361 lines, 30 rows (21 TSV capability
  rows, several split into per-family sub-rows for `phylo_count_large_p`,
  `phylo_gamma_beta_binomial`, `general_covariance_structured`; plus A5's three
  ordinary-random-effect shapes, not yet a TSV row).
- `tests/testthat/test-reml-route-table.R` -- two tests: byte-identical regeneration
  (calls `drm_reml_route_table_lines()` in-process and diffs against the committed
  file), and a sanity check that every TSV-sourced `capability_id` is real, every row's
  `agree` is a real vocabulary value, and every `"NO"` row carries a non-empty gap note.
- `docs/dev-log/evidence/julia-r-parity/reml-by-route/` -- `README.md` (provenance,
  D-139 estimate-vs-actual, key findings, RED CONTROL record), the two probe scripts and
  their logs (`native_reml_probe.R/.log`, `bridge_reml_probe.R/.log`,
  `bridge_reml_probe2.R/.log`), and `a5-census-verbatim.tsv` (A5's PR #1170 receipts,
  reproduced verbatim since that branch is not yet merged).
- `NEWS.md` -- one bullet naming the four findings.

## 4. Route list and its sources (G1)

30 rows total: the 21 rows of the committed `inst/extdata/julia-capabilities.tsv`
(TSV rows), split into 30 by giving `phylo_count_large_p` (2), `phylo_gamma_beta_binomial`
(3), and `general_covariance_structured` (4) one row per REML-relevant family instead of
one row per capability_id, PLUS A5's three ordinary-random-effect shapes
(`gaussian_random_intercept`, `gaussian_random_slope`, `gaussian_sigma_random_intercept`;
PR #1170, not yet a TSV row -- A2 in the ultra-plan backlog owns adding one).
`drm_reml_route_table_rows()` asserts at call time that every `TSV`-sourced
`capability_id` is present in `inst/extdata/julia-capabilities.tsv`; this is the
mechanism the RED CONTROL (section 7) exercises. The task brief named "the six A3
routes"; A3 (PR #1168) actually shipped nine fixed-effect rows, and all nine are
included (`fe_student`, `fe_lognormal`, `fe_gamma`, `fe_poisson`, `fe_nbinom2`,
`fe_beta`, `zi_poisson`, `zi_nbinom2`, `hurdle_nbinom2`) -- treated as "the A3 routes",
not literally six.

## 5. Measurements (D-139)

Two live sessions, estimated <10 min combined before running, both well under budget
(see the evidence README for the full estimate-vs-actual):

- **Native TMB, no Julia** (`native_reml_probe.R`): 13 cells, all completing in
  seconds once `load_all()` finished. No env vars needed.
- **Bridge, one warm Julia session** (`bridge_reml_probe.R`): 10 cells, `TOTAL WALL
  TIME: 39.4s` (first cell pays the ~31s Julia boot).
- **Bridge, one follow-up session** (`bridge_reml_probe2.R`): 1 cell (Poisson +
  `relmat()`), ~25s boot then a 0.1s call.

Every "measured this run" cell in the table cites one of these three logs by row/label.
Every citation cell reproduces an existing receipt verbatim (A3 PR #1168, A5 PR #1170's
`census.tsv`, DRM.jl issue #624's own census comment, or DRM.jl's own committed test
files `test_cox_reid_poisson_ranef.jl` / `test_cox_reid_poisson_phylo.jl`, read directly
from the pinned clone) rather than re-measuring what those sources already measured.

## 6. Findings (the Gaps column, G5)

Full text and citations are in the generated table; summarized here:

1. **`biv_gaussian_residual`** -- native TMB fits a plain fixed-effect bivariate
   Gaussian REML; neither DRM.jl native nor the bridge admits it. New finding, not one
   of #624's three named items.
2. **`gaussian_phylo_mean`** -- DRM.jl #624 item (c) verbatim (mean-only phylogenetic
   Gaussian REML). Explicitly out of scope for this leaf per the task brief; recorded,
   not re-litigated.
3. **`phylo_count_large_p` (poisson)** -- NOT a defect: DRM.jl's Cox-Reid Laplace REML
   (#443/#450) covers a route native TMB's REML (Gaussian/binomial only) does not.
   Documents #1142 item 4's asymmetric-surface question.
4. **`general_covariance_structured` (gaussian)** -- same asymmetry as finding 2, for
   `relmat()` instead of `phylo()`.
5. **`general_covariance_structured` (poisson)** -- NEW finding, opposite direction from
   finding 6: DRM.jl's own test suite (`test_cox_reid_poisson_phylo.jl:134-142`, #450)
   fits Poisson+`relmat()` REML natively, but `engine = "julia"` can never reach it
   because `drm_julia_has_structured_term()` refuses ANY structured term for EVERY
   family before the Poisson-specific gate runs. Re-verified live
   (`bridge_reml_probe2.log`).
6. **`fe_poisson` / `zi_poisson`** -- honesty-of-interface gap: `drm_julia_reml_supported()`'s
   `poisson_reml` branch never checks whether the model has any random effect at all, so
   a fixed-effect-only Poisson REML request is forwarded to Julia instead of refused on
   the R side; DRM.jl itself throws (`test_cox_reid_poisson_ranef.jl`'s own assertion:
   "Fixed-effects-only Poisson has no variance component to restrict"), and the user
   sees a raw `ArgumentError` + full Julia stacktrace (`Error happens in Julia.`)
   instead of the polished `drm_julia_refuse_reml_unsupported()` message every other
   refused cell gets.
7. **`gaussian_random_slope`** -- #1142/#624's own central example (Gaussian random
   slopes) -- but A5's own census (cited, not re-measured) shows the SAME
   honesty-of-interface defect as finding 6: the shipped layer's refusal is a raw Julia
   `ArgumentError`, not the polished cli_abort, because `drm_julia_reml_supported()`'s
   Gaussian branch checks only phylo/`sd()` presence, never whether the mu-side random
   effect is a plain single intercept.
8. **`gaussian_sigma_random_intercept`** -- #1142's own motivating example; recorded as
   the CONTROL showing the polished refusal DOES fire when the maintainers already
   special-cased a shape (`drm_julia_check_ordinary_sigma_ranef_route_limits()`).

Findings 5-7 span four cells sharing one root cause (`drm_julia_reml_supported()`
screens for phylo/`sd()`/structured-term presence but never for "is this random-effect
shape one DRM.jl actually restricts, or does the model have a random effect at all").
**None were fixed here** (task brief: "Do NOT implement REML anywhere"). **No GitHub
issue was filed for them in this leaf**; they are named for A11 or a follow-up leaf.

## 7. RED CONTROL (G4)

Planted: renamed the first row's `capability_id` in `tools/write-reml-route-table.R`
from `base_gaussian_location_scale` to `RED_CONTROL_bogus_capability_id_not_in_tsv`.
`shasum -a 256` before: `8ac1e7d431fa68139f645d1d24b0e54d4aaf88fc422e83a037a178f5be56627f`.
Ran `tests/testthat/test-reml-route-table.R`: went from 5/5 pass to **1 error + 2
failures**, all three naming the planted id verbatim in the generator's own
`stop("route(s) claimed as TSV-sourced but absent from ...: RED_CONTROL_bogus_capability_id_not_in_tsv")`.
Restored from a saved copy; `shasum -a 256` after matched the pre-plant hash exactly.
Re-ran the suite: 5/5 pass again.

## 8. Checks run

- `Rscript tools/write-reml-route-table.R` twice in a row: identical `docs/design/261-reml-by-route.md`
  both times (`wrote 30 REML route rows to ...`; no diff between runs).
- `testthat::test_file("tests/testthat/test-reml-route-table.R")`: 5/5 pass (both before
  and after the RED CONTROL restore).
- `testthat::test_file("tests/testthat/test-reml-direct-sd-phylo.R", NOT_CRAN=true)`:
  8/8 pass, 0 failures -- re-run this session as the `location_scale_scale` native-TMB
  citation, not written from scratch.
- `git diff --stat -- R/ src/`: empty. This leaf touches only the files in OWNS
  (`tools/write-reml-route-table.R`, `docs/design/261-reml-by-route.md`,
  `tests/testthat/test-reml-route-table.R`,
  `docs/dev-log/evidence/julia-r-parity/reml-by-route/`, this file, `NEWS.md`).

## 9. Not covered

- The q4_vcov-on-REML question (DRM.jl #624 item 3) -- SE/vcov correctness on the one
  route (`biv_q4_phylo_reml`) where all three columns already agree the model fits.
  Explicitly named out of scope in the task brief.
- No REML capability was implemented, widened, or narrowed anywhere in this leaf.
- The four-cell honesty-of-interface gap (findings 5-7) is recorded, not fixed, and no
  GitHub issue was filed for it.
- `engine_control_surface` and `cross_family_latent` are recorded as N/A / structurally
  not comparable rather than FITS/REFUSES, since one is orthogonal to the REML/ML choice
  and the other's native side does not exist under any estimator.
- A5's `census.tsv` was read and cited, not independently re-measured (per the task
  brief's "do not re-measure what they measured"); the three A5-sourced rows carry that
  branch's numbers verbatim.
