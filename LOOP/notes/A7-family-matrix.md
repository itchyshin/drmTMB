# A7 — Family × predictor × k prioritization matrix

**Status.** Read-only recon (2026-08-27). No C++ implemented.
**Sources.** drmTMB `origin/main` @ `cc3ef1e8f` (includes #1086 / `1cc1985cd`);
drmSEM `main` @ `e7392d7`; GitHub [#962](https://github.com/itchyshin/drmTMB/issues/962);
drmSEM `LOOP/notes/A1-engine-contract.md` (present at `e7392d7`).
**Lane.** `~/local-scratch/lanes/drmTMB-s6-family-gate` on `cursor/lane-s6-family-gate`.
Do not touch MAG worktrees. Do not edit the dirty drmTMB primary checkout.

---

## Verdict (read this first)

**First A7 target after Gaussian k=2:** `nbinom2()` response × one
`gaussian()` `impute_model()` × k=1.

| | |
|---|---|
| **Ledger id (proposal)** | `mp-nbinom2-gaussian` |
| **Why this, not a whitelist edit** | `nbinom2` is already on `drm_missing_predictor_families()`. C++ already has `has_mi && mi_family == 1` (Bernoulli) in `model_type == 7`. The missing piece is a `mi_family == 0` (Gaussian predictor) branch plus lifting the R "binary only" abort. That is #962's failure mode in reverse: the gate is honest; the likelihood path is not there yet. |
| **C++ scope** | **S (small–medium).** Clone the existing Gaussian-predictor block (`src/drmTMB.cpp` ~1175–1243, drop `has_mi_group` / `has_mi_struct`) into the nbinom2 block (~3894–4138). Adapt the `mu` update onto `eta_mu` (log link), matching the Poisson Bernoulli pattern at ~3774–3813. Existing skip `!(has_mi == 1 && mi_family != 0 && mi_observed(i) == 0)` already *includes* the response density for `mi_family == 0` (latent `x_miss`). R spec already calls `drm_prepare_gaussian_mi_setup()`; only the `!identical(mi_setup$family, "bernoulli")` abort in `drm_build_nbinom2_spec` (~7652) needs a Gaussian exception. `allow_k2` stays `FALSE`. |
| **SEM value** | Modal ecological graph: abundance ~ incomplete continuous mediator. drmSEM @ `e7392d7` already lists `nbinom2` as an impute *response* family; it still aborts non-binary parents (`R/imputation.R:161-168`). Engine first; consumer lift is a later drmSEM slice. |
| **Do not start with** | Gamma / lognormal / student / beta_binomial / zi-* (#962's *new-response* list) — those need greenfield `has_mi` *and* a spec-builder that today never calls mi-setup. Do not start with k=2 on a non-Gaussian (two new things). Do not start with mixed predictor families. |

**#962-literal next cell (tranche 2, not first):** `mp-lognormal-gaussian`
(lognormal response × Gaussian predictor × k=1). Closest clone of
`model_type == 1` onto log-location; #962 lists it first among unwired
responses. Student is harder (`nu`). zi-* are last (extra dpar; Poisson
already rejects `zi` + `mi()`).

---

## 1. Gate logic (current, honest)

`drm_missing_predictor_families()` on `origin/main` (`R/missing-data.R:369-371`):

```r
c("gaussian", "poisson", "binomial", "nbinom2", "beta")
```

This is a **response-family** allow-list for `miss_control(predictor = "model")`
and for a non-null `impute` (`R/drmTMB.R:395-410`). It is **not** the
predictor-family catalogue.

Stacked gates after the allow-list:

| Layer | Where | What it still refuses |
|---|---|---|
| Response allow-list | `drm_missing_predictor_families()` | Gamma, lognormal, student, tweedie, zero_one_beta, beta_binomial, cumulative_logit, truncated_nbinom2, hurdle_nbinom2, zi_poisson, zi_nbinom2, skew_normal, biv_* |
| Binary-only (non-Gaussian) | `drm_build_{poisson,binomial,nbinom2,beta}_spec` | any `impute_model()` family other than Bernoulli/logit |
| k=2 | `drm_prepare_gaussian_mi_setup(..., allow_k2=)` | `allow_k2 = TRUE` **only** on the Gaussian spec builder. Two `mi()` terms on any other response abort. k=2 also requires **both** predictor models Gaussian, fixed-effect only, distinct symbols |
| k>2 | same | abort ("not implemented yet") |
| Syntax | `drm_validate_bare_mi_call` | transforms, interactions, `sigma`/`zi` `mi()` |
| Composition | Poisson/binomial/nbinom2/beta specs | `mi()` + response mask together; `mi()` + `zi`; `mi()` + RE/structured on the *response* `mu` |

drmSEM @ `e7392d7` mirrors the same two laws
(`drm_impute_response_families()`, binary-only in `drm_check_impute_legal`)
and locks the list to the engine with V-80.

**A1 contract (drmSEM `LOOP/notes/A1-engine-contract.md`, present at
`e7392d7`).** Phase 1 ships only `gaussian × gaussian × gaussian` k=2
independent (`mp-gaussian-gaussian-k2-indep`, now on `origin/main`). Item 1
/ A7 is **per-family C++ observed-data likelihood**, not a gate flip.
Promoting a family without `has_mi` is the #962 failure mode. Still refused
after Phase 1: non-Gaussian k=2; non-Gaussian × non-binary; mixed predictor
families; `impute_joint`; exogenous; non-`mu` `mi()`.

---

## 2. C++ `has_mi` vs whitelist-only

`DATA_INTEGER(has_mi)` / `mi_family` / `has_mi2` are global. Wiring is
**per `model_type` block**.

### `mi_family` codes (`R/missing-data.R` ~3960)

| Code | Predictor family |
|---:|---|
| 0 | gaussian |
| 1 | bernoulli |
| 2 | ordinal (`cumulative_logit`) |
| 3 | categorical |
| 4 | beta |
| 5 | poisson |
| 6 | lognormal |
| 7 | gamma |
| 8 | nbinom2 |
| 9 | tweedie |
| 10 | zero_one_beta |
| 11 | truncated_nbinom2 |
| 12 | beta_binomial |

### Response `model_type` vs `has_mi` (C++ on `origin/main`)

| Response | `model_type` | On whitelist? | C++ `has_mi` | Predictor support in C++ | Spec calls mi-setup? |
|---|---:|:---:|---|---|---|
| gaussian | 1 | yes | **full** | `mi_family` 0–12 + `has_mi2` (2nd Gaussian, FE only) + group/struct on first Gaussian | yes; `allow_k2 = TRUE` |
| poisson | 6 | yes | **Bernoulli only** (`mi_family == 1`) | two-state sum; skip mask for non-0 families | yes; binary abort |
| binomial | 18 | yes | **Bernoulli only** | same pattern | yes; binary abort |
| nbinom2 | 7 | yes | **Bernoulli only** | same pattern | yes; binary abort |
| beta | 10 | yes | **Bernoulli only** | same pattern | yes; binary abort |
| Gamma | 5 | **no** | **none** | — | **no** (`drm_build_gamma_ls_spec`) |
| lognormal | 4 | **no** | **none** | — | **no** |
| student | 3 | **no** | **none** | — | **no**; #962: needs `nu` derivation |
| beta_binomial (response) | 14 | **no** | **none** | predictor-side `mi_family == 12` is unrelated | **no** |
| zi_poisson | 8 | **no** | **none** | Poisson+`zi` already rejected even on the wired Poisson cell | **no** |
| zi_nbinom2 | 9 | **no** | **none** | same | **no** |
| tweedie | 16 | no | none | — | no |
| zero_one_beta | 15 | no | none | — | no |
| truncated_nbinom2 | 11 | no | none | — | no |
| hurdle_nbinom2 | 12 | no | none | — | no |
| cumulative_logit | 13 | no | none | — | no |
| skew_normal | 17 | no | none | — | no |
| biv_* | 2/19/20 | no | none | `mi()` inside bivariate explicitly rejected | n/a |

**Summary.** Five whitelist families. One of them (Gaussian) has a real
catalogue + k=2. Four have C++ for **one binary predictor only**. Every
#962 family is whitelist-absent **and** C++-absent **and** spec-absent.
The gate describes the implementation. Do not widen it first.

---

## 3. Ledger: cells that exist vs gaps

Axis `missing_predictor` on
`docs/dev-log/dashboard/capability-ledger/cells.tsv` (`origin/main`).
**18 rows.** Do not invent a second axis (A1 / A5).

### Existing rows

| cell_id | Response × predictor × k | tier / gate | Notes |
|---|---|---|---|
| `mp-gaussian-gaussian` | gaussian × gaussian × 1 | `diagnostic_only` / G2 | Only cell with group + `relmat()` predictor models. No manual `dnorm` logLik cross-check |
| `mp-gaussian-bernoulli` | gaussian × bernoulli × 1 | G2 | manual logLik |
| `mp-gaussian-ordinal` | gaussian × ordinal × 1 | G2 | FE only |
| `mp-gaussian-categorical` | gaussian × categorical × 1 | G2 | FE only |
| `mp-gaussian-beta` | gaussian × beta × 1 | G2 | quadrature |
| `mp-gaussian-zero-one-beta` | gaussian × zob × 1 | G2 | |
| `mp-gaussian-beta-binomial` | gaussian × beta_binomial × 1 | G2 | false-convergence caveat |
| `mp-gaussian-poisson` | gaussian × poisson × 1 | G2 | |
| `mp-gaussian-nbinom2` | gaussian × nbinom2 × 1 | G2 | |
| `mp-gaussian-truncated-nbinom2` | gaussian × trunc_nb2 × 1 | G2 | |
| `mp-gaussian-lognormal` | gaussian × lognormal × 1 | G2 | |
| `mp-gaussian-gamma` | gaussian × gamma × 1 | G2 | |
| `mp-gaussian-tweedie` | gaussian × tweedie × 1 | G2 | |
| `mp-poisson-bernoulli` | poisson × bernoulli × 1 | **G2 only** | **Clearest existing-row hole:** no coefficient-recovery `test_that`. Ledger says so |
| `mp-binomial-bernoulli` | binomial × bernoulli × 1 | `point_fit_recovery` / G3 | |
| `mp-nbinom2-bernoulli` | nbinom2 × bernoulli × 1 | G3 | recovery harness exists — reuse for A7 |
| `mp-beta-bernoulli` | beta × bernoulli × 1 | G3 | |
| `mp-gaussian-gaussian-k2-indep` | gaussian × 2×gaussian × 2 | G3 | #963 option (b). Not `impute_joint`. Issue URL #963 |

A1's "17 one-parent rows" plus the shipped k=2 row = these 18.

### Gaps (no row; most also no C++)

Every blank in the matrix below. Highest-value missing ids:

| Proposed id | Cell | Why missing |
|---|---|---|
| `mp-nbinom2-gaussian` | nbinom2 × gaussian × 1 | **A7 first target.** Wired response, unwired predictor type |
| `mp-poisson-gaussian` | poisson × gaussian × 1 | same pattern; simpler likelihood; weaker existing G3 |
| `mp-binomial-gaussian` | binomial × gaussian × 1 | same |
| `mp-beta-gaussian` | beta × gaussian × 1 | same |
| `mp-lognormal-gaussian` | lognormal × gaussian × 1 | #962 tranche 2 |
| `mp-gamma-gaussian` | Gamma × gaussian × 1 | #962; mean-CV param |
| `mp-student-gaussian` | student × gaussian × 1 | #962; `nu` |
| `mp-nbinom2-bernoulli-k2-indep` | nbinom2 × 2×bernoulli × 2 | later; `has_mi2` is Gaussian-shaped today |
| `mp-nbinom2-gaussian-k2-indep` | nbinom2 × 2×gaussian × 2 | later; needs this file's first cell first |
| `mp-poisson-bernoulli` G3 promotion | (row exists) | **not A7 C++.** Add a recovery test; do not spend A7 budget here unless bundled as honesty |

No `missing_predictor` rows exist for any #962 new response family.

---

## 4. #962 requirements

**Title.** `mi()` likelihood wiring is absent for
Gamma / lognormal / student / beta_binomial / zi-* responses
(not a gate widening).

**Open.** Sequencing comment 2026-08-26
([#issuecomment-5429120815](https://github.com/itchyshin/drmTMB/issues/962#issuecomment-5429120815)):
item 1 comes **after** #963 + a ledger row for the cell that actually ships.
Phase 1 (two independent Gaussian `mi()` on a Gaussian response) has now
shipped (#1086). This issue stays per-family C++ work.

**Acceptance (per family).**

1. C++ marginalisation over the missing predictor's support in `src/drmTMB.cpp`.
2. Known-DGP recovery test.
3. `missing_predictor` ledger row at an honest tier.

Admitting a family without the likelihood path is strictly worse than
leaving it gated.

**Motivation.** Every drmSEM node is one drmTMB fit. drmSEM has no family
whitelist of its own beyond the engine mirror, so a SEM loses `mi()` the
moment any node uses an unwired response.

**Framing tension (do not collapse).**

- **#962 body** = new *response* families with zero `has_mi`.
- **A1 / ultra-plan Phase 2** = after Gaussian k=2, first candidates are
  the *already-allowed* responses (poisson / binomial / nbinom2 / beta)
  if they still only admit a binary predictor.
- **A1 refuse table** also files non-Gaussian k=2 under item 1 / #962.

This matrix treats A7 as **any missing C++ `has_mi` path**, sequenced:
(1) useful predictor on a wired response, (2) #962 new responses,
(3) k=2 on a non-Gaussian. That matches ultra-plan Phase 2 and keeps
#962's "do not flip the gate" rule.

---

## 5. A1 engine contract (drmSEM, present)

File: drmSEM `LOOP/notes/A1-engine-contract.md` @ `e7392d7`.

Locks that bind A7:

- Independence (option b), not `impute_joint`. G3 if independence is
  unusable — stop; do not silently switch estimands.
- Emit shape: bare additive `mi()` in `mu` only; named `impute` list;
  predictor formula/family from the parent node; exogenous → `na_action`.
- `imputed()`: branch on `uncertainty_status`; require `variable` when k≥2.
- Family cells: Phase 1 = `mp-gaussian-gaussian-k2-indep` only.
- Item 1 = C++ observed-data likelihood, not `drm_missing_predictor_families()`
  edits.
- drmSEM consumer already ships k=2 Gaussian (`e7392d7` / PRs #45–#47).
  Capability stays `partial`. A7 is Phase 2 / deferred on the closed S6 arc.

---

## 6. Prioritization matrix

Legend for each cell:

| Mark | Meaning |
|---|---|
| **SHIP** | C++ + R + ledger row |
| **CPP** | C++ exists; R still refuses (or no ledger) |
| **R** | R would accept if C++ existed (whitelist + spec) — does **not** occur today for #962 families |
| **NONE** | no C++, not on whitelist, spec never calls mi-setup |
| **—** | structurally out of scope for A7 (biv, `zi`+`mi`, non-`mu`) |

Predictor types abbreviated: `g` gaussian, `b` bernoulli, `o` ordinal,
`c` categorical, `β` beta, `zob` zero-one-beta, `bb` beta_binomial,
`p` poisson, `nb` nbinom2, `tnb` trunc_nbinom2, `ln` lognormal,
`Γ` gamma, `tw` tweedie.

### k = 1

| Response \ predictor | g | b | o | c | β | zob | bb | p | nb | tnb | ln | Γ | tw |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **gaussian** | SHIP | SHIP | SHIP | SHIP | SHIP | SHIP | SHIP | SHIP | SHIP | SHIP | SHIP | SHIP | SHIP |
| **poisson** | **A7+1** | SHIP (G2 only) | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE |
| **binomial** | A7+2 | SHIP G3 | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE |
| **nbinom2** | **A7 first** | SHIP G3 | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE |
| **beta** | A7+3 | SHIP G3 | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE |
| **lognormal** | #962-2 | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE |
| **Gamma** | #962-3 | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE |
| **student** | #962 later | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE |
| **beta_binomial** | #962 later | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE | NONE |
| **zi_poisson / zi_nbinom2** | last | last | — | — | — | — | — | — | — | — | — | — | — |
| other (tweedie, zob, trunc, hurdle, ordinal, skew, biv) | NONE / — | NONE / — | — | — | — | — | — | — | — | — | — | — | — |

`A7 first` / `A7+1` / `A7+2` / `A7+3` = same C++ pattern (clone
`mi_family == 0` into an already-wired non-Gaussian block), sequenced by
SEM frequency and existing recovery harness quality.

### k = 2 (independent `impute_model()` list, not `impute_joint`)

| Response \ both predictors | 2×gaussian | 2×bernoulli | mixed families |
|---|---|---|---|
| **gaussian** | **SHIP** `mp-gaussian-gaussian-k2-indep` | NONE (parser refuses non-Gaussian pair) | NONE |
| **nbinom2 / poisson / binomial / beta** | after that family's `× gaussian × 1` | possible (4-state sum) but `has_mi2` is Gaussian-shaped; do not start here | later |
| **#962 new responses** | after that family's k=1 Gaussian predictor | later | later |

k>2: no C++, no parser, no ledger. Out of A7 first-cell scope.

---

## 7. Recommended sequence (after this first cell)

| Order | cell_id | C++ scope | Why next |
|---|---|---|---|
| **1** | `mp-nbinom2-gaussian` | S: clone `mi_family==0` → `model_type==7`; lift binary abort for gaussian only | This note's target |
| 2 | `mp-poisson-gaussian` | S: same → `model_type==6` | Same pattern; also add the missing Poisson-Bernoulli G3 recovery while the file is open |
| 3 | `mp-binomial-gaussian` | S → `model_type==18` | Binary response × continuous mediator is common |
| 4 | `mp-beta-gaussian` | S → `model_type==10` | Closes the four-family binary-only set |
| 5 | `mp-lognormal-gaussian` | **M:** new `has_mi` in `model_type==4` + wire `drm_build_lognormal_ls_spec` + add family to the allow-list **after** C++ | First true #962 new-response cell |
| 6 | `mp-gamma-gaussian` | M: `model_type==5` + gamma spec | #962; mean-CV |
| 7 | `mp-nbinom2-gaussian-k2-indep` | M: clone `has_mi2` (~1245–1270) into nbinom2 | Only after cell 1 exists |
| 8 | student / beta_binomial / zi-* | L: `nu`, trials, extra dpar | #962 remainder |

**C++ scope key.** S ≈ 60–120 lines in one `model_type` block + R abort
exception + one recovery test + one ledger row. M ≈ S plus spec-builder
mi-setup plumbing + allow-list append (only after C++). L ≈ new
derivation, not a clone.

---

## 8. First-cell DoD (when someone implements — not this recon)

For `mp-nbinom2-gaussian` only:

1. C++ `has_mi == 1 && mi_family == 0` inside `model_type == 7`.
   Fixed-effect predictor only (no group/struct on this first slice).
2. R: nbinom2 spec accepts `impute_model(..., family = gaussian())`;
   still refuses non-Gaussian non-Bernoulli predictors and k=2.
3. **Do not** edit `drm_missing_predictor_families()` (already lists
   nbinom2).
4. Recovery test (MCAR + at least one MAR/outcome-dependent), plus a
   manual or cloned logLik identity if cheap. Totoro smoke first.
5. Ledger row `mp-nbinom2-gaussian` on the **existing**
   `missing_predictor` axis, honest tier (`diagnostic_only` until
   recovery lands; `point_fit_recovery` if the test is real).
6. Fail-loud tests: Gamma response still aborted; nbinom2 × Poisson
   predictor still aborted; nbinom2 k=2 still aborted.
7. drmSEM consumer gate (`drm_check_impute_legal` binary-only) is
   **not** this lane. Note the follow-up; do not silently emit an
   illegal call from drmSEM before the engine row exists.

---

## 9. What this recon did not do

- No C++. No whitelist edit. No ledger write.
- Did not touch MAG-completeness / MAG-wire / S3-grouping.
- Did not edit drmTMB primary checkout
  (`claude/ledger-biv-gaussian-residual-covered`).
- Did not replace this worktree's leftover interval-audit `LOOP/GOAL.md`
  / `arcs.md` (copied from an older kit). Only this notes file is the
  A7 recon artefact.
- `joint-mi` / `impute_joint` remains A3 prior art, not an A7 path.
