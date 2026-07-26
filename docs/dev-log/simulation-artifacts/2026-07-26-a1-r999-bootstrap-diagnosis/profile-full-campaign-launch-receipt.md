# Scalar A1 profile campaign: launch receipt

## Authorization and scope

Shinichi explicitly approved this Totoro campaign on 2026-07-26: 3,000 outer
fits, at most 100 workers, marginal `R = 999` bootstrap plus profile and Wald
intervals, all failures retained, and no GitHub Actions.

The campaign tests scalar Gaussian iid random-intercept SD inference only. It
does not implement Arc D, alter interval semantics, expose association-lane
code, change a public API, or promote a capability claim.

## Immutable launch contract

| Item | Value |
| --- | --- |
| Totoro result directory | `~/drm_work/results_a1_profile_full_20260726` |
| Totoro log directory | `~/drm_work/logs_a1_profile_full_20260726` |
| Package commit | `37091153b4bdd55a48a6de758d893d75eb9888dc` |
| Runner SHA-256 | `7dc63ca348c5df42519aa30e58066a8387b3bdfa9f62b2a8d2d4fd69aaf45cfc` |
| Helper SHA-256 | `083949bf1868d32a771b7124443f05f44a354b70598cd1703b2c2007a7731435` |
| Bootstrap | marginal percentile, `R = 999` |
| Cells | 10, 25, and 50 groups; 10 observations/group; true SD 0.5 |
| Outer attempts | 1,000/cell; 3,000 total |
| Parallel cap | 100 R workers; single-threaded numerical libraries |

The launcher checks the package version and profile interface, hashes both
source scripts before creating its manifest, writes one row per outer attempt,
and writes the completion timestamp only when all 300 ten-attempt shards return
successfully.

## Duplicate-launch containment

An early launcher defect was corrected before this campaign run. During the
restart, the prior process group was still active and resulted in two
100-worker launchers targeting identical deterministic shard paths. The older
group was terminated once confirmed; the remaining process group was checked
at exactly 100 live R workers. At that point partial shard CSVs existed, so no
interim statistic is usable: the campaign remains unauthenticated until the
surviving launcher completes and the analysis script verifies exactly 3,000
rows, 1,000 unique seeds per cell, and unique aligned source provenance.

This containment is recorded because it prevents a duplicate-launch accident
from becoming an unreported denominator or provenance error. It nevertheless
briefly violated the explicit 100-worker authorisation. The eventual table
passes its row-level integrity checks, but neither this receipt nor its
matching hashes can prove that every retained overlapping shard was written
only by the surviving launcher. Shinichi must ratify this exception or approve
a clean rerun before strict protocol compliance can be claimed.

## Maintainer disposition

On 2026-07-26, Shinichi ratified the contained overlap as **diagnostic-only**
evidence and separately authorised a clean, lock-protected, at-most-100-worker
rerun of the affected `g = 10` cell. The original table therefore remains an
honest diagnostic record; the clean rerun is the strict provenance repair. This
does not waive Fisher's independent directional-miss fence or promote profile
intervals to a public/default route.
