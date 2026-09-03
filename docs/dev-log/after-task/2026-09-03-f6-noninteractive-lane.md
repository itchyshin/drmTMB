# f6 — regression cover for the non-interactive `engine = "julia"` abort

Date: 2026-09-03 · Branch: `claude/followup-f6-noninteractive-lane` · Base: `9da13cfcd`

## What prompted this

An outside user (Ayumi-495/LS_ecogeographical-rules#29, relayed by the DRM.jl lane)
followed the documented `engine = "julia"` setup literally and it failed in an
ordinary `Rscript` session with "Live Julia setup is disabled on the CRAN check
lane". She found the `DRMTMB_JULIA_TESTS=true` workaround herself and is still
using it.

## What I got wrong first, and how it was caught

I "reproduced" the bug by running the predicate in the main checkout and reporting
it unfixed. That was **invalid**: the main checkout sits on
`feat/bridge-lss-reml-row12` @ `79e8f0951`, 45 commits behind `origin/main`. The
behaviour was already fixed on main in `54366baa` (2026-08-30). Comparing
`git show origin/main:R/julia-bridge.R` against the working tree is what surfaced
it. A working tree is one branch, not the repository — the relayed report was
right and my confirmation of it was wrong.

## What was actually missing

Two things the fix left open. Neither is a re-fix; **this arc changes no file under
`R/` or `src/`.**

**1. The fix had no test that fails without it.** Reverting the
`nzchar(_R_CHECK_PACKAGE_NAME_)` conjunct leaves the existing
`tests/testthat/test-cran-lane-filter.R` fully green — 32 passed, 0 failed. Every
case it asserts either sets `_R_CHECK_PACKAGE_NAME_` or is already exempted by
`NOT_CRAN` / `DRMTMB_JULIA_TESTS`, so the one case a user actually hits — a
non-interactive session with no check marker at all — was never asserted. The fix
could have been reverted with CI green. `tests/testthat/test-julia-noninteractive-lane.R`
fails 2 assertions against the pre-fix predicate.

**2. The marker was chosen by inference, and one check lane is invisible to it.**
Measured with probe packages under real `R CMD check --no-manual`
(`docs/dev-log/evidence/julia-r-parity/check-lane-markers/`):

| lane | `_R_CHECK_PACKAGE_NAME_` | `TESTTHAT_IS_CHECKING` |
|---|---|---|
| `\examples` | set | unset |
| `tests/testthat.R` | set | unset |
| inside `test_check()` | set | set |
| vignette rebuild | **unset** | **unset** |

So the shipped choice is the right one — `_R_CHECK_PACKAGE_NAME_` is the only marker
covering every lane that can reach `drm_julia_setup()`, and `TESTTHAT_IS_CHECKING`
would have missed the examples lane, which is the lane the guard was written for
(#1061, the ~10448 s Ligges hang). But the **vignette rebuild carries no check
marker of any kind**, so no marker-based predicate can see it. That is safe today
only because no evaluated vignette chunk calls `engine = "julia"` — the
`julia-engine.Rmd` examples are display-only ` ```r ` fences. The new test file
scans every vignette and fails if an evaluated chunk ever does, with a positive
control proving the scanner detects a planted chunk while correctly ignoring a
display-only fence and an `eval=FALSE` chunk.

## Verification

`.unlazy/followup/gates/leaf-f6.md`, gates f6-G1..G7 met. Two RED controls, both
with the predicate restored byte-identically afterwards (`git diff --name-only -- R`
empty): existing suite stays green with the fix reverted (the finding); new file
fails 2. Neighbouring suites (`test-cran-lane-filter.R`,
`test-julia-batch-startup.R`, `test-julia-bridge-summary.R`) clean; python capability
guards clean; lss-tip-identity receipt still verifies because `R/` is untouched.

## What this does NOT cover

- **It does not get the fix to the user.** `54366baa` is on `main`; `DESCRIPTION`
  still reads `Version: 0.7.0` and the newest tag is `v0.5.0`. Anyone installing a
  tagged version still hits the abort. Whether to release is the owner's call
  (D-164 holds CRAN); the actionable answer for the reporter today is to install
  from `main` at `54366baa` or later.
- It does not touch the `check_drm()` cosmetic false positive also reported.
- It does not change the test-suite skip predicate in
  `tests/testthat/helper-julia-bridge-path.R`, which still uses `!interactive()`.
  That is a *test-skipping* policy, not the user-facing API refusal, and D2's
  loud-skip evidence depends on its current behaviour. Left deliberately unchanged
  rather than swept along.
