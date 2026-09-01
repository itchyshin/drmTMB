# Public Julia LSS bootstrap receipt — development-opt-in shuffled REML and masks

**Superseded for ordinary-batch qualification by `public-004.md`.** The
mathematical and transport checks remain useful, but this runner set
`DRMTMB_JULIA_TESTS=true`; therefore it is development-opt-in evidence only.

## Scope

This is a bounded public-dispatch check, not bootstrap coverage, native-R
interval parity, a large-tree measurement, or complete inference qualification.
It runs `drmTMB(..., engine = "julia", REML = TRUE)` then public
`confint(method = "bootstrap")`, and independently rebuilds the sorted bridge
payload in Julia under the same seed.

## Command and bounded resources

```sh
Rscript --vanilla tools/run-julia-lss-bootstrap-public.R \
  /private/tmp/drm-parity-20260830/DRM.jl \
  /private/tmp/drm-parity-20260830/lss-bootstrap-public-003
```

The run used a 180-second watchdog and completed in 33.394 seconds. The
receipt records one Julia and one BLAS thread. Recursive R/Julia source
manifests were identical before and after; active foreign development bytes are
retained in the status, so this is not a clean-head claim.

## Exercised contract

The input comprises 32 tree tips and four observations per tip. It is shuffled
before the R bridge call. The bridge payload is verified to be tree-tip ordered,
with `row_order` mapping exactly back to the shuffled input. Direct Julia uses
that payload, rather than reconstructing an independently ordered data frame.

All fits requested and retained REML. The direct check makes an additional
manual refit of a real marginal-simulator bootstrap draw with `method = :REML`;
it converges. This is estimator-propagation evidence, not a replacement for the
bootstrap implementation's existing all-draw kernel tests.

| public target | draws used / failed | public 90% interval | direct interval |
|---|---:|---:|---:|
| `fixef:mu:x` | 6 / 0 | [0.42212321528474883, 0.52198194059443914] | identical |
| `fixef:sd_phylo:z` | 6 / 0 | [0.35847444084192287, 0.80370273780476198] | identical |

The scale target is a public fixed-effect coordinate. It must not be searched
only under the bridge's random-effect-SD target class.

The response-include companion masks one full four-row tip block. Its bridge and
direct reconstruction agree with `nobs = 124`, matching the retained mask and
payload row order; its `fixef:mu:x` B = 4 interval has four used and zero failed
draws.

## Provenance

Receipt runner SHA-256:
`d9b4fdf6e236f3764d281814e89b76b5a8e5da4d968caa26fa6b3b019f9a0946`.

The result files are retained outside the worktree:

```text
20dc9511ea7d7464064763610c8b9384e05bb1cec9f71d09ee9d09ce34fb1e20  lss-bootstrap-public-003.json
1ea07d948476c1dab4deaaa0ceb97ae2fd0aba79e57dd1e4524e300dae3fe26e  lss-bootstrap-public-003.rds
bd07dfcb555407db5ecaa942ff576c1f655545e9ee0f0a0f00f4acb7fd92ac19  public-003.log
```

The loaded development DLL SHA-256 is
`37ecda8a20e59c7309717865948928fc186bca853cda65b2c23c27805de60174`.

## Remaining obligations

This does not establish interval coverage, native-R bootstrap parity, a public
random-effect SD wrapper, broad profile nuisance convergence/failure statuses,
sparse or large-tree performance, final clean-head integration, or any remaining
G0-G8 requirement. Existing strict 4e-6 coefficient losses and the full native
missing-predictor denominator remain open.
