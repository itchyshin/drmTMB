# Overnight staleness sweep — "results file frozen before the decision that superseded it"

Lane: `claude/lane-overnight-0815` · read-only sweep over
`/Users/z3437171/local-scratch/lanes/drmTMB-interval-truth-audit` · no R executed, no edits made
except this file.

## Method actually followed

1. Enumerated every `docs/dev-log/dashboard/*.tsv` (406 files) and every
   `docs/dev-log/simulation-artifacts/**/*.tsv` (1,941 files).
2. `grep -l` for decision-bearing column/value signals (`promotion_decision`, `review_decision`,
   `_status`, `pending`, `do_not_promote`, `planned`, `review_required`, `withheld`, `hold`) →
   190 dashboard files carry a `promotion_decision` column (all populated, all `do_not_promote`
   except one row-pair that carries `promote_exact_cell`); 57 carry `review_decision`; 18 carry
   `withheld`; 47 carry `review_required`; 1 carries a bare `hold` value outside the
   `promotion_decision` set.
3. For every file with a `cell_id` column, extracted `(cell_id, promotion_decision)` and looked the
   `cell_id` up in the two authority files: `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
   (104 Q-series rows, columns `interval_status`/`coverage_status` = current truth) and
   `docs/dev-log/dashboard/capability-ledger/cells.tsv` (741 `mc-####` rows, columns
   `capability_status`/`work_status`/`evidence_tier` = current truth).
4. Flagged every `cell_id` where the frozen file says `do_not_promote` but the authority file now
   shows a promoted tier (`interval_status`/`coverage_status` ∈ {`interval_feasible`,
   `inference_ready`} or ledger `evidence_tier` promoted past `point_fit_recovery`). First pass over-
   flagged (`interval_status = unsupported`/`diagnostic_only` are not promotions); refined to only
   count `interval_feasible`/`inference_ready`.
5. For every flagged file, read the full row, `git log --follow` its date, and read the linked
   `docs/dev-log/after-task/*.md` to establish which came first.
6. Spot-checked the largest non-flagged clusters (72 `gaussian-mu-slope-tranche55…126` spatial-DRAC
   dispatch files, 25 `q2-retained-denominator-tranche9…33` files, 15 `q4-location-tranche34…48`
   relmat files, the `structured-re-sigma-slope-spatial-animal-admission-audit.tsv` promotion pair,
   and every dashboard file whose only `mc-####` reference sits next to a `_status`/`_decision`
   column) by hand against the authority files, because the automated pass only covers files that
   use the `qseries_*` cell-id vocabulary.
7. Checked the AGHQ+Cox–Reid non-Gaussian REML arc (`docs/design/224`, after-task
   `2026-07-18-mc0227-o3-aghq-coxreid-coverage-promotion.md`, `2026-07-22-coxreid-claim-and-citation-audit.md`)
   against `structured-re-native-reml-scope-status.tsv` and `structured-re-reml-scope-gate.tsv`
   (both stopped at 2026-07-14) because the arc landed non-Gaussian REML capability afterward
   (2026-07-18/22) and looked at first read like a second instance of the defect class.

## Result table

