# 0.7.1 ordinary-Laplace — reconciled-summary gate

The four frozen fixtures now have a dedicated programme-level reconciler. It
reads only the four per-fixture reconciliations, rejects missing engine-target
rows, mixed source pins, unclean source trees, a changed runner hash, target
manifest drift, and unknown terminal profile statuses. It writes one compact,
tracked `reconciled-summary.tsv`; raw task sidecars remain local and ignored.

`tools/write-parity-scoreboard.R` reads that summary only when its drmTMB and
DRM.jl pins match generation and emits `ORDINARY-LAPLACE-CLASSIFIED`, not the
generic `RECEIPT` point/SE-parity verdict. The coupled L22 endpoint therefore
remains visible as a retained non-finite classification. This guard requires a
fresh four-fixture run after the source commits that introduce it.
