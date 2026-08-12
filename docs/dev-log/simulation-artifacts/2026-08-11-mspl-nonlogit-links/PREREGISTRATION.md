# G1 — TMB-Laplace finiteness for MSPL, probit and cloglog

**FROZEN-PENDING-PROBE. Written 2026-08-11, before any replicate.** Sibling to
`docs/dev-log/simulation-artifacts/2026-08-10-mspl-laplace-finiteness/PREREGISTRATION.md` (F1), whose
structure, endpoint definitions, and grading language this document reuses wherever the two questions
coincide. Slice S2 of the `mspl-nonlogit-evidence` campaign. Slice S3, the separation-depth calibration
probe named throughout, must run and be recorded **before** the grid below is finalized and any
replicate of it is drawn — see §4.

## 1. The question, and why it is owed

**G1:** does drmTMB's MSPL estimator, under TMB-Laplace, return finite interior estimates with finite
positive fixed information for the **probit** and **cloglog** links, in designs where plain ML
diverges or fails?

This is **not** a re-proof of existence. Kosmidis & Firth (2021, *Biometrika* 108(1), 71–82) prove, in
Theorem 1 together with §3.1 and Table 1, that for **any** link whose working weight
`ω(η) = g(η)²/[G(η){1−G(η)}]` vanishes as `η` diverges to either `±∞`, the Jeffreys-penalized fixed
effects have finite components, provided only that `X` is full rank. Logit, probit and cloglog are
named explicitly. Design doc `docs/design/253-mspl-nonlogit-links-derivation.md`, Addendum 2, confirms
this reading against the source text and reverses an earlier (wrong) demotion of the condition to
"AGENT-INFERRED." **The theorem is settled and this campaign does not touch it.**

What is **not** settled is whether drmTMB's specific implementation — TMB automatic differentiation,
the Laplace approximation to the random-effects integral, the composite MSPL objective assembled in
`src/drmTMB.cpp` and `R/mspl.R` — reproduces that guarantee numerically for probit and cloglog. F1
established this for **logit**: Sterzinger & Kosmidis (2023, p. 6) state only that they "encountered no
evidence" against Laplace finiteness, and that evidence was obtained on **lme4/glmer**, not TMB. F1
supplied drmTMB's own logit evidence for the route already shipped. **G1 extends exactly that
question — an implementation/numerical one — to the two links doc 253 proved but drmTMB has never
fitted under MSPL.** Addendum 2's closing line states the target directly: *"composite MSPL existence,
Laplace: NUMERICAL EVIDENCE ONLY... and that evidence is glmer's."* G1 replaces "glmer's" with
"drmTMB's," for probit and cloglog, the same way F1 replaced it for logit.

## 2. What a PASS on G1 does NOT license

Stated once, plainly, so it cannot be read into later:

- **Does not open the MSPL guard.** `R/mspl-estimator.R:179-184` continues to reject non-logit links
  after this campaign, regardless of outcome. Opening the guard is a separate, later decision that also
  needs the softness-scaling question below resolved.
- **Does not authorise shipping probit or cloglog under `estimator = "mspl"`.** A finiteness PASS is
  necessary evidence toward that decision, not sufficient. Doc 253 Addendum 3 records that the
  softness constant `c_n = 2√(p/n)` is a **logit-specific** delta-method result (2023 §7): logit has
  `ω(0) = 1/4` giving `c = 2√(p/n)`, while probit's `ω(0) = 2/π ≈ 0.6366` gives a different constant by
  the same argument, and cloglog's `ω(0)` at its interior maximum (`≈ 0.5820`, doc 253 §2) differs
  again. drmTMB's shipped `c_n` formula does not vary by link. G1 tests whether the estimator stays
  finite **using that as-shipped, possibly-miscalibrated `c_n`** — it says nothing about whether that
  `c_n` gives the asymptotically correct softness for probit or cloglog.
- **Says nothing about intervals or standard errors.** Kosmidis & Firth (2021, §2.1, p. 75) prove Wald
  intervals fail to cover under separation regardless of nominal level, a result doc 253 Addendum 2 §6
  confirms is link-general. Finiteness of a point estimate and its information matrix is not licence
  for inference on either.
- **Is not a proof.** It is numerical evidence on a frozen grid, exactly the same *kind* of evidence
  Sterzinger & Kosmidis offer for logit-on-glmer, produced instead for drmTMB.

## 3. Design requirements this document must satisfy, and why (doc 253 §4)

Four requirements are carried over from doc 253's original grid sketch and the halted E1 probe
(`docs/dev-log/simulation-artifacts/2026-08-09-mspl-nonlogit-finiteness/INSTRUMENT-FINDING.md`), and
are non-negotiable in the grid below:

