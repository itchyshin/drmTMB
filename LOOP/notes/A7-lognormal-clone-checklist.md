# A7 — Lognormal × Bernoulli clone checklist

**Status.** Gauss engine-pattern extract (2026-08-27). Notes only. No C++
from this agent.
**Cell.** `mp-lognormal-bernoulli` — `lognormal()` response × one Bernoulli
`mi()` predictor × k=1. #962's next unwired family after Gamma #1088.
**Source of truth for the clone.** drmTMB `origin/main` @ `6e553879`
(`feat(missing): Gamma response has_mi for one binary predictor (#962) (#1088)`).
**Compare-to.** `model_type == 4` / `drm_build_lognormal_ls_spec` as shipped
on that sha (no `has_mi`, no `impute=`).
**Lane.** `~/local-scratch/lanes/drmTMB-s6-family-gate` on
`cursor/lane-s6-family-gate`. Sibling `67a70b94` owns C++/R. Do not open a
second worktree. Do not edit the dirty primary drmTMB checkout.
**This note.** File map so a resume cannot miss a file. C++ first; allow-list
last. Not FIML. Not `impute_joint`. Not k≥2. capability-status stays
`partial` on the drmSEM side.

Mid-flight snapshot (sibling dirty at write time; do not re-do what is
already correct): `src/drm_response_kernels.h` `case 4` and
`src/drmTMB.cpp` `model_type == 4` `has_mi && mi_family == 1` are in
progress and look parameterization-correct (log-location + Jacobian + skip
mask). Remaining holes are listed under **Still open on the dirty tree**.

---

## 0. Order (do not invert)

