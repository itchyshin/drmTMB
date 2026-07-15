# Arc 1b-S1 admission and ledger migration plan

## Decision

Arc 1b-S1 needs a **stable-ID row split with two additive model-surface
cells**. Re-scope `mc-0199` to the exact admitted `mu1` endpoint, add one
`mu2` endpoint, and add one row for the still-rejected remainder.

- `mc-0107` and `mc-0108` are the two endpoint projections of the existing
  **ML** spatial q2 location block. They remain unchanged at
  `point_fit_recovery` and are comparator/prior-work evidence only.
- `mc-0199` already has the exact invariant axes `biv_gaussian`, `mu1`,
  structured spatial, bivariate, REML. Follow the Arc 3a migration precedent:
  narrow its formerly collapsed q-gate meaning to the admitted q2 intercept
  cell while retaining its legacy rejection evidence as immutable history.
- Add `mc-0672` for the matching `mu2` endpoint and `mc-0673` for the
  directly tested rejected remainder. This mirrors the endpoint granularity
  of `mc-0107`/`mc-0108` without attaching REML evidence to ML cells or
  erasing the old rejected region.

The maximum tier is `point_fit_recovery`. No interval, coverage,
`inference_ready_with_caveats`, or `supported` evidence transfers from the ML
block, the phylogenetic REML block, or another provider.

## Live baseline inspected

This plan was frozen against merged `main` commit
`29a4458addb550c9d82a9dc8c4324c15702e0591` on branch
`codex/arc1b-s1-spatial-q2-reml`.

The authoritative ledger rows are
`docs/dev-log/dashboard/capability-ledger/cells.tsv`; their imported evidence
and state history are in `evidence.tsv` and `transitions.tsv` in the same
directory.

| Cell | Current semantics | Arc 1b-S1 treatment |
|---|---|---|
| `mc-0107` | `biv_gaussian`, `mu1`, structured spatial, bivariate q2, **ML**, implemented/verified, `point_fit_recovery`; one endpoint of `qseries_spatial_q2_mu1_mu2_intercept` | Preserve byte-for-byte except for regeneration effects outside the row. Use as the ML comparator; do not replace its legacy primary evidence. |
| `mc-0108` | Same block and evidence as `mc-0107`, projected onto `mu2` | Preserve as the second ML comparator endpoint. |
| `mc-0199` | `biv_gaussian`, `mu1`, structured spatial, bivariate, **REML**, currently a broad representative rejection over every mean-side spatial q-gate and layout | Re-scope to the exact matched labelled q2 `mu1` endpoint, promote only to `point_fit_recovery`, and append new contract/recovery evidence plus `deferred -> verified`. Keep `ev-mc-0199-legacy` and the seed transition unchanged as pre-Arc evidence. |

At this baseline, `drm_validate_reml_spec_biv()` rejects every spatial
structured block at `R/drmTMB.R:2209-2215`, after the parser/builders have
already enforced matching bivariate spatial terms. A deterministic local
probe using the exact target produced:

```text
For bivariate models, `REML` currently supports only phylogenetic
(`phylo()`) mean-side structured effects.
```

The same blanket REML message currently covers matching slope-only q2,
matching intercept-plus-slope q4, and scale-only q2 inputs. Unmatched
endpoints, mismatched labels, mismatched coordinate objects/groups, and
`mesh =` forms fail earlier with their more specific parser/builder messages.
That order is useful test-of-test evidence: the target test must fail on the
REML gate before implementation, while malformed syntax must continue to fail
before reaching the new exception.

## Exact admitted cells

Append the following rows immediately after `mc-0671` and before the
`missing_response` rows. Shift only the numeric `source_order` of the 18
`mr-*` rows by two; their stable IDs and all substantive fields remain
unchanged.

