# S0-A3 recon inventory

Measured 2026-08-09 in `/Users/z3437171/local-scratch/worktrees/drmTMB-separation-s0`
on `codex/fixed-design-binary-separation-experiment@a28522579`.

Every number below was produced by a command run in this worktree. A first
Haiku recon pass reported this table without executing anything; its values were
discarded after `mu_complete_centered_ambiguous` was falsified by hand. See §5.

## 1. Retained artifact integrity (Golden Set)

`shasum -a 256`:

| File | Hash | Expected | Verdict |
|---|---|---|---|
| `scratchpad/separation-s0a2-cone-spike.R` | `4ae2569477fb12457ebc46fea02b0b5a520d4e6dfbe4f3d4dbdfc16ed881b173` | same | **MATCH** |
| `scratchpad/separation-s0a2-cone-results.tsv` | `3400afa169c9cb321c40184fd5f2daeaf0952dbff57468c28de93ca1e2ce5308` | same | **MATCH** |

`git status --short` returned empty — no stray or modified files.

## 2. Function map (`grep -n`, `separation-s0a2-cone-spike.R`)

| Symbol | Defined | Called |
|---|---|---|
| `build_cone` | 437 | 950 |
| `constraint_residual` | 460 | 531, 587 |
| `solve_cone` | 477 | 951, 1018 |
| `solve_strict_margin` | 556 | 978 |
| `detector_class` | 617 | 1096 |
| `oracle_class` | — (a local value, not a function) | assigned ~988–994 |

`oracle_class` derives from `base_cone$state`, which is why the unresolved cone
propagated its failure into the strict-margin row `s0a2-0011`. Fixing the cone
state fixes both rows.

## 3. Fixtures

**10 core + 3 control = 13.** Controls are gated behind `core_ok`
(`spike.R:1206–1230`) and were recorded `not_run_after_core_failure` in S0-A2.

## 4. Degeneracy measurement (the key input to the contract)

For each fixture: build `X` from `formula`/`data` via `model.matrix` with
`na.omit`, drop zero-weight rows, then split rows into `B` (full failure → `-X[i,]`;
full success → `+X[i,]`) and `E` (partial success). `c = colSums(B)`.

| fixture | expected | nB | nE | p | colSums(B) | max\|c\| | degenerate | rank(B) | null dim |
|---|---|---|---|---|---|---|---|---|---|
| `mu_overlap` | none | 6 | 0 | 2 | 0,0 | 0 | **TRUE** | 2 | 0 |
| `mu_complete_shifted_forced` | complete | 4 | 0 | 2 | 0,4 | 4 | FALSE | 2 | 0 |
| `mu_complete_shifted_forced_mirror` | complete | 4 | 0 | 2 | 0,-4 | 4 | FALSE | 2 | 0 |
| `mu_complete_centered_ambiguous` | complete | 4 | 0 | 2 | 0,6 | 6 | FALSE | 2 | 0 |
| `mu_quasi` | quasi_complete | 4 | 0 | 2 | 0,2 | 2 | FALSE | 2 | 0 |
| `mu_intercept_all_success` | complete | 4 | 0 | 1 | 4 | 4 | FALSE | 1 | 0 |
| `mu_intercept_all_failure` | complete | 4 | 0 | 1 | -4 | 4 | FALSE | 1 | 0 |
| `mu_quasi_expanded` | quasi_complete | 6 | 0 | 2 | 0,4 | 4 | FALSE | 2 | 0 |
| `mu_quasi_grouped` | quasi_complete | 2 | **1** | 2 | 0,2 | 2 | FALSE | 2 | 0 |
| `rank_deficient_control` | rank_deficient | 6 | 0 | 3 | 0,0,0 | 0 | **TRUE** | 2 | **1** |
| `mu_zero_weight` | complete | 4 | 0 | 2 | 0,6 | 6 | FALSE | 2 | 0 |
| `mu_finite_offset` | complete | 4 | 0 | 2 | 0,6 | 6 | FALSE | 2 | 0 |
| `mu_response_mask` | complete | 4 | 0 | 2 | 0,6 | 6 | FALSE | 2 | 0 |

**Findings that shape the contract:**

1. **Exactly two fixtures are degenerate** (`max|c| < 1e-8`): `mu_overlap` — the
   negative control that failed in S0-A2 — and `rank_deficient_control`, which is
   degenerate by construction and is rejected by the rank pre-check *before* the LP.
   The S0-A2 defect therefore has exactly one live trigger, and it is the one
   observed.
2. **`mu_overlap` has `rank(B) = 2 = p`, so the null space of `B` is trivial.**
   Consequently `Bβ = 0 ⟹ β = 0`, and declaring "no separation" there is
   mathematically correct, not an artefact.
3. **Noether's zero-margin pathology is not triggered by any current fixture.**
   The only non-trivial null space belongs to the rank-deficient control, which
   never reaches the cone LP. The null-space branch in the contract is therefore a
   **required correctness guard, not a repair of an observed failure** — and the
   contract must say so rather than imply it fixed something.
4. **`mu_quasi_grouped` is the only fixture with a non-empty `E`** (one partial-success
   row). It is the sole live exercise of the `Eᵀv` term in the dual certificate.

## 5. Provenance note

The first A1 pass (Haiku) returned a fabricated version of §1 and §4: it emitted
heredocs into its reply instead of executing them, wrote no files, reported the
SHA check as "pending", and claimed six degenerate fixtures and four non-trivial
null spaces. `mu_complete_centered_ambiguous` was falsifiable by hand
(`colSums(B) = (0,6)`, not `(0,0)`), which exposed the rest. The table above was
re-measured inline. Recorded because it is a routing fact worth keeping, not to
disparage the tier: the slice needed execution proof, and the brief did not
demand a machine-checkable return.
