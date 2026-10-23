# IRC legacy-evidence audit — batch B

Cells: mc-0398, mc-0427, mc-0085, mc-0086. Lane:
`/Users/z3437171/local-scratch/lanes/drmTMB-interval-truth-audit`, branch
`claude/lane-irc-legacy-evidence`. Read-only against the checkout except this file.

All four cells sit at `evidence_tier = inference_ready_with_caveats` in
`docs/dev-log/dashboard/capability-ledger/cells.tsv`, each with exactly one
`evidence.tsv` row of `evidence_class = legacy_model_evidence`
(`reviewed_by = MR-T0 migration`, `review_date = 2026-07-11`, `run_id`/`command`/
`replicates` all blank).

---

## mc-0398 — nbinom2, dpar = sigma, fixed effect, univariate

**Class: (A) REAL RUN EXISTS — path is correctly wired; only the structured
provenance columns (`run_id`/`command`/`replicates`) are blank.**

- `cells.tsv` row: `family_route=nbinom2`, `dpar=sigma`, `effect_type=fixed`,
  `estimator=ML`. `claim_boundary` / `legacy_evidence_source`: "Wald
  scale-coefficient intervals calibrated —
  `docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot`
  (phase 2)".
- `evidence.tsv` row `ev-mc-0398-legacy`: `path_or_url` = the same directory,
  `result=imported`, `run_id`/`command`/`replicates` blank.
- **Deciding evidence** — the cited directory EXISTS on disk and its
  `phase2-results.tsv` contains a genuine coverage study for exactly this
  target (nbinom2 location-scale, `sigma` = `log_sigma` link coefficients),
  with the empirically-confirmed symbolic map `size = exp(-2·log_sigma)`
  documented in `README.md` before simulating (a lesson the file records: an
  initial `size = exp(+2·log_sigma)` guess gave coverage 0.000, caught by a
  smoke test). Quoted rows from
  `docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot/phase2-results.tsv`
  (`spec = nbinom2_ls`, Wald channel, `confint()`, 400 seeds/cell):

  | n | param | finite_rate | coverage | mcse | clears_094 |
  |---|---|---|---|---|---|
  | 150 | `fixef:sigma:(Intercept)` | 1 | **0.973** | 0.0082 | TRUE |
  | 150 | `fixef:sigma:x` | 1 | **0.955** | 0.0104 | TRUE |
  | 400 | `fixef:sigma:(Intercept)` | 1 | **0.960** | 0.0098 | TRUE |
  | 400 | `fixef:sigma:x` | 1 | **0.932** | 0.0125 | TRUE |
  | 800 | `fixef:sigma:(Intercept)` | 1 | **0.965** | 0.0092 | TRUE |
  | 800 | `fixef:sigma:x` | 1 | **0.955** | 0.0104 | TRUE |

- `phase2-driver.R` (same directory) is a real Totoro-run simulation script
  (`mclapply`, `set.seed`, `drmTMB(..., control = drm_control(se = TRUE))`,
  `confint(fit)`, per-seed containment) — not a fabricated table. `README.md`
  states the run context: "Totoro (90 cores, `OPENBLAS_NUM_THREADS=1`)".
- Git provenance: the directory is added by commit `651019fc1` (phase 1,
  2026-07-09 17:57) and `12de12d88` (phase 2, 2026-07-09 18:11); both are
  confirmed ancestors of the audit lane's `HEAD`
  (`git merge-base --is-ancestor <sha> HEAD` → true for both).
  `docs/dev-log/after-task/2026-07-09-v0.4.0-capability-honest-release-prep.md`
  also lists this directory under "Evidence" for that day's release-prep
  report, corroborating it is a landed, reviewed artifact, not an orphan.
- Cross-check against the sibling audit wave already on this branch
  (commit `9ee8c9fc4`, `scratchpad/uncovered-cohort-A.md`): mc-0398 is
  independently classified there as class **(b)** "Covered by stronger
  instrument… `path exists: yes`" — same conclusion from a shallower pass.

