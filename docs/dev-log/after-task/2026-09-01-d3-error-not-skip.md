## 1. Goal

Repair a test-honesty defect in `tests/testthat/test-julia-tmb-parity.R` (drmTMB
issue #1083): every parity fit was wrapped in `tryCatch(..., error = function(e)
testthat::skip(...))`, so a genuine code regression in the fit path read
identically to JuliaCall/DRM.jl not being installed. Distinct from #1081 (zero CI
coverage); this is about what happens when the test DOES run.

## 2. Implemented

Added a discrimination rule to the test file and applied it at every call site.

**The rule.** `drm_parity_environment_absent_patterns` is a small, explicitly
commented allowlist of the exact startup-failure message substrings that
`JuliaCall::julia_setup()` and `drm_julia_setup()` raise when Julia/DRM.jl itself
is unreachable ("Julia is not found", "libjulia cannot be located", version too
old, sysimage not found, DRM.jl checkout missing/invalid). `drm_parity_run(fit_fn,
label)` runs `fit_fn()`; if the error matches the allowlist it `skip()`s, otherwise
it `fail()`s. In two sentences: an error is classified "environment absent" only
if its message matches one of eight narrow, explicitly-enumerated startup-failure
signatures from `JuliaCall::julia_setup()` or `drm_julia_setup()`; every other
error — including a genuine code/marshalling regression, or JuliaCall's generic
"Error happens when you try to execute command" wrapper around a DRM.jl-side
error — now fails the test instead of being silently skipped.

**Scope.** The same `tryCatch(...) -> skip()` pattern was replicated at all 9
`test_that()` blocks in the file (Route C, Route B, q2 phylo, q2 known-structured,
Route A, q1 relmat/animal/spatial ML, q1 sigma-phylo ML), not only the one cited
in the task description. Fixed all 9 together (adaptive scope, approved by the
coordinator mid-task): leaving 8 of 9 in the swallow-everything state after fixing
one would have been the dishonest option. Also removed 7 sites' `if (inherits(res,
"error")) fail(...)` blocks that followed the old `tryCatch` — dead code, since
`callr::r(..., error = "error")` throws rather than returning an error object, so
that branch could never fire.

**The two pre-existing environment gates above `drm_parity_run()` — 
`skip_if_not_installed("JuliaCall"/"callr"/"pkgload"/"ape")` and
`skip_if_not(dir.exists(drm_parity_jl_path()), ...)` — are untouched** (verified:
40 `skip_if_not*` calls and the file-level `drm_skip_live_julia()` gate are
identical before/after, `git diff` confined to this one file).

## 3a. Decisions and Rejected Alternatives

Classify by a narrow, explicitly-enumerated, commented allowlist of known
startup-failure message substrings rather than a broad heuristic (e.g. "contains
'julia'" or a condition-class check) — `JuliaCall::julia_setup()` and
`drm_julia_setup()` raise plain `simpleError`/`rlang_error` conditions with no
distinguishing class, so message-substring matching was the only discriminator
available; kept the list to the exact `stop()`/`cli_abort()` text those two
functions emit (read from their R source, not guessed) to avoid accidentally
swallowing a DRM.jl-side error whose message happens to mention "Julia".

**Unanchored substrings, not `^`/`$`-anchored regexes — found via the red-test
loop itself, not by inspection.** The first version of the allowlist used `^Julia
is not found` etc. This looked right by inspection but was silently WRONG: a
`callr::r(..., error = "error")` subprocess error's `conditionMessage()` is a
multi-line `"! in callr subprocess.\nCaused by error in \`...\`:\n! Julia is not
found."` chain, not a bare message starting with the JuliaCall text. The anchored
patterns therefore never matched anything, and the negative-control run (§5 below)
failed closed into FAIL instead of SKIP on a genuinely absent environment — caught
only by actually running that negative control live, exactly the kind of gap
`verification-before-completion` exists to catch. Fixed by dropping the anchors to
unanchored substring matches (still narrow and commented; re-verified live, §5).

Left the post-injection cascade of extra `expect_true`/`expect_lt` failures inside
`test_that("... Route C")` as-is (`testthat::fail()` does not abort the rest of the
block the way `stop()`/`skip()` do, so a code-error case now reports 1 primary
failure plus a few downstream ones from asserting against a broken `res`). This
matches existing repo convention (`testthat::fail()` was already used the same way
at 7 of the 9 sites, in the dead-code branches removed here) and the FAIL/SKIP
distinction the task cares about is already unambiguous from the first failure
message. Considered decision, not an oversight; not changing it in this slice.

## 4. Files Touched

`tests/testthat/test-julia-tmb-parity.R` only. This report.

