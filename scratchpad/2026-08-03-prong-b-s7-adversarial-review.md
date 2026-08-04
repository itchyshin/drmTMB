# Prong B Tier 1 — S7 adversarial review

**Scope.** Uncommitted change on `claude/prong-b-tier1` (worktree `/private/tmp/drmtmb-prongb`,
base `origin/main` = `25768833b`). Four lenses: Fisher, Rose, Grace, Boole.
Method: run things. Every finding below cites a command or `file:line`.

**Verdict.** The central claim — *exactly 14 routes opened, nothing else, no ledger promotion* —
**survives**. I attacked it with a 3,757,600-point exhaustive predicate sweep across both
prebuilt libraries and with real `drmTMB()` fits of five topologies the hand-built grid does
not cover; it did not break. The claim is stronger than its own guard proves.

**Counts.** BLOCKING 0 · SHOULD-FIX 5 · NOTE 14.

---

## Environment used

```
PRE  /private/tmp/drmtmb-baseline-lib   libs/drmTMB.so md5 8856caf4f2f8c0d0d726b30741878ad4  Built 2026-08-03 23:20:28 UTC
POST /private/tmp/drmtmb-prongb-lib     libs/drmTMB.so md5 370c1bcd5c727b5307a5add1fe1cc9a8  Built 2026-08-03 23:24:13 UTC
```

Neither library was rebuilt. No repository file was modified; this report is the only file written
inside the worktree.

---

## FISHER — "exactly 14 routes opened, nothing else"

### F1 · NOTE (attack failed; claim confirmed by independent evidence)

The guard's 61 grid points are hand-built from the same mental model that wrote the diff, so I
replaced them with an exhaustive factorial over everything the deleted predicates read:
11 `model_type` × 61 structured-`phylo_mu` shapes (6 providers × {q1 mu/sigma/zoi/coi/zi,
q2 labelled-mu, q2 unlabelled-mu, q2 sigma, q2 cross-dpar, q3} + none) × 7 `random$sigma`
topologies × 2 `random$mu` × 2 `zoi` × 2 `coi` × 2 `mu_sigma` × 10 `dpar` × 5 `internal`.
The gate expression was transcribed from the real call sites, not re-invented
(`R/profile.R:1428-1436` post-edit; `git show origin/main:R/profile.R` lines 1408-1414 and the
`eta_cor_phylo` branch at 1507-1515 pre-edit).

Script: `<scratchpad>/exhaustive.R`. Run against each library with
`R_LIBS_USER="<lib>:<system lib>" Rscript --no-init-file exhaustive.R <out>`.

```
OLD: evaluated=3757600 gate_true=9196 deleted_fns_present=TRUE,TRUE
NEW: evaluated=3757600 gate_true=4156 deleted_fns_present=FALSE,FALSE
NEW-only (newly FENCED) rows: 0
ABORT rows in NEW:            0
```

The 5,040 OLD-only rows collapse to exactly these families and no others:

| family | count | claimed cells |
|---|---|---|
| `poisson`/`nbinom2` labelled-q2 `mu` SD **and** its `eta_cor_*` correlation target | nbinom2×phylo, poisson×{phylo,spatial,animal,relmat} | mc-0418, mc-0436, mc-0446, mc-0450, mc-0454 |
| `nbinom2`/`zi_nbinom2` `sigma` under `phylo_interaction` q1 | 2 | mc-0425, mc-0653 |
| `zero_one_beta` `sigma` structured q1, 5 providers | 5 | mc-0593…0597 |
| `zero_one_beta` `sigma` ordinary q1 | 1 predicate | mc-0568, mc-0576 |

Nothing else flipped in either direction. **The "exactly 14, nothing else" claim holds under an
enumeration ~60,000× larger than the guard's.**

### F2 · NOTE — the claim rests on constructor gates the guard never mentions

