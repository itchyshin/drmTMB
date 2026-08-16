# IRC Legacy Evidence Audit — Batch D

Cells: mc-0285 (spatial mu q1 intercept), mc-0301 (animal sigma q1 one-slope),
mc-0309 (relmat mu q1 intercept), mc-0313 (relmat sigma q1 one-slope).
Lane: `claude/lane-irc-legacy-evidence`, worktree
`/Users/z3437171/local-scratch/lanes/drmTMB-interval-truth-audit`, HEAD =
`302ac2579969f7d5f949a73610468c9f73f938c8` == `origin/main` (verified with
`git merge-base --is-ancestor HEAD origin/main`).

## Headline

**All four cells are class (A): a real, reviewed coverage-study run exists and
numerically backs the exact interval claim in the cell's `claim_boundary`, but
that run is NOT wired into the current `capability-ledger/evidence.tsv` row.**
The current evidence.tsv row for each cell is a single `legacy_model_evidence`
stub with blank `run_id`/`command`/`replicates` — that part of the brief's
premise is correct. But the underlying coverage study is not missing: it lives
in a **predecessor ledger** (`docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
and two companion evidence tables) that the 2026-07-11 "MR-T0 migration" to the
new `capability-ledger/` schema did not carry the machine-readable link forward
from. Every coverage number quoted in each cell's `claim_boundary` is
independently reproducible from raw replicate-level TSVs that exist on disk
and are git-tracked on `main`.

**This contradicts the prior interval-claim-truth-audit lane's Wave 1
classification**, which filed all four cells as class (c) "legacy import, no
run behind it" / bucket "rerun" (`scratchpad/wave1-classification.json`,
commit `9ee8c9fc4`). That classification is not wrong on its own narrower
search (it checked only `capability-ledger/evidence.tsv`'s primary row and
whether `claim_boundary` cites a `docs/dev-log/simulation-artifacts/...` path
by name — see `scratchpad/uncovered-cohort-A.md` lines 143–161, "Files
consulted"), but it did not search `check-log.md`, `after-task/`, or the
pre-migration `structured-re-*` dashboard ledger, where the real evidence
lives. See "Discrepancy with the prior lane" below.

---

## mc-0285 — spatial mu q1 intercept

**Class: (A) REAL RUN EXISTS, NOT WIRED.**

### The claim (verbatim, current `cells.tsv`, 2026-08-15-edited `claim_boundary`)

> "Intercept-only spatial(1 | site, coords = coords); coordinate-based fixed
> covariance only; the precomputed-mesh route (mesh = ...) IS implemented for
> the univariate Gaussian mu slice (R/drmTMB.R:3219, 13082-13104) but is
> outside this cell's evidence, and R/check.R:2977-2982 withholds mesh
> intervals, coverage and range entirely; **SR475 coverage 0.9705, misses
> 4/10**. The default interval is the location-axis bias-corrected
> small-sample-t Wald direct-SD channel; this is inference-ready with
> caveats, not nominal or supported. The raw uncorrected log-SD Wald-z sigma
> channel does not apply. This spatial sd(group) interval is conditional on
> the correlation range: spatial(1 | group, coords = coords) fixes the
> exponential range at the median positive pairwise distance among those
> coords, falling back to the maximum when that median is not positive and
> finite, and never estimates it (R/drmTMB.R:13403-13407); a true correlation
> length away from that fixed value is absorbed by the estimated sd(group).
> **The retained evidence does not test that condition:** its data-generating
> process builds the latent field from the same fixed-range kernel the model
> assumes, so the range was correct by construction and range
> misspecification remains unexamined for this cell."
> (`docs/dev-log/dashboard/capability-ledger/cells.tsv`, row `mc-0285`, col 23)

The stale col-30 `notes` field (never updated by the 2026-08-15 edit) still
carries the pre-fix text: *"...precomputed-mesh spatial (mesh = ...) is
planned but not implemented (R/drmTMB.R:8434-8440); SR475 coverage 0.9705,
misses 4/10."* This is the exact falsehood the prior interval-claim-truth-audit
lane fixed (see below) — it survives only in the unused `notes` column, not in
the live `claim_boundary`.

### Does the SR475 0.9705 figure have a backing artifact? YES — verified by direct recomputation.

Real artifact:
`docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-topup-nibi/structured-re-gaussian-lowq-mu-intercept-sr475-results-replicates.tsv`
— **EXISTS on disk**, 975,266 bytes, 1901 rows (header + 475 reps ×4
providers), columns include `conf.low`, `conf.high`, `covered`,
`lower_miss`, `upper_miss`, `seed`, `pdHess`. Filtering to
`cell_id == "qseries_spatial_q1_mu_intercept"` and `usable_interval == TRUE`
gives **475 usable / 461 covered = 0.970526**, matching the claim's 0.9705
exactly (recomputed live with `awk`, not copied from a summary file).

Aggregate summary row (also EXISTS):
`docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv`,
row `gaussian_lowq_mu_intercept_sr475_spatial`: `n_covered=461`,
`coverage=0.9705`, `coverage_mcse=0.007760`, `lower_miss=4`, `upper_miss=10`
— exact match to the `claim_boundary`'s "0.9705, misses 4/10."

Reviewed promotion trail (both exist, both git-tracked on `main`):
- `docs/dev-log/after-task/2026-06-30-q-series-q1-mu-sr475-inference-ready.md`
  — states verbatim: *"`qseries_spatial_q1_mu_intercept`: 475/475 usable
  intervals, coverage `0.9705`, MCSE `0.007760`, lower/upper misses `4/10`;
  fixed-covariance spatial evidence only."* Checks section shows
  `devtools::test(filter = "structured-re-conversion-contracts")`: 9594 PASS.
- `docs/dev-log/check-log.md:12156-12207` ("## 2026-06-30: Q-Series q1 mu
  SR475 inference-ready promotion") — same numbers, records the promotion of
  `interval_status`/`coverage_status` to `inference_ready`.

**Pre-migration ledger row** (predecessor of today's `cells.tsv`, still
present and git-tracked): `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`,
row `qseries_spatial_q1_mu_intercept` — `interval_status=inference_ready`,
`coverage_status=inference_ready`, `evidence_url=docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv`,
`denominator_policy=sr475_retained_denominator_inference_ready_with_caveats`,
signed off by `Rose/Fisher/Grace` per its own `next_gate` field. This row IS
the wiring — it is just in a different, older ledger file than
`capability-ledger/evidence.tsv`.

### The mesh sub-claim (secondary check, not the coverage question)

`R/drmTMB.R:13082-13104` — EXISTS, is `build_mesh_spatial_mu_structure()` /
`.drm_validate_mesh` code, i.e. real mesh-spatial-mu implementation. `R/drmTMB.R:3219`
itself is a `cli_abort` for a missing mu-formula response, not mesh code, but
`allow_mesh = TRUE` is passed at line 3234 in the same dispatch block, a few
lines away — consistent with, if not byte-exact to, the citation. `R/check.R:2977-2982`
EXISTS and is the `spatial_mu_diagnostics` check-row block referenced. The
"planned but not implemented" claim was independently found false by the
prior interval-claim-truth-audit lane and fixed in commit `8af07b864`
("docs(ledger): narrow all 28 spatial interval claims to the fixed-range
condition") — issue #5 of that lane's after-task report
(`docs/dev-log/after-task/2026-08-15-interval-claim-truth-audit.md:110`):
*"`mc-0285` boundary asserted mesh 'planned but not implemented
(R/drmTMB.R:8434-8440)' — false on both halves | **FIXED**."*

---

## mc-0301 — animal sigma q1 one-slope

**Class: (A) REAL RUN EXISTS, NOT WIRED.**

### The claim (verbatim, `cells.tsv`)

> "One-slope; g=8 SR1000 evidence, raw uncorrected log-SD Wald-z coverage
> 0.9633 (intercept SD) and 0.9895 (slope SD); misses asymmetric (intercept
> 26 lower vs 10 upper); profile is diagnostic-only at g=8. The location-axis
> bias+t correction does not apply to sigma; this is inference-ready with
> caveats, not supported, and pedigree/Ainv bridge marshalling remains a
> separate gate."

### Backing artifacts — all verified to EXIST and reproduce the numbers

- `docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/results/shard_5/05-animal-sigma_intercept-replicates.tsv`
  — EXISTS, 526 lines (525 topup reps + header).
- `docs/dev-log/simulation-artifacts/2026-06-27-sigma-slope-coverage-grid-local/05-animal-sigma_intercept-replicates.tsv`
  — EXISTS, 476 lines (475 SR475-banked reps + header). 525+475 = **1000** =
  "SR1000."
- `docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/results/shard_8/08-animal-sigma_x-replicates.tsv`
  — EXISTS, 1001 lines (1000 reps, sigma:x/slope endpoint).
- `docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/animal-sigma-sr1000-combined-summary.tsv`
  — EXISTS, 2 rows: `animal_sigma_sr1000_intercept` (`n_wald_covered=945`,
  `wald_coverage=0.9633`, `wald_mcse=0.006`, `wald_lower_miss=26`,
  `wald_upper_miss=10`); `animal_sigma_sr1000_x` (`wald_coverage=0.9895`,
  `wald_mcse=0.0033`, `wald_lower_miss=0`, `wald_upper_miss=10`) — exact match
  to the `claim_boundary`.

Reviewed promotion trail (git-tracked on `main`):
- `docs/dev-log/check-log.md:87333-87381` ("## 2026-06-28: Q-Series animal q1
  sigma one-slope SR1000 reconciliation") — raw candidate evidence, explicitly
  `candidate_wald_channel_pending_fisher_rose_signoff` at this stage, cell
  still `planned/planned`.
- `docs/dev-log/check-log.md:87383-87429` ("## 2026-06-28: Q-Series animal q1
  sigma one-slope to inference_ready") — states verbatim: *"Fisher sign-off
  accepted the exact row under the raw uncorrected log-SD Wald-z sigma
  interval channel... Animal `sigma:(Intercept)`: ... Wald coverage 0.9633
  with MCSE 0.0060, and one-sided misses 26 lower / 10 upper. Animal
  `sigma:x`: ... Wald coverage 0.9895 with MCSE 0.0033, and one-sided misses
  0 lower / 10 upper."*
- `docs/dev-log/dashboard/structured-re-sigma-slope-inference-evidence.tsv`
  — EXISTS, row `sigma_slope_inference_animal_intercept`:
  `linked_cell_id=qseries_animal_q1_sigma_one_slope`,
  `source_run=local_sr1000_reconciliation`,
  `source_artifact=docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/animal-sigma-sr1000-combined-summary.tsv`,
  `package_git_sha=060596f94e3056a0f78d326aae79c9983979b9b4`,
  `seed_start=740001`, `seed_end=741000`, `promotion_status=inference_ready_with_caveats`.
  Sibling row `sigma_slope_inference_animal_x` covers the slope endpoint,
  same promotion status.
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`, row
  `qseries_animal_q1_sigma_one_slope`: `interval_status=inference_ready`,
  `coverage_status=inference_ready`,
  `evidence_url=docs/dev-log/dashboard/structured-re-sigma-slope-inference-evidence.tsv`.

The 08-shard replicate-level `covered`/`conf.low`/`conf.high` columns and the
1000-attempt SR1000 denominator make this a genuine coverage study, not a
point-fit or recovery test — it is exactly the raw-Wald-z channel the
`claim_boundary` names as this cell's primary interval mechanism.

---

## mc-0309 — relmat mu q1 intercept

**Class: (A) REAL RUN EXISTS, NOT WIRED.** Same SR475 campaign as mc-0285,
different provider column.

### The claim (verbatim, `cells.tsv`)

> "Intercept-only relmat(1 | id, K = K); K-matrix, not Q bridge marshalling;
> SR475 coverage 0.9789, misses 3/7. The default interval is the
> location-axis bias-corrected small-sample-t Wald direct-SD channel; this is
> inference-ready with caveats, not nominal or supported. The raw
> uncorrected log-SD Wald-z sigma channel does not apply."

### Verified

Same replicate file as mc-0285:
`docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-topup-nibi/structured-re-gaussian-lowq-mu-intercept-sr475-results-replicates.tsv`
— filtering `cell_id == "qseries_relmat_q1_mu_intercept"` and
`usable_interval == TRUE` gives **475 usable / 465 covered = 0.978947**,
matching 0.9789 exactly (recomputed live).

Aggregate row `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv`,
`gaussian_lowq_mu_intercept_sr475_relmat`: `coverage=0.9789`,
`coverage_mcse=0.006587`, `lower_miss=3`, `upper_miss=7` — exact match.

`docs/dev-log/after-task/2026-06-30-q-series-q1-mu-sr475-inference-ready.md`:
*"`qseries_relmat_q1_mu_intercept`: 475/475 usable intervals, coverage
`0.9789`, MCSE `0.006587`, lower/upper misses `3/7`; K-matrix relmat evidence
only."*

`docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`, row
`qseries_relmat_q1_mu_intercept`: `interval_status=inference_ready`,
`coverage_status=inference_ready`,
`evidence_url=docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv`.

---

## mc-0313 — relmat sigma q1 one-slope

**Class: (A) REAL RUN EXISTS, NOT WIRED.** Companion to mc-0301, same
sigma-slope campaign, relmat provider column.

### The claim (verbatim, `cells.tsv`)

> "One-slope; g=8, raw uncorrected log-SD Wald-z coverage 0.9416 (intercept
> SD) and 0.9957 (slope SD); intercept misses upper-tail asymmetric (5 lower
> vs 53 upper); profile is diagnostic-only at g=8. The location-axis bias+t
> correction does not apply to sigma; this is inference-ready with caveats,
> not supported, and relmat K/Q bridge marshalling remains a separate gate."