| Field | Re-scoped `mc-0199` | New `mc-0672` | New `mc-0673` |
|---|---|---|---|
| `source_order` | retain `199` | `672` | `673` |
| `axis` | `model_surface` | `model_surface` | `model_surface` |
| `family_route`, `family_type`, `model_type` | `biv_gaussian`, `biv_gaussian`, `2` | same | same |
| `route_variant` | `arc1b_s1_exact_q2_intercept` | same | `arc1b_s1_remaining_spatial_reml` |
| `route_modifier` | `base` | `base` | `base` |
| `dpar` | `mu1` | `mu2` | `mu1` representative |
| `effect_type` | `structured` | `structured` | `structured` |
| `structure_provider` | `spatial` | `spatial` | `spatial` |
| `dimension` | `bivariate` | `bivariate` | `bivariate` |
| `q_gate` | `q2` | `q2` | `na` representative |
| `estimator` | `REML` | `REML` | `REML` |
| `capability_status` | `implemented` | `implemented` | `rejected_by_design` |
| `work_status` | `verified` | `verified` | `deferred` |
| `evidence_tier` | `point_fit_recovery` | `point_fit_recovery` | `none` |
| `test_gate` | `na` | `na` | `na` |
| `tranche_id` | `arc1b-s1` | `arc1b-s1` | `arc1b-s1` |
| `primary_evidence_id` | `ev-mc-0199-arc1b-recovery` | `ev-mc-0672-arc1b-recovery` | `ev-mc-0673-arc1b-remainder` |

Use the same claim boundary for both admitted endpoint rows, changing only the endpoint
name where clarity requires it:

> Arc 1b-S1 admits native-TMB bivariate-Gaussian REML only for the matched
> labelled location block `spatial(1 | p | site, coords = coords)` in both
> `mu1` and `mu2`. The coordinate-derived covariance is fixed; each location
> endpoint has an intercept-only structured member, while `sigma1`, `sigma2`,
> and `rho12` remain fixed-effect-only. An independent dense restricted-
> likelihood oracle and predeclared all-attempted recovery evidence support
> point-fit recovery only. This does not admit unlabelled, unmatched,
> slope-only, intercept-plus-slope, multiple-label, q4+, scale-side,
> q2-plus-q2, mesh/range-estimating, animal, relmat, non-Gaussian, AI-REML,
> interval, coverage, inference-ready, or supported claims.

Set `next_gate` to require a separately approved, target-specific interval and
coverage campaign before any inference promotion, and separate admission plus
recovery evidence for every excluded neighbour. Populate `updated_commit`,
`updated_date`, and `pr_url` only from the final landed Arc 1b-S1 state; do not
guess them in advance. Keep `issue_url` blank unless a real issue owns this
slice.

## Preserve the rejected remainder as `mc-0673`

Do not discard the rejection region that `mc-0199` previously collapsed.
Move its live remainder into the additive `mc-0673` row while preserving the
old `mc-0199` legacy evidence and seed transition as history:

- set `route_variant = arc1b_s1_remaining_spatial_reml` on `mc-0673`;
- retain `q_gate = na`, because it remains a representative rejected region;
- set `capability_status = rejected_by_design`, `work_status = deferred`,
  and `evidence_tier = none`;
- set `primary_evidence_id = ev-mc-0673-arc1b-remainder`;
- replace the blanket claim with the direct remainder: unlabelled matched
  intercepts, unmatched endpoints, slope-only q2, intercept-plus-slope q4,
  multiple or mismatched labels, partial or all-four location-scale blocks,
  and mesh/range-estimating forms remain outside Arc 1b-S1. The exact matched
  labelled q2 location-intercept exception is recorded only in
  `mc-0199`/`mc-0672`;
- append `tr-mc-0673-arc1b-remainder`, blank to `deferred`, linked to the
  fresh rejection evidence.

`mc-0200` and `mc-0201` remain the animal and relmat bivariate REML
rejections. `mc-0202` remains the spatial scale-only q2 REML rejection. The
new negative test file should exercise those three rows so an over-broad
provider or scale-side gate relaxation cannot pass silently. Their current
cell fields need not change unless the final implementation makes their
existing claim text or primary evidence inaccurate; if it does, append fresh
same-state rejection evidence rather than borrowing `mc-0199`'s record.

