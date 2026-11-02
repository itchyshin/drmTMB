# Second-look execution adapter: plan and bounded probe evidence

**Historical status, as of 2026-10-18:** At that checkpoint, the first-look decision was `look2_required`. The v7 three-registry adapter qualification passed in 60.293 seconds, which is operational evidence only. The approved v8 second-look run started on Totoro and was stopped after 531.969 seconds when observed throughput made the sealed 132.6-minute projection implausible. Batch 1 recorded 366 completed fits, 16 interrupted cases, and 2,618 not started; batches 2 and 3 did not launch. This partial run is not a calibration result. See the v8 execution record below. The frozen [staged calibration contract](staged-calibration-contract.md) still controls the decision. Any restart requires a fresh runtime review and source-bound authorization; the old 132.6-minute estimate is no longer usable. The prior approval decision is superseded for execution by the interval-level correction below; no second look may run until corrected first-look replay and source-bound GO checks pass.

> **Current correction (2026-10-19):** the approved contract uses 95% fitted profile intervals and 97.5% Monte Carlo confidence intervals at the two repeated looks. The separately versioned `worker-0975.R` route and its first-look results followed an incorrect interpretation and remain historical exploratory evidence only. They cannot authorize a second look. The corrected first-look chain is versioned as `prepare-095.R`, `worker-095.R`, `summarize-095.R`, and `run-095.py`. The clean-current 95% first look has now completed 3,000 attempts and returned `look2_required`; see `evidence/calibration-20261019/current-source-bern-095-first-look-v4/` and the 2026-10-19 after-task report. This result does not make stage two eligible: source-bound replay verification, adapter redesign, and independent adapter qualification remain outstanding. Historical runtime projections for the 97.5%-profile route are not launch estimates; use a measured estimate for the approved 95%-profile worker.

> **Clean-current seed correction (2026-10-19):** the frozen clean-current look-one and look-two manifests use seeds 2026101901 and 2026101902, respectively, and exclude all historical streams listed in `staged-calibration-contract.md`. The older 2026101705 manifest and adapter specification below do not match this design. Preserve them as historical evidence only. The first-look preparation pins both clean-current manifests; its worker and summarizer verify look one against the frozen source. The stage-two adapter still requires redesign and independent qualification. No second-look work may run from this older specification.

> **Clean-current preflight update (2026-10-19):** a bounded source-validation slice now converts the frozen look-two CSV (SHA-256 `7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98`) into three exact 3,000-row batches and binds local indices to global source indices. The 95% runner and worker reject the wrong batch, seed stream, profile level, or source mapping before fitting; the combiner also checks every retained result row reports a 95% profile interval. Pure conversion, runner-gate, R mapping, and legacy-rejection tests pass. This is only a no-fit preflight slice: clean-current preparation/sealing, source-bound first-look replay receipt, independent three-fit qualification, end-to-end clean-current combination, and runtime authorization remain incomplete. No look-two fits were launched.

## Exact identity and model capsule

The source manifest has indices 1–9,000: indices 1–3,000 have truth `a=-0.5`, 3,001–6,000 have `a=0`, and 6,001–9,000 have `a=0.5`. **Each block has replicates 1,001–4,000**, master seed 2026101705, 160 groups and 16 observations per group. Its `design_mode=stage_two_not_authorized` is an immutable source label, not a worker mode. The adapter must preserve every source row and its seed. It must check that the 9,000 seeds are unique and disjoint from pilot, first-look production, and qualification streams, as the frozen seed producer specifies. It must not generate fresh seeds, relabel master 1705 as 1703, renumber replicates to 1–3,000, or edit the source CSV.

Use three fixed batches, each containing one complete truth block. A prepared batch `manifest.csv` has local `index=1:3000` because the versioned `worker-095.R` checks that index by row position. For batch `b` and local index `j`, `stage_two_index=3000(b-1)+j` and **`replicate=1000+j`**; the latter is never the local index. The batch also retains `batch_id` in 1:3 and the unchanged truth, seed, design parameters, and `master_seed=2026101705`. The worker-required `design_mode` is `production`; a separate, hashed conversion receipt records the original `stage_two_not_authorized` source label, the recorded GO digest, the exact source-row interval, the original manifest digest, and the new batch-manifest digest. This is an execution encoding, not a change to the frozen seed or decision rule. The global row key is `(look, stage_two_index)` for look two; `(look, first_look_index)` identifies first-look rows. A batch-local index alone is never a global key.