**Verdict nuance:** unlike mc-0085/mc-0086 below, `path_or_url` here is a real,
resolvable, correctly-cited path and the numbers in it match the claim text
almost verbatim ("scale-coefficient intervals calibrated"). The only gap is
that the evidence row itself never got `run_id`/`command`/`replicates`
populated — a metadata-completeness gap, not a broken or absent link.

---

## mc-0427 — poisson, dpar = mu, fixed effect, univariate

**Class: (A) REAL RUN EXISTS — same directory, same wiring quality as mc-0398.**

- `cells.tsv` claim_boundary: "Wald mean-coefficient intervals calibrated
  (finite-rate 1.0, near-nominal incl. low-count stress) —
  `docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot`".
- `evidence.tsv` row `ev-mc-0427-legacy`: same path, `run_id`/`command`/
  `replicates` blank, `result=imported`.
- **Deciding evidence — phase 1** (`results.tsv`, `bf(y ~ x)`, poisson, Wald
  `confint()`, 400 seeds):

  | n | param | finite_rate | coverage | mcse |
  |---|---|---|---|---|
  | 50 | `fixef:mu:(Intercept)` | 1 | 0.963 | 0.0095 |
  | 50 | `fixef:mu:x` | 1 | 0.953 | 0.0106 |
  | 150 | `fixef:mu:(Intercept)` | 1 | 0.955 | 0.0104 |
  | 150 | `fixef:mu:x` | 1 | 0.925 | 0.0132 |
  | 500 | `fixef:mu:(Intercept)` | 1 | 0.938 | 0.0121 |
  | 500 | `fixef:mu:x` | 1 | 0.930 | 0.0128 |

- **Deciding evidence — phase 2, "low-count stress"** (`phase2-results.tsv`,
  `spec = poisson_low`, base mean 1):

  | n | param | finite_rate | coverage | mcse |
  |---|---|---|---|---|
  | 150 | `fixef:mu:(Intercept)` | 1 | 0.950 | 0.0109 |
  | 150 | `fixef:mu:x` | 1 | 0.948 | 0.0112 |
  | 400 | `fixef:mu:(Intercept)` | 1 | 0.953 | 0.0106 |
  | 400 | `fixef:mu:x` | 1 | 0.960 | 0.0098 |
  | 800 | `fixef:mu:(Intercept)` | 1 | 0.940 | 0.0119 |
  | 800 | `fixef:mu:x` | 1 | 0.948 | 0.0112 |

  This is the exact "low-count stress" the claim_boundary text names.
- Same git provenance as mc-0398 (both phases land in the same two commits,
  both confirmed ancestors of HEAD). Same cross-check: cohort-A wave classifies
  mc-0427 as class (b), "path exists: yes".

---

## mc-0085 / mc-0086 — biv_gaussian, dpar mu1/mu2, `phylo` q2 slope pair

**Class: (A) REAL RUN EXISTS, NOT WIRED — `evidence.tsv`'s own `path_or_url`
does not resolve to any file; the real backing artifact lives elsewhere and
was found only by following the claim_boundary text into the dashboard/design
layer, not by following the evidence row itself.**

Per the task's steer, verified rather than assumed the sibling relationship:
mc-0085 (`dpar=mu1`) and mc-0086 (`dpar=mu2`) are confirmed to be the two
labelled endpoints of one `biv_gaussian()` q2 structured-slope block —
`primary_evidence_id`, `legacy_evidence_source`, and the full `claim_boundary`
prose are byte-identical between the two rows in `cells.tsv` (both cite
`cell_id=qseries_phylo_q2_mu1_mu2_one_slope`; formula
`phylo(0 + x | p | species, tree = tree)` in **both** `mu1` and `mu2`). So yes
— one campaign backs both cells, confirmed, not assumed.