The deleted `zero_one_beta_sigma_q1_profile_restricted()` had a domain **strictly larger** than
mc-0568/mc-0576: it ignored `structured$has`, `covariance_labels`, `n_re`, and the presence of
`mu`/`zoi`/`coi` random effects. Of the 2,112 opened stub rows carrying note
`point_fit_only_zero_one_beta_sigma_q1`, only **32** have `structured = none`; 2,080 have a
structured term present, and the labelled (`covariance_labels = "p"`) sigma shape is opened too:

```
sigma-RE shapes among opened rows:  528 s_int  528 s_lab  528 s_nore  528 s_slope
structured:                          32 STRUCT_ABSENT   2080 STRUCT_PRESENT
```

I tested whether any of that is reachable from the public API, with real fits in both libraries
(`<scratchpad>/probe.R`):

```
A_mu_re_plus_sigma_re                CONSTRUCT_ERROR: sigma random intercepts cannot be combined with other random effects
B_sigma_re_plus_zoi_re               CONSTRUCT_ERROR: (same)
C_labelled_sigma_only                CONSTRUCT_ERROR: Only one independent zero_one_beta() sigma random intercept or slope
D_labelled_mu_sigma                  CONSTRUCT_ERROR: Only independent zero_one_beta() mu random intercepts and slopes
E_structured_mu_plus_ordinary_sigma  CONSTRUCT_ERROR: cannot be combined with a structured mu effect
F_plain_sigma_only     OLD -> ready=FALSE note=point_fit_only_zero_one_beta_sigma_q1
F_plain_sigma_only     NEW -> ready=TRUE  note=ready
```

So the extra domain is unreachable and "exactly 14" is true — **but it is true because of
`drmTMB()` construction gates outside `R/profile.R`, not because the deleted predicate was
narrow.** Neither `tools/check-profile-fence-integrity.R` nor
`scratchpad/2026-08-03-prong-b-s2-guard-report.md` says this. A future relaxation of any of those
five constructor errors silently widens the profile surface with no guard firing. Worth one
sentence in the guard header.

### F3 · SHOULD-FIX — the guard proves *classification*, never *computability*; one of the 14 fails

`tools/profile-fence-worker.R:186` calls `drmTMB::profile_targets(fit)` and nothing else. The
battery never calls `confint(method = "profile")`. So "14 routes open" is proven and "14 routes
produce an interval" is not. Only 3 of the 14 gained an interval test
(`tests/testthat/test-count-structured-mu.R:887`, `test-phylo-interaction.R:508`,
`test-zero-one-beta.R:634`).

I ran real profiles on five of the untested routes (`<scratchpad>/endpoint.R`), using the exact
option spelling those three new tests use (`level = 0.70, method = "profile", trace = FALSE,
ystep = 0.50`):

```
mc-0576  sd:sigma:(0 + x | id)                             status=profile        lo=0.4118 hi=0.5397  (16.0s)
mc-0597  sd:sigma:phylo_interaction(1 | plant:pollinator)  status=profile        lo=0.1002 hi=0.2185
mc-0436  sd:mu:phylo(1 | p | site)                         status=profile        lo=0.1587 hi=0.3214
mc-0436  cor:phylo:cor(mu:(Intercept),mu:x | p | site)     status=profile        lo=0.0451 hi=0.7259
mc-0454  sd:mu:relmat(1 | p | id)                          status=profile        lo=0.1776 hi=0.3031
mc-0454  cor:relmat:cor(mu:(Intercept),mu:x | p | id)      status=profile        lo=0.2345 hi=0.7443
mc-0653  sd:sigma:phylo_interaction(1 | plant:pollinator)  status=profile_failed lo=NA     hi=NA
```