Prepare a **new isolated job capsule** from the corrected Bernoulli source snapshot and its matching installed R package, DLL, R runtime, and build receipt. The current Poisson source must never be paired with the Bernoulli DLL. Each batch gets a fresh, non-overwritten directory and a registry pinning the batch manifest, adapter, versioned `worker-095.R`, supervisor, generator, staged analyzer and contract, frozen source CSV, model sources, installed package files, DLL, and R executable. Seal the registry digest outside the job before launch. The old first-look registry remains untouched: its single pinned `manifest.csv` cannot also pin a different batch manifest. The adapter provenance records the first-look and new external registry digests and the source-to-installed-binary receipt. Hash equality of source and installed artifacts alone does not prove build provenance.

## Minimal new interfaces

Put the adapter under `tools/general-sd-regression/native-calibration-stage-two/`; do not edit the frozen first-look harness.

The bounded adapter implementation now exists in that directory. Its current
integrity contract requires a result file for every supervisor-completed case,
allows a failed or timed-out case's result file to be present or absent, hashes
every present result within the planned index range, and rejects files outside
that range. The worker writes a status row before fitting, so a partial file
from a failed case remains part of the digest.

The separate three-case adapter qualification also requires an external digest
of `adapter-qualification-preparation-receipt.json`. Capture and retain that
digest outside the prepared root immediately after preparation, then pass it as
`--preparation-receipt-sha256` to the runner. The receipt binds the three batch
registry and manifest digests. The runner checks the externally retained digest
before launching any worker, records it in the qualification receipt, and the
replay validator requires the recorded and observed hashes to agree. A missing
or stale source-bound first-look replay seal still blocks qualification; this
guard does not replace that independent evidence.

1. `prepare-stage-two.py CORRECTED_FIRST_LOOK_DIR CORRECTED_SOURCE_REGISTRY ISOLATED_LIBRARY FROZEN_STAGE_TWO_MANIFEST GO_RECORD CORRECTED_FIRST_LOOK_SEAL PILOT_MANIFEST QUALIFICATION_MANIFEST CORRECTED_FIRST_LOOK_MANIFEST NEW_STAGE_TWO_ROOT`: verify the corrected 95% first-look registry, manifest, supervisor, all result identities, and externally sealed `look2_required` decision; recompute the decision with the frozen analyzer only after replay rejects any wrong-level result. Verify the source CSV digest and seed disjointness. Emit three deterministic batch manifests and conversion receipts, source registries, and a root preparation receipt. Preparation runs without fits, refuses an existing output, and does not turn the source manifest's `stage_two_not_authorized` label into an apparent prior run. The GO record is an explicit input to the later execution gate, not a decision the adapter may infer from ambiguity alone.
2. `run-stage-two.py PREPARED_ROOT --external-seals FILE --outer-timeout SECONDS`: recheck the GO record, all three prepared registries against the externally retained digests, and the first-look trigger immediately before launch. Call the imported `run.supervise` directly for local indices 1:3,000 in each batch, with the versioned `worker-095.R` command and registry/library environment. The existing `run.py main` cannot be called: it rejects `master_seed=2026101705`. `supervise` itself does **not** perform preflight verification, so the adapter must call `integrity.verify`, check manifest/design/master/row mapping, compare the external seal, and verify installed-library identity first. Run batches sequentially with at most 16 workers, 120 seconds per case, and a bounded per-batch cap no greater than 3,300 seconds. An overall monotonic-clock cap no greater than 10,500 seconds (175 minutes, below three hours), including preparation checks and combination, must kill and reap adapter-owned worker process groups and retain terminal receipts. The historical 132-minute projection used the 97.5%-profile route and is not a runtime estimate for the approved 95%-profile worker. The current-source 45-fit 95%-profile timing pre-run is recorded in `after-task/2026-10-19-current-source-timing-pre-run.md`; re-estimate the exact 9,000-fit campaign and measure memory before launch. Proceed only if the measured estimate remains at most three hours and qualification passes. If it exceeds three hours, stop for a pre-run test and new human approval. No retry silently overwrites an attempt or result.
3. `combine-stage-two.R FIRST_LOOK_DIR BATCH1_DIR BATCH2_DIR BATCH3_DIR EXTERNAL_SEALS OUT_DIR`: authenticate all original and new registries, supervisor receipts, batch conversion maps, raw results, and the first-look decision. Normalize all 12,000 **planned** rows with the same health/interval/oracle predicates used by the frozen first-look summarizer, including rows with worker error or timeout. Compare the recomputed first-look standardized rows and decision with its retained evidence. Require exactly 4,000 rows per truth: 1,000 first-look plus 3,000 additional. Only after all identity and completion checks pass, call the unchanged `native_sd_staged_decision(attempts, manifest_count=12000L, look=2L, completed_campaign=TRUE)`. Write a new sealed decision receipt and all-attempt table, keeping status counts and the separate finite-estimate bias denominator. An incomplete or contradictory capsule yields `incomplete` or `integrity_failure`, never an acceptance flag. The frozen analyzer returns `accept`, `fail`, or `inconclusive` at look two; no third look or changed threshold is available.