## Predeclared evidence records

Evidence is one-to-many. Each admitted endpoint gets its own records even
when both records cite the same joint fit and artifact.

| Evidence ID | Cell | Class | Minimum content |
|---|---|---|---|
| `ev-mc-0199-arc1b-contract` | `mc-0199` | `contract_test` | Exact target admission; current-head rejection as test-of-test; fixed-covariance, shared group/object/label, q2, intercept-only, location-only assertions; `mu1` extractor naming; exact dense restricted-likelihood equality at the optimum and displaced common parameter vectors. |
| `ev-mc-0672-arc1b-contract` | `mc-0672` | `contract_test` | Same joint contract, explicitly tied to the `mu2` endpoint and its SD/extractor target. |
| `ev-mc-0199-arc1b-recovery` | `mc-0199` | `model_recovery` | Authenticated Totoro/DRAC artifact; all attempted fits retained; `mu1` spatial SD and shared spatial correlation results; convergence, `pdHess`, boundary frequency, bias, RMSE, MCSE, and information response; source/raw hashes and reviewer verdicts. |
| `ev-mc-0672-arc1b-recovery` | `mc-0672` | `model_recovery` | Same artifact, with the `mu2` spatial SD explicitly reported; the shared correlation may be cited by both endpoint cells. |
| `ev-mc-0673-arc1b-remainder` | `mc-0673` | `rejection_test` | Direct malformed/rejected neighbour grid listed below, with exact current messages or stable message fragments. |

Each live row in the split receives one append-only transition:

```text
tr-mc-0199-arc1b-verified: deferred -> verified
  evidence_ids = ev-mc-0199-arc1b-contract;ev-mc-0199-arc1b-recovery

tr-mc-0672-arc1b-verified: "" -> verified
  evidence_ids = ev-mc-0672-arc1b-contract;ev-mc-0672-arc1b-recovery

tr-mc-0673-arc1b-remainder: "" -> deferred
  evidence_ids = ev-mc-0673-arc1b-remainder
```

The reason must say that only the exact matched labelled fixed-covariance
spatial q2 REML location-intercept block reached `point_fit_recovery`, and
that inference tiers and every neighbouring layout remain withheld. The
`actor`, `commit_sha`, and `date` must identify the actual final review state.

## Direct admission and rejection matrix

Put these cases beside the admission/oracle test rather than relying on a
generic source inspection. Use snapshots for user-facing errors where the
test suite's normal error-testing convention applies.

| Case | Formula difference from the target | Expected result after Arc 1b-S1 | Ledger relation |
|---|---|---|---|
| Exact target | Matching `spatial(1 | p | site, coords = coords)` in `mu1` and `mu2`; `sigma1 ~ 1`, `sigma2 ~ 1`, `rho12 ~ 1`; `biv_gaussian()`; `REML = TRUE` | Admit; exact oracle parity and extractor contract | Re-scoped `mc-0199`, new `mc-0672` |
| ML comparator | Same formula with `REML = FALSE` | Continue to fit; no row/evidence promotion | Existing `mc-0107`, `mc-0108` |
| Unmatched endpoint | Spatial term in `mu1` only | Reject as unmatched before REML admission | `mc-0673` remainder |
| Mismatched label | `p1` in `mu1`, `p2` in `mu2` | Reject with same-label contract | `mc-0673` remainder |
| Unlabelled pair | `spatial(1 | site, ...)` in both means | Reject: Arc 1b-S1 requires the explicit shared label | `mc-0673` remainder |
| Mismatched group/object | Different group or coordinate object across endpoints | Reject before REML admission | `mc-0673` remainder |
| Slope-only q2 | Matching `spatial(0 + x | p | site, ...)` | Reject; q2 dimension alone is insufficient | `mc-0673` remainder |
| Intercept-plus-slope | Matching `spatial(1 + x | p | site, ...)` | Reject q4+ | `mc-0673` remainder |
| Multiple labels/blocks | More than one spatial label or independent block | Reject | `mc-0673` remainder |
| Scale-only q2 | Matching labelled intercepts in `sigma1`/`sigma2`, means fixed | Reject | Existing `mc-0202` |
| Location-scale/q2-plus-q2 | Spatial endpoints extend beyond `mu1`/`mu2`, whether shared or separate labels | Reject | `mc-0673` remainder plus `mc-0202` boundary |
| Mesh/range-estimating | `mesh =` or any future estimated-covariance grammar instead of the fixed `coords =` path | Reject as unimplemented | `mc-0673` remainder |
| Animal or relmat analogue | Same q2 mean block using `animal()` or `relmat()` | Reject under REML | Existing `mc-0200`, `mc-0201` |
| Non-Gaussian or AI-REML | Change family or estimator | Reject at the existing family/estimator gate | Outside the new rows |
| Random `rho12` | Any random/structured syntax in `rho12` | Reject | Outside the new rows |