1. C++ leaf `case 4` in `drm_response_log_density`.
2. C++ `has_mi` inside `model_type == 4`.
3. R spec: `impute=` plumbing on `drm_build_lognormal_ls_spec` (clone
   Gamma, do **not** clone Gamma's `exp(eta)`).
4. `split_tmb_parameters()` mi-coef branch.
5. Tests (logLik identity + MCAR + MAR + refuse).
6. **Then** `"lognormal"` on `drm_missing_predictor_families()`.
7. Capability-gate test + roxygen/NEWS/man.
8. Ledger row + count bump 19 → 20 (three places).
9. Re-run the committed C17/C14 runner if `src/drmTMB.cpp` stale-dates
   fingerprints (Gamma's second commit in #1088).
10. `devtools::document()`.

Promoting the allow-list without the leaf is the #962 failure mode.

---

## 1. Parameterization (read before touching C++)

| | Gamma `model_type == 5` (shipped) | Lognormal `model_type == 4` (clone onto this) |
|---|---|---|
| Family | `stats::Gamma(link = "log")` | `lognormal()` |
| `mu` link | **log**: `eta_mu` → `mu = exp(eta_mu)` = E[Y] | **identity on log Y**: `mu = offset + Xβ` = E[log(Y)] |
| `sigma` | CV; `log(σ)` on linear predictor; shape = 1/σ², scale = μσ² | sdlog; `σ = exp(log_sigma)` |
| Main-loop density | mean-CV Gamma (`src/drmTMB.cpp` ~2904–2918) | `dnorm(log(y), mu, sigma, true) - log(y)` (~2763–2767 @ 6e553879) |
| Positive y | yes (`y > 0`) | yes (`y > 0`); spec already aborts otherwise (~4671–4675) |
| Family links | mu=log, sigma=log | mu=**identity**, sigma=log (`R/family.R` ~217) |
| DPQ | `dgamma(shape, scale)` | `dlnorm(meanlog=mu, sdlog=sigma)` already includes the Jacobian (`R/family-dpq.R` ~414–425) |

**Do not** write `Type mu = exp(eta_val)` in the lognormal leaf. That is
Gamma. Lognormal `eta_val` **is** the location of `log(y)`.

**Do not** clone Poisson's missing-x REPORT rewrite
`eta_mu = log(p*exp(eta1)+(1-p)*exp(eta0))` (`src/drmTMB.cpp` ~3847–3850).
That is E[μ] on the count scale. Clone Gamma's **linear-on-linear-predictor**
update, applied to lognormal's existing `mu` symbol (already log-location).

---

## 2. File / function map (every #1088 path → lognormal)

### 2a. C++ (do first)

| File | Gamma @ 6e553879 | Lognormal action | Line-region hint |
|---|---|---|---|
| `src/drm_response_kernels.h` | `case 5:` ~78–91 | Add `case 4:` **before** `default:`. Leaf must be `dnorm(log(y_val), eta_val, exp(log_sigma_val), true) - log(y_val)`. `default` currently returns `Type(0.0)` — a missing case 4 silently turns the 2-point sum into the Bernoulli prior. | Insert after `case 10` / before `case 5` or immediately before `default` (~92). |
| `src/drmTMB.cpp` `model_type == 4` | n/a (no `has_mi`) | Clone Gamma's block (~2863–2903) onto the **existing** `mu` vector (already `offset_mu + X_mu * beta_mu`, ~2636–2641). Do **not** introduce `eta_mu` + `exp`. | After sigma-RE + clamp, before the main density loop (~2758–2768 @ 6e553879). |
| `src/drmTMB.cpp` clamp | Gamma moved clamp **before** the 2-point sum (~2857–2862) | Same: clamp `log_sigma` before `has_mi` so leaf and main loop share one clamped scale (beta lesson). | Current clamp is ~2758–2761. Keep it above `has_mi`. |
| `src/drmTMB.cpp` skip mask | `observed_y(i)==1 && !(has_mi==1 && mi_family!=0 && mi_observed(i)==0)` (~2907–2908) | Add the same conjunct. Today's lognormal loop is only `if (observed_y(i)==1)` (~2764). Without the skip, missing-x rows are double-counted (2-point sum **and** main loop). | ~2763–2768. |
| `src/drmTMB.cpp` REPORT update | `eta_mu += beta_mu(mi_col) * (x_or_p - X_mu(i,mi_col))` | Same algebra on `mu(i)`. Observed-x: plug in `mi_x`. Missing-x: plug in `posterior_p1`. REPORT-only for missing-x (skip mask owns the likelihood). | Parallel to Gamma ~2875–2896. |
| `has_mi_group` / `has_mi_struct` / `has_mi2` | Gamma did **not** add these | Do **not** add. FE Bernoulli only. | Gaussian block ~1175–1270 is the wrong clone. |

### 2b. R spec (`drm_build_lognormal_ls_spec`)

Clone the Gamma #1088 hunk in `R/drmTMB.R`. Gamma function starts ~4770;
lognormal starts ~4498. Touch **all** of these or the fit dies before TMB:

| Site | Gamma after #1088 | Lognormal today @ 6e553879 | Action |
|---|---|---|---|
| `drmTMB()` switch | `impute = impute` (~465) | **no** `impute=` (~453–458) | Pass `impute = impute`. |
| Function signature | `impute = NULL` (~4775) | no `impute` (~4498–4503) | Add the argument. |
| After structured/RE validate | `drm_prepare_gaussian_mi_setup` + three aborts (~4873–4898) | none | Copy; rename "Gamma" → "lognormal". Binary-only. Refuse response+predictor together. FE `mu`/`sigma` only. `allow_k2` stays default `FALSE`. |
| `impute_vars` + `vars` | ~4906–4925 | `vars` has no impute (~4618–4624) | Include impute covariates; `setdiff(vars, mi_setup$variable)`. |
| `model.frame` na.action | `include_missing_response \|\| include_missing_predictor` → `na.pass` (~4942–4946) | only `include_missing_response` (~4643–4644) | **Load-bearing.** Without this, NA in `mi(x)` is dropped or errors. |
| After `y` assembled | `drm_build_gaussian_missing_predictor_model` + fill `mf_mu` + `mu_col` (~4985–5013) | none | Same. |
| `spec` list | `missing_predictor = missing_predictor` (~5050) | absent (~4701–4745) | Add the element. |
| After `spec <-` | `spec$start$beta_mi <- …` (~5071–5073) | none | Required or TMB has no `beta_mi` start. |
| `spec$missing_data` | `if (include_missing_predictor) … version = "MD-gamma-mi"` else response (~5074–5087) | response-only `"MR-T2-lognormal"` (~4746–4757) | Add predictor branch; version `"MD-lognormal-mi"`. |
| `spec$nobs` | `include_missing_response \|\| include_missing_predictor` (~5103) | response-only (~4762) | Same or. |
| Gate copy in `drmTMB()` | error strings name `Gamma(link = "log")` (~399, ~407) | still omit lognormal | Add `{.fn lognormal}` **when the allow-list opens**, not before. |
| `split_tmb_parameters()` | `"gamma"` added to mi-coef `if` (~21049–21052) | lognormal is in the **outer** family list (~20998) but **not** the mi-coef `if` | Add `"lognormal"` next to `"gamma"` or `coef(fit, "mi_*")` is missing and the logLik identity test cannot read `beta_mi`. Poisson/binomial have their own early returns (~20919–20946); lognormal does not. |

Do **not** edit `make_tmb_data()` / `make_tmb_data_core()` — they already
read `spec$missing_predictor` generically.

### 2c. Allow-list (after C++ + spec)

| File | Gamma #1088 | Lognormal |
|---|---|---|
| `R/missing-data.R` `drm_missing_predictor_families()` | `"gamma"` appended (~371–373) | Append `"lognormal"`. Today: `c("gaussian", "poisson", "binomial", "nbinom2", "beta", "gamma")`. |
| `R/missing-data.R` roxygen on `miss_control` / `impute_model` (~16–19, ~90–94) | named Gamma | Name `lognormal()`. |
| `R/drmTMB.R` `@param impute` (~137–139) | named Gamma | Name lognormal **as a response** (it is already listed as a *predictor* family for Gaussian responses). |

### 2d. Tests

| File | Gamma | Lognormal |
|---|---|---|
| **New** `tests/testthat/test-missing-predictor-lognormal-response.R` | `test-missing-predictor-gamma-response.R` (164 lines) | Mirror four `test_that` names (below). |
| `tests/testthat/test-missing-data-capability-gate.R` | `"gamma"` in `predictor_validated` (~26–28); lognormal stays in the impute-reject loop (~87) | Add `"lognormal"` to `predictor_validated`. **Remove** `"lognormal"` from `for (ft in c("tweedie", "lognormal"))` (~87) or the promotion test fights the leftover test. Leave tweedie (and student if you add it). |

**Test names to mirror** (keep the structure; fix the DGP):

1. `"binary mi() predictor works with a Lognormal response likelihood"`
   - Fixture n=90, deterministic `y = exp(eta + jitter)` (strictly
     positive; identity does not require y ~ lognormal).
   - `expect_equal(fit$missing_data$version, "MD-lognormal-mi")`.
   - Manual 2-point-sum logLik vs `logLik(fit)`, tolerance `1e-6`.
   - Manual density: `stats::dlnorm(y, meanlog = eta, sdlog = exp(log_sigma), log = TRUE)`
     **or** `dnorm(log(y), eta, exp(log_sigma), log = TRUE) - log(y)`.
     Do **not** call `dnorm(log(y), …)` without the Jacobian and then
     compare to TMB.
2. `"Lognormal-response mi() recovers the log-location, log-scale, and predictor model under MCAR"`
   - `set.seed(13)`, n=3000.
   - `y <- stats::rlnorm(n, meanlog = eta, sdlog = sdlog)` with
     `eta <- 0.4 + 0.5 * z + 0.7 * x`, `sdlog <- 0.3`.
   - Recover `coef(mu) = c(0.4, 0.5, 0.7)`, `coef(sigma) = log(0.3)`,
     `coef(mi_x) = c(0.3, 0.8)`, tolerance 0.15.
3. `"Lognormal-response mi() recovers under outcome-dependent MAR"`
   - `set.seed(21)`. MAR on `scale(log(y))` (Gamma used `scale(log(y))`
     too — keep that; do not MAR on raw y).
   - Same targets, tolerance 0.20.
4. `"Lognormal-response mi() still refuses a non-binary predictor"`
   - `impute_model(biomass ~ z, family = lognormal())` or
     `Gamma(link = "log")`.
   - `expect_error(..., "binary missing predictor")`.

Family in the fit call is `lognormal()`, **not** `Gamma(link = "log")`.

### 2e. Ledger (existing `missing_predictor` axis only)

| File | Gamma | Lognormal |
|---|---|---|
| `docs/dev-log/dashboard/capability-ledger/cells.tsv` | row `mp-gamma-bernoulli` source_order **735**, axis-local `model_type` **18**, `ev-mp-gamma-bernoulli-g3`, G3 `point_fit_recovery` | New last row: `mp-lognormal-bernoulli`, source_order **736**, axis-local `model_type` **19** (this column is the axis index, **not** C++ `4`). `family_route`/`family_type` = `lognormal`. `route_variant` = `bernoulli`. `route_modifier` = `one_binary_predictor`. `tranche_id` = `S6-A7-FAMILY-GATE`. `issue_url` = https://github.com/itchyshin/drmTMB/issues/962. Honest leftovers: not continuous predictor, not k≥2, not `impute_joint`, not FIML, not student/zi-*. Existing `mp-gaussian-lognormal` (lognormal **as predictor**) is unchanged. |
| `docs/dev-log/dashboard/capability-ledger/evidence.tsv` | `ev-mp-gamma-bernoulli-g3` | `ev-mp-lognormal-bernoulli-g3` pointing at the new test file. |
| `tools/capability_ledger.py` | `MISSING_PREDICTOR_COUNT = 19` (~278) | **20**. Comment: six one-binary response families + 13 Gaussian-catalogue + k2. |
| `docs/dev-log/dashboard/capability-ledger/schema.json` | `"missing_predictor": 19` | **20**. Gamma's CI failed when the row landed and the guard still said 18. |
| `tools/tests/test_capability_ledger.py` | runtime set gained `"gamma"`; family-map `"gamma"` → `"implemented"` / `"one binary"` (~2976–2987) | Add `"lognormal"` to the runtime set. Change the lognormal family-map assertion from rejected-by-gate to `"implemented"` + `"one binary"`. |
| Generated surfaces | `vignettes/includes/capability-ledger-*.md`, `capability-surface.html/md` | Regenerated by the ledger tool; do not hand-edit wording. |

`MISSING_PREDICTOR_RUNTIME_GATE["lognormal"]` is already `"lognormal"`
(~871). No map edit. Family-map wording flips automatically once the
runtime allow-list contains `lognormal`.

### 2f. Docs / man / NEWS

| File | Action |
|---|---|
| `NEWS.md` | New bullet: `lognormal()` + one binary `mi()`, C++ `has_mi` + leaf, ledger `mp-lognormal-bernoulli`, MCAR+MAR. **Not** FIML / `impute_joint` / k≥2 / continuous predictor. Student, beta_binomial, zi-* remain gated. |
| `man/drmTMB.Rd` `man/impute_model.Rd` `man/miss_control.Rd` | Refresh via `devtools::document()` after roxygen edits. Do not hand-edit Rd. |
| `LOOP/GOAL.md` `LOOP/arcs.md` `LOOP/checkpoint.md` `LOOP/ultra-plan.md` | Gamma #1088 rewrote these as lane-kit. **Not** required for the cell. Do not clone that rewrite. |

### 2g. C17 fingerprint (the #1088 CI foot-gun)

Touching `src/drmTMB.cpp` stale-dates C17/C14 tip blobs. Gamma needed a
follow-up commit (`0e6a4deb4` inside #1088): bump the axis count **and**
re-run the committed runner (`mean_tau_relative_error` bit-identical;
`source_fingerprint` left alone). Paths that moved in that follow-up:

- `docs/dev-log/dashboard/capability-census/_widget_data.json`
- `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv`
- `docs/dev-log/dashboard/capability-surface.html` / `.md`
- `docs/dev-log/implementation-recovery/2026-08-27-s6-a7-gamma-c17c2-c14-final-source-compatibility/`

If CI fails the same way, re-run that runner; do not invent a second
fingerprint story.

---

## 3. Still open on the dirty tree (sibling `67a70b94`, 2026-08-27)

Already looks right — do not revert:

- `src/drm_response_kernels.h` `case 4:` `dnorm(log_y, eta_val, exp(log_sigma_val), true) - log_y`
- `src/drmTMB.cpp` `model_type == 4` updates `mu` (log-location), clamp
  before `has_mi`, skip mask on the main loop
- `drmTMB()` switch passes `impute=`
- Spec signature + `mi_setup` + binary/FE/no-combo aborts + `mu_col`

**Still missing (easy to skip):**

1. `model.frame` na.action must be
   `include_missing_response || include_missing_predictor` → `na.pass`
   (currently still response-only at ~4683).
2. `spec$missing_predictor <- missing_predictor`.
3. `spec$start$beta_mi <- missing_predictor$beta_start`.
4. `spec$missing_data` predictor branch, `version = "MD-lognormal-mi"`.
5. `spec$nobs` or-in `include_missing_predictor`.
6. `split_tmb_parameters()` mi-coef `if` (~21113) add `"lognormal"`.
7. Test file + capability-gate list edits.
8. Allow-list `"lognormal"` (last).
9. Ledger row + count 19→20 in `.py` **and** `schema.json`.
10. NEWS + `document()`.

---

## 4. Pitfalls (engine)

1. **Log-location, not log-mean.** `lognormal()` links are
   `mu = identity`, `sigma = log`. Cloning `mu = exp(eta)` from Gamma
   (or Poisson) makes a wrong likelihood that can still "fit".
2. **Jacobian `-log(y)`.** Main loop and leaf must both carry it.
   `stats::dlnorm()` already includes it; `dnorm(log(y), …)` does not.
3. **`default:` returns 0.** A forgotten `case 4` is silent and biases
   every distribution-mediated missing-x contribution to zero.
4. **Skip mask.** Missing-x rows are scored in the 2-point sum only.
5. **DGP.** `rlnorm(meanlog = eta, sdlog = sdlog)`. Recover
   `coef(sigma) = log(sdlog)`, **not** Gamma's `log(CV)` with
   `rgamma(shape = 1/cv^2, scale = exp(eta)*cv^2)`. `y > 0` always.
6. **Allow-list last.** Gate copy in `drmTMB()` / `missing-data.R`
   roxygen can name lognormal in the same commit as the list append,
   not earlier.
7. **Ledger count in three places.** `MISSING_PREDICTOR_COUNT`,
   `schema.json` `expected_counts.missing_predictor`, and the new row.
8. **`coef(mi_*)`.** Without `split_tmb_parameters` lognormal in the
   mi-coef branch, recovery tests that read `coef(fit, "mi_x")` fail
   even when TMB is right.
9. **`na.pass` on `mi()` rows.** Without it, `model.frame` drops the
   incomplete predictor and you never reach C++.
10. **Poisson REPORT clone.** `log(E[exp(eta)])` is the wrong
    posterior location for a log-location family.

---

## 5. Out of scope (this cell)

- drmSEM consumer lift (`drm_impute_response_families()`, V-80). Separate
  PR after this engine cell is on `main`. Contract:
  drmSEM `LOOP/notes/A7-consumer-contract.md`.
- nbinom2 × Gaussian (expand an already-gated family). After this #962
  family unless Shinichi re-orders.
- student / beta_binomial / zi-* (`nu`, trials, extra dpar).
- k=2, `impute_joint`, FIML, capability `"covered"`.
- MAG / S3 grouping / `rho12`.
- Coefficient-product mediation (banned on drmSEM; this cell is engine
  observed-data likelihood only).

---

## 6. Smoke

```r
# After compile, on Totoro if multi-seed; laptop only for the n=90 identity.
testthat::test_file("tests/testthat/test-missing-predictor-lognormal-response.R")
testthat::test_file("tests/testthat/test-missing-data-capability-gate.R")
```

Identity first. MAR required to claim G3. MCAR-only is plumbing.
)