### Backing artifacts — verified to EXIST

- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/results/shard_6/06-relmat-sigma_intercept-replicates.tsv`
  — EXISTS, 1001 lines (1000 reps). This is a **Nibi SLURM cluster job**
  (`16844251_6`), not a local run.
- `docs/dev-log/simulation-artifacts/2026-06-27-sigma-slope-coverage-grid-local/07-relmat-sigma_x-replicates.tsv`
  — EXISTS, 476 lines (475 SR475-banked reps, sigma:x/slope endpoint).

`docs/dev-log/check-log.md:86600-86659` ("## 2026-06-28: q1 sigma phylo/relmat
rows to inference_ready") — states verbatim: *"Sigma intercept top-up: ...
relmat N=1000, fit/pdHess 100%, Wald finite 993/1000, coverage 0.9416, MCSE
0.0074, lower/upper misses 5/53."* and *"Sigma:x banked SR475: ... relmat Wald
coverage 0.9957, MCSE 0.0030, profile finite rate 0.8042."* Also: *"Ran Nibi
top-up job `16844251`... Array tasks `16844251_1` and `16844251_6` completed
with exit code 0..."* and *"Fisher signed off with caveats: row-level
phylo/relmat q1 sigma only; raw Wald-z primary; profile diagnostic-only."*

`docs/dev-log/dashboard/structured-re-sigma-slope-inference-evidence.tsv`,
row `sigma_slope_inference_relmat_intercept`:
`linked_cell_id=qseries_relmat_q1_sigma_one_slope`,
`source_run=nibi_sr1000_topup`, `cluster_host=nibi`, `cluster_job=16844251_6`,
`package_git_sha=77b3730fa563b022f04fff31e29907ba3f4f7e37`,
`n_wald_covered=935`, `wald_coverage=0.9416`, `wald_mcse=0.0074`,
`wald_lower_miss=5`, `wald_upper_miss=53`, `promotion_status=inference_ready_with_caveats`.
Sibling row `sigma_slope_inference_relmat_x`: `wald_coverage=0.9957`,
`wald_mcse=0.003`, `promotion_status=inference_ready_with_caveats`.

`docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`, row
`qseries_relmat_q1_sigma_one_slope`: `interval_status=inference_ready`,
`coverage_status=inference_ready`,
`evidence_url=docs/dev-log/dashboard/structured-re-sigma-slope-inference-evidence.tsv`.

---

## Discrepancy with the prior interval-claim-truth-audit lane

The prior lane (`claude/lane-interval-truth-audit`, closed same day, commit
`ced5c0de3`) ran a Wave-1 classification over 210 uncovered cells and filed
all four of these cells as **class (c) "legacy import, no run behind it at
all"** and bucket **"rerun"** (needs a first-ever profile campaign) —
`scratchpad/wave1-classification.json` (commit `9ee8c9fc4`), keys `c` and
`rerun` both contain `mc-0285`, `mc-0301`, `mc-0309`, `mc-0313`. Its per-cell
notes in `scratchpad/uncovered-cohort-A.md:47-50` read literally: *"Primary
ev-mc-0285-legacy: run_id/command/replicates blank | N/A"* for each of the
four.

That conclusion is accurate about the **current evidence.tsv row** (blank
run_id/command/replicates — confirmed above) but is **not accurate about
whether a run exists**. Its own "Files consulted" list
(`uncovered-cohort-A.md:156-161`) shows the search was scoped to
`capability-ledger/evidence.tsv`, `cells.tsv`, and verifying any
`docs/dev-log/simulation-artifacts/...` directory *named explicitly in the
claim_boundary text*. The `claim_boundary` for these four cells names "SR475"
/ "SR1000" but never spells out a `docs/dev-log/...` path, so that narrower
search came up empty. It did not search `check-log.md`, `docs/dev-log/after-task/`,
or the pre-migration `docs/dev-log/dashboard/structured-re-*` ledger files —
which is where this report's evidence was found, per the task brief's
explicit instruction to check exactly those locations.

Two readings are both defensible and are reported, not adjudicated:
1. **Narrow reading (prior lane):** the *current, canonical* evidence ledger
   (`capability-ledger/evidence.tsv`) carries no machine-checkable run for
   these cells, and the `profile_truth_gate.py` instrument (which checks
   whether a *profile* interval brackets a *fixture-derived* true value) has
   no manifest entry for any of them — consistent with "0 of the 41
   `inference_ready_with_caveats` cells have a profile receipt this arc can
   re-check" (`docs/dev-log/2026-08-15-interval-truth-coverage-map.md:37-42`).
2. **Broad reading (this report):** these four cells' claimed interval
   channel is explicitly **Wald-based** ("raw uncorrected log-SD Wald-z",
   "default location-axis bias-corrected small-sample-t Wald direct-SD"), not
   profile-based, so the profile-truth-manifest's absence is expected and not
   informative. A genuine, reviewed, replicate-level **Wald coverage study**
   (SR475 for the two mu-intercept cells, SR475+SR1000 for the two
   sigma-one-slope cells) exists, is git-tracked on `main`, was Fisher/Rose/
   Grace-signed, and is wired into a predecessor ledger — just not the current
   one.

---

## Queries run

1. `grep -n "mc-0285\|mc-0301\|mc-0309\|mc-0313" docs/dev-log/dashboard/capability-ledger/evidence.tsv`
2. `grep -n "^mc-0285\|^mc-0301\|^mc-0309\|^mc-0313" docs/dev-log/dashboard/capability-ledger/cells.tsv`
3. `rg -l "SR475" --glob '!.git' .` (repo-wide, 190+ hits — enumerated, not all read)
4. `rg -l "0\.9633"`, `rg -l "0\.9895"`, `rg -l "0\.9416"`, `rg -l "0\.9957"` (repo-wide)
5. `grep -n -B2 -A2 "0.9633"`, `"0.9416"`, `"0.9895"`, `"0.9957"` in `docs/dev-log/check-log.md`
6. Read `docs/dev-log/after-task/2026-06-30-q-series-q1-mu-sr475-inference-ready.md`,
   `docs/dev-log/after-task/2026-06-30-q-series-q1-mu-sr475-aggregate.md`,
   `docs/dev-log/after-task/2026-06-30-q-series-q1-mu-sr475-status-surface-sync.md`
7. Read `docs/dev-log/simulation-artifacts/2026-07-08-g2-sigma-oneslope-adjudication/ADJUDICATION.md`
   (a *different*, later profile-channel study over the same providers — g=8 profile
   coverage ~0.90-0.92, N=600 LOCAL; not the primary Wald channel these 4 cells
   claim, kept separate from the numbers quoted above)
8. `ls`/`wc -l`/existence checks on every artifact path cited above (all EXIST)
9. `awk -F'\t'` recomputation of coverage rate directly from raw replicate TSVs
   for mc-0285 and mc-0309 (independently reproduced 0.9705 and 0.9789)
10. `grep -rl "mc-0285\|mc-0301\|mc-0309\|mc-0313" docs/dev-log/interval-feasibility/` — **no hits**
11. `[ -d docs/dev-log/interval-campaign-bindings ]` (exists) then
    `rg -l "mc-0285|mc-0301|mc-0309|mc-0313"` and
    `rg -l "qseries_spatial_q1_mu_intercept|qseries_animal_q1_sigma_one_slope|qseries_relmat_q1_mu_intercept|qseries_relmat_q1_sigma_one_slope"`
    inside `docs/dev-log/interval-campaign-bindings/` — **no hits**; that
    directory's `2026-07-31-structured-q1-target-map.tsv` covers a disjoint
    set of cell IDs (count-family q1 targets, mc-0012/0248/0388/0406-0494…),
    not our four
12. `git log --all --oneline -S"mc-0285"` / `-S"mc-0301"` / `-S"mc-0309"` /
    `-S"mc-0313"` (all refs) — surfaced the prior interval-claim-truth-audit
    lane's commits (`8af07b864`, `395772f18`, `9ee8c9fc4`, `2d033a7d3`,
    `ced5c0de3`) plus unrelated missing-data-mask commits
13. `git show --stat` on `8af07b864` and `ced5c0de3`; read
    `docs/dev-log/after-task/2026-08-15-interval-claim-truth-audit.md` in full
14. `git show 9ee8c9fc4:scratchpad/wave1-classification.json` and parsed with
    Python to find which of the six classification buckets (`a`,`b`,`c`,
    `recheck`,`rerun`,`b_silent`) contain each of the four cell IDs
15. `git show 9ee8c9fc4:scratchpad/uncovered-cohort-A.md` and `-B.md` and
    `-C.md`, grepped for the four cell IDs (found only in cohort A)
16. `git merge-base --is-ancestor` both directions to confirm this worktree's
    HEAD equals `origin/main` (so all cited evidence is on the true mainline,
    not an orphaned branch)
17. `sed -n` reads of `R/drmTMB.R:3215-3222`, `R/drmTMB.R:13082-13104`,
    `R/check.R:2940-2995`, and `grep -n "mesh" R/drmTMB.R` restricted to
    lines 3150-3300, to sanity-check the mesh implementation citations in
    mc-0285's claim_boundary
