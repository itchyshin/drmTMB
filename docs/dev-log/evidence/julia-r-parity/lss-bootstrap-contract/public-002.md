# Public Julia LSS bootstrap receipt — initial ordered fixed-effect probe

**Superseded for qualification by `public-003.md`.** This retained result is
still valid for its tree-ordered fixed-effect call, but it did not deliberately
shuffle input rows, manually refit a simulated bootstrap draw, test the masked
direct reconstruction, or request the public `fixef:sd_phylo:z` target. Its
empty random-effect-SD inventory was a harness selection error, not evidence
that the LSS scale fixed-effect target is unavailable.

The recorded `manual_refit` in this first probe simply refit the original data;
it is not evidence that a bootstrap replicate preserves REML. `public-003.md`
supersedes both of those narrow claims with an actual simulator draw and the
admitted scale fixed-effect target.

## Scope

This receipt exercises the public R route only: `drmTMB(..., engine =
"julia", REML = TRUE)` followed by `confint(..., parm = "fixef:mu:x",
method = "bootstrap")`.  It compares that call with a direct Julia rebuild from
the same sorted bridge payload and seed.  It is a B = 6 dispatch check, not a
coverage experiment, native-R interval comparison, or a complete inference
matrix.

## Command and resource contract

The first sandbox wrapper failed before R started because the sandbox rejected
its background process priority operation; retain `public-001.log`.  The
identical bounded command was then run with an explicit 180-second watchdog:

```sh
Rscript --vanilla tools/run-julia-lss-bootstrap-public.R \
  /private/tmp/drm-parity-20260830/DRM.jl \
  /private/tmp/drm-parity-20260830/lss-bootstrap-public-002
```

`public-002.log` records `JULIA_LSS_BOOTSTRAP_PUBLIC_PASS elapsed=38.671`.
Both Julia and BLAS report one thread.

## Results

The main 32-tip / 128-row Gaussian phylogenetic LSS case requested and used
REML in the public bridge and direct Julia reconstruction.  The direct manual
refit also reports REML.  All six requested bootstrap draws were used, zero
failed, and the fixed-effect 90% interval agrees exactly:

| route | lower | upper |
|---|---:|---:|
| public `confint()` | 0.45212304157455413 | 0.60354013930896044 |
| direct Julia | 0.45212304157455413 | 0.60354013930896044 |

The response-include probe replaces one four-row tree-tip response block with
missing values.  It completed with `nobs = 124`, REML retained, and four of
four bootstrap draws used.

`sd_phylo` was deliberately not forced through a private primitive: the public
bridge target inventory contains no random-effect SD target for this LSS fit,
so the receipt records `not_publicly_admitted` rather than treating another SD
wrapper as evidence.

## Provenance

The result writer compared recursive R/Julia source manifests before and after
and reports `source_unchanged = TRUE`.  It retains the active worktree status,
including foreign development bytes; it makes no clean-head claim.  The loaded
native DLL was
`/var/folders/7x/ytfpq14s0v18frbm9v_w9f4c0000gq/T//RtmpyUWN2T/pkgloadaf7c3cc45464/drmTMB.so`
with SHA-256
`37ecda8a20e59c7309717865948928fc186bca853cda65b2c23c27805de60174`.

External retained receipt hashes:

```text
53daeb248c300fb790acaed2e85ced820eaa7ae2248791d06c332e3e610b11b4  lss-bootstrap-public-002.json
8ead2254a25048effb43cb27c22245c95147cb7c63f4cb25b1e27dcc31611e88  lss-bootstrap-public-002.rds
```

## Remaining work

This does not establish bootstrap coverage, native-R interval parity, LSS SD
bootstrap access, sparse/large-tree efficiency, complete profile nuisance
statuses, or the wider G0-G8 programme.  The retained strict raw-coefficient
losses and all missing-predictor obligations remain open.
