# F1 — TMB-Laplace finiteness for MSPL, logit

**Frozen 2026-08-10, before any replicate.** Owner-approved: Totoro, logit-only, logdet endpoint.

## 1. The question, and why it is owed

Sterzinger & Kosmidis (2023) prove MSPL composite existence for the **exact** likelihood and for
vanilla non-adaptive Gauss–Hermite quadrature. For **Laplace** they state only that "we encountered
no evidence that this weaker condition does not hold" — numerical evidence, **obtained on
lme4/glmer** (2023, p. 6).

drmTMB is TMB-Laplace. So the finiteness guarantee behind the estimator **we already ship, under
logit**, is somebody else's numerical evidence on a different implementation. Design doc 253 §2
records this as a live gap for the shipped logit route, not merely for probit/cloglog.

This campaign supplies drmTMB's own evidence for **logit**.

## 2. What this campaign does NOT claim

- **Not a proof.** It is numerical evidence on a frozen grid, exactly the same *kind* of evidence
  the authors offer, on our implementation instead of theirs.
- **Nothing about probit or cloglog.** The MSPL entry point stays logit-only, for two independent
  documented reasons (design 253): `c = 2√(p/n)` is the wrong constant for those links, and there
  is no drmTMB evidence for non-logit `W`. No cell here opens that guard.
- **Not an interval or coverage claim.** Kosmidis & Firth warn Wald CIs "will fail to cover
  regardless of the nominal level", even profiled. Finiteness is not licence for inference.
- **No ledger cell, census, promotion, or release rung moves.**

## 3. Why the endpoint is measured at the optimum, not along a ray

The E1 probe (2026-08-09) tried to establish coercivity by walking escape rays to `t = 10⁴`. It was
**halted before grading**: past `t ≈ 10³` every working weight underflows, `det XᵀWX` underflows to
`rank_deficient_information`, and **no number exists at those `t` to test monotonicity against**.
Its frozen threshold ("drop < −50 nats") also presumed a finite objective, while the likelihood is
`−Inf` from `t = 20`.

drmTMB already computes the same quantity **at the fitted optimum**, where it stays finite. Measured
in the pre-run test (q1, G=12, seed 424242):

| `η_d` | `final_logdet_fixed_information` | `fixed_information_finite_positive` | `objective_identity_error` |
|---|---|---|---|
| 0 | +5.3195 | TRUE | −6.25e−13 |
| −6 | −2.3985 | TRUE | 2.66e−15 |
| −10 | −4.5071 | TRUE | −6.66e−16 |

The monotone decline is the finite-precision image of `det XᵀWX → 0` — the condition E1 was
chasing — evaluated where it is computable. **This is the design repair.**

## 4. The frozen grid

`q ∈ {q1, q2}` × `η_d ∈ {0, −2, −4, −6, −10}` × `G ∈ {12, 30}` = **20 cells**.
`n_per = 10`. Engines: `mspl` and `ml` (control). **500 replicates per cell** ⇒ 20,000 fits.

DGP, identical to the 2026-08-09 SE-calibration campaign (proven on Totoro):

- `q1`: `y ~ trt + (1 | block)`, `u ~ N(0, 0.7²)`, `β_trt = 1.0`, target `trt`
- `q2`: `y ~ x + (1 + x | block)`, `u0 ~ N(0, 0.7²)`, `u1 ~ N(0, 0.4²)`, `β_x = 1.0`, target `x`

**Seeds, frozen:** `seed = 20260810 + 100000 * cell + rep`, `rep ∈ 1..500`.

## 5. Primary endpoint and decision rule — declared before any replicate

Per MSPL fit, from `fit$mspl`:

| id | quantity |
|---|---|
| E1 | `fixed_information_finite_positive` is `TRUE` |
| E2 | `final_logdet_fixed_information` is finite |
| E3 | `is.finite(β̂)` |
| E4 | `numerical$hessian_positive_definite` |
| E5 | `opt$convergence == 0` |

**FINITENESS HOLDS in a cell** iff `E1 ∧ E2 ∧ E3` in **≥ 99%** of its 500 replicates, with the
lower bound of a 95% Clopper–Pearson interval also **≥ 0.97**. E4 and E5 are reported but are **not**
gating: a non-PD Hessian or a slow optimizer is not the same failure as a divergent estimate, and
conflating them is how the SE campaign's first pass went wrong.

**NA HANDLING, declared now:** a missing or non-finite `final_logdet_fixed_information` counts as a
**FAILURE of E2**, never as a dropped row. E1's first scorer used `is.finite()` to filter, which
removed precisely the values that constituted the evidence. Every replicate is scored or the cell is
void.

**SECONDARY (reported, not gating):** median `final_logdet_fixed_information` should decline
monotonically as `η_d` decreases within each `(q, G)` stratum — the coercivity signature.

## 6. Control, and what falsifies the harness

In every cell with `η_d ≤ −6`, ML must show divergence — `|SE| > 10³`, or a failed fit — in **≥ 50%**
of replicates. Pre-run test at `η_d = −10`: ML `SE = 105,561.57` (q1) and outright failure (q2),
against MSPL `SE = 3.95` and a finite estimate.

**If ML is finite and well-behaved everywhere, the DGP is not separating and the harness is wrong.**
Then no MSPL result from that run may be interpreted, exactly as E1's logit control failure meant.

Also void if the event rate is neither 0 nor 1 in any `η_d = −10` cell replicate-set median, since
separation would not have been produced.

## 7. Stopping and abort rules

1. **Smoke first.** One cell, 3 replicates, on Totoro, with one fit inspected past its guards, before
   the grid. Non-empty, non-NA, in-range output required. A stale Totoro build presents as
   *"`drmTMB()` does not use arguments in `...` yet"* — the pre-run test hit exactly this locally.
2. **Read cell 1 early.** Abort the moment the first cell's output is empty, all-NA, or malformed.
   Do not wait for the grid.
3. **Overrun stops.** Estimate is ~15 min wall-clock at 100 cores. If it exceeds **45 min**, stop and
   re-report rather than quietly continuing (D-139).
4. **No post-hoc rescoring.** If the rule proves unevaluable, **halt and revise the criterion in the
   open**, as E1 did. Rescoring after seeing output is the error this document exists to prevent.

## 8. Provenance

Record per run: `source_sha`, `runner_sha256`, `git_blob` of the runner, R and drmTMB versions,
Totoro hostname, core count, UTC start/finish, and the exact command. The package must be **rebuilt
on Totoro from the campaign SHA** — a local fix does not reach the cluster.
