# G3 — MSPL standard-error calibration for probit and cloglog

**FROZEN 2026-08-11, before any G3 replicate.** Extends the logit-only SE campaign of
`docs/dev-log/simulation-artifacts/2026-08-09-mspl-se-calibration/` to the two links G1/G1b showed
drmTMB can fit finitely. Reuses that campaign's design and decision bands verbatim where they
transfer, and **hard-codes its three corrections as advance design rather than hindsight**.

## 1. The question, and why it is the one that matters now

drmTMB ships **Wald standard errors** for MSPL fits (`vcov()`, `summary()`) and no intervals.
gllvmTMB blocks `vcov()` and `standard_errors()` under MSPL entirely, citing Kosmidis & Firth (2021)
that finiteness licenses neither. **Of the two designs ours is the more exposed**, and this is a
public-surface property of the route drmTMB **already ships** — not a future one.

The 2026-08-09 campaign answered it for **logit**: MSPL standard errors are calibrated in the
identified regime, `R = mean(SE)/sd(β̂) ∈ [0.93, 1.04]`. **Nothing is known for probit or cloglog.**
G1/G1b established that drmTMB returns finite estimates for those links; finiteness of a point
estimate and its information matrix is **not** licence for inference on either (KF2021 §2.1, p. 75:
Wald intervals fail to cover under separation regardless of nominal level). G3 measures whether the
standard errors those fits carry mean anything.

## 2. The three corrections from 2026-08-09, promoted to design

That campaign's first headline was retracted after adversarial review. Each failure becomes a rule here.

**(a) `R > 1` is NOT conservatism.** It was read as "conservative, therefore harmless." The raw
replicates showed **estimator collapse**: at `η_d = −10, G = 12`, 996 of 1000 MSPL estimates took
**two distinct values**. `sd(β̂)` there measures how often a replicate escapes its dominant atom, not
sampling variability, so `R` is not a calibration statistic at all.

> **DEGENERACY GUARD, declared now.** A cell is **DEGENERATE** if `R_mad` is infinite (median absolute
> deviation zero) **or** the number of distinct `β̂` values is `< 0.10 × n_retained`. A degenerate
> cell's `R` is reported but **carries no calibration verdict in either direction**, and `R > 1`
> there is recorded as a **degeneracy signal, never as a safety margin**.

**(b) No silent drops.** Cell 15 vanished from the prior summary because the analysis filtered on
`is.finite(se)` then skipped cells with `n < 50`. "Zero anti-conservative failures" was computed over
14 cells and presented as 15.

> **RETENTION IS AN ENDPOINT, not a filter.** Every cell appears in the output with its per-engine
> retention count, whatever that count is. A cell may be *unverdictable*; it may never be *absent*.

**(c) Comparisons must be paired (D-117).** The prior analysis computed each engine's `R` over its
own converged subset, so ML's retained replicates were a survivor subset.

> All cross-engine statements are computed on the **intersection** of replicates where every engine
> returned. Per-engine marginal figures may also be reported, but never compared across engines.

## 3. The new endpoint the prior campaign discovered by accident

At `q2, η_d = −10, G = 30`, MSPL reported `ok = TRUE` on 1000 of 1000 replicates while only **17**
carried a finite standard error. A user sees `convergence = 0` and an `NA` SE.

> **SE-AVAILABILITY is a primary endpoint here**, per cell and per link: the fraction of MSPL fits
> with `convergence == 0` whose `mu` slope SE is missing or non-finite. This is the quantity that
> most directly informs the ship-or-block decision in §1, because it describes what a user actually
> receives.

## 4. Design

Conditions: **logit (reference), probit, cloglog-standard, cloglog-mirrored** — the same four G1/G1b
graded, including both cloglog orientations, because cloglog's tail asymmetry is now measured rather
than assumed (`S3-CALIBRATION.md`).

