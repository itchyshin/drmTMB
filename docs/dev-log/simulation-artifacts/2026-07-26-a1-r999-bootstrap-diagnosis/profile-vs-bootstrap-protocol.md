# Fresh A1 profile-versus-bootstrap campaign protocol — completed, exception under review

Status: the authorised full campaign completed and its row-level integrity
checks pass. A transient duplicate-launch breach reached 200 workers before
the older group was stopped, so strict protocol compliance awaits Shinichi's
ratification or a clean rerun. Fisher's review also withholds a profile-first
recommendation because of material directional misses.

## Frozen estimand and design

For

\[
y_{ij} = 1 + 0.5x_{ij} + b_i + \varepsilon_{ij},
\quad b_i \sim N(0, 0.5^2),
\quad \varepsilon_{ij} \sim N(0, 0.7^2),
\]

compare intervals for the natural-scale scalar target `sd:mu:(1 | g)` on the
same outer fitted datasets:

| Dimension | Frozen value |
|---|---|
| Family and RE structure | Gaussian, iid random intercept `(1 | g)` |
| Groups | 10, 25, 50 |
| Observations per group | 10 |
| True RE SD | 0.5 |
| Outer attempts | 1,000 per cell, all retained |
| Bootstrap | marginal percentile; `R = 999`; `bootstrap_re_form = NULL` |
| Profile | `method = "profile"`, `profile_engine = "auto"` |
| Comparator | Wald interval, recorded but not promoted |
| Unit of parallelism | 10 deterministic outer attempts per shard; 300 shards total |

The runner writes one wide row per attempt, including convergence, `pdHess`,
all endpoints, availability/failure status, profile engine/boundary status,
directional misses, elapsed time, host, timestamp, hashes for both executable
scripts, package version, and package commit. The full campaign fails before
launch unless `A1_REQUIRE_PROVENANCE=1` and `DRMTMB_COMMIT` is set.

## Smoke receipt

On Totoro, one deterministic attempt per cell with `R = 19` passed:

| Cell | Fit converged | pdHess | Bootstrap | Profile engine | Profile boundary | Wald |
|---|---|---|---|---|---|---|
| 10 groups x 10 | yes | TRUE | valid | endpoint | FALSE | valid |
| 25 groups x 10 | yes | TRUE | valid | endpoint | FALSE | valid |
| 50 groups x 10 | yes | TRUE | valid | endpoint | FALSE | valid |

This is a plumbing check, not coverage evidence. The authenticated Totoro
script SHA-256 is
`7dc63ca348c5df42519aa30e58066a8387b3bdfa9f62b2a8d2d4fd69aaf45cfc`.

## Approval and execution receipt

Before launch, Shinichi was presented:

1. this frozen protocol and the passed smoke receipt;
2. the R=999 conclusion that `R=199` is not dominant;
3. exact source/package hashes and the resolved `DRMTMB_COMMIT` value;
4. a command that uses at most 100 Totoro workers with `OPENBLAS_NUM_THREADS=1`;
5. output and log paths under `~/drm_work/`, no GitHub Actions execution or artifacts;
6. the statement that this remains a scalar-A1 method comparison, not a
   capability promotion or public default change.

Approval was received. The completed run used the specified 300-shard layout,
but a restart error briefly left two 100-worker launchers alive. The older
group was stopped. The data table passes row-level integrity checks, but this
execution breach requires ratification or a clean rerun before strict protocol
compliance can be claimed.

## Predeclared interpretation

Profile can support only a narrow future recommendation proposal when all
attempts are retained and its **all-attempt** coverage counts unavailable or
non-finite intervals as failures. It must have no more unavailable intervals
than bootstrap in any cell; in at least two cells, including 10 groups for a
low-group recommendation, satisfy
`abs(profile_coverage_all_attempts - 0.95) < abs(bootstrap_coverage_all_attempts - 0.95)`;
and have exact all-attempt coverage CIs overlapping `[0.925, 0.975]` in those
same cells. The report must show lower/upper misses, every unavailable endpoint,
and every profile-boundary flag; any material one-sided miss or boundary-heavy
pattern blocks a recommendation pending Fisher review. Rose and Fisher must
both approve any recommendation. Otherwise the output remains diagnostic
evidence and bootstrap remains the broad fallback.
