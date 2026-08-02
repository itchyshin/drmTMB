# mc-0615 diagnosis — the structured relmat path is not the problem

**Diagnostic only. No capability claim, no promotion, no ledger change.**
`mc-0615` (coi × relmat) remains `not_implemented`.

Runner: `tools/run-c18-mc-0615-structured-vs-ordinary-probe.R` · source `47a87ac93` · 2026-08-02.

## The question

`mc-0615` was the one C18 atom cell withheld: 3/4 seeds, with seed `2026080624` collapsing the
latent SD to `tau_hat = 0.0006` against a truth of 0.55. Two hypotheses were open:

1. the **structured relmat** path misbehaves relative to the ordinary route, or
2. that particular field draw genuinely makes `tau → 0` preferred.

These matter differently. (1) would be a defect worth fixing, and fixing it would legitimately earn
the cell. (2) means the cell is fine and the gate caught ordinary sampling variability.

## Method

For each of 20 seeds, simulate **once** from the `mc-0615` DGP, then fit the **same data** two ways:

- structured: `coi ~ relmat(1 | species, K = K)`
- ordinary:   `coi ~ 1 + (1 | species)`

If the structured path were at fault, it would collapse on seeds where the ordinary route does not.

## Result — hypothesis (1) is refuted

| | collapses (`tau_hat < 0.05`) |
| --- | --- |
| structured `relmat` | **1 / 20** |
| ordinary `(1 \| species)` | **1 / 20** |
| **structured-only** | **0** |

Both collapse on **exactly the same seed** — `2026080624`, the one that failed the recovery run.
The structured machinery is not implicated. It is the data.

The structured path is in fact *better* behaved than the ordinary one. Median `tau_hat` against a
truth of 0.55:

| | median `tau_hat` | relative bias |
| --- | --- | --- |
| structured `relmat` | 0.4487 | **18.4%** |
| ordinary `(1 \| species)` | 0.3409 | 38.0% |

That is the expected direction: the GMRF prior borrows strength across the correlated field, so the
structured estimator shrinks less than an iid one on the same data.

## The consequence, which is about the GATE and not the cell

The per-seed collapse rate is ≈ 1/20 = 5%. Under an **all-must-pass** decision rule over `n` seeds,
the probability of blocking a genuinely capable cell is `1 − (1 − 0.05)^n`:

| seeds | P(block a working cell) |
| ---: | --- |
| 4 | **18.5%** |
| 8 | 33.7% |
| 12 | 46.0% |
| 20 | 64.2% |

**Roughly one in five capable `coi` cells is expected to be blocked at the current 4-seed bar, by
construction.** `mc-0615` is a draw from that distribution, not a capability limit.

### This refutes the obvious remedy, including the one recommended during C18 review

Fisher's plan-review dissent proposed raising `coi` to 8–12 seeds on the grounds that 4 has low
power. The table above shows that under an **all-must-pass** rule more seeds make the gate *stricter*,
not better powered — 12 seeds would block 46% of capable cells. The seed count was never the
problem. **The decision rule is.**

A defensible alternative would be a rule that tolerates a bounded failure fraction (for example,
"≥ 90% of seeds pass, and the mean relative `tau` error over passing seeds ≤ 0.40"), or one that
treats a boundary collapse as a separately reported diagnostic rather than an automatic block. Both
are changes to the C16 contract and therefore need the owner's decision — they must not be made
silently to rescue one cell.

## What this does and does not license

- It does **not** promote `mc-0615`. The gate as written returned `BLOCKED_LOCAL_FIXTURE` and that
  stands.
- It does **not** license re-running `mc-0615` with other seeds. Under the current rule that is
  seed-shopping, and this note makes the reason precise rather than removing it.
- It **does** close hypothesis (1): there is no structured-relmat defect to fix, so there is no
  bug-fix route to an eighth atom cell.
- It **does** put a number on the gate's false-block rate, which is a property of every `coi` cell
  promoted under C16 parity, not only of `mc-0615`.

## Files

`README.md` (this note) · runner `tools/run-c18-mc-0615-structured-vs-ordinary-probe.R` ·
`relmat_probe.tsv` (per-seed `tau_hat` for both fits).
