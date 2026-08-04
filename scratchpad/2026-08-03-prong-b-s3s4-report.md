# Prong B S3/S4 report: flip fence-invalidated assertions + first se=TRUE profile-interval tests

Worktree: `/private/tmp/drmtmb-s3`. R/profile.R and all other R/ files were left
untouched (they arrived pre-modified in this worktree; I did not edit them).
Nothing was committed or staged. Only the four listed test files were edited,
plus scratchpad evidence scripts under `/private/tmp/drmtmb-s3/scratchpad/`.

## Empirical finding requested up front: what `profile_note` do the se=FALSE fits report?

**"ready", not "tmb_object_required".** Every site in this brief uses
`control = drm_control(se = FALSE)`, which only sets `se = FALSE`;
`keep_tmb_object` defaults to `TRUE` independently, so `fit$obj` is retained
and `profile_internal_is_active()` (the only place that checks
`is.null(object$obj)`) is satisfied. I confirmed this empirically for every
retired-fence route before editing any assertion (scratchpad `probe1.R`,
`probe3.R`, `probe4.R`, `probe8.R`):

- NB2 sigma phylo_interaction (mc-0425, se=FALSE): `profile_ready = TRUE`,
  `profile_note = "ready"`.
- zi_nbinom2 sigma phylo_interaction (mc-0653, se=FALSE): same.
- zero_one_beta structured sigma, phylo/animal/relmat/spatial/phylo_interaction
  providers (se=FALSE): same for all five, spot-checked on phylo and
  phylo_interaction (the two structurally most different providers) and relied
  on the provider-agnostic source logic (`count_point_fit_only_profile_restricted()`
  no longer includes `"sigma"` in its `dpar` set) for animal/relmat/spatial.
- zero_one_beta ordinary (unstructured) sigma random-intercept (mc-0568,
  se=FALSE) and random-slope (mc-0576, se=FALSE): same — both the generic
  fence and the dedicated `zero_one_beta_sigma_q1_profile_restricted()`
  (deleted) are gone.
- count labelled-q2 covariance block, all three targets (2 SD rows +
  1 `cor:` row), all five cells (mc-0436, mc-0418, mc-0446/0450/0454): same —
  these fits use `control = list(eval.max=..., iter.max=...)`, which is not
  `drm_control(se=FALSE)` at all (default `se = TRUE`), so this was expected
  but I verified it anyway (`probe2.R`).

No site in this brief produced `"tmb_object_required"`.

## S3 — sites changed

### A) `tests/testthat/test-count-structured-mu.R` — shared helper (covers 5 cells via 3 call sites)

