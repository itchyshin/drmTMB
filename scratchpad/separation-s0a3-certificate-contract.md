# S0-A3 contract — certified separation detection for fixed-design binomial

Frozen 2026-08-09, **before** the S0-A3 harness was written. Branch
`codex/fixed-design-binary-separation-experiment`. This is a design contract, not
evidence that anything passes.

S0-A3 is an **additive** correction slice. The S0-A2 spike and TSV are immutable
Golden Set artifacts (`4ae25694…`, `3400afa1…`, both re-verified MATCH today) and
must remain byte-identical.

## 1. What failed, and why the fix is not "use a better solver"

S0-A2 could not certify its overlap negative control. `ROI.plugin.lpsolve`
returned solver status 0 (OPTIMAL) with `β = 0` on a system whose own returned
solution violated a constraint by exactly 1.

Root cause, reproduced 2026-08-09: for `mu_overlap`, `colSums(B) = (0,0)`, so the
harness's normalisation row is the degenerate `0ᵀβ ≥ 1`. **lpSolveAPI silently
drops all-zero constraint rows.** The LP it actually solved was missing the only
row that made it infeasible.

The lesson is not that this backend is bad. It is that **a solver status code is
not a proof**. S0-A3 therefore accepts a verdict only when a *witness* has been
re-checked by direct arithmetic, in both directions.

## 2. Estimand

For a full-rank fixed design, Albert & Anderson (1984) — via
`ENGINEERING-NOTEBOOK.md:984`, *"overlap ⇒ MLE exists and is unique"* — make the
complete / quasi-complete / overlap trichotomy exhaustive, with overlap
**necessary and sufficient** for existence of a finite MLE.

Signed design, per row `i` of the model matrix `X` (after `na.omit` and dropping
zero-weight rows):

- `y_i = 0`          → row `−X[i,]` into `B`
- `y_i = trials_i`   → row `+X[i,]` into `B`
- `0 < y_i < trials_i` → row `X[i,]` into `E`

`E` rows are **equalities**: an interior observation drives the likelihood to −∞
if its linear predictor diverges, so any separating direction must satisfy
`x_iᵀβ = 0` exactly. (Noether Q3: confirmed correct per Albert & Anderson.)

Primal system, with `c = colSums(B) = Bᵀ𝟙`:

```
(P)   B β ≥ 0 ,   E β = 0 ,   cᵀβ ≥ 1
```

**(P) feasible ⟺ separated (complete or quasi-complete). (P) infeasible ⟺ overlap.**

Justification of the normalisation. For any `β` with `Bβ ≥ 0`,
`cᵀβ = 𝟙ᵀ(Bβ) ≥ 0`, with equality **iff `Bβ = 0` exactly** (non-negative entries
summing to zero all vanish). So `cᵀβ ≥ 1` excludes precisely the directions with
zero margin on every `B` row, and any direction with a strict inequality anywhere
can be rescaled to satisfy it. It does **not** merely exclude `β = 0`.

## 3. The full-rank precondition — this is the null-space guard

Noether's Q2 caveat: a nonzero `β` with `Bβ = 0` identically would be a
zero-margin direction that `cᵀβ ≥ 1` cannot see, so infeasibility of (P) would not
by itself prove overlap.

That case is **exactly rank deficiency**, and it is excluded by a rank condition
rather than by a special LP branch:

> If `[B; E]` has full column rank `p`, then `Bβ = 0` and `Eβ = 0` force `β = 0`.

Since every row of `B` is `±` a row of `X` and every row of `E` is a row of `X`,
`rank([B; E]) = rank(X)`. So the existing full-rank pre-check on the design is
the guard, and no separate null-space LP is needed.

**Contract requirement C1.** The harness must assert `rank(X) = ncol(X)` and record
it *before* solving any cone LP. If the design is rank deficient it returns class
`rank_deficient` and **must not** emit any separation verdict. A degenerate
normalisation (`max|c| < tol`) on a full-rank design is then provably a genuine
overlap signal, not an artefact — and the harness must record `max|c|` either way
so the S0-A2 defect can never again be silent.

Measured on the current fixture set (see `separation-s0a3-recon-inventory.md` §4):
only `mu_overlap` (full rank, `rank(B) = 2 = p`) and `rank_deficient_control`
(`null dim = 1`, excluded by C1) are degenerate. **The zero-margin pathology is
not triggered by any live fixture.** C1 is a required correctness guard, not a
repair of an observed failure, and must be described that way.

## 4. Verdicts — tri-state, fail-closed

Every verdict requires an arithmetically re-checked witness. No status code is
load-bearing.

### 4a. `feasible` (separated) — primal witness

Accept only if the returned `β` satisfies **all** of:

```
min(B β)            ≥ −τ_B
max|E β|            ≤  τ_E
cᵀβ                 ≥  1 − τ_c
```

### 4b. `infeasible_certified` (overlap) — Farkas/Gordan dual witness

Find `u` (length `nrow(B)`), `v` free (length `nrow(E)`) with

```
u ≥ 1  (componentwise) ,    Bᵀu + Eᵀv = 0
```

Accept only if **both** of:

```
max|Bᵀu + Eᵀv|      ≤  τ_D
min(u)              ≥  1 − τ_u
```