**(a) Three links, one of them a control.** Logit is included **as control**: on the cells it shares
with F1, it must reproduce F1's PASS. A logit failure under this new harness means the harness is
wrong, exactly as F1 §6 required for its own ML control and as the E1 probe's halted logit control
demanded — no probit or cloglog number from a run with a failing logit control may be interpreted.

**(b) Cloglog needs both orientations.** Cloglog's working weight is asymmetric in its tails
(doc 253 §2: `ω = Θ(e^(2η−e^η))` as `η→+∞` against `ω = Θ(e^η)` as `η→−∞`, the two rates genuinely
different, unlike logit and probit which are both symmetric under `h(−η) = 1 − h(η)`). Fitting only the
data as generated exercises one tail's decay rate; fitting the response mirrored as `y ↦ m − y`
(Bernoulli here, so `y* = 1 − y`) exercises the other, without changing the link. Doc 253 §4 calls both
orientations "mandatory... because cloglog is asymmetric," and this is why logit and probit are each
tested in **one** orientation only: mirroring a symmetric link's response is a relabelling of `β`, not
new evidence.

**(c) An adversarial corner is required, not optional.** `c_n = 2√(p/n_eff)` is smallest, and the
Jeffreys penalty weakest relative to the likelihood, when `n_eff` is large and `p` is small — the
regime where separation still bites hardest against the least protection. The grid must include at
least one design point per link/orientation with `c_n ≲ 0.05`.