The currently observed pre-implementation messages establish that the first
five malformed cases are not aliases of the target. After implementation,
the exact target alone should cross the new REML admission helper.

## Generator and surface migration

The additive row split changes the model denominator from 671 to **673** and
the status/work counts from `301/330/40` to **`303/330/40`**
(`implemented/rejected_by_design/not_implemented`; equivalently
`verified/deferred/backlog`). Expected evidence-tier counts become 161
`point_fit_recovery`, 373 `none`, and all higher tiers remain unchanged.

Update source contracts before regenerating:

1. `tools/capability_ledger.py`: keep `IMPORTED_MODEL_COUNT = 668`; set
   `MODEL_SURFACE_COUNT = 673`; update the hard-coded status count gate to
   `303/330/40`.
2. `docs/dev-log/dashboard/capability-ledger/schema.json`: set
   `expected_counts.model_surface = 673`.
3. `tools/tests/test_capability_ledger.py`: update denominator/status counts;
   add an Arc 1b-S1 test that asserts the two admitted rows' exact estimator,
   provider, q-gate, statuses, primary evidence ownership, and exclusion
   wording; assert `mc-0673` remains rejected with the exact exception named;
   assert `mc-0107`/`mc-0108` remain ML with their original primary evidence.
4. `docs/dev-log/dashboard/capability-ledger/README.md` and
   `docs/dev-log/dashboard/README.md`: describe 673 cells, the immutable
   imported range `mc-0001`--`mc-0668`, Arc 3a rows `mc-0669`--`mc-0671`, and
   Arc 1b-S1's re-scoped `mc-0199` plus additive rows
   `mc-0672`--`mc-0673`.

Then run `python3 tools/capability_ledger.py --write`. Stage only the generated
files whose bytes change, but inspect every generated output. The directly
affected generated surfaces are:

- `docs/dev-log/dashboard/capability-census/_master.tsv`;
- `docs/dev-log/dashboard/capability-census/_widget_data.json`;
- `docs/dev-log/dashboard/capability-census/biv_gaussian.tsv`;
- `docs/dev-log/dashboard/capability-surface.md`;
- `docs/dev-log/dashboard/capability-surface.html`;
- `vignettes/includes/capability-ledger-family-map.md`.

The generator also checks/writes the missing-response include and MR tranche
summaries; they should remain substantively unchanged. Do not hand-edit any
generated file.

## Verification gate

Before claiming the migration complete, run:

```sh
python3 tools/capability_ledger.py --write
python3 tools/capability_ledger.py --check
python3 tools/capability_ledger.py --summary
python3 -m unittest tools/tests/test_capability_ledger.py
R_PROFILE_USER=/dev/null Rscript --no-init-file tools/check-capability-runtime.R
python3 tools/validate-mission-control.py
```

Read back the HTML filter count as `673 of 673 cells`, inspect re-scoped
`mc-0199` and both new rows in the generated `biv_gaussian.tsv`, and search the active reader surfaces for
the now-false blanket statement that bivariate spatial REML is always
rejected. The final claim remains exactly one fixed-covariance matched
labelled intercept-only q2 cell at `point_fit_recovery`; PR #781 remains
untouched.