The existing `supervise` receipt calls a full 1:3,000 local-index batch `campaign_complete=TRUE`. That means **batch completion only** here. It does not establish that all 9,000 additional rows or the 12,000 combined rows are complete. The combiner must inspect all three receipts and mapping tables. Terminal worker `error` and per-case `timeout` are retained as invalid attempts in the planned denominator; `launch_error`, `not_started`, interruption, campaign timeout, missing/duplicate files, wrong identity, or contradictory valid results prevent a look-two decision. A nonzero worker can leave a result row; its reported valid interval cannot override its supervisor status. No subset of successful fits can stand in for the complete manifest.

## Independent prelaunch and failure tests

Pure tests should use a tiny fake worker and synthetic CSV/receipt fixtures, not model fits, then a bounded three-case qualification of the complete adapter against the exact capsule before any 9,000-case run. Positive fixtures must prove batch-local 1:3,000 mapping to source 1:9,000, 1,000+3,000 rows per truth in the combined table, all-attempt invalid rows, and equality between recomputed and saved first-look decisions. A fake clock and owned child processes test the outer cap, signal cleanup, and no orphaned workers. The 9,000-case run itself remains a separate compute decision.

Negative controls must mutate one fact at a time and fail before fit launch or decision: original stage-two SHA; seed overlap or duplicate; batch `master_seed=1703`; swapped, missing, extra, or duplicate source/local rows; accidental conversion of source replicates 1,001–4,000 to local indices 1–3,000; changed truth, replicate, seed, or result filename; stale/missing external registry seal; altered DLL or source/build receipt; current Poisson source mixed with original Bernoulli installed package; first-look `accept`, `fail`, or incomplete receipt; changed saved first-look decision; supervisor `campaign_complete=TRUE` with unresolved cases; worker `valid_interval=TRUE` after error/timeout; missing completed-worker result; one interrupted batch; and a combiner fed 9,000 rows or only valid intervals. A synthetic look-two boundary fixture must reproduce the frozen analyzer's `accept`/`fail`/`inconclusive` rule without changing its 97.5% Monte Carlo uncertainty intervals or thresholds.

**Source audit receipt (2026-10-17; status at that checkpoint):** An independent standard-library CSV scan checked every row of the frozen source file against `index=3000(b-1)+j`, truth by fixed block, `replicate=1000+j`, master seed 2026101705, and the source design-mode label. All 9,000 rows passed, with 3,000 rows per truth and 9,000 distinct seeds; the file digest matched the pinned SHA-256 above. A deliberately wrong `replicate=j` conversion disagreed with all 9,000 source rows. Boundary rows `(source index, local index, truth, replicate, seed)` were `(1,1,-0.5,1001,190109013)`, `(3000,3000,-0.5,4000,1041181563)`, `(3001,1,0,1001,1138783083)`, `(6000,3000,0,4000,995150910)`, `(6001,1,0.5,1001,89366678)`, and `(9000,3000,0.5,4000,52143521)`. This audit establishes the source mapping only. Adapter code is now present and its integrity tests pass, but no second-look batch had yet been prepared or run.

**Reconstruction integrity checkpoint (2026-10-17):** The new source-bound reconstruction ran in Totoro capsule-04. Its v2 seal (`67bcd657226c168477c041710e7f1e6e12eadde4a305da97b2275cba256dafb0`) binds the original first-look seal, the independently pinned attempt archive (`4a5ba8a8f1092e366762b02cf733197a8c96ba8f4dd6d979b1fa71792286beb8`), all 3,000 raw result files, and SHA-256 values for the five reconstruction and verification sources. The full R replay returned `FIRST_LOOK_REPLAY_PASS standardized_rows=3000 decision=look2_required`; the standardized table and replay receipt hashes are `2b887af87bcce54d0088757d42524bcad20d95d5e96c92910fbd87f4f9f79ba6` and `f6eabe872e6af853e8985d202408d1a836cdbe502abf816e4332e4cd65c53f5a`. Independent local verification matched all five source hashes to the current code and checked the replay receipt against the seal and CSV. The earlier reconstructed v1 seal and receipt remain preserved as history but lack this source map and must not be used for preparation. Python integrity tests passed 19/19; the R stage-two rules and copied-manifest registry tests passed. This closes only first-look reconstruction provenance. Adapter qualification, second-look preparation, runtime measurement, and any additional fits remain open.