- `evidence.tsv` rows `ev-mc-0085-legacy` / `ev-mc-0086-legacy`:
  `path_or_url = qseries_phylo_q2_mu1_mu2_one_slope` — this is **not a file
  path**, it is an internal cell-id/tag from the old
  `structured-re-q-series-support-cells.tsv` schema. Checked: no file or
  directory named `qseries_phylo_q2_mu1_mu2_one_slope` exists anywhere in the
  tree (`find . -iname "*qseries_phylo_q2_mu1_mu2*"` matches only unrelated
  `..._intercept` directories from a different cell). The evidence row's own
  `claim_boundary` field additionally appends the tag `fixture_not_coverage`
  — which, read literally, says the opposite of what the deeper evidence
  below shows (there **is** real coverage evidence, not just a fixture).
- **Following the tag `qseries_phylo_q2_mu1_mu2_one_slope` into the dashboard**
  (`docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`, matching
  row) gives the real claim: "Inference-ready: the DEFAULT
  `confint(method='wald')` now applies the simulation-calibrated bias+t
  correction to this location-axis structured-RE slope-only SD;
  engine-validated nominal-in-total coverage at the deployment default g=8
  (SR475, ~0.95 across providers) … source:
  `docs/design/219-structured-re-small-sample-bias-correction.md`".
- **`docs/dev-log/dashboard/structured-re-q-series-inference-evidence-summary.tsv`**
  row `qseries_inference_phylo_q2_mu1_mu2` gives the exact numbers verbatim:
  > "two SD endpoints, N=475 per endpoint; pooled all-provider N=1900 is
  > correction acceptance evidence only" / "all engine intervals finite in
  > the g=8 correction grid" / **"bias+t coverage 0.964 MCSE 0.009 for mu1:x;
  > 0.943 MCSE 0.011 for mu2:x; pooled all-provider 0.954 MCSE 0.005"** /
  > "supported withheld for measured right-tail miss asymmetry at SD about
  > 0.9" — `evidence_tier = inference_ready_with_caveats`, source
  > `docs/design/219-structured-re-small-sample-bias-correction.md`.
- **`docs/design/219-structured-re-small-sample-bias-correction.md`** (lines
  152–165) reproduces the same table under "Engine-validated coverage at the
  deployment default g=8 (fresh SR475 fits through `confint`, 4 certified
  cells;
  `docs/dev-log/simulation-artifacts/2026-06-27-bias-corrected-engine-coverage-g8/`)":

  | cell | n | Wald-z | bc + t | MCSE |
  |---|---|---|---|---|
  | phylo mu1:x | 475 | 0.895 | **0.964** | 0.009 |
  | phylo mu2:x | 475 | 0.876 | **0.943** | 0.011 |
  | pooled (4 cells incl. relmat) | 1900 | 0.884 | **0.954** | 0.005 |

- **Raw replicate-level receipt** —
  `docs/dev-log/simulation-artifacts/2026-06-27-bias-corrected-engine-coverage-g8/`
  EXISTS on disk (`replicates.tsv`, `results.log`, `multi-g-results.log`).
  `results.log` records, per target: `phylo mu1:x  parm=sd:mu:mu1:phylo(0 + x
  | p | species) truth=1.050` and `phylo mu2:x  parm=sd:mu:mu2:phylo(0 + x |
  p | species) truth=0.900`, and the summary table exactly matches the design
  doc: `phylo mu1:x  n=475  wald_z=0.895  bc+t=0.964  mcse_bc=0.0085`;
  `phylo mu2:x  n=475  wald_z=0.876  bc+t=0.943  mcse_bc=0.0106`. `replicates.tsv`
  has 1900 data rows (475 × 4 provider/target combinations; confirmed
  `awk -F'\t' '$1=="phylo" && $2=="mu1:x"'` → 475 rows, same for `mu2:x`), one
  row per seed with columns `provider, target, seed, truth, wald_lower,
  wald_upper, bc_lower, bc_upper, wald_contains, bc_contains` — this is
  genuine per-replicate interval-containment data, not a summary-only claim.
