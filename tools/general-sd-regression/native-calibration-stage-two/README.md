# Native Bernoulli SD calibration: optional second look

> Current gate correction (2026-10-19): fitted profile intervals use 95%; 97.5% applies to the Monte Carlo intervals across the two looks. The old `worker-0975.R` first-look run is historical only and cannot authorize stage two. The corrected first-look chain is `prepare-095.R`, `worker-095.R`, `summarize-095.R`, and `run-095.py`. A new 95% first look and full replay are required before this optional second-look route is eligible.

These scripts adapt the frozen 9,000-seed stage-two manifest to the existing
Bernoulli worker. They do not make seeds or fit models during preparation. The
approved programme permits the optional second look only after the frozen
first-look decision, adapter qualification, source-relevant runtime check, and
externally retained GO and run seals all pass. The contract in
`docs/dev-log/general-sd-regression/stage-two-execution-design.md` controls
the statistical and execution rules.

The v8 second-look attempt started on Totoro and stopped after 531.969 seconds.
Batch 1 recorded 366 completed, 16 interrupted, and 2,618 not-started attempts;
batches 2 and 3 did not launch. This is not a calibration result. The prior
7,956-second estimate for 9,000 attempts is contradicted by observed throughput
and must not be used to authorize a restart. See the execution-design record
for the retained receipts and runtime arithmetic.

The fresh v7 three-registry adapter qualification passed on Totoro in 60.293
seconds. Its receipt records three completed probes, `calibration_claim=false`,
and `campaign_complete=false`. This clears adapter operation only. It does not
establish interval calibration and does not complete the second-look campaign.
The prior v2 probe note remains historical.

That receipt pins the legacy `stage-two-manifest.csv` (SHA-256
`8fd627ccb8a7f8689c56e629a5ff12e53405be1a508167216632bcf445652e96`). The
clean-current `look2.csv` has a different frozen SHA-256
(`7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98`), so the
legacy PASS does not qualify the clean-current adapter. The earlier
clean-current path accepted `look2.csv` through an explicit
`--source-mode clean_current` option. Its three qualification probes were rows
1, 4001, and 8001 from the same 9,000-row stream later used for calibration.
Because the qualification runner requires those probe fits to pass health
checks, reusing them in the calibration denominator creates outcome-dependent
selection. The clean-current fit-qualification path is now rejected by the
resolver, runner, and receipt validator. Prior fit-free tests established
identity mapping only; they did not establish independent qualification. Keep
the frozen look-two manifest unchanged. A replacement must use a separately
hashed, seed-disjoint manifest, such as a reviewed design based on the
independent timing stream, and must be qualified against the exact installed
source before any look-two GO record can pass.

The separate `prepare-adapter-qualification.py` /
`run-adapter-qualification.py` path remains usable for the legacy source only.
Its clean-current mode now fails closed until independent qualification seeds
and a matching source-bound runner are implemented. Preparation verifies the retained
first-look seal and raw replay, original Bernoulli source/library receipt,
frozen 9,000-row source, and deterministic prior streams. It creates three
full, isolated 3,000-row registries. The runner attempts one row in each:
batch-local indices 1, 1001, and 2001, corresponding to global stage-two rows
1, 4001, and 8001 (truths -0.5, 0, and 0.5; replicates 1001, 2001, and 3001).
Each supervisor receipt must say `subset_complete: true` and
`campaign_complete: false`. The aggregate qualification receipt binds all
three registry, manifest, supervisor, and result hashes and explicitly sets
`calibration_claim: false`. It is an adapter check, not a calibration result
or authorization to run the 9,000 stage-two fits. The final GO validator
requires this exact three-registry receipt schema; older single-registry or
master-1704 qualification receipts are rejected.

After preparation, calculate and retain the digest of
`adapter-qualification-preparation-receipt.json` outside the prepared root.
Pass that independently retained value to
`run-adapter-qualification.py PREPARED_ROOT --library LIBRARY
--preparation-receipt-sha256 SHA256`. For clean-current, add
`--source-mode clean_current` to both preparation and run commands. The runner
checks the independently retained digest before inspecting
batch registries or launching a worker; the preparation receipt binds all
three registry digests. The final qualification receipt carries both the
expected and observed preparation digest, and replay requires them to match.

