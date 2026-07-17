# After Task: Beta phylogenetic q1 direct-SD interval + coverage promotion (mc-0017)

## 1. Goal

Give the Beta phylogenetic q1 **direct latent-SD regression** route (cell `mc-0017`)
its first interval-and-coverage evidence and, if it clears a pre-registered gate under a
fresh D-43 review, promote it from `point_fit_recovery` to `inference_ready_with_caveats`
over the exact proven `g = 1024, m = 4` domain — or return a rigorous documented
non-promotion. This is the campaign named by mc-0017's own `next_gate`.

## 2. Implemented

- **S0 — estimand freeze** (`docs/dev-log/2026-07-17-beta-phylo-q1-coverage-estimand-alignment.md`):
  declared the coverage estimand as the two FIXED direct-SD regression coefficients
  `alpha_0 = log(0.30)` (log-baseline latent SD) and `alpha_1 = 0.25` (latent-SD slope) on the
  log-SD link scale; Wald + profile side by side; a precedent-anchored calibration gate; a
  finite-profile exclusion policy; the seed-reuse policy; the exclusion fence.
- **S1 — probe**: `confint(method="profile")` returns finite, in-range intervals for the tau
  coefficients with no new plumbing; full-curve `tmbprofile` costs ~24 min/fit at g=1024
  locally (~5.8 min on fir), while Wald is free and **numerically indistinguishable from
  profile** for these unbounded coefficients.
- **S2 — coverage harness** (`tools/run-beta-phylo-q1-sd-coverage.R` + test): additive,
  crash-safe, resumable; reused the interior-DGP runner's DGP/fit/seed grid; scores Wald +
  profile coverage per coefficient with exact-binomial CIs, directional misses, finite-profile
  rate, and a phylogenetic-structure summary.
- **S3 — campaign**: DRAC/fir SLURM array (job 49348332, `%400`), full 12-cell grid
  `{distinct,shared} × g{256,512,1024} × m{2,4}`, N=1200/cell, profile + Wald; 0 task failures;
  fir build reproduced local fits to ~1e-4/1e-5. Evidence retained under
  `docs/dev-log/simulation-artifacts/2026-07-17-beta-phylo-q1-coverage/fir-campaign/`.