**Post-review correction (2026-10-17; status at that checkpoint):** A fresh read-only inference review found
that the v2 reconstruction seal does not bind the current adapter snapshot.
Current `stage_two.py` and `stage-two-rules.R` hashes differ from that seal. The
review also found that a healthy run-receipt batch hash map could fail comparison
because the JSON object parses as a list and `as.character()` drops its names.
The combination check now uses `native_sd_stage_two_hash_maps_equal()`, with a
JSON-shaped reordered positive fixture and mismatch, missing-key, and duplicate-
key controls. Current focused checks pass: Python 21/21,
`STAGE_TWO_R_RULES_PASS`, `PRIOR_SEED_STREAM_NEGATIVES_PASS streams=3`, and the
external registry test. The old 19/19 receipt remains historical and does not
validate this snapshot. The v2 seal still cannot authorize preparation: retain a
new source-bound reconstruction and replay receipt against the final adapter
sources, then obtain a fresh independent review. At the time of this historical
v2 review, no qualification capsule, qualification fit, or second-look campaign
had been prepared or run. The later v7 and v8 records below supersede that
status.

**Execution record placement:** Write a new local evidence GO record under `docs/dev-log/general-sd-regression/evidence/` and an accompanying remote root preparation receipt under `NEW_STAGE_TWO_ROOT/`, both outside the three batch directories. Pin the local record's digest outside the batch outputs and copy that digest into the remote root receipt; retain the remote root receipt's digest in local evidence as its external seal. They record the approved GOAL and plan SHA-256, authenticated first-look `look2_required` decision and its externally retained digest, first-look source/registry identity, adapter qualification receipt, measured runtime and calculation, and the 16-worker, 120-second case, 3,300-second batch, and 10,500-second outer caps. The remote root receipt pins the three batch-registry digests and the local GO record; neither batch workers nor summarizers may rewrite it. This is an operational record of the existing programme approval for a bounded run, not a request for another human decision. The frozen CSV's `stage_two_not_authorized` remains its historical source label. The first-look result and registry receipts need externally retained digests before the second-look capsule is prepared. These bindings do not change the statistical rule or seed set.

## Latest adapter probe record (2026-10-17)

The frozen three-truth adapter check ran against the sealed `prepared-v2` capsule
on Totoro. All three selected attempts completed with convergence code 0,
positive-definite Hessians, valid non-boundary profile intervals, and passing
Laplace-oracle checks. Their individual result files are bound in
[`adapter-probe-attempts.json`](evidence/calibration-20261017/adapter-probe-attempts.json).
The first-probe-to-last-probe span was 36.3356 seconds. The original runner's
whole-run elapsed value, including setup and final validation, was not retained.
The record therefore remains `INCOMPLETE` and `NOT_QUALIFIED`; it makes no
calibration claim and does not authorize or represent the 9,000-row campaign.

The receipt failure came from a formatting mismatch: the frozen CSV contains
`0`, while the validator expected the text `0.0`, even though the fit and worker
oracle both passed. Numeric truth comparisons now accept equivalent finite
decimal spellings, and an offline recorder verifies completed outputs without
launching or replacing fits. The original source-pinned capsule remains intact.
The three-fit record and its provenance are retained in the evidence directory;
the missing whole-run time must be addressed in a fresh, source-pinned
qualification run before the adapter can pass.

## Fresh v7 adapter qualification, 2026-10-18

The previous v2 probe note above is historical. A new source-bound preparation
and run completed on Totoro in 60.2931 seconds. All three selected Bernoulli
fits converged, produced valid profile intervals, passed the independent
Laplace likelihood oracle, and stayed within the per-case cap. The adapter
receipt records `PASS`, three attempted cases, `calibration_claim=false`, and
`campaign_complete=false`. It does not establish interval calibration or
complete the 9,000 planned attempts.

