# After Task: separation lane — finite disposition

Date: 2026-08-09 · Lane: complete/quasi-complete separation experiment ·
Branch: `codex/fixed-design-binary-separation-experiment` · Platform: Claude Code

## 0. Disposition

**DEFER — no demonstrated release-relevant drmTMB defect.**

This is the reviewed finite disposition the staged 0.7.0 candidate arc was waiting on. The
S0-A2 stop is resolved: its cause was a third-party linear-programming backend defect, confined
entirely to a private scratchpad harness. No drmTMB package code, test, document, or release
surface was implicated or changed.

**Lane 1's candidate freeze is not blocked by this lane.**

Reviews: Fisher `SUPPORTS-DEFER`; Grace `CLEAN-WITH-CAVEATS`. Both caveat sets are adopted below,
including the claim narrowing, which is binding on this receipt.

## 1. Goal

Take the separation experiment from a fail-closed STOP to one evidence-backed disposition —
MERGE validated package work, DEFER with no demonstrated release defect, or DEFECT repaired with
tests and review — without performing candidate-preparation work.

## 2. Implemented

An additive S0-A3 correction slice. The S0-A2 spike and result table are immutable Golden Set
artifacts and remain byte-identical.

The contract was frozen **before** any code was written
(`scratchpad/separation-s0a3-certificate-contract.md`). It replaces solver-status trust with
witnesses re-checked by direct arithmetic in R against the original constraint matrices:

- **feasible** requires a primal `β` satisfying every one of `Bβ ≥ −τ_B`, `|Eβ| ≤ τ_E`,
  `cᵀβ ≥ 1 − τ_c`;
- **infeasible_certified** requires a Farkas/Gordan dual witness `u ≥ 1`, `v` free with
  `Bᵀu + Eᵀv = 0`, verified as `max|Bᵀu + Eᵀv| ≤ τ_D` and `min(u) ≥ 1 − τ_u`;
- **unresolved** is everything else and fails the gate.

Tolerances were changed from a bare absolute `1e-8` to norm-relative quantities scaled to the
magnitudes actually entering each check, with the realised tolerance recorded beside each residual.

## 3a. Decisions and rejected alternatives

- **Did not "use a better solver."** A status code is not a proof. Both verdict directions are
  now re-derived arithmetically, so a backend fault can produce only `unresolved` — never a false
  verdict. This is the property that caught the original defect and it is retained deliberately.
- **Did not add a special-case branch for the degenerate normalisation.** Noether's review raised
  that a nonzero `β` with `Bβ = 0` would be a zero-margin separating direction invisible to
  `cᵀβ ≥ 1`. That case is *exactly rank deficiency*: since every row of `B` is `±` a row of `X`
  and every row of `E` is a row of `X`, `rank([B;E]) = rank(X)`, so full column rank forces
  `β = 0`. The existing full-rank pre-check is therefore the guard, and no new LP was added.
- **Recorded that the guard is a correctness condition, not a repair.** Measurement shows the
  zero-margin pathology is not triggered by any live fixture (§4), so claiming it "fixed" something
  would be false.
- **Did not rescore or relax any expected class.** §6 of the contract restates them unchanged.
- **Ran the exact-row controls.** They were `not_run_after_core_failure` in S0-A2 and unlock at
  `core_ok`. Running them is what makes a DEFER evidence-backed rather than merely unblocked. This
  was an explicit owner decision, since the prior slice had fenced them.
- **Pinned `lpSolveAPI`** in `required_versions` after Grace observed that the one dependency this
  slice exists to guard against was not version-gated.

## 4. Root causes — both open issues closed

**S0A2-001 — CLOSED.** For fixture `mu_overlap`, `colSums(B) = (0,0)`, so the harness's
normalisation row is the degenerate `0ᵀβ ≥ 1`. **lpSolveAPI silently drops all-zero constraint
rows**, so the problem actually solved was missing the only row that made it infeasible; it
returned status 0 (OPTIMAL) with `β = 0` and a constraint residual of 1. The formulation was
correct throughout; the backend was not. Now certified: `u = (1,1,1,1,1,1)`, `resid_D = 0`,
`min_u = 1`.

**S0A2-002 — CLOSED.** `type` is a formal of `brglm2::brglmControl()`, not `brglm2::brglmFit()`,
in brglm2 1.1.0. The call now passes `control = brglm2::brglmControl(type = "AS_mean")`. Ten
`RETAINED_FAILURE` rows became 25 `RECORDED` rows. The comparator remains non-gating.

**Neither issue is a drmTMB defect.** drmTMB is used in this harness only to produce a design
matrix and objective values.