| file | frozen verdict | later decision | class | pointer? |
|---|---|---|---|---|
| `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv` | `promotion_decision=do_not_promote`, `linked_interval_status=planned` for phylo/spatial/relmat/animal (all 4 rows) | `docs/dev-log/after-task/2026-06-30-q-series-q1-mu-sr475-inference-ready.md` promoted phylo/spatial/relmat to `interval_status=inference_ready`/`coverage_status=inference_ready`; animal correctly stayed `planned` | CONTRADICTED (given, confirmed instance) | YES — `docs/dev-log/dashboard/2026-08-15-sr475-results-supersession.md` |
| `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-nibi-smoke-results.tsv` | same 4 cells, same `do_not_promote` | same 2026-06-30 after-task | CONTRADICTED — same cluster, sibling artifact of sr475-results.tsv (identical commit `d1b029cb6`, 2026-06-30 18:54:22) | NO |
| `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-pregrid-results.tsv` | same 4 cells, same `do_not_promote` | same | CONTRADICTED — same cluster | NO |
| `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-smoke-results.tsv` | same 4 cells, same `do_not_promote` | same | CONTRADICTED — same cluster | NO |
| `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-pregrid-dispatch.tsv` | same 4 cells, same `do_not_promote` | same | CONTRADICTED — same cluster | NO |
| `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-topup-dispatch.tsv` | same 4 cells, same `do_not_promote` | same | CONTRADICTED — same cluster | NO |
| `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-smoke-contract.tsv` | same 4 cells, same `do_not_promote` | same | CONTRADICTED — same cluster | NO |
| `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-dry-run.tsv` | same 4 cells, same `do_not_promote` | same | CONTRADICTED — same cluster | NO |
| `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-retained-denominator-contract.tsv` | same 4 cells, same `do_not_promote` | same | CONTRADICTED — same cluster | NO |
| `docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-sr475-results-replicates.tsv` and the mirrored per-shard copies under `2026-06-30-gaussian-lowq-mu-intercept-topup-nibi/results/shard_{1..4}_*/` | raw per-replicate mirrors of the same 4-cell dataset, no independent `promotion_decision` semantics of their own (they are the input data, the dashboard files are the decision layer) | n/a | CONSISTENT (raw evidence, not a decision artifact — does not itself assert a verdict) | n/a |
| `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv` | only carries the animal row now (`do_not_promote`, `planned/planned`) | 2026-07-05 commit `3262655f5` removed the 3 promoted rows per the after-task's own instruction ("Removed the promoted rows from the Gaussian low-q audit") | CONSISTENT — correctly maintained | n/a |
| `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv` | only carries the animal row now | same repair | CONSISTENT | n/a |
| `docs/dev-log/dashboard/structured-re-sigma-slope-spatial-animal-admission-audit.tsv` | spatial row `do_not_promote` (still blocked); animal row `promote_exact_cell`/`inference_ready` | in-place edited across 4 commits 2026-06-28 (`2a450ba7b`→`060596f94`→`9eb2e35b3`→`914657590`); matches current `structured-re-q-series-support-cells.tsv` (`inference_ready`) and `structured-re-q-series-inference-evidence-summary.tsv` (`inference_ready_with_caveats`) exactly | CONSISTENT — actively maintained, not frozen | n/a |
| `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche33-q2-plus-parking-decision.tsv` (terminal state of the 25-file `tranche9…33` q2-plus saga) | `qseries_phylo_q2_plus_q2_intercept` parked `do_not_promote` | current ledger still `planned`/`planned` for this cell | CONSISTENT | n/a |
| `docs/dev-log/dashboard/structured-re-q4-location-tranche48-relmat-parking-decision.tsv` (terminal state of the 15-file `tranche34…48` relmat saga) | `qseries_relmat_q4_mu1_mu2_one_slope` parked `do_not_promote` | current ledger still `planned`/`planned` | CONSISTENT | n/a |
| `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche126-spatial-drac-patched-runner-packet-checkpoint.tsv` (terminal state of the 72-file `tranche55…126` spatial-DRAC dispatch saga) | `qseries_spatial_q1_mu_one_slope` checkpointed, next tranche (T127) explicitly "not_submitted" | current ledger still `planned`/`planned` | CONSISTENT (genuinely still open/blocked, not contradicted) | n/a |
| `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-hybrid-sr475-audit.tsv` | `qseries_{phylo,relmat,spatial}_q1_mu_one_slope` all `do_not_promote` (upper-tail miss imbalance) | `docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-sr475-topup.md`; current ledger still `planned`/`planned` for all three | CONSISTENT — never promoted, still correctly blocked | n/a |
| `docs/dev-log/dashboard/structured-re-q2-retained-denominator-review-decision.tsv` | `qseries_{phylo,spatial,animal,relmat}_q2_mu1_mu2_intercept` + `qseries_phylo_q2_plus_q2_intercept` all `do_not_promote_keep_point_fit_planned_planned` (SR150 undercoverage) | current ledger still `planned`/`planned` for all five | CONSISTENT | n/a |
| `docs/dev-log/dashboard/structured-re-q6-mu2-target-interval-feasible.tsv` (2026-08-01, most recent file checked) | `mc-0102`/`mc-0124`/`mc-0146`/`mc-0168` whole-cell `point_fit/planned/planned`, target-level `interval_feasible` | current `capability-ledger/cells.tsv` `evidence_tier=interval_feasible` for all four | CONSISTENT | n/a |
| `docs/dev-log/dashboard/structured-re-native-reml-scope-status.tsv` + `docs/dev-log/dashboard/structured-re-reml-scope-gate.tsv` (both stopped 2026-07-14, commit `6712e86f4`) | rows read as a blanket "non-Gaussian structured rows use ML or Laplace wording … no non-Gaussian REML claim is promoted" | `docs/design/224` + after-task `2026-07-18-mc0227-o3-aghq-coxreid-coverage-promotion.md` relaxed `R/drmTMB.R:352` to admit `binomial` under `REML=TRUE`, and promoted `mc-0227` (cumulative_logit) via a nested AGHQ+Cox–Reid lever — **checked closely; resolved as NOT a contradiction.** The team deliberately kept `estimator="ML"` in the ledger for `mc-0227` specifically to avoid tripping this gate (after-task §5, "Rose F2"); `vignettes/capability-and-limits.Rmd:126,155,166` documents binomial `REML=TRUE` as **diagnostic-only**, never promoted to an inference tier, which is exactly what the gate rows still forbid. `reml_non_gaussian_gate` in `structured-re-reml-scope-gate.tsv` is scoped to `count_structured`, not binomial/ordinal, so it is untouched. | CONSISTENT (verified by reading `R/drmTMB.R`, the vignette, and the 2026-07-22 citation-audit after-task, which exists precisely to keep the wording from drifting into a false "generic non-Gaussian REML" claim) | n/a |
| `docs/dev-log/dashboard/structured-re-relmat-q-drmjl-stack-review.tsv` | DRM.jl PR #297–#300 stack all `reviewed_green_keep_draft_until_*_accepted` / `CLEAN_DRAFT` as of 2026-06-26 | No later internal file references PR #297–#300 merge state; `check-log.md` only cites the same 2026-06-26 after-task. External GitHub PR state cannot be checked read-only/offline from this repo. | UNDETERMINED — queries run: `grep -rl "DRM.jl#29[7-9]\|DRM.jl#300\|pr297\|pr298\|pr299\|pr300" docs/dev-log/after-task/ docs/dev-log/check-log.md docs/design/` (1 hit, the source file's own after-task); `grep -n "DRM.jl#29[7-9]\|DRM.jl#300" AGENTS.md` (no hits) | n/a |