- A second, independent corroborating source at a different `g`:
  `docs/dev-log/dashboard/structured-re-slope-coverage-certification.tsv`,
  rows `cert_q2_slope_phylo_mu1_x_g32` / `cert_q2_slope_phylo_mu2_x_g32`:
  `n_groups=32, n_rep=500, wald_coverage=0.934/0.946, profile_coverage=
  0.948/0.956`, `evidence_url =
  docs/dev-log/simulation-artifacts/2026-06-27-slope-coverage-certification-g32`
  (directory exists, contains `cert-q2-g32/`), `linked_cell_id =
  qseries_phylo_q2_mu1_mu2_one_slope`.
- `docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv` also
  carries a row for `qseries_phylo_q2_mu1_mu2_one_slope` citing the same
  design doc as the "gaussian_inference_anchor" for the v1.0 ledger.
- Git provenance: `docs/design/219-...md` and the g8 replicates directory are
  added by commits `e89eb02f8` ("Engine-validate bias correction to nominal
  at g=8 (0.954); add literature + design note") and `62c6abda7` ("Bank
  engine bias-corrected coverage: all 4 providers nominal at g=8; g16/g32
  hold"); both confirmed ancestors of the audit lane's HEAD.

**Discrepancy worth flagging explicitly:** the sibling in-lane audit wave
already on this branch (commit `9ee8c9fc4`, `scratchpad/uncovered-cohort-A.md`,
line: `mc-0085 | inference_ready_with_caveats | c | Primary ev-mc-0085-legacy:
run_id/command/replicates blank | N/A`) classified mc-0085/mc-0086 as class
**(c)** "legacy import, no run behind it" and queued them for **rerun**
(`wave1-classification.json`, both IDs present in the `"rerun"` array). That
wave's method checked only the `evidence.tsv` row's own fields
(`path_or_url`, `run_id`, `command`, `replicates`) and, because `path_or_url`
here is a non-resolving tag rather than a path, correctly found nothing
*at that row*. It did not follow the tag into
`structured-re-q-series-support-cells.tsv` →
`structured-re-q-series-inference-evidence-summary.tsv` → `docs/design/219` →
the raw `2026-06-27-bias-corrected-engine-coverage-g8/replicates.tsv`, where
a real N=475×2-endpoint (plus a g=32 N=500×2 corroborating grid) interval
coverage study for exactly `phylo mu1:x` / `mu2:x` does exist, on disk, in
git history, ancestors of HEAD. **This batch's finding (real run exists,
mis-wired citation) supersedes cohort-A's "class c / rerun" placement for
these two cells** — not because the earlier pass was wrong about the
`evidence.tsv` row (it was right: that row is empty and points nowhere), but
because "no run behind the *row*" is not the same claim as "no run exists
anywhere," and a real one does.

**Caveat inherited from the source doc itself (not new):** the g=8/g=32
coverage above is for the calibrated bias+t interval channel, is a
per-endpoint SD result (not the correlation), and doc 219 states the
correction is "calibrated per model class… validated for the q2 mu-slope SD
cells (phylo/relmat) at g=8/16/32. Other cells/designs must be re-validated."
This matches, rather than contradicts, the `inference_ready_with_caveats`
(not `supported`) tier already on the ledger.

---

## Queries run (verbatim, in order)

1. `awk` pulls of the full `cells.tsv` and `evidence.tsv` rows for all four
   cell IDs.
