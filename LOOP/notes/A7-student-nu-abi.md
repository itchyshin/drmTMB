# A7 — Student `nu` ABI (`mp-student-bernoulli`)

**Status.** Design locked 2026-08-27; implement on this note.
**Lane.** `~/local-scratch/lanes/drmTMB-s6-student-mi` on
`cursor/lane-s6-student-mi` from `origin/main` @ `4c34c9bbc`
(includes #1094 beta_binomial). Not the family-gate tree. Not the
nbinom2 sibling.
**Issue.** [#962](https://github.com/itchyshin/drmTMB/issues/962) hard
case. Shinichi authorized this parallel cell. `A7-post-lognormal-queue.md`
said **WAIT** on `nu`; this note is the decision that lifts that wait
without extending the shared leaf ABI.
**Capability.** Stays `partial`. No drmSEM consumer change.

---

## Verdict (read this first)

**Do not extend `drm_response_log_density`.** Extract
`drm_student_log_density(y, mu, log_sigma, eta_nu)` and clone the
lognormal identity-`μ` Bernoulli 2-point sum onto `model_type == 3`.

This is **M**, not **L**. The hardness was "the 7-arg leaf has no `nu`
slot." That is true and stays true. Student × Bernoulli does not need
that slot: `mi()` is `mu`-only, so `eta_nu` and `log_sigma` are the
same at `x = 0` and `x = 1`. A named helper (same pattern as
`drm_nbinom2_log_density`) is enough for a correct 2-point sum.

Stuffing `nu` through `V_known_val` is refused. Admitting `"student"`
on the allow-list before C++ is refused.

---

## What the shared leaf actually is

`src/drm_response_kernels.h`:

```
drm_response_log_density(
    model_type, y_val, eta_val, log_sigma_val,
    V_known_val, trials_val, link_code)
```

Leaves exist for cases 1, 4, 5, 6, 7, 10, 14, 18. `default` returns
`Type(0.0)` — a silent drop if a family is admitted without a leaf.
Student (`model_type == 3`) is not among them.

Student density in the main loop (`src/drmTMB.cpp` ~2554–2564):

\[
\nu_i = 2 + \exp(\eta_{\nu,i}), \quad
z_i = (y_i - \mu_i) / \sigma_i
\]

\[
\log f = \ell\bigl(\tfrac{\nu+1}{2}\bigr) - \ell\bigl(\tfrac{\nu}{2}\bigr)
- \tfrac12\log(\nu\pi) - \log\sigma
- \tfrac{\nu+1}{2}\log\bigl(1 + z^2/\nu\bigr)
\]

`eta_val` is identity location (not a log link). `sigma` is a **scale**,
not the residual SD. `nu` is a live third linear predictor
(`X_nu * beta_nu`). The 7-arg leaf cannot see it.

---

## Options

| | Option | What it does | Cost |
|---|---|---|---|
| **A** | Extend the shared leaf ABI | Add `Type eta_nu_val` (or a generic extra dpar). Add `case 3`. Touch every existing call site (~25). | Merge-conflict surface in `src/drmTMB.cpp` (live sibling lanes). One named slot is then overloaded for tweedie power, skew slant, later `zi`. That is a real ABI project, not this cell. |
| **B** | One-off inline density | Copy the six-line student density into the 2-point sum. Leave the main loop as-is. | Smallest diff. Recreates the exact drift the shared leaf was invented to stop (beta lesson: clamp-before-sum vs a second copy). |
| **C** | **Family helper, no shared-leaf change (this PR)** | `drm_student_log_density(y, mu, log_sigma, eta_nu)` in `drm_response_kernels.h`. Main loop and `has_mi` both call it. No `case 3` on the 7-arg leaf. | Same C++ M bucket as Gamma / lognormal / beta_binomial, plus a 4-arg helper. No ABI edit. |

**Recommend C.** A is the right *later* job if several third-dpar
families need one leaf. It is not required to ship student ×
Bernoulli, and it would collide with the nbinom2 sibling on
`src/drmTMB.cpp` call sites. B is a known failure mode.

Do **not** add `case 3` that ignores `nu`. That would be a fake
student density. Leave `default` as `Type(0.0)`; the student `has_mi`
block must not call the 7-arg leaf.

---

## Gauss self-check

1. **Locked emit.** `mi()` in `mu` only. Existing validators already
   refuse `mi()` on `sigma` / `nu`. The 2-point sum updates identity
   `μ` the way lognormal/gaussian do, not Gamma's log-`η`.
2. **Shared dpars.** For each row,
   \(\eta_{\nu}\) and \(\log\sigma\) do not depend on the missing
   binary `x`. Both quadrature points use the same
   `drm_student_log_density(..., log_sigma(i), eta_nu(i))`.
3. **Map.** \(\nu = 2 + \exp(\eta_\nu)\). Never pass `ν` through
   `V_known_val`. Never treat `eta_val` as a log-mean.
4. **Clamp.** Soft-clamp `log_sigma` **before** the 2-point sum so
   the helper and the observed-x loop see the same scale.
5. **Skip mask.** Observed-x loop must skip rows already consumed by
   the 2-point sum:
   `!(has_mi == 1 && mi_family != 0 && mi_observed(i) == 0)`.
6. **Weights.** Applied outside the helper, matching every other
   leaf call site.
7. **AD.** `mu`, `log_sigma`, `eta_nu` stay `Type`. No `asDouble()`.
8. **Refuse while shipping.** Non-Bernoulli predictor; k=2;
   `mi()` + response mask; RE / structured / phylo on any student
   dpar; `mi()` in `nu`.
9. **Allow-list last.** Append `"student"` to
   `drm_missing_predictor_families()` only after the C++ path exists.
10. **Capability.** Engine cell only. drmSEM consumer gate stays
    binary-only until a later drmSEM slice. Do not flip
    capability-status to `covered`.

---

## Implementation checklist (this PR)

1. Helper in `src/drm_response_kernels.h` (byte-identical to the
   current main-loop formula).
2. `model_type == 3`: refactor the observed-x loop onto the helper;
   add `has_mi && mi_family == 1` after clamp; identity-`μ` update;
   skip mask.
3. `drm_build_student_ls_spec(..., impute =)`: Bernoulli-only
   `drm_prepare_gaussian_mi_setup`; exclude the `mi()` symbol from
   complete cases; `MD-student-mi`; dispatcher forwards `impute`.
4. Allow-list + capability-gate test (`student` moves from reject
   set to `predictor_validated`; reject examples become
   `tweedie` / `skew_normal`).
5. `tests/testthat/test-missing-predictor-student-response.R`:
   manual 2-point-sum logLik identity + MCAR + MAR + non-binary
   refuse.
6. Ledger row `mp-student-bernoulli` on the existing
   `missing_predictor` axis. Honest G3. Not FIML. Not `impute_joint`.
7. NEWS. After-task. No whitelist-only commit.

---

## What this does not do

- No shared-leaf signature change.
- No `case 3` on the 7-arg leaf.
- No student × gaussian (quadrature; later).
- No k=2. No `impute_joint`. No zi-*.
- No drmSEM `R/` / capability flip.

**Next after this cell.** Still `mp-zi-poisson-bernoulli` (composition:
`zi` + `mi` is a product mixture; the product already refuses it).
Student × gaussian is a later expand, not a #962 first cell.

---

## Provenance

Clone template: #1092 lognormal (`7c104bbd5` parent) and #1094
beta_binomial identity of "clamp, 2-point sum, skip mask, spec
`impute`, allow-list last." Student density formula from
`src/drmTMB.cpp` model_type 3, already oracle-checked in
`tests/testthat/test-numeric-kernel-oracle.R`.