Reproduced and isolated (`<scratchpad>/mc0653b.R`, on the guard's **own** mc-0653 fixture):

```
ystep=default level=0.95 -> status=profile        lower=0  upper=0.233408  msg=near_sd_boundary
ystep=default level=0.70 -> status=profile        lower=0  upper=0.127321  msg=near_sd_boundary
ystep=0.5     level=0.95 -> status=profile_failed lower=NA upper=NA        msg=nonfinite_interval
ystep=0.5     level=0.70 -> status=profile_failed lower=NA upper=NA        msg=nonfinite_interval
ystep=0.25    level=0.95 -> status=profile_failed lower=NA upper=NA        msg=nonfinite_interval
```

Two things: (i) the interval does not compute under a documented, in-repo option spelling;
(ii) the fixture's ML estimate is `sdpars$sigma = 4.95e-05` against a DGP truth of `sd_pair = 0.60`
(`tools/profile-fence-fixtures.R:805`), i.e. the variance component collapsed to the boundary, and
the guard records it as `FIT OK convergence=0 pdHess=TRUE se_success=TRUE`. The degeneracy is
pre-existing (the repo test at `tests/testthat/test-phylo-interaction.R:555` uses the same default
seed and asserts only classification), so this is not a regression — but the change opens mc-0653
on evidence that never shows an interval coming out of it.

Failure is graceful (`profile_failed` + a message, not an error or a hang), so this is not
BLOCKING. Recommended: either add a battery column that calls `confint(method = "profile")` and
records `conf.status`, or state in the guard report that computability is out of scope and name
mc-0653 as the known boundary case.

### F4 · NOTE — CI mode is a golden-file change detector, not a derivation

`run_guard_mode()` (`tools/check-profile-fence-integrity.R:118-214`) compares observed results
against `spec$expect_new` and `row$new_ready`/`row$new_note`, all hand-written in
`tools/profile-fence-fixtures.R`. It never reads `expect_old` and never re-derives anything. If
the table encoded a wrong belief, CI would pass. The pre/post evidence lives only in `--diff`
mode, which is **not** wired into CI. That is the normal and acceptable design for a regression
guard, but the S2 report's framing ("checks that decision surface directly rather than trusting a
diff review") should not be read as CI-proved correctness.

### F5 · NOTE — the new `cli_abort` fallback is provably unreachable

`R/profile.R:4056-4058`. The single call site (`R/profile.R:1435`) is guarded by a disjunction
whose every branch implies `model_type ∈ {zi_nbinom2, zero_one_beta}`, both handled earlier in the
function. My 3.76M-point sweep produced **0** ABORT rows. `tests/testthat/test-profile-targets.R:3880`
reaches it only by calling the internal directly with a synthetic `gaussian` object, and its comment
says so. Correctly built and correctly documented.

### F6 · NOTE — no orphans, no dangling references

`grep -rn` over `R/`, `tests/`, `man/`, `vignettes/`, `inst/` finds no residual call to
`count_labelled_q2_profile_restricted`, `count_labelled_q2_profile_restricted_status`,
`count_sigma_interaction_profile_restricted`, or `zero_one_beta_sigma_q1_profile_restricted`
(the only hits are two explanatory comments at `tests/testthat/test-zero-one-beta.R:1061,1166`).
`phylo_mu_has_labelled_mu_intercept_slope_q2` (`R/drmTMB.R:11633`) and
`structured_mu_correlation_key` (`R/drmTMB.R:11552`) remain used elsewhere, so the deletions
created no dead code.

---

## ROSE — overclaim, scope, census

### R1 · SHOULD-FIX — shipped docs now contradict shipped behaviour (4 places)

The change updated `?confint.drmTMB` and `?profile_targets` and stopped there. These still assert
the old fence for routes this change opened:

1. **`man/zero_one_beta.Rd:34-37`** (roxygen source in `R/family.R`):
   > "The point-fit-only q1 gates additionally admit one ordinary intercept-only random effect in
   > `sigma`, `zoi`, or `coi` … plus one ordinary slope-only effect … **These routes are point-fit
   > recovery only: direct profiling, intervals, coverage, and broader recovery claims remain
   > unavailable.**"

   False for the two `sigma` routes (mc-0568, mc-0576) as of this change; still true for
   `zoi`/`coi`. This man page ships to CRAN.

2. **`vignettes/formula-grammar.Rmd:78`** (zero-one beta row): "…**their direct targets are not
   profile-ready** and they have no interval, coverage, or inference claim." Same half-false
   statement.

3. **`vignettes/formula-grammar.Rmd:129`** (poisson labelled q2): "It estimates two latent SDs and
   their intercept–slope correlation, but **its direct targets are not profile-ready** and the
   retained evidence is point-fit-only." All three targets are now `profile_ready = TRUE`
   (mc-0436/0446/0450/0454) — I computed intervals for them in F3.

4. **`vignettes/formula-grammar.Rmd:130`** (nbinom2): "The separate exact labelled NB2 q2 exception
   is `phylo(1 + x | p | species, tree = tree)` only, **at point-fit-only status**." Now
   profile-ready (mc-0418).

`vignettes/formula-grammar.Rmd:91` (ZINB2 IID sigma control) and `man/nbinom2.Rd:27` are **correct**
— that route stays fenced. Checked, not assumed.

### R2 · NOTE — `?profile.drmTMB` did not get the caveat

`man/profile.drmTMB.Rd` exists and is untouched. `NEWS.md:5-6` says
"`confint(fit, method = "profile")` **and `profile(fit)`** now reach …", so both entry points are
affected, but only `confint.drmTMB` carries the new `@section`.

### R3 · SHOULD-FIX — stale `R/profile.R` line anchors left in the live evidence record

The change re-anchored 3 citations in `docs/dev-log/dashboard/estimator-surface-conformance.tsv`
(860→881, 896→917, 3078→3089 — I verified all three land on identical source text). It left these,
which shift by the same edits:

| file | citation | shifted to |
|---|---|---|
| `docs/dev-log/dashboard/capability-ledger/cells.tsv` (rows 488, 489, 464) | `R/profile.R:1252`, `:1280`, `:1710` | 1273, 1301, 1721 |
| `docs/dev-log/dashboard/capability-ledger/evidence.tsv:527,528,503` | `R/profile.R:1252-1278`, `:1280-1309`, `:1710` | idem |
| `docs/dev-log/dashboard/capability-census/_master.tsv:485,486,461` | same three | idem |
| `docs/dev-log/dashboard/capability-census/student.tsv:2,3` · `skew_normal.tsv:6` | same | idem |
| `AGENTS.md:369` | `R/profile.R:3844` | 3852 |

On `origin/main`, `R/profile.R:1276` is `drm_profile_targets <- function(object) {`, so
`ev-mc-0484-legacy`'s range `1280-1309` covered that function's head; post-edit it points 21 lines
short. `python3 tools/capability_ledger.py --check` → `capability-ledger: OK (30 generated outputs)`
— it does **not** validate anchors, so nothing catches this. Same class as the fix that was applied;
just applied to one file out of five.

### R4 · SHOULD-FIX — the new guard's own provenance citations are stale in the same commit

`tools/profile-fence-fixtures.R` cites test-file line ranges as the proof that each route reuses a
formula/DGP "already proven to pass in the repo". Every one I checked was correct against
`origin/main` and is wrong against the working tree, because the *same commit* inserted lines into
those test files:

| fixture line | citation | origin/main content | working-tree content |
|---|---|---|---|
| `:557` (mc-0594) | `test-zero-one-beta.R:776-782` | animal q1 sigma gate | **coi phylo** assertions |
| `:601` (mc-0596) | `test-zero-one-beta.R:824-830` | spatial q1 sigma gate | **animal** fit assertions |
| `:623` (mc-0597) | `test-zero-one-beta.R:958-962` | phylo-interaction q1 sigma gate | unrelated `expect_error` + `})` |
| `:710` (mc-0418) | `test-count-structured-mu.R:936-951` (seed 2026072801) | NB2 phylo labelled q2 | a block with **seed 2026072812** |
| `:734/746/759` | `test-count-structured-mu.R:1119-1186` | "Poisson admits only the C2 labelled provider cohort" | `)` inside an `expect_error` |
| `:840` (mc-0653) | `test-phylo-interaction.R:509-525` | zi-NB2 gate test | the **new** smoke test's comment block |
| `:862` (fenced-zi) | `test-phylo-interaction.R:659-669` | zi-NB2 ordinary sigma | the **NB2** phylo-interaction fit |

A reviewer following these lands on the wrong test. This is the load-bearing provenance for the 12
routes whose spellings were *not* verified against a runner.

### R5 · NOTE — census verified unchanged; the brief's "182/60" is model_surface-scoped, not wrong

```
git diff --stat origin/main -- docs/dev-log/dashboard/capability-ledger/   ->  (empty)
python3 tools/capability_ledger.py --check                                 ->  OK (30 generated outputs)
axis == model_surface: 182 interval_feasible · 60 point_fit_recovery       (matches the brief)
whole file:            187 interval_feasible · 78 point_fit_recovery
all 14 cells:          evidence_tier = point_fit_recovery, capability_status = implemented
```

Only `docs/dev-log/dashboard/estimator-surface-conformance.tsv` is modified under
`docs/dev-log/dashboard/`. `cells.tsv`, `evidence.tsv`, and the transitions/census files are
byte-identical to `origin/main`. **No promotion. Confirmed.**

### R6 · NOTE — no validity or coverage claim anywhere in the change

I read `NEWS.md:3-42`, the new `@section` (`R/profile.R:174-189` → `man/confint.drmTMB.Rd:225-243`),
every changed `test_that()` description, and every new comment. Nothing asserts or implies coverage,
calibration, or promotion. `NEWS.md:22-26` disclaims explicitly ("It is not a claim that the
resulting interval attains nominal coverage, and it promotes no capability-ledger cell"), and each
new interval test carries "This is not a coverage or recovery claim — a single seed carries no error
bar for that". Clean.

### R7 · NOTE — the bias claim is sourced, but extrapolated in the indicative

Traced to `docs/dev-log/after-task/2026-08-03-nbinom2-structured-sigma-family-low-bias.md:69,120`
(mc-0421 2/3, mc-0422 3/3, mc-0423 3/3, mc-0424 3/3 → 11/12; one-sided p = 0.0032). Arithmetic
checks: `P(X≥11 | n=12, p=½) = 13/4096 = 0.00317`; cell level `(½)^4 = 0.0625`. Both correct.

But `man/confint.drmTMB.Rd:227-231` says the ML estimate "**is biased low** for this class of cell"
where the class is stated as `zero_one_beta()`, `nbinom2()`, **and** `zi_nbinom2()`, while the
measurement exists only for the four `nbinom2` provider cells. The word "sibling" flags the
extrapolation and the direction is conservative (warning where none was measured), so this is not an
overclaim — but a shipped man page asserts an unmeasured property of two families. One hedging clause
("no equivalent measurement exists yet for `zero_one_beta()` or `zi_nbinom2()`") would close it.

### R8 · NOTE — NEWS's enumeration does not add to fourteen

`NEWS.md:5-16` lists: 2 ordinary zob sigma + 5 structured zob sigma + "the labelled intercept-slope
covariance blocks of `poisson()` and `nbinom2()` `mu`" + 2 count sigma-interaction. A reader counts
**11**, not 14, because the third item silently stands for five cells and does not say that `nbinom2`
is `phylo`-only while `poisson` covers `phylo`/`spatial`/`animal`/`relmat`. That asymmetry is real
(pre-edit, `nbinom2` q2 labelled with `spatial`/`animal`/`relmat` was already unfenced — grid row
`neg-nbinom2-mu-q2-spatial-not-permitted` covers it) and it is exactly the kind of thing a reader of
a fence NEWS item needs.

---

## GRACE — environment parity and CI reality

### G1 · NOTE (verified) — the two libraries genuinely differ

`.so` md5s and `Built:` strings differ (shown above), and the sweep's own provenance line proves the
namespaces differ where it matters: `deleted_fns_present=TRUE,TRUE` (OLD) vs `FALSE,FALSE` (NEW).

### G2 · NOTE (verified) — the orchestrator really does not load drmTMB

The claim in `tools/profile-fence-fixtures.R:6-11` and
`tools/check-profile-fence-integrity.R:86-89` checks out:

```
$ Rscript --vanilla -e 'source("tools/profile-fence-fixtures.R"); profile_fence_grid(); profile_fence_routes();
                        cat("drmTMB loaded:", "drmTMB" %in% loadedNamespaces())'
grid rows: 58   routes: 24   drmTMB loaded: FALSE   attached: FALSE
```

Every drmTMB reference in the fixtures is inside a closure. Worker isolation via
`system2("Rscript", ...)` is real, one process per library.

### G3 · SHOULD-FIX — guard mode silently discards the caller's library path

`run_worker()` is called from guard mode with `r_libs_user = NULL`
(`tools/check-profile-fence-integrity.R:122`), so line 93 emits `R_LIBS_USER=` (empty). Because
`$R_HOME/etc/Renviron:48` is `R_LIBS_USER=${R_LIBS_USER:-'%U'}`, an **empty** value is replaced by
R's *default* user library — the worker does not inherit and does not fall back to the caller's:

```
$ R_LIBS_USER=/tmp/.../fakelib Rscript --no-init-file -e '
    cat(.libPaths()); system2("Rscript", c("--vanilla","-e",shQuote("cat(.libPaths())")), env="R_LIBS_USER=")'
OUTER: /tmp/.../fakelib  +  .../R.framework/.../library
INNER: /Users/z3437171/Library/R/arm64/4.6/library  +  .../R.framework/.../library      <-- fakelib gone
```

`run_diff_mode()` already knows about this and handles it explicitly
(`tools/check-profile-fence-integrity.R:222-226`, with a comment naming the failure:
"not just `.Library` … which omits the user library and makes the worker subprocess fail to find
TMB"). Guard mode does not.

On GitHub Actions this happens to work: `r-lib/actions/setup-r-dependencies@v2`'s `action.yaml`
lines 99-106 read `Sys.getenv("R_LIBS_USER")` **from R** and export that same value to `GITHUB_ENV`,
so the runner's `R_LIBS_USER` *is* R's default and the substitution returns the same path. But the CI
step's success depends on that coincidence, and it breaks under any non-default library (an `renv`
project, a self-hosted runner that pre-sets `R_LIBS_USER`, or a developer running the guard under a
project library). One-line fix, matching line 226:
`worker <- run_worker(out_dir, r_libs_user = paste(.libPaths(), collapse = ":"), load_all_path = pkg_root)`.

### G4 · NOTE (verified) — this is **not** the `test-estimator-surface-conformance.R` mistake

The named precedent is a test inside `tests/` that reads a `docs/` file excluded by
`.Rbuildignore:10 ^docs$`, so it silently skips under `R CMD check`. The new guard is a different
shape and is safe:

* `.Rbuildignore:17` contains `^tools$`, so the guard is not in the tarball and `R CMD check` never
  tries to run it — correct.
* It runs as its own workflow step from the checkout, not from the tarball
  (`.github/workflows/R-CMD-check.yaml:120-125`).
* It reads **no** `docs/` file. `profile_fence_grid()` and `profile_fence_routes()` are pure code.
* It exits non-zero on any violation (`quit(status = ... 1L)`, line 391), and a `run:` step under
  GitHub Actions' default `bash -e` fails the job on a non-zero exit.
* Verified end-to-end locally with the exact CI command:
  `Rscript --no-init-file tools/check-profile-fence-integrity.R` →
  `[guard] enumeration rows=61 battery rows=34 violations=0`, `VIOLATIONS: none`, `EXIT=0`, ~24 s.

### G5 · NOTE (verified) — CI placement and dependencies are sound

The step sits after `Rscript --no-init-file tools/check-capability-runtime.R`, which calls
`pkgload::load_all(root, quiet = TRUE)` (`tools/check-capability-runtime.R:17`) — pkgload's default
`compile = NA`, so the TMB `.so` is already current when the fence guard runs with the same setting.
The guard therefore adds ~24 s, not a multi-minute recompile, inside a 45-minute job budget.
`ape` and `pkgload` are both in `DESCRIPTION` `Suggests:`, which `needs: check` installs.

### G6 · NOTE — no skip path

The battery hard-fails on any fit error; there is no `skip_if_not_installed()` equivalent for `ape`.
Fail-closed, so acceptable, but if the CI dependency set ever changes the guard reports a fit error
rather than a skip. Recording it, not asking for a change.

---

## BOOLE — formula/API coverage

### B1 · NOTE (verified) — all 14 routes match their ledger cells

Cross-checked `tools/profile-fence-fixtures.R` route definitions against
`docs/dev-log/dashboard/capability-ledger/cells.tsv` columns 6 `model_type`, 9 `dpar`,
11 `structure_provider`, 13 `q_gate`:

```
mc-0418 nbinom2      mu    phylo              q2   <- bf(nb2_phylo ~ x + phylo(1 + x | p | site))
mc-0436 poisson      mu    phylo              q2   <- bf(poisson_phylo ~ x + phylo(1 + x | p | site))
mc-0446 poisson      mu    spatial            q2   <- bf(poisson_spatial ~ x + spatial(1 + x | p | site))
mc-0450 poisson      mu    animal             q2   <- bf(poisson_known ~ x + animal(1 + x | p | id, Ainv = Q))
mc-0454 poisson      mu    relmat             q2   <- bf(poisson_known ~ x + relmat(1 + x | p | id, Q = Q))
mc-0425 nbinom2      sigma phylo_interaction  q1   <- sigma ~ phylo_interaction(1 | plant:pollinator, ...)
mc-0653 zi_nbinom2   sigma phylo_interaction  q1   <- same + zi ~ 1
mc-0568 zero_one_beta sigma none              na   <- sigma ~ 1 + (1 | id)          [effect_type ordinary_re_intercept]
mc-0576 zero_one_beta sigma none              na   <- sigma ~ x + (0 + x | id)      [effect_type ordinary_re_slope]
mc-0593..0597 zero_one_beta sigma {phylo,animal,relmat,spatial,phylo_interaction} q1
```

`effect_type` for mc-0568/mc-0576 (`ordinary_re_intercept` / `ordinary_re_slope`) matches the two
formula spellings exactly. **No route fits a different model than the cell it claims.**

### B2 · NOTE (verified) — `parm` spellings resolve

The worker writes `MISSING_ROW` when a `parm` does not match exactly one target row
(`tools/profile-fence-worker.R:197-203`). The local run produced 34/34 clean rows and zero
`MISSING_ROW`; I independently reproduced `stats::confint()` on 7 of those `parm` strings (F3),
including the two correlation targets `cor:phylo:cor(mu:(Intercept),mu:x | p | site)` and
`cor:relmat:cor(mu:(Intercept),mu:x | p | id)`.

### B3 · NOTE — mc-0450 and mc-0454 are the same numerical model twice

`tools/profile-fence-fixtures.R:745-770`: both build from
`new_count_structured_mu_slope_data(seed = 2026072908)`, both fit `poisson_known`, and both pass the
**same** matrix `Q` — one as `animal(1 + x | p | id, Ainv = Q)`, the other as
`relmat(1 + x | p | id, Q = Q)`. `animal(Ainv=)` and `relmat(Q=)` are the same precision
parameterisation, so the two "distinct" cells are one model exercised under two provider keywords.
That is exactly the right test for a *fence* (the provider label is what the predicate reads) but it
is not two independent routes; the route descriptions do not say so.

### B4 · see R4 — the 12 non-runner-verified spellings are cited to line ranges this commit invalidated.

---

## What I did not find

* No newly **fenced** route anywhere in 3,757,600 predicate evaluations.
* No reachable `cli_abort`.
* No ledger, evidence, transitions, or census file modified.
* No coverage, calibration, or promotion claim in `NEWS.md`, the roxygen, any `test_that()`
  description, or any comment.
* No dangling reference to a deleted predicate, and no code orphaned by the deletions.
* No `.Rbuildignore`-invisibility defect in the new guard.
