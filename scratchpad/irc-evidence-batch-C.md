# IRC legacy-evidence audit — batch C (mc-0153, mc-0154, mc-0272, mc-0276)

Lane: `drmTMB-interval-truth-audit` @ `claude/lane-irc-legacy-evidence`, HEAD `302ac2579`
(`origin/main`). Read-only except this file.

**Headline: all four cells are class (A) — a real, reviewed, mainline-committed run
backs the interval/coverage claim, but the capability-ledger's `evidence.tsv` row is an
unwired stub (`legacy_model_evidence`, no `run_id`/`command`, `path_or_url` is a bare
legacy token, not a file path).** A prior Wave-1 pass on this same lane
(`9ee8c9fc4`) classified all four as class **(c)** ("legacy import with no run") purely
from the blank `run_id`/`command`/`replicates` fields in `evidence.tsv` — that
classification is **wrong** for these four cells once the dashboard/design-doc/git-log
trail is followed. See §5.

---

## mc-0153 / mc-0154 — biv_gaussian mu1/mu2 relmat q2 slope-only SD

**Class: (A) REAL RUN EXISTS, NOT WIRED**

`cells.tsv` `legacy_evidence_source` / evidence.tsv `path_or_url` for both cells is the
token `qseries_relmat_q2_mu1_mu2_one_slope`. That token is a real `cell_id` in
`docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`, current row:

```
qseries_relmat_q2_mu1_mu2_one_slope ... interval_status=inference_ready
coverage_status=inference_ready ... evidence_url=docs/design/219-structured-re-small-sample-bias-correction.md
"Inference-ready: the DEFAULT confint(method='wald') now applies the simulation-calibrated
bias+t correction ... engine-validated nominal-in-total coverage at g=8 (SR475) plus a
second grid (near-boundary conservative, extra g, one-sided rates) ... interval reliability
rung passed. supported is WITHHELD: residual right-tail miss asymmetry and g-dependent
under-correction (g=12 ~0.93) ..."
```

Deciding evidence, all EXISTS on disk (checked):

1. **Primary coverage run** — `docs/design/219-structured-re-small-sample-bias-correction.md`
   §Evidence, "Engine-validated coverage at the deployment default g=8", table sourced
   from `docs/dev-log/simulation-artifacts/2026-06-27-bias-corrected-engine-coverage-g8/`
   (EXISTS: `results.log`, `multi-g-results.log`, `replicates.tsv` = 1900 data rows + header
   = 475 reps x 4 cells [phylo mu1:x, relmat mu1:x, phylo mu2:x, relmat mu2:x]).
   Quoted verbatim from `results.log`:
   ```
   cell                 n   wald_z     bc+t  mcse_bc
   phylo mu1:x        475    0.895    0.964   0.0085
   relmat mu1:x       475    0.893    0.964   0.0085
   phylo mu2:x        475    0.876    0.943   0.0106
   relmat mu2:x       475    0.874    0.945   0.0104
   POOLED  n=1900  wald_z=0.884  bc+t=0.954  (mcse 0.0048)
   ```
   This is the exact source of the "0.95 across providers" / "nominal-in-total coverage at
   g=8" claim. `multi-g-results.log` in the same dir also gives g=16 (bc+t 0.954, pooled
   n=1200) and g=32 (bc+t continuing to nominal).

2. **"Second grid" (near-boundary + extra g + one-sided rates)** —
   `docs/dev-log/simulation-artifacts/2026-06-27-bias-corrected-secondgrid/results.log`
   (EXISTS). Quoted verbatim:
   ```
   === (a) NEAR-BOUNDARY small-SD truth (0.35), g=8 ===
   phylo mu1:x   g=8  truth=0.35  n=300  cov=0.963  miss_below=0.027  miss_above=0.010
   relmat mu1:x  g=8  truth=0.35  n=300  cov=0.970  miss_below=0.027  miss_above=0.003
   === (b) original truths, extra g (6, 12) + one-sided misses ===
   relmat mu1:x  g=12 truth=1.05  n=300  cov=0.930  miss_below=0.057  miss_above=0.013
   ```
   This is the exact source of the claim_boundary's "g=12 ~0.93" residual-under-correction
   caveat.

