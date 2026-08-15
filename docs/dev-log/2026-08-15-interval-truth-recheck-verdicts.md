# Interval-truth re-check — verdicts for the 116 re-checkable cells

**Arc:** drmTMB interval-claim truth audit · lane `claude/lane-interval-truth-audit` · 2026-08-15
**Authorized by Shinichi:** *"re-check the 116 first, magnitude-only is fine — label it."*
**Every verdict in this document is MAGNITUDE-ONLY.** See §4.

## 1. Result

| | cells |
| --- | ---: |
| re-checkable (receipt on disk) | 116 |
| **truth recovered and checked** | **85** |
| truth not recoverable — no verdict | 31 |
| — of the 85: **PASS** (worst relative miss ≤ 5%) | **78** |
| — of the 85: **FAIL** (worst relative miss > 5%) | **7** |

> **CORRECTION (2026-08-15, same day).** This section first reported 77 pass / 8 fail, listing
> `mc-0248` as a failure. That was **my join error, not a defect in the cell** — see §3.1. Under exact
> `target_id` matching the split is **78 / 7**, and **all seven failures are spatial**.

## 2. How truth was obtained — and why it is derived, not hand-typed

The runners named in these cells' evidence rows (`tools/run-lane-b-*-profile-gate.R`) are **not on the
mainline**: 96 of the 116 cite a runner absent from `origin/main`. They were never deleted — the
commits that added them are simply not ancestors of `origin/main`. The receipts are stored under the
producing commit's own sha (e.g. `.../results/3672ce7572feab.../q4-provider-highinfo/mc-0115/`), and
that commit `3672ce757` is exactly where its runner lives.

Each runner reads a frozen contract under `docs/dev-log/interval-campaign-bindings/` carrying a
`true_parameter_scale` column. **101 such contracts exist across refs; exactly 1 survives on
`origin/main`.** Recovering them yielded a numeric truth for 85 of the 116.

For the q4 cohort the contract's truth agrees with the adapter's own `target_truth` vector
(`c(.55, .50, .40, .35)` in `lane_b_q4_provider_contracts()`), so the value traces to fixture **code**,
not to prose. That is the standard this arc requires.

## 3. THE SEVEN FAILURES — every one of them spatial

| cell | truth | retained interval | worst miss | target |
| --- | ---: | --- | ---: | --- |
| `mc-0116` | 0.50 | `[1.676, 2.544]` | **235.2%** | `sd:mu:mu2:spatial(1 \| p \| site)` |
| `mc-0115` | 0.55 | `[1.773, 2.677]` | **222.4%** | `sd:mu:mu1:spatial(1 \| p \| site)` |
| `mc-0117` | 0.40 | `[0.929, 1.843]` | **132.2%** | `sd:mu:sigma1:spatial(1 \| p \| site)` |
| `mc-0118` | 0.35 | `[0.607, 1.310]` | **73.5%** | `sd:mu:sigma2:spatial(1 \| p \| site)` |
| `mc-0114` | 0.40 | `[0.677, 1.642]` | **69.2%** | `sd:mu:sigma2:spatial(1 \| ps \| site)` |
| `mc-0494` | 0.20 | `[0.305, 0.528]` | **52.7%** | `sd:mu:spatial(0 + x \| id)` (student) |
| `mc-0113` | 0.45 | `[0.547, 1.348]` | **21.6%** | `sd:mu:sigma1:spatial(1 \| ps \| site)` |

**All seven involve the `spatial` provider**, and the mechanism in §3.2 accounts for every one. No
failure is left unexplained.

### 3.1 The correction: `mc-0248` was my error, and it is a lesson about joining truth

`mc-0248` was first reported as a 99% failure. It is not. The cell carries **two** targets:

| target | truth | `execution_authority` |
| --- | ---: | --- |
| `mc-0248::sd:mu:relmat(1 \| id)` — intercept | **0.50** | **TRUE** |
| `mc-0248::sd:mu:relmat(0 + x \| id)` — slope | 0.20 | FALSE |

Its own `claim_boundary` says the second is excluded: *"The sibling
`mc-0248::sd:mu:relmat(0 + x | id)` remains profile_failed and point-fit only."* My first pass joined
truth to interval **by cell**, falling back to the cell's single retained interval when the target IDs
did not match — so it tested the claimed intercept's interval against the *excluded slope's* truth.
Against the target actually claimed, `[0.398, 0.664]` contains 0.50 and the cell **PASSES**.

**The lesson, which applies to every future re-check:** a cell is not the unit of a location check —
a **target** is. Cells can carry several targets, and a claim may deliberately cover only some of
them. Truth must be joined on exact `target_id`, and a non-matching target must be reported as
*unmatched*, never silently substituted. Only two of the 85 cells carry more than one truth target
(`mc-0248`, `mc-0494`), so the blast radius was small — but the failure mode was silent, which is
precisely the class of defect this arc exists to find. It is also a caution about the arc's own
instrument: the first pass produced a confident, specific, wrong number.