2. `ls` / `test -e` on
   `docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot/`
   (the task's named lead) — confirmed present; read `README.md`,
   `results.tsv`, `phase2-results.tsv`, `driver.R`, `phase2-driver.R` in full.
3. `git log --all --oneline --follow -- docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot/`
   → `651019fc1`, `12de12d88`; `git merge-base --is-ancestor <sha> HEAD` for
   both → true.
4. `grep -rl "nongaussian-unstructured-coverage-pilot"` over
   `docs/dev-log/after-task/` and `docs/dev-log/check-log.md`.
5. `git log --all --oneline -S"qseries_phylo_q2_mu1_mu2_one_slope"` over the
   whole ref-space (30 hits); `git merge-base --is-ancestor` checks on the
   relevant ones (`9ae75bf17`, `464e90215`, `5c1008ec6`, `25b92a985`,
   `15d4412ba` — all ancestors of HEAD).
6. `grep -r "qseries_phylo_q2_mu1_mu2_one_slope"` across the working tree
   (29 files); read the matching row in
   `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv` and
   `docs/dev-log/dashboard/structured-re-slope-coverage-certification.tsv`
   in full.
7. `find . -iname "*qseries_phylo_q2_mu1_mu2*"` and
   `test -e "qseries_phylo_q2_mu1_mu2_one_slope"` — confirmed the
   `path_or_url` string in `evidence.tsv` does not resolve to any file.
8. `grep -i "phylo"` /
   `grep -i "SR475"` sweeps of `docs/dev-log/dashboard/*.tsv` →
   `structured-re-q-series-inference-evidence-summary.tsv`,
   `structured-re-q2-slope-bias-t-coverage-evidence.tsv` (checked: covers
   spatial/animal only, not phylo — not a match for these two cells),
   `structured-re-q-series-v1-release-ledger.tsv`.
9. `grep -n "phylo\|mu1:x\|mu2:x\|0.9..."` in
   `docs/design/219-structured-re-small-sample-bias-correction.md`; read
   lines 130–185 in full.
10. `ls` + read
    `docs/dev-log/simulation-artifacts/2026-06-27-bias-corrected-engine-coverage-g8/`
    (`replicates.tsv` head + full column list, `results.log`,
    `multi-g-results.log`); `wc -l` and `awk` row-counts by
    provider/target; `git log --all --oneline` + `merge-base --is-ancestor`
    for `62c6abda7` / `e89eb02f8` → both ancestors of HEAD.
11. `ls docs/dev-log/interval-feasibility/` and
    `ls docs/dev-log/interval-campaign-bindings/`; grepped
    `^mc-0085|^mc-0086` across all interval-campaign-bindings TSVs (no hit);
    read `2026-07-28-phylo-q2-canonical-registry.tsv` in full — covers
    `mc-0083/mc-0084/mc-0208/mc-0209` (q2 **intercept**, ML/REML fixture
    cohort), a *different* cell pair from mc-0085/mc-0086 (which are the
    **slope**-only pair) — not a match, noted to avoid false-positive reuse.
12. `grep "^mc-0398\|^mc-0427\|^mc-0085\|^mc-0086"` against
    `c14-candidate-evidence-manifest.tsv` and
    `c16-source-bound-evidence-manifest.tsv` — no hits (those manifests cover
    a different cell subset).
13. `git log --all --oneline -S"mc-0398"` / `-S"mc-0427"` (timed out on the
    full -S sweep for mc-0085/mc-0086 specifically; not re-run given the
    tag-based search in query 5–6 already found the load-bearing evidence).
14. Discovered and read the sibling in-lane audit wave already committed on
    this branch: `git show --stat 9ee8c9fc4`, then
    `git show 9ee8c9fc4:scratchpad/wave1-classification.json` (parsed with
    `python3 -m json`) and
    `git show 9ee8c9fc4:scratchpad/uncovered-cohort-A.md` — cross-checked its
    per-cell classification against this batch's independent findings (see
    "Discrepancy worth flagging" above for mc-0085/mc-0086; mc-0398/mc-0427
    agree).

## Not established

- No `run_id` or `command` was ever recorded for any of the four legacy
  evidence rows themselves; that gap in `evidence.tsv` is real and confirmed,
  regardless of whether a backing artifact exists elsewhere.
- Whether the g=8 phylo mu1:x/mu2:x run (`2026-06-27-bias-corrected-engine-coverage-g8`)
  used exactly `n_each=?`/design matching mc-0085/0086's implicit "univariate
  dimension per endpoint" framing in `cells.tsv` was not re-derived from the
  simulation code itself (no driver script was found alongside
  `replicates.tsv`/`results.log` in that directory — only the two log files
  and the replicate table). The doc-219 prose and dashboard summary describe
  the design (SR475, deployment g=8, bias+t correction) but I did not locate
  the generating R script to re-verify the DGP independently the way
  `phase2-driver.R` allowed for mc-0398/mc-0427. NOT ESTABLISHED beyond what
  the log files and design doc state.