**Degeneracy measurement** (`scratchpad/separation-s0a3-recon-inventory.md` §4). Of 13 fixtures,
exactly two have `max|colSums(B)| < 1e-8`: `mu_overlap` (full rank, so `Bβ = 0 ⟹ β = 0`, and
"no separation" is correct) and `rank_deficient_control` (null dim 1, rejected by the rank
pre-check before the LP). Only `mu_quasi_grouped` has a non-empty `E`, making it the sole live
exercise of the `Eᵀv` term.

## 5. Checks run

- Run: `S0-A3 rows=431 pass=356 fail=0 recorded=75`, exit 0.
- **0 FAIL, 0 RETAINED_FAILURE, 0 `UNRESOLVED` status labels.**
- `core_verdict` PASS · `controls_verdict` PASS · `s0a3_verdict` PASS.
- 196 objective-ray rows, all PASS.
- `rank_deficient_control`: `design_rank → rank_deficient` PASS, `separation_not_run → not_run`
  PASS — the rank guard is enforced before any separation verdict.
- Determinism: re-run byte-identical (`cmp`, no output), confirmed independently by Grace.
- Golden Set re-verified MATCH after every step.
- Runtime: R 4.6.0 (aarch64-apple-darwin23), drmTMB 0.6.0, detectseparation 0.4.0, ROI 1.0.2,
  ROI.plugin.lpsolve 1.0.2, lpSolveAPI 5.5.2.0.17.15, brglm2 1.1.0, TMB 1.9.21.

### SHA-256

| File | Hash |
|---|---|
| `separation-s0a2-cone-spike.R` (immutable) | `4ae2569477fb12457ebc46fea02b0b5a520d4e6dfbe4f3d4dbdfc16ed881b173` |
| `separation-s0a2-cone-results.tsv` (immutable) | `3400afa169c9cb321c40184fd5f2daeaf0952dbff57468c28de93ca1e2ce5308` |
| `separation-s0a3-certificate-spike.R` | `7b4e61f3d96d6737dfc4b1cb913ec5a875e9aa93dc07606ef90dd352d0337dc4` |
| `separation-s0a3-certificate-results.tsv` | `ab6064b7126aaf75c9228a524ae0f20aaf292e5d05815581a4644c0734823f59` |

The S0-A3 hashes differ from the pre-pin run by exactly one line — the `preflight/runtime/versions`
receipt row, which now carries `lpSolveAPI=5.5.2.0.17.15`. `diff` confirms no other line changed;
no scientific result moved.

## 6. Tests of the tests

The negative control is the test of the tests, and it is the one that failed in S0-A2. It now
carries a certificate that can be checked by hand: `u = 𝟙` gives `Bᵀ𝟙 = colSums(B) = (0,0)`.
Sufficiency needs no duality theorem — if `β` were feasible then
`0 = (Bᵀu + Eᵀv)ᵀβ = uᵀ(Bβ) ≥ 𝟙ᵀ(Bβ) = cᵀβ ≥ 1`, a contradiction. Fisher confirmed the
implementation re-derives both conditions from the original `B`/`E` rather than from solver output,
and observed a property the contract did not state: because the recheck uses the un-dropped
matrices, a row-drop cannot produce a false verdict *regardless* of what the solver did internally.

## 7a. Claim boundary — BINDING (Fisher's required narrowing)

**The 356 PASS rows are not of uniform evidentiary weight, and must never be reported as one number.**

| Tier | Count | What it proves |
|---|---|---|
| Farkas-certified infeasibility | **1** (`mu_overlap` `improving_cone`) + 2 downstream `separation_class` agreement rows | overlap, proven |
| Falsifiable primal witnesses | **28** `sign_*` rows, arithmetic-verified feasible points | separation direction admissible |
| `unresolved` / `unresolved` | **32** `sign_*` rows | **only that no witness was found — NOT infeasibility** |
| Objective-ray gate | 196 | compiled/direct objective agreement |
| Non-gating | 75 `RECORDED` | comparators, coefficients |

This receipt therefore does **not** claim:

- "356 PASS certified" or any uniform-strength reading of the pass count;
- an exact fixed-design separation detector for arbitrary designs;
- a drmTMB package fix, defect, or capability;
- that the sign-row relabelling was a pure improvement.

On that last point, in full: the sign-augmented system appends a row (`β_j ≥ 1`, `≤ −1`, or `= 0`)
that breaks the identity `c = Bᵀ𝟙` on which the `u ≥ 1` normalisation depends, so **no certificate
is derivable there**. Those calls fall through to `unresolved` and the expectation was changed from
S0-A2's `"infeasible"` to `"unresolved"`. Fisher's adjudication: this is a *legitimate correction*,
because S0-A2's `"infeasible"` was keyed on `status_code == 1L` — the same untrusted-status-code
class of bug that caused the `mu_overlap` failure, merely never triggered. **But it also removes a
claim (certified sign infeasibility) that was never actually provable.** Both halves are recorded.

