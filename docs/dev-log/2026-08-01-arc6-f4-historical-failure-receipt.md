# Arc 6 F4 historical failure receipt

## Purpose

Preserve a current-main, retrievable record of the completed private F4
failure without merging its stale development branch or re-running any
campaign.

## Frozen source

The authoritative historical review is stored in Git commit
`0f0d347db30228313355949ceb77105b8ccae7d1` at:

- `docs/dev-log/2026-07-27-arc6-f4-completion-review.md`
- `docs/dev-log/after-task/2026-07-27-arc6-f4-campaign-failure.md`

That commit records the completed, fixed-effect, complete-pair Bernoulli x
ordinary-NB2 alpha Godambe-Wald screen at source SHA
`a97aa0930cbfe635886f483cb32baf4e75f74227`. This receipt copies the decision
facts only; the historical files remain available through that immutable Git
object.

## Retained failure

The frozen F4 grid comprised 24 cells x 1,000 attempts: 24,000 valid-protocol
attempts. Primary coverage used every valid-protocol outer dataset, treating
an unavailable alpha interval as non-coverage. Five cells missed the
pre-registered 0.925 lower coverage bound:

| Cell | `(n, b0, sigma, alpha)` | Primary coverage |
| --- | --- | ---: |
| f4-c01 | `(120, -1.4, 0.25, 0)` | 0.896 |
| f4-c02 | `(120, -1.4, 0.25, 0.22)` | 0.887 |
| f4-c05 | `(120, -0.2, 0.25, 0)` | 0.912 |
| f4-c06 | `(120, -0.2, 0.25, 0.22)` | 0.904 |
| f4-c10 | `(240, -1.4, 0.25, 0.22)` | 0.923 |

F4 therefore failed. It does not authorize public `vcov()` or `confint()` for
`associate_pairs()`, eta intervals, a capability or ledger change, or F5.
The later F4R high-information screen is a separate private result and does
not erase, retry, or revise this retained F4 failure.

## Scope

This is archival provenance only. It adds no package code, API, public
inference claim, campaign artifact, or compute result.
