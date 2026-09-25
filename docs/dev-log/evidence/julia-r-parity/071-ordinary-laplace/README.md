# 071-ordinary-laplace: folded historical evidence from #1304

This directory was folded from itchyshin/drmTMB#1304 by Arc 1 PR-D. Every other file here is
copied byte for byte from #1304 and was measured against DRM.jl (DRModels)
`b2caf00f23f080fe89028966a4bfb098ef095510`, with drmTMB frozen at `453cff782`. This README is the
only file the fold added.

The folded files describe #1304's own code in the present tense: the scoreboard reader for
`reconciled-summary.tsv`, the `marginal = "Laplace"` argument, the coupled NB2 `mu`/`sigma` bridge
route, and its Cholesky profiling. **None of that code is on `main`.** It is listed for Arc 2. The
campaign fitted every Julia target with `marginal = "Laplace"`, which `drmTMB()` on `main` does not
accept, so `main` cannot rerun these fits. Read the files as historical evidence about #1304's
routes, not as a description of what `main` does.

Full account, file by file:
[`docs/dev-log/loop/arc1-honest-ledger/pr1304-fold-provenance.md`](../../../loop/arc1-honest-ledger/pr1304-fold-provenance.md),
section 0 ("Read this first").