## 5. Checks Run — Mandatory Red-Test Evidence

**(a) Injection.** Added `stop("SYNTHETIC CODE BUG (D3 red-test injection):
marshalling contract broken")` to `drm_parity_fit_route_c()`, right after the TMB
fit and before the Julia fit call — a plain-message R error that does not match
the environment-absent allowlist, standing in for a genuine marshalling
regression.

**(b) Confirmed FAIL, not skip.** Ran (against a live local DRM.jl checkout, see
§ pinned ref below):

```
NOT_CRAN=true DRM_JL_PHYLO_PATH="/Users/z3437171/Dropbox/Github Local/DRM.jl" \
  Rscript -e 'devtools::test(filter = "julia-tmb-parity", reporter = "summary")'
```

Observed output (first, primary assertion):

```
── 1. Failure ('test-julia-tmb-parity.R:134:3'): engine='julia' == engine='tmb' 
tmb-vs-julia parity round-trip (Route C) subprocess raised a CODE error (not an environment gap): ! in callr subprocess.
Caused by error in `(function (pkg, jl_path) ...`:
! SYNTHETIC CODE BUG (D3 red-test injection): marshalling contract broken
Backtrace:
    ▆
 1. └─drmTMB (local) drm_parity_run(drm_parity_fit_route_c, "tmb-vs-julia parity round-trip (Route C)") at test-julia-tmb-parity.R:134:3
```

This first run used the still-anchored (`^`) version of the pattern list and
happened to pass because the injected message is not one of the allowlisted
startup-failure strings under either version. The anchoring bug was found next,
via the negative control (below), not via this run.

**(c) Injection removed**, `git diff`/`grep -rn "SYNTHETIC CODE BUG"` confirmed
clean before every commit.

**(d) Negative control — confirmed SKIP.** With a deliberately broken environment
(`DRM_JL_JULIA_HOME` pointed at a nonexistent path, real DRM.jl checkout present so
the subprocess reaches `JuliaCall::julia_setup()` and fails there):

First attempt, with the still-`^`/`$`-anchored pattern list, **failed the gate it
was meant to prove**: all 9 tests came back as FAILUREs, not skips, e.g.

```
── 1. Failure ('test-julia-tmb-parity.R:133:3'): ...
tmb-vs-julia parity round-trip (Route C) subprocess raised a CODE error (not an environment gap): ! in callr subprocess.
Caused by error in `JuliaCall::julia_setup(installJulia = FALSE)`:
! Julia is not found.
```

Root cause diagnosed live (§3a): `conditionMessage()` on a callr subprocess error
is the multi-line "Caused by error..." chain, so the `^`-anchored pattern
`"^Julia is not found"` never matched a message that doesn't start with that
string. Fixed by unanchoring the patterns and correcting the DRM.jl-checkout
patterns to match the real `cli_abort()` text (`"The DRM.jl path '...' does not
exist."`, confirmed by calling `drmTMB:::drm_julia_setup()` directly).

Re-ran the same negative control after the fix — **all 9 tests SKIP**, e.g.:

```
1. engine='julia' == engine='tmb' to <=1e-6 on Gaussian location-scale (Route C) ('test-julia-tmb-parity.R:141:3') - Reason: tmb-vs-julia parity round-trip (Route C) unavailable: ! in callr subprocess.
Caused by error in `JuliaCall::julia_setup(installJulia = FALSE)`:
! Julia is not found.
```
(9 skips total, one per `test_that()` block, all citing "Julia is not found.")

**Re-verified the red test against the corrected pattern list** (re-injected the
same `stop()`, ran `testthat::test_file()` against the live DRM.jl checkout,
observed the same primary FAILURE at Route C with the injected message, and
observed the other 8 tests PASS live — `julia-tmb-parity: 1234.........` where `1234`
are the 4 Route-C assertions that fail and the trailing dots are the other 8
tests' assertions passing against the pinned DRM.jl ref). Removed the injection a
final time; `grep -rn "SYNTHETIC CODE BUG"` across the repo returns nothing.

## 5a. Pinned DRM.jl Reference

The live round-trips above ran against a local DRM.jl checkout at
`/Users/z3437171/Dropbox/Github Local/DRM.jl` — **another lane's working tree**,
not modified in any way by this task. Pinned state at time of measurement:

```
git -C "/Users/z3437171/Dropbox/Github Local/DRM.jl" rev-parse HEAD
f47789646f27221ba4fad29a8ba1b3b8a790b521
git -C "/Users/z3437171/Dropbox/Github Local/DRM.jl" branch --show-current
main
```

(One untracked file, `.codex/agents/shannon-coordinator.toml`, present but not
touched or relevant to any tracked source; no modifications to tracked files.)

## 6. Filtered-Suite Run

`Rscript -e 'devtools::test(filter = "julia", reporter = "summary")'` with
`NOT_CRAN=true` and no `DRM_JL_PHYLO_PATH` override (default local environment —
same as CI's live-Julia-absent default), matching the task's "filtered suite only,
not the full suite" instruction:

- 34 `julia-*` test files matched.
- **982 pass, 24 skip, 0 fail, 0 error, 0 warning.**
- All 24 skips are legitimate environment-absent skips (`DRM.jl engine path not
  available`, `DRM.jl phylo engine not available`, etc.) or the file-level CRAN
  guard; none are the `julia-tmb-parity` block's tests reporting anything other
  than a clean skip in this no-Julia-configured environment (9 of the 24 skips
  are this file's 9 blocks).

Full suite (`devtools::test()`) was explicitly **not run** — the coordinator
reserves that as a single later integration gate, and running it in every parallel
lane already breached the estimate-before-you-run discipline once this session.

## 7. Tests of the Tests

The red-test/negative-control loop above IS the test of the test: it demonstrated
the guard can both fail (on an injected code error) and skip (on a genuinely
absent environment), and it caught a real bug in the guard itself (the anchoring
mistake) that a static read of the code would not have surfaced — the anchored
regex looked completely reasonable until it was run against a live callr error.

## 7a. Issue Ledger

Addresses drmTMB #1083. Distinct from #1081 (CI coverage), which remains open and
unaddressed by this slice. No release, merge to main, version bump, or push
occurred — commit only, on `claude/rev-parity-d3-error-not-skip`.

## 8. Consistency Audit

Checked all 9 `test_that()` blocks in the file use the same `drm_parity_run()`
helper with a distinct, descriptive label; checked the two environment gates
(`skip_if_not_installed`, `skip_if_not(dir.exists(...))`) are byte-identical to
before (`git diff` shows only additions/removals inside the function bodies, none
in the gate lines); checked no other test file in the repo shares this exact
`tryCatch(..., error = skip(...))` pattern for a parity round-trip (a `grep` for
the same idiom was scoped to this file only, per the task's boundary).

## 9. What Did Not Go Smoothly

The first version of the discrimination rule was wrong in a way that inspection
alone would not have caught: `^`-anchored regexes against `conditionMessage()`
looked correct but never matched because callr wraps subprocess errors in a
multi-line "Caused by error..." chain. This was found only by actually running the
negative control live (per the task's own mandatory-red-test discipline extended
to the skip side), not by re-reading the code. Also hit the general slowness of
live Julia startup (~30-60s per subprocess, worse under this shared machine's
concurrent load from unrelated agents' Julia processes) — several runs took
minutes longer than a quiet-machine estimate would suggest.

## 10. Known Residuals

This does NOT cover: #1081 (CI coverage — this file still runs nowhere in CI by
default); any change to `R/julia-bridge.R`, `.github/workflows/`,
`inst/extdata/julia-capabilities.tsv`, or `docs/dev-log/coordination-board.md`
(explicitly out of scope, untouched); the full `devtools::test()` suite (not run,
per coordinator instruction); the cascade of secondary `expect_*` failures after a
primary code-error `fail()` (left as a considered convention match, not fixed);
whether other test files in the repo have the same swallow-everything defect
outside this one file (not audited here — scoped to
`test-julia-tmb-parity.R` per the task).

## 11. Team Learning

The mandatory red-test discipline this task specified ("inject a code error,
confirm FAIL; remove it; confirm a genuine environment-absent case still SKIPS")
caught a real defect in the fix itself, not just in the original code: an
anchored-regex discrimination rule that looked obviously correct on inspection
silently failed-closed on the skip side because of how `callr::r(error = "error")`
wraps subprocess conditions. The negative-control half of the red test is not
optional decoration — it is exactly what caught this. Also: when the same defect
pattern is replicated at N call sites in one file, fix all N in the same slice
(Rose principle) rather than treating "only the one example cited" as the scope
boundary; the coordinator confirmed this as adaptive scope, not drift.

## 12. Cross-Product Coverage

This covers: the discrimination rule and its application at all 9 call sites in
`tests/testthat/test-julia-tmb-parity.R`; live confirmation (against a pinned
DRM.jl ref) that a code error fails and an absent environment skips; a
default-environment filtered-suite run (`filter = "julia"`) showing 0
regressions. It does NOT cover: CI wiring for this file (#1081), the full package
test suite, any DRM.jl-side change, or any claim about the correctness of the
parity fits' numeric assertions themselves (unchanged by this task).