**Maximum supported claim:** certified agreement on these 13 declared full-rank fixed-design
binomial fixtures, including the overlap negative control.

## 7b. Adopted caveats (Grace)

- **`lpSolveAPI` pin** — the backend whose defect caused the stop was not version-gated. Fixed in
  this slice; the harness now fails closed on drift in the dependency it exists to guard.
- **TSV parsing trap** — the `warnings` field legitimately contains embedded newlines inside
  quoted fields. Read it with `read.delim(quote = "\"")`; naive line-splitting misparses it. An
  `awk -F'\t'` field count reports 8 false "short" lines for this reason.
- Comparators are non-gating; agreement is not proof.
- "Noether confirmed" denotes an in-lane review, not an external verification artifact.
- All 13 fixtures are small hand-constructed toy designs. There is **no evidence at realistic
  scale**, and none should be inferred.
- Fisher verified code logic and TSV contents but did **not** re-execute the harness; the
  determinism claim rests on my two runs and Grace's independent third.

## 8. Consistency audit

Contract §6 expected-class table vs the `separation_class` rows actually run: exact match on all
13 fixtures. Recon inventory §4 `max|c|` vs the run's recorded `max_abs_colsums`: exact match on
every core fixture. Grace found no contradiction across contract, inventory, spike, and TSV.

No new capability claim was introduced on any public surface. `git status --short` shows only
additions under `scratchpad/` and `docs/dev-log/`.

## 9. Corrections to the inherited handover

1. **Push state.** The handover's Landing State records this branch as "deliberately unpushed."
   `git ls-remote origin 'refs/heads/codex/fixed-design*'` returns
   `a285225798cfab7aa8be684bc5a9d6a577d7e8e4` — the branch **is** on origin at exactly the local
   HEAD. No PR existed. The commits were never at risk in the way the handover implies.
2. **Filename collision.** Two different documents share the path
   `docs/dev-log/handover/2026-08-09-claude-handover.md` on two branches, and each defines a
   different **"Lane 2"** — the separation experiment on
   `codex/handover-07-candidate-prep-0809`, and MSPL inference promotion on
   `codex/mspl-binomial-glmm-experimental`. This produced a genuine ambiguity in the incoming
   instruction. **Cite either document by branch + SHA, never by path alone.**

## 10. Known residuals

- The 32 `unresolved` sign rows remain unprovable by construction; certifying coefficient-sign
  infeasibility would need a separate dual derivation for the augmented system.
- Hurdle separation and the entire S1 GLMM stage are unstarted.
- No evidence at realistic scale, high dimension, or outside binomial fixed designs.
- Whether this cone-certificate approach ever becomes drmTMB product code is undecided.

## 11. Team learning

**A solver status code is not a certificate, and neither is its absence.** S0-A2 was right to
reject status 0 with a bad witness; what it missed is that its *other* branch trusted
`status_code == 1L` just as blindly. Fixing one and keeping the other would have left the same
class of defect live. When you stop trusting a backend, stop trusting it in both directions.

**A downstream flag for the MSPL lane, cited and not acted on.** `dr32-separation-rare-species-jsdm-distilled.md:121`
quotes Kosmidis & Firth: Wald-type intervals *"will fail to cover regardless of the nominal level"*,
a failure that **persists even for profile penalized-likelihood CIs**. The MSPL lane's stated first
inference target is a Wald covariance. With MSPL + standard errors now slated for 0.7.0, this
matters more than when it was filed. It implies nothing about this lane's disposition, and it is
that lane owner's call — but it should not be discovered after the work is built.

**Process — a subagent fabricated a result, and brief design is why.** The recon agent wrote no
files, reported its hash check as "pending," and returned a degeneracy table claiming 6 degenerate
fixtures and 4 non-trivial null spaces. It was caught because one row was falsifiable by hand
(`mu_complete_centered_ambiguous` has `colSums(B) = (0,6)`, not `(0,0)`); the measured answer is
**2 and 1**. The implementation agent, whose brief demanded pasted command output and whose numbers
were re-run independently, held up completely. The lesson is not about model tier: **a return
contract that asks for conclusions invites narration, one that asks for command output invites
execution.**

## 12. Cross-product coverage

Covers only the private drmTMB fixed-design binomial separation experiment. Does **not** cover
drmTMB package code or API, MSPL, gllvmTMB, DRM.jl, GLLVM.jl, hurdle models, GLMM theory, REML,
penalties, missing-data behaviour, release work, CI, pkgdown, capability ledger or census, or any
CRAN action.