The prepared-v7 tree and receipts are retained under
`evidence/calibration-20261017/first-look-v4/adapter-qualification-v7/`.
The externally retained preparation digest is
`148667c74bdfddd5d7260b4c15656deb89f4550003f3394b2caaed0012685598`; the
qualification receipt digest is
`5f7ace0329835c5db4f4ce46bce1d3046e37285a4f4f08e2d5a549ca892aed20`.
Independent readback confirmed all three registries, manifests, supervisor
receipts, and selected result hashes. The copied registry files contain
absolute Totoro paths, so local readback verifies the retained bytes, not the
continued existence of those remote paths.

The existing 15-process Totoro timing receipt (SHA-256
`f23480f8f9dd52e88c947e93178a906979f03d63cbdababe7483f49039d5814b`) projects 2,652.14 seconds per
3,000-fit batch and 7,956.41 seconds for three batches, below the 10,500-second
outer cap then in force. It reports operational stress `PASS` but says
its repeated attempts are not independent. Its sealed registry digest is
`ad8ab89bf433f010f24e42e1662c0b221708556aaacd522225706973308f6265`; the
registry's historical 95% `worker.R` hash matches the unchanged frozen file and its compiled DLL hash
matches the v7 installed library. This establishes operational timing relevance
for that worker/library snapshot, not calibration. The subsequent v8 run used
recorded GO and fresh external preparation/run seals, but stopped incomplete as
recorded below.

## Interrupted v8 second-look attempt, 2026-10-18

The sealed Totoro run stopped after 531.969 seconds. Its batch-1 supervisor
planned 3,000 attempts: 366 completed, 16 were interrupted, and 2,618 were not
started. The retained batch has 381 result files: 366 completed, 12 still in
profiling, and 3 still marked started. One started case has no result file.
Every completed case belongs to truth `a=-0.5`; the run did not reach the other
truth blocks or the registered interim analysis. The run receipt is
`status=batch_1_incomplete`; the missing batch entries reflect the fail-closed
rule that adds a batch only after full validation.

The partial completed-case rate projects about 218 minutes for 9,000 attempts.
Summed case times project about 192 minutes at ideal 16-worker concurrency,
before overhead. Both estimates exceed the 175-minute outer cap, so the earlier
132.6-minute projection is no longer credible. These are rough extrapolations
from an interrupted subset, not a new production estimate. Do not restart until
a bounded timing review supports a revised run design and fresh seals.

All 366 completed fits converged, had positive-definite Hessians, passed the
independent likelihood oracle, and had inactive clamps. Those diagnostics apply
only to this selected partial subset. They do not establish coverage, bias,
false-positive rates, or calibrated uncertainty. The full 9,000-row second
look and the frozen staged decision remain outstanding.

## Independent no-retry continuation audit, 2026-10-18

An independent read-only review found no valid way to turn the v8 capsule into
a look-two calibration result under the frozen contract. Its supervisor
receipt partitions the 3,000 planned cases into 366 completed, 16 interrupted,
and 2,618 not started. The interrupted indices are
`365, 366, 367, 368, 369, 371, 373, 374, 375, 376, 377, 378, 379, 380, 381,
382`; only indices `383:3000` are untouched and eligible for a no-retry
technical continuation. The retained manifest SHA-256 is
`db27b71daa4701cacb41521ae7584f3977ece3779640c3de0ad9d5e0ce0b0a89` and the
supervisor-receipt SHA-256 is
`faa23cb6de466defb5be6c084453cdde06ce0f80a4616fc079b3c5e36f726447`.

The frozen staged contract counts error and per-case timeout outcomes as
invalid intervals within the planned denominator. It separately defines
`interrupted`, `not_started`, `campaign_timeout`, and `launch_error` as
unresolved states that make a claimed-complete campaign an integrity failure.
Therefore the 16 started cases cannot be retried or relabelled as ordinary
errors, and running only the untouched indices would not make this capsule
eligible for the frozen decision. The original v8 receipt and result files
remain immutable. Any attempt to use these data in a calibration decision
needs a prospectively reviewed and explicitly approved protocol amendment
with new source-bound receipts; otherwise a clean, independent calibration
campaign is required. No fits were launched during this audit.

The adapter itself also refuses to overwrite its run receipt. The general
supervisor can create a new subset directory, but that interface alone does
not satisfy the stage-two combiner or decision contract. The current measured
full-run estimate exceeds both the 175-minute adapter cap and the three-hour
approval line, so no replacement campaign may launch until fresh timing
evidence and the required approval are in place.