3. **Interval-reliability rung** —
   `docs/dev-log/after-task/2026-06-27-interval-reliability-rung.md` (EXISTS), computed
   from the g=32 certification replicates in
   `docs/dev-log/simulation-artifacts/2026-06-27-slope-coverage-certification-g32/cert-q2-g32/`
   (EXISTS: `01-phylo-mu1_x-{summary,replicates}.tsv`,
   `09-relmat-mu1_x-{summary,replicates}.tsv`, `10-relmat-mu2_x-{summary,replicates}.tsv`,
   etc.). Table row for `relmat mu1:x`: finite 100%, width CV 0.13, symmetry 1.51, profile
   cov 0.950 — passes Fisher's pre-specified interval-reliability bar.
   `docs/dev-log/dashboard/structured-re-slope-coverage-certification.tsv` also carries this
   g=32 grid machine-readably (`cert_q2_slope_relmat_mu1_x_g32`: wald_coverage 0.94,
   profile_coverage 0.95, 500 reps, `evidence_url=docs/dev-log/simulation-artifacts/2026-06-27-slope-coverage-certification-g32`,
   `linked_cell_id=qseries_relmat_q2_mu1_mu2_one_slope`).

4. **The promotion itself is a real, reviewed, mainline commit** —
   `git log` on `structured-re-q-series-support-cells.tsv` shows commit `9ae75bf17`
   "Promote phylo/relmat q2 mu-slope cells to inference_ready (interval + coverage)"
   (2026-06-27, author Shinichi Nakagawa). `git merge-base --is-ancestor 9ae75bf17 HEAD`
   → **is an ancestor of the current checkout**. Commit body: "The default bias+t
   correction (commit 484c0d0d) gives nominal-in-total coverage at the deployment default
   g=8 via the DEFAULT confint() -- engine-validated SR475 across all four providers
   (0.94-0.97), with a second grid ... supported is WITHHELD (held the bar): residual
   ~6:1 right-tail miss asymmetry ... + g-dependent under-correction (relmat g=12 ~0.93)."
   This text is reproduced near-verbatim in mc-0153/mc-0154's `claim_boundary` in
   `cells.tsv` — i.e. the migration DID capture the right substance, it just didn't wire
   a machine-readable `evidence.tsv` row (`run_id`, `command`, `path_or_url` as a real
   path) pointing at any of files 1-3 above.

**On the `fixture_not_coverage` suffix in evidence.tsv**: this string is carried forward
faithfully from the support-cells.tsv `denominator_policy` column, which did **not**
change across the promotion diff (`git show 9ae75bf17` — the column is `fixture_not_coverage`
both before and after). It labels what the row's single `evidence_url` field points to
(a fit/extractor fixture-parity file, `structured-re-q2-slope-parity-fixture.tsv`), not an
absence of coverage evidence — the coverage evidence is named in the claim_boundary prose
and lives in the separate files verified in items 1-3, confirmed to exist with real
per-replicate data. This is a ledger-schema quirk (one `evidence_url` slot, prose citing a
second source), not a fabricated claim, but it does explain why a shallow evidence.tsv
read looks like "no run."

**Mc-0153 vs mc-0154 (mu1 vs mu2)**: NOT identical evidence — the same campaigns fit both
endpoints in the same run (`phylo/relmat mu1:x` and `mu2:x` are separate columns/targets in
every file above), so the two cells share a run but are not literally the same number
(mu1:x bc+t 0.964, mu2:x bc+t 0.943, pooled 0.954, per item 1 table).

---

## mc-0272 — gaussian mu, phylo q1, intercept-only

**Class: (A) REAL RUN EXISTS, NOT WIRED**

`legacy_evidence_source` = `qseries_phylo_q1_mu_intercept`. Current
`structured-re-q-series-support-cells.tsv` row (EXISTS, matches `cells.tsv` claim_boundary
verbatim): `interval_status=inference_ready`, `coverage_status=inference_ready`,
`evidence_url=docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv`.

Deciding evidence, all EXISTS on disk (checked):

1. **`docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv`**
   (EXISTS), row `gaussian_lowq_mu_intercept_sr475_phylo`,
   `cell_id=qseries_phylo_q1_mu_intercept`: `n_rep=475`, `n_fit_ok=475` (1.0000),
   `n_converged=475` (1.0000), `n_pdhess=475` (1.0000), `n_usable_intervals=475` (1.0000),
   `n_covered=467`, **`coverage=0.9832`, `coverage_mcse=0.005904`**, `lower_miss=4`,
   `upper_miss=4` — an exact match to mc-0272's `claim_boundary` ("Nibi SR475
   retained-denominator coverage 0.9832 (MCSE 0.0059), 4/4 misses"). `slurm_job_ids`
   column: `16977254,16978889`.

2. **Raw per-replicate artifact** —
   `docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-topup-nibi/`
   (EXISTS: `results/`, `metadata/`, `logs/`, `remote-run-root.txt`, and
   `structured-re-gaussian-lowq-mu-intercept-sr475-results-replicates.tsv`, 975 KB). The
   run root file records the Nibi path
   `/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q1-mu-sr475-topup-77b634ed-r163`.

