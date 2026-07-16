# Beta phylogenetic q1 disjoint repair: local smoke

**Status:** mechanical smoke passed; no recovery claim

This three-fit local smoke ran from clean pushed head
`ad1ebe9bdd73fc009668af81cd4f5e806f3b983e`, using runner commit
`39acd66a191d2c6fb6d768e6423f3a91241f9c51` and runner SHA-256
`777f7de6da2ae003624122e11c035fc096449af85971bd6ac3e0dff4a1d9f2a4`.
It used `--mode=repair_smoke`, one fit at each `g = {64,256,1024}`, `m = 4`,
and one BLAS thread.

All three fits returned convergence code zero and `pdHess = TRUE`, with no
warnings or boundary flags. The source, prior-artifact, frozen-design, and seed
audits passed. Bias and RMSE rows from one replicate are descriptive only; they
cannot support or reject recovery.

```text
adaa06bb0d5ca100d37d573089d8c0df986d48f640d27d16fe64ba6ad53b047c  design.tsv
05581026594110e194522e62b4cb529bae21077550c4935af0fe91282c3a8e3b  gates.tsv
d1bc3e0f8ee42dcc2431a7a02d1a54530e7d26fe58ec4a3ab42390f9ed4794c9  provenance-audit.tsv
d801bf35126ff415008706b1be68e77fc93dc87d8eeb40b57db17196b3f881be  raw-attempts.tsv
d549a825defcc0f557fabbf7df4194b9629d7d68dafe88bdf604e56959f67494  rmse-difference.tsv
ff8f813a0753a2dbe3582ca8a45a394bb810dba59ece471abe2ba9fb7e60ffcd  run-provenance.tsv
a9ca1b5b9839304363d4b17a8a98102f199faf38401db6b1881d9178f0c2ef54  seed-audit.tsv
a0850b493b6d21836fca9e606b53470e411d80f0d8b16594284462a1bd92d1e8  session-info.txt
db1def13515e7fb804d66aa4cacd615c0a0275c8ce3a340815d4203641946260  summary.tsv
```
