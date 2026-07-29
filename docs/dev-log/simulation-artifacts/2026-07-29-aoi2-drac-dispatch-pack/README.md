# AOI-2 Bernoulli × ordinary-NB2 DRAC dispatch pack

## Status and authority

**PREPARED, NOT AUTHORIZED, AND NOT SUBMITTED.**  This is a prospective
point-recovery packet for AOI-2.  It contains no scheduler script and no
remote-cluster action.  Its purpose is to make the next owner decision
specific and auditable, rather than to imply that a DRAC run has started.

The AOI-1 implementation baseline was `00c75b79c` on `codex/aoi-full-fixed`
(the implementation commit is `90c186611`).  The owner-approved run must
freeze and record the exact later commit that contains this packet.  It is
limited to frozen-margin,
complete-pair, fixed-effect-ML Bernoulli × ordinary-NB2 associations with
`kernel = latent_normal()`.  It does not construct or report standard errors,
covariance, intervals, profiles, coverage, capability changes, or a public
association-inference claim.

The packet is governed by
[`../../2026-07-29-aoi2-aoi3-validation-protocol.md`](../../2026-07-29-aoi2-aoi3-validation-protocol.md)
and follows the one authorised local smoke receipt in
[`../2026-07-29-aoi2-local-smoke/README.md`](../2026-07-29-aoi2-local-smoke/README.md).

## Frozen AOI-2 grid

Each cell has 200 independent outer datasets.  The 15 cells are the Cartesian
product of `n = 360, 720, 1440` and the five formula/DGP rows below.  The run
uses 60 array shards (four non-overlapping 50-replicate shards per cell).  No
shard may overwrite an existing result directory.

| ID | Association formula | True alpha (encoded coefficient order) |
| --- | --- | --- |
| `additive` | `~ x1 + x2` | `(Intercept)=-0.15`, `x1=0.40`, `x2=-0.25` |
| `mixed` | `~ x1 + habitat` | `(Intercept)=-0.10`, `x1=0.35`, `habitatforest=0.20` |
| `factor_interaction` | `~ x1 + habitat + x1:habitat` | `(Intercept)=-0.10`, `x1=0.30`, `habitatforest=0.15`, `x1:habitatforest=0.20` |
| `numeric_interaction` | `~ x1 + x2 + x1:x2` | `(Intercept)=-0.10`, `x1=0.30`, `x2=-0.20`, `x1:x2=0.20` |
| `transformation` | `~ x1 + I(x2^2)` | `(Intercept)=-0.10`, `x1=0.30`, `I(x2^2)=0.20` |

For each dataset, `x1` and `x2` are independent standard-normal draws.  The
factor has exactly balanced `field`/`forest` allocation, randomly permuted;
this prevents an accidental missing level.  The design matrix is constructed
with `stats::model.matrix()` before outcome simulation and must have the
declared coefficient names and full column rank.  A design failing either
check is a retained `dgp_design_error` attempt, not a replacement draw.

The binary margin is `binary ~ x1 + x2` with
`Pr(binary = 1) = plogis(-0.2 + 0.25*x1 - 0.10*x2)`.  The ordinary-NB2 margin
is `count ~ x1 + x2, sigma ~ 1`, with mean
`exp(0.5 + 0.15*x1 - 0.10*x2)` and `sigma = 0.6`.  A latent bivariate-normal
draw uses the true row association
`0.999999*tanh(X_A*alpha)`, then the package's existing NB2 normal-quantile
helper creates the count.  Both margins are refit before every association
fit.

## Retained data and analysis rule

Each raw row must retain: source SHA; formula ID; sample size; replicate and
seed; design fingerprint and encoded column order; fit status; error/failure
stage and message; every alpha estimate/truth; five fixed new-data link
predictions/truth; convergence/pdHess diagnostics; and elapsed time.
The denominator is all 200 generated outer datasets per cell, including
design, margin, association, prediction, and boundary failures.  Failed or
unavailable estimates are not silently replaced or dropped.

The campaign is **point recovery only**.  It will report coefficient-wise and
fixed-newdata-link bias/RMSE plus availability and failure taxonomy.  A
preliminary point-recovery gate requires, for each claimed cell, all 200
attempts retained, at least 95% usable interior association fits, and absolute
bias no greater than 0.10 for every declared coefficient and fixed new-data
link target.  This is a decision gate for further AOI work, not an interval or
capability criterion.  The `n = 360` rows are stress diagnostics; no
lower-sample-size claim is made solely from a pass there.

The five fixed prediction rows are `(x1, x2, habitat)` equal to
`(-1.0, -0.7, field)`, `(-0.5, -0.2, forest)`, `(0.0, 0.0, field)`,
`(0.5, 0.3, forest)`, and `(1.0, 0.8, field)`.  They are identical in every
outer replicate, so their eta diagnostics have an unambiguous known truth.

The committed `tools/summarize-aoi2-bernoulli-nb2-recovery.R` analyser refuses
missing, duplicate, or malformed cell keys, writes the retained-denominator
receipt separately from coefficient/link diagnostics, and emits only
`PASS_POINT_RECOVERY_ONLY` or `HOLD_NO_POINT_RECOVERY_CLAIM`.  It has no
interval, covariance, or coverage code path.

## Required live preflight before any submission

The owner must separately approve this exact campaign after reviewing this
packet.  Then, and only then:

1. Verify a live DRAC ControlMaster socket and the exact available CPU cluster
   and account; do not infer an account from a historical script.
2. Copy the committed source at the approved SHA to a unique `/project` run
   root and record `git rev-parse HEAD`, modules, R/TMB versions, and scheduler
   settings there.
3. Run one local, source-loaded non-empty shard from the committed runner and
   inspect its retained raw row before any array submission.
4. Submit at most the approved 60-task, four-shards-per-cell array from the
   verified run root.  Use one CPU per task, a 2-hour walltime limit, 4 GB
   memory per task, and a concurrency cap of four pending the first `seff`
   read-back.
5. Retain failed jobs and partial outputs; analyse only after the full expected
   shard/replicate key set has been verified.

No GitHub Actions, Totoro substitution, public documentation update, or
capability-ledger change is in this packet.

The Rorqual submission script is
`tools/slurm/aoi2-bernoulli-nb2-recovery-rorqual.sbatch`.  It is pinned to the
owner-verified `def-snakagaw_cpu` account and the exact campaign run-root
format; it refuses unsupported task IDs, absent staged source, unsafe roots,
and pre-existing result directories.  Every task maps deterministically to one
formula, sample size, and non-overlapping 50-replicate shard.
The runner source-loads locally when `devtools` is available, but the array
uses the package installed into each task's isolated library; `devtools` is not
a cluster dependency.

## Owner authorization text

> I approve the AOI-2 point-recovery DRAC campaign exactly as frozen in this
> dispatch pack: 15 cells, 200 outer datasets per cell, retained all-attempt
> denominators, and point-estimate/prediction outputs only. Verify the live
> DRAC account and run one source-loaded shard first; do not begin AOI-3 or
> expose public uncertainty.