3. **After-task reports** (both EXIST):
   - `docs/dev-log/after-task/2026-06-30-q-series-q1-mu-sr475-aggregate.md` — the raw
     aggregate, explicitly `do_not_promote` at that point ("This promotes exactly no
     Q-Series row ... Fisher/Rose/Grace must review ... before any support-cell status
     edit").
   - `docs/dev-log/after-task/2026-06-30-q-series-q1-mu-sr475-inference-ready.md` — the
     **actual promotion**, after Fisher/Rose/Grace review: "Promoted
     `qseries_phylo_q1_mu_intercept`, `qseries_spatial_q1_mu_intercept`, and
     `qseries_relmat_q1_mu_intercept` to interval+coverage `inference_ready`,"
     with the identical row numbers (coverage 0.9832, MCSE 0.005904, 4/4 misses).
     `qseries_animal_q1_mu_intercept` was explicitly held back (2 boundary intervals) —
     evidence that this was a real, discriminating review, not a rubber stamp.

4. **Git provenance**: the support-cells.tsv edit that flips this row from
   `planned/planned` to `inference_ready/inference_ready` is commit `d1b029cb6`
   "Record Q-Series evidence ledger" (2026-06-30, Shinichi Nakagawa).
   `git merge-base --is-ancestor d1b029cb6 HEAD` → **is an ancestor of HEAD**.

`denominator_policy` for this row is `sr475_retained_denominator_inference_ready_with_caveats`
(not `fixture_not_coverage` — this row's policy label correctly reflects real coverage
evidence, unlike the q2-slope rows above which retain a stale fixture-era label).

---

## mc-0276 — gaussian sigma, phylo q1, one-slope (intercept + slope)

**Class: (A) REAL RUN EXISTS, NOT WIRED**

`legacy_evidence_source` = `qseries_phylo_q1_sigma_one_slope`. Current
`structured-re-q-series-support-cells.tsv` row (EXISTS): `interval_status=inference_ready`,
`coverage_status=inference_ready`,
`evidence_url=docs/dev-log/dashboard/structured-re-sigma-slope-parity-fixture.tsv` (fit
evidence url; the coverage evidence, as with mc-0153/mc-0154, is cited in the prose and
lives in a separate, verified file below).

Deciding evidence — **all four numbers in mc-0276's `claim_boundary` are an exact,
verbatim match** to
`docs/dev-log/dashboard/structured-re-sigma-slope-inference-evidence.tsv` (EXISTS), which
is itself a real, reviewed evidence table (not a stub):

| ledger claim text | file value | row |
|---|---|---|
| "Wald coverage 0.9388 (intercept SD)" | `wald_coverage=0.9388` | `sigma_slope_inference_phylo_intercept` |
| "5 lower vs 56 upper" | `wald_lower_miss=5`, `wald_upper_miss=56` | same row |
| "0.9935 (slope SD)" | `wald_coverage=0.9935` | `sigma_slope_inference_phylo_x` |
| "sigma:x profile finite rate 0.7579" | `profile_finite_rate_of_fit=0.7579` | same row |

Row detail (EXISTS on disk):

1. **`sigma_slope_inference_phylo_intercept`**: `source_run=nibi_sr1000_topup`,
   `cluster_host=nibi`, `cluster_job=16844251_1`,
   `package_git_sha=77b3730fa563b022f04fff31e29907ba3f4f7e37`, `planned_reps=1000`,
   `n_fit_ok=1000`, `n_converged=1000`, `n_pdhess=1000` (all 1000/1000), Wald finite
   996/1000, `wald_coverage=0.9388`, `wald_mcse=0.0076`, `promotion_status=inference_ready_with_caveats`.
   Source artifact
   `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/results/shard_1/01-phylo-sigma_intercept-replicates.tsv`
   — **EXISTS, 1001 lines (1000 reps + header)**, matching `planned_reps=1000` exactly.

2. **`sigma_slope_inference_phylo_x`**: `source_run=local_sr475_banked`,
   `cluster_host=local_mac`, `planned_reps=475`, `wald_coverage=0.9935`,
   `wald_mcse=0.0037`, `profile_finite_rate_of_fit=0.7579`,
   `promotion_status=inference_ready_with_caveats`. Source artifact
   `docs/dev-log/simulation-artifacts/2026-06-27-sigma-slope-coverage-grid-local/02-phylo-sigma_x-replicates.tsv`
   — **EXISTS, 476 lines (475 reps + header)**, matching exactly.

3. **After-task report** (EXISTS):
   `docs/dev-log/after-task/2026-06-28-sigma-q1-inference-ready.md` — full reviewed
   promotion. "Ran the sigma top-up campaign on Nibi for the two intercept targets ...
   SLURM job `16844251` completed array tasks 1 and 6 with exit code 0 on node `c542`.
   Preserved the Nibi artifacts under
   `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/` ...
   Fisher and Rose accepted a narrow promotion only under the raw uncorrected log-SD
   Wald-z channel." Explicitly states the residuals quoted in mc-0276's claim_boundary
   ("phylo Wald coverage is 0.9388 with 5 lower and 56 upper misses"; "profile channel is
   diagnostic-only at g = 8 ... finite rates ... 0.7579").

4. **Git provenance**: commit `fff3a8e6e` "Promote phylo relmat sigma q1 evidence"
   introduces `docs/dev-log/after-task/2026-06-28-sigma-q1-inference-ready.md` and the
   support-cells.tsv edit. `git merge-base --is-ancestor fff3a8e6e HEAD` → **is an
   ancestor of HEAD**.

---

## 4. Queries run (all four cells)

- Read `docs/dev-log/dashboard/capability-ledger/cells.tsv` and `evidence.tsv` rows for
  mc-0153, mc-0154, mc-0272, mc-0276 directly (awk field dump).
- `rg -l "qseries_relmat_q2_mu1_mu2_one_slope" --hidden -g '!.git' .` (repo-wide) — 40+
  hits across `tools/`, `tests/`, `docs/design/`, `docs/dev-log/after-task/`,
  `docs/dev-log/dashboard/*.tsv`, `docs/dev-log/simulation-artifacts/`.
- `rg -l "qseries_phylo_q1_mu_intercept"` / `qseries_phylo_q1_sigma_one_slope"` (same
  scope) — similar fan-out.
- `rg -l "0\.9832"`, `rg -l "SR475"`, `rg -l "0\.9388"`, `rg -l "0\.9935"`,
  `rg -l "0\.7579"` repo-wide (excluding `.git`) to find the exact numeric source of each
  quoted coverage figure.
- `rg -l "near-boundary"`, `rg -l "0\.35"` (scoped to the bias-corrected-engine-coverage
  and secondgrid directories) to find the "second grid" cited in the q2-slope
  claim_boundary.
- Read `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv` rows for all
  three legacy tokens directly (`grep "^qseries_..." `).
- Read `docs/design/219-structured-re-small-sample-bias-correction.md` in full.
- Read after-task reports:
  `2026-06-27-interval-feasible-promotion.md`,
  `2026-06-27-interval-reliability-rung.md`,
  `2026-06-30-q-series-q1-mu-sr475-aggregate.md`,
  `2026-06-30-q-series-q1-mu-sr475-inference-ready.md`,
  `2026-06-28-sigma-q1-inference-ready.md`.
- `ls -la` / `wc -l` on every cited artifact directory and replicate file to confirm
  on-disk existence and row counts (all reported above; none were missing).
- `git log --oneline --all -- docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
  then `git show <sha> -- <file>` to find the exact promotion commits (`9ae75bf17`,
  `d1b029cb6`, `fff3a8e6e`).
- `git merge-base --is-ancestor <sha> HEAD` for all three promotion commits — all three
  **are** ancestors of the current checkout (i.e. on mainline, not an orphaned branch).
- `git log --all --oneline -Smc-0153` / `-Smc-0154` / `-Smc-0272` / `-Smc-0276` — no
  commit directly ties the new `mc-XXXX` ID to a fresh evidence run; the mc-ID layer is a
  later wrapper (`fa8c48d91` "add auditable missing-response ledger") over the pre-existing
  q-series legacy evidence, consistent with everything above living under the old token
  names rather than the new IDs.
- Checked `docs/dev-log/interval-feasibility/` and `docs/dev-log/interval-campaign-bindings/`
  for a receipt keyed on `mc-0153`/`mc-0154`/`mc-0272`/`mc-0276` or on the three legacy
  tokens — **no hits in either directory** (`grep -rl` over both, and over the
  `interval-campaign-bindings` TSVs by legacy token) — these directories host a later,
  unrelated arc (count/highq atlas). This is a genuine negative result, not a claim of
  overall absence: the real evidence for these four cells lives in
  `docs/dev-log/dashboard/*.tsv`, `docs/design/219`, and
  `docs/dev-log/simulation-artifacts/2026-06-27-*` / `2026-06-28-*` / `2026-06-30-*`
  instead.

## 5. Note on the prior Wave-1 pass

Commit `9ee8c9fc4` (this same lane, "Wave 1 classification") already scored all four
cells as class **(c)** "legacy import with no run," reasoning only from
`evidence.tsv`'s blank `run_id`/`command`/`replicates` fields. That check is a true
description of `evidence.tsv` but not of the repository: all four cells have a real,
Fisher/Rose(/Grace)-reviewed, on-mainline campaign backing the exact coverage numbers
quoted in their `claim_boundary` text. The gap is a **wiring gap in `evidence.tsv`**
(the migration copied the claim text but not a resolvable `run_id`/`command`/`path`),
not an **evidence gap**.
