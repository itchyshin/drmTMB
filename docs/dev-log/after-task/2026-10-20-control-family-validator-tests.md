# Control, family and Julia-bridge validator tests

## 1. Goal

Pin the behaviour of small pure-R validators with direct tests, so later
refactors of the control and bridge code cannot change them silently.

## 2. Implemented

New `tests/testthat/test-control-family-validators.R` covers
`drm_control_flag()`, `drm_control_validate_start()`,
`drm_control_reserved_names()` (R/control.R), `drm_family_call_parts()` and the
two beta-call detectors (R/family.R), and `drm_julia_supported_algorithms()`,
`drm_julia_validate_g_tol()`, `drm_julia_validate_algorithm()`
(R/julia-bridge.R).

## 3a. Decisions and Rejected Alternatives

Characterisation only; no `R/` change. `drm_julia_translate_control()`,
`drm_julia_default_control()` and identical()-based control gating are left out
on purpose (issue #1471, PR #1502).

Observation, not a bug: both beta-call detectors require a zero-argument call,
so `beta(...)` is not matched; only `beta()` is.

## 4. Files Touched

The new test file and this report. No `R/`, `NEWS.md`, `DESCRIPTION` or
existing-test change.

## 5. Checks Run

`testthat::test_file()` on the new file (see PR body for counts).