`mc-0494` is the other two-target cell and its claim **does** cover both (*"its two exact direct
Student spatial mu SD targets"*), so its miss stands.

### 3.2 The spatial mechanism: the fixture's declared truth is not the model's estimand

In the q4 adapter (`lane_b_q4_provider_fixture`, recovered from `3672ce757`) the DGP builds latent
effects from

```
K <- outer(i, j, function(i,j) 0.25^abs(i-j));  diag(K) <- diag(K) + 0.35
effects <- t(chol(K)) %*% rnorm(...) %*% diag(c(.55,.50,.40,.35))
```

For the **animal** and **relmat** arms the model is then handed `Ainv = Q = solve(K)` — the *same*
matrix. Those arms match the DGP exactly, and they **pass**.

For the **spatial** arm the model is handed only `coords = (x = 1:60, y = sqrt(1:60))` and builds its
own correlation (`drm_spatial_coords_precision`, `R/drmTMB.R:13395-13405`):

```
range <- median(positive pairwise distances)      # = 18.07 for these coords
cov   <- exp(-distance / range)
```

The two structures are not close:

| lag | DGP `K` | model covariance |
| ---: | ---: | ---: |
| 1 | 0.250 | **0.942** |
| 3 | 0.016 | 0.839 |
| 10 | 0.000 | 0.567 |

The DGP's correlation length is under one site; the model's is about twenty — a **~30× mismatch**.
A near-constant field cannot reproduce site-to-site variation without inflating its SD, which is
precisely the 3–4× inflation observed. (The nugget contributes a little: the DGP's marginal SD is
`sqrt(1.35) × 0.55 = 0.639`, still far below the fitted ~2.16.)

**So these intervals are not demonstrably mislocated. There is no valid truth for them to bracket** —
the parameter the contract declares is not the parameter the model estimates. This is a **fixture
defect**, not a defect in drmTMB's profile machinery. The correct disposition is the same either way:
*the `interval_feasible` claim is not currently supported*, because no location check can be
constructed for the cell as it stands.

Every one of the seven failures is accounted for by this mechanism. `mc-0248`, previously listed as an
eighth and unexplained failure, was a join error on my part and passes on its claimed target (§3.1).

## 4. Every verdict here is magnitude-only — what that does and does not mean

The gate fails a cell when either arm fires (`tools/profile_truth_gate.py:210-225`):
`worst_relative_miss > MISS_MAGNITUDE_TOL` (0.05), **or** `len(misses) > MISS_COUNT_TOL` (1).

**At one retained seed the count arm is structurally unreachable**: the maximum possible miss count is
1, and `1 > 1` is False. 110 of the 116 carry one seed or none, so only the magnitude arm can decide
them. A **PASS** here therefore means *this cell's single retained interval did not miss truth by more
than 5% of scale*. It does **not** mean the interval achieves nominal coverage, and it is weaker than
the 3–5-seed standard the gate was calibrated for. Only 6 cells (`mc-0282`, `mc-0568`, `mc-0576`,
`mc-0595`, `mc-0596`, `mc-0653`) carry 5 seeds.

The gate's outputs are **screening statistics**. Arc 7b's own per-cell p-values were 0.017–0.039 and
none survived multiplicity correction. No cell here is described as *proven mislocated*.

## 5. What this re-check did NOT cover

- **31 of the 116 have no recovered truth and therefore no verdict.** Their contracts either carry no
  numeric `true_parameter_scale` or were not found across refs.
- **The 73 re-run cells are untouched** — no compute was authorized or spent.
- **`mc-0248` needed a correction, not a partition** — see §3.1. Its excluded slope target
  (`sd:mu:relmat(0 + x | id)`, truth 0.20) has no receipt at all and therefore still has **no verdict**.
- **No ledger row was changed.** These are verdicts, not demotions; the tier edits are a separate,
  reviewable step.
- **The 78 passes were not re-derived from the fixture code** cell-by-cell. Truth came from the frozen
  contract, which for the q4 cohort was *shown* to agree with adapter code; that agreement was not
  re-established for every campaign.
- **A provenance risk this exposes:** 96 of 116 cells rest on receipts whose producing runner is not on
  `origin/main`, and 100 of 101 campaign contracts are likewise off-mainline. The evidence is real and
  recoverable, but it is not reproducible from a clean checkout of the mainline.

## 6. Reproduce

```bash
python3 -B tools/tests/test_profile_truth_gate.py     # 24/24 OK — unchanged by this arc
python3 tools/capability_ledger.py --check            # OK (31 generated outputs)
```

Machine-readable outputs: `scratchpad/recovered-truth.json`, `scratchpad/recheck-verdicts.json`,
`scratchpad/recheck-runners.json`.
