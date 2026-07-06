# M5 Row 105 — simultaneous multi-provider structured count mu: GREEN plan

Meta: 2026-07-05 · Claude (Shannon) · continues the Q-Series 104/104 arc after M3
(q12, merged `7817a99e`, 102/104). Row 105 = `qseries_count_mu_simultaneous_
structured_types_rejected`, first of the 2 non-Gaussian rows toward 104.

## Admission target (RED, pinned)

`tests/testthat/test-count-multiprovider-structured-mu.R` (currently RED): a
CROSSED site×id NB2 model

    y ~ x + spatial(1 | site, coords = coords) + relmat(1 | id, Q = Q)

must BUILD and surface both structured fields — `sdpars$mu` =
{`spatial(1 | site)`, `relmat(1 | id)`}, `ranef()` includes `spatial_mu` +
`relmat_mu`, both direct profile targets. Recovery of both known variance
components under the crossed (identifiable) design is the admission bar.
`pdHess=FALSE` is OK (profile/bootstrap; ELR excluded — locked doctrine). STAN
cross-check is the M5 target.

## Confirmed recon (why this needs C++)

- **Guards (pre-optimization):** `select_count_mu_structured_term`
  (`R/drmTMB.R:7013`) aborts on `>1` structured type; Gaussian analogue
  `R/drmTMB.R:2582`.
- **Single-field architecture end-to-end:** `mu_structured_term` (singular)
  threads the count assembly (`R/drmTMB.R:5094` Poisson, `5464`/`5647` NB2);
  `build_structured_mu_structure` (`9489`) builds ONE `phylo_mu` field per model.
- **C++ declares a SINGLE structured group precision:**
  `DATA_SPARSE_MATRIX(Q_phylo)` + `DATA_SCALAR(log_det_Q_phylo)` +
  `PARAMETER_VECTOR(u_phylo)`/`log_sd_phylo`/`theta_phylo`
  (`src/drmTMB.cpp:340-405`; grep count of `Q_phylo` matrix = 1). The
  `phylo_mu_block_id`/`phylo_mu_n_blocks` fields are multiple ENDPOINTS within
  ONE provider (how q6/q8/q12 share one group precision), NOT two providers.
- **Therefore:** spatial + relmat carry DIFFERENT group precisions (coord kernel
  vs `Q`), so the C++ needs a SECOND structured field. NOT R-assembly-only.

## Slices

1. **[DONE]** RED build test + crossed DGP (`test-count-multiprovider-structured-mu.R`).
2. **R-assembly** — relax both guards for the spatial+relmat combo; assemble TWO
   `phylo_mu`-style structures + a SECOND group precision + parameter set into the
   count TMB data; disambiguate `ranef`/`sdpars`/`profile_targets` naming (avoid
   the `log_sd_phylo` collision). *[Claude: R refactor + parse/build tests]*
3. **C++** — add a second structured field (`Q_phylo2`, `u_phylo2`,
   `log_sd_phylo2`, `theta_phylo2`, `phylo_mu2_*` metadata) contributing to the
   count `eta` + joint nll; reuse the separable/penalty kernels per field;
   recompile. *[Codex lane: live TMB compile + real NB2 fits]*
4. **Recovery ladder** — crossed n up; both variance components recover; cap-sat
   guard; streamed per fit. *[Claude R sims]*
5. **STAN cross-check** (brms/Stan) — the M5 bar; must match drmTMB. *[Codex/Claude]*
6. **Status admission** (AFTER the rename chip lands + sync `main`): flip row 105
   `unsupported`→`point_fit`; regenerate sidecars + 4 gates + conversion test;
   4-lens gate (Curie/Noether/Fisher/Rose) → **103/104**.

## Coordination (concurrent rename chip, task_79a14cc2)

Chip owns: cell_id rename, README/ROADMAP backfill, `validate-mission-control.py`,
dashboard/sidecar TSVs, `test-structured-re-conversion-contracts.R`. M5 engine
work stays on `R/drmTMB.R` + `src/drmTMB.cpp` + the new test + sims ONLY. Defer
slice 6 (status) until the chip merges + `git pull` `main`, so M5 adopts the
renamed `_q12_all_four_two_slope` keys instead of the stale `_q8_planned` ones.

## Open decisions / risks

- **Execution split:** R-assembly (2) = Claude; C++ (3) + real fits = Codex lane
  (per the Claude/Codex division of labour), or Claude drives inline. Maintainer
  to steer.
- **Generalize to N fields vs a scoped 2nd field:** prefer a clean 2-field
  generalization if the C++ index surgery stays bounded; else a scoped second
  field for this cell.
- **Separability risk:** if site and id are not genuinely crossed in the DGP the
  two fields confound — the crossed `expand.grid(site, id, rep)` design guards it.