**Derivation** (Noether confirmed necessary *and* sufficient). Write (P) as
`Aβ ≥ b` with `A = [B; E; −E; cᵀ]`, `b = (0;0;0;1)`. Infeasibility ⟺ ∃ `y ≥ 0`
with `Aᵀy = 0`, `bᵀy > 0`; writing `y = (u₀, v₁, v₂, w)` and `v = v₁ − v₂` gives
`Bᵀu₀ + Eᵀv + w c = 0` with `w > 0`. Because `c = Bᵀ𝟙` — and *only* because of
that — substituting `u = (u₀ + w𝟙)/w` yields `u ≥ 1` and `Bᵀu + Eᵀv/w = 0`. So
`u ≥ 1` is the correct normalisation; `u ≥ 0, u ≠ 0` would not suffice.

Sufficiency needs no duality theorem, which is what makes the check trustworthy:
if `β` were feasible and `(u,v)` satisfies the certificate, then

```
0 = (Bᵀu + Eᵀv)ᵀβ = uᵀ(Bβ) + vᵀ(Eβ) = uᵀ(Bβ) ≥ 𝟙ᵀ(Bβ) = cᵀβ ≥ 1
```

— a contradiction. The certificate is a self-contained disproof of feasibility.

### 4c. `unresolved` — everything else

Any other outcome, including a solver reporting success whose witness fails
verification. `unresolved` **fails the gate**. This is the S0-A2 behaviour and it
is retained deliberately: it is what caught the defect.

**Contract requirement C2.** A backend fault can therefore produce a false
`unresolved`, never a false `feasible` or false `infeasible_certified`. Every
inequality in 4a and 4b must be evaluated — checking a subset breaks this
property (Noether Q4).

## 5. Tolerances — relative, not absolute

S0-A2 used a bare `tol = 1e-8` against quantities whose scale depends on `X`.
S0-A3 scales each check to the magnitudes actually entering it. With
`ε = 1e-8` and `‖·‖∞` the max-abs entry:

```
τ_B = ε · max(1, ‖B‖∞ · ‖β‖∞)
τ_E = ε · max(1, ‖E‖∞ · ‖β‖∞)
τ_c = ε · max(1, ‖c‖∞ · ‖β‖∞)
τ_D = ε · max(1, ‖B‖∞ · ‖u‖∞, ‖E‖∞ · ‖v‖∞)
τ_u = ε                                  (u is normalised to ≥ 1; absolute is correct here)
```

The harness must record the realised tolerance alongside each residual, so a pass
can be audited rather than trusted.

## 6. Expected classes

Unchanged from S0-A2 — S0-A3 corrects the *instrument*, not the expectations.
Re-stating them here freezes them before the run.

| fixture | expected | notes |
|---|---|---|
| `mu_overlap` | none | the negative control; `max|c| = 0`, full rank |
| `mu_complete_shifted_forced` | complete | |
| `mu_complete_shifted_forced_mirror` | complete | mirror |
| `mu_complete_centered_ambiguous` | complete | admits a zero-intercept ray |
| `mu_quasi` | quasi_complete | |
| `mu_intercept_all_success` | complete | intercept-only, `+∞` |
| `mu_intercept_all_failure` | complete | intercept-only, `−∞` |
| `mu_quasi_expanded` | quasi_complete | Bernoulli expansion |
| `mu_quasi_grouped` | quasi_complete | **only fixture with `E` non-empty** — the sole live exercise of the `Eᵀv` term |
| `rank_deficient_control` | rank_deficient | must be caught by C1 before the LP |
| `mu_zero_weight` | complete | exact-row control |
| `mu_finite_offset` | complete | exact-row control |
| `mu_response_mask` | complete | exact-row control |

## 7. Comparators

`detectseparation 0.4.0` stays the maintained comparator (Konis's dual-LP
detection, ~one IRLS fit — `ENGINEERING-NOTEBOOK.md:1198`). Its agreement is
recorded, never used to *define* the oracle.

**Contract requirement C3.** The `brglm2` comparator is repaired to the installed
interface: `type` is a formal of `brglmControl()`, not `brglmFit()`, so the call
becomes `brglmFit(..., control = brglm2::brglmControl(type = "AS_mean"))`. It stays
**non-gating**. A comparator that errors is not evidence; a comparator that runs
is not an oracle.

## 8. Scope and stop line

In scope: the binomial fixed-design core, the objective-ray gate, and — because
they unlock at `core_ok` — the exact-row controls (zero-weight, offset,
response-mask).

**Out of scope, hard stop:** hurdle separation, the S1 GLMM stage, any package
code under `R/`, `src/`, `tests/`, `man/`, `DESCRIPTION`, `NAMESPACE`, `NEWS.md`,
`_pkgdown.yml`, any release surface, any compute campaign, and any capability or
ledger claim.

**Claim boundary.** A green S0-A3 licenses exactly one statement: *on these
declared full-rank fixed-design binomial fixtures, the certified cone test agrees
with the maintained detector and with the drmTMB objective's recession
directions.* It is **not** an exact detector PASS for arbitrary designs, and it is
**not** a drmTMB capability. Separation remedies (Firth/Jeffreys, MSPL) and their
inference properties are outside this contract — including the Kosmidis & Firth
Wald-coverage warning, which is carried in
`separation-s0a3-literature-cites.md` §4 as a flag for the MSPL lane only.