`expect_count_labelled_q2_profile_restriction()`, now at :583-633 (was
:583-634; net -1 line). Called at :733 (inside
`expect_poisson_labelled_q2_provider_fit`, itself called for spatial/animal/relmat
at the "Poisson admits only the C2 labelled provider covariance cohort" test,
mc-0446/0450/0454), :884 (mc-0436, "Poisson phylo admits one labelled
intercept-slope covariance block"), :1026 (mc-0418, "NB2 phylo admits one
labelled intercept-slope covariance block").

Before (:597-633, abridged):
```r
expect_equal(restricted$target_type, rep("direct", length(target_names)))
expect_false(any(restricted$profile_ready))
expect_equal(restricted$profile_note, rep("point_fit_only_count_q2", length(target_names)))
expect_false(any(target_names %in% profile_targets(fit, ready_only = TRUE)$parm))
expect_error(stats::confint(fit, parm = target_names[[1L]], method = "profile"), "not ready for direct profiling")
expect_error(stats::profile(fit, parm = target_names[[1L]]), "not ready for direct profiling")
endpoint_called <- FALSE
testthat::local_mocked_bindings(drm_profile_target_endpoint_confint = function(...) {
  endpoint_called <<- TRUE; stop("endpoint profile must not start", call. = FALSE)
}, .package = "drmTMB")
endpoint <- stats::confint(fit, parm = target_names[[1L]], method = "profile", profile_engine = "endpoint")
expect_false(endpoint_called)
expect_equal(endpoint$conf.status, "profile_failed")
expect_match(endpoint$profile.message, "endpoint engine unsupported")
```

After: `profile_ready` all `TRUE`, `profile_note` all `"ready"`, all three
target names present in `profile_targets(fit, ready_only = TRUE)$parm`. The
two `expect_error(..., "not ready for direct profiling")` calls are removed
(the condition they tested no longer exists; the general
profile_ready/note/ready_only triple above already covers what they were
checking). The endpoint-mock block is **kept and flipped, not deleted**: I
verified empirically (`probe2.R`) that once `profile_ready = TRUE`,
`profile_endpoint_target_supported()` now accepts this target (class
`random-effect-sd`, transformation `exp`), so `drm_profile_target_confint()`
actually reaches the mocked `drm_profile_target_endpoint_confint()` instead of
short-circuiting to "unsupported". The mock still aborts immediately
(`stop("endpoint profile must not start")`), so this stays cheap — no real
profile optimization runs in this shared helper. Flipped assertions:
`expect_true(endpoint_called)`, `conf.status` still `"profile_failed"`
(unchanged), `profile.message` now matches `"endpoint profile must not
start"` (the mock's own message) instead of `"endpoint engine unsupported"`.

### B) `tests/testthat/test-phylo-interaction.R`

- NB2 sigma phylo_interaction gate (mc-0425), now :423-436 (was :435-459 in
  the brief's pre-edit numbering). Same triple flip + same endpoint-mock flip
  as site A (verified empirically per-target in `probe3.R`, using the actual
  fit rather than a mock-only check for the profile_ready/note/ready_only
  part).
- zi_nbinom2 sigma phylo_interaction gate (mc-0653), now :527-543 (was
  :541-557). Same flip.
- **Left unchanged, verified still passing**: the ORDINARY (non-interaction)
  zi_nbinom2 sigma q1 gate at :674-698 (note
  `"point_fit_only_zi_nbinom2_sigma_q1"`, deliberately retained per the
  brief) — I re-read it after editing the neighbouring blocks and confirmed
  no edit touched it.

### C) `tests/testthat/test-zero-one-beta.R`

**Structured sigma** (5 sites, one per provider; only the `sigma`-route
assertion flips — the note strings themselves are not retired, since
structured `mu`/`zoi`/`coi` sites elsewhere still use them):
- phylo, now :611-619 (test "...exact phylo q1 sigma gate", starts :601)
- animal, now :825-838 (test starts :819)
- relmat, now :860-871 (test starts :854)
- spatial, now :885-892 (test starts :879)
- phylo_interaction, now :1023-1030 (test "...exact phylo-interaction q1
  sigma gate", starts :1019)

Root cause confirmed by source reading, not just observed behaviour:
`count_point_fit_only_profile_restricted()` dropped `"sigma"` from its
`dpar %in% c("mu","zoi","coi")` set (was `c("mu","sigma","zoi","coi")`),
so for `dpar = "sigma"` this predicate is now always `FALSE` regardless of
provider, and `drm_profile_targets()` falls through to
`profile_direct_target_status()` (ready). Each site: `profile_ready` FALSE ->
TRUE, note -> `"ready"`, `ready_only` check flipped, the two
`"not ready for direct profiling"` `expect_error()` calls removed, endpoint-
mock block kept and flipped exactly as in sites A/B.

**Ordinary (unstructured) sigma** — the note `"point_fit_only_zero_one_beta_sigma_q1"`
itself IS retired (its dedicated gate function
`zero_one_beta_sigma_q1_profile_restricted()` was deleted outright):
- mc-0568, random-intercept (`sigma ~ 1 + (1 | id)`), test "...exact sigma
  random-intercept q1 gate" now :1039-1109. Core assertions at :1057-1064
  (was :990-994 in the brief's numbering — narrower than what I actually had
  to change). Triple flip + 2 error-checks removed. **The endpoint-mock block
  at (now) :1065-1082 was also flipped**, even though the brief's cited range
  stopped at :994: I verified empirically that leaving it as `expect_false(
  endpoint_called)` / `"endpoint engine unsupported"` would fail once
  `profile_ready = TRUE` (same eligibility mechanism as site A), so it needed
  the same treatment to reach 0 failures. Flagging this explicitly since it
  is outside the literal cited line range.
- mc-0576, random-slope (`sigma ~ x + (0 + x | id)`), test "...exact sigma
  random-slope q1 gate" now :1148-1207. Core assertions at :1162-1164 (was
  :1089-1093). Per the brief's explicit instruction for this site only, the
  two `expect_error(..., "not ready for direct profiling")` calls (the
  `confint()` one and the `profile()` one) are **replaced by one real
  profile-interval assertion**, not deleted:
  ```r
  sigma_ci <- stats::confint(fit, parm = target$parm, level = 0.70,
    method = "profile", trace = FALSE, ystep = 0.50)
  expect_equal(sigma_ci$parm, target$parm)
  expect_identical(sigma_ci$conf.status, "profile")
  expect_true(is.finite(sigma_ci$lower)); expect_true(is.finite(sigma_ci$upper))
  expect_lt(sigma_ci$lower, target$estimate); expect_gt(sigma_ci$upper, target$estimate)
  ```
  measured ~4.3 s on this se=FALSE fit (matches the brief's own "~5.4 s"
  estimate for this route). **Decision, flagged explicitly**: I did not also
  re-run the bare `profile()` curve call for real (that would add a second
  ~4.4 s real optimization for a curve object, not "an interval"); I read the
  brief's singular "a real interval assertion" as asking for one real
  interval (the `confint()` one), with the endpoint-mock block below still
  exercising the `profile_engine = "endpoint"` path for free. `profile()`'s
  real (non-mocked) success is instead exercised by the dedicated se=TRUE
  test added in S4. The endpoint-mock block right after this (now
  :1187-1198) is flipped the same way as every other site.

### D) `tests/testthat/test-profile-targets.R`

`expect_profile_target_contract()`'s allow-list, now :456-468. Removed the
two dead entries `"point_fit_only_count_q2"` and
`"point_fit_only_count_sigma_interaction"` (were at :462-463); kept
`"point_fit_only_zero_one_beta_phylo_q1"` (now :462, unchanged value). Pure
hygiene per the brief — this list is a permissive superset check used by 10
call sites across the file, and since these two tokens can no longer be
produced by any fit, removing them changes nothing observable.

## S4 — new tests added

Four fast `se = TRUE` profile-interval smoke tests (one per promoted group),
each asserting: `profile_ready`, finite `lower`/`upper`, `lower < estimate <
upper`, `conf.status == "profile"`, and a Wald cross-check on the same fit
(`method = "wald"`, same `parm`, checking the two intervals overlap:
`profile.lower < wald.upper` and `profile.upper > wald.lower`). None assert
truth-bracketing against the simulated parameter. All four use
`level = 0.70, ystep = 0.50` per `test-spatial-gaussian.R:315-337`, and each
carries a comment stating it is a happy-path smoke test, not a boundary
probe, and not a coverage/recovery claim. `test_that()` descriptions are
mechanical ("computes a finite ordered profile interval"); none say
"valid"/"correct"/"recovers"/"accurate".

1. `tests/testthat/test-zero-one-beta.R:1209` — **"zero-one-beta ordinary
   sigma random-slope computes a finite ordered profile interval"** (zob
   sigma ordinary). Reuses mc-0576's DGP/formula (`sigma ~ x + (0 + x |
   id)`) but without `drm_control(se = FALSE)`. Measured: profile ~3.7 s,
   total test ~4.3 s. Profile 70% CI `[0.2945, 0.4886]` vs Wald
   `[0.2912, 0.4862]` (`probe_s4_1.R`).
2. `tests/testthat/test-zero-one-beta.R:634` — **"zero-one-beta structured
   phylo sigma computes a finite ordered profile interval"** (zob sigma
   structured). Reuses the phylo q1 sigma gate test's DGP/formula (`sigma ~
   phylo(1 | species, tree = tree)`), se=TRUE. Measured: profile ~4.9 s,
   total ~5.7 s. Profile 70% CI `[0.3508, 0.5410]` vs Wald `[0.3483,
   0.5386]` (`probe_s4_2.R`).
3. `tests/testthat/test-count-structured-mu.R:887` — **"Poisson phylo
   labelled q2 intercept SD computes a finite ordered profile interval"**
   (count mu labelled q2). Reuses the "Poisson phylo admits one labelled
   intercept-slope covariance block" test's DGP/formula
   (`poisson_phylo ~ x + phylo(1 + x | p | site, tree = tree)`); this route
   was already se=TRUE by default (no `drm_control(se=FALSE)` was ever used
   here). Profiles one of the three newly-ready targets (the intercept SD,
   `sd:mu:phylo(1 | p | site)`); the other two (slope SD, `cor:` row) are
   left to the flipped S3 assertions in the shared helper. Measured: profile
   ~0.57 s, total ~0.80 s — the fastest of the four (`probe_s4_3.R`).
4. `tests/testthat/test-phylo-interaction.R:508` — **"NB2 sigma
   phylo-interaction computes a finite ordered profile interval"** (count
   sigma phylo_interaction). Reuses the NB2 (non-zero-inflated) sigma
   phylo_interaction gate test's DGP/formula, se=TRUE; `skip_on_cran()`
   added to match this test file's existing convention for phylo_interaction
   fits (used at the 3 pre-existing `skip_on_cran()` sites in this file). I
   deliberately used the plain NB2 route, not the zi_nbinom2 sibling: the
   zi_nbinom2 sigma phylo_interaction ML SD estimate is `~4.95e-05`
   (essentially at the boundary in that DGP/seed), whereas the NB2 route's
   estimate is `0.241` — a better-conditioned target for a profile-interval
   smoke test. Measured: profile ~2.4 s, total ~2.7 s. Profile 70% CI
   `[0.1339, 0.3684]` vs Wald `[0.1501, 0.3872]` (`probe_s4_4.R`).

## S4 — internal `cli_abort` fall-through test

`tests/testthat/test-profile-targets.R:3880` — **"count_point_fit_only_profile_restricted_status()
aborts on an unreachable model_type/dpar combination"**. Calls
`drmTMB:::count_point_fit_only_profile_restricted_status()` directly with a
synthetic `object = list(model = list(model_type = "gaussian"))` and
`dpar = "sigma"`. Every one of the callee's own guard checks
(`zero_one_beta_zoi_q1_profile_restricted`, `..._coi_q1_...`,
`zi_nbinom2_sigma_q1_profile_restricted`, and the final
`identical(model_type, "zero_one_beta")` block) short-circuits to `FALSE` on
`model_type != "zero_one_beta"`/`"zi_nbinom2"` before touching any other
field, so the minimal fake object is sufficient — no need to fabricate
`$structured$phylo_mu` or `$random$*`. Asserts
`expect_error(..., "Internal error: no point-fit-only profile note")`.
Verified message text empirically (`probe_s4_5.R`):
`Internal error: no point-fit-only profile note for "gaussian" "sigma".`
A code comment states the limitation: this branch is unreachable from any
public call today (every caller-side guard is mirrored by one of the
callee's own branches), so it can only be exercised by calling the internal
directly with an object that deliberately breaks that invariant.

## Verification — final counts

Individually, all four files: 0 failures.
- `test-count-structured-mu.R`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 533 ]`
- `test-phylo-interaction.R`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 160 ]`
- `test-zero-one-beta.R`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 1581 ]` (~45 s)
- `test-profile-targets.R`: `[ FAIL 0 | WARN 6 | SKIP 0 | PASS 862 ]` (~37 s;
  the 6 warnings are pre-existing `sd_phylo1()`/`sd_phylo2()` deprecation
  warnings at test-profile-targets.R:2862, unrelated to this task — present
  in the file before any of my edits and deliberately triggered by that test
  to check the deprecation-warning path itself)

Required combined command:
```r
testthat::test_dir("tests/testthat", package="drmTMB", load_package="installed",
  filter="zero-one-beta|count-structured-mu|phylo-interaction|profile-targets")
```
Result: **`[ FAIL 0 | WARN 6 | SKIP 0 | PASS 3136 ]`**, elapsed ~93.4 s. (Same
6 pre-existing warnings as above; PASS count is exactly the sum of the four
files' individual PASS counts, confirming no cross-file interaction.)

## Files touched

- `/private/tmp/drmtmb-s3/tests/testthat/test-count-structured-mu.R`
- `/private/tmp/drmtmb-s3/tests/testthat/test-phylo-interaction.R`
- `/private/tmp/drmtmb-s3/tests/testthat/test-zero-one-beta.R`
- `/private/tmp/drmtmb-s3/tests/testthat/test-profile-targets.R`

No `R/` file, `NEWS.md`, or `man/` file was modified by me (they arrived
already modified in this worktree). Nothing committed or staged. Evidence
scripts left under `/private/tmp/drmtmb-s3/scratchpad/probe*.R` (probe1-8.R
for S3 empirical verification, probe_s4_1-5.R for S4); `.rds`/`.log`
artifacts in that directory are gitignored and not part of the diff.
