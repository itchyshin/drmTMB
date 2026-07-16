# Beta phylogenetic q1 disjoint repair: Totoro smoke

**Status:** mechanical smoke passed; no recovery claim

This three-fit Totoro smoke ran from a detached checkout of clean pushed head
`ad1ebe9bdd73fc009668af81cd4f5e806f3b983e`, using runner commit
`39acd66a191d2c6fb6d768e6423f3a91241f9c51` and runner SHA-256
`777f7de6da2ae003624122e11c035fc096449af85971bd6ac3e0dff4a1d9f2a4`.
It used `--mode=repair_smoke`, one fit at each `g = {64,256,1024}`, `m = 4`,
and one BLAS thread.

All three fits returned convergence code zero and `pdHess = TRUE`, with no
warnings or boundary flags. The design, provenance audit, seed audit, and run
provenance are byte-identical to the local smoke. Parameter estimates agree
with the local results to ordinary cross-platform floating-point precision.
Bias and RMSE rows from one replicate are descriptive only.

```text
adaa06bb0d5ca100d37d573089d8c0df986d48f640d27d16fe64ba6ad53b047c  design.tsv
6a64e396080775514f09fc83bef8ec4da114c48244d9d2d3b02fe3124165dfd2  gates.tsv
d1bc3e0f8ee42dcc2431a7a02d1a54530e7d26fe58ec4a3ab42390f9ed4794c9  provenance-audit.tsv
ba928329c9ad088cf117869bbb0dd19fd100c90218ffc4b7981c62a8ba23b4b0  raw-attempts.tsv
4b10f8bd22f1a8c794e30bdaf84216a2e5a7ac39b90d0bbf8dd15d3bd4579546  rmse-difference.tsv
ff8f813a0753a2dbe3582ca8a45a394bb810dba59ece471abe2ba9fb7e60ffcd  run-provenance.tsv
a9ca1b5b9839304363d4b17a8a98102f199faf38401db6b1881d9178f0c2ef54  seed-audit.tsv
ca387881c519897ce0fca8434c8ddfcafa21a21c212616f863d98e21809728b2  session-info.txt
d0febe4f2b8b3bed915a5f0e1f5993c70276b316043f9b2ba173651cba4cae50  summary.tsv
```
