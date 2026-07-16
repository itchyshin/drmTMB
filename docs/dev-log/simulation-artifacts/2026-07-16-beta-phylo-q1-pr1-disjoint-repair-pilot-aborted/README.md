# Beta phylogenetic q1 disjoint repair: pilot abort

**Status:** `ABORTED-BEFORE-CERTIFICATION`; PR 1 recovery promotion blocked

This 30-fit Totoro pilot ran from a detached checkout of clean pushed head
`ad1ebe9bdd73fc009668af81cd4f5e806f3b983e`, using runner commit
`39acd66a191d2c6fb6d768e6423f3a91241f9c51` and runner SHA-256
`777f7de6da2ae003624122e11c035fc096449af85971bd6ac3e0dff4a1d9f2a4`.
It used the frozen `repair_pilot` schedule: ten fits at each
`g = {64,256,1024}`, `m = 4`, 16 workers, and one BLAS thread per worker.

All 30 attempts returned convergence code zero and `pdHess = TRUE`, with no
warnings or boundary flags. Every provenance and seed-disjointness check
passed. Fixed `mu` and family-`sigma` slopes passed their pilot gates, as did
all five RMSE non-increase checks. Family `sigma` still means the Beta
variability parameter with `phi = sigma^(-2)`; it is not the latent
phylogenetic location-effect SD.

The load-bearing `g = 256` mean latent log-SD bias was `-0.2214` (MCSE
`0.0861`), so its absolute value failed the frozen `0.10` gate. The
`g = 1024` value passed at `-0.0771` (MCSE `0.0489`). This reproduces the
direction and magnitude of the earlier valid `m = 4` HOLD (`-0.2470`) under a
genuinely disjoint seed schedule.

The predeclared pooled rule makes further certification unsuitable. With the
earlier 400-attempt `g = 256` bias `b_old = -0.246998`, an equal-sized repair
block could satisfy pooled absolute bias at most `0.10` only if its bias were
at least `+0.046998`. The disjoint pilot is negative, and all prior moderate-
tree results are negative. Noether, Fisher, and Rose therefore returned STOP
for the 1,200-attempt certification. The pilot is an abort signal, not a
recovery estimate or capability promotion.

No threshold, estimand, scale, denominator, or claim changed. The ledger stays
unchanged, no PR 1 was opened, and PR 2 direct phylogenetic-SD regression
remains blocked.

```text
1e18d29890a6df5a9d83bea9277bfd0cc177433f06e310b0749011b38979834a  design.tsv
de3375abab93de1e29ae69e09a7355c3fd8d89a9d9425be03382ffb50a400333  gates.tsv
d1bc3e0f8ee42dcc2431a7a02d1a54530e7d26fe58ec4a3ab42390f9ed4794c9  provenance-audit.tsv
cf37a0bcbff4bf318b966936547c34976d96ae8cd89ae5019274ed8d5b1cb799  raw-attempts.tsv
eaefc50b8db26b086e678f859f918fc6ceb244e810985739198b401d85be25ed  rmse-difference.tsv
1ac3d241cdc4ccdbdd7ed650edb10cc87af3546cb2babac23d0c4f53e1276a4e  run-provenance.tsv
b1eb99881923860a8796836cf9e288e14f51ffe21bdd8a455938cc35e3b23413  seed-audit.tsv
7c3faefc23dc093463e2bd690ff7515b4afab749eec19f2e275072336214e726  session-info.txt
df4fa266572ab3b93da399f9c2a8e19740ae2c40f31b9d5f0be403fc959ca774  summary.tsv
```
