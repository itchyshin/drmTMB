# Check log: older open issues sweep (<1650, 2026-11-20)

Base: `main` @ `d3126d93d4b0ef5b940241bb62ba837d4d44df3a` (local `devtools::load_all`).

## Method

- Skipped: issues linked from open PRs, #922, #1554, #1452, and API/estimand/default/convergence-rule buckets.
- Evidence: existing `testthat` files + targeted repro where noted.

## Sampled issue files (pass on main)

| Issue | Local command / file | Result |
| --- | --- | --- |
| #1469 | `test-mle-existence.R`, `test-n8-multistart-note.R` | PASS |
| #1476/#1532 | `test-mi-quadrature-1476-1477.R` | PASS (2 skips: Beta μ≈0.02; several On-CRAN skips) |
| #1459 | `test-mi-weights-1459.R` | PASS (documents open design; warning helper OK) |
| #1267 | R repro `poisson()` + `hu ~ 1` | Still refuses (open) |
| #1129 | — | Still open (inner Newton / closed-form imputed modes) |

Draft fix branch: `cursor/sweep-1468-tweedie-eta-nu-ef39` (refs #1468 only).