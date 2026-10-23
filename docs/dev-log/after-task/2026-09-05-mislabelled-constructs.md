# mislabelled-constructs: the two silent cells re-measured off one fixture, and the one that was still real

**Reader**: anyone reading PR #1227's classification table and wondering how
far it generalises; anyone touching
`drm_julia_bridge_payload_coef_labels()` (`R/julia-bridge.R`), DRM.jl's
`_bridge_check_coef_labels_fidelity` / `_bridge_rendered_regression_blocks`
(`src/bridge.jl`), or the location-scale-scale `sd(<group>)` bridge route.

Two PRs, DRM.jl first: itchyshin/DRM.jl#730 (branch
`claude/parity-mislabelled-constructs-drmjl`, off DRM.jl `origin/main`
`345892520`) and the drmTMB PR from `claude/parity-mislabelled-constructs`
(this report's branch, off drmTMB `origin/main` `2fcbb0fbf`).

## 1. Goal

Close the two constructs PR #1227 classified `MISLABELLED_SILENT` -- either
marshal them faithfully or refuse them by name -- and then extend the battery,
which ran on ONE Gaussian location-scale fixture, to non-Gaussian routes and
report whether the classification holds.

## 2. Implemented

**First act: read #1227.** It is OPEN, not merged. The battery test file and
its after-task report landed on `main` from an earlier A6 PR; #1227's guard
(`drm_julia_check_factor_level_fidelity()` in `R/julia-bridge.R`) has not. So
the defect was still live on `main` when this leaf started.

Then the measurement changed the shape of the job.

1. **The two cells do not reproduce as silent at a live engine.** Re-measured
   at drmTMB `2fcbb0fbf` against DRM.jl `aee371cc9` on #1227's own Gaussian
   location-scale route, both are REFUSED -- by DRM.jl's own
   `_bridge_check_coef_labels_fidelity`, which is absent from the dead pin
   `430ef64cc` #1227 measured at. The silence was a property of the pin.
2. **The classification holds on `mu` and `sigma` off Gaussian.** Both shapes,
   five families (poisson, nbinom2, binomial, gamma, cumulative_logit), both
   dpar sides: REFUSED in every cell, with declared-factor controls FAITHFUL to
   `1.05e-11` / `1.07e-11` / `5.58e-12`.
3. **It does not hold on the LSS `sd(<group>)` block, and that one was real.**
   `_bridge_rendered_regression_blocks` skips `sd_`/`sdphy_` blocks by
   construction, so the fidelity check never sees them.
   `bf(y ~ x + (1 | study), sigma ~ z, sd(study) ~ s_chr)` converged on both
   engines to an identical `logLik` `-69.917488` (diff `2.98e-13`) under
   identical names, `mu`/`sigma` faithful to `2.12e-11`, and the `sd` block off
   by **`1.3853`** -- `s_chrBeta` `+0.692648` on tmb and `-0.692648` on julia.
4. **DRM.jl #730** adds `_bridge_check_lss_coef_labels_fidelity`, comparing the
   single-component LSS route the same way, refusing by name with both
   spellings. The multi-IID route is deliberately left uncompared: it qualifies
   each public spelling with a `"<group>: "` prefix the R side does not supply,
   so comparing it there would refuse a faithful design.
5. **drmTMB** gains `tests/testthat/test-julia-formula-constructs-nongaussian.R`,
   which pins the contract across the extended fixtures.

## 3a. Decisions and Rejected Alternatives

- **Did not re-implement #1227's R-side guard.** It is written, it works, and
  it reaches the LSS route (verified here, §5). A second PR touching the same
  `R/julia-bridge.R` region would conflict with a good open PR for no gain.
  This leaf changes **no R source at all**.
- **Asserted the CONTRACT, not a specific refusal message.** The test says
  "FAITHFUL or REFUSED, never silent". That assertion is stable whichever of
  #1227 / DRM.jl #730 lands first, and it keeps holding if a future DRM.jl
  route stops rendering a block.
- **Gated only the LSS case on guard presence**, with a skip reason naming both
  PRs and the measured `1.3853`. A test that is simply red on `main` in an
  overnight merge queue is noise; a skip that states its own dependency and its
  own number is not.
- **Forced a Latin collation in the test.** testthat sets `LC_COLLATE = "C"`,
  which IS Julia's code-point order, so the first live run skipped both
  mislabel tests while reading green -- a skip masquerading as a pass. Caught
  and fixed; the test now asserts `levels(factor(m_chr)) == c("alpha", "Beta",
  "gamma")` before it trusts the fixture.

## 4. Files Touched

drmTMB (`claude/parity-mislabelled-constructs`):
- `tests/testthat/test-julia-formula-constructs-nongaussian.R` (new)
- `NEWS.md`
- `docs/dev-log/evidence/julia-r-parity/mislabelled-constructs/` (new: 3 probe
  scripts, `report.md`, `route-classification.tsv`, 3 run logs)
- this report

DRM.jl (`claude/parity-mislabelled-constructs-drmjl`):
- `src/bridge.jl` (new `_bridge_check_lss_coef_labels_fidelity` + its call)
- `test/test_bridge_formula_constructs.jl` (new testset `(f)`)

No R source file is modified by this leaf.

## 5. Checks Run

All in this run. drmTMB `2fcbb0fbf` unless stated; `NOT_CRAN=true`,
`OPENBLAS_NUM_THREADS=1`.

| check | result |
|---|---|
| new test file, no Julia | 8 pass / 0 fail / 4 skip |
| new test file, live vs DRM.jl #730 branch | **31 pass / 0 fail / 0 skip**, 4 live tests ran |
| new test file, live vs DRM.jl `aee371cc9` | 30 pass / 0 fail / 1 skip (skip names its dependency) |
| existing `test-julia-formula-constructs.R`, live vs DRM.jl #730 | **65 pass / 0 fail / 0 skip** |
| all 51 `test-julia*.R` files, non-live | **1644 pass / 0 fail / 0 error / 44 skip** |
| DRM.jl `test_bridge_formula_constructs.jl` | **191 pass / 0 fail**, 30.5s |
| DRM.jl `test_bridge_lss_labels` | 10/10 |
| DRM.jl `test_bridge_coef_labels_echo` | 42/42 |
| DRM.jl `test_bridge_lss_routes` | 6+10+11+4 |
| DRM.jl `test_bridge_formula_labels` | 819/819 |
| DRM.jl `test_bridge_base_r_names` | 20/20 |

## 6. Tests of the Tests

Two RED controls, both restored byte-identically.

**drmTMB.** Removed the guard-presence `skip_if_not()` from the LSS test and
re-ran live against DRM.jl `aee371cc9` (neither guard present):

```
FAILURE: 'test-julia-formula-constructs-nongaussian.R:247:3'
Expected LSS sd(study) ~ <character column>: verdict MISLABELLED_SILENT
(max|coef diff| = 1.3853 over blocks mu/sigma/sd; |logLik diff| = 2.98e-13) to be TRUE.
[ FAIL 1 | WARN 0 | SKIP 0 | PASS 30 ]
```

Restored: sha256 `e13761042a921944c41d5f44ae57a6945f7770043ca1854f3c33a7afcc2672ca`
before and after.

**DRM.jl.** Removed the call to `_bridge_check_lss_coef_labels_fidelity`:

```
ERROR: LoadError: Some tests did not pass: 185 passed, 1 failed, 0 errored, 0 broken.
NOT REFUSED: ["mu_(Intercept)", "mu_x", "sigma_(Intercept)",
              "sd_(Intercept)", "sd_labBeta", "sd_labgamma"]
```

Restored: sha256 `06e971ee865712d854878b9e0027005267e9b8742cc8917af043f46861e9feeb`
before and after.

**GREEN controls** (a refusal that refuses too much is a worse bug): declared
factor on the same LSS route FAITHFUL to `1.46144e-10`; `sd(study) ~ 1`
FAITHFUL to `3.47833e-13`; DRM.jl testset `(f)` asserts the agreeing labels are
accepted with `coefficients` and `raw_coef_names` unchanged.

## 7a. Issue Ledger

- DRM.jl #467 / #609: the construct contract. Extended here, not re-litigated.
- DRM.jl #730 (opened by this leaf): the LSS `sd()` fidelity hole.
- drmTMB #1227: independently verified, including on a route it did not claim.

## 8. Consistency Audit

Walked the neighbours of the change. `_bridge_lss_public_to_raw!` is the only
other consumer of `_bridge_render_formula_block` for `sd_` keys and is
untouched; the new function mirrors its alignment logic and bails (`continue`)
on exactly the branches that one treats specially. The count check in
`_bridge_echo_coef_labels` still fires first -- pinned by testset `(e)`, which
still passes. `sdphy_<group>` shares the new code path but was not exercised
live (§10).

## 9. What Did Not Go Smoothly

- The first live run of the new test file reported `PASS 18, SKIP 2` and looked
  green. Both skips were the mislabel cases, skipped because testthat's
  `LC_COLLATE = "C"` is Julia's code-point order. Exactly the failure mode the
  brief warns about; found by reading the skip reasons rather than the counter.
- The fresh DRM.jl worktree had no instantiated `Manifest.toml` and failed to
  precompile (`ForwardDiff ... does not seem to be installed`), which surfaced
  as three identical "REFUSED" rows that were nothing of the kind. Copied the
  reference checkout's manifest and re-ran; `Manifest.toml` is git-ignored.
- A first attempt at the drmTMB RED control spliced the file by string index
  and produced a parse error. Restored from the kept copy and re-planted by
  line range.

## 10. Known Residuals

- **The multi-IID LSS `sd` route is still uncompared** in DRM.jl, by explicit
  decision (the `"<group>: "` prefix). drmTMB's #1227 guard covers it on the R
  side; DRM.jl's does not.
- **`sdphy_<group>` was not exercised live.** Same code path, no receipt.
- **Random-effect routes refuse every factor**, declared or not, because DRM.jl
  supplies no `bridge_formula_labels_v1` there -- measured here on
  `y ~ x + g_fac + (1 | grp)` for both an alphabetical and a non-alphabetical
  factor. Honest, not silent, and a separate gap.
- **`beta_family()` is not an exported name**; the beta fixture was dropped
  from the battery rather than guessed at.
- The full `R CMD check` was not run; this leaf adds no R source.

## 11. Team Learning

A classification table is only as strong as its fixture. #1227's two silent
cells were both honestly measured and both, at a live engine, no longer silent
-- while the same shape on a route it never tried was silent, converged, and
off by 1.4 on a log-SD coefficient. **The generalisable move is not "re-run the
battery on more families"; it is "find the block the guard structurally cannot
see".** Here that was one `continue` in
`_bridge_rendered_regression_blocks`. Reading the guard's skip conditions found
in minutes what a wider family sweep would not have found at all: five families
all came back REFUSED.

Second: when a test's fixture depends on locale, encoding, or any ambient
setting the test framework itself normalises, assert the fixture before
trusting the result. `SKIP` is not `PASS`.

## 12. Cross-Product Coverage

Constructs x fixtures actually crossed, with verdicts, are banked one row per
cell in
`docs/dev-log/evidence/julia-r-parity/mislabelled-constructs/route-classification.tsv`
(22 rows). Not crossed: random-effect routes beyond the two probes above,
bivariate routes, structured markers, phylogenetic routes, `meta_V()`, and
every construct from #1227's 58 other than the two silent ones and their
declared-factor controls.
