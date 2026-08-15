# Profile shape boundary (issue #859, slice S5)

Investigation of `badprof.rds` (lme4 testdata) against drmTMB's profile-CI
code, and a test pinning what drmTMB can and cannot honestly claim about
non-monotone profile shapes.

Environment: `lme4` 2.0.1 installed at
`/Users/z3437171/Library/R/arm64/4.6/library/lme4`; drmTMB worktree
`.worktrees/external-oracle` at commit `2cca97836` (`devtools::load_all()`,
version 0.7.0).

## What `badprof.rds` actually is

`file.path(find.package("lme4"), "testdata", "badprof.rds")` deserializes to
an object of class `c("thpr", "data.frame")`, dimension 360 x 8, columns
`.zeta, .sig01, .sig02, .sig03, .sigma, (Intercept), cYear, .par`. It is a
**stored `lme4::profile()` result**, not a model and not a dataset:

- `bp$call` is `NULL`; there is no `formula` or `data` attribute on the
  object. Its only attributes are `forward`/`backward` (spline
  representations of the profile trace, per variance component) and
  `lower`/`upper` bounds (`0, -1, 0, 0` / `Inf, 1, Inf, Inf`) for the four
  variance-component columns.
- `list.files(file.path(find.package("lme4"), "testdata"))` returns 41
  files; none besides `badprof.rds` itself references "badprof" by name, and
  none is an obvious companion dataset for the `(Intercept)`/`cYear`
  fixed-effect columns visible in the trace.
- lme4's own test suite (`tests/testthat/test-methods.R` in the lme4 GitHub
  source, fetched via `gh api repos/lme4/lme4/contents/...` since the
  installed binary package ships no `tests/`) uses `badprof.rds` the same
  way — as a stored profile passed straight to `confint()`, never refit:

  ```r
  test_that("confint with bad profile", {
    badprof <- readRDS(system.file("testdata","badprof.rds", package="lme4"))
    expect_warning(cc <- confint(badprof), "falling back to linear")
    ...
  })
  ```

  `lme4::confint.thpr()` is a pure post-processing step over the stored
  spline/trace data; it never re-touches the original `lmer` object.

## Can it be run through our CI code

**No — confirmed, not merely expected.** Two independent reasons, both
verified rather than assumed:

1. **Structural**: `profile.drmTMB()` (`R/profile.R:740`) requires
   `fitted` to `inherit(fitted, "drmTMB")` and pulls `fitted$obj` (the live
   TMB object) to call `TMB::tmbprofile()` against. `badprof.rds` is a
   `thpr`/`data.frame`, not a `drmTMB` fit, and carries no TMB object, no
   `drmTMB()` call, and no original data. There is nothing to profile "with"
   — drmTMB's classifier (`profile_interval_diagnostics()`,
   `R/profile.R:4106`) only ever runs as the last step inside
   `drm_profile_curve()`, on a `target` produced by `drm_profile_targets()`
   from an actual `drmTMB` fit object.
2. **Data**: no accompanying dataset or generating script ships next to
   `badprof.rds` in `lme4`'s `testdata/`, so even a manual re-implementation
   (build the same `lmer` model in drmTMB's `mu`/`sd()` grammar, refit, then
   profile) is not reproducible from what ships with lme4. Locating the
   original data (the `cYear` / `(Intercept)` structure is consistent with a
   longitudinal mixed model, plausibly from an lme4 GitHub issue) was out of
   scope for this slice and was not pursued further.

So "run `badprof.rds` through the profile CI code" is not a describable
action on this repository's `profile()`/`confint(method = "profile")`
surface. What IS possible, and what this slice does instead, is use
`badprof.rds` as a **read-only shape oracle**: a real, external example of
the exact pathology (`.zeta` non-monotonicity) drmTMB's classifier
structurally cannot detect.

## The zeta vs delta_deviance correspondence, with numbers

Corrected/refined from the prior investigation's framing:

