## 1. Goal

Protect public R interval tables from losing Julia profile-failure status or messages, within the approved twin-parity programme (DRM.jl #563).

## 2. Implemented

Added one mocked regression test covering both fixed-effect and SD profile adapters. It checks failed and searched-range no-crossing results separately, including exact messages, parameter selection and the SD interval transformation. No R production code changed.

## 3a. Decisions and Rejected Alternatives

Use the existing synthetic Julia fit and mock only inference dispatch. Exercise public confint and real R row conversion. Do not require JuliaCall, a fit, compilation or a large campaign for this data-forwarding check. Leave numerical inference correctness to the separate Julia slice.

## 4. Files Touched

tests/testthat/test-julia-inference.R, this report and matching check-log. Raw evidence is retained in the paired DRM.jl repository under docs/dev-log/evidence/julia-r-parity/locscale-profile-status-20260831/.

## 5. Checks Run

R 4.6.0, drmTMB 0.7.0, pkgload with recompile=FALSE: selected test passes 14 assertions with no errors or skips. Its runner parses the actual source test and two existing helper definitions. bridge-r-receipt.json binds the R production bridge and test SHA-256 values. A fresh re-verification passed the same 14 assertions in 2.8 seconds with all R/*.R and selected-test hashes unchanged. No full test-file or live JuliaCall claim.

## 6. Tests of the Tests

The negative-control runner mocks both row adapters to erase conf.status and profile.message. All six intended status/message checks fail and the process exits 1. The raw log has Failure blocks numbered 1 through 6. Production source remains unchanged.

## 7a. Issue Ledger

The parent programme and all global G0–G8 gates remain open. No issue closure, PR publication or collaborator message.

## 8. Consistency Audit

The same infinite bounds can represent a failed search or a searched-range no-crossing result; the test protects their distinct statuses and messages. The R interface forwards columns, not a warning condition. Root also added a Julia helper regression, reviewed separately.

## 9. What Did Not Go Smoothly

A scout initially counted five negative-control failures. Direct inspection of all six numbered raw blocks corrected the count. This was a report-count error, not a new execution result.

## 10. Known Residuals

Live JuliaCall propagation and numerically certified location-scale intervals remain unverified by this R test. Julia implementation review found additional endpoint-status defects; those do not invalidate this narrowly mocked forwarding check. Rose independently approved this bounded R test/report/check-log slice; the Julia implementation remains under repair.

## 11. Team Learning

Root Sol/medium; mechanical scout Luna/low; Rose Sol/high independent review approved. Active agent-hours were not instrumented. Memory receipt: no Codex memory changed. Golden Set: existing synthetic fit and two public adapter paths.

## 12. Cross-Product Coverage

This does NOT cover native-R/direct-Julia numerical parity, a real JuliaCall fit, bootstrap, threading, performance, documentation rendering, full package tests or programme completion.