`prepare-stage-two.py` requires the completed first-look directory, its pinned
source registry, the original Bernoulli library, the frozen seed CSV, the
externally recorded GO record and first-look seal, and exactly three prior
manifests (pilot, qualification, first look), followed by a new output root.
The first-look seal must bind its registry, readable `look2_required`
decision artifact, and raw-attempt digest; it must also carry the pinned
Bernoulli source archive and the source-to-installed-library match list.
Preparation fails if any prior streams overlap the stage-two seeds.

The GO record JSON binds `look: 1`, `decision: "look2_required"`,
`first_look_registry_sha256`, and `first_look_decision_sha256`. After
preparation, retain the printed `root-preparation-receipt.json` digest outside
the output tree. Before running, the external seal JSON must bind the GO file
and digest, first-look seal and directory, decision path, root preparation
receipt digest, and all three `batch_registry_sha256` values keyed by `1`,
`2`, and `3`. The launcher requires the SHA-256 of that run-authorization
seal, then rechecks every binding and replays the first-look raw attempts
immediately before calling the frozen supervisor. Its run receipt records the
authorization-seal digest and each terminal batch's raw-attempt digest.

The GO file must also record `approved_goal_id`, paths and matching SHA-256
values for the approved goal and plan, and hashed paths to the adapter-qualification and timing
receipts, the qualification source-registry digest, three batches, the
projected total runtime (three times the measured per-batch projection), and
the exact frozen worker/case/batch/outer caps. Qualification must say
`operational_qualification: PASS` with `calibration_claim: false`; timing must
pass its bounded stress gate. The launcher verifies both receipt hashes and
their required fields before preparation or execution proceeds.

The retained timing receipt is source-relevant: its sealed registry binds the
same historical `worker.R` and compiled DLL hashes as the v7 qualification. It projects
7,956.41 seconds for three batches, below the frozen 10,500-second outer cap.
The timing repetitions are operational attempts, not independent calibration
replicates.

Run only after the approved look-one decision is verified, the timing evidence
matches the exact worker/library snapshot, and the measured runtime remains
within the approved three-hour bound. The launcher processes
three batches sequentially, with at most 16 workers, 120 seconds per case,
3,300 seconds per batch, and 10,500 seconds overall. The total deadline starts
before launch-time preflight and is recorded in the run receipt; the combiner
checks that same deadline before and during combination. A case-level timeout
remains an invalid planned attempt, while campaign timeout, launch error, or
interruption blocks the next batch and prevents a combined decision. It does
not retry or overwrite attempts. After execution, create a separate combination seal
containing `run_authorization_seals_sha256`, the run-receipt SHA-256, and the
three `batch_attempt_sha256` values. Pass the combination-seal SHA-256 as the
required integrity argument to `combine-stage-two.R`. This two-seal design
avoids a digest cycle: the run receipt binds the authorization seal, while the
combination seal binds the run receipt and outputs. It also pins the unchanged
staged analyzer path and SHA-256. Then run `combine-stage-two.R` against the
first-look and all three
batch directories. It verifies every attempt identity, recomputes the
first-look decision and metrics, requires 4,000 planned attempts per truth,
and calls the unchanged look-two decision function. Its output preserves all
12,000 planned attempts and the exact decision receipt. Only `accept`, `fail`,
or `inconclusive` produce the `STAGE_TWO_COMBINE_COMPLETE` marker and a zero
exit status. A nonqualifying decision such as `incomplete` or
`integrity_failure` is retained in the receipt, emits
`STAGE_TWO_COMBINE_NONQUALIFYING`, and exits nonzero.

`test_stage_two.py`, `test-stage-two-rules.R`, and `test-prior-seeds.R` exercise
pure identity, mapping, seal, timeout, deadline, and deterministic-seed rules.
`test-combine-stage-two.R` additionally invokes the real combiner on sealed,
no-fit synthetic inputs and injects an impossible analyzer state to verify the
nonqualifying subprocess marker, exit status, and retained receipt. This is
defensive process-boundary evidence, not statistical evidence. None of these
tests qualifies the adapter. The v8 partial execution is recorded in the
execution-design document. No combined look-two analysis or calibration claim
has been produced.