## Negative results (checked, no contradiction found)

- All 190 `promotion_decision`-bearing dashboard files cross-referenced against
  `structured-re-q-series-support-cells.tsv` (`interval_status`/`coverage_status`): only the 9-file
  sr475 cluster above flags as a genuine promoted-vs-frozen mismatch. Query:
  `python3` script joining `cell_id` across all 190 files against the authority TSV, first with a
  naive "any non-`planned` status = promoted" rule (284 false-positive rows — `unsupported` and
  `diagnostic_only` are negative/neutral states, not promotions), refined to only count
  `interval_feasible`/`inference_ready`, which reduced the flagged set to the 12 files reported above
  (9 real, 3 further false positives from files whose own schema already correctly records
  `interval_feasible` for a baseline-comparator row that was never meant to promote further —
  verified by reading `structured-re-gaussian-lowq-status-audit.tsv`'s own `linked_interval_status`
  column for `qseries_ordinary_q1_intercept` and `qseries_phylo_direct_sd_univariate`, both already
  correctly `interval_feasible`).
- `docs/dev-log/dashboard/capability-ledger/transitions.tsv`: `grep -ic pending` → 1 hit, not a
  frozen-verdict row (a `reason` field mentioning "pending" in prose, not a status column).
- 47 files carry `review_required` as a value; 33 of those are outside the already-checked
  `promotion_decision` set (mostly per-shard `structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv`
  copies replicated across `2026-06-30-gaussian-lowq-sigma-boundary-patch-sr*-local*` shard
  directories in `simulation-artifacts/`); spot-checked 3 representative shards — all carry the same
  sigma-intercept `do_not_promote` verdict, which matches the current ledger (`qseries_*_q1_sigma_intercept`
  cells remain `planned`/`planned`, separate from and not implicated by the mu-intercept sr475
  promotion). No contradiction.
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv` (the file carrying the one
  standalone `hold` value): a dated (2026-07-06) work-queue snapshot, not a verdict about a specific
  cell; its "8 inference-ready rows" figure was true on 2026-07-06 and is a planning artifact, not an
  evergreen claim — excluded from the class rather than marked CONSISTENT/CONTRADICTED because it
  does not assert a durable fact about a `cell_id`.
- Spot-checked 741-row `capability-ledger/cells.tsv` cross-references via the 3 dashboard files whose
  header mixes `mc-####` IDs with a decision/status column
  (`structured-re-native-reml-scope-status.tsv`, `structured-re-q6-mu2-target-interval-feasible.tsv`,
  `structured-re-reml-scope-gate.tsv`) — all three resolved CONSISTENT above.

## What this sweep does NOT cover

- The remaining ~1,900 `simulation-artifacts/**/*.tsv` files are almost entirely raw per-replicate
  data or seed manifests that mirror the dashboard summary files already checked; they are evidence
  inputs, not decision records, and were not exhaustively read row-by-row.
- Files with `_status`-only columns and no `promotion_decision`/`review_decision`/`cell_id` triple
  (the bulk of the 406 dashboard TSVs) were not individually re-verified against the ledger beyond
  the clusters spot-checked above (spatial-DRAC dispatch, q2-retained-denominator, q4-location
  relmat, sigma-slope admission, REML scope gates).
- No R was run; every "current truth" comparison used the two static authority TSVs
  (`structured-re-q-series-support-cells.tsv`, `capability-ledger/cells.tsv`) as recorded on disk,
  not a live re-derivation.

## Counts

- **CONTRADICTED:** 9 files (1 already known + pointed at — `structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv`; 8 newly identified siblings in the same cluster, same commit, same cells, no pointer of their own).
- **CONSISTENT:** 11 files/clusters checked and confirmed to match current ledger state.
- **UNDETERMINED:** 1 file (`structured-re-relmat-q-drmjl-stack-review.tsv` — depends on external GitHub PR state not verifiable read-only).
