# Prepare-only Totoro approval packet — scalar A1 ML versus REML

## Request that will require fresh written approval

Run a future paired scalar-A1 ML-versus-REML profile/Wald coverage study on
Totoro only.  This file is a packet, not authorization and not a launcher.
It is eligible for review because the six-row oracle now passes; it does not
turn that readiness evidence into compute authority.

## Frozen run contract

| Field | Contract |
| --- | --- |
| Scope | Gaussian iid scalar random-intercept SD only; three frozen A1 cells |
| Attempt unit | one generated outer dataset with both ML and REML retained |
| Maximum workers | 100 total live workers |
| Threads | `OPENBLAS_NUM_THREADS=1` |
| Output | unique run root, per-attempt shards, all failures retained |
| Provenance | immutable source snapshot, runner/helper/oracle hashes, installed tarball SHA-256 |
| Safety | atomic run lock, cleanup trap, worker-count check, append-safe merge |
| CI policy | never GitHub Actions and never GitHub artifacts |

## Required pre-launch evidence

1. Oracle receipt passes for ML and REML at every group count.
2. The six-arm local smoke is non-empty, paired, target-correct, and retains all
   statuses.
3. Source snapshot, installed package tarball, runner, helper, and oracle script
   hashes are recorded in the manifest.
4. The exact command, worker count, output root, expected wall time, and storage
   estimate are presented to Shinichi and approved in writing.

## Frozen pre-launch identifiers

| Item | SHA-256 |
| --- | --- |
| `a1_ml_reml_smoke.R` (proposed campaign runner) | `cb4ff4020be5ade71c500c5fb85a3dab190ec0ece3a53a318393306814010076` |
| `analyse_a1_ml_reml_smoke.R` (merge checker) | `b84f717b276f17d5af3ebef7686417b6d3b11f995c84b2f38b98a988cbe456c2` |
| `launch_a1_ml_reml_full.sh` (lock-protected launcher) | `8dafbc8c53054577742287fcf54efd3ce7cedff79f579324d81059aaf8720cd3` |
| `a1_ml_reml_common.R` | `f23ee237b00c93f4b5ac20355679b86384278f051ee05dd4e980739eaf2f7178` |
| `a1_ml_reml_oracle.R` | `557cfcab8edec40f9a0f1c3f0b2229369d50a5bcd99f71387013672a8fb9fafc` |
| built `drmTMB_0.6.0.tar.gz` | `9fc6ad979ce0fcdffe83134e27352bb3af8efb4470c63ec4a5f303ffe731237c` |

The campaign is 3 cells × 1,000 paired outer attempts.  Its merge checker is
called with `1000` and rejects any missing or unexpected `(cell_id, seed,
attempt_id)` key before calculating all-attempt coverage or paired contrasts.
Each attempt uses one outer dataset, fits both estimators, and retains two rows
even when only one estimator fails.  The proposed execution uses at most 100 workers and
`OPENBLAS_NUM_THREADS=1`.  Wall time and storage are deliberately estimates to
be measured in the first authenticated shard, then recorded in the execution
manifest; they are not asserted from the six-attempt plumbing smoke.

## Stop conditions

Do not launch if a lock already exists, the worker count exceeds 100, any
provenance hash is missing, an output root already contains campaign shards, the
first completed shard lacks both estimator rows, or the initial merged output
has duplicated `(cell_id, seed, attempt_id, estimator)` keys.

## Explicitly excluded

This packet does not authorize Arc D, endpoint-clamp interpretation, bootstrap
correction, public interval guidance, capability promotion, association work, or
any non-Gaussian or structured random-effect study.
