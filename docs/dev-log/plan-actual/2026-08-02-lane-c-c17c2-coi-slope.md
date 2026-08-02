# Plan Versus Actual: Lane C C17-C2 `coi` Random Slope

## Planned Claim

Admit and independently adjudicate only
`coi ~ x + (0 + x | id)` for zero-one-beta when the fixed and random slopes
use the same untransformed raw symbol. A successful promotion raises the
canonical model-surface census from `329 / 340 / 18` to `330 / 340 / 17` while
remaining at `point_fit_recovery`.

## Source and Runner Receipt

- Candidate source: `ac86a6429f67b738d9b2e21072b109c9c7681b79`.
- C17-C2 runner SHA-256:
  `01a762c641e13f6b90152b78df7d7d9a226ff3cb553876d0c12b247d5ed31414`.
- C14 compatibility runner SHA-256:
  `03e230c48539267d803a22e43ffcc68786b08236c4bd6bf9f11c1b1b37c9b1df`.
- Totoro checkout:
  `/home/snakagaw/hsq_work/drmTMB-c17c2-ac86a642`.

## Plan Versus Actual

| Item | Plan | Actual | Disposition |
|---|---|---|---|
| Carrier | Reuse C17-C1 `u_coi` / `log_sd_coi` | Reused without C++ changes | As planned |
| Syntax | Exact same-raw-symbol slope | Exact gate implemented; malformed neighbours rejected | As planned |
| Local oracle | Objective `1e-8`, gradient `2e-5`, active SD fence | Passed with independent full-mixture oracle | As planned |
| Recovery ladder | M=16/32 diagnostics, M=64 claim | M=16 3/4, M=32 4/4, M=64 4/4 population recovery | Claim rung passed |
| Boundary-row predictor SD | At least 0.5 in every M=64 group | 3/4 attempts passed; seed 2026081781 minimum 0.403 | Retained warning; strong direct recovery did not support a block |
| External comparator | `glmer()` common parameters within `1e-3` | Maximum difference `5.89e-4` | Passed |
| C14 compatibility | Preserve immutable receipt/fingerprint | 12/12 current-source attempts passed; no historical receipt changed | Passed; ledger guard pending integration |
| Documentation | Exact scope plus limitations | Reader surfaces updated; formula grammar, likelihood docs, and check-log deferred by explicit boundary | As planned |
| Ledger | Promote only `mc-0578` | Waiting for foreign Lane B PR #889, which owns overlapping generated outputs | Pending dependency |
| Review and landing | D-43, focused PR, unchanged-head CI, fresh merge authority | Not yet run because the candidate ledger is not final | Pending |

## Retained M=64 Receipt

- Four of four fits: convergence 0, `pdHess = TRUE`, maximum gradient at most
  0.01, non-boundary SD, and mode correlation above 0.45.
- Mean absolute errors: `mu` intercept 0.0117, `mu` slope 0.0102, `zoi`
  intercept 0.0277, `coi` intercept 0.0231, `coi` slope 0.1068, and log
  `sigma` 0.0062.
- Mean relative random-slope SD error: 0.2776.
- Maximum common-parameter difference from `glmer()`: `5.89e-4`.

## Scope Reconciliation

No structured atom effect, q2-plus route, profile, interval, coverage,
inference-ready/support status, REML/AGHQ path, missing-response route, formula
grammar, Lane A classification, Lane B classification, or foreign branch was
changed. The package check and pkgdown check passed before ledger integration.

This reconciliation remains open until it records the final ledger hash,
review verdicts, PR/head/merge SHAs, detached-main ledger check, and Mission
Control `330 / 340 / 17` read-back.
