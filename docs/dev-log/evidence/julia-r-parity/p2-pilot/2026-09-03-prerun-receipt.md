# N5 P2 pre-run receipt -- ABANDONED (Julia-embedding segfault on Totoro)

estimate_minutes: 10
drmtmb_ref: 0ceb77eb0cf7af1d590e313d6a84c514bbef51c1
drmjl_ref: 77513aa0663209b96e53a649d232558515f687fa
tmb_converged: TRUE
julia_converged: FALSE
wall_seconds: 1554

D-139 pre-run estimate, stated before running: `plain_binomial_nonphylo` (DRM.jl
fixture `test/parity/fixtures/binomial-trials`, n = 180, `bf(cbind(successes,
failures) ~ x)`, `family = stats::binomial()`), one bootstrap CI (`R = 20`) per
coefficient on both engines, single core, `OPENBLAS_NUM_THREADS=1` on Totoro --
expected < 10 minutes (matches `n5-pilot-inputs.md`'s proposed pre-run).

## What actually happened

Setup (drmTMB main + DRM.jl @ 77513aa0) completed and worked. The pre-run itself
could not complete on the Julia side: `JuliaCall::julia_setup()` reliably
**segfaults the R process** (exit 139, unrecoverable, not caught by
`tryCatch()`) when embedding Julia into this R 4.5.3 build on Totoro, tried
against BOTH Julia 1.12.6 (`~/.juliaup/bin/julia`, the version verified
reachable earlier tonight) and Julia 1.10.10 (a juliaup-managed build matching
DRM.jl's `Project.toml` `julia = "1.10"` compat bound, `~/.julia/juliaup/
julia-1.10.10+0.x64.linux.gnu`). Reproduced with `LD_LIBRARY_PATH` pointed at
Julia's private lib dir, `TMPDIR` redirected to `~/hsq_work/jltmp` (an env
variant seen in a prior, unrelated HSquared.jl Julia-embedding fight at
`~/hsq_work/envfix/`), and `JULIA_NUM_THREADS=1`. None of the three variants
avoided the crash. This is an **R-process/libjulia embedding problem specific
to this Totoro stack**, not a drmTMB or DRM.jl code defect: a concurrent,
unrelated lane on the same box (`snakagaw` PID 1472370) was running DRM.jl's
own `Pkg.test()` under the exact same Julia 1.12.6 binary at full CPU
throughout this pre-run with no trouble, so Julia itself is healthy --
only the R-embedded path (`library(JuliaCall); julia_setup()`) breaks.

Per this leaf's own gate G5 and per the task's 15-minute-per-step rule, this
step (diagnosing and retrying the Julia embedding) is ABANDONED after three
targeted retries (~15-20 minutes of the ~26-minute Totoro session) rather than
chased further.

A second, narrower, and separate finding surfaced on the TMB side before the
Julia blocker was hit: `confint(fit, method = "bootstrap")` on this specific
fixture's response type errors --

```
Error in `bootstrap_response_data()`:
! Bootstrap confidence intervals require a stored response column in the
  fitted data.
```

-- because the fitted formula's response is `cbind(successes, failures)`
(a two-column matrix response), and `bootstrap_response_data()`
(`R/profile.R:2945`) only special-cases a single stored response column or the
two `biv_gaussian`/`biv_lognormal` simulated-column names; a `cbind(s, f) ~ x`
binomial-trials fit falls into neither branch. `method = "wald"` and
`method = "profile"` both work fine on the same fit/target. This is a
narrow, real gap in bootstrap support for two-column binomial responses --
worth a ticket for the engineering lane -- but it is independent of, and
smaller than, the Julia-embedding blocker above, and this receipt does not
attempt to fix it.

Given both blockers, no cross-engine bootstrap comparison exists for this row.
The table below reports what the TMB side *could* produce (Wald, not
bootstrap, since bootstrap itself errored for this response type) so the
receipt carries real numbers rather than none; the Julia columns are `NA`
because no Julia fit or confint call ever completed.

## Totoro session

Exact commands (existing ControlMaster socket, never a fresh login):

```sh
ssh -o ControlPath=/Users/z3437171/.ssh/cm-snakagaw@totoro.biology.ualberta.ca:22 \
    -o BatchMode=yes -o ConnectTimeout=15 snakagaw@totoro.biology.ualberta.ca '<cmd>'

# setup
git clone https://github.com/itchyshin/drmTMB.git repo   # -> 0ceb77eb0
R_LIBS_USER=$HOME/hsq_work/parity-p2/Rlib \
  R CMD INSTALL --library=$HOME/hsq_work/parity-p2/Rlib --no-multiarch repo
git clone https://github.com/itchyshin/DRM.jl.git drmjl
cd drmjl && git checkout 77513aa0                         # -> 77513aa0663209b96e53a649d232558515f687fa
~/hsq_work/julia-1.10.10/bin/julia --project=. -e 'using Pkg; Pkg.instantiate()'   # after removing a
  # Julia-1.12-generated Manifest.toml that pinned JuliaSyntaxHighlighting=1.12.0,
  # unsatisfiable on 1.10; kept as Manifest.toml.julia112.bak

# pre-run attempts (each segfaulted, exit 139)
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  DRM_JL_PATH=$HOME/hsq_work/parity-p2/drmjl DRMTMB_P2_OUT=$HOME/hsq_work/parity-p2/prerun.tsv \
  JULIA_HOME=$HOME/.julia/juliaup/julia-1.10.10+0.x64.linux.gnu/bin \
  R_LIBS_USER=$HOME/hsq_work/parity-p2/Rlib \
  Rscript tools/parity-p2-pilot.R --prerun

# TMB-only confirmation (real numbers, no Julia involved)
OPENBLAS_NUM_THREADS=1 R_LIBS_USER=$HOME/hsq_work/parity-p2/Rlib Rscript -e '...'
```

`nproc` = 384 throughout (unchanged, as expected -- no scaling was attempted).
`/proc/loadavg` before this session's first command: `3.36 3.97 4.27` (load ~4,
other users' jobs). `/proc/loadavg` at the end: `6.63 10.53 7.79` -- the rise is
a concurrent, unrelated lane's DRM.jl `Pkg.test()` run (PID 1472370, `snakagaw`,
`~/s7b_work/DRM.jl`, 99% CPU) already in progress on the shared box, not this
pre-run (which never used more than 1 core and completed its own work in well
under a minute of that window). No processes of this pre-run were left running
at any point -- every launch (`R CMD INSTALL`, `Pkg.instantiate`, each
`Rscript` attempt) ran to completion or crashed on its own; `ps aux` at the end
shows nothing from this leaf still alive.

This proves the PIPELINE only where it got that far (drmTMB main installs and
fits with `engine = "tmb"` cleanly on Totoro; DRM.jl clones, pins to
77513aa0, and instantiates under Julia 1.10). It does not establish an
interval-coverage property of either engine's confidence intervals, and no
capability-ledger row or dashboard TSV is touched by this receipt.

## Table

| coefficient | ci_lower_tmb | ci_upper_tmb | ci_lower_julia | ci_upper_julia | endpoint_abs_delta |
|---|---|---|---|---|---|
| mu:(Intercept) [wald, not bootstrap] | -0.2995212 | -0.1075562 | NA | NA | NA |
| mu:x [wald, not bootstrap] | 0.3479328 | 0.5480262 | NA | NA | NA |

TMB fit: converged, `sdr$pdHess = TRUE`, fit wall time 0.037s. Julia fit: never
attempted past `julia_setup()`, which crashed the R process before any
`drmTMB(..., engine = "julia")` call was reached.

## Full pilot estimate

The full pilot (4 rows x {profile, bootstrap} x 2 engines x 5 reps from the
plan doc) cannot be estimated honestly right now: its dominant cost is the
Julia half, and the Julia half is currently blocked on Totoro by the
`JuliaCall::julia_setup()` embedding segfault documented above, not by fit or
bootstrap wall-clock. Until that is fixed (or the pre-run is repeated on a
machine/R+Julia combination where `library(JuliaCall); julia_setup()` does not
crash), the full pilot's TMB-side cost alone is a poor proxy for the total,
because every prior successful engine="julia" measurement in this repo's
existing receipts (Workflow G, A5, q4-SE) ran on a different host (the
developer's own Mac), not Totoro.

What is measurable from this session: a single TMB fit + Wald confint on this
180-row fixture took 0.037s + a few ms: negligible. If the Julia embedding is
fixed, the TMB half of a 4-row x 2-method x 5-rep pilot is sub-second in total
and the Julia half's wall-clock should track the existing Workflow G / A5
JuliaCall-boot-plus-fit pattern (JuliaCall setup is a one-time few-second cost
per R session, each subsequent fit and bootstrap replicate on fixtures this
small should be well under a second). On that basis, once unblocked, a
single-core full pilot is still plausibly under 30 minutes wall-clock -- but
this is an extrapolation from other-host numbers, not a measurement made on
Totoro, and should be re-estimated with a fresh pre-run once the embedding
issue is resolved. Recommended next step: file the `JuliaCall::julia_setup()`
segfault as its own, narrower diagnostic task (does it reproduce outside
drmTMB entirely, e.g. `library(JuliaCall); julia_setup()` alone against a
freshly-added `~/.julia/environments/v1.12` `DataFrames` dependency) before
committing more Totoro time to P2.
