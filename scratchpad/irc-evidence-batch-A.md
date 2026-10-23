# IRC legacy-evidence audit — Batch A (mc-0001, mc-0003, mc-0057, mc-0397)

Lane: `drmTMB-interval-truth-audit` (branch `claude/lane-irc-legacy-evidence`).
Checkout root: `/Users/z3437171/local-scratch/lanes/drmTMB-interval-truth-audit`.
Read-only audit; only this file was written.

## Headline

All four cells classify **(A)** in a qualified sense: a real, on-mainline coverage
campaign backs each cell's interval claim, **and unlike the "orphaned artifact"
reading of class A, the evidence.tsv row already cites the correct path**
(`path_or_url` points straight at the campaign directory, and its
`claim_boundary` text is a verbatim paraphrase of the campaign's own README
verdict). What is genuinely missing is administrative, not evidentiary: the
`command`, `run_id`, and `replicates` columns in `evidence.tsv` are blank, even
though `driver.R` / `phase2-driver.R` in the same directory contain the exact
command and the results files carry an explicit `nsim = 400` per row. So: real
run, correctly referenced by path, incompletely wired at the column level.

All four evidence rows share one `path_or_url`:
`docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot`
— confirmed to **exist on disk** (`README.md`, `driver.R`, `phase2-driver.R`,
`results.tsv`, `phase2-results.tsv`).

Both files that supply results are landed on `main`/`origin/main` (verified with
`git merge-base --is-ancestor`, not just present in the working tree):

| commit | date | message | ancestor of origin/main |
|---|---|---|---|
| `651019fc1` | 2026-07-09 17:57:39 -0600 | `sim: unstructured non-Gaussian coverage pilot (mean coefficients)` | YES |
| `12de12d88` | 2026-07-09 18:11:24 -0600 | `sim: non-Gaussian scale-coefficient + stress coverage (phase 2)` | YES |

`git diff 12de12d88 -- docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot/`
is empty: the working tree matches the landed commit exactly, i.e. the numbers
below have not been altered post-hoc.

An independent corroborating account exists at
`docs/dev-log/after-task/2026-07-09-v0.4.0-capability-honest-release-prep.md`
(§2, Arc 2): "Ran a coverage campaign on Totoro (384-core lab server):
unstructured non-Gaussian fixed-effect **mean** intervals (binomial/poisson/
beta/nbinom2, incl. rare-event and low-count stress) and **nbinom2
location-scale** intervals are calibrated (Wald, finite-rate ≈ 1.0,
near-nominal); beta location-scale calibrated for interior proportions.
Promoted the 6 validated cells in the census." This matches the campaign
README's own verdict text word-for-word and confirms the campaign was run
deliberately to justify promotions, not an accidental artifact.

---

## mc-0001 — beta, mu (fixed), model_surface

- **cells.tsv row**: `family_route=beta`, `dpar=mu`, `effect_type=fixed`,
  `evidence_tier=inference_ready_with_caveats`,
  `claim_boundary="Wald mean-coefficient intervals calibrated — docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot"`.
- **evidence.tsv row** `ev-mc-0001-legacy`: class `legacy_model_evidence`,
  `path_or_url` = the pilot dir, `command`/`run_id`/`replicates` blank,
  `reviewed_by="MR-T0 migration"`, `review_date=2026-07-11`.
- **Deciding evidence**: `results.tsv` (phase 1), rows `family == "beta"`,
  `param` = `fixef:mu:(Intercept)` / `fixef:mu:x`, at n = 50, 150, 500:

  | n | param | nsim | finite_rate | coverage | mcse |
  |---|---|---|---|---|---|
  | 50 | mu:(Intercept) | 400 | 1 | 0.922 | 0.0134 |
  | 50 | mu:x | 400 | 1 | 0.940 | 0.0119 |
  | 150 | mu:(Intercept) | 400 | 1 | 0.950 | 0.0109 |
  | 150 | mu:x | 400 | 1 | 0.925 | 0.0132 |
  | 500 | mu:(Intercept) | 400 | 1 | 0.943 | 0.0116 |
  | 500 | mu:x | 400 | 1 | 0.958 | 0.0101 |

  `driver.R` (same dir) calls `confint(fit)` (Wald channel) and reports coverage
  of the true generating coefficients — this is a genuine interval/coverage
  study, not a point-fit test.
- **Class: (A)** — real run exists, correctly path-referenced, not fully
  column-wired (no `command`/`run_id`/`replicates` in evidence.tsv).
- **Paths checked** (exists yes/no):
  - `docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot/results.tsv` — YES
  - `docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot/driver.R` — YES
  - `docs/dev-log/interval-feasibility/` — no file mentions `mc-0001`
  - `docs/dev-log/interval-campaign-bindings/` — no file mentions `mc-0001` (expected: those TSVs are all structured-RE q1/q2/q4 campaign contracts; mc-0001 is `structure_provider=none`, `q_gate=na`, out of that scope)
  - `docs/dev-log/after-task/2026-07-09-v0.4.0-capability-honest-release-prep.md` — YES, corroborates

---

## mc-0003 — beta, sigma (fixed), model_surface

