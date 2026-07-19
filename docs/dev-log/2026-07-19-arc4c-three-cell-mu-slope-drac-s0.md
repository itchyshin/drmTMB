# Arc 4c S0: three-family `mu` random-slope coverage batch (DRAC)

**Status:** Pre-compute design ratified by Fisher and Rose; PR-A infrastructure implementation authorized by Shinichi on 2026-07-19. **Compute remains withheld: no smoke, DRAC submission, or campaign fit is authorized until the merged-PR-A Gate A approval.**

## Goal and scope

Evaluate each of the three remaining `mu` independent-random-slope cells separately:

| Cell | Family | Formula | Current tier |
| --- | --- | --- | --- |
| `mc-0464` | `skew_normal` | `bf(y ~ x + (0 + x | id), sigma ~ z, nu ~ 1)` | `point_fit_recovery` |
| `mc-0539` | `tweedie` | `bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1)` | `point_fit_recovery` |
| `mc-0575` | `zero_one_beta` | `bf(y ~ x + (0 + x | id))` | `point_fit_recovery` |

This reuses the frozen `mc-0242` ML-Laplace/profile-coverage policy. It is not an O3 campaign: `mc-0227` already used O3 because ordinal information was lower. It makes neither a pooled three-family claim nor a `supported` claim. A cell either earns a separately fenced `inference_ready_with_caveats` claim or retains `point_fit_recovery` with its negative evidence recorded.

## Frozen estimand and data-generating processes

The target is the population SD, 0.50, of the `mu` slope random effect `u[id] * x`, on the family-specific `mu` linear-predictor scale. It is scored against `confint(fit, parm = "sd:mu:(0 + x | id)", method = "profile")` on its natural RE-SD scale. The matching `log_sd_mu` Wald interval is reported only as a comparator.

Every replicate has iid, **uncentered** `u ~ N(0, 0.50)`, `x ~ N(0, 1)`, and independent seeds. This deliberately differs from the centered Arc-2b recovery fixture: the coverage estimand is the population SD, not the realised, mean-centered finite-group SD.

| Cell | Response DGP | `n_each` | M grid |
| --- | --- | ---: | --- |
| `mc-0464` | skew-normal with `mu = 0.2 + 0.6x + u[id]x`, `z ~ N(0,1)`, `sigma = exp(-0.3 + 0.15z)`, `nu = 1.6` | 12 | 8, 16, 32, 64 |
| `mc-0539` | Tweedie with `mu = exp(0.2 + 0.5x + u[id]x)`, `phi = 1.4`, `power = 1.5` | 12 | 8, 16, 32, 64 |
| `mc-0575` | zero-one Beta with `logit(mu) = 0.3 + 0.7x + u[id]x`, `phi = 6.25`, 15% balanced structural 0/1 observations | 15 | 8, 16, 32, 64 |

The runner will derive all three specs from the Arc-2b recovery constructors, changing only the random-effect draw from centered to iid uncentered. In particular, skew-normal retains the recovery fixture's `sigma ~ z`, rather than silently simplifying it. It must retain `sdrow = "log_sd_mu"`, `sd_parm = "sd:mu:(0 + x | id)"`, the raw replicate rows, a per-M manifest, and `sd_hat = exp(estimate)` for point-bias reporting at the coverage fixture.

## Gate and decision rule

For each cell and M, run N=1200 replicates and report all-attempts and conditional coverage separately: `hits / 1200` (primary, with a noncomputable interval scored as noncoverage) and `hits / n_profile_finite` (diagnostic only), each with MCSE and an exact binomial 95% interval. Also report finite-profile availability as `n_profile_finite / 1200`, all fit/convergence/Hessian/profile failures and messages, below-lower and above-upper misses, profile width, and mean RE-SD relative bias. The full campaign therefore has 3 x 4 x 1200 = **14,400 attempted fits**; denominators and verdicts are never pooled across families or M.

1. A profile availability rate of 1.000 is clean; `>= 0.99` can be promoted only with every failure disclosed and the primary all-attempts coverage meeting (2). `< 0.99` or any unrecorded failure withholds that M rung.
2. Calibration passes when the primary all-attempts exact-binomial interval intersects `[0.925, 0.975]`, or when its lower limit exceeds 0.975 (labelled conservative, never nominal). It withholds when its upper limit is below 0.925. Conditional-on-finite coverage cannot rescue an attempted-denominator failure.
3. Let `A` be the acceptable non-exploratory rungs. Promotion requires `64` in `A` and `A` to be a contiguous suffix of `{16, 32, 64}`. The deployment floor is the smallest member of that suffix. A hole or an unacceptable M=64 positive control withholds promotion pending diagnosis. A floor is **firmly nominal** only when its primary exact interval lies wholly within `[0.925, 0.975]`; boundary-overlap and conservative suffixes support at most `inference_ready_with_caveats`. M=8 is exploratory and never sets the floor.
4. Pre-registered diagnostic: ML-Laplace's low RE-SD bias predicts predominantly above-upper interval misses at small M. The opposite direction is a red flag requiring investigation, not an ad-hoc promotion.

