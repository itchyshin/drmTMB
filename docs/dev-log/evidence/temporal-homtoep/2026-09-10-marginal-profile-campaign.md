# Marginal Toeplitz profile campaign — retained evidence receipt

**Status:** qualified for the frozen primary fixed-effect profile-interval claim.

The campaign evaluated the source-pinned marginal homogeneous Toeplitz model at
commit `b3a117edec97f6ad43d26a190e086c7451604cde`. It retains exactly one
attempt for each of 4,000 deterministic task IDs and uses worker MD5
`e01521b817f1c38c5acd2cf148e92b40`. The final immutable archive set and the
summary live on Totoro:

```text
/home/snakagaw/drmtmb-temporal-homtoep-b3a117edec97-totoro/artifacts/
/home/snakagaw/drmtmb-temporal-homtoep-b3a117edec97-totoro/assessment/
```

## Host transition and denominator

Fir job `59091538` completed task IDs 1--965 using one CPU and 2 GB per task.
Its remaining array elements were held after Fir capacity became intermittent.
The user authorised use of another computer; Totoro continued IDs 966--4000
from the same clean source commit, deterministic seeds, worker checksum, and
one-attempt rule. The host split is retained in Totoro's
`HOST-TRANSITION.md` and must be reported rather than collapsed into a
single-host performance claim.

Task 966 was the Totoro portability record: 1.72 seconds wall time and 241980
KiB maximum resident memory. The remaining 3,034 tasks ran at 150
single-threaded workers. The user authorised a shared 250-core ceiling across
Codex, Claude, and Cursor, but automatic approval review rejected a 250-worker
launch against the repository's then-binding 150-core Totoro limit. The actual
continuation therefore used 150 workers. All workers exited after completion.

## Immutable reverify

The first write and the later no-write reverify both returned:

```text
TEMPORAL_HOMTOEP_PROFILE_CAMPAIGN_SUMMARY_PASS
TEMPORAL_HOMTOEP_PROFILE_CAMPAIGN_QUALIFIED
```

The verifier unpacked each outer archive, required its one `attempt-001`
directory and all six required files, checked task IDs 1--4000, the exact
1,000-per-cell denominators, the source commit, and the worker checksum. It
did not load `drmTMB` or fit a model.

## Primary results

All nine primary coefficient--cell rows had availability 1.000 and met the
predeclared coverage and bias criteria.

| Cell | Coefficient | Coverage | Bias | Empirical SD |
| --- | --- | ---: | ---: | ---: |
| P1 | Intercept | 0.950 | 0.00153 | 0.05627 |
| P1 | between | 0.940 | 0.00006 | 0.10954 |
| P1 | within | 0.954 | 0.00033 | 0.05080 |
| P2 | Intercept | 0.931 | 0.00027 | 0.05108 |
| P2 | between | 0.942 | 0.00800 | 0.09933 |
| P2 | within | 0.941 | 0.00027 | 0.05048 |
| P3 | Intercept | 0.956 | -0.00006 | 0.02436 |
| P3 | between | 0.948 | 0.00201 | 0.05027 |
| P3 | within | 0.951 | 0.00368 | 0.06510 |

The S1 stress cell remains descriptive. Its intercept interval coverage was
0.916 (below the primary target); between and within coverage were 0.926 and
0.933. These outcomes were retained and do not alter the primary qualification.

## Reproduction command

Run on Totoro from the frozen source root; it reads the retained archive set and
does not launch any fits:

```sh
Rscript --vanilla tools/summarize-temporal-homtoep-marginal-profile-campaign.R \
  --input-dir=/home/snakagaw/drmtmb-temporal-homtoep-b3a117edec97-totoro/artifacts \
  --output-dir=/home/snakagaw/drmtmb-temporal-homtoep-b3a117edec97-totoro/assessment \
  --reverify
```

## Fir cleanup

After Totoro reverify, the held Fir remainder was cancelled. Its retained Slurm
receipt contains 965 completed elements and one cancelled held remainder, and
is stored at:

```text
/home/snakagaw/drmtmb-temporal-homtoep-b3a117edec97-totoro/fir-job-59091538-sacct.txt
```

The temporary Fir source, installed library, artifact directory, and transfer
bundle were then removed. Totoro is the sole durable evidence location.
