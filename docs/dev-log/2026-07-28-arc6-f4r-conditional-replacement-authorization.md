# Arc 6 F4R conditional replacement authorization

## Decision

On 2026-07-28, the owner authorized **one replacement F4R DRAC array only if
Rorqual job array `17551889` terminates incomplete**. This is a conditional
follow-on authorization; it does not change, cancel, extend, or overlap the
running original array.

## Frozen replacement contract

The replacement must retain the same:

- source SHA `18c37bbc8e472e79272056ce90e12a18f2379ff4`;
- private engine and fixture blobs recorded in the original runbook;
- 16-cell, 16,000-attempt F4R grid;
- 1,000 assigned replicates per cell; and
- frozen seed manifest.

It is a fresh, full `1-16` array, with **24 hours per shard**. It may use a
new immutable source snapshot and new empty scratch, durable-result, packet,
and log roots so it cannot overwrite or mingle with the original evidence.

## Activation and prohibitions

Before launch, the operator must retain and inspect `17551889`'s terminal
scheduler state and durable/scratch evidence. The replacement is permitted
only when that record proves that the original did not produce all 16 complete
shards with their 1,000 retained assigned attempts.

This authorization does not permit cancellation or overlap of `17551889`,
individual-shard retries, adaptive grid/seed/source changes, F5 work, public
API work, capability movement, or a public inference claim. It replaces the
original runbook's resource-exhaustion no-replacement clause only in this
specific terminal-incomplete situation; all other original provenance,
retention, and review rules remain in force.

## Next action

While `17551889` remains active, do not submit anything. If it completes all
16 shards, review that original evidence. If it terminates incomplete, prepare
and preflight the single 24-hour replacement packet, then submit it under this
receipt.