**(d) Separation depth is calibrated, not assumed, per link.** `ω(0)` differs across links — logit
`1/4`, probit `2/π ≈ 0.6366`, cloglog `≈ 0.5820` at its interior maximum (doc 253 §2) — so the same
`η_d` grid that drives logit to `ML SE > 10³` in F1 is not guaranteed to drive probit or cloglog into
the same regime. Reusing F1's `η_d` values unchecked for probit/cloglog would risk a repeat of F1 §6's
own warning in reverse: a control that silently fails to separate, producing a vacuous PASS ("MSPL
returned something finite" when ML would have too). §4 below states exactly what a companion probe
(slice S3) is and is not permitted to change about this grid before the first replicate.

**(e) A genuine control condition.** Every cell nominated "deep separation" must independently show ML
divergence or failure, on the same 50%-of-replicates threshold F1 §6 used, or the cell — and the
harness — is void for that link.

## 4. Two-stage structure: S3 calibrates, then G1's grid runs — the exact boundary

F1's `η_d ∈ {0, −2, −4, −6, −10}` grid was tuned, empirically, to drive logit's `ML |SE|` past `10³`
or to outright failure by `η_d = −6` (F1 §6 pre-run test: `SE = 105,561.57` at `η_d = −10`, q1). There
is no equivalent empirical basis yet for probit or cloglog. Rather than assume F1's values transfer —
which requirement (d) above rules out — a **small, separate calibration probe, slice S3, runs first**
and hands this grid the `η_d` values it needs. S3 is not specified in full here (it is its own
prereg-scale artefact); what follows is the precise boundary of what it may and may not change.

**S3 is permitted to set, before the first G1 replicate is drawn:**

1. The `η_d` grid values used for **probit**, **cloglog-standard**, and **cloglog-mirrored** — chosen so
   that each link's deepest cell independently satisfies the same control condition F1 used (`ML |SE| >
   10³` or fit failure, in ≥ 50% of a small calibration batch), rather than inheriting F1's logit-tuned
   values unchecked.
2. Whether cloglog's two orientations need **different** `η_d` grids from each other, given their
   different tail decay rates (§3b above). S3 may return one shared grid or two link-orientation-
   specific grids for cloglog; either is admissible provided each independently satisfies the control
   condition.
3. Which two of each link's calibrated `η_d` values are used inside the adversarial-corner cells (§5.3)
   — S3's output values only, never a value S3 did not calibrate.

**S3 may NOT change, regardless of what it finds:**

- The DGP structural forms (`q1`, `q2`), reused verbatim from F1 §4 and extended only by `link=` and,
  for cloglog-mirrored, the response relabelling `y* = m − y` (§5.1).
- `G ∈ {12, 30}` and `n_per = 10` for the main grid, and the adversarial-corner design point
  `G = 400, n_per = 10` (§5.3) — these are fixed by the design, not by numerics.
- `σ_u = 0.7` (intercept), `σ_u1 = 0.4` (slope, q2 only), `β_trt = β_x = 1.0` — identical to F1.
- The **number** of `η_d` grid points per link (5, matching F1's count), even though their **values**
  for probit/cloglog are S3's to set.
- The set of links/orientations tested: exactly `{logit-control, probit, cloglog-standard,
  cloglog-mirrored}` — no fewer, no more.
- Replicates per cell (500, §5.4) and the seed-generation recipe (§5.4).
- The primary and secondary endpoints, their thresholds, and the decision rule (§6) — identical to F1
  §5, unchanged.
- The control rule and its harness-invalidation consequence (§7) — identical in structure to F1 §6.
- The abort/stopping rules (§8).

If S3 cannot find, for some link, any `η_d` in a reasonable range that drives ML into the control
regime, **that is itself a finding to report, not a licence to relax the control threshold** — see §7.

## 5. The grid, frozen except where §4 names S3's authority

### 5.1 DGP (identical to F1 §4, extended by link and, for cloglog, response orientation)

- `q1`: `y ~ trt + (1 | block)`, `u ~ N(0, 0.7²)`, `β_trt = 1.0`, target `trt`.
- `q2`: `y ~ x + (1 + x | block)`, `u0 ~ N(0, 0.7²)`, `u1 ~ N(0, 0.4²)`, `β_x = 1.0`, target `x`.
- `n_per = 10` (main grid); `block` factor with `G` levels.
- Response: `y = rbinom(N, 1, h(η_d + β·covariate + u[block]))` with `h = g⁻¹` for the cell's link
  (`plogis`, `pnorm`, or `1 − exp(−exp(η))` for cloglog).
- **Cloglog-mirrored orientation:** fit the SAME simulated `y` relabelled as `y* = 1 − y` (Bernoulli,
  `m = 1`), under the SAME cloglog link. This is a response relabelling, not a link change or a new
  DGP — it is exactly doc 253 §4's `y ↦ m − y` requirement.
- Logit and probit are each fitted in one orientation only (§3b).

### 5.2 Main grid

`link/orientation ∈ {logit-control, probit, cloglog-standard, cloglog-mirrored}` ×
`q ∈ {q1, q2}` × `η_d` (5 values per link/orientation, S3-set for the three non-logit conditions,
F1's `{0, −2, −4, −6, −10}` reused verbatim for logit) × `G ∈ {12, 30}`
= **4 × 2 × 5 × 2 = 80 cells.**

The 20 logit-control cells are the exact 20 cells of F1 §4 (same `q × η_d × G`), re-fit under this
campaign's own seeds (§5.4) as a harness-reproduction check, not merely cited from F1's run.

### 5.3 Adversarial-corner cells (requirement c)

`c_n = 2√(p/n_eff)` is a deterministic function of `(p, n_eff)`, so hitting a target `c_n` needs no
calibration — only arithmetic. For `q1` (`p = 2`, intercept + `trt`), `n_eff = G × n_per`. Choosing
`G = 400, n_per = 10` gives `n_eff = 4000` and `c_n = 2√(2/4000) ≈ 0.0447 ≤ 0.05`, satisfying
requirement (c) with margin. The corner uses `q1` only — the question here is the size of `c_n`, not
random-slope structure, which the main grid already exercises at `q2`.

`link/orientation ∈ {logit-control, probit, cloglog-standard, cloglog-mirrored}` × the **two deepest**
`η_d` values from that link/orientation's calibrated grid (§4, point 3) × `G = 400, n_per = 10` fixed
= **4 × 2 = 8 cells.**

### 5.4 Replicates and seeds

**500 replicates per cell**, matching F1 — needed to resolve the same Clopper–Pearson lower-bound
threshold (§6) at comparable precision. Engines: `mspl` and `ml` (control), as in F1.

**Total: 80 + 8 = 88 cells × 500 replicates × 2 engines = 88,000 fits.**

**Seeds, frozen:** `seed = 20260811 + 100000 * cell + rep`, `cell` a single running index over the full
88-cell table (main grid cells 1–80 in `link × q × η_d × G` order, corner cells 81–88), `rep ∈ 1..500`.
The date prefix (`20260811`) deliberately differs from F1's (`20260810`) so no seed collides with an F1
seed even though several DGP cells are numerically identical to F1's.

## 6. Primary endpoint and decision rule — declared before any replicate

Identical to F1 §5, per MSPL fit, from `fit$mspl`:

| id | quantity |
|---|---|
| E1 | `fixed_information_finite_positive` is `TRUE` |
| E2 | `final_logdet_fixed_information` is finite |
| E3 | `is.finite(β̂)` |
| E4 | `numerical$hessian_positive_definite` |
| E5 | `opt$convergence == 0` |

**FINITENESS HOLDS in a cell** iff `E1 ∧ E2 ∧ E3` in **≥ 99%** of its 500 replicates, with the lower
bound of a 95% Clopper–Pearson interval also **≥ 0.97**. E4 and E5 are reported but **not** gating, for
the same reason F1 gave: a non-PD Hessian or a slow optimizer is a different failure from a divergent
estimate.

**NA HANDLING, declared now, identical to F1:** a missing or non-finite
`final_logdet_fixed_information` counts as a **FAILURE of E2**, never a dropped row. Every replicate is
scored or the cell is void.

**SECONDARY (reported, not gating):** median `final_logdet_fixed_information` should decline
monotonically as `η_d` decreases within each `(link/orientation, q, G)` stratum, exactly as F1 §5
reported for logit — the coercivity signature, evaluated at the fitted optimum where it stays finite,
not along the escape ray where E1's harness could not evaluate it (INSTRUMENT-FINDING.md).

**The claim G1 licenses on a PASS**, stated in F1's form: *on the frozen grid, drmTMB's MSPL estimator
under TMB-Laplace and the [probit / cloglog-standard / cloglog-mirrored] condition returned a finite
interior estimate with finite, positive fixed information in N of N fits, including every cell where
maximum likelihood diverged or failed* — graded and reported **per link/orientation**, not pooled,
because a probit PASS is not evidence for cloglog and vice versa (doc 253 §3: "clearing probit is NOT
evidence for cloglog. They fail differently and must be evidenced separately").

## 7. Control, and what falsifies the harness

In every cell designated "deep separation" for its link/orientation (the two deepest S3-calibrated
`η_d` values, or F1's `η_d ∈ {−6, −10}` for logit), ML must show divergence (`|SE| > 10³`) or a failed
fit in **≥ 50%** of replicates — identical threshold to F1 §6.

**If ML is finite and well-behaved everywhere for a given link/orientation, that link/orientation's
DGP is not separating and the harness is wrong for it.** No MSPL result from that link/orientation may
be interpreted, exactly as F1 §6 required and exactly what halted the E1 probe's logit control
(INSTRUMENT-FINDING.md). This is graded **per link/orientation**: a logit-control failure voids only
logit (and, per §3a, the whole run, since logit not reproducing F1 means the harness itself changed);
a probit-only control failure voids probit but not cloglog, unless S3 could not calibrate a separating
`η_d` for probit at all, in which case that is reported as a finding (§4, closing paragraph), not
silently patched.

Also void, for a given link/orientation, if the median event rate is neither near-0 nor near-1 in that
link's deepest-cell replicate set, since separation would not have been produced (same check F1 §6
used, generalized across links since the achievable extreme event rate differs by link's tail shape).

## 8. Stopping and abort rules (identical structure to F1 §7)

1. **S3 first, in full, before any G1 replicate.** §4 is the exact contract; S3's output `η_d` values
   must be recorded in this artefact directory before cell 1 of the grid is drawn.
2. **Smoke second.** One cell per link/orientation (4 cells), 3 replicates each, on Totoro, with one
   fit per link/orientation inspected past its guards, before the full grid. Non-empty, non-NA,
   in-range output required. Watch specifically for the stale-build failure mode F1 §7 and the E1 probe
   both hit (*"`drmTMB()` does not use arguments in `...` yet"*), and for un-exported internals used
   directly (`INSTRUMENT-FINDING.md` bug 1) — this runner, like F1's, must use only exported
   `drmTMB()`/`coef()`/`vcov()` and the `fit$mspl` field, never `drmTMB:::`.
3. **Read cell 1 of each link/orientation early.** Abort that link/orientation's remaining cells the
   moment its first cell's output is empty, all-NA, or malformed. Do not wait for the full grid.
4. **Time one fit at the adversarial-corner size before committing the full run.** `G = 400` is 13×
   F1's largest `G = 30`; report the single-fit wall-clock time and the projected total before running
   all 8 corner cells, per the standing discipline that a large-`n` fit must be timed once and
   extrapolated, not assumed proportional.
5. **Overrun stops.** State the extrapolated total wall-clock time before running the full 88,000-fit
   grid; if the actual run exceeds that estimate, stop and re-report rather than continuing quietly
   (D-139).
6. **No post-hoc rescoring.** If any rule above proves unevaluable as written, halt and revise the
   criterion in the open, exactly as the E1 probe was required to and exactly as F1 §7 restates.
   Rescoring after seeing output is the error this document exists to prevent.

## 9. Provenance

Record per run: `source_sha`, `runner_sha256`, `git_blob` of the runner, the S3 calibration output
(its own `η_d` table, saved alongside this file), R and drmTMB versions, Totoro hostname, core count,
UTC start/finish, and the exact command. The package must be rebuilt on Totoro from the campaign SHA —
a local fix does not reach the cluster (F1 §8; also the specific failure mode both F1's pre-run test
and the E1 probe hit).