- **S4 — D-43 review**: round 1 withheld (2 NOT-DONE) — the claim wasn't drafted and had
  presentation gaps + two pre-existing ledger-hygiene bugs; round 2 passed after corrections
  (Fisher DONE, Rose DONE, Noether's single hygiene defect fixed).
- **S5 — promotion**: `mc-0017` → `inference_ready_with_caveats` in the ledger, with new
  `evidence.tsv`/`transitions.tsv` rows and a regenerated capability surface.

## 3. Mathematical Contract

DGP (unchanged interior-DGP lineage): for observation `i` in species `s`,
`logit(mu_i) = beta_0 + beta_1 x_mu,i + a_{s(i)}`, `log(sigma_i) = gamma_0 + gamma_1 x_sigma,i`
with Beta precision `phi_i = sigma_i^{-2}`, and `log(tau_s) = alpha_0 + alpha_1 x_tau,s`,
`a ~ N(0, D_tau A D_tau)`, `D_tau = diag(tau_s)`, `A` the phylogenetic correlation.

The coverage estimand is `alpha_0, alpha_1` (fixed coefficients of the `sd(spp_id,
level="phylogenetic") ~ x_tau` linear predictor) — NOT Beta family sigma/phi, which is a
structurally separate target. The CI is scored on the link scale against the fixed truths
`log(0.30)` and `0.25` with no back-transform. Because these are fixed coefficients (not a
realised random-effect SD), there is no realised-vs-population ambiguity — the Arc 4a
mean-centring trap does not apply here.

## 3a. Decisions and rejected alternatives

- **Venue = DRAC/fir, not Totoro.** ~1000 core-hours is a DRAC-shaped job; fir was reachable,
  ~4× faster per profile, and spared the shared lab server. Gated by a reproducibility check
  (fir vs local to 1e-4) so the evidence is numerically consistent with the point campaign.
- **Full 12-cell N=1200** (not a reduced Totoro run): fir's speed made the thorough grid cheap;
  N=1200 matches Arc 4a's MCSE (~0.006–0.007).
- **Calibration gate = precedent-anchored [0.925, 0.975] CI overlap**, NOT "CI overlaps 0.95".
  The plan-review caught that the stricter rule contradicted the very `inference_ready_with_caveats`
  precedent it invoked (`mc-0382` was promoted with sub-nominal arms). Frozen pre-campaign.
- **Profile is not asserted superior**; Wald ≈ profile is reported as an observation.

## 4. Files Changed

- New: `tools/run-beta-phylo-q1-sd-coverage.R`,
  `tests/testthat/test-beta-phylo-q1-sd-coverage-runner.R`,
  `docs/dev-log/2026-07-17-beta-phylo-q1-coverage-estimand-alignment.md`,
  `docs/dev-log/simulation-artifacts/2026-07-17-beta-phylo-q1-coverage/` (S1 probe report +
  `fir-campaign/` summary, raw, seed-audit, build-repro, s3-launch).
- Ledger: `docs/dev-log/dashboard/capability-ledger/{cells.tsv,evidence.tsv,transitions.tsv}`
  (mc-0017 promotion; mc-0676 + transitions/evidence hygiene fixes) + regenerated derived
  outputs (capability-surface `.md`/`.html`, census `_master`/`beta`, family-map vignette
  include); `tools/tests/test_capability_ledger.py` (updated expectations).
- **R package source (`R/`, `NAMESPACE`, `man/`) was NOT changed** — the profile machinery
  already existed on `main`.

## 5. Checks Run

- Coverage runner test (`test-beta-phylo-q1-sd-coverage-runner.R`): 15/15 blocks pass, 0 fail.
- `python3 tools/capability_ledger.py --check`: OK (30 generated outputs).
- `python3 -m unittest tools.tests.test_capability_ledger`: 37/37 pass.
- `pkgdown::check_pkgdown()`: no problems.
- `git diff --name-only origin/main -- R/ NAMESPACE man/`: empty → `--as-cran` not required.
- fir reproducibility gate (`build-repro.md`): fir vs local agree to ~1e-4/1e-5, conv=0, pdHess.
- Seed audit sha256 `1c67e66be2e348efc565ace523e84cae017a5e3845747b25ebd7da49dfbf33f6`.

## 6. Tests of the Tests

The coverage indicator, exact-binomial CI, and directional-miss helpers were unit-tested on
synthetic inputs (no live fit). The S1 probe's numbers were independently reproduced
bit-for-bit by the S2 harness on the same seed. Two D-43 reviewers (Fisher, Rose)
independently recomputed the promotion-arm Clopper–Pearson CIs in R from raw hits/N rather
than trusting the pipeline's own columns; Rose re-derived the seed-audit sha256 by hand.

## 7a. Issue Ledger

No GitHub issue was opened or closed. Issue #682 (broad profile-likelihood methods) remains the
coherent home for future profile-interval work; this arc is carried by its own PR.

## 8. Consistency Audit

The claim_boundary leads with the worst-in-arm result, names both exact arms, discloses the
finite-profile exclusion and the seed correlation, cites the effective-N, and lists the §9
fence verbatim. A pre-existing ledger drift — `mc-0676`, `transitions.tsv:737`, and
`evidence.tsv` describing mc-0017 as a "constant-latent-SD exception" (stale since mc-0017 is
now a *slope* regression) — was found by the D-43 panel and corrected in all three live rows;
a repo-wide grep confirms zero remaining contradictions, and the three dated 2026-07-16
historical dev-log files were correctly left as frozen record.

## 9. What Did Not Go Smoothly

- A Bash/Agent safety classifier ("claude-opus-4-8 temporarily unavailable") was intermittently
  down all session, forcing many retries.
- fir's BLAS is **FlexiBLAS**, not OpenBLAS — `OPENBLAS_NUM_THREADS=1` is silently ignored;
  the first fit oversubscribed 65 threads and hung. Fixed by pinning
  `OMP/FLEXIBLAS/BLIS_NUM_THREADS=1` + `--cpus-per-task=1` on every array task.
- The initial coverage gate was drafted too strict (CI-overlap-0.95); the members' plan-review
  caught the contradiction with the `inference_ready_with_caveats` precedent before compute ran.
- D-43 round 1 correctly withheld because the claim_boundary hadn't been drafted before review
  (process-ordering error); the draft agent then left a stale "intercept-only" adjective that
  round 2's Noether caught.

## 10. Known Residuals / Limitations

The promotion covers exactly the two `g=1024, m=4` arms (distinct + shared), profile method,
N=1200, at the frozen alpha truths. Coverage is **nominal-to-mildly-anti-conservative** (worst:
shared-arm intercept 0.9333, CI 0.9176–0.9467); the regression **slope is nominal in both
arms**. The phylogenetic effective sample size is low (~2.3 despite g=1024). Excluded: q>1;
family-sigma phylogeny; random/hierarchical RHS in `sd()`; labels/slopes; REML; missing routes;
other families; a coverage-*correcting* estimator; neighbouring SDs/species counts;
`supported`/nominal claims; the `shared_g256_m02` HOLD (descriptive-only, never pooled); the
stopped campaign `1c9bfd5f`; PR #788. Coverage/point-recovery share seeds (reps 1–400) → they
are correlated, not independent, evidence.

## 11. Team Learning

- **Freeze the coverage gate against the tier's own precedent before the campaign**, not against
  a stricter tier's rule — a members' plan-review before compute catches this cheaply.
- **A cross-machine campaign needs a reproducibility gate AND a BLAS-family check** — FlexiBLAS
  ignores `OPENBLAS_NUM_THREADS`; verify thread-pinning actually took before scaling.
- **Draft the actual claim text before dispatching the D-43 review** — a review of an
  undrafted claim correctly defaults to NOT-DONE.
- **When correcting stale ledger prose, substitute the phrase, don't append** — appending left
  a self-contradiction ("intercept-only … intercept plus slope").

## 12. Cross-Product Coverage

This arc covers profile+Wald interval calibration for the two fixed direct-SD coefficients on
the two g=1024,m=4 arms only. It does NOT cover other g/m designs (context cells give the
trend only), other families, structured/labelled/slope sd() effects, REML, or any package-wide
inference promise. The natural sibling follow-on is **Gamma sigma-random-intercept coverage**
(`mc-0242`), which reuses this exact methodology.

## 13. Next Actions

1. Open one successor PR for this arc (do NOT merge).
2. Broader coverage/bias evidence (other predictor designs, g/m away from the exact arms, or a
   bias-corrected interval) before any expansion beyond the tested domain or tier.
3. `reviewed_by`/`review_date` on `ev-mc-0017-arc-coverage` remain "pending" until the PR review
   ratifies the promotion.
