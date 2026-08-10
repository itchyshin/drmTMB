# Session Handoff: overnight MSPL evidence run — what landed, what was HALTED

Meta: 2026-08-09 evening → 2026-08-10. Autonomous run while Shinichi was away.
**Cite by branch + SHA, never by path.**

## Read this first

Two campaigns were run on Totoro tonight. **One produced a result. One was deliberately stopped
before it could produce a misleading one.** The stop is the more important item.

| Lane | Branch @ SHA | State |
|---|---|---|
| Arc D (probit/cloglog) | `claude/binomial-link-generalisation` | **PR [#973](https://github.com/itchyshin/drmTMB/pull/973) open**, merge conflict with main RESOLVED, gates re-running on the merged tree |
| MSPL evidence | `claude/mspl-binomial-inference-promotion` @ `fd1eef46f` | pushed, no PR (yours to call) |

## 1. SE-calibration campaign — RESULT, with a retraction

60,000 fits (15 cells × 1000 reps × 4 engines), pre-registered before any replicate.

**What it licenses:** *MSPL standard errors are calibrated in the identified regime* —
`R = mean(SE)/sd(β̂) ∈ [0.93, 1.05]`, bootstrap MCSE ≈ 0.02. Logit only, tested grid only.

**The first headline was WRONG and is retracted in `VERDICT.md`.** It read "zero anti-conservative
failures; deep separation is conservative, therefore harmless." Both halves failed:

- **"Conservative" was estimator COLLAPSE.** At `η_d = −10, G = 12`, **996/1000 MSPL estimates take
  essentially the same value — two distinct values across a thousand replicates.** `sd(β̂)` then
  measures atom-hopping, not sampling variability, so `R = 28.5` is a degeneracy signal. The tell
  was already printed beside the headline: `R_mad = Inf` means the median absolute deviation is zero.
- **A cell was silently dropped**, violating the campaign's own §8 rule 5. Cell 15 reports
  `ok = TRUE` on all 1000 replicates with a finite SE on only **17**.
- **Engine comparison was not paired**, so "ML reached 95,220" is not like-for-like.

Caught by Fisher's adversarial review, verified against raw replicates, then re-analysed paired with
degeneracy flags and a bootstrap MCSE (`analyse2.R`).

**The re-analysis found the real structure:** every degenerate cell is **q1**; **no q2 cell
degenerates**. So `R = 2.04` at `q2, η_d = −6` is a *genuine* conservative result while `R = 2.81`
at the comparable q1 cell is collapse. Also: **cell 2 is `R = 0.933 ± 0.026`, below the PASS floor
on the ANTI-conservative side** — BORDERLINE, not FAIL, but never highlighted by the first pass.

**Issue [#977](https://github.com/itchyshin/drmTMB/issues/977) opened:** MSPL returns
`convergence = 0` with an `NA` standard error in 98% of the worst cell.

## 2. Non-logit MSPL — derived, then the probe was HALTED

**`docs/design/253-mspl-nonlogit-links-derivation.md`** (Noether) supplies the justification design
252 §7 asserted but never showed, and **agrees with the existing guard**:

- The **fixed-effect** half extends to probit and cloglog: `w(η) → 0` in both tails, so
  `det XᵀWX → 0` along every ray. Asymmetry breaks nothing.
- The gap is the **mixed-effects** half, and it is **coercivity, not boundedness**. Logit is exactly
  the case `κ₁ = κ₀ = h(1−h)`, which makes the Laplace Hessian `y`-free, built from the *same* `w` as
  the Jeffreys term, and parameter-free-sandwichable — three things at once. For probit/cloglog the
  bounds split.
- **Cloglog is the harder case** (`κ₀ = e^η` unbounded, no sandwich). **Probit keeps one with
  `C = 1`.** *Clearing probit is NOT evidence for cloglog.*
- **Most consequential open item, and NOT about new links:** UNVERIFIED whether the source theorem
  concerns the exact marginal or the Laplace criterion. `src/drmTMB.cpp:5019` penalises the Laplace
  `nll`. **That is a live question for the SHIPPED LOGIT ROUTE.**

**The E1 probe was pre-registered, built, smoked — and HALTED before grading.** See
`INSTRUMENT-FINDING.md`. The logit control failed, which by the prereg's own rule means the harness
is wrong. Inspecting a ray showed worse: **the frozen rule cannot be evaluated as written.** The
objective descends decisively (Jeffreys bonus +0.83 → −5.24, likelihood −Inf by `t = 20`), but past
`t ≈ 10³` every weight underflows and `det XᵀWX` reports rank-deficiency — the numerical image of
the §2 condition, with no *number* left to test monotonicity against.

**Rescoring that as "descent" would flip every fixture FAIL → PASS.** That is a post-hoc
reinterpretation, forbidden by §6 rule 6, and it is the identical error the SE campaign made hours
earlier. It may well be correct — it is not mine to make after seeing the output. **The criterion
goes back to Noether for revision.**

## 3. A defect fixed in this arc's own work

`mspl_penalty_components()` took **no `link` argument** and silently used the logit default, so the
composite reference stayed logit-only after the leaves were made link-general. Fixed with a
regression test whose load-bearing assertion is **negative** — the composite must *change* with the
link. Same failure mode as the morning's `link_code` incident: **the caller named nothing about
links, so no search for "link" would have found it.**

## Owed / next

1. **Confirm the post-merge gate** on `claude/binomial-link-generalisation` (running at handover).
   Main moved 5 commits during the session; `NEWS.md` conflicted and was resolved keeping **both**
   sections. Julia suites re-verified green after the merge.
2. **Merge #973** — your call; gates were green pre-merge and are re-running post-merge.
3. **Revise the E1 criterion** (Noether) — three specific changes named in `INSTRUMENT-FINDING.md`.
4. **Noether's intermediate (D)**, not yet started: expose `P_f`, `c_n`, `log det XᵀWX` as *reported
   diagnostics* under `estimator = "ml"` — never in the objective. Deliberately left for a waking
   decision because it adds public surface.
5. **The MSPL PR** — unchanged, yours.

## Do NOT

- Do not open the MSPL guard. Doc 253 says NEEDS EVIDENCE and no valid evidence exists yet.
- Do not quote the retracted "conservative/harmless" reading, or the unpaired engine ratios, or the
  first-pass MCSE.
- Do not treat gllvmTMB PR #952 as having solved this: it admits all three links behind a
  point-estimation fence and records that **its own all-link campaign is still outstanding.**

## Environment

```sh
cd /Users/z3437171/local-scratch/worktrees/drmTMB-links          # Arc D
cd /Users/z3437171/local-scratch/worktrees/drmTMB-mspl-inference # MSPL
# Totoro: ~/drmtmb_se_cal  (built package in ~/R/lib; rebuild after ANY local R/ change)
```

**Totoro gotcha, paid for twice tonight:** an *installed* package hides internals (`drmTMB:::`
needed, unlike `load_all()`), and local fixes do not reach the cluster — redeploy and rebuild.
