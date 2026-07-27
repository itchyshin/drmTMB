# Lane B E1 source map — Arc D Design 2 trace-first contract

**Purpose.** This is the source map for the *implemented* Arc D Design 2
trace-first `clamp_limited` contract. It separates that narrowly bounded
numerical/profile safeguard from E1 campaign planning and from unrelated lanes.
It is an implementation map, not fit, smoke, simulation, coverage, capability,
or public-inference evidence.

## Authoritative change

The authoritative merged change is [PR #857](https://github.com/itchyshin/drmTMB/pull/857),
merged as `f6cc6fe52250827d1b9cfc54912e4954b7093f50` (*Arc D: trace full TMB
profile evaluations*). The Lane-B prerequisite receipt records its green Ubuntu
release check and the retained interpretation: `clamp_limited` and
`trace_incomplete` are unavailable and non-covering, while K=12 remains
negative evidence ([`docs/dev-log/2026-07-27-lane-b-e0-prerequisite-receipt.md:8-16`](2026-07-27-lane-b-e0-prerequisite-receipt.md)).

The merge changes six implementation/test surfaces only:

| Surface | Responsibility in the merged contract |
| --- | --- |
| [`src/drmTMB.cpp:18-65`](../../src/drmTMB.cpp) | Applies the configured residual-scale soft clamp to direct-SD predictors before exponentiation, while retaining the overflow-only guard; the raw predictor is retained for reporting. |
| [`src/drmTMB.cpp:853-866`](../../src/drmTMB.cpp), [`src/drmTMB.cpp:2305-2320`](../../src/drmTMB.cpp) | Uses that direct-SD clamp in likelihood and reporting paths. The analogous phylogenetic and other model-type sites follow the same helper rather than inventing a second clamp. |
| [`R/drmTMB.R:20188-20269`](../../R/drmTMB.R) | Reconstructs raw direct-SD log predictors without clamping/exponentiating for the trace classifier, and mirrors C++ clamping for R-side extracted values. |
| [`R/profile.R:3399-3538`](../../R/profile.R) | Wraps only the full `TMB::tmbprofile()` objective, snapshots the baseline plus every `obj$fn()` evaluation, reconstructs raw direct-SD predictors, and classifies clamp contact fail-closed. |
| [`R/profile.R:2831-2905`](../../R/profile.R), [`R/profile.R:1237-1250`](../../R/profile.R) | Converts a non-`ok` applicable trace to a `tmbprofile` result with `conf.status = "clamp_limited"`, `profile.boundary = TRUE`, `profile.message` equal to the trace status, and missing endpoints; registers the status vocabulary. |
| [`tests/testthat/test-arc-d-profile-trace.R:13-132`](../../tests/testthat/test-arc-d-profile-trace.R), [`tests/testthat/test-arc-d-sd-overflow-guard.R:25-114`](../../tests/testthat/test-arc-d-sd-overflow-guard.R), [`tests/testthat/test-phase18-meta-v-lss-runner.R:66-86`](../../tests/testthat/test-phase18-meta-v-lss-runner.R) | Pin private trace capture, raw/C++ alignment, interval withholding on contact, the unchanged overflow failure route, and the K=12 negative-control reduction. |

The two design records were not changed in PR #857, but remain the policy
context: Design 245 identifies the false-precision failure created by applying
the residual clamp to direct-SD regression ([`docs/design/245-f5-sd-regression-clamp-and-identifiability.md:47-80`](../design/245-f5-sd-regression-clamp-and-identifiability.md)); Design 247 describes Design 2 as "clamp, and report" and anticipates its status-contract cost ([`docs/design/247-arc-d-clamp-profile-contract-d1.md:125-149`](../design/247-arc-d-clamp-profile-contract-d1.md)).

## Exact trace and `clamp_limited` contract

1. The likelihood clamps a direct-SD raw linear predictor only when
   `use_logsigma_clamp == 1`; it then passes the clamped value to the existing
   overflow guard. The raw predictor is still reported and is the value examined
   by profiling ([`src/drmTMB.cpp:41-65`](../../src/drmTMB.cpp),
   [`src/drmTMB.cpp:2305-2320`](../../src/drmTMB.cpp)).
2. `drm_tmbprofile()` pins the fitted TMB object, installs a private `obj$fn()`
   wrapper, and attaches a snapshot containing the fitted baseline and every
   evaluated fixed parameter vector to the profile object
   ([`R/profile.R:3399-3473`](../../R/profile.R)). This is trace-first because
   the full TMB profile API does not otherwise return all constrained optimizer
   states.
3. `drm_profile_direct_sd_clamp_trace()` reconstructs the direct-SD raw
   predictor at the baseline and every traced evaluation. It returns
   `not_applicable` when the clamp is disabled; `ok` only after every applicable
   value is finite and inside the identity band; `clamp_limited` when any value
   lies outside it; and `trace_incomplete` for malformed bands, missing trace,
   failed parameter reconstruction, or non-finite reconstructed values
   ([`R/profile.R:3475-3538`](../../R/profile.R)). Thus missing trace evidence is
   never interpreted as no clamp contact.
4. For the full `tmbprofile` route, either `clamp_limited` or
   `trace_incomplete` withholds the interval. The returned row has
   `lower = upper = NA`, `conf.status = "clamp_limited"`,
   `profile.boundary = TRUE`, and the trace status as `profile.message`
   ([`R/profile.R:2838-2855`](../../R/profile.R),
   [`R/profile.R:2889-2905`](../../R/profile.R)). The curve-reporting route
   likewise does not publish a finite profile interval after a non-`ok` trace
   ([`R/profile.R:899-929`](../../R/profile.R)).

The fixture tests are deliberately exact: synthetic clamp contact is classified
as `clamp_limited` ([`tests/testthat/test-arc-d-profile-trace.R:77-110`](../../tests/testthat/test-arc-d-profile-trace.R)); a clamp-touched full profile returns
the status/boundary/message above and both endpoints `NA`
([`tests/testthat/test-arc-d-profile-trace.R:112-132`](../../tests/testthat/test-arc-d-profile-trace.R)).

## K=12 and unavailable/non-covering fence

The dense location-scale-scale meta-V K=12 control is retained as a failure
detector, not converted into a finite interval. Its test permits only
`nonfinite_interval`, `clamp_limited`, or `trace_incomplete` messages, while
requiring `interval_status = "incomplete"`, `complete_profile = 0`, and
`usable_and_covering = 0` ([`tests/testthat/test-phase18-meta-v-lss-runner.R:66-86`](../../tests/testthat/test-phase18-meta-v-lss-runner.R)). This preserves the
central Design-245 observation: a finite K=12 endpoint caused by the band is
false precision, not information from the data
([`docs/design/245-f5-sd-regression-clamp-and-identifiability.md:51-75`](../design/245-f5-sd-regression-clamp-and-identifiability.md)).

The overflow-only path remains independently fail-closed: with the configurable
clamp disabled, an overflow guard hit makes the objective non-finite and maps to
the pre-existing `profile_failed` handling rather than supplying a guard-shaped
root ([`tests/testthat/test-arc-d-sd-overflow-guard.R:77-114`](../../tests/testthat/test-arc-d-sd-overflow-guard.R)).

## Scope fences

- This is trace support for the full `tmbprofile` route only. The changed call
  sites are `drm_tmbprofile()` and `drm_profile_target_tmbprofile_confint()`;
  the separate endpoint engine is not given an equivalent trace. Therefore this
  map does **not** assert clamp detection for endpoint profiles.
- The change adds no user-facing argument, no capability/ledger transition, and
  no claim that an interval is identified, calibrated, or covering. Its only
  positive behavior is to withhold a full-profile interval when the objective
  encountered a clamp or cannot be reconstructed.
- No fits, smokes, remote compute, campaigns, bootstrap work, association work,
  missing-response work, ledger edits, bindings, or public documentation belong
  to this source-map slice.
- [`docs/design/246-marginal-bootstrap-coverage.md:1-18`](../design/246-marginal-bootstrap-coverage.md)
  is Arc A1 marginal-bootstrap coverage material. It is unrelated to Arc D
  Design 2 and supplies neither an implementation dependency nor evidence for
  this contract.

## Stable reading order

1. Read the merged source in `src/drmTMB.cpp:18-65`, then the matching R
   reconstruction in `R/drmTMB.R:20188-20269`.
2. Read the full-profile wrapper/classifier in `R/profile.R:3399-3538`, then
   the result conversion in `R/profile.R:2831-2905`.
3. Read the three focused test blocks cited above, with the K=12 test as the
   non-covering contract.
4. Use Design 245 for the falsified finite-endpoint mechanism and Design 247
   for the original Design-2 rationale; do not substitute Design 246.