| | q1 | q2 |
|---|---|---|
| formula | `y ~ trt + (1 \| block)` | `y ~ x + (1 + x \| block)` |
| `G` | {12, 30} | {30} |
| cells per condition | 10 | 5 |

**`η_d` is per-link, from `S3-CALIBRATION.md`** — logit `{0, −2, −4, −6, −10}`, probit
`{0, −1.2, −2.1, −3, −4.2}`, cloglog-standard `{0, −2, −3.5, −5, −7}`, cloglog-mirrored
`{0, −2.4, −4.2, −6, −8.4}`. **Transplanting logit's grid is specifically forbidden**: `pnorm(−10)`
is 7.6e−24 against `plogis(−10)` = 4.5e−5, and reusing it unchecked is the error S3 exists to prevent.

**Regime split, per link:** *identified* = that link's two shallowest `η_d`; *separated* = its three
deepest. This generalises the prior campaign's `η_d ∈ {0, −2}` split correctly across links rather
than by absolute value.

**60 cells × 1000 replicates × 3 engines = 180,000 fits.**

Engines: **drmTMB MSPL** (subject), **drmTMB ML** (paired reference), **`glmmTMB`** (sanity arm — also
TMB + Laplace, so it isolates implementation from method). `glmer` is dropped: its inner approximation
differs, its bound was already loose, and its retention was the worst of the four, which costs
intersection size under the pairing rule in §2(c). Dropping it narrows the sanity comparison and is
recorded as a deliberate design choice.

**Seeds:** `seed = 20260813 + 100000 * cell + rep`, a fresh stream distinct from F1/G1/G1b.

## 5. Decision rule — frozen, bands taken verbatim from 2026-08-09 §5

| regime | PASS | BORDERLINE | FAIL |
|---|---|---|---|
| identified | `R ∈ [0.95, 1.05]` | `[0.90, 1.10]` | outside |
| separated | `R ∈ [0.90, 1.15]` | `[0.80, 1.25]` | outside |

`R = mean(SE) / sd(β̂)` on retained, non-degenerate replicates for the `mu` slope target.

> **One anti-conservative FAIL fails the campaign for that link.** Not a majority, not an average.
> A single cell with `R` below its FAIL floor means MSPL standard errors are not calibrated in that
> regime, and that is the honest report.

**Asymmetry note, corrected from the prior campaign:** the separated band is wider on the upper side,
but a high `R` is only benign in a **non-degenerate** cell. In a degenerate cell it is meaningless
(§2a). The prior campaign's phrase "conservatism is harmless" is **retired** and must not be quoted.

**Paired-reference clause (D-117).** If MSPL under-calibrates, check ML and `glmmTMB` **on the same
replicates** before claiming a drmTMB defect. Imperfect calibration is the norm; famous packages
undercover too. If all engines under-calibrate together, that is a fact about the regime, not a
drmTMB defect, and must be reported as such.

## 6. Verdicts available per link

- **CALIBRATED (identified)** — all identified cells PASS or BORDERLINE, none FAIL.
- **NOT CALIBRATED** — ≥ 1 anti-conservative FAIL in an evaluable cell.
- **DEGENERATE-LIMITED** — calibration holds where evaluable, but ≥ 1 separated cell is degenerate and
  carries no verdict. **This is expected for the deep cells and is not a defect** — it is the honest
  description of an estimator that has collapsed onto atoms.

## 7. What G3 cannot do

It cannot license intervals. KF2021 §2.1 proves Wald intervals fail to cover under separation at any
nominal level, link-generally, and a calibrated `R` in the identified regime does not touch that.
It does not open the MSPL guard, and it does not settle `c_n` (that is G2, not run).

## 8. Stopping rules

Smoke one cell per condition before the grid, inspecting one fit past its guards. Read the first cell
of each condition early and abort that condition on empty/all-NA output. State the wall-clock estimate
before the run and stop-and-re-report on overrun (D-139). No post-hoc rescoring, and no cell removed
from the summary for any reason (§2b).