- `R/profile.R:1109`: `delta_deviance = 2 * delta_objective`, and
  `delta_objective <- objective - min(objective, na.rm = TRUE)`
  (`R/profile.R:1064`) — **the baseline is the trace's own minimum
  objective, not `fit$opt$objective` directly.** These coincide only when
  the profile's warm-started inner optimizer never beats the fit's own
  optimizer (the pathology `profile_below_fit_objective` exists precisely
  to catch cases where they don't — see `R/profile.R:4106-4155`, issue
  #1009). This is a real, if usually small, distinction the prior framing
  collapsed.
- lme4's `.zeta` is signed; drmTMB's `delta_deviance` is unsigned and
  `>= 0` by construction. `zeta = sign(profile_value - estimate) *
  sqrt(delta_deviance)` recovers the signed root. Verified numerically on a
  drmTMB fixture (`n_id = 12`, `n_each = 5`, Gaussian `y ~ x + (1 | ID)`,
  `sd:mu:(1 | ID)` target, `profile_precision = "fast"`, 31 trace rows):

  ```
  max abs diff (stored delta_deviance vs 2 * (objective - fit$opt$objective)): 0
  max abs diff (zeta^2 vs delta_deviance):                                     8.881784e-16
  fit$opt$objective:      45.17345
  min(prof$objective):    45.17345   (identical to 15 digits)
  ```

  Both the identity and the independent baseline cross-check (using
  `fit$opt$objective`, which the internal formula never references) hold to
  numerical precision on this clean fixture. `zeta` is monotone increasing
  in `profile_value_link` here (`!is.unsorted(zeta[order(profile_value_link)])`
  is `TRUE`) — this is the positive control the test relies on: a genuinely
  broken profile on this class of fixture would flip that assertion.

## The pathology, quantified

Using lme4's own internal detector from its `R/profile.R`
(`min(diff(obj1[,2]) < (-non.mono.tol), na.rm = TRUE)` with
`non.mono.tol = 1e-2`, fetched via `gh api repos/lme4/lme4/contents/R/profile.R`)
and by directly calling `stats::confint(badprof)` and capturing every
warning:

```
WARNING: bad spline fit for .sig02: falling back to linear interpolation
WARNING: bad spline fit for (Intercept): falling back to linear interpolation
WARNING: no non-missing arguments to min; returning Inf
WARNING: non-monotonic profile for cYear
```

Per-column raw-order characterization (`n` rows, `.zeta` range, first
non-monotone flip):

| `.par` | n | NA(`.zeta`) | range(param) | range(`.zeta`) | lme4 verdict |
|---|---|---|---|---|---|
| `cYear` | 198 | 197 | [-3.7685, -3.1078] | {0} only | **non-monotonic** (warning) |
| `(Intercept)` | 106 | 0 | [-17.684, 19.810] | [-1.293, 4.281] | bad spline fit -> falls back to linear |
| `.sig01` | 15 | 0 | [0, 77.434] | [-1.149, 4.292] | clean |
| `.sig02` | 2 | 0 | [-1.01, -1.00] | [-0.0017, 0] | bad spline fit (too few points: `splineDesign` needs >= 7 knots) -> falls back to linear |
| `.sig03` | 20 | 0 | [1.021, 14.667] | [-4.222, 4.441] | clean |
| `.sigma` | 19 | 0 | [40.302, 88.113] | [-4.276, 4.433] | clean |

Correction to the prior investigation's framing: the pathology is **not
uniformly** "sign-flipping `.zeta`". Only `cYear` is flagged by lme4's own
non-monotonicity test, and even that is not a simple sign flip — 197 of 198
`.zeta` values for `cYear` are `NaN` (the inner optimizer stalled almost
everywhere along that profile direction; the single finite point, `zeta =
0`, is the anchor at the fitted estimate itself). `(Intercept)` and
`.sig02` fail for a *different* reason (spline-fit failure — `.sig02` has
only 2 trace points, too few for the cubic spline lme4 uses;
`(Intercept)`'s backward spline hits a numerically singular linear system)
and are handled by lme4's `approxfun()` fallback, not flagged as
non-monotonic outright. `.sig01`, `.sig03`, `.sigma` are clean. So
`badprof.rds` actually exercises three distinct pathology classes at once,
of which only one (`cYear`) is genuine `.zeta` non-monotonicity in the
sense the issue's framing anticipated.

## What drmTMB can and cannot honestly claim

Accepted, with the correction above folded in: `badprof.rds` is a
**diagnostic-only shape oracle**. drmTMB can honestly assert that its
profile classifier does **not** claim to detect non-monotone profile
shape, and this arc does not build a new detector. The evidence for that
claim is structural, not just descriptive:

- `profile_interval_diagnostics()` (`R/profile.R:4106`) takes only
  `interval, transformation, estimate, sd_boundary, correlation_boundary,
  profile_min_objective, fit_objective, profile_below_fit_tol` — a
  two-number interval plus fit-level scalars. It never receives the
  per-row `.zeta`/`objective` trace a monotonicity check would need, so it
  is architecturally incapable of shape detection as currently signed, not
  merely undocumented as capable.
- Its function body contains no "monoton"/"shape" text, and its fixed
  message vocabulary is exactly `nonfinite_interval,
  profile_below_fit_objective (gap=... nll), point_estimate_outside_interval,
  near_sd_boundary, near_correlation_boundary, ok` — verified by calling
  each branch directly.
- `docs/dev-log/known-limitations.md` (local checkout only; `docs/` is
  `.Rbuildignore`-excluded, `^docs$`) already states this honestly: "The
  current boundary diagnostics are endpoint flags, not a full
  profile-shape classifier: one-sided intervals and automatic recovery
  from non-monotone profiles remain planned."

## What the test pins

`tests/testthat/test-profile-shape-boundary.R`, four `test_that()` blocks:

1. **`badprof.rds cannot be run through drmTMB's profile CI code`** —
   confirms class/dimensions, confirms no `call`/`formula`/`data`
   attribute, confirms no sibling data file in lme4's `testdata/`.
   `skip_if_not_installed("lme4")` only (a real optional-dependency gate,
   precedented 10+ times elsewhere in this test suite).
2. **`lme4 confirms non-monotonicity in badprof$.zeta that drmTMB cannot
   see`** — reproduces the NA-heavy `cYear` trace numerically and
   independently confirms lme4's own `"non-monotonic profile for cYear"`
   warning via `withCallingHandlers()`. `skip_if_not_installed("lme4")`
   only.
3. **`profile_interval_diagnostics() is structurally endpoint-only, not
   shape-aware`** — the load-bearing pin. Unconditional: no lme4, no
   `docs/`. Asserts the exact `formals()` list, asserts no trace-shaped
   argument name is present, asserts the body text contains no
   "monoton"/"shape" keyword, and asserts the exact known message
   vocabulary via direct branch probes. This is what actually holds under
   `R CMD check`, where neither `lme4::testdata` availability nor `docs/`
   presence can be assumed to matter for the pin's substance.
4. **`known-limitations.md still documents the non-monotone-profile
   boundary`** — supplementary. `docs/` is excluded from the build
   (`.Rbuildignore: ^docs$`), so this assertion is `skip_if_not()`-gated on
   file existence and only runs against a full git checkout, never inside
   an `R CMD check` tree. It is explicitly NOT the load-bearing check —
   block 3 is — so a future PR cannot make this whole boundary claim
   silently vanish under CI just by this one block skipping. The skip
   reason is stated plainly (`"docs/ is not present in this check tree
   (excluded via .Rbuildignore)"`) rather than left blank.
5. **`zeta^2 == delta_deviance on a drmTMB profile we can actually
   compute`** — fits a small Gaussian `(1 | ID)` model, profiles the
   random-effect SD target, and checks two things numerically (not
   algebraic tautologies alone): (a) `delta_deviance` recomputed from
   `fit$opt$objective` (an independent baseline the package's own formula
   never references) matches the stored `delta_deviance` to `1e-8`; (b)
   the recovered signed `zeta` squares back to `delta_deviance` to `1e-8`;
   (c) `zeta` is monotone on this clean fixture (positive control: a
   genuine drmTMB profile-shape regression would break this).

None of these touch `R/methods.R`, `R/drmTMB.R`, `src/drmTMB.cpp`,
`tests/testthat/test-zero-one-beta.R`, or
`tools/run-lane-c-c17c1-c14-model15-compatibility.R`. No new detector, no
change to `profile_interval_diagnostics()`, no public-behaviour change.