- **cells.tsv row**: `family_route=beta`, `dpar=sigma`, `effect_type=fixed`,
  `evidence_tier=inference_ready_with_caveats`,
  `claim_boundary="Wald scale-coefficient intervals calibrated for INTERIOR proportions — .../2026-07-09-nongaussian-unstructured-coverage-pilot (phase 2); exact 0/1 need zero_one_beta()"`.
- **evidence.tsv row** `ev-mc-0003-legacy`: same pattern (legacy, no command/run_id/replicates).
- **Deciding evidence**: `phase2-results.tsv`, `spec == "beta_ls"`,
  `param` = `fixef:sigma:(Intercept)` / `fixef:sigma:x`:

  | n | param | nsim | finite_rate | coverage | mcse | clears_094 |
  |---|---|---|---|---|---|---|
  | 150 | sigma:(Intercept) | 400 | 0.978 | 0.934 | 0.0126 | TRUE |
  | 150 | sigma:x | 400 | 0.978 | 0.941 | 0.0119 | TRUE |
  | 400 | sigma:(Intercept) | 400 | 0.958 | 0.950 | 0.0111 | TRUE |
  | 400 | sigma:x | 400 | 0.958 | 0.953 | 0.0108 | TRUE |
  | 800 | sigma:(Intercept) | 400 | 0.885 | 0.927 | 0.0139 | FALSE |
  | 800 | sigma:x | 400 | 0.885 | 0.944 | 0.0123 | FALSE |

  The README (phase 2 section) explains the n=800 finite-rate drop precisely:
  "every non-finite case has an observation with `y == 1.0` exactly — ... `beta()`
  correctly requires `y ∈ (0, 1)` and returns non-finite on boundary data; this is
  correct behaviour, not an interval defect." This is exactly why the cell's own
  `claim_boundary` restricts the claim to "INTERIOR proportions" and names
  `zero_one_beta()` as the escape route for exact 0/1 — the ledger text and the
  artifact's caveat match verbatim in substance.
- **Class: (A)** — same qualified reading as mc-0001. The coverage numbers
  directly support the scale-coefficient interval claim, restricted to interior
  proportions exactly as the claim_boundary states.
- **Paths checked** (exists yes/no):
  - `.../phase2-results.tsv` — YES
  - `.../phase2-driver.R` — YES (confirms `bf(y ~ x, sigma ~ x)`, `confint()` Wald channel, symbolic map `phi = exp(-2*log_sigma)`)
  - `docs/dev-log/interval-feasibility/` — no mention of `mc-0003`
  - `docs/dev-log/interval-campaign-bindings/` — no mention of `mc-0003`
  - after-task report above — YES, corroborates ("beta location-scale calibrated for interior proportions")

---

## mc-0057 — binomial, mu (fixed), model_surface

- **cells.tsv row**: `family_route=binomial`, `dpar=mu`, `effect_type=fixed`,
  `evidence_tier=inference_ready_with_caveats`,
  `claim_boundary="Wald mean-coefficient intervals calibrated (finite-rate 1.0, near-nominal incl. rare-event stress) — .../2026-07-09-nongaussian-unstructured-coverage-pilot"`.
- **Deciding evidence**: `results.tsv`, `family == "binomial"` (n=50,150,500) +
  `phase2-results.tsv`, `spec == "binomial_rare"` (n=150,400,800, ~8% base rate
  stress):

  | source | n | param | finite_rate | coverage |
  |---|---|---|---|---|
  | results.tsv | 50 | mu:(Intercept) | 1 | 0.973 |
  | results.tsv | 50 | mu:x | 1 | 0.958 |
  | results.tsv | 150 | mu:(Intercept) | 1 | 0.953 |
  | results.tsv | 500 | mu:(Intercept) | 1 | 0.963 |
  | phase2 binomial_rare | 150 | mu:(Intercept) | 1 | 0.960 |
  | phase2 binomial_rare | 800 | mu:(Intercept) | 1 | 0.958 |
  | phase2 binomial_rare | 800 | mu:x | 1 | 0.955 |

  The cell's own claim_boundary parenthetical "incl. rare-event stress" maps
  exactly onto the `binomial_rare` spec in `phase2-driver.R`
  (`truth = c(...(Intercept) = -2.5, x = 0.7)`, ~8% base rate per the README).
- **Class: (A)** — real, on-mainline coverage run, correctly path-referenced,
  administratively (not evidentially) incomplete.
- **Paths checked** (exists yes/no):
  - `.../results.tsv` — YES; `.../phase2-results.tsv` — YES
  - `docs/dev-log/interval-feasibility/` — no mention of `mc-0057`
  - `docs/dev-log/interval-campaign-bindings/` — no mention of `mc-0057`
  - after-task report — YES, corroborates

---

## mc-0397 — nbinom2, mu (fixed), model_surface

- **cells.tsv row**: `family_route=nbinom2`, `dpar=mu`, `effect_type=fixed`,
  `evidence_tier=inference_ready_with_caveats`,
  `claim_boundary="Wald mean-coefficient intervals calibrated — .../2026-07-09-nongaussian-unstructured-coverage-pilot (phase 2)"`.
