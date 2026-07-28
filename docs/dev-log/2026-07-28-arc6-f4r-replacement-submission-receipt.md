# Arc 6 F4R replacement submission receipt

## Trigger

The original Rorqual F4R array `17551889` reached a terminal incomplete state:
five shards completed and eleven timed out at the original 12-hour limit. Its
retained scratch evidence contains 13,790 protocol-valid attempt records. This
satisfies the owner's 2026-07-28 conditional authorization for one fresh,
full-campaign replacement.

## Submitted replacement

| Item | Receipt |
| --- | --- |
| Rorqual array | `17603598` |
| account | `def-snakagaw_cpu` |
| source SHA | `18c37bbc8e472e79272056ce90e12a18f2379ff4` |
| source snapshot | `/home/snakagaw/arc6-f4r-replacement-18c37bbc8/source` |
| scratch root | `/scratch/snakagaw/arc6-f4r-replacement-18c37bbc8/shards` |
| durable results | `/home/snakagaw/arc6-f4r-replacement-18c37bbc8/results` |
| packet/log root | `/home/snakagaw/arc6-f4r-replacement-18c37bbc8/packet`, `/home/snakagaw/arc6-f4r-replacement-18c37bbc8/logs` |
| resources | `1` CPU, `8G`, `24:00:00` per task |
| array | exactly `1-16` |

The replacement uses the original frozen 16-cell / 16,000-attempt grid and
seed manifest. Its copied source receipt retains the expected private engine
blob `d090f67b74bf5dfee6baa4396a8f45a3c977d6fd` and fixture blob
`d36b02b2ad470e641843d4f751ee1c998e6922bf`.

## Boundary

This is the one authorized full replacement, not an individual-shard retry.
It does not authorize F5, public API work, capability movement, or a public
inference claim. Review begins only after its full retained evidence is
terminal.
