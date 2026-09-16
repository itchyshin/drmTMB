# DRM.jl follow-ups from drmTMB Dinnage arc3 Wave A

**Status:** coordination list only (2026-09-16).  
**drmTMB pins:** Wave A merged on `origin/main` as PR [#1368](https://github.com/itchyshin/drmTMB/pull/1368) (A1 docs), [#1369](https://github.com/itchyshin/drmTMB/pull/1369) (A2 check/profile), [#1367](https://github.com/itchyshin/drmTMB/pull/1367) (A3 misc/TMB).  
**DRM.jl local path:** `/Users/z3437171/Dropbox/Github Local/DRM.jl` · remote `git@github.com:itchyshin/DRM.jl.git`.  
**Lane:** drmTMB has many active lanes (Codex/Cursor/Claude); **do not edit DRM.jl package code from this Cursor slice** unless Shinichi assigns the Julia lane. Codex typically owns Julia implementation.

**Purpose:** Map Russell Dinnage audit Wave A themes on the R/TMB twin to concrete DRM.jl gaps, existing issues, and proposed fixes so parity docs and the bridge do not certify stale or divergent behaviour.

---

## Wave A theme map (drmTMB → DRM.jl)

| Wave | drmTMB delivery | Twin surface on DRM.jl | Parity risk |
| --- | --- | --- | --- |
| **A1** | Doc-only fixes + `test-dinnage-audit-wave1.R` | Documenter pages, rosetta, bridge marshalling notes | Users follow R help and hit Julia refusals or different semantics |
| **A2** | `check_drm()` / `confint()` / `profile` behaviour (#1338, #1343) | `check_drm`, `confint`, `locscale_profile.jl`, bridge diagnostics export (#569) | Silent listwise loss of RE levels; wrong CI advice at `rho12` boundary |
| **A3** | REML summary honesty, phylo tip message, summary UX, TMB kernel/CondExp (#1367) | `summary`, structured phylo builders, native likelihoods (no CppAD CondExp) | Mis-labelled REML; phylo subsetting invisible; numeric drift vs bridge receipts |
| **Infra** | C17 capability ledger TSV, `env-skip-census.tsv`, `tools/source-tree-tests.txt` | `docs/dev-log/evidence/julia-r-parity/capability-manifest.json`, `test/runtests.jl` sharding | Scoreboard rows cite pre–Wave A R behaviour |

---

## Item list (fix proposals)

Severity: **P0** = breaks twin trust or certifies wrong agreement; **P1** = user-visible mismatch with R Wave A contract; **P2** = docs/process/ledger hygiene.

### A1 — documentation and grammar (`#1368`)

| ID | drmTMB ref | DRM.jl symptom / gap | Severity | DRM.jl issue | Proposed fix |
| --- | --- | --- | --- | --- | --- |
| JL-A1-01 | #1323 / Md-F — `mi()` family table | Julia joint/missing frontend is narrower (`joint_missing_frontend.jl`); rosetta does not mirror the new non-Gaussian `mi()` pass/fail table | P1 | [#49](https://github.com/itchyshin/DRM.jl/issues/49) (umbrella missing-data) | Add a **capabilities table** to Documenter (which families admit one binary missing predictor on `mu`) and a **`test/docs_dinnage_mi_table.jl`** that asserts the table matches drmTMB's audited list. |
| JL-A1-02 | #1334 / A-4 — `meta_V()` row order | R now documents positional matching explicitly; Julia already warns on subset-unsafe routes (`gaussian_core.jl` ~756) but **meta-analysis guide** does not state dimname/row-order contract as clearly as R | P1 | *(none)* | **New issue:** `docs: meta_V(v) matches rows by position, not dimnames (twin #1334)`. Update `docs/src/model-guides/meta-analysis.md` + rosetta warm-timing note. |
| JL-A1-03 | #1345 / Mi-7 — ordinal integers | `cumulative_logit` docs may not state integer-coded response requirement | P2 | *(none)* | Documenter sentence + link to drmTMB ordinal vignette; optional bridge refusal message if R sends non-integer. |
| JL-A1-04 | #1349 / Mi-11 — Student `sigma` semantics | Student scale vs SD interpretation must match R family help | P2 | [#721](https://github.com/itchyshin/DRM.jl/issues/721) (Student loglik bug, separate) | Doc fix independent of #721; add rosetta row "public `sigma` is scale, not marginal SD". |
| JL-A1-05 | #1359 / UX-4 — fully qualified `confint` `parm` | Julia `confint` naming may differ; cross-links in [#696](https://github.com/itchyshin/DRM.jl/issues/696), [#680](https://github.com/itchyshin/DRM.jl/issues/680) (404 profile article) | P2 | #696, #680 | Fix broken drmTMB profile URL in Documenter; document Julia `parm` symbol list vs R qualified strings. |
| JL-A1-06 | #1317 / S8 — REML `confint` caveat | REML mean-interval limitation not mirrored in Julia inference docs | P1 | #696 | Add REML bootstrap/profile boundary text beside `confint(...; method=:profile)` docs (same caveat as R: integrated mean coefs). |
| JL-A1-07 | #1320 / Md-C — `predict(type="response")` vs `E[Y]` | Predictor docs may imply response scale always equals mean | P2 | *(none)* | **New issue:** `docs: predict response scale vs fitted() mean (twin Md-C)`. |
| JL-A1-08 | #1341 / Mi-3 — DHARMa / `emmeans` | Julia path is **quantile residuals** (`test_quantile_residuals.jl`), not DHARMa | P2 | *(none)* | Documenter "DHARMa analogue" subsection pointing to quantile residuals; no new dependency. |
| JL-A1-09 | #1346 / Mi-8 — Pearson residual conventions | Family-specific Pearson defs may differ in edge cases | P2 | *(none)* | Add parity row to `tools/parity_fixture` or doc table for Student/skew-normal/beta. |
| JL-A1-10 | #1354 / Mi-16 — row-varying `sigma()` | Per-observation scale summaries; bridge may flatten | P1 | *(none)* | **New issue:** `accessor: sigma(fit) vector vs scalar summary (twin Mi-16)` + bridge export test. |
| JL-A1-11 | #1344 / Mi-6 (A1 half) — phylo branch-length scale | R `?phylo` now states no silent rescaling to unit height | P1 | [#732](https://github.com/itchyshin/DRM.jl/issues/732) (RE SD scale, related phylo) | Documenter: ultrametric branch lengths used as supplied; cross-link #732 for SD scale vs VCV reporting. |

### A2 — check, profile, ledger (`#1369`)

| ID | drmTMB ref | DRM.jl symptom / gap | Severity | DRM.jl issue | Proposed fix |
| --- | --- | --- | --- | --- | --- |
| JL-A2-01 | #1338 / A-8 — `groups_lost` under complete-case drop | `drm_listwise` / response NA drop report **row counts only** (`missing_data.jl`); no check for **empty RE grouping levels** after drop (drmTMB `check_drm()` `dropped_rows` now reports `groups_lost=`). `check_drm` is convergence/PD only (`inference.jl`), not a tabular fit audit | **P1** | *(none)* | **New issue:** `diagnostics: report grouping levels lost after listwise/NA response drop (twin #1338)`. Implement in `drm_listwise` warning and/or extend `check_drm` with optional `dropped_rows` fields; add `test/test_dinnage_listwise_groups_lost.jl` mirroring `test-dinnage-audit-wave4a.R`. |
| JL-A2-02 | #1343 / Mi-5 — `rho12` boundary CI messaging | At high \|ρ\|, profile ≈ Wald; R no longer tells users to switch to profile in boundary warning | **P1** | [#766](https://github.com/itchyshin/DRM.jl/issues/766) (profile abort, different failure mode) | Audit `confint` / Wald boundary warnings for `rho12`; align text with R (`check_rho12_boundary` message). Add focused test with simulated bivariate lognormal ρ≈0.95. |
| JL-A2-03 | C17 capability ledger rows touched in #1369 | drmTMB `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv` updated | **P2** | *(none)* | Regenerate or manually sync DRM.jl `capability-manifest.json` / parity scoreboard if any row boundary cites pre-A2 check behaviour. |
| JL-A2-04 | `control` / `keep_data` input-data checks (#1369 touches `R/control.R`, `R/drmTMB.R`) | Bridge may not surface whether fit retained original vs processed data for dropped-row audits | P2 | #569 | Extend bridge export with `nobs` / listwise metadata when R side adds `check_fit_input_data` patterns. |

### A3 — misc, phylo UX, TMB (`#1367`)

| ID | drmTMB ref | DRM.jl symptom / gap | Severity | DRM.jl issue | Proposed fix |
| --- | --- | --- | --- | --- | --- |
| JL-A3-01 | Md-I — `estimator_exact` in `summary()` | drmTMB distinguishes exact REML vs Laplace/Cox-Reid adjusted REML in summary messages; DRM.jl has `estim_method` but **no `estimator_exact` flag** or equivalent user-facing line | **P1** | *(none)* | **New issue:** `summary: state exact vs Laplace-adjusted REML (twin Md-I)`. Map routes: ordinary Gaussian RI REML vs sigma-RE / adjusted paths. |
| JL-A3-02 | Mi-6 — phylo extra tips pruned | R emits `"Pruning N phylogeny tip"` (`drm_phylo_tip_covariance`); **no matching user message** found in DRM.jl `src/` | **P1** | [#482](https://github.com/itchyshin/DRM.jl/issues/482) class (subset-safe phylo) | When species vector omits tips, `@warn` with count pruned (mirror R text); test with 5-tip tree and 4-species data. |
| JL-A3-03 | Mi-10 — `simulate()` restores RNG | `associate_pairs` / pair-simulation path on Julia side needs seed-restore contract if exposed | P2 | *(none)* | If Julia exports pair simulation, add seed test like `test-dinnage-audit-a3-misc.R`; else document "not exported". |
| JL-A3-04 | Mi-12 — shared O3 optim control | Internal AGHQ/O3 path; Julia has separate optimizer stacks | P2 | *(none)* | No code port; record in developer-notes that O3 tolerances are not R-identical. |
| JL-A3-05 | UX-2 / UX-3 — `summary` `nobs`, empty `$derived` | Verify `summary` prints `nobs` and redirects empty derived blocks to `$sdpars` | P2 | [#752](https://github.com/itchyshin/DRM.jl/issues/752), [#751](https://github.com/itchyshin/DRM.jl/issues/751) (summary gaps) | Close overlap with #752/#751; add explicit twin test for location-scale model with `sigma ~ x`. |
| JL-A3-06 | TMB CondExp / kernel edits in `src/drmTMB.cpp`, `drm_response_kernels.h` | **Native DRM.jl likelihoods do not share CppAD CondExp sites**; bridge `engine="julia"` unaffected. R **native TMB** engine changes can desync bridge receipts until re-measured | **P0** (bridge) | [#473](https://github.com/itchyshin/DRM.jl/issues/473) (provenance) | After drmTMB A3 merge: re-run pinned **`tools/parity_numeric.R` / warm-timing fixtures** and bump receipt pins; file DRM.jl issue if coef/logLik drift beyond tolerance on shared CSV cells. |
| JL-A3-07 | `associate-pairs` / Cox-Reid touch (`R/aghq-coxreid.R`, `R/associate-pairs.R`) | Julia `associate_pairs.jl` already staged; ensure sandwich metadata matches any R-side associate change | P2 | parity ledger `biv_associate` | One associate_pairs receipt row re-measured post-#1367. |

### Infra — census, manifests, env skips (drmTMB Wave A collateral)

| ID | drmTMB ref | DRM.jl symptom / gap | Severity | DRM.jl issue | Proposed fix |
| --- | --- | --- | --- | --- | --- |
| JL-INF-01 | `inst/extdata/env-skip-census.tsv` + `test-env-skip-census.R` | DRM.jl uses `test/runtests.jl` sharding, no skip census artefact | P2 | *(none)* | Optional: **manifest of `@test_broken` / `@test_skip`** in DRM.jl CI (pattern-only, do not copy R scanner verbatim). |
| JL-INF-02 | `tools/source-tree-tests.txt` manifest | drmTMB gates doc/example drift; DRM.jl has large `test/` tree without committed manifest | P2 | *(none)* | Consider `tools/source-tree-tests.jl --check` analogue for Documenter + `test/` inclusion list. |
| JL-INF-03 | DHARMa in drmTMB **Suggests** (#1341) | Julia stays dependency-free; quantile residuals are the twin | P2 | — | Document in rosetta only. |

---

## Comparator tests and benchmarks to add (DRM.jl)

1. **`test_dinnage_listwise_groups_lost.jl`** — MCAR response NA on 6 of 40 ids; assert warning or diagnostic mentions **6 levels lost** (JL-A2-01).
2. **`test_dinnage_rho12_boundary_message.jl`** — bivariate lognormal, ρ≈0.95; Wald boundary warning must **not** recommend profile-only path (JL-A2-02).
3. **`test_dinnage_reml_summary_exact.jl`** — Gaussian RI REML vs sigma-RE REML; summary text distinguishes exact vs adjusted (JL-A3-01).
4. **`test_dinnage_phylo_tip_prune_message.jl`** — species ⊂ tip labels; expect prune count in log (JL-A3-02).
5. **Receipt refresh job** — post–drmTMB `main` ≥ #1367, run existing `tools/parity_biv_meta.R`, `parity_campaign`, warm-timing subset; attach to DRM.jl check-log (JL-A3-06).

Do **not** copy drmTMB's CppAD CondExp enumeration test wholesale; Julia needs its own AD-safety audit (ForwardDiff/CHOLMOD routes already noted in `check_drm` warnings).

---

## Architecture: what drmTMB Wave A does *not* imply for DRM.jl

- **No literal port of `R/check.R` table** — keep Julia's struct-shaped `check_drm`; add fields instead of mirroring every S3 check row.
- **No CppAD CondExp parity** — A3 kernel work is TMB-specific unless a numeric mismatch appears on shared fixtures.
- **Docs-first A1** — many items are Documenter + rosetta synchronisation, not new likelihood code.
- **Wave 3 (not Wave A) still pending on R** — M1 weights×`mi()`, M2 clamped `sigma()` accessors: when those land on drmTMB `main`, schedule a **second** DRM.jl pass (Julia clamp semantics in kernels vs R TMB clamps).

---

## Novelty / claim hygiene

- Wave A does **not** justify claiming "full Dinnage audit parity" on DRM.jl; only the items above are in scope.
- Existing promotion language in `coordination-board.md` (REML #575, bridge scoreboard) remains valid but **must be re-measured** after A3 TMB numeric edits if receipts used `engine="tmb"` on R.
- Do not claim DRM.jl implements DHARMa; claim **quantile residuals** as the diagnostic twin.

---

## Proposed new GitHub issues (titles only — not filed from this doc)

1. `diagnostics: report grouping levels lost after listwise / response NA drop (twin drmTMB #1338)`
2. `confint: rho12 boundary warnings should not push profile when Wald matches (twin #1343)`
3. `phylo: warn when tip labels are pruned to match data (twin #1344 Mi-6)`
4. `summary: distinguish exact REML vs Laplace-adjusted REML (twin arc3 A3 Md-I)`
5. `docs: meta_V row-position contract and dimnames (twin #1334)`
6. `parity: refresh warm/bridge receipts after drmTMB arc3 A3 TMB merge (#1367)`

---

## Top 5 must-do DRM.jl follow-ups

1. **JL-A2-01 (P1)** — Listwise / NA-response diagnostics for **RE levels lost** (twin #1338); highest user harm if Julia silently fits on depleted groups.
2. **JL-A3-06 (P0 bridge)** — Re-run pinned parity receipts after drmTMB #1367 TMB/kernel merge; update provenance (#473).
3. **JL-A2-02 (P1)** — Align **`rho12` boundary CI messaging** with R Mi-5 (#1343); related to #766 but distinct.
4. **JL-A3-01 (P1)** — **REML summary honesty** (exact vs adjusted); prevents mis-reading REML fits on sigma-RE models.
5. **JL-A3-02 (P1)** — **Phylo tip pruning message** (Mi-6 behaviour half); pairs with A1 phylo branch-length docs (JL-A1-11).

---

## Sources consulted

- drmTMB `origin/main`: `tests/testthat/test-dinnage-audit-wave4a.R`, `test-dinnage-audit-a3-misc.R`, `NEWS.md` (0.7.1 arc3 A2 header).
- drmTMB PR bodies: #1368, #1369, #1367 (GitHub API).
- DRM.jl: `src/inference.jl` (`check_drm`), `src/missing_data.jl` (`drm_listwise`), `src/gaussian_core.jl` (meta_V / missing routes), `docs/src/model-guides/meta-analysis.md`.
- DRM.jl open issues sample: `gh issue list` (2026-09-16).
- Coordination: `docs/dev-log/coordination-board.md`, `docs/dev-log/correspondence/2026-09-15-russell-dinnage-response-map.md`.