- **Deciding evidence**: `results.tsv`, `family == "nbinom2"` (n=50,150,500) +
  `phase2-results.tsv`, `spec == "nbinom2_ls"` mu rows (n=150,400,800):

  | source | n | param | finite_rate | coverage |
  |---|---|---|---|---|
  | results.tsv | 50 | mu:(Intercept) | 1 | 0.968 |
  | results.tsv | 150 | mu:(Intercept) | 1 | 0.940 |
  | results.tsv | 500 | mu:(Intercept) | 1 | 0.940 |
  | phase2 nbinom2_ls | 150 | mu:(Intercept) | 1 | 0.927 |
  | phase2 nbinom2_ls | 400 | mu:(Intercept) | 1 | 0.943 |
  | phase2 nbinom2_ls | 800 | mu:(Intercept) | 1 | 0.948 |

  Note the claim_boundary cites "(phase 2)" specifically, which is the
  location-scale run (`nbinom2_ls`, mean+scale jointly) — a stricter test than
  the phase-1 mean-only model, and it still clears (finite_rate 1.0, coverage
  0.927–0.968 across all n and both mu params).
- **Class: (A)** — same qualified reading.
- **Paths checked** (exists yes/no):
  - `.../results.tsv` — YES; `.../phase2-results.tsv` — YES
  - `docs/dev-log/interval-feasibility/` — no mention of `mc-0397`
  - `docs/dev-log/interval-campaign-bindings/` — no mention of `mc-0397`
  - after-task report — YES, corroborates ("nbinom2 location-scale intervals are calibrated")

---

## Queries run (all four cells)

1. `awk -F'\t' '$1 ~ /mc-0001|mc-0003|mc-0057|mc-0397 (row match)/'` over
   `docs/dev-log/dashboard/capability-ledger/evidence.tsv` and `cells.tsv`.
2. `ls` + `cat` on `docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot/{README.md,driver.R,phase2-driver.R,results.tsv,phase2-results.tsv}`.
3. `grep -rl "mc-0001\|mc-0003\|mc-0057\|mc-0397" docs/dev-log/interval-feasibility/` — no hits.
4. `ls docs/dev-log/interval-campaign-bindings/` (103 files) + `grep -rl "mc-0001\|mc-0003\|mc-0057\|mc-0397" docs/dev-log/interval-campaign-bindings/` — no hits (exit 1 / no matches). This directory's contents (q1/q2/q4/animal/relmat/phylo canonical-registry and execution-authorization TSVs) are all structured-random-effect campaign contracts; these four cells are `structure_provider=none`, `q_gate=na`, so absence here is consistent with scope, not a gap.
5. `grep -rl "nongaussian-unstructured-coverage-pilot\|mc-0001\b\|mc-0003\b\|mc-0057\b\|mc-0397\b" docs/dev-log/after-task/` → one hit:
   `docs/dev-log/after-task/2026-07-09-v0.4.0-capability-honest-release-prep.md`.
6. `grep -rl "nongaussian-unstructured-coverage-pilot" docs/dev-log/` excluding the artifact's own directory → only the after-task report above; no other doc references the campaign by name.
7. `git log --all --oneline --follow -- docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot` → 2 commits (`651019fc1`, `12de12d88`).
8. `git merge-base --is-ancestor 651019fc1 origin/main` and same for `12de12d882` → both `YES` (exit 0): the artifact is on mainline, not an off-mainline orphan of the kind the 2026-08-15 134-file recovery found.
9. `git show --stat 651019fc1` / `12de12d88` → confirms file-by-file provenance (README/driver/results added together, authored by Shinichi, `Co-Authored-By: Claude Opus 4.8`).
10. `git diff 12de12d88 -- docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot/` → empty: no post-landing tampering.
11. `grep -n "mc-0001\|mc-0003\|mc-0057\|mc-0397"` over the other capability-ledger audit TSVs present in the same directory (`c14-boundary-source.tsv`, `c14-candidate-evidence-manifest.tsv`, `c16-source-bound-evidence-manifest.tsv`, `c17c1/c17c2-c14-current-source-compatibility.tsv`, the `2026-08-08-*` variants, `c14-receipt-equivalence.tsv`) — no hits in any; these appear to be a separate prior audit scoped to different (likely structured-RE) cells, not these four.
12. Attempted `git log --all -S"mc-0001"` (no path filter) — timed out at the whole-repo scale (very large history from many prior audit lanes); not completed for `mc-0001`/`mc-0003`/`mc-0057`/`mc-0397` beyond the partial `mc-0001` output already showing unrelated ledger-restructuring commits (Wave-1 classification, census work) rather than any additional evidence artifact. Given queries 1–11 already establish a affirmative, well-corroborated answer for all four cells, this open-ended history search was not pursued further to completion.

## Not established

- Whether the `command`/`run_id`/`replicates` gap in `evidence.tsv` is
  deliberate (legacy migration didn't attempt to backfill structured fields
  from `driver.R`) or an oversight — I did not find a migration-design note
  explaining the omission for these rows specifically. NOT ESTABLISHED.
