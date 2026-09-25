# 071-ordinary-laplace: folded historical evidence from #1304

This directory was folded from itchyshin/drmTMB#1304 by Arc 1 PR-D. Every other file here is
copied byte for byte from #1304. This README is the only file the fold added.

The data files carry two pin sets, each recorded in the file itself:

- `s7-coverage-summary.tsv` (the retained S7 campaign): drmTMB
  `453cff782900aa55211d3f5971c229fc485d291e`, DRM.jl (DRModels)
  `b2caf00f23f080fe89028966a4bfb098ef095510`.
- `reconciled-summary.tsv` and `cost-probe.md` (preliminary receipts and cost probe): drmTMB
  `9939ace07967af9a9b6e23a4d021080d5d7d76a7`, DRM.jl `b877f5136dbd13b6ff1cb3a1de02ee826b0fdf1c`.
  `four-fixture-contract.md` marks these as superseded diagnostics.

The scripts record no pin of their own.

The folded files describe #1304's own code in the present tense: the scoreboard reader for
`reconciled-summary.tsv`, the `marginal = "Laplace"` argument, the coupled NB2 `mu`/`sigma` bridge
route, and its Cholesky profiling. **None of that code is on `main`.** It is listed for Arc 2. The
campaign fixture requests `marginal = "Laplace"` for the three scalar fixtures, which `drmTMB()` on
`main` does not accept, and passes no `marginal` for the coupled NB2 fixture, a route `main`
rejects; so `main` cannot rerun these fits. No file here records which integrator Julia actually
used. Read the files as historical evidence about #1304's routes, not as a description of what
`main` does.

Full account, file by file:
[`docs/dev-log/loop/arc1-honest-ledger/pr1304-fold-provenance.md`](../../../loop/arc1-honest-ledger/pr1304-fold-provenance.md),
section 0 ("Read this first").