The expected floor is M >= 16, not a promise. Skew-normal has slant-identifiability risk, Tweedie has low-information / near-zero-cluster risk, and zero-one Beta has fewer interior observations. Raw records additionally retain skew-normal `nu_hat` and a near-zero-slant flag, Tweedie zero and all-zero-cluster counts, and zero-one-Beta interior/boundary counts plus invalid-interior failures. These are per-cell risks, not grounds to alter the gate after results are known.

## Smoke, DRAC array, and reproducibility plan

After Gate A approval, dependency installation and a fresh-clone `pkgload::load_all` compile receipt precede the first model fit. The first model fit is then a one-replicate, exact-DGP smoke at every family x M. It must write a nonempty retained row, converge (`convergence == 0`, `pdHess = TRUE`), and return a finite in-range profile interval. An M=8 failure excludes only that exploratory rung. Any failure at M in `{16,32,64}` halts that family before all N=1200 tasks; the other families follow the same frozen rule independently.

The campaign has 12 logical family x M cells and at most 1,440 physical single-CPU array tasks. Every smoke-approved cell has 120 shards; shard `k` owns exactly replicate indices `10(k-1)+1` through `10k`. Each replicate resets the RNG with immutable seed `202607190 + r` immediately before simulation; the same r-seed across design cells is intentional and recorded. The immutable logical task ID is determined from cell order (`mc-0464`, `mc-0539`, `mc-0575`), M order (`8,16,32,64`), and `k=1,...,120`. No task shares an output path.

The new runner must persist one raw row for every attempted replicate (including errors) atomically within its shard. A shard is complete only with its exact ten unique assigned rows and a valid schema/checksum. A partial or inconsistent shard is quarantined and retried under the same logical task ID; partial and retried outputs are never merged. Aggregation requires, per approved cell, exactly 120 valid shards whose union is `r=1:1200`; duplicate, missing, wrong-cell, wrong-M, or checksum-invalid rows fail closed. Fir's live `MaxArraySize` is re-read before submission. If the selected manifest fits, submit one array with `%96`; otherwise partition deterministically while retaining logical IDs and a global concurrency ceiling of 96. More than 96 required partitions returns `BLOCKED_RESOURCE_LAYOUT` before any `sbatch`. An `afterok` job recomputes summaries only from valid retained rows. No simulation output is uploaded as a GitHub Actions artifact; the legacy `phase18-simulation-grid` workflow remains out of scope.

Before submission, the worker must verify Fir account `def-snakagaw_cpu`; clone the verified PR-A merge commit into a fresh `/project` run root; record `git status --porcelain`, source-tree checksum, compiler/R/TMB/module versions, `sessionInfo()`, R-library path, and a `pkgload::load_all` compile receipt; and build/load from that clone on a compute node, never the login node or stale installed drmTMB. R libraries and source live on `/project`; `/scratch` is task-local temporary I/O only. Every worker copies raw rows, manifests, checksums, Slurm environment, job IDs, session information, and logs back even if R exits non-zero. It pins `OMP_NUM_THREADS`, `OPENBLAS_NUM_THREADS`, `FLEXIBLAS_NUM_THREADS`, `BLIS_NUM_THREADS`, `MKL_NUM_THREADS`, and TMB threads to one. Smoke timing and RSS mechanically determine the full task request under the ratified ultra-plan; they cannot change the fixture, seeds, or gate.

After verified aggregation, the claim-bearing repository receipt is `docs/dev-log/simulation-artifacts/2026-07-19-arc4c-mu-slope-coverage/README.md`, with raw/summary/manifest/checksum sidecars below that directory. The durable DRAC `/project` run root is recorded verbatim in that README; raw campaign files remain local/`/project` under D-50 and are not GitHub Actions artifacts.

A shared seed from each promoted M will be rerun locally from the same source commit. The comparison includes `sd_hat`, profile endpoints, and status and must agree to approximately 1e-4 before using the DRAC evidence. The artifact README records commit, package version, module list, host, Slurm job/array IDs, seed base, command, grid, and copy-back paths.

## Promotion and closeout (only after results and D-43)

For every promoted cell, keep `estimator = "ML"`; a new estimator token would make the family-map slope appear absent. Key all ledger edits by `cell_id`, replace rather than append stale `notes`/`claim_boundary`, add an evidence row and `verified -> verified` transition, decrement the `point_fit_recovery` test expectation once per promotion, then run `capability_ledger.py --write`, `--check`, and `python3 -m unittest tools.tests.test_capability_ledger`.

Before a promotion, Fisher, Rose, and an independent Noether lens receive the frozen S0 and evidence in a memo-blind D-43 review. Two or more withholds block promotion. A failed cell still gets a diagnostic artifact, an explicit failed `next_gate`, and an after-task report; its tier does not change.

## Explicit stop boundary

PR-A infrastructure may be implemented, tested with pure-logic fixtures and ordinary package checks, reviewed, and merged. Then stop. Do not compile on a DRAC compute node, run any Arc 4c model fit or smoke, submit an array, or alter ledger status until Shinichi explicitly grants Gate A compute approval against the verified PR-A merge SHA.
